// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/token/ERC1155/IERC1155.sol";

contract SellSeasonOne is Ownable {

    constructor() {
        _transferOwnership(0x75989893BFa48F54E59A6f3020FEd3878Cc8bad9);
    }
    
    function sellSeasonOne() external {
        IERC1155(0x0000000010C38b3D8B4D642D9D065FB69BC77bC7).safeTransferFrom(msg.sender, owner(), 1, 1, "");

        require(address(this).balance > 0, "No balance to pay out");
        
        (bool success, bytes memory res) = msg.sender.call{value: 1}("");
        require(success, string(res));
    }

    function withdraw() external onlyOwner {
        (bool success, bytes memory res) = owner().call{value: address(this).balance}("");
        require(success, string(res));
    }

    receive() external payable onlyOwner {}
}