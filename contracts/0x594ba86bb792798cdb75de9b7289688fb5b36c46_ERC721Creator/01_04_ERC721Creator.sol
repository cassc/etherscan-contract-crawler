// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC721Creator is Proxy {
    
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initialBaseURI,
        uint256 _initialPrice,
        uint256 _initialSupply,
        address newOwner,
        address proxyAddress
    ) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        //0x13819d58837c88B228046686e6eF3BFc933aaF5e
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = proxyAddress;
        Address.functionDelegateCall(
            proxyAddress,
            abi.encodeWithSignature(
                "initialize(string,string,string,uint256,uint256,address)",
                _name,
                _symbol,
                _initialBaseURI,
                _initialPrice,
                _initialSupply,
                newOwner
            )
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