//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IERC721.sol";

contract Dashboard is ReentrancyGuard, AccessControlEnumerable {
    mapping(address => uint16) public investmentPerCard;

    // Supported NFT Collections that allow users to use the dashboard. Can be updated by admins.
    address[] private _nftCards;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function addNftContract(address _nft, uint16 investmentAllowed) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (investmentPerCard[_nft] == 0) {
            _nftCards.push(_nft);
            investmentPerCard[_nft] = investmentAllowed;
        }
    }

    function getCardCount(address wallet) public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < _nftCards.length; i++) {
            IERC721 nftCard = IERC721(_nftCards[i]);
            count += nftCard.balanceOf(wallet);
        }
        return count;
    }

    function getInvestmentAllowed(address wallet) public view returns (uint256) {
        uint256 allowed = 0;
        for (uint256 i = 0; i < _nftCards.length; i++) {
            IERC721 nftCard = IERC721(_nftCards[i]);
            allowed += nftCard.balanceOf(wallet) * investmentPerCard[_nftCards[i]];
        }
        return allowed;
    }

    function getNftCards() external view returns (address[] memory) {
        return _nftCards;
    }

    function ownsNftCard(address wallet) external view returns (bool) {
        for (uint256 i = 0; i < _nftCards.length; i++) {
            IERC721 nftCard = IERC721(_nftCards[i]);
            if (nftCard.balanceOf(wallet) > 0) return true;
        }
        return false;
    }

    function updateInvestmentPerCard(uint16 amount, address nft) external onlyRole(DEFAULT_ADMIN_ROLE) {
        investmentPerCard[nft] = amount;
    }
}