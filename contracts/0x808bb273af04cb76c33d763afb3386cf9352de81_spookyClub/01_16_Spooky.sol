// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract spookyClub is ERC721, Ownable, ReentrancyGuard {
    constructor(
        string memory _name,
        string memory _symbol,
        uint16 _maxSupply
    ) ERC721(_name, _symbol) {
        maxSupply = _maxSupply;
    }

    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Strings for uint256;

    Counters.Counter public _ID;

    uint256 public constant publicSalePrice = 0.014 ether;
    uint256 public constant whiteListSalePrice = 0.009 ether;

    uint256 public constant maxTotalMintAmount = 5;

    uint16 public totalSupply;
    uint16 public maxSupply;

    bool public freeMintStatus; 
    bool public publicSaleStatus;
    bool public whiteListSaleStatus; 

    bool public revealStatus;

    bytes32 whiteListRoot; 
    bytes32 freeMintRoot; 

    string bURI;
    

    modifier checkAmountAndSupplyAndBalance(uint16 _amount){
        require(_amount!=0,"amount can not be zero");
        require(uint256(totalSupply).add(_amount) <= maxSupply,"Exceeds Max Supply");
        require(balanceOf(_msgSender()).add(_amount)<=maxTotalMintAmount , "Exceed Total Mint Amount");
        _;
    }

    modifier isWhiteList(bytes32[] calldata _proof){
        bytes32 _leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_proof, whiteListRoot, _leaf),"Not On Whitelist");
        _;
    }

    modifier isFreeMint(bytes32[] calldata _proof){
        bytes32 _leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_proof, freeMintRoot, _leaf),"Not On Free Mint list");
        _;
    }


    function freeMint(uint16 _amount,bytes32[] calldata _proof) external nonReentrant checkAmountAndSupplyAndBalance(_amount) isFreeMint(_proof) {
        require(freeMintStatus,"Free mint is not active");
        totalSupply += _amount;
         for (uint16 index = 1; index <= _amount; index++) {
            _safeMint(_msgSender(), _ID.current(), "");
            _ID.increment();
        }
    }

    function whiteListMint(uint16 _amount, bytes32[] calldata _proof) external payable nonReentrant isWhiteList(_proof) checkAmountAndSupplyAndBalance(_amount) {
        require(whiteListSaleStatus,"wihteList mint is not active");
        require(msg.value == whiteListSalePrice.mul(_amount),"Insufficient ETH Sent");
        totalSupply += _amount;
        for (uint256 index = 1; index <= _amount; index++) {
            _safeMint(_msgSender(), _ID.current(), "");
            _ID.increment();
        }
    }

    function publicMint(uint16 _amount) external  payable nonReentrant checkAmountAndSupplyAndBalance(_amount){
        require(publicSaleStatus,"public mint is not active");
        require(msg.value == publicSalePrice.mul(_amount),"Insufficient ETH Sent");
        totalSupply += _amount;
        for (uint256 index = 1; index <= _amount; index++) {
            _safeMint(_msgSender(), _ID.current(), "");
            _ID.increment();
        }
    }

    //Owner Functions
    function toggleWhitelistSaleStatus() external onlyOwner {
        whiteListSaleStatus = !whiteListSaleStatus;
    }

    function togglePublicSaleStatus() external onlyOwner {
        publicSaleStatus = !publicSaleStatus;
    }
    function toggleFreeMintStatus() external onlyOwner {
        freeMintStatus = !freeMintStatus;
    }

    function setMerkleRootWhiteListMint(bytes32 _merkleRoot) external onlyOwner {
        whiteListRoot = _merkleRoot;
    }

    function setMerkleRootFreeMint(bytes32 _merkleRoot) external onlyOwner {
        freeMintRoot = _merkleRoot;
    }

    function reveal() external onlyOwner {
        revealStatus = true;
    }

    function setBaseURI(string calldata _newbURI) external onlyOwner {
        bURI = _newbURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return bURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);
        string memory baseURI = _baseURI();

        if (revealStatus) {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(),".json")) : "";
            
        } else {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI,"unreveal.json")) : "";
        }
    }

    function burn(uint16 _tokenId) external  {
        require(ownerOf(_tokenId) == _msgSender(),"owner is invalid");
        _burn(_tokenId);
    }

    function withdraw() payable external onlyOwner nonReentrant{
        (bool sent,) = owner().call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }
}