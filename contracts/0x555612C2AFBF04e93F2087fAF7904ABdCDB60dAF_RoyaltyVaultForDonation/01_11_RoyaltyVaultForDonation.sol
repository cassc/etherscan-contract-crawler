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

contract RoyaltyVaultForDonation is AccessControl, Pausable, ReentrancyGuard{
  using SafeMath for uint256;
  uint256 public requestId = 0;
  uint256 public receiveETHId = 0;
  uint256 public withdrawnId = 0;
  IERC20 public WETH;
  address payable public TEAM_WALLET;


  mapping(uint256=>Amount) public claimablePerMaterial;
  mapping(uint256=>Amount) public withdrawnPerMaterial;
  struct Amount {
    uint256 amountETH;
    uint256 amountWETH;
  }
  mapping(uint256=>Request) public requestIdToRequest;
  struct Request {
    uint256 materialId;
    uint256 amount;
    bool isWETH;
  }
  mapping(uint256 => address) public materialIdToWithdrawer;
  bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE");
  bytes32 public constant REQUESTER_ROLE = keccak256("REQUESTER_ROLE");
  bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");
  bytes32 public constant WITHDRAWER_MANAGER_ROLE = keccak256("WITHDRAWER_MANAGER_ROLE");
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  
  constructor(address WETH_, address payable TEAM_WALLET_) {
    WETH = IERC20(WETH_);
    TEAM_WALLET = TEAM_WALLET_;
    _setupRole(DEFAULT_ADMIN_ROLE,      msg.sender);
    _grantRole(REQUESTER_ROLE,          msg.sender);
    _grantRole(WITHDRAWER_ROLE,         msg.sender);
    _grantRole(WITHDRAWER_MANAGER_ROLE, msg.sender);
    _grantRole(PAUSER_ROLE,             msg.sender);
  }

  event ReceivedETH(uint256 receiveETHId, uint256 amount);
  event RequestAdded(uint256 indexed requestId, uint256 indexed materialId, bool isWETH, uint256 amount);
  event RequestRemoved(uint256 indexed requestId, uint256 indexed materialId, bool isWETH, uint256 amount);
  event WithdrawedETH(uint256 indexed materialId, address recipient, uint256 amountClaimed);
  event WithdrawedWETH(uint256 indexed materialId, address recipient, uint256 amountClaimed);
  event WETHAddressUpdated(address previousAddress, address newAddress);
  event TeamWalletUpdated(address previousAddress, address newAddress);

  error ZeroAmountRequest();
  error InvalidTokenId();
  function addRequest(uint256 materialId, uint256 amount, bool isWETH) external onlyRole(REQUESTER_ROLE) {
    if(materialId > 6) revert InvalidTokenId();
    if(amount == 0) revert ZeroAmountRequest();
    requestId ++;
    Request memory request = Request(materialId, amount, isWETH);
    requestIdToRequest[requestId] = request;
    if (isWETH) {
      claimablePerMaterial[materialId].amountWETH += amount;
    } else {
      claimablePerMaterial[materialId].amountETH += amount;
    }
    emit RequestAdded(requestId, materialId, isWETH, amount);
  }
  
  error InvalidRequestId();
  function removeRequest(uint256 _requestId)external onlyRole(REQUESTER_ROLE){
    if(_requestId > requestId || requestIdToRequest[_requestId].amount == 0 ) revert InvalidRequestId();
    Request memory request = requestIdToRequest[_requestId];
    delete requestIdToRequest[_requestId];
    uint256 amount = request.amount;
    bool isWETH = request.isWETH;
    uint256 materialId = request.materialId;
    if (isWETH) {
      claimablePerMaterial[materialId].amountWETH -= amount;
    } else {
      claimablePerMaterial[materialId].amountETH -= amount;
    }
    emit RequestRemoved(requestId, materialId, isWETH, amount);
  }

  // receive ETH
  receive() external payable {
    ++receiveETHId;
    emit ReceivedETH(receiveETHId, msg.value);
  }

  error NotAllowedWithdrawer(uint256 materialId, address withdrawer);
  error ClaimedTooMuchWETH(uint256 materialId, uint256 claimableWETH, uint256 amountClaimed);
  error ClaimedTooMuchETH(uint256 materialId, uint256 claimableETH, uint256 amountClaimed);
  function withdraw(uint256 materialId, bool isWETH, address payable recipient, uint256 amountClaimed) 
    external 
    payable
    whenNotPaused
    nonReentrant {
      if(materialIdToWithdrawer[materialId] != msg.sender)
        revert NotAllowedWithdrawer(materialId, msg.sender);
      uint256 claimableETH = claimablePerMaterial[materialId].amountETH;
      uint256 claimableWETH = claimablePerMaterial[materialId].amountWETH;
      if(isWETH){
        if(claimableWETH < amountClaimed) revert ClaimedTooMuchWETH(materialId, claimableWETH, amountClaimed);
        if(_isWETHClaimable(amountClaimed)){
          claimablePerMaterial[materialId].amountWETH -= amountClaimed;
          withdrawnPerMaterial[materialId].amountWETH += amountClaimed;
          IERC20(WETH).transfer(recipient, amountClaimed);
          emit WithdrawedWETH(materialId, recipient, amountClaimed);
        }
      } else {
        if(claimableETH < amountClaimed) revert ClaimedTooMuchETH(materialId, claimableETH, amountClaimed);
        if(_isETHClaimable(amountClaimed)){
          claimablePerMaterial[materialId].amountETH -= amountClaimed;
          withdrawnPerMaterial[materialId].amountETH += amountClaimed;
          _transfer(recipient, amountClaimed);
          emit WithdrawedETH(materialId, recipient, amountClaimed);  
        }
      }
  }

  function sweep(uint256 materialId, bool isWETH, uint256 amountClaimed)
    external
    onlyRole(WITHDRAWER_ROLE)
    nonReentrant
  {
    uint256 claimableETH = claimablePerMaterial[materialId].amountETH;
    uint256 claimableWETH = claimablePerMaterial[materialId].amountWETH;
    if(isWETH){
      if(claimableWETH < amountClaimed) revert ClaimedTooMuchWETH(materialId, claimableWETH, amountClaimed);
      if(_isWETHClaimable(amountClaimed)){
        claimablePerMaterial[materialId].amountWETH -= amountClaimed;
        withdrawnPerMaterial[materialId].amountWETH += amountClaimed;
        IERC20(WETH).transfer(TEAM_WALLET, amountClaimed);
        emit WithdrawedWETH(materialId, TEAM_WALLET, amountClaimed);
      }
    } else {
      if(claimableETH < amountClaimed) revert ClaimedTooMuchETH(materialId, claimableETH, amountClaimed);
      if(_isETHClaimable(amountClaimed)){
        claimablePerMaterial[materialId].amountETH -= amountClaimed;
        withdrawnPerMaterial[materialId].amountETH += amountClaimed;
        _transfer(TEAM_WALLET, amountClaimed);
        emit WithdrawedETH(materialId, TEAM_WALLET, amountClaimed);  
      }
    }
  }

  /*
   * Setter function
   */
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

  error InvalidMaterialId();
  function setWithdrawerForMaterialId(uint256 materialId, address withdrawer) external onlyRole(WITHDRAWER_MANAGER_ROLE) {
    if(materialId > 6) revert InvalidMaterialId();
    if(withdrawer == address(0)) revert InvalidAddress();
    materialIdToWithdrawer[materialId] = withdrawer;
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
   * Internal functions
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