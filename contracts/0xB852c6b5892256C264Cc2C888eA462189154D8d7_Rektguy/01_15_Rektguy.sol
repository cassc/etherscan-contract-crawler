// SPDX-License-Identifier: NULL
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";


contract Rektguy is ERC721,Ownable,ReentrancyGuard{


    using SafeMath for uint256;
    
    uint256 public tokenCounter;
    uint256 public constant MAX_TOKENS = 11000;
    uint256 public constant MAX_PURCHASE_TOKENS = 10;
    uint256 public PRESALE_DURATION = 6 days;
    bool public preSaleIsActive = false;
    string private uri;
    string private _baseTokenURI;
    uint256 public preSaleStartTimestamp;
    bytes32 private merkleRootOne =
        0xc891c5b4634598d1ed7cf4a3743ca20a33fc03bb10bcd7c45fe801e1434ba356;

    bytes32 private merkleRootTwo =
        0x68760e8751ab187e7ac9aa58505886ef38d71baed1fc1bcfb3ccb0d86bb8b543;

    mapping(address => uint256) public validNumberOfTokensPerBuyerMap;
    mapping(address => uint256) public tokenBalancePerOwner;
    mapping(address => bool) public whitelistClaimed;
    
    constructor( 
        string memory name, 
        string memory symbol,
        string memory initialURI
    ) ERC721(name, symbol) ReentrancyGuard(){
        tokenCounter=0;
        uri = initialURI;
    }

    function getMerkleOneProofFor(address sampleAddress, bytes32[] calldata _merkleProof) public view returns (bool){
        bytes32 leaf = keccak256(abi.encodePacked(sampleAddress));
        return MerkleProof.verify(_merkleProof, merkleRootOne, leaf);
    }

    function getMerkleTwoProofFor(address sampleAddress, bytes32[] calldata _merkleProof) public view returns (bool){
        bytes32 leaf = keccak256(abi.encodePacked(sampleAddress));
        return MerkleProof.verify(_merkleProof, merkleRootTwo, leaf);
    }

    function  balanceOf(address sampleAddress) public view  virtual override returns (uint256){
        return tokenBalancePerOwner[sampleAddress];
    }

    function getValidNumberOfTokensForBuyer(address sampleAddress) public view returns (uint256){
        return validNumberOfTokensPerBuyerMap[sampleAddress];
    }

    function setMerkleRootOne(bytes32 _merkleRoot) public onlyOwner {
        merkleRootOne = _merkleRoot;
    }

    function setMerkleRootTwo(bytes32 _merkleRoot) public onlyOwner {
        merkleRootTwo = _merkleRoot;
    }

    function flipPreSale() public onlyOwner {
        preSaleStartTimestamp = block.timestamp;
        preSaleIsActive = !preSaleIsActive;
    }

    function setDuration(uint256 duration) public onlyOwner{
        PRESALE_DURATION = duration;
    }

    /*
    * whitelist addresses with more than one valid number of tokens for presale
    */
    function whitelistAddresses(address[] calldata wallets, uint256[] calldata validTokens) public onlyOwner {
        for(uint256 i=0; i<wallets.length;i++) {
            validNumberOfTokensPerBuyerMap[wallets[i]] = validTokens[i];
        }
    }

    function setBaseURI(string calldata newBaseTokenURI) public onlyOwner{
        uri = newBaseTokenURI;
    }

    function getPreSaleDuration() public view returns (uint256){
        return block.timestamp - preSaleStartTimestamp;
    }

    function mintNFTPreSale(uint256 numberOfTokens, bytes32[] calldata _merkleProof) public nonReentrant() {
        require(preSaleIsActive, "minting is not open yet");
        require(tokenCounter.add(numberOfTokens) <= MAX_TOKENS, "rektguy has now sold out");
        require(getPreSaleDuration() < PRESALE_DURATION, "the mint has ended");
        
        if (validNumberOfTokensPerBuyerMap[msg.sender] == 0 && !whitelistClaimed[msg.sender]){
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            if(MerkleProof.verify(_merkleProof, merkleRootOne, leaf)){
                whitelistClaimed[msg.sender] = true;
                validNumberOfTokensPerBuyerMap[msg.sender]= 1;
                tokenBalancePerOwner[msg.sender] = 1;
            } else if (MerkleProof.verify(_merkleProof, merkleRootTwo, leaf)){
                whitelistClaimed[msg.sender] = true;
                validNumberOfTokensPerBuyerMap[msg.sender]= 2;
            }else{
                require(false, "your address is not allowlisted");
            }
        }
        
        require(tokenBalancePerOwner[msg.sender].add(numberOfTokens) <= validNumberOfTokensPerBuyerMap[msg.sender], "you have reached your maximum number of mints");
    
        for(uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, tokenCounter);
            tokenCounter++;
            tokenBalancePerOwner[msg.sender]++;
        }
    }

    function getValidNumberOfTokens(address checkAddress) public view returns (uint256){
        return validNumberOfTokensPerBuyerMap[checkAddress];
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory)
    {
        return string(abi.encodePacked(uri, Strings.toString(tokenId)));
    }

}