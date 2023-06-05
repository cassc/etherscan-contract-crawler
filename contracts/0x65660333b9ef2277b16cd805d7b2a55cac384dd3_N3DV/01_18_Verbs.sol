// SPDX-License-Identifier: MIT

//  author Name: Alex Yap
//  author-email: <[email protected]>
//  author-website: https://alexyap.dev

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./NounToken.sol";


contract N3DV is ERC721Enumerable, ReentrancyGuard, Ownable {

    string public NOUNS3D_PROVENANCE = "";
    string public baseTokenURI;

    uint256 public maxNouns3dPerMint;
    uint256 public maxNouns3dPerClaim;
    uint256 public constant MAX_NOUNS3D = 100000;
    uint256 public constant START_NOUNS3D = 7400;

    uint256 public nouns3dPrice;
    uint256 public nameChangeTokenPrice = 300 ether;
    uint256 public claimTokenPrice = 900 ether;

    bool public saleIsActive = false;
    bool public claimIsActive = false;

    mapping(uint256 => string) public nameN3D;

    NounToken public nounToken;

    event NameChanged(uint256 tokenId, string name);

    constructor(string memory baseURI, address _noun) ERC721("Nouns3D Verbs", "N3DV") {
        setBaseURI(baseURI);
        nounToken = NounToken(_noun);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setNounToken(address _noun) external onlyOwner {
        nounToken = NounToken(_noun);
    }

    function setBurnRate(uint256 _namingPrice, uint256 _claimingPrice) external onlyOwner {
        nameChangeTokenPrice = _namingPrice;
        claimTokenPrice = _claimingPrice;
    }

    function changeName(uint256 _tokenId, string memory _newName) public {
        require(ownerOf(_tokenId) == msg.sender);
        require(validateName(_newName) == true, "Invalid name");
        nounToken.burn(msg.sender, nameChangeTokenPrice);
        nameN3D[_tokenId] = _newName;

        emit NameChanged(_tokenId, _newName);
    }

    function validateName(string memory str) internal pure returns (bool) {
        bytes memory b = bytes(str);

        if(b.length < 1) return false;
        if(b.length > 25) return false;
        if(b[0] == 0x20) return false; // Leading space
        if(b[b.length - 1] == 0x20) return false; // Trailing space

        bytes1 lastChar = b[0];

        for (uint256 i; i < b.length; i++) {
            bytes1 char = b[i];

            if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

            if (
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x20) //space
            ) {
                return false;
            }

            lastChar = char;
        }

        return true;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);

        payable(msg.sender).transfer(balance);
    }

    function reserveNouns3d(uint256 _maxMint) public onlyOwner {
        uint256 supply = totalSupply();
        uint256 i;
        for (i = 0; i < _maxMint; i++) {
            if (totalSupply() < MAX_NOUNS3D) {
                uint256 mintIndex = supply + i;
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        NOUNS3D_PROVENANCE = provenanceHash;
    }

    function setMaxClaimPerTransaction(uint256 _maxNFTPerTransaction) internal onlyOwner {
        maxNouns3dPerClaim = _maxNFTPerTransaction;
    }

    function flipClaimState(uint256 price, uint256 _maxClaim) public onlyOwner {
        claimTokenPrice = price;
        setMaxClaimPerTransaction(_maxClaim);
        claimIsActive = !claimIsActive;
    }

    function claim(uint256 numberOfTokens) external {
        require(claimIsActive, "Sale must be active to mint");
        require(numberOfTokens > 0, "Invalid number of tokens");
        require(numberOfTokens <= maxNouns3dPerClaim, "Cannot purchase this many tokens in a transaction");
        require(totalSupply() + numberOfTokens <= MAX_NOUNS3D, "Purchase would exceed max supply");

        nounToken.burn(msg.sender, claimTokenPrice * numberOfTokens);

        for(uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = START_NOUNS3D + totalSupply();
            if (totalSupply() < MAX_NOUNS3D) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function setMaxMintPerTransaction(uint256 _maxNFTPerTransaction) internal onlyOwner {
        maxNouns3dPerMint = _maxNFTPerTransaction;
    }

    function flipSaleState(uint256 price, uint256 _maxMint) public onlyOwner {
        nouns3dPrice = price;
        setMaxMintPerTransaction(_maxMint);
        saleIsActive = !saleIsActive;
    }

    function mint(uint256 numberOfTokens) public payable nonReentrant{
        require(saleIsActive, "Sale must be active to mint");
        require(numberOfTokens > 0, "Invalid number of tokens");
        require(numberOfTokens <= maxNouns3dPerMint, "Cannot purchase this many tokens in a transaction");
        require(totalSupply() + numberOfTokens <= MAX_NOUNS3D, "Purchase would exceed max supply");
        require(nouns3dPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for(uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = START_NOUNS3D + totalSupply();
            if (totalSupply() < MAX_NOUNS3D) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }
}