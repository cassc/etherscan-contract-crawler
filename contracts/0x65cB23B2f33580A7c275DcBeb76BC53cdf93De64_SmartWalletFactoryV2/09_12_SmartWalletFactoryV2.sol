// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./WhitelistConsumer.sol";
import "./interfaces/IWhitelist.sol";
import "./interfaces/ISmartWallet.sol";

contract SmartWalletFactoryV2 is
    WhitelistConsumer,
    Initializable,
    OwnableUpgradeable
{
    event SmartWalletCreated(address _smartWalletAddress);
    event TemplateChanged(address _previousAddress, address _newAddress);

    bytes1 public constant OPERATIONAL_WHITELIST = 0x01;
    bytes1 public constant SMART_WALLETS_WHITELIST = 0x02;

    address public templateAddress;

    uint256[50] __gap;

    function initialize(
        address _owner,
        address _templateAddress,
        address _operationalWhitelistAddress,
        address _smartWalletsWhitelistAddress
    ) public initializer {
        _setWhitelistAddress(
            _operationalWhitelistAddress,
            OPERATIONAL_WHITELIST
        );
        _setWhitelistAddress(
            _smartWalletsWhitelistAddress,
            SMART_WALLETS_WHITELIST
        );

        __Ownable_init();

        setTemplateAddress(_templateAddress);
        _transferOwnership(_owner);
    }

    constructor() {
        _disableInitializers();
    }

    function setOperationalWhitelistAddress(address _whitelistAddress)
        external
        onlyOwner
    {
        _setWhitelistAddress(_whitelistAddress, OPERATIONAL_WHITELIST);
    }

    function setSmartWalletsWhitelistAddress(address _whitelistAddress)
        external
        onlyOwner
    {
        _setWhitelistAddress(_whitelistAddress, SMART_WALLETS_WHITELIST);
    }

    function setTemplateAddress(address _templateAddress) public onlyOwner {
        require(
            ERC165Checker.supportsInterface(
                _templateAddress,
                type(ISmartWallet).interfaceId
            ),
            "Interface not supported"
        );
        address previousAddress = templateAddress;
        templateAddress = _templateAddress;
        emit TemplateChanged(previousAddress, _templateAddress);
    }

    function deploySmartWallet(bytes32 salt)
        internal
        returns (address instance)
    {
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x60803d60043d630c5a6f2f60e01b600052335afa600051611234553d61002780
            )
            mstore(
                add(ptr, 0x20),
                0x6100273d3981f360006000361561002557363d3d373d3d3d363d611234545af4
            )
            mstore(
                add(ptr, 0x40),
                0x3d82803e903d9161002557fd5bf3000000000000000000000000000000000000
            )
            instance := create2(0, ptr, 0x4e, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    function predictSmartWalletAddress(bytes32 salt)
        public
        view
        returns (address predicted)
    {
        address deployer = address(this);
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x60803d60043d630c5a6f2f60e01b600052335afa600051611234553d61002780
            )
            mstore(
                add(ptr, 0x20),
                0x6100273d3981f360006000361561002557363d3d373d3d3d363d611234545af4
            )
            mstore(
                add(ptr, 0x40),
                0x3d82803e903d9161002557fd5bf3ff0000000000000000000000000000000000
            )
            mstore(add(ptr, 0x4f), shl(0x60, deployer))
            mstore(add(ptr, 0x63), salt)
            mstore(add(ptr, 0x83), keccak256(ptr, 0x4e))
            predicted := keccak256(add(ptr, 0x4e), 0x55)
        }
    }

    function createSmartWallet(
        bytes32 _salt,
        address _smartWalletOperationalWhitelistAddress
    )
        external
        isWhitelistedOn(OPERATIONAL_WHITELIST)
        returns (address smartWalletAddress)
    {
        smartWalletAddress = deploySmartWallet(_salt);

        ISmartWallet(smartWalletAddress).initialize(
            _smartWalletOperationalWhitelistAddress
        );

        if (whitelists[SMART_WALLETS_WHITELIST] != address(0)) {
            IWhitelist(whitelists[SMART_WALLETS_WHITELIST]).addToWhitelist(
                smartWalletAddress
            );
        }

        emit SmartWalletCreated(smartWalletAddress);
    }
}