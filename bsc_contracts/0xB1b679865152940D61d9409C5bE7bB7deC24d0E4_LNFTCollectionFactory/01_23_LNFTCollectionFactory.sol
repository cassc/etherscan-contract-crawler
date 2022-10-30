// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../contracts/collection/LNFTCollection.sol";
import "./Market.sol";

error MarketAddressIsZero();
error MintAmountIsLowerThanOne();
error ValueIsLowerThanMintFee();

contract LNFTCollectionFactory is LNFTCollection, Market {
    using SafeMath for uint256;

    event CollectionCreated(address creator, address collection);

    event TokensCreated(uint256[] tokens);

    uint256 private collectionMintFee = 3;

    constructor(string memory _name, string memory _symbol)
        LNFTCollection(_name, _symbol, marketAddress)
    {}

    function deployNewCollection(string memory _name, string memory _symbol)
        external
        payable
        returns (address)
    {
        LNFTCollection _lnft;
        if (marketAddress == address(0)) {
            revert MarketAddressIsZero();
        }
        _lnft = new LNFTCollection(_name, _symbol, marketAddress);
        emit CollectionCreated(_msgSender(), address(_lnft));
        return address(_lnft);
    }

    function createTokens(
        address _collection,
        uint256 _mintAmount,
        string memory _uriPrefix,
        uint256 _royalty
    ) external payable {
        if (_mintAmount <= 0) {
            revert MintAmountIsLowerThanOne();
        }
        uint256 mintFee;
        uint256 allowedFreeMint = getMaxMintLimit();

        if (
            _mintAmount <= allowedFreeMint ||
            (_mintAmount > allowedFreeMint && _isWhitelisted(_msgSender()))
        ) {
            mintFee = 0;
        } else {
            mintFee = _mintAmount
                .sub(allowedFreeMint)
                .mul(collectionMintFee)
                .div(100);
            if (msg.value < mintFee) {
                revert ValueIsLowerThanMintFee();
            }
            (bool os, ) = payable(address(this)).call{value: msg.value}("");
            require(os);
        }

        uint256[] memory tokens = new uint256[](_mintAmount);
        tokens = LNFTCollection(_collection).mint(
            _msgSender(),
            _mintAmount,
            _uriPrefix
        );
        emit TokensCreated(tokens);
        for (uint256 i = 0; i < tokens.length; i++) {
            setApprovalForAll(marketAddress, true);
            _addNewMinter(_msgSender(), _collection, tokens[i]);
            _setTokenRoyalty(_collection, tokens[i], _royalty);
        }
    }

    function setCollectionMintFee(uint256 _collectionMintFee)
        external
        onlyOwner
    {
        collectionMintFee = _collectionMintFee;
    }

    function getCollectionMintFee() external view returns (uint256) {
        return collectionMintFee;
    }

    function withdraw() external onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}