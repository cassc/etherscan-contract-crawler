// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./RoyaltiesV1.sol";
contract UniqueCollectionRoyaltiesV1 is RoyaltiesV1 {

    uint256 public royaltyPercentage;
    address public royaltyRecipient;


    function _setTokenRoyalty(
        uint256 _royalty,
        address _recipient
    ) internal {
        _setTokenRoyaltyPercentage(_royalty);
        _setTokenRoyaltyRecipient(_recipient);
    }

    function _setTokenRoyaltyRecipient(
        address _recipient
    ) internal {
        royaltyRecipient = _recipient;
    }

    function _setTokenRoyaltyPercentage(
        uint256 _royalty
    ) internal {
        require(_royalty < HUNDRED_PERCENT, "Royalties too high");
        royaltyPercentage = _royalty;
    }

    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = royaltyRecipient;
        royaltyAmount = (salePrice * royaltyPercentage) / HUNDRED_PERCENT;
    }
}