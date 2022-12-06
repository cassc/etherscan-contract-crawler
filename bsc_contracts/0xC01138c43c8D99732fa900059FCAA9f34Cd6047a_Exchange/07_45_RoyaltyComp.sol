// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../common/RoyaltyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

contract RoyaltyComp {
    function _payRoyalty(address token, uint256 _tokenId, address currency, uint256 _salePrice) internal returns(uint256){
        RoyaltyUpgradeable royalty = RoyaltyUpgradeable(token);

        address receiver;
        uint256 royaltyAmount;
        (receiver, royaltyAmount) = royalty.royaltyInfo(_tokenId, _salePrice);

        if (currency == address(0)){
            payable(receiver).transfer(royaltyAmount);
        }else{
            IERC20Upgradeable erc20 =  IERC20Upgradeable(currency);
            require(erc20.transfer(receiver, royaltyAmount), "BidComp: Bid with ERC20 token failed");
        }

        return royaltyAmount;
    }
}