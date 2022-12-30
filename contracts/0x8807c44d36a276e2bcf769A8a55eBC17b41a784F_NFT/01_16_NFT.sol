// SPDX-License-Identifier: bsl-1.1
/**
 * Copyright 2022 Raise protocol ([email protected])
 */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./INFTFactory.sol";
import "./INFT.sol";

/**
 * @dev since we use light proxies for deploy NFT collections we have to use ERC721Upgradeable parent contract
 * This contract is IERC721 compatible
 */
contract NFT is OwnableUpgradeable, ERC721Upgradeable, INFT {

    // 1 = 100% = 10000 basis points
    uint16 private constant SHARES_100_PERCENT_IN_BP = 100 * 100;
    bytes32 public constant override isNFTFactoryNFT = keccak256("NFTFactoryNFT");
    INFTFactory public immutable nftFactory;

    RoundInfo[] internal roundInfo;
    mapping(uint => TokenInfo) internal tokenInfo;
    uint internal maxTokenId;

    uint16 public override totalMintedSharesBasisPoints;

    constructor(INFTFactory _nftFactory) {
        nftFactory = _nftFactory;
    }

    function initialize(address _ownersAddress, string memory _name, string memory _symbol) initializer public {
        require(_ownersAddress != address(0), "NFT: ZERO_ADDRESS");
        require(_validString(_name), "NFT: INVALID_NAME");
        require(_validString(_symbol), "NFT: INVALID_SYMBOL");

        __ERC721_init(_name, _symbol);

        // __Ownable_init(); // disabled to save gas since there is only setting owner to msg.sender here
        _transferOwnership(_ownersAddress);
    }

    function owner() public view override(INFT, OwnableUpgradeable) returns (address) {
        return super.owner();
    }

    function name() public view override(INFT, ERC721Upgradeable) returns (string memory) {
        return super.name();
    }

    function symbol() public view override(INFT, ERC721Upgradeable) returns (string memory) {
        return super.symbol();
    }

    function getRoundInfo(uint _roundId) public view override returns (RoundInfo memory) {
        return roundInfo[_roundId];
    }

    /**
     * @notice Token ids start from 1
     * @dev in case of possible issues with wallets, explorers etc
     **/
    function getTokenInfo(uint _tokenId) public view override returns (TokenInfo memory) {
        require(_exists(_tokenId), "NFT: NONEXISTENT_TOKEN");

        return tokenInfo[_tokenId];
    }

    function getRoundsCount() public view override returns (uint) {
        return roundInfo.length;
    }

    function getMaxTokenId() public view override returns (uint) {
        return maxTokenId;
    }

    function addRoundAndMint(
        uint128 _valuation, uint16 _maxRoundShareBasisPoints, string memory _roundName, uint32 _roundStartTS,
        address _to, uint16[] memory _sharesBasisPoints
    ) public onlyOwner returns(uint32 roundId, uint[] memory mintedIds) {
        roundId = addRound(_valuation, _maxRoundShareBasisPoints, _roundName, _roundStartTS);
        mintedIds = mint(_to, roundId, _sharesBasisPoints);
    }

    function addRound(uint128 _valuation, uint16 _maxRoundShareBasisPoints, string memory _roundName, uint32 _roundStartTS)
        public onlyOwner returns(uint32 _roundId)
    {
        uint roundId = roundInfo.length;
        require(roundId < type(uint32).max, "NFT: MAX_AMOUNT_OF_ROUNDS");

        require(_valuation > 0, "NFT: ZERO_VALUATION");

        require(_maxRoundShareBasisPoints > 0, "NFT: ZERO_MAX_ROUND_SHARE");
        require(_maxRoundShareBasisPoints <= SHARES_100_PERCENT_IN_BP, "NFT: MAX_ROUND_SHARES_MORE_THAN_100_PERCENT");

        require(_validString(_roundName), "NFT: INVALID_ROUND_NAME");

        _roundId = uint32(roundId);
        roundInfo.push(RoundInfo(_valuation, _maxRoundShareBasisPoints, 0, _roundStartTS, _roundName));

        emit RoundAdded(_roundId, _valuation, _maxRoundShareBasisPoints, _roundName);
    }

    function mint(address _to, uint32 _roundId, uint16[] memory _sharesBasisPoints)
        public onlyOwner returns (uint[] memory mintedIds)
    {
        require(_roundId < uint32(roundInfo.length), "NFT: INVALID_ROUND");
        require(_sharesBasisPoints.length > 0, "NFT: EMPTY_SHARES");

        IWithBalance requiredTokenToMint = nftFactory.requiredTokenToMint();
        if (address(requiredTokenToMint) != address(0)) {
            require(requiredTokenToMint.balanceOf(msg.sender) >= nftFactory.requiredTokenToMintAmount(), "NFT: NOT_ENOUGH_TOKEN_TO_MINT");
        }

        mintedIds = new uint[](_sharesBasisPoints.length);

        RoundInfo storage round = roundInfo[_roundId];
        uint128 roundValuation = round.valuation;
        uint16 newTotalMintedSharesBP = totalMintedSharesBasisPoints;
        uint16 newRoundMintedSharesBP = round.mintedSharesBasisPoints;
        uint256 mintedTokenId = maxTokenId; // tokens ids start from 1, will be increased on mint
        for (uint i=0; i<_sharesBasisPoints.length; i++) {
            uint16 shareBasisPoints = _sharesBasisPoints[i];
            require(shareBasisPoints > 0, "NFT: INVALID_SHARE");

            uint128 tokenInitialValuation =  _tokenInitialValuation(roundValuation, shareBasisPoints);
            require(tokenInitialValuation > 0, "NFT: TO_SMALL_SHARE");

            newTotalMintedSharesBP += shareBasisPoints;
            newRoundMintedSharesBP += shareBasisPoints;

            _mint(_to, ++mintedTokenId);
            tokenInfo[mintedTokenId] = TokenInfo(_roundId, shareBasisPoints, tokenInitialValuation);
            mintedIds[i] = mintedTokenId;
        }
        require(newTotalMintedSharesBP <= SHARES_100_PERCENT_IN_BP, "NFT: TOTAL_SHARES_MORE_THAN_100_PERCENT");
        require(newRoundMintedSharesBP <= round.maxRoundSharesBasisPoints, "NFT: ROUND_SHARES_MORE_THAN_MAX_ROUND_SHARES");

        maxTokenId = mintedTokenId;
        totalMintedSharesBasisPoints = newTotalMintedSharesBP;
        round.mintedSharesBasisPoints = newRoundMintedSharesBP;
    }

    function burn(uint256 _tokenId) public {
        require(_exists(_tokenId), "NFT: NONEXISTENT_TOKEN");
        require(ownerOf(_tokenId) == msg.sender, "NFT: AUTH_FAILED");

        _burn(_tokenId);

        delete tokenInfo[_tokenId];
    }

    function burnMany(uint256[] memory _tokenIds) public {
        require(_tokenIds.length > 0, "NFT: INVALID_LENGTH");

        for(uint i=0; i<_tokenIds.length; i++) {
            burn(_tokenIds[i]);
        }
    }

    /**
     * @notice burns token and decreases mintedSharesBasisPoints and totalMintedSharesBasisPoints
     * Should be used in case of mint by error or unsold items
     */
    function burnByCollectionOwner(uint256 _tokenId) public onlyOwner {
        require(_exists(_tokenId), "NFT: NONEXISTENT_TOKEN");
        require(ownerOf(_tokenId) == msg.sender, "NFT: AUTH_FAILED");

        _burn(_tokenId);

        TokenInfo storage token = tokenInfo[_tokenId];
        RoundInfo storage round = roundInfo[token.roundId];

        uint16 tokenShareBasisPoints = token.shareBasisPoints;

        require(round.mintedSharesBasisPoints >= tokenShareBasisPoints, "NFT: BROKEN_ROUND_SHARES");
        round.mintedSharesBasisPoints -= tokenShareBasisPoints;

        require(totalMintedSharesBasisPoints >= tokenShareBasisPoints, "NFT: BROKEN_TOTAL_MINTED_SHARES");
        totalMintedSharesBasisPoints -= tokenShareBasisPoints;

        delete tokenInfo[_tokenId];
    }

    /**
     * @notice burns token and decreases mintedSharesBasisPoints and totalMintedSharesBasisPoints
     * Should be used in case of mint by error or unsold items
     */
    function burnByCollectionOwnerMany(uint256[] memory _tokenIds) public onlyOwner {
        require(_tokenIds.length > 0, "NFT: INVALID_LENGTH");

        for(uint i=0; i<_tokenIds.length; i++) {
            burnByCollectionOwner(_tokenIds[i]);
        }
    }

    function tokenURI(uint256 tokenId) public view override(ERC721Upgradeable, INFT) returns (string memory) {
        require(_exists(tokenId), "NFT: NONEXISTENT_TOKEN");

        return nftFactory.nftRepresentation().getTokenUri(this, tokenId);
    }

    /**
     * @dev see https://docs.opensea.io/docs/contract-level-metadata
     **/
    function contractURI() public view returns (string memory) {
        return nftFactory.nftRepresentation().getContractUri(this);
    }

    function getTokenInfoExtended(uint256 _tokenId) public view override returns (
        TokenInfo memory _tokenInfo,
        RoundInfo memory _roundInfo,
        address _ownersAddress
    ) {
        require(_exists(_tokenId), "NFT: NONEXISTENT_TOKEN");

        _tokenInfo = tokenInfo[_tokenId];
        _roundInfo = roundInfo[_tokenInfo.roundId];
        _ownersAddress = ownerOf(_tokenId);
    }

    function getTokensInfoExtended(uint256[] memory _tokensIds) public view override returns (
        TokenInfo[] memory _tokensInfo,
        RoundInfo[] memory _roundsInfo,
        address[] memory _ownersAddresses
    ) {
        _tokensInfo = new TokenInfo[](_tokensIds.length);
        _roundsInfo = new RoundInfo[](_tokensIds.length);
        _ownersAddresses = new address[](_tokensIds.length);

        for (uint i=0; i<_tokensIds.length; i++) {
            // for nonexisting tokens zero structs would be returned. For mass check
            _tokensInfo[i] = tokenInfo[_tokensIds[i]];
            _roundsInfo[i] = _tokensInfo[i].shareBasisPoints > 0 ? roundInfo[_tokensInfo[i].roundId] : RoundInfo(0, 0, 0, 0, '');
            _ownersAddresses[i] = _tokensInfo[i].shareBasisPoints > 0 ? ownerOf(_tokensIds[i]) : address(0);
        }
    }

    function transferOwnership(address newOwner) public override /* onlyOwner */ { // ownership is checked in parent call
        address oldOwner = owner();
        super.transferOwnership(newOwner);

        nftFactory.trackNftContractOwners(oldOwner, newOwner);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        nftFactory.trackTokenTransfer(owner(), from, to, tokenId);
    }

    function _tokenInitialValuation(uint128 _roundValuation, uint16 tokenShareBp) internal pure returns (uint128) {
        return _roundValuation * uint128(tokenShareBp) / uint128(SHARES_100_PERCENT_IN_BP);
    }

    function _validString(string memory _str) internal pure returns (bool) {
        bytes memory strBytes = bytes(_str);
        if (bytes(_str).length == 0 || strBytes.length > type(uint8).max) {
            return false;
        }

        for (uint8 i = 0; i < strBytes.length; i++) {
            bool isOk =
                   strBytes[i] >= bytes1('a') && strBytes[i] <= bytes1('z')
                || strBytes[i] >= bytes1('A') && strBytes[i] <= bytes1('Z')
                || strBytes[i] >= bytes1('0') && strBytes[i] <= bytes1('9')
                || strBytes[i] == '-'
                || strBytes[i] == ' '
                || strBytes[i] == '_';

            if (!isOk) {
                return false;
            }
        }
        return true;
    }
}