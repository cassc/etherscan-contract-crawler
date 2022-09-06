//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
//@0xSimon_

error SaleNotActive();
error Underpriced();
error NotWhitelisted();
error SoldOut();
error MaxMints();
error OilSaleNotActive();

contract Celephais is ERC721A, Ownable{
    using ECDSA for bytes32;

    uint constant maxSupply = 3333;
    uint constant public maxWlSupply = 2733;
    uint constant public maxOilMints = 500;
    uint public maxMintsPerWallet = 2;
    uint public wlCounter;
    uint public oilCounter;
    uint public presalePrice  = .077 ether;
    uint public publicPrice =   .099 ether;
    uint public OIL_PRICE = 195000 ether; //decimals are 18

    string public baseURI = "ipfs:/CID/";
    string public notRevealedURI = "ipfs://QmSWyUNKibpbXeRWmbg5FT55JxDQDQ8DZ2t3ircBbvr5wX";
    string uriSuffix = ".json";
    
    IERC20 public OIL = IERC20(0x5Fe8C486B5f216B9AD83C12958d8A03eb3fD5060);

    bool private revealed;
    
    enum SaleStatus {INACTIVE,DROWSY,PUBLIC}
    SaleStatus public saleStatus = SaleStatus.INACTIVE;

    address private signer = 0x592dacdB2a90683DA40096501F2ff1E82b00b9c7;

    mapping(address => mapping(uint=>uint)) public numMinted;

    constructor() ERC721A("Celephais","CLPH"){
        teamMint(0xB7f3aeFB9eBb90cB95D3C4e9c7ECB5c48d5D4384,8);
        transferOwnership(0xB7f3aeFB9eBb90cB95D3C4e9c7ECB5c48d5D4384);
    }
    

     /*/////////////////////////////////////////
                      MINTING
    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*/

    function teamMint(address to,uint amount) public onlyOwner{
        if(totalSupply() + amount > maxSupply) revert SoldOut();
        _mint(to,amount);
    }
    function airdrop(address[] calldata accounts, uint[] calldata amounts) external onlyOwner{
        for(uint i = 0; i<amounts.length;i++){
            if(totalSupply() + amounts[i] > maxSupply) revert SoldOut();
            _mint(accounts[i],amounts[i]);
        }
    }
    function drowsyEthMint(uint amount,uint max,bytes memory signature) external payable 
    {
        if(saleStatus != SaleStatus.DROWSY) revert SaleNotActive();
        if(msg.value <  presalePrice * amount) revert Underpriced();     
        bytes32 hash = keccak256(abi.encodePacked(max,msg.sender));
        address _signer = hash.toEthSignedMessageHash().recover(signature);
        if(signer != _signer) revert NotWhitelisted(); 
        if(wlCounter + amount > maxWlSupply) revert SoldOut();
        if(numMinted[msg.sender][0] + amount > maxMintsPerWallet) revert MaxMints();
        numMinted[msg.sender][0] += amount;
        wlCounter += amount;
        _mint(msg.sender,amount);
    }

    function drowsyOilMint(uint amount) external 
    {
        if(saleStatus == SaleStatus.INACTIVE) revert SaleNotActive();
        if(oilCounter + amount > maxOilMints) revert SoldOut();
        if(numMinted[msg.sender][1] + amount > maxMintsPerWallet) revert MaxMints();
        OIL.transferFrom(msg.sender, address(this), OIL_PRICE * amount);
        oilCounter += amount;
        numMinted[msg.sender][1] += amount;
        _mint(msg.sender,amount);
    }

    function publicMint(uint amount) external payable
    {
        if(saleStatus != SaleStatus.PUBLIC) revert SaleNotActive();
        if(msg.value <  publicPrice * amount) revert Underpriced();
        if(totalSupply() + amount > maxSupply) revert SoldOut();
        if(numMinted[msg.sender][2] + amount > maxMintsPerWallet) revert MaxMints();
        numMinted[msg.sender][2] += amount;
        _mint(msg.sender,amount);
    }

    

    /*/////////////////////////////////////////
                      SETTERS
    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*/
  
    function setBaseURI(string memory newUri) public onlyOwner {
        baseURI = newUri;
    }
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedURI = _notRevealedURI;
    }
    function setUriSuffix(string memory _suffix) external onlyOwner{
        uriSuffix = _suffix;
    }
    function flipRevealed() external onlyOwner{
        revealed = !revealed;
    }
    function startDrowsyMint() external onlyOwner {
        saleStatus = SaleStatus.DROWSY;
    }
    function startPublicMint() external onlyOwner {
        saleStatus = SaleStatus.PUBLIC;
    }
    function turnOffAllMints() external onlyOwner{
        saleStatus = SaleStatus.INACTIVE;
    }
    function setSigner(address _address) external onlyOwner{
        signer = _address;
    }

    function setOil(address _address) external onlyOwner{
        OIL = IERC20(_address);
    }
    function setPresalePrice(uint _newPrice) external onlyOwner{
        presalePrice = _newPrice;
    }
    function setPublicPrice(uint _newPrice) external onlyOwner{
        publicPrice = _newPrice;
    }
    function setOilPrice(uint oilPrice) external onlyOwner{
        OIL_PRICE = oilPrice;
    }
    function setMaxMintsPerWallet(uint _newMax) external onlyOwner{
        maxMintsPerWallet = _newMax;
    }
    
    

 
    /*////////////////////////////////////////
                    TOKEN FACTORY
    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*/
    function tokenURI(uint256 tokenId) public view override(ERC721A) 
    returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if(!revealed){
            return notRevealedURI;
        }
       
        return string(abi.encodePacked(baseURI,_toString(tokenId),uriSuffix));
       
    }




    /*/////////////////////////////////////////
                      WITHDRAW
    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*/
    function withdrawOIL() external onlyOwner{
        uint OIL_BALANCE = OIL.balanceOf(address(this));
        OIL.transfer(msg.sender, OIL_BALANCE);
    }

    function withdrawETH() external onlyOwner {
        uint balance = address(this).balance;
        (bool success,) = payable(owner()).call{value:balance}("");
        require(success);
    }
    
}


interface IERC20{
    function transferFrom(address from, address to, uint amount) external;
    function transfer(address to, uint amount) external;
    function balanceOf(address account) external view returns(uint);
}