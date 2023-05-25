// SPDX-License-Identifier: MIT

//  author Name: Alex Yap
//  author-email: <[email protected]>
//  author-website: https://alexyap.dev

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./NounToken.sol";

interface INouns3dv1 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract Nouns3Dv2 is ERC721Enumerable, ReentrancyGuard, Ownable {

    string public NOUNS3D_PROVENANCE = "";
    string public baseTokenURI;

    uint256 public constant MAX_NOUNS3D = 7400;
    uint256 public namingNounPrice = 300 ether;

    bool public mintIsActive = false;

    mapping(uint256 => string) public nameN3D;
    mapping(address => uint256) public balanceN3D;

    INouns3dv1 public nouns3dv1Contract;
    NounToken public nounToken;

    event NameChanged(string name);

    constructor(string memory baseURI, address _nouns3dv1) ERC721("Nouns3D", "N3D") {
        setBaseURI(baseURI);
        nouns3dv1Contract = INouns3dv1(_nouns3dv1);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        NOUNS3D_PROVENANCE = provenanceHash;
    }

    function setNouns3dv1(address _nouns3dv1) external onlyOwner {
        nouns3dv1Contract = INouns3dv1(_nouns3dv1);
    }

    function setNounToken(address _noun) external onlyOwner {
        nounToken = NounToken(_noun);
    }

    function setBalanceN3D(address wallet, uint256 _newBalance) external onlyOwner {
        balanceN3D[wallet] = _newBalance;
    }

    function setBurnRate(uint256 _namingPrice) external onlyOwner {
        namingNounPrice = _namingPrice;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);

        payable(msg.sender).transfer(balance);
    }

    function flipMint() public onlyOwner {
        mintIsActive = !mintIsActive;
    }

    function mintAdmin(uint256[] calldata tokenIds, address _to) public payable onlyOwner {
        require(totalSupply() < MAX_NOUNS3D, "Max supply reached");
        require(totalSupply() + tokenIds.length <= MAX_NOUNS3D, "Minting would exceed max supply of Nouns3D V2");

        for(uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenIds[i] < MAX_NOUNS3D, "Invalid token ID");
            require(nouns3dv1Contract.ownerOf(tokenIds[i]) == _to, "Not the owner of this Nouns3D token");
            require(!_exists(tokenIds[i]), "Tokens has already been minted");

            if (totalSupply() < MAX_NOUNS3D) {
                _safeMint(_to, tokenIds[i]);
                balanceN3D[_to] += 1;
            }
        }
        //update reward on mint
        nounToken.updateRewardOnMint(_to, tokenIds.length);
    }

    function mint(uint256[] calldata tokenIds) public payable nonReentrant {
        require(mintIsActive, "Migration must be active in order to mint");
        require(totalSupply() < MAX_NOUNS3D, "Max supply reached");
        require(totalSupply() + tokenIds.length <= MAX_NOUNS3D, "Minting would exceed max supply of Nouns3D V2");

        for(uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenIds[i] < MAX_NOUNS3D, "Invalid token ID");
            require(nouns3dv1Contract.ownerOf(tokenIds[i]) == msg.sender, "Not the owner of this Nouns3D token");
            require(!_exists(tokenIds[i]), "Tokens has already been minted");

            if (totalSupply() < MAX_NOUNS3D) {
                _safeMint(msg.sender, tokenIds[i]);
                balanceN3D[msg.sender] += 1;
            }
        }
        //update reward on mint
        nounToken.updateRewardOnMint(msg.sender, tokenIds.length);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override nonReentrant {
        nounToken.updateReward(from, to, tokenId);
        balanceN3D[from] -= 1;
        balanceN3D[to] += 1;

        ERC721.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override nonReentrant {
        nounToken.updateReward(from, to, tokenId);
        balanceN3D[from] -= 1;
        balanceN3D[to] += 1;

        ERC721.safeTransferFrom(from, to, tokenId, _data);
    }

    function getReward() external {
        nounToken.updateReward(msg.sender, address(0), 0);
        nounToken.getReward(msg.sender);
    }

    function changeName(uint256 _tokenId, string memory _newName) public {
        require(ownerOf(_tokenId) == msg.sender);
        require(validateName(_newName) == true, "Invalid name");
        
        nounToken.burn(msg.sender, namingNounPrice);
        nameN3D[_tokenId] = _newName;

        emit NameChanged(_newName);
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
}