//999

pragma solidity >=0.8.0 <0.9.0;

import "https://github.com/chiru-labs/ERC721A/blob/main/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Revelation is ERC721A, Ownable { 

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    bool public paidSaleOpen;
    bool public freeSaleOpen;
    bool public revealed = false;
    string public baseURI = "";  
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;
    
    
 
    uint256 public  maxFreePerAdress = 1;    
    uint256 public  maxFreeSupply = 999; 

    uint256 public  maxPerTx = 3;              
    uint256 public  maxPerWallet = 6;                
    uint256 public  maxSupply = 999;                  
    uint256 public  cost = 0.005 ether;                

    mapping(address => bool) public userMintedFree;

    constructor() ERC721A("Revelation 2022", "RVN") {     
        paidSaleOpen = true;
        freeSaleOpen = true;
        setHiddenMetadataUri("ipfs://bafybeietahbpbdyn65lml5r4zwreajwlu5vwco2tnnq3do3gzmztqmdxnu/stillsleeping.json");
       
    }

    function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string(
            abi.encodePacked(
              baseURI,
              Strings.toString(_tokenId), ".json"
            )
        ) : "";
    }

    function ownerMint(address mintTo, uint256 numOfTokens) external onlyOwner {
        _safeMint(mintTo, numOfTokens);
    }

    function paidMintEnvoy(uint256 numOfTokens) external payable callerIsUser {
        require(paidSaleOpen, "Sale is not active yet");
        require(totalSupply() + numOfTokens < maxSupply, "Exceed max supply"); 
        require(numOfTokens <= maxPerTx, "Can't create more in a txn");
        require(numberMinted(msg.sender) + numOfTokens <= maxPerWallet, "Can't create this many");
        require(msg.value >= cost * numOfTokens, "Insufficient funds provided to mint");

        _safeMint(msg.sender, numOfTokens);
    }

    function freeMintEnvoy(uint256 numOfTokens) external callerIsUser {
        require(freeSaleOpen, "FreeSale is not active yet");
        require(totalSupply() + numOfTokens < maxFreeSupply, "Exceed max free supply, use paidMintEnvoy to mint"); 
        require(numOfTokens <= maxFreePerAdress, "Can't create more for free");
        require(numberMinted(msg.sender) + numOfTokens <= maxFreePerAdress, "Can't create this many");

        userMintedFree[msg.sender] = true;
        _safeMint(msg.sender, numOfTokens);
    }

        function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
    }
    
    function _startTokenId() internal pure override returns (uint) {
	return 1;
    }

    function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
    }

    function seturiSuffix(string memory _newuriSuffix) public onlyOwner {
    uriSuffix = _newuriSuffix;
    }

    function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function withdrawFunds() public onlyOwner {
        uint256 balance = accountBalance();
        require(balance > 0, "No funds to withdraw");
        
        _withdraw(payable(msg.sender), balance);
    }

    function _withdraw(address payable account, uint256 amount) internal {
        (bool sent, ) = account.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function accountBalance() internal view returns(uint256) {
        return address(this).balance;
    }

    function isSaleOpen() public view returns (bool) {
        return paidSaleOpen;
    }

    function isFreeSaleOpen() public view returns (bool) {
        return freeSaleOpen && totalSupply() < maxFreeSupply;
    }
//supply settings
    function setMaxFreePerAdress(uint256 _maxFreePerAdress) public onlyOwner {
    maxFreePerAdress = _maxFreePerAdress;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
    }
    
    function setMaxFreeSupply(uint256 _maxFreeSupply) public onlyOwner {
    maxFreeSupply = _maxFreeSupply;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) public onlyOwner {
    maxPerWallet = _maxPerWallet;
    }

    function setMaxPerTx(uint256 _maxPerTx) public onlyOwner {
    maxPerTx = _maxPerTx;
    }
}

//"is this everything?"
//SPDX-License-Identifier: MIT