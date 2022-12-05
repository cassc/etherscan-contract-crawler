// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

interface IYogurtVerse {
  function ownerOf(uint256 tokenId) external returns (address);
}

contract gurts is ERC721A, ERC721AQueryable, Ownable {
    IYogurtVerse public constant yvContract = IYogurtVerse(0xC34CC9f3Cf4E1F8DD3cde01BBE985003dcFc169f);

    uint256 public constant maxSupply = 4444;
    uint256 public constant maxWhitelist = 3012;

    uint256 public constant maxClaimSupply = 321;
    uint256 public claimSupply = 0;

    uint256 public price = 0.015 ether;
    string public baseURI = "";
    bool public privateSale = false;
    bool public publicSale = false;
    bool public claimSale = false;

    mapping(address => bool) public hasMintedPublic;
    mapping(address => bool) public hasMintedWhitelist;

    mapping(uint256 => bool) public passHasClaimed;

    

    bytes32 merkleRoot;

    constructor() ERC721A("Gurts", "GURT") {}

    function whitelistMint(bytes32[] calldata _merkleProof) payable external {
        address _caller = msg.sender;
        require(privateSale, "Private sale not live");
        require(maxWhitelist >= totalSupply() + 1, "Exceeds max WL supply");
        require(msg.value == price, "Wrong ether amount sent");
        require(tx.origin == _caller, "No contracts");
        require(!hasMintedWhitelist[_caller], "Already minted");

        bytes32 node = keccak256(abi.encodePacked(_caller));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, node),
            "Invalid proof"
        );

        hasMintedWhitelist[_caller] = true;
        _mint(_caller, 1);
    }

    function publicMint() payable external {
        address _caller = msg.sender;
        require(publicSale, "Public sale not live");
        require(maxSupply - maxClaimSupply >= (totalSupply() - claimSupply) + 1, "Exceeds max supply");
        require(msg.value == price, "Wrong ether amount sent");
        require(tx.origin == _caller, "No contracts");
        require(!hasMintedPublic[_caller], "Already minted");

        hasMintedPublic[_caller] = true;
        _mint(_caller, 1);
    }

    function passMint(uint256[] memory tokenIds) external {
        address _caller = msg.sender;
        require(claimSale, "Claim not live");
        require(maxSupply >= totalSupply() + tokenIds.length, "Exceeds max supply");
        require(tx.origin == _caller, "No contracts");
        require(tokenIds.length > 0, "must have atleast 1 token");

        for (uint256 i; i < tokenIds.length; i++) {
            uint256 currentId = tokenIds[i];
            require(!passHasClaimed[currentId], "Already claimed");
            require(yvContract.ownerOf(currentId) == _caller, "Not owner of token");
            
            passHasClaimed[currentId] = true;
        }
        claimSupply += tokenIds.length;
        _mint(_caller, tokenIds.length);
    }

    function ownerMint(uint256 _amount, address _to) external onlyOwner {
        require(maxSupply >= totalSupply() + _amount, "Exceeds max supply");
        _mint(_to, _amount);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Failed to send");
    }

    function setPrivateSale(bool _state) external onlyOwner {
        privateSale = _state;
    }

    function setPublicSale(bool _state) external onlyOwner {
        publicSale = _state;
    }

    function setClaimSale(bool _state) external onlyOwner {
        claimSale = _state;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return bytes(baseURI).length > 0 ? string(
            abi.encodePacked(
              baseURI,
              Strings.toString(_tokenId)
            )
        ) : "";
    }
}