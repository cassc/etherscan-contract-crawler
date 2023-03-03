// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Administration.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

abstract contract Treasury is Administration {
    address internal _treasury;

    modifier isTreasuryOrGlobalAdmin() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) && _msgSender() != _treasury) {
            revert InsufficientAccess();
        }
        _;
    }

    function setTreasury(address treasury) external isGlobalAdmin {
        _treasury = treasury;
    }

    function getTreasuryAddress() public view returns (address) {
        return _treasury;
    }

    function withdraw() external isTreasuryOrGlobalAdmin {
        if (_treasury == address(0)) revert MustSetTreasury();
        (bool success, ) = payable(_treasury).call{value: address(this).balance}("");
        if (!success) revert WithdrawFailed();
    }

    function withdrawToken(address token) external isTreasuryOrGlobalAdmin {
        if (_treasury == address(0)) revert MustSetTreasury();
        IERC20 t = IERC20(token);
        t.transfer(_treasury, t.balanceOf(address(this)));
    }

    function withdraw1155(address token, uint256 tokenId) external isTreasuryOrGlobalAdmin {
        if (_treasury == address(0)) revert MustSetTreasury();
        IERC1155 erc1155 = IERC1155(token);
        erc1155.safeTransferFrom(address(this), _treasury, tokenId, erc1155.balanceOf(address(this), tokenId), "");
    }

    function withdraw721(address token, uint256 tokenId) external isTreasuryOrGlobalAdmin {
        if (_treasury == address(0)) revert MustSetTreasury();
        IERC721 erc721 = IERC721(token);
        erc721.transferFrom(address(this), _treasury, tokenId);
    }

    //////////////  ERRORS  //////////////
    error WithdrawFailed();
    error MustSetTreasury();
    /////////////////////////////////////
}