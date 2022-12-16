// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract Future is ERC721A, Ownable {
    using SafeMath for uint256;

    bytes32 public merkleRoot;

    bool public revealed = false;
    bool public mintActive = false;

    string public baseURI;
    string public nonRevealURI;

    uint256 public price;

    uint256 public maxSupply;

    constructor() ERC721A("FUTURE NFT", "FTR") {
        price = 0.0099 ether;
        maxSupply = 1111;

        merkleRoot = 0x712666e13fbd6e5c31b4773862675ea161c645dbb04ad13e0a9e7676e3d309bf;
        nonRevealURI = 'https://future-nft.nyc3.digitaloceanspaces.com/reveal/json/';
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if (!revealed) {
            return bytes(nonRevealURI).length != 0 ? string(abi.encodePacked(nonRevealURI, _toString(tokenId), '.json')) : '';
        }

        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), '.json')) : '';
    }

    function mint(uint256 quantity) external payable {
        require(mintActive, "The mint is not active.");
        require(totalSupply().add(quantity) <= maxSupply, "The requested mint quantity exceeds the supply.");
        uint256 ethValue = _numberMinted(msg.sender) >= 1 ? price.mul(quantity) : price.mul(quantity.sub(1));
        require(ethValue <= msg.value, "Not enough ETH for mint transaction.");

        _mint(msg.sender, quantity);
    }

    function whitelistMint(uint256 quantity, bytes32[] calldata merkleProof) external payable {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "Invalid merkle proof.");
        require(totalSupply().add(quantity) <= maxSupply, "The requested mint quantity exceeds the supply.");
        uint256 ethValue = _numberMinted(msg.sender) >= 1 ? price.mul(quantity) : price.mul(quantity.sub(1));
        require(ethValue <= msg.value, "Not enough ETH for mint transaction.");

        _mint(msg.sender, quantity);
    }

    function mintTo(uint256 _quantity, address _receiver) external onlyOwner {
        require(totalSupply().add(_quantity) <= maxSupply, "The requested mint quantity exceeds the supply.");
        _mint(_receiver, _quantity);
    }

    function fundsWithdraw() external onlyOwner {
        uint256 funds = address(this).balance;
        require(funds > 0, "Insufficient balance.");

        (bool status,) = payable(msg.sender).call{value : funds}("");
        require(status, "Transfer failed.");
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setRevealed(bool _revealed) external onlyOwner {
        revealed = _revealed;
    }

    function setMintActive(bool _mintActive) external onlyOwner {
        mintActive = _mintActive;
    }

    function setBaseUri(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNonRevealUri(string memory _nonRevealURI) external onlyOwner {
        nonRevealURI = _nonRevealURI;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }
}