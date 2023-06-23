// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../NFTCollection.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

abstract contract NFTCollectionRoyalties is
    NFTCollection,
    ERC2981
{
    constructor(address _royaltiesReceiver, uint96 _royaltiesAmount) {
        _setDefaultRoyalty(_royaltiesReceiver, _royaltiesAmount);
    }

    function setRoyaltiesReceiver(address _receiver) external onlyOwner {
        uint256 amount;
        ( , amount) = royaltyInfo(0, _feeDenominator());
        _setDefaultRoyalty(_receiver, uint96(amount));
    }

    function setRoyaltiesAmount(uint96 _amount) external onlyOwner {
        address receiver;
        (receiver, ) = royaltyInfo(0, _feeDenominator());
        _setDefaultRoyalty(receiver, _amount);
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(_interfaceId) ||
            ERC2981.supportsInterface(_interfaceId);
    }
}