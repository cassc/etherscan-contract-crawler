// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../NFTCollection.sol";
import "../ERC2981/ERC2981ContractWideRoyalties.sol";

abstract contract NFTCollectionRoyalties is
    NFTCollection,
    ERC2981ContractWideRoyalties
{
    constructor(address _royaltiesReceiver, uint256 _royaltiesAmount) {
        _setRoyaltiesReceiver(_royaltiesReceiver);
        _setRoyaltiesAmount(_royaltiesAmount);
    }

    function setRoyaltiesReceiver(address _receiver) external onlyOwner {
        _setRoyaltiesReceiver(_receiver);
    }

    function setRoyaltiesAmount(uint256 _amount) external onlyOwner {
        _setRoyaltiesAmount(_amount);
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981Base)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(_interfaceId) ||
            ERC2981Base.supportsInterface(_interfaceId);
    }
}