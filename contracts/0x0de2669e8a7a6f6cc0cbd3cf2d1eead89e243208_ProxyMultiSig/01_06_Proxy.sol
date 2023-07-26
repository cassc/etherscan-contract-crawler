// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./MultiSigWallet.sol";
import "hardhat/console.sol";


contract ProxyMultiSig is Proxy, MultiSigWallet {
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    bytes32 private constant ADMIN_STORAGE_LOCATION = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    bytes4 private constant _UPGRADE_TO_AND_CALL_SIGNATURE = bytes4(keccak256("_upgradeToAndCall(address,bytes)"));

    event Upgraded(address indexed implementation);


    constructor(
        address _logic,
        bytes memory _data,
        address[] memory owners,
        uint _required

    ) MultiSigWallet(owners, _required) {
        // Cannot use _upgradeToAndCall because of onlyWallet modifier
        _upgradeTo(_logic);
        if (_data.length > 0) {
            Address.functionDelegateCall(_logic, _data);
        }

        StorageSlot.getAddressSlot(ADMIN_STORAGE_LOCATION).value = msg.sender;  // trick the hardhat-deploy
    }


    function implementation() external view returns (address) {
        return _implementation();
    }

    function upgradeTo(address newImplementation) external payable ownerExists(msg.sender) {
        submitTransaction(
            address(this),
            msg.value,
            abi.encodeWithSelector(_UPGRADE_TO_AND_CALL_SIGNATURE, newImplementation, bytes(""))
        );
    }

    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ownerExists(msg.sender) {
        submitTransaction(
            address(this),
            msg.value,
            abi.encodeWithSelector(_UPGRADE_TO_AND_CALL_SIGNATURE, newImplementation, data)
        );
    }

    function _upgradeToAndCall(address newImplementation, bytes memory data) external onlyWallet payable {
        _upgradeTo(newImplementation);
        if (data.length > 0) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    function _upgradeTo(address newImplementation) internal {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
        emit Upgraded(newImplementation);
    }

    function _implementation() internal view override returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }
}