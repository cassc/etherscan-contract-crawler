// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9 <0.9.0;

abstract contract ERC721Payable {
    /**
    * Helper method to allow ETH withdraws.
    */
    function _withdraw(address _address, uint256 _amount) internal {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Failed to withdraw Ether");
    }

    // contract can recieve Ether
    receive() external payable { }
}