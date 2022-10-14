// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract WithdrawAll is Ownable {

    function withdrawEth(address payable receiver, uint amount) public onlyOwner payable {
        uint balance = address(this).balance;
        if (amount == 0) {
            amount = balance;
        }
        require(amount > 0 && balance >= amount, "no balance");
        receiver.transfer(amount);
    }

    function withdrawToken(address receiver, address tokenAddress, uint amount) public onlyOwner {
        uint balance = IERC20(tokenAddress).balanceOf(address(this));
        if (amount == 0) {
            amount = balance;
        }

        require(amount > 0 && balance >= amount, "bad amount");
        IERC20(tokenAddress).transfer(receiver, amount);
    }

    function withdrawNft(address receiver, address nftAddress, uint256 tokenId) public onlyOwner {
        IERC721(nftAddress).transferFrom(address(this), receiver, tokenId);
    }
}