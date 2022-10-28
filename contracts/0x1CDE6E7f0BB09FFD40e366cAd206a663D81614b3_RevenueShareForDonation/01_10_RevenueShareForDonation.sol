// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * 
 * ___  ___ _  _                            ______                                       _____  _                       
 * |  \/  |(_)| |                           | ___ \                                     /  ___|| |                      
 * | .  . | _ | |_  __ _  _ __ ___    __ _  | |_/ / ___ __   __ ___  _ __   _   _   ___ \ `--. | |__    __ _  _ __  ___ 
 * | |\/| || || __|/ _` || '_ ` _ \  / _` | |    / / _ \\ \ / // _ \| '_ \ | | | | / _ \ `--. \| '_ \  / _` || '__|/ _ \
 * | |  | || || |_| (_| || | | | | || (_| | | |\ \|  __/ \ V /|  __/| | | || |_| ||  __//\__/ /| | | || (_| || |  |  __/
 * \_|  |_/|_| \__|\__,_||_| |_| |_| \__,_| \_| \_|\___|  \_/  \___||_| |_| \__,_| \___|\____/ |_| |_| \__,_||_|   \___|                                                                                                                                                                                         
 *                                                                                                                   
 *   __              ______                      _    _               
 *  / _|             |  _  \                    | |  (_)              
 * | |_  ___   _ __  | | | | ___   _ __    __ _ | |_  _   ___   _ __  
 * |  _|/ _ \ | '__| | | | |/ _ \ | '_ \  / _` || __|| | / _ \ | '_ \ 
 * | | | (_) || |    | |/ /| (_) || | | || (_| || |_ | || (_) || | | |
 * |_|  \___/ |_|    |___/  \___/ |_| |_| \__,_| \__||_| \___/ |_| |_| 
 * 
 * produced by http://mitama-mint.com/
 * written by zkitty.eth
 */

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract RevenueShareForDonation is AccessControl, ReentrancyGuard{
  using SafeMath for uint256;
  uint256 public receiveId;
  uint256 public requestId;
  uint256 public withdrawnId;
  address public WETH;
  address[7] public donations;


  uint256 public totalReceivedETH;
  uint256 public totalReceivedWETH;
  uint256 public ETHbal;
  uint256 public WETHbal;
  mapping(uint256=>Amount) public claimablePerMaterial;
  mapping(uint256=>Amount) public withdrawnPerMaterial;
  struct Amount {
    uint256 amountETH;
    uint256 amountWETH;
  }
  mapping(uint256=>Payment) public receiveIdToPayments;
  struct Payment {
    uint256 amount;
    bool isWETH;
  }
  mapping(uint256=>Request) public requestIdToRequests;
  struct Request {
      uint256 tokenId;
      uint256 amount;
  }
  uint256 numWithdrawer;
  uint256 public tokenToMaterialCount;
  bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");

  mapping(uint256 => uint256) internal tokenToMaterial;
  mapping(uint256 => address) internal materialToDonation;
  
  constructor() {
      _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
      _grantRole(WITHDRAWER_ROLE, msg.sender);
  }

  event ReceivedETH(uint256 receivedId, uint256 amount);
  event ReceivedWETH(uint256 receivedId, uint256 amount);
  event RequestAdded(uint tokenId, uint256 amount, uint256 materialId);
  event WithdrawedETH(address indexed account, uint256 indexed amount);
  event WithdrawedWETH(address indexed account, uint256 indexed amount);
  event WithdrawerAdded(address withdrawer);
  event WithdrawerRemoved(address withdrawer);

  function addRequest(uint tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _updateReceivedWETH();
    ++requestId;
    Payment memory payment = receiveIdToPayments[requestId];
    require(payment.amount > 0, "request amount should be > 0");
    //amount is given by receivedIdToPayments
    uint256 materialId = tokenToMaterial[tokenId];
    // address donation = materialToDonation[materialId];
    Request memory request =  Request(tokenId, payment.amount);
    requestIdToRequests[requestId] = request;
    if (payment.isWETH) {
        claimablePerMaterial[materialId].amountWETH += payment.amount;
    } else {
        withdrawnPerMaterial[materialId].amountETH += payment.amount;
    }
    emit RequestAdded(tokenId, payment.amount, materialId);
  }

  // receive ETH
  receive() external payable {
    _updateReceivedWETH();
    ++receiveId;
    receiveIdToPayments[receiveId] = Payment(msg.value, false);
    totalReceivedETH += msg.value;
    emit ReceivedETH(receiveId, msg.value);
  }

  // update receivedWETH
  function _updateReceivedWETH() internal {
    require(WETH != address(0), "failed setWET()");
    uint256 bal = IERC20(WETH).balanceOf(address(this));
    if(bal == 0){
      WETHbal == 0;
    } else if(bal > 0 && bal > WETHbal) {   
      uint256 diff = bal - WETHbal;
      ++receiveId;
      receiveIdToPayments[receiveId] = Payment(diff, true);
      totalReceivedWETH += diff;
      WETHbal = bal;
      emit ReceivedWETH(receiveId, diff);
    }
  }

  // onEvent: WETH is transfered to this contract
  function getWETHbal() public returns(uint256){
      _updateReceivedWETH();
      return WETHbal;
  }

  function batchWithdraw() external onlyRole(WITHDRAWER_ROLE) payable nonReentrant{
    require(withdrawnId < requestId, "No Withdrawable Request");
    require(donations.length == 7, "7 Donation addresslits is not set.");
    // transfer claimablePerAddress to all addresses if the amount is not zero.
    // to get the wallet list: requestIdToRequests[requestId(itterable)].members
    for(uint i=0; i < donations.length; i++){
      uint256 materialId = i;
      address account = donations[i];
      if(claimablePerMaterial[materialId].amountETH > 0){
          uint256 claimableETH = claimablePerMaterial[materialId].amountETH;
          withdrawnPerMaterial[materialId].amountETH += claimableETH;
          claimablePerMaterial[materialId].amountETH = 0;
          _transfer(account, claimableETH);
          emit WithdrawedETH(account, claimableETH);
      }
      if(claimablePerMaterial[materialId].amountWETH > 0){
          uint256 claimableWETH = claimablePerMaterial[materialId].amountWETH;
          withdrawnPerMaterial[materialId].amountWETH += claimableWETH;
          claimablePerMaterial[materialId].amountWETH = 0;
          IERC20(WETH).transfer(account, claimableWETH);
          emit WithdrawedWETH(account, claimableWETH);
      }      
    }
    ETHbal = address(this).balance;
    withdrawnId = requestId;
  }

  function withdrawETH(address account, uint amount) external onlyRole(WITHDRAWER_ROLE) payable nonReentrant{
    require(getMaterialIdFromAddress(account) >= 0, "Invalid account;");
    uint256 materialId = getMaterialIdFromAddress(account);
    require(claimablePerMaterial[materialId].amountETH > 0, "Account has no claimable amount.");
    require(claimablePerMaterial[materialId].amountETH > amount, "Amount exceeds claimable amount.");
    claimablePerMaterial[materialId].amountETH -= amount;
    withdrawnPerMaterial[materialId].amountETH += amount;
    _transfer(account, amount);
    ETHbal = address(this).balance;
    emit WithdrawedETH(account, amount);
  }

  function withdrawWETH(address account, uint amount) external onlyRole(WITHDRAWER_ROLE) payable nonReentrant{
    require(getMaterialIdFromAddress(account) != 0x0, "Invalid account;");
    uint256 materialId = getMaterialIdFromAddress(account);
    require(claimablePerMaterial[materialId].amountWETH > 0, "Account has no claimable amount.");
    require(claimablePerMaterial[materialId].amountWETH > amount, "Amount exceeds claimable amount.");
    claimablePerMaterial[materialId].amountWETH -= amount;
    withdrawnPerMaterial[materialId].amountWETH += amount;
    IERC20(WETH).transfer(account, amount);
    WETHbal = IERC20(WETH).balanceOf(address(this));
    emit WithdrawedWETH(account, amount);
  }
  
  ////
  // add and remove Withdrawer
  ////

  function addProvider(address withdrawer) external onlyRole(DEFAULT_ADMIN_ROLE) {
      // withdrawer should not have WITHDRAWER_ROLE already.
      require(!hasRole(WITHDRAWER_ROLE, withdrawer), "Withdrawer already added.");

      _grantRole(WITHDRAWER_ROLE, withdrawer);
      numWithdrawer++;

      emit WithdrawerAdded(withdrawer);
  }

  function removeProvider(address withdrawer) external onlyRole(DEFAULT_ADMIN_ROLE) {
      // withdrawer should have WITHDRAWER_ROLE.
      require(hasRole(WITHDRAWER_ROLE, withdrawer), "Withdrawer doesn't exist.");

      _revokeRole(WITHDRAWER_ROLE, withdrawer);
      numWithdrawer--;

      emit WithdrawerRemoved(withdrawer);
  }


  // adopted from https://github.com/lexDAO/Kali/blob/main/contracts/libraries/SafeTransferLib.sol
  error TransferFailed();
  function _transfer(address to, uint256 amount) internal {
    bool callStatus;
    assembly {
      callStatus := call(gas(), to, amount, 0, 0, 0, 0)
    }
    if (!callStatus) revert TransferFailed();
  }

  /*
   * House Keepings
   */
  function getMaterialIdFromAddress(address account) public view returns(uint256) {
      require(account != address(0), "Invalid Address.");
      require(donations.length > 0, "materialToDonation isn't set." );
      uint256 materialId;
      for(uint256 i; i < donations.length; i++){
        if(account == donations[i]) {
          materialId = i;
        } else {
          revert("Address is not found.");
        }
      }
      return materialId;
  } 

  function setWET(address _addr) external onlyRole(DEFAULT_ADMIN_ROLE) {
      require(_addr != address(0), "Invalid token address");
      WETH = _addr;
  }

  function setTokenToMaterial(uint256[500] memory materialList, uint256 page) public onlyRole(DEFAULT_ADMIN_ROLE){
    require(tokenToMaterialCount == page*500 , "Invalid starting index.");
    for(uint256 i = 0; i < 500; i++) {
      uint256 counter = page * 500 + i;
      tokenToMaterial[counter] = materialList[i];
      tokenToMaterialCount++;
    }
  }
  
  function setMaterialToDonation(address[7] memory addresses) public onlyRole(DEFAULT_ADMIN_ROLE){
    donations = addresses;
    for(uint256 i; i < addresses.length; i++){
      materialToDonation[i] = addresses[i];
    }
  }
}