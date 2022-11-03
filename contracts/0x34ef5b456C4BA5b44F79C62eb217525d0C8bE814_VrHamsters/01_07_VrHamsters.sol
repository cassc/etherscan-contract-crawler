// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract VrHamsters is ERC721A, Ownable {
    using SafeMath for uint256;

    bytes32 public merkleRoot;

    bool public revealed = false;
    bool public mintActive = false;
    bool public whitelistedMintActive = false;

    string public baseURI;
    string public nonRevealURI;
    string public uriSuffix = '.json';

    uint256 public price = 0.03 ether;
    uint256 public whitelistedPrice = 0.02 ether;

    uint256 public mintLimit = 5;
    uint256 public maxSupply = 5555;

    constructor() ERC721A("VR Hamsters", "VRH") {}

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if (!revealed) {
            return nonRevealURI;
        }

        string memory URI = baseURI;
        return bytes(URI).length != 0 ? string(abi.encodePacked(URI, _toString(tokenId), uriSuffix)) : '';
    }

    function mint(uint256 quantity) external payable {
        require(mintActive, "The mint is not active.");
        require(totalSupply().add(quantity) <= maxSupply, "The requested mint quantity exceeds the supply.");
        require(_numberMinted(msg.sender).add(quantity) <= mintLimit, "The requested mint quantity exceeds the mint limit.");
        require(price.mul(quantity) <= msg.value, "Not enough ETH for mint transaction.");

        _mint(msg.sender, quantity);
    }

    function whitelistMint(uint256 quantity, bytes32[] calldata merkleProof) external payable {
        require(whitelistedMintActive, "The mint is not active.");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "Invalid merkle proof.");
        require(totalSupply().add(quantity) <= maxSupply, "The requested mint quantity exceeds the supply.");
        require(_numberMinted(msg.sender).add(quantity) <= mintLimit, "The requested mint quantity exceeds the mint limit.");
        require(whitelistedPrice.mul(quantity) <= msg.value, "Not enough ETH for mint transaction.");

        _mint(msg.sender, quantity);
    }

    function airdrop(address[] memory _addresses) external onlyOwner {
        require(totalSupply().add(_addresses.length) <= maxSupply, "The requested mint quantity exceeds the supply.");

        for (uint256 i = 0; i < _addresses.length; i++) {
            _mint(_addresses[i], 1);
        }
    }

    function mintTo(uint256 _quantity, address _receiver) external onlyOwner {
        require(totalSupply().add(_quantity) <= maxSupply, "The requested mint quantity exceeds the supply.");
        _mint(_receiver, _quantity);
    }

    function adjustMaxSupply(uint256 _maxSupply) external onlyOwner {
        require(_maxSupply >= totalSupply(), "The max supply must be greater than or equal to the current supply.");
        require(_maxSupply <= maxSupply, "The max supply must be less than the current.");
        maxSupply = _maxSupply;
    }

    function fundsWithdraw() external onlyOwner {
        uint256 funds = address(this).balance;
        require(funds > 0, "Insufficient balance.");

        (bool succ,) = payable(0x195332Ae6818c8381a17993b9C0Ac24f25DA7075).call{value : funds}("");
        require(succ, "Transfer failed.");
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

    function setWhitelistedMintActive(bool _whitelistedMintActive) external onlyOwner {
        whitelistedMintActive = _whitelistedMintActive;
    }

    function setBaseUri(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNonRevealUri(string memory _nonRevealURI) external onlyOwner {
        nonRevealURI = _nonRevealURI;
    }

    function setUriSuffix(string memory _uriSuffix) external onlyOwner {
        uriSuffix = _uriSuffix;
    }
}