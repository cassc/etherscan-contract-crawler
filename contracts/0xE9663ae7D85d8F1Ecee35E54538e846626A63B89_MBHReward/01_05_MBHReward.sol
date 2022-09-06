// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// @author: olive

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                //
//                                                                                                                //
//                                                                                                                //
//     $$\      $$\ $$$$$$$\  $$\   $$\       $$$$$$$\                                                    $$\     //
//     $$$\    $$$ |$$  __$$\ $$ |  $$ |      $$  __$$\                                                   $$ |    //
//     $$$$\  $$$$ |$$ |  $$ |$$ |  $$ |      $$ |  $$ | $$$$$$\  $$\  $$\  $$\  $$$$$$\   $$$$$$\   $$$$$$$ |    //
//     $$\$$\$$ $$ |$$$$$$$\ |$$$$$$$$ |      $$$$$$$  |$$  __$$\ $$ | $$ | $$ | \____$$\ $$  __$$\ $$  __$$ |    //
//     $$ \$$$  $$ |$$  __$$\ $$  __$$ |      $$  __$$< $$$$$$$$ |$$ | $$ | $$ | $$$$$$$ |$$ |  \__|$$ /  $$ |    //
//     $$ |\$  /$$ |$$ |  $$ |$$ |  $$ |      $$ |  $$ |$$   ____|$$ | $$ | $$ |$$  __$$ |$$ |      $$ |  $$ |    //
//     $$ | \_/ $$ |$$$$$$$  |$$ |  $$ |      $$ |  $$ |\$$$$$$$\ \$$$$$\$$$$  |\$$$$$$$ |$$ |      \$$$$$$$ |    //
//     \__|     \__|\_______/ \__|  \__|      \__|  \__| \_______| \_____\____/  \_______|\__|       \_______|    //
//                                                                                                                //
//                                                                                                                //
//                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract MBHReward is Ownable, ReentrancyGuard {
    address private signerAddress;

    mapping(address => bool) internal admins;

    mapping(address => uint256) lastCheckPoint;
    uint256 public delayBetweenPayout = 5 * 24 * 60 * 60;
    mapping(address => uint256) payoutLimit;
    uint256 public defaultLimit = 5 ether;
    uint256 timeLimit = 90;

    address public constant topAdminAddress = 0x075Dc6D3a35eD0eaD2e10632161Dfc4E1bD59697;

    event Deposited(uint256 amount);
    event Payout(address to, uint256 amount);

    constructor(address _signer) {
      signerAddress = _signer;
    }

    modifier onlyAdmin() {
        require(admins[_msgSender()], 'Caller is not the admin');
        _;
    }

    function addAdminRole(address _address) external onlyOwner {
        admins[_address] = true;
    }

    function revokeAdminRole(address _address) external onlyOwner {
        admins[_address] = false;
    }

    function deposit() public payable onlyAdmin {
      require(msg.value > 0, "Not a valid amount");
      emit Deposited(msg.value);
    }

    function withdrawSome(uint256 _amount) public onlyAdmin {
      uint256 balance = address(this).balance;
      require(balance > 0 && _amount <= balance);
      _widthdraw(topAdminAddress, _amount);
    }

    function withdrawAll() public onlyAdmin {
      uint256 balance = address(this).balance;
      require(balance > 0);
      _widthdraw(topAdminAddress, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
      (bool success, ) = _address.call{value: _amount}("");
      require(success, "Transfer failed.");
    }

    function getLimit(address _claimer) public view returns (uint256) {
      uint256 limit = payoutLimit[_claimer];
      if (limit == 0) { limit = defaultLimit; }

      return limit;
    }

    function setLimit(address[] memory _claimer, uint256[] memory _limit) public onlyOwner {
        for(uint i = 0; i < _claimer.length; i ++){
            payoutLimit[_claimer[i]] = _limit[i];
        }
    }

    function payout(uint256 _amount, uint256 _timestamp, uint256 _oldCheckPoint, bytes memory _signature) external nonReentrant {
      uint256 balance = address(this).balance;
      require(_amount <= balance, "Not enough balance");

      address wallet = _msgSender();
      address signerOwner = signatureWallet(wallet, _amount, _timestamp, _oldCheckPoint, _signature);
      require(signerOwner == signerAddress, "Invalid data provided");

      require(_timestamp >= block.timestamp - timeLimit, "Out of time");
      
      uint256 checkPoint = lastCheckPoint[wallet];
      if(_oldCheckPoint > checkPoint) checkPoint = _oldCheckPoint;
      require(_timestamp >= checkPoint + delayBetweenPayout, "Invalid timestamp");

      require(_amount < getLimit(wallet), "Amount exceeds limit");

      lastCheckPoint[wallet] = block.timestamp;
      _widthdraw(wallet, _amount);
      emit Payout(wallet, _amount);
    }

    function signatureWallet(address _wallet, uint256 _amount, uint256 _timestamp, uint256 _oldCheckPoint, bytes memory _signature) public pure returns (address){

      return ECDSA.recover(keccak256(abi.encode(_wallet, _amount, _timestamp, _oldCheckPoint)), _signature);

    }

    function setCheckPoint(address _claimer, uint256 _point) public onlyOwner {
      require(_claimer != address(0), "Unknown address");
      lastCheckPoint[_claimer] = _point;
    }

    function getCheckPoint(address _claimer) external view returns (uint256) {
      return lastCheckPoint[_claimer];
    }

    function updateSignerAddress(address _signer) public onlyOwner {
      signerAddress = _signer;
    }

    function updateTimeLimit(uint256 _timeLimit) public onlyOwner {
      timeLimit = _timeLimit;
    }
}