// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./ERC721AManager.sol";

// @author: miinded.com

abstract contract ERC721AManagerMint is ERC721AManager, ReentrancyGuard {

    uint32 public MAX_SUPPLY;
    uint32 public RESERVE;
    uint256 public reserved;

    modifier notSoldOut(uint256 _count) {
        require(_totalMinted() + _count <= MAX_SUPPLY, "Sold out!");
        _;
    }

    function _setMaxSupply(uint32 _maxSupply) internal {
        MAX_SUPPLY = _maxSupply;
    }
    function _setReserve(uint32 _reserve) internal {
        RESERVE = _reserve;
    }

    function Reserve(address _to, uint256 _count) public virtual onlyOwnerOrAdmins {
        require(reserved + _count <= RESERVE, "Exceeded RESERVE_NFT");
        require(_totalMinted() + _count <= MAX_SUPPLY, "Sold out!");
        reserved += _count;
        ERC721AManager._mint(_to, _count);
    }
}