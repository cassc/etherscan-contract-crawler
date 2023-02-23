// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/utils/Counters.sol";
import "./DesiderNft.sol";
import "./DesiderOG.sol";

contract SpaceRanger is DesiderNft {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    bool public _revealed = false;

    // Constants
    uint256 public constant MAX_SUPPLY = 5500;
    uint256 public constant wlPrice = 0.023 ether;
    uint256 public constant pubPrice = 0.033 ether;
    uint256 public constant maxBalance = 5;
    // time setting
    uint256 private constant pubStart = 1677118980;

    string public baseURI;
    string public notRevealedUri;

    //Merkle
    bytes32 private saleMerkleRoot;

    // record og mint 
    mapping(address => uint256) private _ogmint;
    // record whitelist mint 
    mapping(address => uint256) private _wlmint;

    constructor(address _owner) ERC721("DESIDER SPACE RANGERS", "DSR")
    {
        transferOwnership(_owner);
    }

    function ownerMint(uint256 tokenQuantity, address to) external onlyOwner {
        require(
            totalSupply() + tokenQuantity <= MAX_SUPPLY,
            "Sale would exceed max supply"
        );

        _mintNft(tokenQuantity, to);
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function ogMint() external {
        require(block.timestamp > pubStart, "mint not start");
        uint256 num = _ogmint[msg.sender];
        require(num == 0, "one og can only use once");
        require(totalSupply() + 1 <= MAX_SUPPLY, "Sale would exceed max supply");
        require(balanceOf(msg.sender) + 1 <= maxBalance, "Sale would exceed max balance");

        uint256 ogcheck = DesiderOG(0xAfa3CA7A79091CEbb035f490a51C6bfD45Cb4FC8).balanceOf(msg.sender);
        require(ogcheck >= 1,
            "only og can use this mint"
        );
        _ogmint[msg.sender] = 1;

        _mintNft(1, msg.sender);
    }

    function wlMint(uint256 tokenQuantity, bytes32[] calldata merkleProof) external payable {
        require(block.timestamp > pubStart, "mint not start");
        uint256 num = _wlmint[msg.sender];
        //check max supply
        require(totalSupply() + tokenQuantity <= MAX_SUPPLY, "Sale would exceed max supply");
        //check whitelist mint total limit
        require(num + tokenQuantity <= maxBalance, "one whitelist can only use once");
        //check balance
        require(balanceOf(msg.sender) + tokenQuantity <= maxBalance, "Sale would exceed max balance");
        //check enough eth
        require(tokenQuantity * wlPrice <= msg.value, "Not enough ether sent");

        _wlmint[msg.sender] = _wlmint[msg.sender] +tokenQuantity ;
        _mintWithProof(tokenQuantity, merkleProof, saleMerkleRoot);
    }

    function pubMint(uint256 tokenQuantity) external payable {
        require(block.timestamp > pubStart, "mint not start");
        //check max supply
        require(totalSupply() + tokenQuantity <= MAX_SUPPLY, "Sale would exceed max supply");
        //check balance
        require( balanceOf(msg.sender) + tokenQuantity <= maxBalance, "Sale would exceed max balance");
        //check enough eth
        require(tokenQuantity * pubPrice <= msg.value, "Not enough ether sent");

        _mintNft(tokenQuantity, msg.sender);
    }

    function _mintWithProof(uint256 tokenQuantity, bytes32[] calldata merkleProof, bytes32 merkleRoot) internal isValidMerkleProof(merkleProof, merkleRoot) {
        _mintNft(tokenQuantity, msg.sender);
    }

    function _mintNft(uint256 tokenQuantity, address to) internal {
        for (uint256 i = 0; i < tokenQuantity; i++) {
            // 
            uint256 mintIndex = totalSupply();
            if (mintIndex < MAX_SUPPLY) {
                _tokenIdCounter.increment();
                initTokenId(mintIndex);
                _safeMint(to, mintIndex);
            }
        }
    }

    function ogMintedNum(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _ogmint[owner];
    }

    function wlMintedNum(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _wlmint[owner];
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (_revealed == false) {
            return notRevealedUri;
        }

        string memory _tokenURI = _getTokenUri(tokenId);
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString(), ".json"));
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function flipReveal() external onlyOwner {
        _revealed = !_revealed;
    }

    function setNotRevealedURI(string memory _notRevealedURI) external onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function withdraw(address to) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
    }

    function setSaleMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        saleMerkleRoot = merkleRoot;
    }

}