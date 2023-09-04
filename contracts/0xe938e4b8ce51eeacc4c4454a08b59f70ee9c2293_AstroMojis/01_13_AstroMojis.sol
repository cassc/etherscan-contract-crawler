// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract AstroMojis is ERC721Enumerable, Ownable {
    uint256 public MintPrice = 77700000000000000;
    uint256 public WhiteListMintPrice = 55500000000000000;
    uint256 public WhiteListSupply = 3333;
    uint256 public Supply = 4445;
    string public BaseURI;
    bool public SaleActive;
    bool public WhiteListActive;
    bool public supplyLocked;
    bool public metadataFrozen;
    mapping(address => bool) private WhiteList;  
    event LockSupply(bool _supplyLocked);
    event FreezeMetadata(bool _frozen);

    constructor(string memory baseURI) ERC721("AstroMojis", "ASJ1"){
        BaseURI = baseURI;
    }

    /*
    Below are functions accesseble to the owner of the contract.
    These are admin functions to alter state.
    */

    function setMintPrice(uint256 _priceWei) public onlyOwner {
        MintPrice = _priceWei;
    }

    function setWhiteListMintPrice(uint256 _priceWei) public onlyOwner {
        WhiteListMintPrice = _priceWei;
    }

    function adjustWhiteListSupply(uint256 newWLSupply) public onlyOwner{
        require(!supplyLocked, "Supply has been permanently locked");
        WhiteListSupply = newWLSupply;
    }

    function adjustSupply(uint256 newSupply) public onlyOwner {
        require(!supplyLocked, "Supply has been permanently locked");
        Supply = newSupply;
    }
    
    function lockSupply() public onlyOwner {
        supplyLocked = true; 
        emit LockSupply(true);
        //Once function called, supply is permanently set and no longer variable
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        require(!metadataFrozen, "Metadata has been locked and permenantly decentralized");
        BaseURI = newBaseURI;
    }

    function freezeMetadata() public onlyOwner {
        metadataFrozen = true;
        emit FreezeMetadata(true);
        //Once function called, BaseURI can no longer be altered
    }

    function addToWhitelist(address[] memory members, bool addOrRemove) external onlyOwner {
        for (uint256 i = 0; i < members.length; i++){
            WhiteList[members[i]] = addOrRemove; 
        }
    }

    function pauseWhitelist() public onlyOwner {
        WhiteListActive = !WhiteListActive;
    }

    function pause() public onlyOwner {
        SaleActive = !SaleActive;
    }

    function reserve(uint256 numberOfTokens, address reciever) public onlyOwner{
        uint256 s = totalSupply();
        require(s + numberOfTokens + 1 <= Supply+ 1, "Supply minted out");
        for (uint256 i = 0; i < numberOfTokens; i++){
            _safeMint(reciever, s + i + 1);
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }


    /*
    Below are public payable functions that alter contract state.
    */

    function mint(uint256 numberOfTokens) public payable {
        require(SaleActive, "Sale not active");
        require(MintPrice*numberOfTokens <= msg.value, "Incorrect value sent");
        uint256 s = totalSupply();
        require(s + numberOfTokens + 1 <= Supply+ 1, "Sold out");
        require(numberOfTokens <= 20, "Limited to 20 tokens per tx");
        require(numberOfTokens > 0, "Must mint at least 1");
        for (uint256 i = 0; i < numberOfTokens; i++){
            _safeMint(msg.sender, s+i+1);
        }
    }

    function mintWhiteList(uint256 numberOfTokens) public payable {
        require(WhiteListActive, "Whitelist is not active");
        uint256 s = totalSupply();
        require(s + numberOfTokens + 1 <= WhiteListSupply + 1, "Whitelist minted out"); 
        require(WhiteList[msg.sender], "You are not whitelisted");
        require(WhiteListMintPrice*numberOfTokens <= msg.value, "Incorrect value sent");
        require(numberOfTokens <= 20, "You can only mint 20 tokens at a time");
        require(numberOfTokens > 0, "Must mint at least 1");
        for (uint256 i = 0; i < numberOfTokens; i++){
            _safeMint(msg.sender, s+i+1);
        }
    }

    /*
    Below are functions that are publicly available to view 
    contract state.
    */

    function OnWhiteList(address minter) public view returns (bool){
        return WhiteList[minter];
    }

    function contractURI() public view returns (string memory) {
        string memory baseURI = _baseURI();
        return string(abi.encodePacked(baseURI, "contract.json"));
    }

    /*
    Below are internal functions that are not publicly available
    and do not alter contract state.
    */

    function _baseURI() internal view virtual override returns (string memory) {
        return BaseURI;
    }
    
}