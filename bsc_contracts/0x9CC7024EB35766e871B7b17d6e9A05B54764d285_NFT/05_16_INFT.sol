// SPDX-License-Identifier: bsl-1.1
/**
 * Copyright 2022 Raise protocol ([email protected])
 */
pragma solidity ^0.8.0;
pragma abicoder v2;


interface INFT {

    struct RoundInfo {
        uint128 valuation;
        uint16 maxRoundSharesBasisPoints;
        uint16 mintedSharesBasisPoints;
        uint32 startTS;
        string name;
    }

    struct TokenInfo {
        uint32 roundId;
        uint16 shareBasisPoints;
        uint128 shareInitialValuation;
    }

    event RoundAdded(uint32 roundId, uint128 valuation, uint16 maxRoundShareBasisPoints, string name);

    function totalMintedSharesBasisPoints() external view returns (uint16);

    /// @notice owner of collection
    function owner() external view returns (address);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);

    function getRoundInfo(uint _roundId) external view returns (RoundInfo memory);
    function getTokenInfo(uint _tokenId) external view returns (TokenInfo memory);
    /// @notice get full info about token (including round info and owner)
    function getTokenInfoExtended(uint256 tokenId) external view returns (
        TokenInfo memory _tokenInfo,
        RoundInfo memory  _roundInfo,
        address _ownersAddress
    );
    /// @notice get full info about tokens (including round info and owner)
    function getTokensInfoExtended(uint256[] memory _tokensIds) external view returns (
        TokenInfo[] memory _tokensInfo,
        RoundInfo[] memory _roundsInfo,
        address[] memory _ownersAddresses
    );

    function getRoundsCount() external view returns (uint);
    function getMaxTokenId() external view returns (uint);

    /**
     * @notice returns token info as json using data url
     * @dev see https://docs.opensea.io/docs/metadata-standards
     **/
    function tokenURI(uint256 tokenId) external view returns (string memory);

    /**
     * @notice returns contract info as json using data url
     * @dev see https://docs.opensea.io/docs/contract-level-metadata
     **/
    function contractURI() external view returns (string memory);


    function addRound(uint128 _valuation, uint16 _maxRoundShareBasisPoints, string memory _roundName, uint32 _roundStartTS)
        external returns(uint32 _roundId);
    function mint(address _to, uint32 _roundId, uint16[] memory _sharesBasisPoints)
        external returns (uint[] memory mintedIds);
    function addRoundAndMint(
        uint128 _valuation, uint16 _maxRoundShareBasisPoints, string memory _roundName, uint32 _roundStartTS,
        address _to, uint16[] memory _sharesBasisPoints
    ) external returns(uint32 roundId, uint[] memory mintedIds);

    /**
     * @notice burns token by owner. Do not decreases round.mintedSharesBasisPoints and totalMintedSharesBasisPoints
     * Common case of usage - burn during swap to project token
     */
    function burn(uint256 _tokenId) external;
    /**
     * @notice burns tokens by owner. Do not decreases round.mintedSharesBasisPoints and totalMintedSharesBasisPoints
     * Common case of usage - burn during swap to project token
     */
    function burnMany(uint256[] memory _tokenIds) external;

    /**
     * @notice burns token by owner if owner is a collection ownet.
     * Decreases round.mintedSharesBasisPoints and totalMintedSharesBasisPoints
     * Common case of usage - burn minted by mistake or unsold tokens
     */
    function burnByCollectionOwner(uint256 _tokenId) external;
    /**
     * @notice burns tokens by owner if owner is a collection ownet.
     * Decreases round.mintedSharesBasisPoints and totalMintedSharesBasisPoints
     * Common case of usage - burn minted by mistake or unsold tokens
     */
    function burnByCollectionOwnerMany(uint256[] memory _tokenIds) external;

    /**
     * @dev marker for checks that nft token deployed by factory
     * @dev must return keccak256("NFTFactoryNFT")
     */
    function isNFTFactoryNFT() external view returns (bytes32);
}