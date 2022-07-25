// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract LonerBeasts is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_TOKENS = 7777;

    uint256 public price = 0 ether;
    uint256 public maxMint = 3;
    bool public publicSale = false;
    bool public whitelistSale = false;

    mapping(address => uint256) public _whitelistClaimed;

    string public baseURI = "";
    bytes32 public merkleRoot = 0x8bb6d256c7e50e8e92ef2b8cecefee98f701cde8d6065db3ca56150a12504e3e;

    constructor() ERC721A("Loner Beasts", "LNRBST") {
    }

    function toggleWhitelistSale() external onlyOwner {
        whitelistSale = !whitelistSale;
    }

    function togglePublicSale() external onlyOwner {
        publicSale = !publicSale;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    //change max mint 
    function setMaxMint(uint256 _newMaxMint) external onlyOwner {
        maxMint = _newMaxMint;
    }

    //wl only mint
    function whitelistMint(uint256 tokens, bytes32[] calldata merkleProof) external payable {
        require(whitelistSale, "LONER: You can not mint right now");
        require(MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "LONER: Please wait to mint on public sale");
        require(_whitelistClaimed[_msgSender()] + tokens <= maxMint, "LONER: Cannot mint this many CORES");
        require(tokens > 0, "LONER: Please mint at least 1 CORE");
        require(price * tokens == msg.value, "LONER: Not enough ETH");

        _safeMint(_msgSender(), tokens);
        _whitelistClaimed[_msgSender()] += tokens;
    }

    //mint function for public
    function mint(uint256 tokens) external payable {
        require(publicSale, "LONER: Public sale has not started");
        require(tokens <= maxMint, "LONER: Cannot purchase this many tokens in a transaction");
        require(totalSupply() + tokens <= MAX_TOKENS, "LONER: Exceeded supply");
        require(tokens > 0, "LONER: Please mint at least 1 CORE");
        require(price * tokens == msg.value, "LONER: Not enough ETH");
        _safeMint(_msgSender(), tokens);
    }

    // Owner mint has no restrictions. use for giveaways, airdrops, etc
    function ownerMint(address to, uint256 tokens) external onlyOwner {
        require(totalSupply() + tokens <= MAX_TOKENS, "LONER: Minting would exceed max supply");
        require(tokens > 0, "LONER: Must mint at least one token");
        _safeMint(to, tokens);
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
  }
}