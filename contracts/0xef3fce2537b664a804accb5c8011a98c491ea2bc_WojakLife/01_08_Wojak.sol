// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract WojakLife is ERC721A, Ownable, ReentrancyGuard{
   
    using Strings for uint;

    string public baseURI = "ipfs://QmShvXXYhnYpYaBVrikKvUnBE5i5FWZrmpMD2fvSnv4i7a/";
    
    uint private constant MAX_MINTS = 5;
    uint private constant MAX_FREE_MINTS = 1000;
    uint public FREE_MINTED = 0;
    uint private constant MAX_SUPPLY = 4000;
    uint public mintRate = 0.0069 ether;
    uint private price = 0 ether;

    bool public mintStarted = false;

    mapping (address => bool) public freeWojakMinted;

    bytes32 public merkleRoot;

    address payable [] private payees;

    constructor(bytes32 _merkleRoot, address payable [] memory _addresses) ERC721A("WojakLife", "WJKLF") {
        merkleRoot = _merkleRoot;

        for(uint i = 0; i < _addresses.length; i++)
        {
            payees.push(_addresses[i]);
        }
    }

    function mint(uint256 quantity,bytes32[] memory proof) external payable {

        require(mintStarted, "Mint not started yet or has ended!");
        require(msg.sender == tx.origin, "Contract minting not allowed.");
        require(quantity + _numberMinted(msg.sender) <= MAX_MINTS, "Exceeded the mint limit.");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough supply left.");

        if(isValid(proof, keccak256(abi.encodePacked(msg.sender))))
        {
            if(freeWojakMinted[msg.sender])
            { 
                price = quantity * mintRate;
            }
            else
            {
                if(FREE_MINTED < MAX_FREE_MINTS)
                {
                    FREE_MINTED = FREE_MINTED + 1;
                    freeWojakMinted[msg.sender] = true;
                    price = (quantity-1) * mintRate;
                }
                else
                {
                    price = quantity * mintRate;
                }
            }    
        }
        else
        {

            price = quantity * mintRate;

        }

        require(msg.value >= price, "Not enough ether sent.");
        _safeMint(msg.sender, quantity);

    }

    function collabMint(address _to, uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough supply left.");
        _safeMint(_to, quantity);
    }

    function setMintState(bool _state) external onlyOwner {
        mintStarted = _state;
    }

    function setSaleMintRate(uint256 _mintRate) public onlyOwner {
        mintRate = _mintRate;
    }

    function withdrawAll() external onlyOwner {
        require(address(this).balance > 0,"You do not have enough balance!");

        uint256 shares = address(this).balance/payees.length;

        for(uint i = 0; i < payees.length; i++)
        {

            payees[i].transfer(shares);

        }
        
    }

    function changeBaseURI(string memory _newURI) external onlyOwner {
        baseURI = _newURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI_ = _baseURI();
        
        return bytes(baseURI_).length > 0 ? string(abi.encodePacked(baseURI_, Strings.toString(tokenId), ".json")) : "";

    }
        
    function updateMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        merkleRoot = _newMerkleRoot;
    }

    function isValid(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

}