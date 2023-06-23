// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../extensions/NFTCollectionMintByBurn.sol";
import "../extensions/NFTCollectionRoyalties.sol";
import "../extensions/NFTCollectionMutableParams.sol";
import "../extensions/NFTCollectionPausableMint.sol";

contract NFTCollectionPresetMintByBurn is
    NFTCollectionRoyalties,
    NFTCollectionMintByBurn,
    NFTCollectionMutableParams,
    NFTCollectionPausableMint,
    NFTCollectionBurnable
{
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _notRevealedUri,
        uint256 _cost,
        uint256 _maxSupply,
        address _owner,
        address _royaltiesReceiver,
        uint96 _royaltiesAmount,
        address _burnContract
    )
        NFTCollection(
            _name,
            _symbol,
            _notRevealedUri,
            _cost,
            _maxSupply,
            _owner
        )
        NFTCollectionMintByBurn(_burnContract)
        NFTCollectionRoyalties(_royaltiesReceiver, _royaltiesAmount)
    {}

    function mint(uint256 _amount)
        public
        payable
        override(NFTCollection, NFTCollectionMintByBurn)
    {
        NFTCollectionMintByBurn.mint(_amount);
    }

    function _mintAmount(uint256 _amount)
        internal
        override(NFTCollection, NFTCollectionPausableMint)
    {
        NFTCollectionPausableMint._mintAmount(_amount);
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(ERC721A, NFTCollectionRoyalties)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }
}