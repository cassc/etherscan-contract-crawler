// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import './token/ERC721/IERC721.sol';

contract swapAndBurnNFT {
    bool public autoFlush = true;
    address public adminAddress;
    address public tokenContractAddress;
    uint256 public swapCost;

    event SwapToETH(uint256 tokenId, address receiverOnETH);

    constructor(address _adminAddress, address _tokenContractAddress, bool _autoFlush, uint256 _swapCost) {
        adminAddress = _adminAddress;
        tokenContractAddress = _tokenContractAddress;
        swapCost = _swapCost;
        autoFlush = _autoFlush;
    }

    modifier onlyAdmin {
        require(msg.sender == adminAddress, 'Only admin');
        _;
    }

    function setautoFlush(bool _autoFlush)
    external
    virtual
    onlyAdmin
    {
        autoFlush = _autoFlush;
    }

    function setswapCost(uint256 _swapCost)
    external
    virtual
    onlyAdmin
    {
        swapCost = _swapCost;
    }

    function flushERC721Token(uint256 _tokenId)
    external
    virtual
    onlyAdmin
    {
        IERC721 instance = IERC721(tokenContractAddress);
        instance.burn(_tokenId);
    }

    function swapERC721Token(uint256 _tokenId)
    external
    virtual
    payable
    {
        require(msg.value >= swapCost, "swapERC721Token: Insufficient funds");
        (bool os, ) = payable(adminAddress).call{value: address(this).balance}('');
        require(os);

        IERC721 instance = IERC721(tokenContractAddress);
        if (autoFlush) {
//            instance.transferFrom(msg.sender, address(this), _tokenId);
            instance.burn(_tokenId);
        } else {
            instance.transferFrom(msg.sender, address(this), _tokenId);
        }

        emit SwapToETH({
            receiverOnETH: msg.sender,
            tokenId: _tokenId
        });
    }
}