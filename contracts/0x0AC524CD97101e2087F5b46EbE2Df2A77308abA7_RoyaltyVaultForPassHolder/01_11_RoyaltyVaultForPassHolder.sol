// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/** 
 * ___  ____ _                                                   
 * |  \/  (_) |                                                  
 * | .  . |_| |_ __ _ _ __ ___   __ _                            
 * | |\/| | | __/ _` | '_ ` _ \ / _` |                           
 * | |  | | | || (_| | | | | | | (_| |                           
 * \_|  |_/_|\__\__,_|_| |_| |_|\__,_|                                                                           
 * ______                  _ _           _   _             _ _   
 * | ___ \                | | |         | | | |           | | |
 * | |_/ /___  _   _  __ _| | |_ _   _  | | | | __ _ _   _| | |_ 
 * |    // _ \| | | |/ _` | | __| | | | | | | |/ _` | | | | | __|
 * | |\ \ (_) | |_| | (_| | | |_| |_| | \ \_/ / (_| | |_| | | |_ 
 * \_| \_\___/ \__, |\__,_|_|\__|\__, |  \___/ \__,_|\__,_|_|\__|
 *              __/ |             __/ |                          
 *             |___/             |___/                           
 * 
 * produced by http://mitama-mint.com/
 * written by zkitty.eth
 */

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract RoyaltyVaultForPassHolder is AccessControl, Pausable, ReentrancyGuard{
  using SafeMath for uint256;
  uint256 public requestId = 0;
  uint256 public receiveETHId = 0;
  IERC20 public WETH;
  address payable public TEAM_WALLET;

  /**
   * Request and Receive management 
   */
  mapping(address=>Amount) public claimablePerAccount;
  mapping(address=>Amount) public withdrawnPerAccount;
  struct Amount {
    uint256 amountETH;
    uint256 amountWETH;
  }
  mapping(uint256=>Request) public requestIdToRequest;
  struct Request{
      uint256 amount;
      bool isWETH;
      uint256 tokenId;
      address[] members;
  }
  struct MembersAmount {
      address[] member;
      uint256 amount;
  }

  bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");
  bytes32 public constant REQUESTER_ROLE = keccak256("REQUESTER_ROLE");
  bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE");
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  
  constructor(address WETH_, address TEAM_WALLET_) {
      WETH = IERC20(WETH_);
      TEAM_WALLET = payable(TEAM_WALLET_);
      _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
      _grantRole(WITHDRAWER_ROLE, msg.sender);
      _grantRole(REQUESTER_ROLE, msg.sender);
      _grantRole(SETTER_ROLE, msg.sender);
      _grantRole(PAUSER_ROLE, msg.sender);
  }

  /**
   * Event
   */
  event ReceivedETH(uint256 receiveETHId, uint256 amount);
  event RequestAdded(uint256 requestId, bool isWETH, uint tokenId, uint256 amount, address[] members);
  event RequestRemoved(uint256 requestId, bool isWETH, uint tokenId, uint256 amount, address[] members);
  event Withdrawed(address indexed account, uint256 indexed amountETH, uint256 indexed amountWETH);
  event Sweeped(address indexed account, address desctination, uint256 indexed amountETH, uint256 indexed amountWETH);
  event WETHAddressUpdated(address previousAddress, address newAddress);
  event TeamWalletUpdated(address previousAddress, address newAddress);

  error InvalidAddress();
  function setWETH(address _addr) external onlyRole(SETTER_ROLE) {
      if(_addr == address(0)) revert InvalidAddress();
      IERC20 _WETH = WETH;
      WETH = IERC20(_addr);
      emit WETHAddressUpdated(address(_WETH), _addr);
  }

  function setTeamWallet(address wallet) external onlyRole(SETTER_ROLE) {
      if(wallet == address(0)) revert InvalidAddress();
      address _wallet = address(TEAM_WALLET);
      TEAM_WALLET = payable(wallet);
      emit TeamWalletUpdated(_wallet, wallet);
  }

  error InvalidTokenId();
  error InvalidMembers();
  error ZeroAmountRequest();
  error DivisionFailure(uint256 numerator, uint256 demoninator);
  function addRequest(uint256 amount, bool isWETH, uint tokenId, address[] memory members) external onlyRole(REQUESTER_ROLE) {
    if(tokenId >= 10000) revert InvalidTokenId();
    if(members.length == 0 ||  members.length > 7) revert InvalidMembers();
    if(amount == 0) revert ZeroAmountRequest();

    requestId ++;
    Request memory request = Request(amount, isWETH, tokenId, members);
    requestIdToRequest[requestId] = request;
    (bool res, uint256 revenuePerMember) = amount.tryDiv(members.length);
    if(!res) revert DivisionFailure(amount, members.length);
    for(uint i=0; i<members.length; i++) {
      if (isWETH) {
        claimablePerAccount[members[i]].amountWETH += revenuePerMember;
      } else {
        claimablePerAccount[members[i]].amountETH += revenuePerMember;
      }
    }
    emit RequestAdded(requestId, isWETH, tokenId, amount, members);
  }

  error InvalidRequestId();
  error RequestIdDoesntExist();
  function removeRequest(uint256 _requestId)external onlyRole(REQUESTER_ROLE){
    if(_requestId > requestId) revert InvalidRequestId();
    if(requestIdToRequest[_requestId].amount == 0) revert RequestIdDoesntExist();
    
    Request memory request = requestIdToRequest[_requestId];
    delete requestIdToRequest[_requestId];
    uint256 amount = request.amount;
    address[] memory members = request.members;
    bool isWETH = request.isWETH;
    uint256 tokenId = request.tokenId;
    (bool res, uint256 revenuePerMember) = amount.tryDiv(members.length);
    if(!res) revert DivisionFailure(amount, members.length);
    for(uint i=0; i<members.length; i++) {
      if (isWETH) {
        claimablePerAccount[members[i]].amountWETH -= revenuePerMember;
      } else {
        claimablePerAccount[members[i]].amountETH -= revenuePerMember;
      }
    }
    emit RequestRemoved(requestId, isWETH, tokenId, amount, members);
  }
  
  receive() external payable {
    ++receiveETHId;
    emit ReceivedETH(receiveETHId, msg.value);
  }

  /**
   * withdraw functions
   */
  
  error AccountHasNoClaimableAmount();
  function withdraw() external payable nonReentrant whenNotPaused {
    uint256 claimableETH = claimablePerAccount[msg.sender].amountETH;
    uint256 claimableWETH = claimablePerAccount[msg.sender].amountWETH;
    if(claimableETH == 0 && claimableWETH == 0) revert AccountHasNoClaimableAmount();
    if(claimableETH> 0 && _isETHClaimable(claimableETH)) {
      claimablePerAccount[msg.sender].amountETH -= claimableETH;
      withdrawnPerAccount[msg.sender].amountETH += claimableETH;
      _transfer(payable(msg.sender), claimableETH);
    }
    if(claimableWETH> 0 && _isWETHClaimable(claimableWETH)){
      claimablePerAccount[msg.sender].amountWETH -= claimableWETH;
      withdrawnPerAccount[msg.sender].amountWETH += claimableWETH;
      IERC20(WETH).transfer(msg.sender, claimableWETH);
    }
    emit Withdrawed(msg.sender, claimableETH, claimableWETH);
  }

  function batchWithdraw(address[] memory addressList) external payable onlyRole(WITHDRAWER_ROLE) nonReentrant {
    for(uint256 i; i < addressList.length; i++){
      address recipient = addressList[i];
      uint256 claimableETH = claimablePerAccount[recipient].amountETH;
      uint256 claimableWETH = claimablePerAccount[recipient].amountWETH;
      if(claimableETH == 0 && claimableWETH == 0) revert AccountHasNoClaimableAmount();
      if(claimableETH > 0 && _isETHClaimable(claimableETH)) {
        claimablePerAccount[recipient].amountETH -= claimableETH;
        withdrawnPerAccount[recipient].amountETH += claimableETH;
        _transfer(payable(recipient), claimableETH);
      }
      if(claimableWETH > 0 && _isWETHClaimable(claimableWETH)) {
        claimablePerAccount[recipient].amountWETH -= claimableWETH;
        withdrawnPerAccount[recipient].amountWETH += claimableWETH;
        IERC20(WETH).transfer(recipient, claimableWETH);
      }
      emit Withdrawed(recipient, claimableETH, claimableWETH);
    }
  }

  error InvalidWallet();
  function sweep(address[] memory addressList) external payable onlyRole(WITHDRAWER_ROLE) nonReentrant {
    if(TEAM_WALLET == address(0)) revert InvalidWallet();
    for(uint256 i; i < addressList.length; i++){
      uint256 claimableETH = claimablePerAccount[addressList[i]].amountETH;
      uint256 claimableWETH = claimablePerAccount[addressList[i]].amountWETH;
      if(claimableETH == 0 && claimableWETH == 0) revert AccountHasNoClaimableAmount();
      if(claimableETH > 0 && _isETHClaimable(claimableETH)) {
        claimablePerAccount[addressList[i]].amountETH -= claimableETH;
        withdrawnPerAccount[addressList[i]].amountETH += claimableETH;
        _transfer(TEAM_WALLET, claimableETH);
      }
      if(claimableWETH > 0 && _isWETHClaimable(claimableWETH)) {
        claimablePerAccount[addressList[i]].amountWETH -= claimableWETH;
        withdrawnPerAccount[addressList[i]].amountWETH += claimableWETH;
        IERC20(WETH).transfer(TEAM_WALLET, claimableWETH);
      }
      emit Sweeped(addressList[i], TEAM_WALLET, claimableETH, claimableWETH);
    }
  }

  /*
   * Pausable function
   */
  
  function pause() external onlyRole(PAUSER_ROLE) {
    _pause();
  }

  function unpause() external onlyRole(PAUSER_ROLE) {
    _unpause();
  }

  /**
   * internal functions
   */

  error WithdrawTooMuchETH(uint256 actual, uint256 claimed);
  function _isETHClaimable(uint256 claimed) internal view returns (bool){
    uint256 ETHbal = address(this).balance;
    if(claimed > ETHbal) revert WithdrawTooMuchETH(ETHbal, claimed);
    return true;
  }

  error NoWETHAddress();
  error WithdrawTooMuchWETH(uint256 actual, uint256 claimed);
  function _isWETHClaimable(uint256 claimed) internal view returns (bool){
    if(WETH == IERC20(address(0))) revert NoWETHAddress();
    uint256 WETHbal = IERC20(WETH).balanceOf(address(this));
    if(claimed > WETHbal) revert WithdrawTooMuchWETH(WETHbal, claimed);
    return true;
  }
  
  error ETHTransferFailed();
  function _transfer(address payable to, uint256 amount) internal {
    (bool callStatus,) = to.call{value: amount}("");
    if (!callStatus) revert ETHTransferFailed();
  }
}