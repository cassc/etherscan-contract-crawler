// SPDX-License-Identifier: MIT

import "../interfaces/IERC721.sol";
import "../interfaces/IERC20.sol";
import "../util/BmallMath.sol";
import "../util/Context.sol";

pragma solidity 0.8.15;

contract FeeManagerLogic is Context {
  using BmallMath for uint256;

  event AdminWithdraw(address tokenAddr, uint256 tokenAmount);
  event FeeClaim(address nftAddr, uint256[] tokenID, address[] paymentTokenAddrs, uint256[] paymentTokenAmounts);
  event CommunityFeeUpdate(address nftAddr, address paymentTokenAddr, uint256 cummunityFee);
  event SetWhiteList(address nftAddr, bool state);
  event Paused(address account);
  event Unpaused(address account);

  uint256 constant UNIFIEDPOINT = 10 ** 18;
  address constant NATIVECOINADDR = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

  address public implementationAddr;
  address public owner;
  address public wyvernProtocolAddr;
  bool private _paused;

  mapping(address => uint256) public nftTotalSupply;

  // This Variable is existed, because of "stack too deep"
  struct CummunityFeeParams {
    uint256 totalSupply;
    uint256 holdingPercent;
    uint256 tokenLength;
    uint256 totalClaimableAmount;
    uint256 rewardPerNFT;
  }

  // accumulatedCommunityFee[nftAddr][tokenAddr] = unifiedAmount
  mapping(address => mapping(address => uint256)) public accumulatedCommunityFee;

  // claimedCommunityFeeInCollection[nftAddr][tokenAddr] = unifiedAmount
  mapping(address => mapping(address => uint256)) public claimedCommunityFeeInCollection;

  // claimedCommunityFee[nftAddr][tokenAddr][nftID] = unifiedAmount
  mapping(address => mapping(address => mapping(uint256 => uint256))) public claimedCommunityFee;

  // NFT whiteList in feeClaim
  mapping(address => bool) public whiteList;

  modifier onlyOwner() {
    require(owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  modifier onlyWyvernProtocol() {
    require((wyvernProtocolAddr == msg.sender) || (owner == msg.sender), "Wyvernable: caller is not the WyvernProtocol contract");
    _;
  }

  modifier whenNotPaused() {
    _requireNotPaused();
    _;
  }

  modifier whenPaused() {
    _requirePaused();
    _;
  }

  /**
    * @dev Returns true if the contract is paused, and false otherwise.
    */
  function paused() public view returns (bool) {
    return _paused;
  }

  /**
    * @dev Throws if the contract is paused.
    */
  function _requireNotPaused() internal view {
    require(!paused(), "Pausable: paused");
  }

  /**
    * @dev Throws if the contract is not paused.
    */
  function _requirePaused() internal view {
    require(paused(), "Pausable: not paused");
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function _pause() internal whenNotPaused {
    _paused = true;
    emit Paused(_msgSender());
  }

  function _unpause() internal whenPaused {
    _paused = false;
    emit Unpaused(_msgSender());
  }

  function communityFeeUpdate(address nftAddr, address paymentTokenAddr, uint256 cummunityFee) external onlyWyvernProtocol {
    if(paymentTokenAddr == NATIVECOINADDR){
      accumulatedCommunityFee[nftAddr][NATIVECOINADDR] += cummunityFee;
    }else{
      IERC20 paymentToken = IERC20(paymentTokenAddr);
      uint256 underlyingDecimal = uint256(10 ** paymentToken.decimals());

      uint256 unifiedAmount = cummunityFee.underlyingToUnifiedAmount(underlyingDecimal);
      accumulatedCommunityFee[nftAddr][paymentTokenAddr] += unifiedAmount;
    }

    emit CommunityFeeUpdate(nftAddr, paymentTokenAddr, cummunityFee);
  }

  function batchFeeClaim(address[] memory nftAddr, uint256[][] memory tokenID, address[][] memory tokenAddrs) external whenNotPaused {
    for(uint256 i = 0; i < nftAddr.length; i++){
      _feeClaim(nftAddr[i], tokenID[i], tokenAddrs[i]);
    }
  }

  function adminWithdraw(address tokenAddr, uint256 tokenAmount) external onlyOwner {
    if(tokenAddr == NATIVECOINADDR){
      payable(owner).transfer(tokenAmount);
    }else{
      require(IERC20(tokenAddr).transfer(owner, tokenAmount));
    }
    emit AdminWithdraw(tokenAddr, tokenAmount);
  }

  function feeClaim(address nftAddr, uint256[] memory tokenID, address[] memory tokenAddrs) external whenNotPaused {
    _feeClaim(nftAddr, tokenID, tokenAddrs);
  }

  function _feeClaim(address nftAddr, uint256[] memory tokenID, address[] memory tokenAddrs) internal {
    // mitigation for flashloan attack based on NFT
    require(msg.sender == tx.origin);

    // mitigation for malicious nft contract, add whiteList require statement
    require(whiteList[nftAddr] == true, "only whitelist");

    IERC721 nft = IERC721(nftAddr);

    CummunityFeeParams memory cummunityFeeParams;
    cummunityFeeParams.totalSupply = _getTotalSupply(nftAddr);
    cummunityFeeParams.tokenLength = tokenID.length * UNIFIEDPOINT;


    // This code for blocking nft's minting. if specific nft is minted in Bmall, maybe this nft is blocked.
    if(nftTotalSupply[nftAddr] == 0){
      nftTotalSupply[nftAddr] = cummunityFeeParams.totalSupply;
    }
    require( nftTotalSupply[nftAddr] == cummunityFeeParams.totalSupply, "NFT totalSupply is changed");
    //

    uint256[] memory rewardAmount = new uint256[](tokenAddrs.length);

    for(uint256 tokenAddrIndex = 0; tokenAddrIndex < tokenAddrs.length; tokenAddrIndex++){
        address _tokenAddr = tokenAddrs[tokenAddrIndex];

        for(uint256 tokenIDIndex = 0; tokenIDIndex < tokenID.length; tokenIDIndex++) {
            uint256 _tokenID = tokenID[tokenIDIndex];
            address nftOwner = nft.ownerOf(_tokenID);
            require(nftOwner == msg.sender, "Do not match nft owners");

            cummunityFeeParams.rewardPerNFT = accumulatedCommunityFee[nftAddr][_tokenAddr].unifiedDiv(cummunityFeeParams.totalSupply);

            if(cummunityFeeParams.rewardPerNFT > claimedCommunityFee[nftAddr][_tokenAddr][_tokenID]){
                cummunityFeeParams.rewardPerNFT -= claimedCommunityFee[nftAddr][_tokenAddr][_tokenID];
            }else{
                continue;
            }

            claimedCommunityFee[nftAddr][_tokenAddr][_tokenID] += cummunityFeeParams.rewardPerNFT;
            claimedCommunityFeeInCollection[nftAddr][_tokenAddr] += cummunityFeeParams.rewardPerNFT;
            rewardAmount[tokenAddrIndex] += cummunityFeeParams.rewardPerNFT;
        }

        require(claimedCommunityFeeInCollection[nftAddr][_tokenAddr] <= accumulatedCommunityFee[nftAddr][_tokenAddr], "Over claimed fees");

        if(rewardAmount[tokenAddrIndex] > 0){
          if(tokenAddrs[tokenAddrIndex] == NATIVECOINADDR){
            payable(msg.sender).transfer(rewardAmount[tokenAddrIndex]);
          }else{
            IERC20 token = IERC20(tokenAddrs[tokenAddrIndex]);
            uint256 underlyingDecimal = uint256(10 ** token.decimals());
            uint256 underlyingAmount = rewardAmount[tokenAddrIndex].unifiedToUnderlyingAmount(underlyingDecimal);
            require(token.transfer(msg.sender, underlyingAmount));
          }
        }

    }

    emit FeeClaim(nftAddr, tokenID, tokenAddrs, rewardAmount);
  }

  // mitigation of totalSupply function not existed in erc721
  function _getTotalSupply(address nftAddr) internal view returns (uint256) {
    IERC721 erc721 = IERC721(nftAddr);

    try erc721.totalSupply() returns (uint256 _value) {
      return (_value * UNIFIEDPOINT);
    }
    catch {
      require(nftTotalSupply[nftAddr] != 0, "Err: nft totalSupply is 0");
      return nftTotalSupply[nftAddr];
    }
  }

  function setWhiteList(address _nftAddr, bool _state) external onlyOwner {
    whiteList[_nftAddr] = _state;
    emit SetWhiteList(_nftAddr, _state);
  }

  function setClaimedCommunityFeeInCollection(address _nftAddr, address _tokenAddr, uint256 _claimedAmount) external onlyOwner {
    claimedCommunityFeeInCollection[_nftAddr][_tokenAddr] = _claimedAmount;
  }

  function setClaimedCommunityFee(address _nftAddr, address _tokenAddr, uint256 _nftID, uint256 _claimedAmount) external onlyOwner {
    claimedCommunityFee[_nftAddr][_tokenAddr][_nftID] = _claimedAmount;
  }

  function setAccumulatedCommunityFee(address _nftAddr, address _tokenAddr, uint256 _accumulatedAmount) external onlyOwner {
    accumulatedCommunityFee[_nftAddr][_tokenAddr] = _accumulatedAmount;
  }

  function setOwner(address _owner) external onlyOwner {
    owner = _owner;
  }

  function setWyvernProtocolAddr(address _wyvernProtocolAddr) external onlyOwner {
    wyvernProtocolAddr = _wyvernProtocolAddr;
  }

  function getWhiteList(address _nftAddr) external view returns (bool) {
    return whiteList[_nftAddr];
  }

  function setNFTTotalSupply(address _nftAddr, uint256 _totalSupply) external onlyOwner {
    nftTotalSupply[_nftAddr] = _totalSupply;
  }

  function getNFTTotalSupply(address _nftAddr) external view returns (uint256) {
    return nftTotalSupply[_nftAddr];
  }

  function getWyvernProtocolAddr() external view returns (address) {
    return wyvernProtocolAddr;
  }

  function getRewardPerNFT(address _nftAddr, address _tokenAddr) external view returns (uint256) {
    return _getRewardPerNFT(_nftAddr, _tokenAddr);
  }

  function _getRewardPerNFT(address _nftAddr, address _tokenAddr) internal view returns (uint256) {
    uint256 totalSupply = _getTotalSupply(_nftAddr);
    uint256 rewardPerNFT = accumulatedCommunityFee[_nftAddr][_tokenAddr].unifiedDiv(totalSupply);
    return rewardPerNFT;
  }

  function getRewardAmount(address _nftAddr, address _tokenAddr, uint256 _tokenID) external view returns (uint256) {
    uint256 rewardPerNFT = _getRewardPerNFT(_nftAddr, _tokenAddr);
    return rewardPerNFT - claimedCommunityFee[_nftAddr][_tokenAddr][_tokenID];
  }

  function getClaimedCommunityFee(address _nftAddr, address _tokenAddr, uint256 _tokenID) external view returns (uint256) {
    return claimedCommunityFee[_nftAddr][_tokenAddr][_tokenID];
  }

  function getAccumulatedCommunityFee(address _nftAddr, address _tokenAddr) external view returns (uint256) {
    return accumulatedCommunityFee[_nftAddr][_tokenAddr];
  }

  receive() external payable {}
}