//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
//import "hardhat/console.sol";


contract WAGMAM is ERC1155, Ownable, ReentrancyGuard {

    /// @dev Stores the information about a token
    struct TokenInfo {
        uint256 tokenId;
        uint256 mintedAmount;
        uint256 maxSupply;
        string uri;
    }

    /// @dev The max supply allowed to be minted for the tokens.
    mapping(uint256 => TokenInfo) public tokenInfo;

    /// @dev Stores the minted amount for a given account, as team or public.
    mapping(address => mapping(uint256 => uint256)) public mintedAmount;

    /// @dev Stores the merkle root of each drop.
    mapping(uint256 => bytes32) public dropMerkleRoot;

    /// @dev Stores the url of the contract level metadata
    string _contractURI;

    constructor() ERC1155("") {
    }

    /// @dev Mint the amount of tokens to the recipient. `maxAmount` is the max amount for the account and is used for proof verification
    function mint(uint256 pDrop, uint256 pTokenId, address pRecipient, uint256 amount, bytes32[] memory pProof) external nonReentrant {
        TokenInfo storage token = tokenInfo[pTokenId];
        require(token.maxSupply > 0, "not mintable or not set");
        require(token.mintedAmount + amount <= token.maxSupply, "exceeds max supply");
        require(mintedAmount[pRecipient][pTokenId] == 0, "already minted");
        require(MerkleProof.verify(pProof, dropMerkleRoot[pDrop],
                    keccak256(abi.encodePacked(pTokenId, pRecipient, amount))), "not allowed or invalid proof");


        _mint(pRecipient, pTokenId, amount, "");
        
        tokenInfo[pTokenId].mintedAmount += amount;
        mintedAmount[pRecipient][pTokenId] = amount;
    }

    /// @dev Set the maximum supply of a token for public and team distribution.
    function setMaxTokenSupply(uint256 tokenId, uint256 maxSupply) external onlyOwner nonReentrant {
        TokenInfo memory info = tokenInfo[tokenId];
        info.maxSupply = maxSupply;
        tokenInfo[tokenId] = info;
    }

    /// @dev Set the URI of a token.
    function setTokenUri(uint256 tokenId, string memory tokenUri) external onlyOwner nonReentrant {
        tokenInfo[tokenId].uri = tokenUri;
    }

    /// @dev Return the URI of a token.
    function uri(uint256 tokenId) public view override returns (string memory) {
        return tokenInfo[tokenId].uri;
    }

    /// @dev Set the token info.
    function setTokenInfo(uint256 tokenId, uint256 maxSupply, string memory tokenUri) external onlyOwner nonReentrant {
        tokenInfo[tokenId].maxSupply = maxSupply;
        tokenInfo[tokenId].uri = tokenUri;
    }

    /// @dev Sets the merkle root for a specific token
    function setMerkleRoot(uint256 pDrop, bytes32 pRoot) external onlyOwner {
        dropMerkleRoot[pDrop] = pRoot;
    }

    /// @dev Gets the merkle root of the whitelist 
    function getMerkleRoot(uint256 pDrop) external view returns(bytes32) {
        return dropMerkleRoot[pDrop];
    }

    /// @dev Sets the contract level metadata
    function setContractURI(string memory pContractUri) external onlyOwner {
        _contractURI = pContractUri;
    }

    /// @dev Gets the contract metadata URI
    function contractURI() external view returns (string memory) {
        return _contractURI;
    }
}