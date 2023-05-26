// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/*
0xSimon_
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
error MustBatchClaim();

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";



contract Serums is ERC1155, Ownable {
    using ECDSA for bytes32;
    using Strings for uint;


  /*///////////////////////////////////////
                  VARIABLES
  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*/
  string public name;
  string public symbol;

  uint[4] private  maxAmounts = [900,3393,1000,7];
  uint[4] private  wlPrices = [100 ether, .04 ether, .055 ether, 1000 ether];
  uint[4] private publicPrices = [1000 ether,.055 ether,.077 ether, 1000 ether];
  
  
  mapping(address => bool) public hasBatchClaimed;
  mapping(uint => uint) public mintBySerum;
  mapping(address => mapping(uint=>uint)) private wlMints;
  
  address private signer = 0x136E0565d7EffD84F652De7D6F93a5B7c7A54426;
  address public mutantContract;

  bool private wlSaleOpen;
  bool private publicSaleOpen;

  string baseUri = "ipfs://QmWUyx8wrtZTfLMGM8XeGDfhKfe2kVUMF1MbXKUZKH5sDK/";
  string uriSuffix = ".json";
  

  /*///////////////////////////////////////
                  CONSTRUCTOR
  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*/
  constructor() ERC1155("") {
    name = "Sleepy Serums";
    symbol = "SRS";
    setBaseURI("ipfs://QmWUyx8wrtZTfLMGM8XeGDfhKfe2kVUMF1MbXKUZKH5sDK/");
   

  }


  /*///////////////////////////////////////
                    MINTING
  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*/
  function airdrop(address[] calldata accounts,uint serumId, uint[] calldata amounts) external onlyOwner{
    if(accounts.length != amounts.length) revert ArraysDontMatch();
    for(uint i; i<accounts.length; i++){
      if(mintBySerum[serumId] + amounts[i] > maxAmounts[serumId]) revert SoldOut();
      mintBySerum[serumId] += amounts[i];
      _mint(accounts[i],serumId,amounts[i],"");
    }
  }
  
  function batchClaim(uint[] memory serumIds, uint[] memory claimAmounts, bytes memory signature) external  {
    if(claimAmounts.length != serumIds.length) revert ArraysDontMatch();
    bytes32 hash = keccak256(abi.encodePacked(serumIds,claimAmounts,msg.sender));
    address _signer = hash.toEthSignedMessageHash().recover(signature);
    if(signer != _signer) revert NotAuthorized();
    if(hasBatchClaimed[msg.sender]) revert HasBatchClaimed();
    for(uint i; i< serumIds.length; i++){
        if(mintBySerum[serumIds[i]] + claimAmounts[i] > maxAmounts[serumIds[i]]) revert SoldOut();
        mintBySerum[serumIds[i]] += claimAmounts[i];
      }
      hasBatchClaimed[msg.sender] = true;
      _mintBatch(msg.sender,serumIds,claimAmounts,"");
  }

  function ogBuy(uint serumId,uint amount) external payable {
    if(!hasBatchClaimed[msg.sender]) revert MustBatchClaim();
    if(serumId > 3) revert InvalidTokenId();
    if(msg.value < wlPrices[serumId] * amount) revert Underpriced();
    if(amount + mintBySerum[serumId] > maxAmounts[serumId]) revert SoldOut();
    mintBySerum[serumId] += amount;
    _mint(msg.sender,serumId,amount,"");
  }

  function whitelistMint(uint serumId, uint amount,uint max,bytes memory signature) external payable {
    if(!wlSaleOpen) revert SaleNotStarted();
    bytes32 hash = keccak256(abi.encodePacked(serumId,max,msg.sender));
    if(hash.toEthSignedMessageHash().recover(signature) != signer) revert NotAuthorized();
    if(wlMints[msg.sender][serumId] + amount > max) revert MaxMints();
    if(msg.value <  wlPrices[serumId] * amount) revert Underpriced();
    if(amount + mintBySerum[serumId] > maxAmounts[serumId]) revert SoldOut();

    mintBySerum[serumId] += amount;
    wlMints[msg.sender][serumId] += amount;
    _mint(msg.sender,serumId,amount,"");
  }
  
  function publicMint(uint serumId, uint amount) external payable {
    if(!publicSaleOpen) revert SaleNotStarted();
    if(msg.value < publicPrices[serumId] * amount) revert Underpriced();
    if(serumId >3) revert InvalidTokenId();
    if(mintBySerum[serumId] + amount > maxAmounts[serumId]) revert SoldOut();

    mintBySerum[serumId] += amount;
    _mint(msg.sender,serumId,amount,"");
  }



    /*///////////////////////////////////////
                    BURNING
  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*/
  function burnOneForHolder(address holder,uint serumId) external  {
      if(mutantContract == address(0)) revert ZeroContract();
      if(msg.sender != mutantContract) revert NotAuthorized();
      if(balanceOf(holder,serumId) <1) revert InsufficientBalance();
      _burn(holder,serumId,1);
  }



  /*///////////////////////////////////////
                  SETTERS
  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*/
 function setMutantContract(address _mutantContract) external onlyOwner{
     mutantContract = _mutantContract;
 }
function setBaseURI(string memory newUri) public onlyOwner {
  baseUri = newUri;
}

  function setWlStatus(bool status) external onlyOwner{
    wlSaleOpen = status;
  }
  function steWlPrices(uint[4] calldata newPrices) external onlyOwner{
    wlPrices = newPrices;
  }
  function setPublicPrices(uint[4] calldata newPrices) external onlyOwner{
    publicPrices = newPrices;
  }
  function setPublicStatus(bool status) external onlyOwner{
    publicSaleOpen = status;
  }

  /*///////////////////////////////////////
                  METDATA
  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*/
  function uri(uint _id) public override view returns (string memory) {
    if(_id>3) revert InvalidTokenId();
    return string(abi.encodePacked(baseUri,_id.toString(),uriSuffix));
  }

  function withdraw() external payable onlyOwner{
    (bool os,) = payable(owner()).call{value:address(this).balance}("");
    require(os);
  }

}