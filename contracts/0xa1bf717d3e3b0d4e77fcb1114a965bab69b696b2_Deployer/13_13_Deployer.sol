// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "openzeppelin-contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title Deployer
 * @dev Deploys minter contracts
 */
contract Deployer is OwnableUpgradeable {
    /**
     * @dev Event for a new contract deployment
     */
    event DeployContract(
        address indexed owner,
        address indexed proxyAddress,
        address indexed logicAddress
    );

    /**
     * @dev Event for setting a privileged mint address
     */
    event SetPrivilegedMintAddress(
        address indexed mintAddress,
        bool isPrivileged
    );

    /**
     * @dev Event for setting the ERC721Minter logic contract address
     */
    event SetMinter721Address(address indexed minter721Address);

    /**
     * @notice The address of the ERC721Minter logic contract
     */
    address public minter721Address;

    /**
     * @notice Addresses that are permitted to mint on behalf of others.
     * @dev This is used for allow listing external payment services.
     */
    mapping(address => bool) public privilegedMintAddresses;

    constructor() {
        // https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializing_the_implementation_contract
        _disableInitializers();
    }

    /**
     * @notice Initializes the contract. Required for ugpradeable contracts.
     * @param minter721Address_ The 721 minter contract address
     */
    function initialize(address payable minter721Address_) public initializer {
        __Ownable_init();
        minter721Address = minter721Address_;
    }

    /**
     * @notice Deploys a new ERC721Minter proxy contract
     * @param proxyAdmin_ The proxy admin that can perform proxy upgrades (must be different from the msg.sender)
     * @param name_ The token name of the minter contract
     * @param symbol_ The token symbol of the minter contract
     * @param baseUri_ The base URI of the minter contract
     * @param contractURI_ The contract URI of the minter contract
     * @param maxSupply_ The maxSupply of the minter contract
     * @param maxQuantity_ The max quantity of the minter contract
     * @param price_ The mint price
     * @param startTime_ The start time of the minter contract
     * @param merkleRoot_ The allow-list merkle root of the minter contract
     * @param transferable_ Whether or not tokens are transferable
     * @param payees_ The payee addresses of the minter contract
     * @param shares_ The shares per payee address of the minter contract
     * @return The address of the deployed proxy contract
     */
    function deploy721(
        address proxyAdmin_,
        string calldata name_,
        string calldata symbol_,
        string calldata baseUri_,
        string calldata contractURI_,
        uint256 maxSupply_,
        uint256 maxQuantity_,
        uint256 price_,
        uint256 startTime_,
        bytes32 merkleRoot_,
        bool transferable_,
        address[] calldata payees_,
        uint256[] calldata shares_
    ) external returns (address payable) {
        bytes memory data = abi.encodeWithSignature(
            "initialize(address,string,string,string,string,uint256,uint256,uint256,uint256,bytes32,bool,address[],uint256[])",
            address(this),
            name_,
            symbol_,
            baseUri_,
            contractURI_,
            maxSupply_,
            maxQuantity_,
            price_,
            startTime_,
            merkleRoot_,
            transferable_,
            payees_,
            shares_
        );

        return _deployProxy(minter721Address, proxyAdmin_, data);
    }

    function setPrivilegedMintAddress(address mintAddress_, bool isPrivileged_)
        external
        onlyOwner
    {
        require(
            mintAddress_ != address(0),
            "Deployer: cannot set privileged mint address to zero address"
        );

        privilegedMintAddresses[mintAddress_] = isPrivileged_;
        emit SetPrivilegedMintAddress(mintAddress_, isPrivileged_);
    }

    function setMinter721Address(address minter721Address_) external onlyOwner {
        minter721Address = minter721Address_;
        emit SetMinter721Address(minter721Address_);
    }

    function _deployProxy(
        address contractAddress_,
        address proxyAdmin_,
        bytes memory data_
    ) internal returns (address payable) {
        /**
         * @dev https://docs.openzeppelin.com/contracts/4.x/api/proxy#TransparentUpgradeableProxy
         * If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the implementation.
         * If the admin tries to call a function on the implementation it will fail with an error that says "admin cannot fallback to proxy target".
         */
        require(
            proxyAdmin_ != msg.sender,
            "Deployer: proxy admin cannot be the msg.sender"
        );

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            contractAddress_,
            proxyAdmin_,
            data_
        );

        address payable proxyAddress = payable(address(proxy));

        OwnableUpgradeable(proxyAddress).transferOwnership(msg.sender);

        emit DeployContract(msg.sender, address(proxy), contractAddress_);

        return proxyAddress;
    }
}