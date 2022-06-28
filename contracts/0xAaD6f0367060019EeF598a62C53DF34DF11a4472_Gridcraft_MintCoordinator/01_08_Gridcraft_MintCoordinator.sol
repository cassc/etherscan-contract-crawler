//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//   ██████╗ ██████╗ ██╗██████╗  ██████╗██████╗  █████╗ ███████╗████████╗
//  ██╔════╝ ██╔══██╗██║██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔════╝╚══██╔══╝
//  ██║  ███╗██████╔╝██║██║  ██║██║     ██████╔╝███████║█████╗     ██║   
//  ██║   ██║██╔══██╗██║██║  ██║██║     ██╔══██╗██╔══██║██╔══╝     ██║   
//  ╚██████╔╝██║  ██║██║██████╔╝╚██████╗██║  ██║██║  ██║██║        ██║   
//   ╚═════╝ ╚═╝  ╚═╝╚═╝╚═════╝  ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝        ╚═╝   
//
// Website: https://gridcraft.net/
// Twitter: https://twitter.com/gridcraft
// Discord: https://discord.gg/gridcraft
//

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./INFT.sol";
import "./IERC1155.sol";
import "./ILlamaZoo.sol";

contract Gridcraft_MintCoordinator is Ownable {
  using ECDSA for bytes32;
  address public signer = 0xe506dbCA845412C04B6d4F7210D64098F58C5da1;

  mapping(uint256 => bool) public llamaVerseIdUsed;

  mapping(address => uint256) public identityMints;
  mapping(address => uint256) public landMints; 
  mapping(address => bool) public bundleMint;

  INFT public gridcraftIdentities;
  INFT public llamascapeLand;
  INFT LlamaVerse = INFT(0x9df8Aa7C681f33E442A0d57B838555da863504f3);
  ILlamaZoo LlamaStake = ILlamaZoo(0x48193776062991c2fE024D9c99C35576A51DaDe0);
  IERC1155 LlamaBoost = IERC1155(0x0BD4D37E0907C9F564aaa0a7528837B81B25c605);

  bool public allowSaleIsActive = false;
  bool public publicSaleIsActive = false;
  
  uint256 public identityPrice = 0.3 ether;
  uint256 public landPrice = 0.3 ether;
  uint256 public bundleSave = 0.04 ether;

  uint256[][] allowListMax = [[3,1], [1,2], [3,3]];
  uint256 public identityMax = 5;
  uint256 public landMax = 3;

  uint256 public bundlesAvailable = 1600;

  uint256 public landFreeMints;

  address withdrawWallet = 0x5d28e347583e70b5F7B0631CA5ab5575bD37Cbcd;

  constructor(address _gridcraftIdentitiesAddress,
              address _llamascapeLandAddress
  ) {
    gridcraftIdentities = INFT(_gridcraftIdentitiesAddress);
    llamascapeLand = INFT(_llamascapeLandAddress);
  }

  function allowListSale(uint256 _gridcraftAmount, uint256 _llamascapeAmount, bool _bundle, uint256 _wl, bool _stake, bytes memory _signature) external payable {
    require (allowSaleIsActive, "Not active");
    require (_gridcraftAmount <= gridcraftIdentities.remaining(), "Max identities supply reached");
    require (_llamascapeAmount <= llamascapeLand.remaining(), "Max land supply reached");
    require (msg.value == priceOfRequest(_gridcraftAmount, _llamascapeAmount, _bundle), "Wrong amount sent");

    bytes32 hash = hashTransaction(_msgSender(), _gridcraftAmount, _llamascapeAmount, _bundle, _wl);
    require(matchSignerAdmin(signTransaction(hash), _signature), "Signature mismatch");
    require (msg.sender == tx.origin, "bm8gcm9ib3Rz");

    if (_wl == 0) {
      require(_bundle || _llamascapeAmount == 0, "No land without bundle"); //❄️
    }
    if (_wl == 1) {
      require(_bundle || _llamascapeAmount == 1, "One land without bundle"); //❄️
    }

    if (_bundle){
      require (bundlesAvailable > 0, "Bundles exhausted");
      require (!bundleMint[msg.sender], "One bundle per wallet");
      unchecked{ --bundlesAvailable; }
      bundleMint[msg.sender] = true;
    }
    if (_gridcraftAmount > 0){
      require ( identityMints[msg.sender] + _gridcraftAmount <= allowListMax[_wl][0], "Exceeds allowance" );
      unchecked { identityMints[msg.sender] += _gridcraftAmount; }
      gridcraftIdentities.saleMint(msg.sender, _gridcraftAmount, _stake);
    }
    if (_llamascapeAmount > 0){
      require ( landMints[msg.sender] + _llamascapeAmount <= allowListMax[_wl][1], "Exceeds allowance" );
      unchecked { landMints[msg.sender] += _llamascapeAmount; }
      llamascapeLand.saleMint(msg.sender, _llamascapeAmount, _stake);
    }
  }

  function publicSale(uint256 _gridcraftAmount, uint256 _llamascapeAmount, bool _bundle, bool _stake) external payable {
    require(publicSaleIsActive, "Not active");
    require (_gridcraftAmount <= gridcraftIdentities.remaining(), "Max identities supply reached");
    require (_llamascapeAmount <= llamascapeLand.remaining(), "Max land supply reached");
    require (msg.value == priceOfRequest(_gridcraftAmount, _llamascapeAmount, _bundle), "Wrong amount sent");
    require (msg.sender == tx.origin, "bm8gcm9ib3Rz");

    if (_bundle){
      require (bundlesAvailable > 0, "Bundles exhausted");
      require (!bundleMint[msg.sender], "One bundle per wallet");
      unchecked{ --bundlesAvailable; }
      bundleMint[msg.sender] = true;
    } 
    if (_gridcraftAmount > 0){
      require ( identityMints[msg.sender] + _gridcraftAmount <= identityMax, "Exceeds allowance" );
      unchecked { identityMints[msg.sender] += _gridcraftAmount; }
      gridcraftIdentities.saleMint(msg.sender, _gridcraftAmount, _stake);
    }
    if (_llamascapeAmount > 0){
      require ( landMints[msg.sender] + _llamascapeAmount <= landMax, "Exceeds allowance" );
      unchecked { landMints[msg.sender] += _llamascapeAmount; }
      llamascapeLand.saleMint(msg.sender, _llamascapeAmount, _stake);
    }

  }

  function llamaverseSaleUnstaked(uint256[] memory _llamaVerseIds, bool _stake) external payable {
    require (allowSaleIsActive || publicSaleIsActive, "Not active");
    uint256 amount = _llamaVerseIds.length;
    require ( amount <= llamascapeLand.remaining(), "Max land supply reached");
    require ( msg.sender == tx.origin, "bm8gcm9ib3Rz");

    (, , , uint128 silverBoosts, uint128 goldBoosts) = LlamaStake.getStakedTokens(msg.sender);

    if (userHasLlamaboost(msg.sender) || silverBoosts > 0 || goldBoosts > 0){
      require(msg.value == 0, "Mint is free");
      unchecked { landFreeMints += amount; }
    } else {
      require(msg.value == amount * landPrice, "Wrong amount sent");
    }

    for (uint i; i < amount; ) {
      require ( LlamaVerse.ownerOf(_llamaVerseIds[i]) == msg.sender, "Llamaverse id not owned");
      require ( !llamaVerseIdUsed[_llamaVerseIds[i]], "Id already used");
      llamaVerseIdUsed[_llamaVerseIds[i]] = true;
      unchecked { ++i; }
    }
    llamascapeLand.saleMint(msg.sender, amount, _stake);
  }

  function llamaverseSaleStaked(uint256 _amount, bool _stake) external payable {
    require (allowSaleIsActive || publicSaleIsActive, "Not active");
    require ( _amount <= llamascapeLand.remaining(), "Max land supply reached");
    require ( msg.sender == tx.origin, "bm8gcm9ib3Rz");

    (uint256[] memory llamas, , , uint128 silverBoosts, uint128 goldBoosts) = LlamaStake.getStakedTokens(msg.sender);

    if (userHasLlamaboost(msg.sender) || silverBoosts > 0 || goldBoosts > 0){
      require(msg.value == 0, "Mint is free");
      unchecked { landFreeMints += _amount; }
    } else {
      require(msg.value == _amount * landPrice, "Wrong amount sent");
    }

    bool good;
    uint unusedLlamas;
    for (uint i; i < llamas.length; ) {
      if (!llamaVerseIdUsed[llamas[i]]){
        unchecked{ ++unusedLlamas; }
        llamaVerseIdUsed[llamas[i]] = true;
        if (unusedLlamas == _amount){
          good = true;
          break;
        }
      }
      unchecked { ++i; }
    }
    require(good, "Not enough unused staked llamas");
    llamascapeLand.saleMint(msg.sender, _amount, _stake);
  }


  // viewers

  function priceOfRequest(uint256 _gridcraftAmount, uint256 _llamascapeAmount, bool _bundle) public view returns(uint256 price) {
    price = _gridcraftAmount * identityPrice + _llamascapeAmount * landPrice;
    if (_bundle) {
      unchecked { price -= bundleSave; }
    }
  }

  function gridcraftTotalSupply() external view returns(uint256) {
    return gridcraftIdentities.totalSupply();
  }

  function llamascapeTotalSupply() external view returns(uint256) {
    return llamascapeLand.totalSupply();
  }

  function userHasLlamaboost(address _user) public view returns(bool) {
    return (LlamaBoost.balanceOf(_user, 1) != 0 || LlamaBoost.balanceOf(_user, 2) != 0);
  }

  function stakedLlamasUnused(address _user) public view returns(uint256 unused) {
    (uint256[] memory llamas, , , , ) = LlamaStake.getStakedTokens(_user);
    for (uint i; i < llamas.length ; ) {
      if (!llamaVerseIdUsed[llamas[i]]){
        unchecked { ++unused; }
      }
      unchecked { ++i; }
    }
  }

  // Owner setters

  function withdraw() external {
    require(msg.sender == withdrawWallet || msg.sender == owner(), "Not allowed");

    uint balance = address(this).balance;
    payable(withdrawWallet).transfer(balance);
  }

  function toggleAllowSale() external onlyOwner {
    allowSaleIsActive = !allowSaleIsActive;
  }

  function togglePublicSale() external onlyOwner {
    publicSaleIsActive = !publicSaleIsActive;
  }

  function setGridcraftIdentitiesAddress(address _gridcraftIdentitiesAddress) external onlyOwner {
    gridcraftIdentities = INFT(_gridcraftIdentitiesAddress);
  }

  function setLlamascapeLandAddress(address _llamascapeLandAddress) external onlyOwner {
    llamascapeLand = INFT(_llamascapeLandAddress);
  }

  function setPrices(uint256 _newIdentityPrice, uint256 _newLandPrice, uint256 _newDiscount) external onlyOwner {
    identityPrice = _newIdentityPrice;
    landPrice = _newLandPrice;
    bundleSave = _newDiscount;
  }

  function setSigner(address _newSigner) external onlyOwner {
    signer = _newSigner;
  }

  function setMaxIdentitiesPerWallet(uint256 _max) external onlyOwner {
    identityMax = _max;
  }

    function setMaxLandPerWallet(uint256 _max) external onlyOwner {
    landMax = _max;
  }

  // ECDSA related

  function hashTransaction(address _sender, uint256 _gridcraftAmount, uint256 _llamascapeAmount, bool _bundle, uint256 _wl) public pure returns (bytes32 _hash) {
    _hash = keccak256(abi.encode(_sender, _gridcraftAmount, _llamascapeAmount, _bundle, _wl));
  }
	
  function signTransaction(bytes32 _hash) public pure returns (bytes32) {
	  return _hash.toEthSignedMessageHash();
  }

  function matchSignerAdmin(bytes32 _payload, bytes memory _signature) public view returns (bool) {
	  return signer == _payload.recover(_signature);
  }

}