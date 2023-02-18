// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IPassport2.sol";
import "../interfaces/ILoyaltyLedger2.sol";
import "../interfaces/IPassageRegistry2.sol";

contract PassagePresetFactory is Ownable {
    // structs
    struct AirdropParameters {
        address[] addresses;
        uint256[] amounts;
    }
    struct LoyaltyTokenParameters {
        string name;
        uint256 maxSupply;
    }
    struct MintingModuleParameters {
        string name;
        bytes data;
    }

    // constants
    address public immutable registry; // Passage Registry v2
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x0000000000000000000000000000000000000000000000000000000000000000;
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // module addresses
    address public nonTransferableAddr; // shared contract
    address public nonTransferable1155Addr; // shared contract
    mapping(string => address) public mmNameToImplAddr; // minting module human readable name -> cloneable implementation address

    // events
    event PresetPassportCreated(address indexed creator, address passportAddress);
    event PresetLoyaltyLedgerCreated(address indexed creator, address llAddress);
    event NonTransferable721ModuleSet(address implAddress);
    event NonTransferable1155ModuleSet(address implAddress);
    event MintingModuleSet(string indexed name, address implAddress);

    /// @param _registry Passage registry address
    constructor(address _registry) {
        require(_registry != address(0), "Invalid registry address");

        registry = _registry;
    }

    /// @notice Creates a new Loyalty Ledger
    /// @param royaltyWallet The address of the wallet to designated to receive royalty payments
    /// @param royaltyBasisPoints The number representing the basis points of royalty fees out of 10000 (e.g. 750 = 7.5% royalty)
    /// @param transferEnabled If transfer should be enabled
    /// @param mmParameters Human readable minting module name (for impl address lookups) & their respective bytes encoded initializer data
    /// @param tokenParameters Token name & maxSupply parameters to create on the Loyalty Ledger
    /// @param airdropParameters Addresses and amounts for each address to mint tokens for after contract creation. Lengths must be equal. For no airdrop, pass an empty array for both values. Lengths must be equal
    function createLoyalty(
        address royaltyWallet,
        uint96 royaltyBasisPoints,
        bool transferEnabled,
        MintingModuleParameters[] calldata mmParameters,
        LoyaltyTokenParameters calldata tokenParameters,
        AirdropParameters calldata airdropParameters
    ) external returns (address) {
        address loyaltyLedger = _createLoyalty(royaltyWallet, royaltyBasisPoints);
        ILoyaltyLedger2(loyaltyLedger).createToken(tokenParameters.name, tokenParameters.maxSupply);
        for (uint256 i = 0; i < mmParameters.length; ) {
            address mmAddress = mmNameToImplAddr[mmParameters[i].name];
            require(mmAddress != address(0), "invalid minting module name");
            require(mmParameters[i].data.length > 0, "invalid minting module data");
            bytes memory data = abi.encodeWithSignature(
                "initialize(address,address,bytes)",
                msg.sender,
                loyaltyLedger,
                mmParameters[i].data
            );
            mmAddress = cloneAndInitialize(mmAddress, data);
            ILoyaltyLedger2(loyaltyLedger).setTokenMintingModule(0, i, mmAddress);
            unchecked {
                ++i;
            }
        }
        if (!transferEnabled) {
            ILoyaltyLedger2(loyaltyLedger).setBeforeTransfersModule(nonTransferable1155Addr);
        }
        if (airdropParameters.addresses.length > 0) {
            require(
                airdropParameters.amounts.length == airdropParameters.addresses.length,
                "airdrop params length mismatch"
            );

            ILoyaltyLedger2(loyaltyLedger).mintBulk(
                airdropParameters.addresses,
                new uint256[](airdropParameters.addresses.length), // minting token 0 and defaults to 0
                airdropParameters.amounts
            );
        }
        _grantRoles(loyaltyLedger, msg.sender);
        _revokeRoles(loyaltyLedger, address(this));
        return loyaltyLedger;
    }

    /// @notice Creates a new Passport
    /// @param tokenName The token name
    /// @param tokenSymbol The token symbol
    /// @param maxSupply Max supply of tokens
    /// @param royaltyWallet The address of the wallet to designated to receive royalty payments
    /// @param royaltyBasisPoints The number representing the basis points of royalty fees out of 10000 (e.g. 750 = 7.5% royalty)
    /// @param transferEnabled If transfer should be enabled
    /// @param mmParameters Human readable minting module name (for impl address lookups) & their respective bytes encoded initializer data.
    /// @param airdropParameters Addresses and amounts for each address to mint passports for after contract creation. Lengths must be equal. For no airdrop, pass an empty array for both values.
    function createPassport(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 maxSupply,
        address royaltyWallet,
        uint96 royaltyBasisPoints,
        bool transferEnabled,
        MintingModuleParameters[] calldata mmParameters,
        AirdropParameters calldata airdropParameters
    ) external returns (address) {
        address passport = _createPassport(tokenName, tokenSymbol, maxSupply, royaltyWallet, royaltyBasisPoints);

        if (mmParameters.length > 0) {
            for (uint256 i = 0; i < mmParameters.length; ) {
                address mmAddress = mmNameToImplAddr[mmParameters[i].name];
                require(mmAddress != address(0), "invalid minting module name");
                require(mmParameters[i].data.length > 0, "invalid minting module data");
                bytes memory data = abi.encodeWithSignature(
                    "initialize(address,address,bytes)",
                    msg.sender,
                    passport,
                    mmParameters[i].data
                );
                mmAddress = cloneAndInitialize(mmAddress, data);
                IPassport2(passport).setMintingModule(i, mmAddress);
                unchecked {
                    ++i;
                }
            }
        }
        if (!transferEnabled) {
            IPassport2(passport).setBeforeTransfersModule(nonTransferableAddr);
        }
        if (airdropParameters.addresses.length > 0) {
            require(
                airdropParameters.amounts.length == airdropParameters.addresses.length,
                "airdrop params length mismatch"
            );

            IPassport2(passport).mintPassports(airdropParameters.addresses, airdropParameters.amounts);
        }
        _grantRoles(passport, msg.sender);
        _revokeRoles(passport, address(this));
        return passport;
    }

    function setNonTransferable721Addr(address contractAddress) external onlyOwner {
        nonTransferableAddr = contractAddress;
        emit NonTransferable721ModuleSet(contractAddress);
    }

    function setNonTransferable1155Addr(address contractAddress) external onlyOwner {
        nonTransferable1155Addr = contractAddress;
        emit NonTransferable1155ModuleSet(contractAddress);
    }

    function setMintingModule(string calldata name, address implAddress) external onlyOwner {
        require(bytes(name).length > 0, "mm name required");
        mmNameToImplAddr[name] = implAddress;
        emit MintingModuleSet(name, implAddress);
    }

    function _createPassport(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 maxSupply,
        address royaltyWallet,
        uint96 royaltyBasisPoints
    ) internal returns (address) {
        IPassageRegistry2 r = IPassageRegistry2(registry);
        bytes memory args = abi.encodeWithSignature(
            "initialize(address,string,string,uint256,uint256,address,uint96)",
            address(this), // factory gets initial permissions
            tokenName,
            tokenSymbol,
            maxSupply,
            0,
            royaltyWallet,
            royaltyBasisPoints
        );
        address passport = r.createPassport(args);

        emit PresetPassportCreated(msg.sender, passport);
        return passport;
    }

    function _grantRoles(address _contract, address _address) internal {
        IPassport2(_contract).grantRole(DEFAULT_ADMIN_ROLE, _address);
        IPassport2(_contract).grantRole(UPGRADER_ROLE, _address);
        IPassport2(_contract).grantRole(MANAGER_ROLE, _address);
        IPassport2(_contract).grantRole(MINTER_ROLE, _address);
        IPassport2(_contract).setOwnership(_address);
    }

    function _revokeRoles(address _contract, address _address) internal {
        IPassport2(_contract).revokeRole(UPGRADER_ROLE, _address);
        IPassport2(_contract).revokeRole(MANAGER_ROLE, _address);
        IPassport2(_contract).revokeRole(MINTER_ROLE, _address);
        IPassport2(_contract).revokeRole(DEFAULT_ADMIN_ROLE, _address);
    }

    function cloneAndInitialize(address mmImplAddr, bytes memory data) public returns (address) {
        address cloneAddr = Clones.clone(mmImplAddr);
        (bool success, ) = cloneAddr.call(data);
        require(success, "module initialize failed");
        return cloneAddr;
    }

    function _createLoyalty(address royaltyWallet, uint96 royaltyBasisPoints) internal returns (address) {
        IPassageRegistry2 r = IPassageRegistry2(registry);
        bytes memory args = abi.encodeWithSignature(
            "initialize(address,address,uint96)",
            address(this), // factory gets initial permissions
            royaltyWallet,
            royaltyBasisPoints
        );
        address loyaltyLedger = r.createLoyalty(args);

        emit PresetLoyaltyLedgerCreated(msg.sender, loyaltyLedger);
        return loyaltyLedger;
    }
}