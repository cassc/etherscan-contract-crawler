// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import './ERC1155AstroverseAssets.sol';

contract AstroverseAssets is  ERC1155AstroverseAssets {

constructor(string memory _name,
    string memory _symbol,
    string memory _uri) public ERC1155AstroverseAssets(_name, _symbol, _uri){

}

    function withdraw() public onlyOwnerOrOperator {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(owner(), address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

}