// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/[email protected]/access/Ownable.sol";
import "./lib/ERC721EnumerableMod.sol";

error InvalidEtherValue();
error MaxTokensMinted();
error ContractIsLocked();
error InvalidParameter();
error MaxBaycClaimed();
error MaxMaycClaimed();
error MaxBakcClaimed();
error TokenIdDoesNotExist();

/**
 * @title Open BAYC Sewer Pass ERC-721 Smart Contract
 */
contract OpenBAYCSewerPass is ERC721EnumerableMod, Ownable {
    uint64 private _totalSupply;
    uint64 public constant MAX_TOKENS = 30000;
    uint64 public constant MAX_BAYC = 10000;
    uint64 public constant MAX_MAYC = 20000;
    uint64 public constant MAX_BAKC = 10000;
    uint256 public constant BASE_PRICE = 1e16;
    bool public contractIsLocked;
    string private baseURI;
    uint64 public baycClaimed;
    uint64 public maycClaimed;
    uint64 public bakcClaimed;
    uint64 private _reserved = 2000;
    mapping(uint256 => uint256) public tokenIdtoMintData;

    event SewerPassMinted(
        uint256 indexed sewerPassTokenId,
        uint256 indexed tier,
        uint256 indexed baycMaycTokenId,
        uint256 bakcTokenId
    );

    constructor(
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {}

    /**
     * @notice Mint a Sewer Pass
     */
    function mintSewerPass(
        uint256 tier
    ) external payable {
        if (msg.value < tier * BASE_PRICE) revert InvalidEtherValue();

        _mintSewerPass(tier);
    }

    function _mintSewerPass(
        uint256 tier
    ) private {
        if (_totalSupply + _reserved >= MAX_TOKENS) revert MaxTokensMinted();
        if (contractIsLocked) revert ContractIsLocked();
        if (tier < 1 || tier > 4) revert InvalidParameter();

        uint256 baycMaycTokenId;
        if (tier > 2) {
            if (baycClaimed >= MAX_BAYC) revert MaxBaycClaimed();
            baycMaycTokenId = baycClaimed;
            ++baycClaimed;
        } else {
            if (maycClaimed >= MAX_MAYC) revert MaxMaycClaimed();
            baycMaycTokenId = maycClaimed;
            ++maycClaimed;
        }

        uint256 bakcTokenId;
        if (tier == 2 || tier == 4) {
            if (bakcClaimed >= MAX_BAKC) revert MaxBakcClaimed();
            bakcTokenId = bakcClaimed;
            ++bakcClaimed;
        } else {
            bakcTokenId = MAX_BAKC;
        }

        // prepare mint data for storage
        uint256 mintData = tier;
        mintData |= baycMaycTokenId << 64;
        mintData |= bakcTokenId << 128;

        uint256 tokenId = _totalSupply;
        ++_totalSupply;
        tokenIdtoMintData[tokenId] = mintData;
        _safeMint(msg.sender, tokenId);

        emit SewerPassMinted(
            tokenId,
            tier,
            baycMaycTokenId,
            bakcTokenId
        );
    }

    /**
     * @notice Get the data from token mint by token id
     * @param tokenId the token id
     * @return tier game pass tier
     * @return apeTokenId tier 1 & 2 mayc token id, tier 3 & 4 bayc token id
     * @return dogTokenId bakc token id, if 10000 dog was not used in claim
     */
    function getMintDataByTokenId(
        uint256 tokenId
    )
        external
        view
        returns (uint256 tier, uint256 apeTokenId, uint256 dogTokenId)
    {
        if (!_exists(tokenId)) revert TokenIdDoesNotExist();

        uint256 mintData = tokenIdtoMintData[tokenId];
        tier = uint256(uint64(mintData));
        apeTokenId = uint256(uint64(mintData >> 64));
        dogTokenId = uint256(uint64(mintData >> 128));
    }

    /**
     * @notice Get token ids by wallet
     * @param _owner the address of the owner
     */
    function tokenIdsByWallet(
        address _owner
    ) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    /**
     * @notice Check if a token exists
     */
    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @notice Get the total supply of tokens
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    // operator functions

    /**
     * @notice Lock the contract - stops minting
     * KILL SWITCH - THIS CAN'T BE REVERSED
     */
    function lockContract() external onlyOwner {
        contractIsLocked = true;
    }

    /**
     * @notice Set base uri of metadata
     * @param uri the base uri of the metadata store
     */
    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function mintReserved(
        uint256 tier,
        uint64 count
    ) external onlyOwner {
        if (count > _reserved) revert InvalidParameter();
        _reserved -= count;
        for (uint256 i = 0; i < count; i++) {
            _mintSewerPass(tier);
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // Function overrides

    /**
     * @notice override _baseURI function
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}