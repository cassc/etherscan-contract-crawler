/*
Crafted with love by
Metablaze
*/
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;


import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./ERC721ARoyalty.sol";


abstract contract ShareHolder is ERC721ARoyalty, ReentrancyGuard {
    // total wei reflected ev
    uint256 public ethReflectionBasis;
    uint256 public totalReflected;

    mapping(address => uint256) public lastReflectionBasis;
    mapping(address => uint256) public claimedReflection;

    /**
     * @dev overriden functions of transfer function that claims sender and receiver reflection before transfering the token
    * */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override nonReentrant {
        _claimReflection(from);
        _claimReflection(to);
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override nonReentrant {
        _claimReflection(from);
        _claimReflection(to);
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory //_data
    ) public virtual override nonReentrant {
        _claimReflection(from);
        _claimReflection(to);
        super.safeTransferFrom(from, to, tokenId);
    }

    /** @dev claims reflection of function caller */
    function claimReflection() external {
        _claimReflection(msg.sender);
    }

    /** @dev private function that does the math to calculate what is owed to the user */
    function _claimReflection(address sender) private {
        uint256 basisDifference = ethReflectionBasis - lastReflectionBasis[sender];
        uint256 owed = basisDifference * balanceOf(sender) / totalSupply();

        lastReflectionBasis[sender] = ethReflectionBasis;
        if (owed == 0) {
            return;
        }
        claimedReflection[sender] += owed;
        totalReflected += owed;
        payable(sender).transfer(owed);
    }
}