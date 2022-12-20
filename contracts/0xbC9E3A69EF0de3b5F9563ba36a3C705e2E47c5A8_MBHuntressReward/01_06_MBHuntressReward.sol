// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// @author: olive

///////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                       //
//                                                                                                       //
//          ___   _   _             _                           ___                                 _    //
//   /'\_/`(  _`\( ) ( )           ( )_                        |  _`\                              ( )   //
//   |     | (_) | |_| |_   _  ___ | ,_)_ __  __   ___  ___    | (_) )  __  _   _   _   _ _ _ __  _| |   //
//   | (_) |  _ <|  _  ( ) ( /' _ `| | ( '__/'__`/',__/',__)   | ,  / /'__`( ) ( ) ( )/'_` ( '__/'_` |   //
//   | | | | (_) | | | | (_) | ( ) | |_| | (  ___\__, \__, \   | |\ \(  ___| \_/ \_/ ( (_| | | ( (_| |   //
//   (_) (_(____/(_) (_`\___/(_) (_`\__(_) `\____(____(____/   (_) (_`\____`\___x___/`\__,_(_) `\__,_)   //
//                                                                                                       //
//                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////

contract MBHuntressReward is Ownable, ReentrancyGuard {
    address private signerAddress;

    mapping(address => bool) internal admins;

    mapping(address => uint256) lastCheckPoint;
    uint256 public delayBetweenPayout = 20 * 24 * 60 * 60;
    mapping(address => uint256) payoutLimit;
    uint256 public defaultLimit = 5 ether;
    uint256 timeLimit = 90;

    address public constant topAdminAddress = 0x570530F085509D3BCFd76525fb8198d9E672885F;

    event Deposited(uint256 amount);
    event Payout(address to, uint256 amount);

    constructor(address _signer) {
      signerAddress = _signer;
    }

    modifier onlyAdmin() {
        require(admins[_msgSender()], 'MBHuntressReward: Caller is not the admin');
        _;
    }

    function addAdminRole(address _address) external onlyOwner {
        admins[_address] = true;
    }

    function revokeAdminRole(address _address) external onlyOwner {
        admins[_address] = false;
    }

    function deposit() public payable onlyAdmin {
      require(msg.value > 0, "MBHuntressReward: Not a valid amount");
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
      require(success, "MBHuntressReward: Transfer failed.");
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
      require(_amount <= balance, "MBHuntressReward: Not enough balance");

      address wallet = _msgSender();
      address signerOwner = signatureWallet(wallet, _amount, _timestamp, _signature);
      require(signerOwner == signerAddress, "MBHuntressReward: Invalid data provided");

      require(_timestamp >= block.timestamp - timeLimit, "MBHuntressReward: Out of time");

      require(_timestamp >= lastCheckPoint[wallet] + delayBetweenPayout, "MBHuntressReward: Invalid timestamp");

      require(_amount < getLimit(wallet), "MBHuntressReward: Amount exceeds limit");

      lastCheckPoint[wallet] = block.timestamp;
      _widthdraw(wallet, _amount);
      emit Payout(wallet, _amount);
    }

    function signatureWallet(address _wallet, uint256 _amount, uint256 _timestamp, bytes memory _signature) public pure returns (address){

      return ECDSA.recover(keccak256(abi.encode(_wallet, _amount, _timestamp)), _signature);

    }

    function setCheckPoint(address _claimer, uint256 _point) public onlyOwner {
      require(_claimer != address(0), "MBHuntressReward: Unknown address");
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