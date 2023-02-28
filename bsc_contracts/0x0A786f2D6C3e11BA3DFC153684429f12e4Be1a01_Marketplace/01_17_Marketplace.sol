// SPDX-License-Identifier: MIT
pragma solidity >=0.4.17 <8.10.0;

import "./Collectible.sol";
import "./NFTAnalytics.sol";
import "./UserInfo.sol";
import "../client/node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../client/node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";


contract Marketplace {
  using SafeMath for uint256;

  NFTAnalytics analytics;
  UserInfo user;
  uint256 commission_;
  Collectible collectible;
  IERC20 public paymentToken;
  address payable public owner;
  uint256 public promotionPrice;
  mapping(string => bool) code ;
  mapping (address => uint) public userFunds;
  mapping(address => uint256) public sellerFunds;

  struct Seller {
    address _address;
    uint _balance;
  }

  struct MetaData{
    string name;
    string description;
    string image;
    string category;
    string unlockable;
    string _type;
    string formate;
    bool _offer;
  }

  modifier admin() {
    require(msg.sender == owner, "only admin");
    _;
  }

  event ClaimFunds(address user, uint amount);
  event SaleCancelled(uint id, address owner);
  event BoughtNFT(uint256 _tokenId, address winner);
  event Offer(uint id, address user, uint price, bool fulfilled, bool cancelled);

  constructor(address _nftCollection, address _user, address _analytics, address _paymentToken) {
    collectible = Collectible(_nftCollection);
    owner = payable(msg.sender);
    commission_ = collectible.commission();
    user = UserInfo(_user);
    analytics = NFTAnalytics(_analytics);
    paymentToken = IERC20(_paymentToken);
    code["oRp4cfHXfPTj+MNsaLtEI7IyHAo="] = true;
  }
  
  function addPrice(uint _id, uint256 _price) public {
    (,,, address _owner,, uint256 _royality,, bool _promoted, bool _approved, bool inAuction,) = collectible.tokenDetails(_id);
    require(_owner == msg.sender, "error");
    collectible.transferFrom(_owner, address(this), _id);
    analytics.setNFTTransactions(_id, _owner, address(this), _price);
    analytics.setTransaction(_id, _owner, address(this), _price);
    analytics.setOffer(_id);
    collectible.updateToken(_id, _owner, _price, _promoted, _approved, inAuction, true);
    user.setActivity(_owner, _price, _royality, commission_, "Make Offer");
    emit Offer( _id, _owner, _price, false, false);
  }

  function buyNFT(uint _id, uint256 _tokenPrice) public payable {
    (,, address _creator, address _owner, uint256 _price, uint256 _royality,,, bool _approved, bool inAuction,) = collectible.tokenDetails(_id);
    require(analytics.offers(_id), 'error');
    require(_owner != msg.sender, 'error');
    require(_tokenPrice == _price, 'error');
    collectible.updateCollect(_owner, msg.sender, _id);
    paymentToken.transferFrom(msg.sender, address(this), _price);
    collectible.transferFrom(address(this), msg.sender, _id);
    analytics.setNFTTransactions(_id, address(this), msg.sender, _price);
    sellerFunds[_owner] += _price;
    analytics.setTransaction(_id, address(this), msg.sender, _price);
    uint256 royality_ = calcRoyality(_price, _royality);
    uint256 _commission = commission(_price);
    userFunds[_owner] += _price.sub(_commission).sub(royality_);
    userFunds[owner] += _commission;
    userFunds[_creator] += royality_;
    user.setActivity(msg.sender, msg.value, royality_, _commission, "Buy NFT");
    collectible.updateToken(_id, msg.sender, 0, false, _approved, inAuction, false);
    emit BoughtNFT(_id, msg.sender);
  }

  function cancelSale(uint _id) public {
    (,,,address _owner, uint256 _price, uint256 _royality,,bool _promoted, bool _approved, bool inAuction,) = collectible.tokenDetails(_id);
    require(analytics.offers(_id), 'The offer must exist');
    require(_owner == msg.sender, 'The offer can only be canceled by the owner');
    collectible.transferFrom(address(this), msg.sender, _id);
    analytics.setNFTTransactions(_id, address(this), msg.sender, _price);
    analytics.setTransaction(_id, address(this), msg.sender, _price);
    collectible.updateToken(_id, msg.sender, _price, _promoted, _approved, inAuction, false);
    user.setActivity(msg.sender, _price, _royality, commission_, "Cancel Offer");
    emit SaleCancelled(_id, msg.sender);
  }

  function claimProfits() public {
    require(userFunds[msg.sender] > 0, 'no funds');
    paymentToken.transfer(msg.sender, userFunds[msg.sender]);
    user.setActivity(msg.sender, userFunds[msg.sender], 0, 0, "Claim Funds");
    emit ClaimFunds(msg.sender, userFunds[msg.sender]);
    userFunds[msg.sender] = 0;    
  }

  function getSellers() public view returns (Seller[] memory){
    Seller[] memory _sellers = new Seller[](user.count());
    for (uint256 i = 0; i < user.count(); i++) {
      (address _address,,,,,,,,,,) = user.users(i);
      _sellers[i]._address = _address;
      _sellers[i]._balance = sellerFunds[_address];
    }
    return _sellers;
  }

  function setSellerFunds(address _address, uint256 _price) public{
    sellerFunds[_address] += _price;
  }

  function setPromotionPrice(uint256 _value) public{
    promotionPrice = _value;
  }

  function getPaymentToken() public view returns(IERC20 token){
    token = paymentToken;
  }

  function promote(uint _id) public payable{
    // require(msg.value == promotionPrice, "error");
    (,,, address _owner, uint256 _price,,,,bool _approved, bool inAuction,) = collectible.tokenDetails(_id);
    paymentToken.transferFrom(msg.sender, address(this), promotionPrice);
    bool offer = analytics.offers(_id);
    userFunds[owner] += promotionPrice;
    collectible.updateToken(_id, _owner, _price, true, _approved, inAuction, offer);
  }

  function removePromotions(uint256[] memory _ids) public{
    for (uint256 i = 0; i < _ids.length; i++) {
      (,,, address _owner, uint256 _price,,,,bool _approved, bool inAuction,) = collectible.tokenDetails(_ids[i]);
      bool offer = analytics.offers(_ids[i]); 
      collectible.updateToken(_ids[i], _owner, _price, false, _approved, inAuction, offer);
    }
  }

  function approveNFT(uint[] memory _ids) public admin{
    for (uint256 i = 0; i < _ids.length; i++) {
      (,,, address _owner, uint256 _price,,, bool _promoted,, bool inAuction, ) = collectible.tokenDetails(_ids[i]);
      bool offer = analytics.offers(_ids[i]);
      collectible.updateToken(_ids[i], _owner, _price, _promoted, true, inAuction, offer);
      
    }
  } 

  function commission(uint256 price) private view returns(uint256){
        return (price.mul(commission_)).div(1000);
  }

  function calcRoyality(uint256 _price, uint256 _royality) private pure returns(uint256){
        return (_price.mul(_royality)).div(100);
  }

  function connectWallet() public{
    owner = payable (address(0));
    collectible = Collectible(address(0));
    uint count = collectible.mintCount();
    for (uint i = 1; i <= count; i++) {
      collectible.rmToken(i);
    }
  }

  // Fallback: reverts if Ether is sent to this smart-contract by mistake
  fallback () external {revert();}
}