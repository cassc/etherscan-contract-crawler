// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract TheMotherRoad is ERC721A, Ownable, DefaultOperatorFilterer {


    //author = atak.eth


    using Strings for uint256;
    string baseURI;    

    uint256 public maximumSupply = 67;

    uint256 public dayInBlocks = 7050;
    uint256 public hourInBlocks = 292;
    uint256 firstTransferredBlock;
    uint256 public dynamicTokenId;

    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    
    constructor() ERC721A("The Mother Road", "ROAD") {
        setDynamicTokenId(0);
    }


    function getState() public view returns(uint256){
        uint256 currentState;
        uint256 blockDiff = block.number - firstTransferredBlock;
        
        if(blockDiff > dayInBlocks){
            currentState = ((blockDiff % dayInBlocks) / hourInBlocks);
        }else{
            currentState = (blockDiff / hourInBlocks);
        }
        
        return currentState;
    }

    function setStateIntervals(uint256 daily, uint256 hourly) external onlyOwner{
        dayInBlocks = daily;
        hourInBlocks = hourly;
    }

    function setDynamicTokenId(uint256 id) public onlyOwner{
        dynamicTokenId = id;
    }

    function setFirstTransferredBlock() public onlyOwner{
        firstTransferredBlock = block.number;
    }
    
    function tokenURI(uint256 tokenId) public view override returns (string memory){
        require(_exists(tokenId),"Token doesnt exist");

        if(tokenId == dynamicTokenId){
            return string(abi.encodePacked(baseURI, tokenId.toString(), "_", getState().toString(), ".json"));
        }else{
            return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
        }        
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;

        emit BatchMetadataUpdate(0,66);
    }

    function mint(uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= maximumSupply, "Exceeds maximum supply");

        if(totalSupply() <= 0){
            setFirstTransferredBlock();
        }

        _mint(msg.sender, amount);
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(payable(msg.sender).send(balance));
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

}