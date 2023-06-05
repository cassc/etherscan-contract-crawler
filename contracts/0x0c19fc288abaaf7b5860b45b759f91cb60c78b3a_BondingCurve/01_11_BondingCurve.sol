// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./BytesLib.sol";
import "./SignedWadMath.sol";
import "./iGUA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";




interface iCurve {
  function getFee(bytes32[] memory _queryhash) external view returns (uint256 fee);
  function getNextMintPrice() external view returns(uint256 price);
  function getNextBurnPrice() external view returns(uint256 price);
  function getCount() external view returns(uint256);
  function getMintPrice(uint256 _x) external view returns(uint256 price);
  function getPosFeePercent18() external view returns(int256);
  function resetCurve(int256 k18_, int256 L18_, int256 b18_, int256 posFeePercent18_, uint256 _reserveBalance) external returns(uint256 newReserve);
  function incrementCount(uint256 _amount) external;
  function decrementCount() external;
  function getNextBurnReward() external view returns(uint256 reward);
}

/** @title BondingCurve Contract
  * @author @0xAnimist
  * @notice First Onchain GIF, collaboration between Cai Guo-Qiang and Kanon
  */
contract BondingCurve is ERC721Holder, Ownable {
  address public _guaContract;
  address public _eetContract;
  bool public _frozen;

  uint256 public _ethReserveBalance;
  uint256 public _k21ReserveBalance;

  address public _k21TokenAddress;

  address public _royaltyRecipient;
  address public _guardians;

  int256 public _posFeeSplitForReferrers18;//% in wad of referrers share of POS

  address public _ethCurve;
  address public _k21Curve;

  bool public _freezeCurves;

  mapping(address => uint256) public _ethPOSBalances;
  mapping(address => uint256) public _k21POSBalances;


  constructor(address ethCurve_, address k21Curve_, address k21TokenAddress_, address initialRecipient_) Ownable(){
    _ethCurve = ethCurve_;
    _k21Curve = k21Curve_;
    _royaltyRecipient = initialRecipient_;
    _guardians = initialRecipient_;
    _k21TokenAddress = k21TokenAddress_;

    _posFeeSplitForReferrers18 = SignedWadMath.wadDiv(15, 100);//0.15 (15%)
  }

  function _setPOSFeeSplit(int256 posFeeSplitForReferrers18_) internal {
    int256 rangeTop = SignedWadMath.wadDiv(50, 100);
    int256 rangeBottom = SignedWadMath.wadDiv(15, 100);
    require(posFeeSplitForReferrers18_ >= rangeBottom && posFeeSplitForReferrers18_ <= rangeTop, "out of range");

    _posFeeSplitForReferrers18 = posFeeSplitForReferrers18_;
  }

  function pay(address _payee, uint256 _amount, uint256 _tokenCount, address _currency, bytes calldata _mintPayload) external payable returns(bool success) {
    int256 amount = int256(_amount);

    if(_currency == address(0)){//ETH
      require(msg.value == _amount, "wrong amount");

      int256 posFee18 = SignedWadMath.wadMul(iCurve(_ethCurve).getPosFeePercent18(), amount);

      //calculate fee split
      uint256 referrerShareOfPOS = uint256(SignedWadMath.wadMul(posFee18, _posFeeSplitForReferrers18));

      uint256 royaltyRecipientShareOfPOS = uint256(posFee18) - referrerShareOfPOS;

      //_royaltyRecipient credited with half POS fee
      _ethPOSBalances[_royaltyRecipient] += royaltyRecipientShareOfPOS;

      //referrer credited with half POS fee (or guardians if no referrer)
      if(_mintPayload.length >= 20){//there is a referrer
        _ethPOSBalances[BytesLib.toAddress(_mintPayload, 0)] += referrerShareOfPOS;
      }else{//no referrer
        _ethPOSBalances[_guardians] += referrerShareOfPOS;
      }

      uint256 reserve = _amount - uint256(posFee18);

      _ethReserveBalance += reserve;

      iCurve(_ethCurve).incrementCount(_tokenCount);
    }else{//K21
      require(_k21TokenAddress == _currency, "only K21");
      bool sent = IERC20(_k21TokenAddress).transferFrom(_payee, address(this), _amount);
      require(sent, "K21 not sent");

      int256 posFee18 = SignedWadMath.wadMul(iCurve(_k21Curve).getPosFeePercent18(), amount);


      //calculate fee split
      uint256 referrerShareOfPOS = uint256(SignedWadMath.wadMul(posFee18, _posFeeSplitForReferrers18));

      uint256 royaltyRecipientShareOfPOS = uint256(posFee18) - referrerShareOfPOS;

      //_royaltyRecipient credited with half POS fee
      _k21POSBalances[_royaltyRecipient] += royaltyRecipientShareOfPOS;

      //referrer credited with half POS fee (or guardians if no referrer)
      if(_mintPayload.length >= 20){//there is a referrer
        _k21POSBalances[BytesLib.toAddress(_mintPayload, 0)] += referrerShareOfPOS;
      }else{//no referrer
        _k21POSBalances[_guardians] += referrerShareOfPOS;
      }

      uint256 reserve = _amount - uint256(posFee18);

      _k21ReserveBalance += reserve;

      iCurve(_k21Curve).incrementCount(_tokenCount);
    }

    success = true;
  }

  function resetCurve(address _currency, int256 k18_, int256 L18_, int256 b18_, int256 posFeePercent18_, int256 posFeeSplitForReferrers18_) external onlyOwner returns(bool success){
    int256 rangeTop = SignedWadMath.wadDiv(55, 100);
    int256 rangeBottom = SignedWadMath.wadDiv(8, 100);
    require(posFeePercent18_ >= rangeBottom && posFeePercent18_ <= rangeTop, "out of range");


    uint256 newReserve;
    if(_currency == address(0)){//EthCurve
      newReserve = iCurve(_ethCurve).resetCurve(k18_, L18_, b18_, posFeePercent18_, _ethReserveBalance);
    }else{//K21Curve
      newReserve = iCurve(_k21Curve).resetCurve(k18_, L18_, b18_, posFeePercent18_, _k21ReserveBalance);
    }

    success = _flush(_currency, newReserve);

    //update fee split for referrer
    _setPOSFeeSplit(posFeeSplitForReferrers18_);
  }

  function _flush(address _currency, uint256 _reserve) internal returns(bool success){
    if(_currency == address(0)){//EthCurve
      uint256 ethRelease = _ethReserveBalance - _reserve;
      if(ethRelease > 0){
        int256 ethRelease18 = int256(ethRelease);

        //calculate flush split
        uint256 guardiansShareOfFlush = uint256(SignedWadMath.wadMul(ethRelease18, _posFeeSplitForReferrers18));

        uint256 royaltyRecipientShareOfFlush = uint256(ethRelease18) - guardiansShareOfFlush;

        require(address(this).balance >= royaltyRecipientShareOfFlush, "insuff bal R");

        (bool sent1,) = _royaltyRecipient.call{value: royaltyRecipientShareOfFlush, gas: gasleft()}("");
        require(sent1, "eth tx fail R");

        require(address(this).balance >= guardiansShareOfFlush, "insuff bal G");
        (bool sent2,) = _guardians.call{value: guardiansShareOfFlush, gas: gasleft()}("");
        require(sent2, "eth tx fail G");

        _ethReserveBalance -= ethRelease;//== _reserve
      }
    }else{//K21Curve
      uint256 k21Release = _k21ReserveBalance - _reserve;
      if(k21Release > 0){
        int256 k21Release18 = int256(k21Release);

        //calculate flush split
        uint256 guardiansShareOfFlush = uint256(SignedWadMath.wadMul(k21Release18, _posFeeSplitForReferrers18));

        uint256 royaltyRecipientShareOfFlush = uint256(k21Release18) - guardiansShareOfFlush;

        bool sent1 = IERC20(_k21TokenAddress).transfer(_royaltyRecipient, royaltyRecipientShareOfFlush);
        require(sent1, "k21 tx fail R");
        bool sent2 = IERC20(_k21TokenAddress).transfer(_guardians, guardiansShareOfFlush);
        require(sent2, "k21 tx fail G");

        _k21ReserveBalance -= k21Release;//== _reserve
      }
    }

    success = true;
  }

  function getBalances(address _account) external view returns(uint256 ethBalance, uint256 k21Balance) {
    return (_ethPOSBalances[_account], _k21POSBalances[_account]);
  }

  function withdraw() external returns(bool success) {
    if(_ethPOSBalances[msg.sender] > 0){
      // Use transfer to send Ether to the msg.sender, and handle errors
      (bool transferSuccess, ) = payable(msg.sender).call{value: _ethPOSBalances[msg.sender], gas: gasleft()}("");
      require(transferSuccess, "Ether withdraw fail");

      _ethPOSBalances[msg.sender] = 0; // Update the balance to zero

      success = true;
    }
    if(_k21POSBalances[msg.sender] > 0){
      // Use transfer to send K21 to the msg.sender, and handle errors
      bool transferSuccess = IERC20(_k21TokenAddress).transfer(msg.sender, _k21POSBalances[msg.sender]);
      require(transferSuccess, "K21 withdraw fail");

      _k21POSBalances[msg.sender] = 0; // Update the balance to zero

      success = true;
    }
  }

  function setRoyaltyRecipientAddress(address royaltyRecipient_) external {
    require(msg.sender == _royaltyRecipient, "not auth");
    _royaltyRecipient = royaltyRecipient_;
  }

  function setGuardiansAddress(address guardians_) external {
    require(msg.sender == _guardians, "not auth");
    _guardians = guardians_;
  }

  function setDependencies(address guaContract_, address eetContract_, bool _freeze) external onlyOwner {
    require(!_frozen, "frozen");
    _guaContract = guaContract_;
    _eetContract = eetContract_;
    _frozen = _freeze;
  }

  //Because the bonding curve will be the holder of GUA tokens
  function publishQuery(uint256 _tokenId, string memory _query) external {
    require(msg.sender == IERC721(_eetContract).ownerOf(_tokenId), "EET owner only");
    iGUA(_guaContract).publishQuery(_tokenId, _query);
  }

  function setCurves(address ethCurve_, address k21Curve_, bool _freeze) external onlyOwner {
    require(!_freezeCurves, "frozen");

    _ethCurve = ethCurve_;
    _k21Curve = k21Curve_;

    _freezeCurves = _freeze;
  }

  function getFee(uint256 _totalFortunes, address _currency) public view returns (uint256 fee) {
    address curve;
    if(_currency == address(0)){
      curve = _ethCurve;
    }else {
      curve = _k21Curve;
    }

    uint256 count = iCurve(curve).getCount();
    count++;
    for(uint256 i = 0; i < _totalFortunes; i++){
      fee += iCurve(curve).getMintPrice(count++);
    }
  }

  function redeemFortune(uint256 _tokenId, bytes32 _queryhash, uint256 _rand, string memory _encrypted) external returns(bool success){
    require(IERC721(_eetContract).ownerOf(_tokenId) == msg.sender, "not EET owner");

    return iGUA(_guaContract).redeemFortune(_tokenId, _queryhash, _rand, _encrypted);
  }

  function burnTo(uint256 _tokenId, address _owner, address payable _msgSender, address _currency, bytes memory _burnPayload) external returns (bool rewarded) {
    require(msg.sender == _eetContract, "only EET");
    uint256 reward;
    if(_currency == address(0)){
      reward = iCurve(_ethCurve).getNextBurnReward();
      iCurve(_ethCurve).decrementCount();

      (bool sent,) = _msgSender.call{value: reward, gas: gasleft()}("");
      require(sent, "Eth reward fail");

      _ethReserveBalance -= reward;
    }else{
      reward = iCurve(_k21Curve).getNextBurnReward();
      iCurve(_k21Curve).decrementCount();

      require(_k21TokenAddress == _currency, "only K21");
      bool sent = IERC20(_k21TokenAddress).transfer(_msgSender, reward);
      require(sent, "K21 reward fail");

      _k21ReserveBalance -= reward;
    }

    rewarded = true;
  }

}//end