//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "[email protected]/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Saviour is ERC721A, Ownable {

    using   Strings for uint256;
    string  private unRevealedURL="ipfs://bafybeiehpzggmwnyxo3agh4utr3co3zkeyrfqdk2cfijodh3ebs7o7wue4/1.json";
    string  public baseURI;
    string  public baseExtension = ".json";
    bool    public pause;
    bool    public isRevealed; 
    uint    public immutable maxSupply =  10000;
    uint    public reservedNFTs = 200;
    uint    public publicSaleCost = 0.049 ether;
    uint    public preSaleCost = 0.033 ether;
    uint    public MintedFreeNFTs;

    mapping(address => uint) public totalHold;

    constructor() ERC721A("Saviours", "SV") {

        autoApproveMarketplace(0x1E0049783F008A0085193E00003D00cd54003c71); 
        autoApproveMarketplace(0xDef1C0ded9bec7F1a1670819833240f027b25EfF); 
        autoApproveMarketplace(0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e);
        autoApproveMarketplace(0x4feE7B061C97C9c496b01DbcE9CDb10c02f0a0Be);
        autoApproveMarketplace(0xF849de01B080aDC3A814FaBE1E2087475cF2E354);
    }

    ////////////////////////////////////////
    //     Auto Approve Market Places     //
    ////////////////////////////////////////

   function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    mapping(address => bool) private allowed;

    function autoApproveMarketplace(address _spender) public onlyOwner {
        allowed[_spender] = !allowed[_spender];
    }

    function isApprovedForAll(address _owner, address _operator) public view override(ERC721A) returns (bool) {
        if (_operator == OpenSea(0xa5409ec958C83C3f309868babACA7c86DCB077c1).proxies(_owner) ) return true;
        else if (allowed[_operator]) return true; 
        return super.isApprovedForAll(_owner, _operator);
    }

    //////////////////////////
    //     NFTs Minting     //
    //////////////////////////

    function mint(uint _howMuch) public payable callerIsUser checkWalletLimit(_howMuch) checkMintingLimit(_howMuch) checkNFTsAvailable(_howMuch) checkSaleStart{  
       
        if(totalHold[_msgSender()] == 0 && MintedFreeNFTs < 500 && totalSupply() < 1999){
            require(msg.value == ((_howMuch - 1) * preSaleCost), "You have insufficient balance.");
            _safeMint(_msgSender(), _howMuch);
            totalHold[_msgSender()] += _howMuch;
            ++MintedFreeNFTs;
        }
        else if((totalHold[_msgSender()] > 0 && totalSupply() < 1999) || (MintedFreeNFTs >= 500 && totalSupply() < 1999)){
            require(msg.value == (_howMuch * preSaleCost), "You have insufficient balance.");
            _safeMint(_msgSender(), _howMuch);
            totalHold[_msgSender()] += _howMuch;
        }
        else if(MintedFreeNFTs >= 500 && totalSupply() >= 1999){
            require(msg.value == (_howMuch * publicSaleCost), "You have insufficient balance.");
            _safeMint(_msgSender(), _howMuch);
            totalHold[_msgSender()] += _howMuch;
        }
    }

    //////////////////////////
    //     AIRDROP NFTs     //
    //////////////////////////

    function giftNFTs(address[] calldata _sendNftsTo, uint256 _Quantity) external onlyOwner checkNFTsAvailable(_sendNftsTo.length * _Quantity) 
    {
        reservedNFTs -= _sendNftsTo.length * _Quantity;
        for (uint256 i = 0; i < _sendNftsTo.length; i++)
            _safeMint(_sendNftsTo[i], _Quantity);
    }

    //////////////////////////
    //   NFTs Exploration   //
    //////////////////////////

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        if(isRevealed==true)
        {
            require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
            string memory currentBaseURI = _baseURI();
            return bytes(currentBaseURI).length > 0 ? string( abi.encodePacked( currentBaseURI, tokenId.toString(), baseExtension) ) : "";
        }
        else{
            require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
            return unRevealedURL;
        }

    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    ///////////////////////
    //  Owner functions  //
    ///////////////////////

    function reveal_collection() public onlyOwner{
        require(isRevealed!=true,"Collection is already revealed");
        isRevealed = true;
    } 

    function setPublicsaleCost(uint256 _newCost) public onlyOwner{
    publicSaleCost = _newCost;
    }

    function setPresaleCost(uint256 _newCost) public onlyOwner{
        preSaleCost = _newCost;
    }

    function setReservedNFTs(uint256 _Quantity) public onlyOwner{
        reservedNFTs = _Quantity;
    }    

    function setBaseURI(string memory _newBaseURI) public onlyOwner{
        baseURI = _newBaseURI;
    }

    function setUnrevealedURL(string memory _newBaseURI) public onlyOwner{
        unRevealedURL = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner{
        baseExtension = _newBaseExtension;
    }

    function setPause(bool _state) public onlyOwner{
        pause = _state;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
    
    function withdraw() public payable onlyOwner{
        payable(_msgSender()).transfer(address(this).balance);
    }

    //////////////////////
    //     Modifiers    //
    //////////////////////

    modifier checkNFTsAvailable(uint256 _Quantity) {
        require(_Quantity + totalSupply() + reservedNFTs <= maxSupply,  "The collection has been sold or try to mint less.");
        _;
    }

    modifier checkMintingLimit(uint256 _Quantity) {
        require(_Quantity >= 1 && _Quantity <= 4, "Try to mint less NFTs.");
        _;
    }

    modifier checkWalletLimit(uint _Quantity) {
        require(totalHold[_msgSender()] + _Quantity <= 4, "You already reached the maximum limit or may mint less.");
        _;
    }
    
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is a smart contract");
        _;
    }

    modifier checkSaleStart() {
        require(pause == true, "Minting paused by Owner.");
        _;
    }
    
}

interface OpenSea {
    function proxies(address) external view returns (address);
}