// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

abstract contract OwnerWithdrawable is Ownable, ReentrancyGuard {
    function withdrawAll() external virtual nonReentrant {
        Address.sendValue(payable(owner()), address(this).balance);
    }

    function withdrawAllERC20(IERC20 _erc20Token)
        external
        virtual
        nonReentrant
    {
        _erc20Token.transfer(owner(), _erc20Token.balanceOf(address(this)));
    }

    function withdrawERC721(IERC721 _erc721Token, uint256 _tokenId)
        external
        virtual
        onlyOwner
        nonReentrant
    {
        _erc721Token.transferFrom(address(this), owner(), _tokenId);
    }
}