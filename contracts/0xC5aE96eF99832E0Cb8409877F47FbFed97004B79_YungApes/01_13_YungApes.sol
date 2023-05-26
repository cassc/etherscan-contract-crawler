// SPDX-License-Identifier: None

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";




contract YungApes is Ownable, ERC721 {
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  
  uint256 public mintPrice = 42000000000000000;
  uint256 public mintLimitPerTx = 10;
  uint256 public mintLimitPerAddress = 20;
  uint256 public maxSupply = 6969;
  uint256 private publicNextId = 697;
  uint256 private privateWhitelistNextId = 1;
  uint256 private maxWhitelistAddresses = 696;

  Counters.Counter private _tokenIdCounter;


  bool public preSaleState = false;
  bool public publicSaleState = false;

  
  string public baseURI;

  address private deployer;
  address payable private gnosisWallet;

  mapping (address => uint256[]) private tokenIdsOfAddresses;
  mapping (uint256 => address) private addressesOfTokenIds;
  mapping (address => uint256) public mintedByAddress;

  event GnosisWalletSet (address indexed newGnosisAddress);

  constructor() ERC721("Yung Ape Squad", "YAS") { 
    deployer = msg.sender;
  }
  
  modifier whitelisted {
    require(tokenIdsOfAddresses[msg.sender].length > 0, "You aren't whitelisted!");
    _;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string calldata newBaseUri) external onlyOwner {
    baseURI = newBaseUri;
  }

  function addToWhitelist(address[] memory wallets) public onlyOwner {
    require(wallets.length + privateWhitelistNextId <= maxWhitelistAddresses +1, "This would exceed max whitelist spots.");

    for(uint i = 0; i < wallets.length; i++) {
      tokenIdsOfAddresses[wallets[i]].push(privateWhitelistNextId);
      addressesOfTokenIds[privateWhitelistNextId] = wallets[i];
      privateWhitelistNextId++;
    }

  }

  function whitelistedIdsOfWallet (address wallet) public view returns(uint256[] memory tokenIds){
    return tokenIdsOfAddresses[wallet];
  }

  function setGnosisSafeWallet(address payable _newAddress) public onlyOwner {
    gnosisWallet = _newAddress;
    emit GnosisWalletSet(gnosisWallet);
  }

  function changeStatePreSale() external onlyOwner returns(bool) {
      preSaleState = !preSaleState;
      return preSaleState;
  }
  
  function changeStatePublicSale() external onlyOwner returns(bool) {
    publicSaleState = !publicSaleState;
    return publicSaleState;
  }
  
  function claimYungApe(uint tokenId) external whitelisted{
    require(preSaleState, "Presale is not active");

    mintInternalPresale(msg.sender, tokenId);
  }

  function claimYungApeMultiple(uint256[] memory _tokenIds) external whitelisted{
    require(preSaleState, "Presale is not active");
    require(_tokenIds.length <= tokenIdsOfAddresses[msg.sender].length, "You aren't whitelisted for this amount of tokens.");

    for(uint256 _index = 0; _index < _tokenIds.length; _index++){
      if(!_exists(_tokenIds[_index])){
        mintInternalPresale(msg.sender, _tokenIds[_index]);
      }
    }


  }

  function mint(uint256 numberOfTokens) external payable {
    require(publicSaleState, "Sale is not active");
    require(numberOfTokens <= mintLimitPerTx, "Too many tokens for one transaction");
    uint256 currentMintedByAddress = mintedByAddress[msg.sender];
    require(currentMintedByAddress + numberOfTokens <= mintLimitPerAddress, "You don't have enough mints left for minting this many tokens for this address");
    require(msg.value >= mintPrice.mul(numberOfTokens), "Insufficient payment");

    mintInternal(msg.sender, numberOfTokens);
  }

  function mintInternal(address wallet, uint amount) internal {
    require(publicNextId.add(amount) <= maxSupply, "Not enough tokens left");

    
    for(uint i = 0; i< amount; i++){
    _safeMint(wallet, publicNextId);
    publicNextId++;
    _tokenIdCounter.increment();
    mintedByAddress[wallet] ++;
    }

  }

  function mintInternalPresale(address wallet, uint tokenId) internal {

    uint currentTokenSupply = totalSupply();
    require(currentTokenSupply.add(1) <= maxSupply, "Not enough tokens left");
    require(!_exists(tokenId),"Token already exists?");
    require(addressesOfTokenIds[tokenId] == wallet, "You weren't holding this id when the snapshot was taken");

    
    
    _safeMint(wallet, tokenId);
    _tokenIdCounter.increment();
    mintedByAddress[wallet] ++;
    
    
    
    
    
    
  }

 
  function reserve(uint256 amount) external onlyOwner {
    mintInternal(msg.sender, amount);
    mintedByAddress[msg.sender] -= amount;
    
  }

  function withdraw() external onlyOwner {
    require(address(this).balance > 0, "No balance to withdraw");
    uint256 balance = address(this).balance;
    gnosisWallet.transfer(balance/4);
    payable(deployer).transfer(address(this).balance); 
  }


  function isClaimed(uint tokenId) external view returns(bool tokenExists){
    return _exists(tokenId);
  }

    function totalSupply() public view returns (uint){
    return _tokenIdCounter.current();
  }

  function tokensOfOwner(address _owner, uint startId, uint endId) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index = 0;

            for (uint256 tokenId = startId; tokenId < endId; tokenId++) {
                if (index == tokenCount) break;

                if (ownerOf(tokenId) == _owner) {
                    result[index] = tokenId;
                    index++;
                }
            }

            return result;
        }
  }

}