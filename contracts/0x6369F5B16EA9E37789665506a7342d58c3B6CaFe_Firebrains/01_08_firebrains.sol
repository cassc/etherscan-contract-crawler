// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Firebrains is ERC721A,Ownable,ReentrancyGuard {
    using Strings for uint256;

    //Basic Settings
    uint256 public maxSupply = 2555; //Collection supply
    uint256 public price = 0.04 ether; //Sale Price
    uint256 public regularMintMax = 10; //Max NFT per wallet
    bool public paused = true;
    bool public stopTransfers = true;

    //Reveal-Non Reveal 
    string public _baseTokenURI;
    string public _baseTokenEXT;
    
    

    //Airdrop Settings
    uint256 public reserved = 55;
    uint256 public airDropCount;

    //Whitelist Settings
    bool public whitelistSale = true;
    uint256 public whitelistMinted ;
    uint256 public whitelistMaxMint = 2; //Max NFT per wallet during WL
    uint256 public whitelistPrice = 0.04 ether;
    uint256 public whitelistExclusivePrice = 0.02 ether; 
    uint256 public wlSpots = 1250; 
    uint256 public exclusiveWlSpots = 250;
    bytes32 public merkleRoot; 

    //Storing WlMint Information
    mapping(address => uint256) public _totalMinted;


    constructor() ERC721A("FireBrains","FB") {}

    function mint(uint256 _mintAmount) public payable nonReentrant {
        require(!paused,"Contract Minting Paused");
        require(!whitelistSale,": Cannot Mint During Whitelist Sale");
        require(msg.value >= price * _mintAmount,"Insufficient Fund");
        require(totalSupply() + _mintAmount <= maxSupply ,": No more NFTs to mint,decrease the quantity or check out OpenSea.");
        _safeMint(msg.sender,_mintAmount);
    }

    function WhiteListMint(uint256 _mintAmount,bytes32[] calldata _merkleProof) public payable nonReentrant{
        require(!paused,"Contract Minting Paused");
        require(whitelistSale,": Whitelist is paused.");
        require(whitelistMinted + _mintAmount <= wlSpots ,": No more NFTs to mint,decrease the quantity or wait for Public Mint.");
        
        require(_mintAmount+_totalMinted[msg.sender] <= whitelistMaxMint,"You cant mint more,Decrease MintAmount or Wait For Public Mint" );
        require(msg.value >= getWLPrice(_mintAmount),"Insufficient FUnd");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof,merkleRoot,leaf),"You are Not whitelisted");
        _safeMint(msg.sender,_mintAmount);
        _totalMinted[msg.sender]+=_mintAmount;
        whitelistMinted+=_mintAmount;
    }

    function getWLPrice(uint256 _mintAmount) public view returns(uint256) {
        
        if(whitelistMinted +_mintAmount  <= exclusiveWlSpots){
            return _mintAmount * whitelistExclusivePrice;
        }
        else if(whitelistMinted +_mintAmount > exclusiveWlSpots && whitelistMinted < exclusiveWlSpots){
            uint256 discountedAvailable = (exclusiveWlSpots - whitelistMinted);
            uint256 fullPriceAmount = _mintAmount - discountedAvailable;
            return (discountedAvailable * whitelistExclusivePrice) + fullPriceAmount * whitelistPrice;
        }
        return _mintAmount * whitelistPrice;
    }
        
    
    function _airdrop(uint256 amount,address[] memory _address) public onlyOwner {
        uint256 _mintAmount = _address.length * amount;
        require(airDropCount+_mintAmount <= reserved,"Airdrop Limit Drained!");
        require(totalSupply()+_mintAmount <= maxSupply,"Airdrop Exceeds MaxSupply");
        for(uint256 i=0;i<_address.length;i++){
            _safeMint(_address[i], amount);
        }
        airDropCount+=_mintAmount;
    }

    function startPublicSale() public onlyOwner{
        paused = false;
        whitelistSale = false;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setPublicMintMax(uint256 newMax) public onlyOwner {
        regularMintMax = newMax;
    }

    function setWhiteListMax(uint256 newMax) public onlyOwner {
        whitelistMaxMint = newMax;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI,tokenId.toString(),_baseTokenEXT)) : "";
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(!stopTransfers,"Trading is not Enabled .");
        super.setApprovalForAll(operator,approved);
    }

    function approve(address to, uint256 tokenId) public  virtual override {
        require(!stopTransfers,"Trading is not Enabled .");
        super.approve(to, tokenId);
    }




    function toggleWhiteList() public onlyOwner{
        whitelistSale = !whitelistSale;
    }

    function togglePause() public onlyOwner{
        paused = !paused;
    }

    function toggleTransfer() public onlyOwner{
        stopTransfers = !stopTransfers;
    }

    function changeURLParams(string memory _nURL,string memory _nBaseExt) public onlyOwner {
        _baseTokenURI = _nURL;
        _baseTokenEXT = _nBaseExt;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function setWLPrice(uint256 newPrice) public onlyOwner {
        whitelistPrice = newPrice;
    }

    function setMerkleRoot(bytes32 merkleHash) public onlyOwner {
        merkleRoot = merkleHash;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success,"Transfer failed.");
    }

}