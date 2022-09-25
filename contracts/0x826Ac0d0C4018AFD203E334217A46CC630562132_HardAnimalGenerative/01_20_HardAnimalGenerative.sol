// SPDX-License-Identifier: MIT
/*
 @@@@@@@@@@@@@@@@@              @@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@              @@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@              @@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@              @@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@              @@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@              @@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@
 @@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@
 @@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@
 @@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@
 @@@@@@@@@@ @@@@@@              @@@@@@ @@@@@@@@@@
 @@@@@@@@@ @@@@@@@              @@@@@@@ @@@@@@@@@
 @@@@@@@@ @@@@@@@@              @@@@@@@@ @@@@@@@@

 @@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@
 @@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@
 @@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@
 @@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@
 @@ @@@@@@@@@@@@@@                               
 @ @@@@@@@@@@@@@@@       @@@@@@@ @@@@@@@@@@@@@@ @
  @@@@@@@@@@@@@@@@       @@@@@@@ @@@@@@@@@@@@@@@ 
                         @@@@@@@                 
 @@@@@@@@@@@@@@@@@              @@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@              @@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@              @@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*/

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract HardAnimalGenerative is ERC721AQueryable, ERC2981 , Ownable, Pausable {
    using Strings for uint256;
    bool public revealed;
    string public baseURI = "";
    string public notRevealedURI = "";
    uint256 public saleHCost = 0.005 ether;
    uint256 public saleGCost = 0.005 ether;
    uint256 public publicCost = 0.005 ether;

    bool public saleHStart = false;
    bool public saleGStart = false;
    bool public publicStart = false;
    address public royaltyAddress;
    uint96 public royaltyFee = 1000;

    uint256 constant public MAX_SUPPLY = 4444;
    uint256 constant public MINTLIMIT_H = 3;
    uint256 constant public MINTLIMIT_G = 1;
    uint256 constant public MINTLIMIT_P = 1;

    mapping(address => uint256) public mintedH; 
    mapping(address => uint256) public mintedG; 

    bytes32 public merkleRootH;
    bytes32 public merkleRootG;
 
    constructor(
    ) ERC721A("HardAnimalGenerative","HAG") {
        royaltyAddress = msg.sender;
        _setDefaultRoyalty(msg.sender, royaltyFee);
    }

    // internal
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 _tokenId) public view virtual override(ERC721A) returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");
        if(revealed == false) {
            return notRevealedURI;
        }
        return string(abi.encodePacked(_baseURI(), Strings.toString(_tokenId), ".json"));
    }

    // public mint
    function publicMint(uint256 _mintAmount) public payable whenNotPaused {
        mintCheck(_mintAmount, publicCost * _mintAmount);
        require(publicStart, "Presale is active.");
        require(_mintAmount <= MINTLIMIT_P, "Mint amount over");

        _safeMint(msg.sender, _mintAmount);
    }

    function HPassMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable whenNotPaused {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        mintCheck(_mintAmount,  saleHCost * _mintAmount);
        require(saleHStart, "Presale is not active.");
        require(MINTLIMIT_H >= mintedH[msg.sender] + _mintAmount, "You have no Mint left");
        require(MerkleProof.verify(_merkleProof, merkleRootH, leaf),"Invalid Merkle Proof");
        mintedH[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    function GPassMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable whenNotPaused {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        mintCheck(_mintAmount,  saleGCost * _mintAmount);
        require(saleGStart, "Presale is not active.");
        require(MINTLIMIT_G >= mintedG[msg.sender] + _mintAmount, "You have no Mint left");
        require(MerkleProof.verify(_merkleProof, merkleRootG, leaf),"Invalid Merkle Proof");
        mintedG[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    function mintCheck(uint256 _mintAmount, uint256 _cost) private view {
        require(_mintAmount > 0, "Mint amount cannot be zero");
        require(totalSupply() + _mintAmount <= MAX_SUPPLY, "MAXSUPPLY over");
        require(msg.value >= _cost, "Not enough funds");
    }

    function ownerMint(address _address, uint256 _mintAmount) public onlyOwner {
       _safeMint(_address, _mintAmount);
    }

    function setHSale(bool _state) public onlyOwner {
        saleHStart = _state;
    }
    function setGSale(bool _state) public onlyOwner {
        saleGStart = _state;
    }
    function setPSale(bool _state) public onlyOwner {
        publicStart = _state;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    function setHiddenURI(string memory _newHiddenURI) public onlyOwner {
        notRevealedURI = _newHiddenURI;
    }

    function switchReveal() public onlyOwner {
        revealed = !revealed;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdrawRevenueShare() external onlyOwner {
        uint256 sendAmount = address(this).balance;
        
        address artist = payable(0x195903A241555a23ACCD14C981fe5fd320AEB5B0);
        address engineer = payable(0x7Abb65089055fB2bf5b247c89E3C11F7dB861213);
        address engineer2 = payable(0x2064f95A4537a7e9ce364384F55A2F4bBA3F0346);
        address marketer = payable(0xf2fd31926B3bc3fB47C108B31cC0829F20DeE4c0);
        bool success;
        
        (success, ) = artist.call{value: (sendAmount * 650/1000)}("");
        require(success, "Failed to withdraw Ether");
        (success, ) = engineer.call{value: (sendAmount * 125/1000)}("");
        require(success, "Failed to withdraw Ether");
        (success, ) = engineer2.call{value: (sendAmount * 125/1000)}("");
        require(success, "Failed to withdraw Ether");
        (success, ) = marketer.call{value: (sendAmount * 100/1000)}("");
        require(success, "Failed to withdraw Ether");
    }

    function setMerkleRootH(bytes32 _merkleRoot) external onlyOwner {
        merkleRootH= _merkleRoot;
    }
    function setMerkleRootG(bytes32 _merkleRoot) external onlyOwner {
        merkleRootG= _merkleRoot;
    }

     //@notice Change the royalty fee for the collection
    function setRoyaltyFee(uint96 _feeNumerator) external onlyOwner {
        royaltyFee = _feeNumerator;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

     //@notice Change the royalty address where royalty payouts are sent
    function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        royaltyAddress = _royaltyAddress;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}