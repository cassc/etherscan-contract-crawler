// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/*

*/
error InvalidTokenId();
error NotAuthorized();
error SoldOut();
error HasBatchClaimed();
error ZeroContract();
error InsufficientBalance();
error Underpriced();
error MaxMints();
error SaleNotStarted();
error ArraysDontMatch();
error AlreadyMinted();
error MaxMintsPerTx();
error CantMintZero();
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";




contract Silk is ERC1155, ERC1155Supply, Ownable {
    using ECDSA for bytes32;
    using Strings for uint;


  /*///////////////////////////////////////
                  VARIABLES
  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*/
  uint constant silkTokenId = 0;
  uint public maxSupply = 2250;
  uint public price = .99 ether;
  uint public maxMintsPerTxPublic = 1;
  string public name;
  string public symbol;
  address private signer = 0x6884efd53b2650679996D3Ea206D116356dA08a9;
  enum SaleStatus{INACTIVE, SILK, OG,RESERVE,PUBLIC}
  SaleStatus public saleStatus = SaleStatus.SILK;
  string baseUri = "ipfs://QmWBb72STMYvSa5j41LVxwPkXL9yyjbo6RZWFMTpWodH7g";

  //Mints carry over on each sale
  mapping(address => uint) public tokenMints;

  /*///////////////////////////////////////
                  CONSTRUCTOR
  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*/
  constructor() ERC1155("") {
    name = "Silk";
    symbol = "SILK";
    _mint(0x4c5b3a1f4999c0a5def76543Fceab81bc53D95f4, silkTokenId, 1,"");

  }


  /*///////////////////////////////////////
                    MINTING
  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*/
  function airdrop(address[] calldata accounts, uint[] calldata amounts) external onlyOwner {
    if(accounts.length != amounts.length) revert ArraysDontMatch();
    for(uint i; i<accounts.length; i++){
        if(totalSupply(silkTokenId) + amounts[i] > maxSupply) revert SoldOut();
        _mint(accounts[i],silkTokenId, amounts[i],"");
    }  
  }
  function verifyForSale(string memory phase,uint max,address account,bytes memory signature) internal view returns(bool) {
    bytes32 hash = keccak256(abi.encodePacked(phase,max,account));
    return signer == hash.toEthSignedMessageHash().recover(signature);
  }
  function silkMint(uint amount,uint max,bytes memory signature) external payable {
    if(amount == 0 ) revert CantMintZero();
    if(totalSupply(silkTokenId) + amount > maxSupply) revert SoldOut();
    if(tokenMints[msg.sender]  + amount > max ) revert MaxMints();
    if(saleStatus != SaleStatus.SILK) revert SaleNotStarted();
    if(!verifyForSale("SILK",max,msg.sender, signature)) revert NotAuthorized();
    if(msg.value < price * amount) revert Underpriced();
    tokenMints[msg.sender] += amount;
    _mint(msg.sender,silkTokenId,amount,"");
  }

  function ogMint(uint amount, uint max,bytes memory signature) external payable {
    if(amount == 0 ) revert CantMintZero();
    if(totalSupply(silkTokenId) + amount > maxSupply) revert SoldOut();
    if(tokenMints[msg.sender] + amount > max) revert MaxMints();
    if(saleStatus != SaleStatus.OG) revert SaleNotStarted();
    if(!verifyForSale("OG",max,msg.sender, signature)) revert NotAuthorized();
    if(msg.value < price * amount) revert Underpriced();
    tokenMints[msg.sender] += amount;
    _mint(msg.sender,silkTokenId,amount,"");
  }

  function reserveMint(uint amount, uint max,bytes memory signature) external payable {
    if(amount == 0 ) revert CantMintZero();
    if(totalSupply(silkTokenId) + amount > maxSupply) revert SoldOut();
    if(tokenMints[msg.sender] + amount > max) revert MaxMints();
    if(saleStatus != SaleStatus.RESERVE) revert SaleNotStarted();
    if(!verifyForSale("RESERVE",max,msg.sender, signature)) revert NotAuthorized();
    if(msg.value < price * amount) revert Underpriced();
    tokenMints[msg.sender] += amount;
    _mint(msg.sender,silkTokenId,amount,"");
  }

  function publicMint(uint amount) external payable {
    if(amount == 0 ) revert CantMintZero();
    if(totalSupply(silkTokenId) + amount > maxSupply) revert SoldOut();
    if(amount > maxMintsPerTxPublic) revert MaxMintsPerTx();
    if(saleStatus != SaleStatus.PUBLIC) revert SaleNotStarted();
    if(msg.value < price * amount) revert Underpriced();
    _mint(msg.sender,silkTokenId,amount,"");
  }



  /*///////////////////////////////////////
                  SETTERS
  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*/

function setBaseURI(string memory newUri) public onlyOwner {
  baseUri = newUri;
}

  function turnSilkSaleOn() external onlyOwner{
    saleStatus = SaleStatus.SILK;
  }
  function turnOgOn() external onlyOwner{
    saleStatus = SaleStatus.OG;
  }
  function turnReserveOn() external onlyOwner{
    saleStatus = SaleStatus.RESERVE;
  }
  function turnPublicOn() external onlyOwner{
    saleStatus = SaleStatus.PUBLIC;
  }
  function turnAllSalesOff() external onlyOwner{
    saleStatus = SaleStatus.INACTIVE;
  }
  function setPrice(uint newPrice) external onlyOwner{
    price = newPrice;
  }
  function setMaxMintsPerTxPublic(uint max) external onlyOwner {
    maxMintsPerTxPublic = max;
  }
  function setMaxSupply(uint max) external onlyOwner {
    maxSupply = max;
  }
  function setSigner(address newSigner) external onlyOwner {
    signer = newSigner;
  }




  /*///////////////////////////////////////
                  METDATA
  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*/
  function uri(uint _id) public override view returns (string memory) {
    if(_id != silkTokenId) revert InvalidTokenId();
    return baseUri; 
  }

  function withdraw() external  onlyOwner{
    (bool os,) = payable(owner()).call{value:address(this).balance}("");
    require(os);
  }

  function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
  internal
  override(ERC1155, ERC1155Supply)
{
  super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
}


}