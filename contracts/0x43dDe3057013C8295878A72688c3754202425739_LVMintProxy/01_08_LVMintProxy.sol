// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Address.sol";
import "../../Common/Delegated.sol";
import "../../Common/Merkle.sol";

import "hardhat/console.sol";

interface ILlamaBoost{
  function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns(uint256[] memory);
}

interface ILlamaVerse{
  function balanceOf(address) external view returns(uint256);
}

interface ILlamaZoo{
  struct Staker {
    uint256[] stakedLlamas;
    uint256 stakedPixletCanvas;
    uint256 stakedLlamaDraws;
    uint128 stakedSilverBoosts;
    uint128 stakedGoldBoosts;
  }

  function getStakedTokens(address) external view returns (Staker memory);
}

interface IWLP{
  function mintTo(uint16[] calldata quantity, address[] calldata recipient, bool isLlamaverse) external payable;
}

contract LVMintProxy is Delegated, Merkle {
  ILlamaBoost public llamaBoost = ILlamaBoost(0x0BD4D37E0907C9F564aaa0a7528837B81B25c605);
  ILlamaVerse public llamaVerse = ILlamaVerse(0x9df8Aa7C681f33E442A0d57B838555da863504f3);
  ILlamaZoo public llamaZoo = ILlamaZoo(0x48193776062991c2fE024D9c99C35576A51DaDe0);
  IWLP public wlp = IWLP(0x5e4Cd61E666d610392701934651bd90367984483);

  enum SaleState{
    NONE,
    LLAMASALE, //1
    LISTSALE,  //2
    PUBLICSALE //3
  }

  struct MintConfig{
    uint64 ethPrice;
    uint64 discPrice;
    uint64 boostPrice;

    uint16 maxMint;
    uint16 maxOrder;
    uint16 maxSupply;

    SaleState saleState;
  }

  MintConfig public config = MintConfig(
    0.12 ether, //ethPrice
    0.10 ether, //discPrice
    0.09 ether, //boostPrice
     132,       //maxMint
     132,       //maxOrder
    4000,       //maxSupply

    SaleState.NONE
  );

  mapping(address => uint16) public numberMinted;
  uint256 public totalSupply;

  //payable
  function mint(uint16 quantity, bytes32[] calldata proof) external payable {
    //checks
    MintConfig memory cfg = config;
    require(uint8(cfg.saleState) > 0, "Sale is not active");
    require(numberMinted[msg.sender] + quantity <= cfg.maxMint, "Mint/Order exceeds wallet limit");
    require(quantity <= cfg.maxOrder, "Order too big");
    require(totalSupply + quantity <= cfg.maxSupply, "Mint/Order exceeds supply");
    if(!_isValidProof( keccak256( abi.encodePacked( msg.sender ) ), proof))
      revert( "Wallet not allowed" );

    require(numberMinted[msg.sender] + quantity <= _countLlamaVerse(msg.sender), "Mint/Order exceeds owner limit");

    uint256 usePrice;
    if(_countLlamaBoost(msg.sender) > 0)
      usePrice = config.boostPrice;
    else
      usePrice = config.discPrice;
    require(msg.value == quantity * usePrice, "Ether sent is not correct");

    //effects
    totalSupply += quantity;
    numberMinted[msg.sender] += quantity;

    //interactions
    address[] memory accounts = new address[](1);
    accounts[0] = msg.sender;

    uint16[] memory quantities = new uint16[](1);
    quantities[0] = quantity;

    wlp.mintTo{ value: msg.value }(quantities, accounts, true);
  }

  function setConfig(MintConfig memory newConfig) public onlyDelegates{
    MintConfig memory cfg = config;
    require(totalSupply <= newConfig.maxSupply, "existing supply must be lte new max supply");
    require(cfg.maxSupply >= newConfig.maxOrder, "existing max supply must be gte new max order");
    require(5 > uint8(newConfig.saleState), "invalid sale state");
    require(newConfig.maxSupply <= 4000, "supply exceeds global limit");

    config = newConfig;
  }

  function setLlamaProxies(ILlamaBoost boost, ILlamaVerse verse, ILlamaZoo zoo) external onlyDelegates{
    llamaBoost = boost;
    llamaVerse = verse;
    llamaZoo = zoo;
  }


  //view
  function getPrice(address account) public view returns(uint256) {
    require(_countLlamaVerse(account) > 0, "Must be a Llamaverse holder");

    if(_countLlamaBoost(account) > 0)
      return config.boostPrice;
    else
      return config.discPrice;
  }


  //internal
  function _countLlamaBoost(address account) private view returns(uint256) {
    uint256 total = 0;
    if(address(llamaBoost) != address(0)){
      address[] memory accounts = new address[](2);
      accounts[0] = account;
      accounts[1] = account;

      uint256[] memory tokens = new uint256[](2);
      tokens[0] = 1;
      tokens[1] = 2;

      uint256[] memory counts = llamaBoost.balanceOfBatch(accounts, tokens);
      total += counts[0] + counts[1];
    }

    if(total == 0){
      if(address(llamaZoo) != address(0)){
        ILlamaZoo.Staker memory staker = llamaZoo.getStakedTokens(account);
        total += staker.stakedSilverBoosts + staker.stakedGoldBoosts;
      }
    }

    return total;
  }

  function _countLlamaVerse(address account) private view returns(uint256) {
    uint256 total = 0;
    if(address(llamaVerse) != address(0)){
      total += llamaVerse.balanceOf(account);
      console.log(total);
    }

    if(address(llamaZoo) != address(0)){
      ILlamaZoo.Staker memory info = llamaZoo.getStakedTokens(account);
      total += info.stakedLlamas.length;
    }

    return total;
  }
}