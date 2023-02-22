// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract PixassoNft is Ownable, ERC721 {
  event UserTransferredToken(address from, address to, uint256 tokenId);
  event UserSavedToken(uint256 tokenId);

  struct Generations {
    uint256 creationBlock;
    string pixels;
    address originalOwnerDuringThisGeneration;
  }

  struct NftData {
    uint256 generationCounter;
    address currentOwner;
    mapping(uint256 => Generations) generation;
  }

  struct Orders{
    uint orderType;
    uint256 tokenId;
    bytes32 key;
    uint estimatedPrice;
    address customer;
    int creditForThis;
    bool paid;
  }

  struct UserCredit{
    int credit;
    bool doesExists;
  }

  mapping(bytes32 => Orders) private order;

  uint private tokenCounter = 0;

  mapping(uint256 => NftData) token;
  mapping(address => uint256[]) tokensOwnedByUser;

  mapping(address => UserCredit) pixelCreditOfUser;

  string private _currentBaseURI;

  constructor()
  ERC721("Pixasso", "PIXASSO") {
    setBaseURI("http://pixasso.io/backend/token/");
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    _currentBaseURI = baseURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _currentBaseURI;
  }

  function getOrder(bytes32 requestId) public view returns(uint orderType, uint256 tokenId, uint estimatedPrice, address customer, bool paid){
    orderType = order[requestId].orderType;
    tokenId = order[requestId].tokenId;
    estimatedPrice = order[requestId].estimatedPrice;
    customer = order[requestId].customer;
    paid = order[requestId].paid;
  }

  function placeOrder(uint orderType, uint256 tokenId, bytes32 requestId, bytes32 key, uint estimatedPrice, int creditForThis, address customer) public onlyOwner{
    if(orderType == 1){
      require(_exists(tokenId), "token not minted");
      require(customer == ownerOf(tokenId), "You are not the owner of the specified token.");
    }

    order[requestId].tokenId = tokenId;
    order[requestId].orderType = orderType;
    order[requestId].key = key;
    order[requestId].estimatedPrice = estimatedPrice;
    order[requestId].customer = customer;
    order[requestId].creditForThis = creditForThis;
    order[requestId].paid = false;
  }

  function getCreditsOfUser(address user) public view returns(int credit){
    if(!pixelCreditOfUser[user].doesExists){
      credit = 0;
    }else{
      credit = pixelCreditOfUser[user].credit;
    }
  }

  function completeOrder(bytes32 requestId, bytes32 key) public payable{
    require(order[requestId].key == key, "We could not find an order with the specified requestId and key.");
    require(order[requestId].paid == false, "This order is already paid.");

    if(order[requestId].orderType == 1){
      require(msg.sender == ownerOf(order[requestId].tokenId), "You are not the owner of the specified token.");
    }

    require(msg.value == order[requestId].estimatedPrice, "You did not provide enough ETH for the transaction.");

    if(!pixelCreditOfUser[order[requestId].customer].doesExists){
      pixelCreditOfUser[order[requestId].customer].credit = 0;
      pixelCreditOfUser[order[requestId].customer].doesExists = true;
    }

    if(order[requestId].creditForThis < 0){
      require(pixelCreditOfUser[order[requestId].customer].credit + order[requestId].creditForThis >= 0, "You want to use more credits than you have.");
    }

    payable(owner()).transfer(order[requestId].estimatedPrice);
    pixelCreditOfUser[order[requestId].customer].credit = pixelCreditOfUser[order[requestId].customer].credit + order[requestId].creditForThis;

    order[requestId].paid = true;
  }

  function testDeliverOrder(bytes32 requestId, string calldata plotData, uint testType) public onlyOwner{
    //need this for estimateTransactionGas cause deliverOrder would revert
    if(testType == 0){
      mint(msg.sender, plotData);
    }else if(testType == 1){
      updateToken(order[requestId].tokenId, plotData);
    }
  }

  function deliverOrder(bytes32 requestId, string calldata plotData) public onlyOwner{
    require(order[requestId].paid == true, "The order is not paid yet, reverting...");

    if(order[requestId].orderType == 0){
      mint(order[requestId].customer, plotData);
    }else if(order[requestId].orderType == 1){
      updateToken(order[requestId].tokenId, plotData);
    }

    delete order[requestId];
  }

  function deleteOrder(bytes32 requestId) public onlyOwner{
    delete order[requestId];
  }

  function mint(address proudOwner, string calldata pixelData) internal { //returns (bytes32 requestId)
    uint tokenId = tokenCounter;

    NftData storage data = token[tokenId];

    data.generationCounter = 0;
    data.generation[data.generationCounter].creationBlock = block.number;
    data.generation[data.generationCounter].pixels = pixelData;
    data.generation[data.generationCounter].originalOwnerDuringThisGeneration = proudOwner;
    data.currentOwner = proudOwner;

    _safeMint(proudOwner, tokenId);
    tokensOwnedByUser[proudOwner].push(tokenId);

    tokenCounter += 1;
  }

  function getAllTokenIdsOfUser() external view returns(uint256[] memory ownedTokens){
    ownedTokens = tokensOwnedByUser[msg.sender];
  }

  function get(uint256 tokenId, uint256 generationId) external view returns (uint256 creationBlock, string memory pixels, uint256 generationCounter, address ownerAddress, address originalOwnerDuringThisGeneration) {
    require(_exists(tokenId), "token not minted");

    require(token[tokenId].generationCounter >= generationId, "generation not found");

    NftData storage data = token[tokenId];

    creationBlock = data.generation[generationId].creationBlock;

    pixels = data.generation[generationId].pixels;

    generationCounter = data.generationCounter;

    originalOwnerDuringThisGeneration = data.generation[generationId].originalOwnerDuringThisGeneration;

    ownerAddress = ownerOf(tokenId);
  }

  function updateToken(uint tokenId, string memory plotPixels) internal {
    uint256 generationId = token[tokenId].generationCounter + 1;
    token[tokenId].generationCounter = generationId;

    token[tokenId].generation[generationId].pixels = plotPixels;
    token[tokenId].generation[generationId].creationBlock = block.number;
    token[tokenId].generation[generationId].originalOwnerDuringThisGeneration = ownerOf(tokenId);

    emit UserSavedToken(tokenId);
  }

  function totalSupply() public view returns (uint) {
    return tokenCounter;
  }

  function totalGenerations(uint256 tokenId) public view returns (uint total) {
    require(_exists(tokenId), "token not minted");

    total = token[tokenId].generationCounter;
  }

  function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual override {
    require(batchSize < 2, "Transfer can not be done in batches");
    require(to != address(0), "Token can not be transferred to null address, this means that the token can not be burned either.");
    if(from != address(0)){ //should not happen during mint since everything is setup already
      uint256[] memory tokensOfFromUser = tokensOwnedByUser[from];
      uint256 fromUserTokensLength = tokensOfFromUser.length;

      delete tokensOwnedByUser[from];

      for(uint i=0; i<fromUserTokensLength; ++i) {
        if(tokensOfFromUser[i] != firstTokenId){
          tokensOwnedByUser[from].push(tokensOfFromUser[i]);
        }
      }

      token[firstTokenId].currentOwner = to;
      tokensOwnedByUser[to].push(firstTokenId);
    }
    emit UserTransferredToken(from, to, firstTokenId);
  }
}