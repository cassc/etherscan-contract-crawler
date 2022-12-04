// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract NFT is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0 ether;
  uint256 public maxSupply = 25000;
  uint256 public maxMintAmount = 25000;
  bool public paused = false;
  bool public revealed = true;
  string public notRevealedUri;
  uint public priceIncrementEvery = 200;
  uint public priceIncrementValue = 0.175 ether;
  address payable fundWallet;
  address payable founder1 = payable(0x50A096afB9C9D424aE52f5bcD3F1869acD7fD98F);
  address payable founder2 = payable(0x54b6e86A23B2Fe78aF6CAdbA1D6f8Ed3A2131F23);
  address payable devWallet = payable(0x4a443081Ab78AaAb0CEFFfcE721410d93Ae8C8C2);

  mapping(uint=>uint) public rewardAmount;
  mapping(uint=>uint) internal lastClaimed;
  uint public dayCounter = 1;
  uint internal priceIncCounter = 0;
  uint private timestamp= block.timestamp;
  uint public totalRewardPerDay=3500000;
  IERC20 public rewardToken;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri,
    IERC20 _rewardToken
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
    rewardToken = _rewardToken;
    fundWallet = payable(msg.sender);
  }
  //events
  event Claim (uint);

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
    function declareReward() public onlyOwner{
    uint256 supply = totalSupply();
    rewardAmount[dayCounter]=(totalRewardPerDay*1 ether/supply);
    timestamp = timestamp+1 days;
    dayCounter++;
  }
  function claim(uint _tokenId) public returns (uint){
    require (ownerOf(_tokenId)==msg.sender);
    uint totalClaimable = claimableAmountforOne(_tokenId);
    lastClaimed[_tokenId] = dayCounter;
    rewardToken.transferFrom(owner(),msg.sender,totalClaimable);
    emit Claim(totalClaimable);
    return totalClaimable;
  }
  
  function claimAll() public{
    uint[] memory tokens = walletOfOwner(msg.sender);
    for (uint256 index = 0; index < tokens.length; index++) {
      uint element = tokens[index];
      claim(element);
    }
  }
  function totalClaimableAmount(address _owner) public view returns(uint){
  uint[] memory tokens = walletOfOwner(_owner);
  uint totalClaimable;
  for (uint256 index = 0; index < tokens.length; index++) {
    uint element = tokens[index];
    uint amount = claimableAmountforOne(element);
    totalClaimable+=amount;
  }
  return totalClaimable;
}
  function claimableAmountforOne(uint _tokenId) public view returns(uint){
    uint _lastClaimed = lastClaimed[_tokenId];
    uint totalClaimable;
    for(uint i = _lastClaimed; i<dayCounter; i++){
      totalClaimable+=rewardAmount[i];
    }
    return totalClaimable;
  }

  function mint(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused);
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount);
    require(supply + _mintAmount <= maxSupply);
    
    if (msg.sender != owner()) {
      require(msg.value >= cost * _mintAmount);
    }

    uint foundersCut = cost * _mintAmount/2/3;
    founder1.transfer(foundersCut);
    founder2.transfer(foundersCut);
    devWallet.transfer(foundersCut);

    for (uint256 i = 1; i <= _mintAmount; i++) {
      priceIncCounter++;
      _safeMint(msg.sender, supply + i);
      lastClaimed[supply + i]=dayCounter;
    }

    if(priceIncCounter>=priceIncrementEvery){
      uint increasedAmount = (priceIncCounter/priceIncrementEvery)*priceIncrementValue;
      priceIncCounter = getRemainder(priceIncCounter,priceIncrementEvery);
      cost+=increasedAmount;
    }
  }
  function mintFor(uint256 _mintAmount, address _walet) public payable onlyOwner{
    uint256 supply = totalSupply();
    require(!paused);
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount);
    require(supply + _mintAmount <= maxSupply);
    
    if (msg.sender != owner()) {
      require(msg.value >= cost * _mintAmount);
    }

    uint foundersCut = cost * _mintAmount/2/3;
    founder1.transfer(foundersCut);
    founder2.transfer(foundersCut);
    devWallet.transfer(foundersCut);

    for (uint256 i = 1; i <= _mintAmount; i++) {
      priceIncCounter++;
      _safeMint(_walet, supply + i);
      lastClaimed[supply + i]=dayCounter;
    }

    if(priceIncCounter>=priceIncrementEvery){
      uint increasedAmount = (priceIncCounter/priceIncrementEvery)*priceIncrementValue;
      priceIncCounter = getRemainder(priceIncCounter,priceIncrementEvery);
      cost+=increasedAmount;
    }
  }

  function _transfer(
      address from,
      address to,
      uint256 tokenId
  ) internal override {
      if (totalSupply()<maxSupply) {
        require(msg.sender==owner(),"You can not transfer any token/node untill all tokens are sold.");
      } 
      super._transfer(from, to, tokenId);

  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  function getRemainder(uint _dividend, uint _divisor) public pure returns(uint){
      uint quotient = _dividend/_divisor;
      return _dividend-(quotient*_divisor);
  }

  function setIncValue(uint _value) public onlyOwner{
    priceIncrementValue = _value;
  }

  function setIncEvery(uint _value) public onlyOwner{
    priceIncrementEvery = _value;
  }

  function setRewardPerDay(uint _value) public onlyOwner{
    totalRewardPerDay = _value;
  }
  function setMaxSupply(uint _value) public onlyOwner{
    maxSupply = _value;
  }

  //only owner
  function reveal() public onlyOwner {
      revealed = true;
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function changeFundAddress(address _founder) public {
    require (msg.sender == founder1 || msg.sender == founder2 || msg.sender == devWallet || msg.sender == fundWallet, "You must be one of the founder to execute this");
    if(msg.sender==founder1){
      founder1 = payable(_founder);
    } else if(msg.sender==founder2){
      founder2 = payable(_founder);
    }else if(msg.sender==devWallet){
      devWallet = payable(_founder);
    }else if(msg.sender==fundWallet){
      fundWallet = payable(_founder);
    }
  }
 
  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(fundWallet).call{value: address(this).balance}("");
    require(os);
  }
}