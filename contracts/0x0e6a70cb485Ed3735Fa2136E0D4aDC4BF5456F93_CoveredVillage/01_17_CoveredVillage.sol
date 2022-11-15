// SPDX-License-Identifier: MIT
/*
---------------------------------------------------------------------------------------------------------------------
              @@@@@@                            @@@@ @@@@       @@@@@@         @@@@ @@@@      @@@@@@                 
             @@@@@@@                 @@@@@@      @@@@ @@@@      @@@@@@@         @@@@ @@@@     @@@@@@@                
   @@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@   @@@ @@@@ @@@@     @@@@@@@          @@@@ @@@@    @@@@@@@                
    @@@@@@@@@@@@@@@@@@@@@@@@@       @@@@@@@    @@@@             @@@@@@@@@@@@@@@@              @@@@@@@                
     @@@@@@@@@@@@@    @@@@@@@      @@@@@@@@     @@@@@@          @@@@@@@@@@@@@@@@@@@@@@@       @@@@@@@                
         @@@@@@@F     @@@@@@@      @@@@@@@      @@@@@@          @@@@@@@@@@@@@@@@@@@@@@@       @@@@@@@              @@
        @@@@@@@F     @@@@@@@      @@@@@@@@       @@@@@@         @@@@@@@                       @@@@@@@          @@@@@@
       @@@@@@@F     @@@@@@@      @@@@@@@@        @@@@@@@        @@@@@@@                       @@@@@@@    @@@@@@@@@@@@
      @@@@@@@@@@@@@@@@@@@@       @@@@@@@          @@@@@@@       @@@@@@@           @@@@@@      @@@@@@@@@@@@@@@@@@@@@@@
     @@@@@@@   @@@@@@@@@@       @@@@@@@@           @@@@@@@      @@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@     
    @@@@@@@@       @@@@@       @@@@@@@@             @@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@        @@@@@@@@@@           
---------------------------------------------------------------------------------------------------------------------
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract CoveredVillage is ERC721A, Ownable, ReentrancyGuard, ERC2981{
    uint256 public tokenCount;
    uint256 public prePrice = 0.005 ether;
    uint256 public pubPrice = 0.008 ether;
    uint256 public batchSize = 100;
    uint256 public mintLimit = 3;
    uint256 public _totalSupply = 3333;
    bool public preSaleStart = false;
    bool public pubSaleStart = false;
    mapping(address => uint256) public minted; 
    bytes32 public merkleRoot;

    address public royaltyAddress;
    uint96 public royaltyFee = 1000;
    
    bool public revealed;
    string public baseURI;
    string public notRevealedURI;

    constructor() ERC721A("CoveredVillage", "CV",batchSize, _totalSupply) {
        tokenCount = 0;
        royaltyAddress = msg.sender;
        _setDefaultRoyalty(msg.sender, royaltyFee);
    }

    function ownerMint(uint256 _mintAmount, address to) external onlyOwner {
        require((_mintAmount + tokenCount) <= (_totalSupply), "too many already minted before patner mint");
        _safeMint(to, _mintAmount);
        tokenCount += _mintAmount;
    }

    function preMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable nonReentrant {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        
        require(mintLimit >= _mintAmount, "limit over");
        require(mintLimit >= minted[msg.sender] + _mintAmount, "You have no Mint left");
        require(msg.value >= prePrice * _mintAmount, "Value sent is not correct");
        require((_mintAmount + tokenCount) <= (_totalSupply), "Sorry. No more NFTs");
        require(preSaleStart, "Sale Paused");
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf),"Invalid Merkle Proof");
        
        minted[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
        tokenCount += _mintAmount;
    }
    
    function pubMint(uint256 _mintAmount) public payable nonReentrant {
        require(mintLimit >= _mintAmount, "limit over");
        require(mintLimit >= minted[msg.sender] + _mintAmount, "You have no Mint left");
        require(msg.value >= pubPrice * _mintAmount, "Value sent is not correct");
        require((_mintAmount + tokenCount) <= (_totalSupply), "Sorry. No more NFTs");
        require(pubSaleStart, "Sale Paused");

        minted[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
        tokenCount += _mintAmount;
    }
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
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
    function tokenURI(uint256 _tokenId) public view virtual override(ERC721A) returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");
        if(revealed == false) {
            return notRevealedURI;
        }
        return string(abi.encodePacked(_baseURI(), Strings.toString(_tokenId), ".json"));
    }

    function withdrawRevenueShare() external onlyOwner {
        uint256 sendAmount = address(this).balance;
        address artist = payable(0x91f5914A70C1F5d9fae0408aE16f1c19758337Eb);
        address engineer1 = payable(0xeDAcc663C23ba31398550E17b1ccF47cd9Da1888);
        address engineer2 = payable(0x2064f95A4537a7e9ce364384F55A2F4bBA3F0346);
        bool success;
        
        (success, ) = artist.call{value: (sendAmount * 800/1000)}("");
        require(success, "Failed to withdraw Ether");
        (success, ) = engineer1.call{value: (sendAmount * 100/1000)}("");
        require(success, "Failed to withdraw Ether");
        (success, ) = engineer2.call{value: (sendAmount * 100/1000)}("");
        require(success, "Failed to withdraw Ether");
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }
    function switchPreSale(bool _state) external onlyOwner {
        preSaleStart = _state;
    }
    function switchPubSale(bool _state) external onlyOwner {
        pubSaleStart = _state;
    }
    function setLimit(uint256 newLimit) external onlyOwner {
        mintLimit = newLimit;
    }
    function walletOfOwner(address _address) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_address);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_address, i);
        }
        return tokenIds;
    }
    //set Default Royalty._feeNumerator 500 = 5% Royalty
    function setRoyaltyFee(uint96 _feeNumerator) external onlyOwner {
        royaltyFee = _feeNumerator;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }
    //Change the royalty address where royalty payouts are sent
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