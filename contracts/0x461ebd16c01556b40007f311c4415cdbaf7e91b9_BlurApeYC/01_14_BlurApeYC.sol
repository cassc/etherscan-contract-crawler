// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./erc721/ERC721A.sol";

contract BlurApeYC is ERC721A, Ownable, ReentrancyGuard {

    address private key;
    using ECDSA for bytes32;
    bool public Minting  = false;
    uint256[] public freeMintArray = [2,1,0];
    uint256[] public supplyMintArray = [7500 ,9000 ,9500];
    uint256 public price = 2800000000000000;
    string public baseURIReveal;  
    string public baseURIUnrevealed;  
    uint256 public maxPerTx = 20;  
    uint256 public maxSupply = 10000;
    uint256 public teamSupply = 100;  
    mapping (address => uint256) public minted;
    mapping (uint256 => bool) public reveal;
    mapping (uint256 => string) public revealUrl;

    constructor() ERC721A("Blur Ape YC", "Blur Ape YC",100,10000){}

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function RevealToken(uint256 tokenId,bytes memory signature) external payable
    {
        require(ownerOf(tokenId) == msg.sender, "Blur Ape YC Not Owner!");
        require(reveal[tokenId] == false, "Blur Ape YC Revealed!");
        require(isMessageValid(signature,tokenId),"Blur Ape YC Wrong Signature!");
        bytes32 messagehash = keccak256(abi.encodePacked(key,tokenId));
        reveal[tokenId] = true;
        revealUrl[tokenId] = Strings.toHexString(uint(messagehash), 32);
    }

    function mint(uint256 qty) external payable
    {
        require(Minting , "Blur Ape YC Minting Pause !");
        require(qty <= maxPerTx, "Blur Ape YC Limit Per Tx !");
        require(totalSupply() + qty <= maxSupply-teamSupply,"Blur Ape YC Soldout !");
        _safemint(qty);
    }

    function _safemint(uint256 qty) internal  {
        uint freeMint = FreeMintBatch();
        if(minted[msg.sender] < freeMint) 
        {
            if(qty < freeMint) qty = freeMint;
           require(msg.value >= (qty - freeMint) * price,"Blur Ape YC Insufficient Funds !");
            minted[msg.sender] += qty;
           _safeMint(msg.sender, qty);
        }
        else
        {
           require(msg.value >= qty * price,"Blur Ape YC Insufficient Funds !");
            minted[msg.sender] += qty;
           _safeMint(msg.sender, qty);
        }
    }

    function FreeMintBatch() public view returns (uint256) {
        if(totalSupply() < supplyMintArray[0])
        {
            return freeMintArray[0];
        }
        else if (totalSupply() < supplyMintArray[1])
        {
            return freeMintArray[1];
        }
        else if (totalSupply() < supplyMintArray[2])
        {
            return freeMintArray[2];
        }
        else
        {
            return 0;
        }
    }
    function isMessageValid(bytes memory _signature, uint256 tokenId) public view returns (bool)
    {
        bytes32 messagehash = keccak256(abi.encodePacked(address(this),key,tokenId));
        address signer = messagehash.toEthSignedMessageHash().recover(_signature);

        if (key == signer) {
            return true;
        } else {
            return false;
        }
    }

    function _setKey(address _newOwner) external onlyOwner {
        key = _newOwner;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURIReveal;
    }

    function airdrop(address[] memory listedAirdrop ,uint256[] memory qty) external onlyOwner {
        for (uint256 i = 0; i < listedAirdrop.length; i++) {
           _safeMint(listedAirdrop[i], qty[i]);
        }
    }
    
    function setPublicMinting() external onlyOwner {
        Minting  = !Minting ;
    }
    
    function setBaseURI(string memory baseURIReveal_,string memory baseURIUnrevealed_) external onlyOwner {
        baseURIReveal = baseURIReveal_;
        baseURIUnrevealed = baseURIUnrevealed_;
    }

    function setsupplyMintArray(uint256[] memory supplyMintArray_) external onlyOwner {
        supplyMintArray = supplyMintArray_;
    }
    
    function setfreeMintArray(uint256[] memory freeMintArray_) external onlyOwner {
        freeMintArray = freeMintArray_;
    }

    function setMaxSupply(uint256 maxMint_) external onlyOwner {
        maxSupply = maxMint_;
    }

    function OwnerBatchMint(uint256 qty) external onlyOwner
    {
        _safeMint(msg.sender, qty);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if(reveal[tokenId])
        {
            return bytes(baseURIReveal).length > 0 ? string(abi.encodePacked(baseURIReveal, revealUrl[tokenId],"/json")) : "";
        }
        else
        {
            return bytes(baseURIUnrevealed).length > 0 ? string(abi.encodePacked(baseURIUnrevealed, Strings.toString(tokenId))) : "";
        }
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(payable(address(this)).balance);
    }
}