// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract SybilSamurai is ERC721Enumerable, Ownable {
    
    uint256 public maxSamuraiMintValue = 1000001;
    uint256 public totalSamuraiValueMinted;
    uint256 public teamMintedCount;

    mapping(uint256 => uint256) public tierValueUSD;
    mapping(uint256 => uint256) public tokenIdToTier;
    mapping(uint256 => uint256) public tierToEthValue;
    mapping(address => bool) public hasWhitelistedMinted;

    uint256 public ethPrice;

    bool public whitelistMintOpen; 
    bool public publicMintOpen;

    string public baseURI;
    bytes32 public root;

    constructor() ERC721("Sybil Samurai", "Sybil Samurai") {
        tierValueUSD[1] = 50;
        tierValueUSD[2] = 300;
        tierValueUSD[3] = 1500;

        whitelistMintOpen = false;
        publicMintOpen = false;

        baseURI = "ipfs://bafybeifnek24coy5xj5qabdwh24dlp5omq34nzgvazkfyxgnqms4eidsiq/";
    }

    function setRoot(bytes32 newRoot) public onlyOwner {
        root = newRoot;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function setEthPrice(uint256 newPrice) external onlyOwner {
        ethPrice = newPrice;
        updateTierEthPrices();
    }

    function updateTierEthPrices() private {
        for(uint8 i = 1; i <= 3; i++) {
            tierToEthValue[i] = tierValueUSD[i] * 1 ether / ethPrice;
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist.");
        uint256 tier = tokenIdToTier[tokenId];
        return string(abi.encodePacked(baseURI, Strings.toString(tier), ".json"));
    }

    function isValid(bytes32[] memory proof, bytes32 leaf) private view returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    function setWhitelistMintAllowed(bool status) external onlyOwner {
        require(ethPrice > 0, "Set ETH Price");
        whitelistMintOpen = status;
    }

    function setPublicMintAllowed(bool status) external onlyOwner {
        require(ethPrice > 0, "Set ETH Price");
        publicMintOpen = status;
    }

    function publicMintSamurai(uint256 quantity, uint8 tier) external payable {
        require(msg.sender == tx.origin, "No smart contract bots, cheeky Samurai");
        uint256 mintValueInEth = tierToEthValue[tier] * quantity;
        uint256 mintValueInUSD = tierValueUSD[tier] * quantity;

        require(publicMintOpen, "Public mint not open");
        require(quantity > 0 && quantity < 11, "Quantity must be between 1 and 10 (inclusive)");
        require(msg.value >= mintValueInEth, "Incorrect ether sent");
        require(maxSamuraiMintValue > totalSamuraiValueMinted + mintValueInUSD, "Mint HC reached");
        require(tier > 0 && tier < 4, "Invalid Tier");

        mintTier(quantity, tier);
        totalSamuraiValueMinted += mintValueInUSD;

        if (msg.value > mintValueInEth) {
         payable(msg.sender).transfer(msg.value - mintValueInEth);
        }
    }

    function mintWLSamurai(bytes32[] memory proof) external payable {
        require(msg.sender == tx.origin, "No smart contract bots, cheeky Samurai");
        uint256 mintValue = tierToEthValue[2];
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        require(whitelistMintOpen, "WL not open yet Samurai");
        require(isValid(proof, leaf), "Not a WL address");
        require(msg.value >= mintValue, "Incorrect ether sent");
        require(!hasWhitelistedMinted[msg.sender], "Already minted an NFT");

        mintTier(1, 2);

        totalSamuraiValueMinted += 300;
        hasWhitelistedMinted[msg.sender] = true;

        if (msg.value > mintValue) {
         payable(msg.sender).transfer(msg.value - mintValue);
        }
    }

    function mintTeam(uint256 quantity, uint8 tier) external onlyOwner {
        require(teamMintedCount + quantity <= 200, "Team mint limit exceeded");
        mintTier(quantity, tier);
        teamMintedCount += quantity;
    }

    function mintTier(uint256 quantity, uint8 tier) private {
        uint256 totalSupply = _owners.length;
        for (uint256 i; i < quantity; i++) {
         _mint(_msgSender(), totalSupply + i, tier);
        }
    }

    function _mint(address to, uint256 tokenId, uint256 tier) internal virtual {
        super._mint(to, tokenId);
        tokenIdToTier[tokenId] = tier;
    }

    function withdraw(address payable safeAddress) external onlyOwner {
        (bool success, ) = safeAddress.call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    function withdrawERC20(address tokenAddress, address to, uint256 amount) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(to, amount), "Transfer failed");
    }

    function withdrawERC721(address tokenAddress, address to, uint256 tokenId) external onlyOwner {
        IERC721 token = IERC721(tokenAddress);
        token.safeTransferFrom(address(this), to, tokenId);
    }
}