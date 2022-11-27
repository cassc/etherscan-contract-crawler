// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

contract Oasis is ERC721A, Ownable {
    bool public isWhitelistSaleActive = false;
    bool public isPublicSaleActive = false;
    bool public revealed = false;

    string private baseURI;
    string private baseContractDataUri;
    uint public maxSupply = 5999;
    uint public whitelistSupply = 1999;
    uint public publicMintCost = 2.25 ether;
    uint public whitelistMintCost = 1.75 ether;
    bytes32 merkleRoot;

    mapping(address => bool) private usedWL;

    constructor(string memory _baseNftUri, string memory _baseContractDataUri, bytes32 _merkleRoot) ERC721A("Oasis metaverse", "OASIS") {
        baseURI = _baseNftUri;
        baseContractDataUri = _baseContractDataUri;
        merkleRoot = _merkleRoot;

        _safeMint(msg.sender, 1);
    }

    function checkWhitelist(bytes32[] memory _merkleProof) public view returns(bool) {
        return MerkleProof.verify(_merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender)));
    }
    
    function publicMint() public payable {
        require(totalSupply() <= maxSupply, "All NFT have already been minted!");
        require(isPublicSaleActive == true, "Public sale is inactive!");
        require(msg.value >= publicMintCost, "You are trying to pay the wrong amount");

        _safeMint(msg.sender, 1);
    }

    function whitelistMint(bytes32[] memory _merkleProof) public payable {
        require(totalSupply() <= whitelistSupply, "All NFT for WL have already been minted!");
        require(isWhitelistSaleActive, "Whitelist sale is inactive!");
        require(msg.value >= whitelistMintCost, "You are trying to pay the wrong amount");
        require(checkWhitelist(_merkleProof), "Failed merkle proof!");
        require(usedWL[msg.sender] == false, "You already minted!");

        _safeMint(msg.sender, 1);
        usedWL[msg.sender] = true;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }
        
    function setWlMintPrice(uint _newPrice) public onlyOwner {
        whitelistMintCost = _newPrice;
    }

    function setPublicMintPrice(uint _newPrice) public onlyOwner {
        publicMintCost = _newPrice;
    }
    
    function togglePublicSale() public onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }

    function toggleWhitelistSale() public onlyOwner {
        isWhitelistSaleActive = !isWhitelistSaleActive;
    }

    function toggleReveal(string memory baseURI_) public onlyOwner {
        revealed = !revealed;
        baseURI = baseURI_;
    }

    function withdrawMoney(address receiver) public onlyOwner {
        address payable _to = payable(receiver);
        address _thisContract = address(this);
        _to.transfer(_thisContract.balance);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        if (revealed) return bytes(_baseURI()).length != 0 ? string(abi.encodePacked(_baseURI(), _toString(tokenId), ".json")) : '';
        else return string(abi.encodePacked(baseURI, "hidden.json"));
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(baseContractDataUri, "contract_data.json"));
    }

    function _startTokenId() internal view override virtual returns (uint256) {
        return 1;
    }

    function teamMint(uint256 count) public onlyOwner {
        require(totalSupply() <= maxSupply, "All NFT have already been minted!");
        _safeMint(msg.sender, count);
    }
}