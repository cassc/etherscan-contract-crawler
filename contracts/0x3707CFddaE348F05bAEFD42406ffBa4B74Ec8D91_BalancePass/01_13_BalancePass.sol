// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

/// @notice Balance Alpha Pass NFT
/// Mint limits:
/// - there is limit 1 NFT per wallet
/// - using multiple wallets in same transaction through your SC is forbidden, so tx.origin should be direct msg.sender
/// - primary and secondary WL mints (and public mint if hard cap was not reached) will start at specific unix time of block
contract BalancePass is ERC721AQueryable, Ownable {

    using SafeERC20 for IERC20;

    string public baseTokenURI;

    uint public maxMint;
    uint public maxMintWalletLimit;
    uint public whitelist1MintStartTimestamp;
    uint public whitelist2MintStartTimestamp;
    uint public publicMintStartTimestamp;
    bytes32 private whitelist1Root;
    bytes32 private whitelist2Root;
    mapping(address => uint8) public mintWalletLimit;

    mapping(uint8 => uint[][]) public tokenTypeArray;

    ///
    /// events
    ///

    event NftMinted(address indexed _user, uint _tokenId);

    /// @notice one time initialize for the Pass Nonfungible Token
    /// @param _maxMint  uint256 the max number of mints on this chain
    /// @param _maxMintWalletLimit  uint256 the max number of mints per wallet
    /// @param _baseTokenURI string token metadata URI
    /// @param _whitelist1MintStartTimestamp primary WL timestamp
    /// @param _whitelist2MintStartTimestamp secondary WL timestamp
    /// @param _publicMintStartTimestamp public mint timestamp
    /// @param _whitelist1Root bytes32 merkle root for whitelist
    /// @param _whitelist2Root bytes32 merkle root for whitelist
    constructor(
        uint _maxMint,
        uint _maxMintWalletLimit,
        string memory _baseTokenURI,
        uint _whitelist1MintStartTimestamp,
        uint _whitelist2MintStartTimestamp,
        uint _publicMintStartTimestamp,
        bytes32 _whitelist1Root,
        bytes32 _whitelist2Root
    ) ERC721A("Balance Pass", "BALANCE-PASS") {
        maxMint = _maxMint;
        maxMintWalletLimit = _maxMintWalletLimit;
        baseTokenURI = _baseTokenURI;
        whitelist1MintStartTimestamp = _whitelist1MintStartTimestamp;
        whitelist2MintStartTimestamp = _whitelist2MintStartTimestamp;
        publicMintStartTimestamp = _publicMintStartTimestamp;
        whitelist1Root = _whitelist1Root;
        whitelist2Root = _whitelist2Root;
    }

    /// @notice set new metadata uri prefix
    /// @param _baseTokenURI new uri prefix (without /<tokenId>.json)
    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    /// @notice alter existing hard cap
    /// @param _maxMint new hard cap
    function setMaxMint(uint _maxMint) external onlyOwner {
        maxMint = _maxMint;
    }

    /// @notice change maximum allowed images per wallet
    /// @param _maxMintWalletLimit new limit
    function setMaxMintWalletLimit(uint _maxMintWalletLimit) external onlyOwner {
        maxMintWalletLimit = _maxMintWalletLimit;
    }

    /// @notice set unix timestamp when primary WL mint starts
    /// @param _whitelist1MintStartTimestamp unix time in seconds
    function setWhitelist1MintStartTimestamp(uint _whitelist1MintStartTimestamp) external onlyOwner {
        whitelist1MintStartTimestamp = _whitelist1MintStartTimestamp;
    }

    /// @notice set unix timestamp when secondary WL mint starts
    /// @param _whitelist2MintStartTimestamp unix time in seconds
    function setWhitelist2MintStartTimestamp(uint _whitelist2MintStartTimestamp) external onlyOwner {
        whitelist2MintStartTimestamp = _whitelist2MintStartTimestamp;
    }

    /// @notice set unix timestamp when public mint starts
    /// @param _publicMintStartTimestamp unix time in seconds
    function setPublicMintStartTimestamp(uint _publicMintStartTimestamp) external onlyOwner {
        publicMintStartTimestamp = _publicMintStartTimestamp;
    }

    /// @notice set token types of token ID
    /// @param _tokenIdInfo uint256 2d array, example: [[1,10],[11,30]] which means 1 and 10 are in first interval and 11 and 30 are in second
    /// @param _tokenType uint8 0: Genesis 1: Gold 2: Platinum
    function setTokenType(uint[][] memory _tokenIdInfo, uint8 _tokenType) external onlyOwner {
        tokenTypeArray[_tokenType] = _tokenIdInfo;
    }

    /// @notice set merkle root for initial whitelist
    /// @param _whitelist1Root bytes32 merkle root for primary whitelist
    function setWhitelist1Root(bytes32 _whitelist1Root) external onlyOwner {
        whitelist1Root = _whitelist1Root;
    }

    /// @notice set merkle root for secondary whitelist
    /// @param _whitelist2Root bytes32 merkle root for secondary whitelist
    function setWhitelist2Root(bytes32 _whitelist2Root) external onlyOwner {
        whitelist2Root = _whitelist2Root;
    }

    ///
    /// business logic
    ///

    /// @notice generic mint function, if _merkleProof1 is != null its WL1, if _merkleProof2 != null its WL2, otherwise its public mint
    /// @param _merkleProof1 merkle proof array for WL1
    /// @param _merkleProof2 merkle proof array for WL2
    function mint(bytes32[] calldata _merkleProof1, bytes32[] calldata _merkleProof2) external payable returns (uint) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        if (_merkleProof1.length > 0) {
            require(block.timestamp >= whitelist1MintStartTimestamp, "WHITELIST1_MINT_DIDNT_START");

            // verify against merkle root
            require(MerkleProof.verify(_merkleProof1, whitelist1Root, leaf), "BalancePass: Invalid proof");
        } else if (_merkleProof2.length > 0) {
            require(block.timestamp >= whitelist2MintStartTimestamp, "WHITELIST2_MINT_DIDNT_START");

            // verify against merkle root
            require(MerkleProof.verify(_merkleProof2, whitelist2Root, leaf), "BalancePass: Invalid proof");
        } else {
            require(block.timestamp >= publicMintStartTimestamp, "PUBLIC_MINT_DIDNT_START");
        }

        return doMint(true);
    }

    /// @notice owner mint
    function mint_owner() external payable onlyOwner returns (uint) {
        return doMint(false);
    }

    function doMint(bool _limitCheck) internal returns (uint) {
        require(totalSupply() < maxMint, "TOTAL_SUPPLY_REACHED");
        // this should mitigate to use multiple addresses in one transaction
        require(msg.sender == tx.origin, "SMART_CONTRACTS_FORBIDDEN");
        if (_limitCheck) {
            require(mintWalletLimit[msg.sender] + 1 <= maxMintWalletLimit, "MAX_WALLET_LIMIT_REACHED");
        }

        mintWalletLimit[msg.sender] += 1;

        uint tokenId = _nextTokenId();
        _mint(msg.sender, 1);

        emit NftMinted(msg.sender, tokenId);

        return tokenId;
    }

    /// @notice Get the base URI
    function baseURI() public view returns (string memory) {
        return baseTokenURI;
    }

    /// @notice return tokenURI of specific token ID
    /// @param _tokenId tokenid
    /// @return _tokenURI token uri
    function tokenURI(uint _tokenId) public view override(ERC721A, IERC721A) returns (string memory _tokenURI) {
        _tokenURI = string(abi.encodePacked(baseTokenURI, "/", Strings.toString(_tokenId), ".json"));
    }

    /// @notice current Token ID
    function currentTokenId() external view returns (uint256) {
        return _nextTokenId();
    }

    /// @notice return tokenTypes based on tokenId
    /// @param _tokenId uint256
    /// @return token type
    function getTokenType(uint _tokenId) public view returns (string memory) {
        for (uint8 i = 0; i < 3; i++) {
            uint[][] memory temp = tokenTypeArray[i];
            for (uint j = 0; j < temp.length; j++) {
                if (_tokenId >= temp[j][0] && _tokenId <= temp[j][1])
                    if (i == 2) return "Platinum";
                    else if (i == 1) return "Gold";
                    else return "Genesis";
            }
        }
        return "Undefined";
    }

    /// @notice can recover tokens sent by mistake to this CA
    /// @param token CA
    function recoverTokens(IERC20 token) external onlyOwner {
        token.safeTransfer(owner(), token.balanceOf(address(this)));
    }

    function recoverEth() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

}