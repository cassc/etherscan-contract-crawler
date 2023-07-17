// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract NFT is ERC1155, Ownable {
  mapping (uint256 => address) public creators;
  mapping (uint256 => uint256) public tokenSupply;
  mapping (uint256 => Fees[]) public creatorFees;
  mapping (uint256 => uint256) public initialPrice;
  mapping (uint256 => string) customUri;
  // mapping (uint256 => MysteryBDetails) mysteryBoxes; // collection => token => {reveal count, total sold}
  // mapping (address => mapping (uint256 => uint32)) reveals;
  mapping (uint256 => uint32) private serviceFees;
  // mapping (uint256 => CollectionDetails) private collectionDetails; // collention => (child limit, [nft1, nft2, nft3])
  mapping (uint256 => uint256) private tokenPoolId;

  bool private enableMint = true;
  bool private enableChangeToken = false;
  // mapping(uint256 => mapping(address => uint256)) private balances;
  // Contract name
  string public name;
  // Contract symbol
  string public symbol;

  struct Fees {
    address receiver;
    uint32 percent;
  }

  // struct CollectionDetails {
  //   uint256 childLimit;
  //   uint256[] nfts;
  // }


  // struct MysteryBDetails {
  //   uint32 revealItems;
  //   uint256 totalSold;
  // }

  // uint256 public serviceFees = 200;
  address public marketplaceAddress; 

  struct TokenInfo {IERC20 paytoken; }
  TokenInfo[] public AllowedCrypto;

  /**
   * @dev Require _msgSender() to be the creator of the token id
   */
  modifier creatorOnly(uint256 _id) {
    require(creators[_id] == _msgSender(), "ERC1155Tradable#creatorOnly: ONLY_CREATOR_ALLOWED");
    _;
  }

  /**
   * @dev Require _msgSender() to own more than 0 of the token id
   */
  modifier ownersOnly(uint256 _id) {
    require(balanceOf(_msgSender(), _id) > 0, "ERC1155Tradable#ownersOnly: ONLY_OWNERS_ALLOWED");
    _;
  }

  event Mint(
    address indexed to, 
    uint256 indexed id,
    string indexed tokenUri,
    uint256  qty
  );

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _uri,
    // address _proxyRegistryAddress
    address _marketplaceAddress
  ) ERC1155(_uri) {
    name = _name;
    symbol = _symbol;
    marketplaceAddress = _marketplaceAddress;
    // proxyRegistryAddress = _proxyRegistryAddress;
    // _initializeEIP712(name);
  }

  function uri(
    uint256 _id
  ) override public view returns (string memory) {
    require(_exists(_id), "ERC1155Tradable#uri: NONEXISTENT_TOKEN");
    // We have to convert string to bytes to check for existence
    bytes memory customUriBytes = bytes(customUri[_id]);
    if (customUriBytes.length > 0) {
        return customUri[_id];
    } else {
        return super.uri(_id);
    }
  }

  function _exists(
    uint256 _id
  ) internal view returns (bool) {
    return creators[_id] != address(0);
  }

  function exists(
    uint256 _id
  ) external view returns (bool) {
    return _exists(_id);
  }

  /**
    * @dev Returns the total quantity for a token ID
    * @param _id uint256 ID of the token to query
    * @return amount of token in existence
    */
  function totalSupply(
    uint256 _id
  ) public view returns (uint256) {
    return tokenSupply[_id];
  }

  /**
   * @dev Sets a new URI for all token types, by relying on the token type ID
    * substitution mechanism
    * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
   * @param _newURI New URI for all tokens
   */
  function setURI(
    string memory _newURI
  ) public onlyOwner {
    _setURI(_newURI);
  }

  /**
   * @dev Will update the base URI for the token
   * @param _tokenId The token to update. _msgSender() must be its creator.
   * @param _newURI New URI for the token.
   */
  function setCustomURI(
    uint256 _tokenId,
    string memory _newURI
  ) public creatorOnly(_tokenId)  { 
    customUri[_tokenId] = _newURI;
    emit URI(_newURI, _tokenId);
  }

  function setCreator(
    address _to,
    uint256[] memory _ids
  ) public {
    require(_to != address(0), "ERC1155Tradable#setCreator: INVALID_ADDRESS.");
    for (uint256 i = 0; i < _ids.length; i++) {
      uint256 id = _ids[i];
      _setCreator(_to, id);
    }
  }

  function _setCreator(address _to, uint256 _id) internal creatorOnly(_id)
  {
      creators[_id] = _to;
  }

  function setCreatorOnlyOwner(address _to, uint256[] calldata _ids) external onlyOwner  {
    for (uint256 i = 0; i < _ids.length; i++) {
      creators[_ids[i]] = _to;
    }
  }

  function initiateToken(uint256 _tokenId, address _owner, uint256 _price, uint256 _supply, address[] calldata _creators, 
    uint32[] calldata _creatorFees, uint32 _serviceFees, uint256 _pId) external {
    require(!_exists(_tokenId), "tokenId already exists");
    tokenSupply[_tokenId] = _supply;
    creators[_tokenId] = _owner;
    initialPrice[_tokenId] = _price;
    serviceFees[_tokenId] = _serviceFees;
    tokenPoolId[_tokenId] = _pId;

    for (uint8 i=0; i<_creators.length; i++) {
      creatorFees[_tokenId].push(Fees(_creators[i], _creatorFees[i]));
    }

    // if(_mysteryBoxChilds > 0) {
    //   mysteryBoxes[_tokenId] = MysteryBDetails(_mysteryBoxChilds, 0); // n childs and zero sold till now
    // }
    // collectionDetails[_collectionId].childLimit = _mbContentLimits;
  }

  function initiateTokenMint(uint256 _tokenId, address _owner, string calldata _tokenURI, uint256 _supply, address[] calldata _creators, 
    uint32[] calldata _creatorFees, uint32 _serviceFees, uint256 _pId) external {
    require(enableMint, "Minting Paused");
    require(!_exists(_tokenId), "tokenId already exists");
    tokenSupply[_tokenId] = _supply;
    creators[_tokenId] = _owner;
    serviceFees[_tokenId] = _serviceFees;
    tokenPoolId[_tokenId] = _pId;

    for (uint8 i=0; i<_creators.length; i++) {
      creatorFees[_tokenId].push(Fees(_creators[i], _creatorFees[i]));
    }

    // if(_mysteryBoxChilds > 0) {
    //   mysteryBoxes[_tokenId] = MysteryBDetails(_mysteryBoxChilds, 0); // n childs and zero sold till now
    // }
    _mintOne(_owner, _tokenId, _tokenURI, _supply);
  }

  function setCreatorFees(uint256 _tokenId, address[] calldata _creators, uint8[] calldata _creatorFees) external creatorOnly(_tokenId) {
    require(_exists(_tokenId), "Invalid tokenId");
    
    delete creatorFees[_tokenId]; // delete before adding new
    for (uint8 i=0; i<_creators.length; i++) {
      creatorFees[_tokenId].push(Fees(_creators[i], _creatorFees[i]));
    }
  }

  function setServiceFees(uint256 _tokenId, uint32 _serviceFees) external onlyOwner{
    serviceFees[_tokenId] = _serviceFees;
  }

  function getServiceFees(uint256 _tokenId) external view onlyOwner returns (uint32){
    return serviceFees[_tokenId];
  }

  function setEnableMint(bool _enableMint) external onlyOwner{
    enableMint = _enableMint;
  }

  function getEnableMint() external view onlyOwner returns (bool){
    return enableMint;
  }

  function setEnableChangeToken(bool _enableTc) external onlyOwner{
    enableChangeToken = _enableTc;
  }

  function getEnableChangeToken() external view onlyOwner returns (bool){
    return enableChangeToken;
  }  

  function mint(address _to, uint256[] calldata _tokenIds, string[] calldata _tokenURIs, uint256[] calldata _qty, uint256 _pId, uint256 cost) external payable {
    require(enableMint, "Minting Paused");
    
    for (uint256 i = 0; i < _tokenIds.length; ++i) {
      require(_exists(_tokenIds[i]), "ERC1155Tradable#uri: NONEXISTENT_TOKEN");

      ///Normal
      if(_pId == 99999){ 
        require(initialPrice[_tokenIds[i]]*_qty[i] <= msg.value, "Insufficient fund sent");
      }
      else{
        //// item / token pool id == given pool id
        if(tokenPoolId[i] == _pId && _pId != 99999) {
            require(initialPrice[_tokenIds[i]]*_qty[i] <= cost, "Insufficient fund sent");
        }
        else {
          revert("Not Allowed");
        }
      }
     
      _mintOne(_to, _tokenIds[i], _tokenURIs[i], _qty[i]);
      // TODO send creator fees
      _sendCreatorEarnings(_tokenIds[i], _pId, cost);
    }
  }

  // function getTotalSoldChildsMB(uint256 _collectionId) view internal returns (uint256){
  //   uint256 soldNfts = 0;
  //   for (uint256 i = 0; i < collectionDetails[_collectionId].nfts.length; ++i) {
  //     soldNfts += mysteryBoxes[_collectionId][collectionDetails[_collectionId].nfts[i]].totalSold * mysteryBoxes[_collectionId][collectionDetails[_collectionId].nfts[i]].revealItems;
  //   }
  //   return soldNfts;
  // }

  function _mintOne(address _to, uint256 _tokenId, string calldata _tokenURI, uint256 _qty) internal {
    require(_exists(_tokenId), "Invalid tokenId");
    require(enableMint, "Minting Paused");

    // require(collectionDetails[_collectionId].childLimit >= getTotalSoldChildsMB(_collectionId), "No more Boxes left");

    // TODO fix the issue of partial fail
    if (bytes(_tokenURI).length > 0) {
      customUri[_tokenId] = _tokenURI;
      emit URI(_tokenURI, _tokenId);
    }
    _mint(_to, _tokenId, _qty, "");
    emit Mint(_to, _tokenId, _tokenURI, _qty);
    setApprovalForAll(marketplaceAddress, true);
  }

  /*
  * Only for Creators to premint their tokens
  */
  function create(address _to, uint256 _tokenId, string calldata _tokenURI, uint256 _qty) external creatorOnly(_tokenId){
    _mintOne(_to, _tokenId, _tokenURI, _qty);
  }

  function _sendCreatorEarnings(uint256 _tokenId, uint256 _pId, uint256 cost) internal {
    uint256 fees = 0;
    /////Non ERC 20 token
    if(_pId == 99999) {
        //// normal payment transfer
        payable(creators[_tokenId]).transfer(msg.value - fees - (msg.value*serviceFees[_tokenId]/10000));
    }
    else {
		uint256 totalCost = (cost - fees - (cost*serviceFees[_tokenId]/10000));
        IERC20 paytoken;
        TokenInfo storage tokens = AllowedCrypto[_pId];
        paytoken = tokens.paytoken;
        paytoken.transferFrom(msg.sender, creators[_tokenId], totalCost);
    }
    // disable creaor earning from minting form the main contract
    // for (uint256 i = 0; i < creatorFees[_tokenId].length; ++i) {
    //   fees += msg.value*creatorFees[_tokenId][i].percent/10000;
    //   payable(creatorFees[_tokenId][i].receiver).transfer(msg.value*creatorFees[_tokenId][i].percent/10000);
    // }
    
  }

  function bulkCreate(address _to, uint256[] calldata _tokenIds, string[] calldata _tokenURIs, uint256[] calldata _qty) external {
    require(enableMint, "Minting Paused");
    for (uint256 i = 0; i < _tokenIds.length; ++i) {
      this.create(_to, _tokenIds[i], _tokenURIs[i], _qty[i]);
    }
  }

  // function reveal(uint256 _tokenId, uint256[] calldata _revealItems, string[] calldata _tokenURIs, uint256[] calldata _qty) external ownersOnly(_tokenId){
  //   require(enableMint, "Minting Paused");
  //   require(mysteryBoxes[_tokenId].revealItems > 0, "Not a mystery Box");
  //   uint256 balance = this.balanceOf(_msgSender(), _tokenId);
  //   require(balance >= _revealItems.length, "Reveal limit exceeded");

  //   // revealItems
  //   for (uint256 i = 0; i < _revealItems.length; ++i) {
  //     _mintOne(_msgSender(), _revealItems[i], _tokenURIs[i], _qty[i]);
  //   }

  //   _burn(_msgSender(), _tokenId, _revealItems.length);
  //   // mapping (uint256 => uint32) mysteryBoxes;
  //   // mapping (address => mapping (uint256 => uint32)) reveals;

  // }

  function burn(address account, uint256 _tokenId, uint256 amount) external creatorOnly(_tokenId) {
    _burn(account, _tokenId, amount);
  }

  function burnBatch(address[] calldata _accounts, uint256[] calldata _tokenIds, uint256[] calldata _amounts) external {
    for (uint256 i = 0; i < _tokenIds.length; ++i) {
      this.burn(_accounts[i], _tokenIds[i], _amounts[i]);
    }
  }

  function withdrawFunds(uint256 withdrawAmount) external onlyOwner {
    require(address(this).balance > 0 && withdrawAmount <= address(this).balance, "Insufficient Fund");
    (bool success, ) = msg.sender.call{value: withdrawAmount}("");
    require(success, "Withdraw failed.");
  }
  
  function transferFund(uint256 transferAmount, address transferTo) external onlyOwner {
      require(address(this).balance > 0 && transferAmount <= address(this).balance, "Insufficient Fund");
      (bool success,) = transferTo.call{value: transferAmount}("");
      require(success, "Transfer Failed");
  }

  function addCurrency(IERC20 _paytoken) public onlyOwner {
    AllowedCrypto.push( TokenInfo({paytoken: _paytoken}) );
  }

  function withdrawToken(uint256 _pid) public payable onlyOwner() {
    TokenInfo storage tokens = AllowedCrypto[_pid];
    IERC20 paytoken;
    paytoken = tokens.paytoken;
    paytoken.transfer(msg.sender, paytoken.balanceOf(address(this)));
  }

  function setMarketplaceAddress(address _address) external onlyOwner{
    marketplaceAddress = _address;
  }
}