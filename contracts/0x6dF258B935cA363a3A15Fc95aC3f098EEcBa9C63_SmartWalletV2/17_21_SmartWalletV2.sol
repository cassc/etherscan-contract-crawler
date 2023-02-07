// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol";
import "./WhitelistConsumer.sol";
import "./libs/CallHelpers.sol";
import "./interfaces/ISmartWallet.sol";
import "./interfaces/IWhitelist.sol";

contract SmartWalletV2 is
    ISmartWallet,
    ERC165Upgradeable,
    ERC721HolderUpgradeable,
    ERC1155HolderUpgradeable,
    ReentrancyGuardUpgradeable,
    WhitelistConsumer
{
    using CallHelpers for bytes;

    bytes1 public constant OPERATIONAL_WHITELIST = 0x01;
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x0000000000000000000000000000000000000000000000000000000000001234;

    event Executed(
        address caller,
        address destAddress,
        bytes encodedCalldata,
        uint256 value,
        bytes result
    );

    bool public initialized = false;

    modifier isInitialized() {
        require(initialized, "Not initialized");

        _;
    }

    function initialize(address _operationalWhitelistAddress)
        external
        initializer
    {
        __ReentrancyGuard_init();
        __ERC165_init();
        __ERC721Holder_init();
        __ERC1155Holder_init();
        initialized = true;

        _setWhitelistAddress(
            _operationalWhitelistAddress,
            OPERATIONAL_WHITELIST
        );
    }

    function setOperationalWhitelistAddress(
        address _operationalWhitelistAddress
    ) external isInitialized isWhitelistedOn(OPERATIONAL_WHITELIST) {
        _setWhitelistAddress(
            _operationalWhitelistAddress,
            OPERATIONAL_WHITELIST
        );
    }

    function execute(address _destAddress, bytes calldata _encodedCalldata)
        external
        returns (bytes memory)
    {
        return _execute(_destAddress, _encodedCalldata, 0);
    }

    function execute(
        address _destAddress,
        bytes calldata _encodedCalldata,
        uint256 _value
    ) external returns (bytes memory) {
        return _execute(_destAddress, _encodedCalldata, _value);
    }

    function _execute(
        address _destAddress,
        bytes calldata _encodedCalldata,
        uint256 _value
    )
        private
        nonReentrant
        isInitialized
        isWhitelistedOn(OPERATIONAL_WHITELIST)
        returns (bytes memory)
    {
        (bool success, bytes memory result) = _destAddress.call{value: _value}(
            _encodedCalldata
        );

        if (!success) {
            revert(result.getRevertMsg());
        }

        emit Executed(
            msg.sender,
            _destAddress,
            _encodedCalldata,
            _value,
            result
        );

        return result;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Upgradeable, ERC1155ReceiverUpgradeable)
        returns (bool)
    {
        return
            interfaceId == type(ISmartWallet).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function upgrade(address newImplementation)
        public
        isWhitelistedOn(OPERATIONAL_WHITELIST)
    {
        StorageSlotUpgradeable
            .getAddressSlot(IMPLEMENTATION_SLOT)
            .value = newImplementation;
    }

    function getImplementationAddress()
        public
        view
        returns (address implementation)
    {
        return StorageSlotUpgradeable.getAddressSlot(IMPLEMENTATION_SLOT).value;
    }

    receive() external payable {}
}