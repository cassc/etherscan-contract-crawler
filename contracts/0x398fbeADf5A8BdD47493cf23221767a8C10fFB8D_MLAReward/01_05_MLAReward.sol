// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// @author: olive

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                          //
//                                                                                                          //
//    888b     d888 888             d8888      8888888b.                                             888    //
//    8888b   d8888 888            d88888      888   Y88b                                            888    //
//    88888b.d88888 888           d88P888      888    888                                            888    //
//    888Y88888P888 888          d88P 888      888   d88P .d88b.  888  888  888  8888b.  888d888 .d88888    //
//    888 Y888P 888 888         d88P  888      8888888P" d8P  Y8b 888  888  888     "88b 888P"  d88" 888    //
//    888  Y8P  888 888        d88P   888      888 T88b  88888888 888  888  888 .d888888 888    888  888    //
//    888   "   888 888       d8888888888      888  T88b Y8b.     Y88b 888 d88P 888  888 888    Y88b 888    //
//    888       888 88888888 d88P     888      888   T88b "Y8888   "Y8888888P"  "Y888888 888     "Y88888    //
//                                                                                                          //     
//                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract MLAReward is Ownable, ReentrancyGuard {
    address private signerAddress;

    mapping(address => bool) internal admins;

    mapping(address => uint256) lastCheckPoint;
    uint256 public delayBetweenPayout = 20 * 24 * 60 * 60;
    mapping(address => uint256) payoutLimit;
    uint256 public defaultLimit = 5 ether;
    uint256 timeLimit = 90;

    address public constant topAdminAddress = 0xe4Fb4CC7d6A568231B139553636bfa2A6dBcDb46;

    event Deposited(uint256 amount);
    event Payout(address to, uint256 amount);

    constructor(address _signer) {
      admins[msg.sender] = true;
      signerAddress = _signer;
    }

    modifier onlyAdmin() {
        require(admins[_msgSender()], 'MLAReward: Caller is not the admin');
        _;
    }

    function addAdminRole(address _address) external onlyOwner {
        admins[_address] = true;
    }

    function revokeAdminRole(address _address) external onlyOwner {
        admins[_address] = false;
    }

    function deposit() public payable onlyAdmin {
      require(msg.value > 0, "MLAReward: Not a valid amount");
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
      require(success, "MLAReward: Transfer failed.");
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

    function payout(uint256 _amount, uint256 _timestamp, bytes memory _signature) external nonReentrant {
      uint256 balance = address(this).balance;
      require(_amount <= balance, "MLAReward: Not enough balance");

      address wallet = _msgSender();
      address signerOwner = signatureWallet(wallet, _amount, _timestamp, _signature);
      require(signerOwner == signerAddress, "MLAReward: Invalid data provided");

      require(_timestamp >= block.timestamp - timeLimit, "MLAReward: Out of time");
      
      require(_timestamp >= lastCheckPoint[wallet] + delayBetweenPayout, "MLAReward: Invalid timestamp");

      require(_amount < getLimit(wallet), "MLAReward: Amount exceeds limit");

      lastCheckPoint[wallet] = block.timestamp;
      _widthdraw(wallet, _amount);
      emit Payout(wallet, _amount);
    }

    function signatureWallet(address _wallet, uint256 _amount, uint256 _timestamp, bytes memory _signature) public pure returns (address){

      return ECDSA.recover(keccak256(abi.encode(_wallet, _amount, _timestamp)), _signature);

    }

    function setCheckPoint(address _claimer, uint256 _point) public onlyOwner {
      require(_claimer != address(0), "MLAReward: Unknown address");
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

    function updateDefaultLimit(uint256 _limit) public onlyOwner {
      defaultLimit = _limit;
    }
}