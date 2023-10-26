// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/Proxy.sol";
import "@openzeppelin/Address.sol";
import "@openzeppelin/StorageSlot.sol";
import "@openzeppelin/Ownable.sol";
contract ERC721Creator is Proxy, Ownable {
    constructor(string memory name, string memory symbol, address validator, uint256 maxBatchSize, uint256 maxSupply, string memory baseURI, string memory collectionURI, address recipient, uint256 royaltyAmount, uint256 _startTimestamp, uint256 _freeMintQtyPerUser) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x3D12cd455f96F6F84DdEDb40AE6E3dC42b26738B;

         Address.functionDelegateCall(
            0x3D12cd455f96F6F84DdEDb40AE6E3dC42b26738B,
	    abi.encodeWithSignature("initCreator(string,string,address,uint256,string,string,address,uint256,uint256,uint256,uint256)", name, symbol, validator, maxSupply, baseURI, collectionURI, recipient, royaltyAmount, _startTimestamp, 0, _freeMintQtyPerUser)
         );

    }

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal override view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

}