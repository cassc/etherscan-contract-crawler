// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./NftCheck.sol";
import "../interfaces/ICryptoPunks.sol";

library AelinNftGating {
    address constant CRYPTO_PUNKS = address(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB);

    // collectionAddress should be unique, otherwise will override
    struct NftCollectionRules {
        // if 0, then unlimited purchase
        uint256 purchaseAmount;
        address collectionAddress;
        // if true, then `purchaseAmount` is per token
        // else `purchaseAmount` is per account regardless of the NFTs held
        bool purchaseAmountPerToken;
        // both variables below are only applicable for 1155
        uint256[] tokenIds;
        // min number of tokens required for participating
        uint256[] minTokensEligible;
    }

    struct NftGatingData {
        mapping(address => NftCollectionRules) nftCollectionDetails;
        mapping(address => mapping(address => bool)) nftWalletUsedForPurchase;
        mapping(address => mapping(uint256 => bool)) nftId;
        bool hasNftList;
    }

    struct NftPurchaseList {
        address collectionAddress;
        uint256[] tokenIds;
    }

    /**
     * @dev check if deal is nft gated, sets hasNftList
     * if yes, move collection rule array input to mapping in the data storage
     * @param _nftCollectionRules array of all nft collection rule data
     * @param _data contract storage data passed by reference
     */
    function initialize(NftCollectionRules[] calldata _nftCollectionRules, NftGatingData storage _data) external {
        if (_nftCollectionRules.length > 0) {
            // if the first address supports punks or 721, the entire pool only supports 721 or punks
            if (
                _nftCollectionRules[0].collectionAddress == CRYPTO_PUNKS ||
                NftCheck.supports721(_nftCollectionRules[0].collectionAddress)
            ) {
                for (uint256 i; i < _nftCollectionRules.length; ++i) {
                    require(
                        _nftCollectionRules[i].collectionAddress == CRYPTO_PUNKS ||
                            NftCheck.supports721(_nftCollectionRules[i].collectionAddress),
                        "can only contain 721"
                    );
                    _data.nftCollectionDetails[_nftCollectionRules[i].collectionAddress] = _nftCollectionRules[i];
                    emit PoolWith721(
                        _nftCollectionRules[i].collectionAddress,
                        _nftCollectionRules[i].purchaseAmount,
                        _nftCollectionRules[i].purchaseAmountPerToken
                    );
                }
                _data.hasNftList = true;
            }
            // if the first address supports 1155, the entire pool only supports 1155
            else if (NftCheck.supports1155(_nftCollectionRules[0].collectionAddress)) {
                for (uint256 i; i < _nftCollectionRules.length; ++i) {
                    require(NftCheck.supports1155(_nftCollectionRules[i].collectionAddress), "can only contain 1155");
                    _data.nftCollectionDetails[_nftCollectionRules[i].collectionAddress] = _nftCollectionRules[i];

                    for (uint256 j; j < _nftCollectionRules[i].tokenIds.length; ++j) {
                        _data.nftId[_nftCollectionRules[i].collectionAddress][_nftCollectionRules[i].tokenIds[j]] = true;
                    }
                    emit PoolWith1155(
                        _nftCollectionRules[i].collectionAddress,
                        _nftCollectionRules[i].purchaseAmount,
                        _nftCollectionRules[i].purchaseAmountPerToken,
                        _nftCollectionRules[i].tokenIds,
                        _nftCollectionRules[i].minTokensEligible
                    );
                }
                _data.hasNftList = true;
            } else {
                require(false, "collection is not compatible");
            }
        } else {
            _data.hasNftList = false;
        }
    }

    /**
     * @dev allows anyone to become a purchaser with a qualified erc721
     * nft in the pool depending on the scenarios
     *
     * Scenarios:
     * 1. each wallet holding a qualified NFT to deposit an unlimited amount of purchase tokens
     * 2. certain amount of purchase tokens per wallet regardless of the number of qualified NFTs held
     * 3. certain amount of Investment tokens per qualified NFT held
     * @param _nftPurchaseList nft collection address and token ids to use for purchase
     * @param _data contract storage data for nft gating passed by reference
     * @param _purchaseTokenAmount amount to purchase with, must not exceed max allowable from collection rules
     * @return uint256 max purchase token amount allowable
     */
    function purchaseDealTokensWithNft(
        NftPurchaseList[] calldata _nftPurchaseList,
        NftGatingData storage _data,
        uint256 _purchaseTokenAmount
    ) external returns (uint256) {
        require(_data.hasNftList, "pool does not have an NFT list");
        require(_nftPurchaseList.length > 0, "must provide purchase list");

        uint256 maxPurchaseTokenAmount;

        for (uint256 i; i < _nftPurchaseList.length; ++i) {
            NftPurchaseList memory nftPurchaseList = _nftPurchaseList[i];
            address _collectionAddress = nftPurchaseList.collectionAddress;
            uint256[] memory _tokenIds = nftPurchaseList.tokenIds;

            NftCollectionRules memory nftCollectionRules = _data.nftCollectionDetails[_collectionAddress];

            require(_collectionAddress != address(0), "collection should not be null");
            require(nftCollectionRules.collectionAddress == _collectionAddress, "collection not in the pool");

            if (nftCollectionRules.purchaseAmountPerToken && nftCollectionRules.purchaseAmount > 0) {
                if (NftCheck.supports1155(_collectionAddress)) {
                    for (uint256 j; j < _tokenIds.length; ++j) {
                        unchecked {
                            uint256 collectionAllowance = nftCollectionRules.purchaseAmount *
                                IERC1155(_collectionAddress).balanceOf(msg.sender, _tokenIds[j]);
                            // if there is an overflow of the pervious calculation, allow the max purchase token amount
                            if (
                                collectionAllowance / nftCollectionRules.purchaseAmount !=
                                IERC1155(_collectionAddress).balanceOf(msg.sender, _tokenIds[j])
                            ) {
                                maxPurchaseTokenAmount = type(uint256).max;
                            } else {
                                maxPurchaseTokenAmount += collectionAllowance;
                                if (maxPurchaseTokenAmount < collectionAllowance) {
                                    maxPurchaseTokenAmount = type(uint256).max;
                                }
                            }
                        }
                    }
                } else {
                    unchecked {
                        uint256 collectionAllowance = nftCollectionRules.purchaseAmount * _tokenIds.length;
                        // if there is an overflow of the pervious calculation, allow the max purchase token amount
                        if (collectionAllowance / nftCollectionRules.purchaseAmount != _tokenIds.length) {
                            maxPurchaseTokenAmount = type(uint256).max;
                        } else {
                            maxPurchaseTokenAmount += collectionAllowance;
                            if (maxPurchaseTokenAmount < collectionAllowance) {
                                maxPurchaseTokenAmount = type(uint256).max;
                            }
                        }
                    }
                }
            }

            if (!nftCollectionRules.purchaseAmountPerToken && nftCollectionRules.purchaseAmount > 0) {
                require(!_data.nftWalletUsedForPurchase[_collectionAddress][msg.sender], "wallet already used for nft set");
                _data.nftWalletUsedForPurchase[_collectionAddress][msg.sender] = true;
                unchecked {
                    maxPurchaseTokenAmount += nftCollectionRules.purchaseAmount;
                    // if addition causes overflow the max allowance is max value of uint256
                    if (maxPurchaseTokenAmount < nftCollectionRules.purchaseAmount) {
                        maxPurchaseTokenAmount = type(uint256).max;
                    }
                }
            }

            if (nftCollectionRules.purchaseAmount == 0) {
                maxPurchaseTokenAmount = type(uint256).max;
            }

            if (NftCheck.supports721(_collectionAddress)) {
                for (uint256 j; j < _tokenIds.length; ++j) {
                    require(IERC721(_collectionAddress).ownerOf(_tokenIds[j]) == msg.sender, "has to be the token owner");
                    require(!_data.nftId[_collectionAddress][_tokenIds[j]], "tokenId already used");
                    _data.nftId[_collectionAddress][_tokenIds[j]] = true;
                    emit BlacklistNFT(_collectionAddress, _tokenIds[j]);
                }
            }
            if (NftCheck.supports1155(_collectionAddress)) {
                for (uint256 j; j < _tokenIds.length; ++j) {
                    require(_data.nftId[_collectionAddress][_tokenIds[j]], "tokenId not in the pool");
                    require(
                        IERC1155(_collectionAddress).balanceOf(msg.sender, _tokenIds[j]) >=
                            nftCollectionRules.minTokensEligible[j],
                        "erc1155 balance too low"
                    );
                }
            }
            if (_collectionAddress == CRYPTO_PUNKS) {
                for (uint256 j; j < _tokenIds.length; ++j) {
                    require(
                        ICryptoPunks(_collectionAddress).punkIndexToAddress(_tokenIds[j]) == msg.sender,
                        "not the owner"
                    );
                    require(!_data.nftId[_collectionAddress][_tokenIds[j]], "tokenId already used");
                    _data.nftId[_collectionAddress][_tokenIds[j]] = true;
                    emit BlacklistNFT(_collectionAddress, _tokenIds[j]);
                }
            }
        }

        require(_purchaseTokenAmount <= maxPurchaseTokenAmount, "purchase amount greater than max allocation");

        return (maxPurchaseTokenAmount);
    }

    event PoolWith721(address indexed collectionAddress, uint256 purchaseAmount, bool purchaseAmountPerToken);

    event PoolWith1155(
        address indexed collectionAddress,
        uint256 purchaseAmount,
        bool purchaseAmountPerToken,
        uint256[] tokenIds,
        uint256[] minTokensEligible
    );
    event BlacklistNFT(address indexed collection, uint256 nftID);
}