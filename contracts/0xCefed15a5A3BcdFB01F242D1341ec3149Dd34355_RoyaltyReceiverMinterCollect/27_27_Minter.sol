// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

contract Minter {

    mapping(uint => address) private minter;

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        if (to == address(0) && from != address(0)){
            delete minter[tokenId];
        }

        if ( from == address(0)){
            minter[tokenId] = to;
        }

    }

    function getMinter(uint tokenId) public view returns (address) {
        address _minter = minter[tokenId];
        require (_minter != address(0), "Not minted");
        return _minter;
    }

}