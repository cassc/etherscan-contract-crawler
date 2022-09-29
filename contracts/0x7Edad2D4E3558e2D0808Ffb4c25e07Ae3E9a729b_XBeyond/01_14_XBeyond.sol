// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract XBeyond is ERC721, Ownable, ReentrancyGuard {

    string public baseURI;
    struct Config {
        uint mintPrice;
        uint redeemPrice;
        bool isMintOpen;
        bool isRedeemOpen;
    }
    
    Config[2] public configs;
    bytes32 public merkleRoot;
    address public paymentToken;
    mapping(uint => mapping(address => bool)) public whitelistUsed;


    struct CollectionConfig {
        address asset;
        address derivAsset;
    }
    mapping(uint256 => CollectionConfig) collections;
    mapping(uint256 => bool) public redeemed;

    constructor(string memory name, string memory symbol, string memory _uri) ERC721(name, symbol) {
        baseURI = _uri;
        collections[1000000] = CollectionConfig(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D, 0xDBfD76AF2157Dc15eE4e57F3f942bB45Ba84aF24);
        collections[2000000] = CollectionConfig(0x60E4d786628Fea6478F785A6d7e704777c86a7c6, 0x69f37e419bD1457d2a25ed3f5d418169caAe8D1F);
    }

    function mint(uint256 collectionId, uint256 tokenId, bool isBend, bytes32[] calldata proof) payable public nonReentrant{
        Config memory _config = checkWl(collectionId, tokenId, proof) ? configs[1] : configs[0];
 
        require(_config.isMintOpen, "Mint not open");
        require(msg.value >= _config.mintPrice, "Invalid payment");
        CollectionConfig memory collection = collections[collectionId];

        IERC721 nft;
        if (isBend) {
            nft = IERC721(collection.derivAsset);
        } else {
            nft = IERC721(collection.asset);
        }

        require(msg.sender == nft.ownerOf(tokenId), 'not owner');
        _safeMint(msg.sender, collectionId  + tokenId);
    }


    function mintAndRedeem(uint256 collectionId, uint256 tokenId, bool isBend, bytes32[] calldata proof) payable external{
        mint(collectionId, tokenId, isBend, proof);
        redeem(collectionId, tokenId, proof);
    }
    
    function checkWl(uint256 collectionId, uint256 tokenId, bytes32[] calldata proof) public view returns (bool) {
        if (proof.length == 0) {
            return false;
        }
        bytes32 node = keccak256(abi.encodePacked(collectionId, tokenId));
        return MerkleProof.verify(proof, merkleRoot, node);
    }

    function redeem(uint256 collectionId, uint256 tokenId, bytes32[] calldata proof) public {
        Config memory _config = checkWl(collectionId, tokenId, proof) ? configs[1] : configs[0];
        require(_config.isRedeemOpen, "not open for this collection");
        require(!redeemed[collectionId + tokenId], "already redeemd");
        require(ownerOf(collectionId+tokenId) == msg.sender, "not owner of nft");

        if (_config.redeemPrice > 0) {
            IERC20(paymentToken).transferFrom(msg.sender, owner(), _config.redeemPrice);
        }
        redeemed[collectionId + tokenId] = true;
    }
   
    function setCollection(uint collectionId, address asset, address bendAsset) external onlyOwner  {
        collections[collectionId] = CollectionConfig(asset, bendAsset);
    }

    // 0 public, 1 whitelist
    function setMintStatus(uint index, bool _isOpen) external onlyOwner {
        configs[index].isMintOpen = _isOpen;
    }

    function setRedeemStatus(uint index, bool _isOpen) external onlyOwner {
        configs[index].isRedeemOpen = _isOpen;
    }

    function setStatus(uint index, bool _isOpen) external onlyOwner {
        configs[index].isRedeemOpen = _isOpen;
        configs[index].isMintOpen = _isOpen;
    }

    function setMintConfig(address _paymentToken, uint _mintPrice, uint _redeemPrice, uint _wlMintPrice, uint _wlRedeemPrice) external onlyOwner  {
        paymentToken = _paymentToken;
        configs[0].mintPrice = _mintPrice;
        configs[0].redeemPrice = _redeemPrice;
        configs[1].mintPrice = _wlMintPrice;
        configs[1].redeemPrice = _wlRedeemPrice;
    }
    
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }
    
    function setBaseURI(string memory base) external onlyOwner {
        baseURI = base;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function withdraw(address token) external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        IERC20(token).transfer(owner(), IERC20(token).balanceOf(address(this)));
        require(success, "Transfer failed.");
    }
    
}