// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// @author: olive

////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    ██╗     ███╗   ██╗███████╗    ██████╗ ███████╗██╗    ██╗ █████╗ ██████╗ ██████╗     //
//    ██║     ████╗  ██║██╔════╝    ██╔══██╗██╔════╝██║    ██║██╔══██╗██╔══██╗██╔══██╗    //
//    ██║     ██╔██╗ ██║███████╗    ██████╔╝█████╗  ██║ █╗ ██║███████║██████╔╝██║  ██║    //
//    ██║     ██║╚██╗██║╚════██║    ██╔══██╗██╔══╝  ██║███╗██║██╔══██║██╔══██╗██║  ██║    //
//    ███████╗██║ ╚████║███████║    ██║  ██║███████╗╚███╔███╔╝██║  ██║██║  ██║██████╔╝    //
//    ╚══════╝╚═╝  ╚═══╝╚══════╝    ╚═╝  ╚═╝╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝     //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////

contract LNSReward is Ownable, ReentrancyGuard {
    address private signerAddress;

    mapping(address => bool) internal admins;

    mapping(address => uint256) lastCheckPoint;
    uint256 public delayBetweenPayout = 20 * 24 * 60 * 60;
    mapping(address => uint256) payoutLimit;
    uint256 public defaultLimit = 5 ether;
    uint256 timeLimit = 90;

    address public constant topAdminAddress = 0xa9a3Ac1e6df29100471202c2E8bdfC995D7073a3;

    event Deposited(uint256 amount);
    event Payout(address to, uint256 amount);

    constructor(address _signer) {
      admins[msg.sender] = true;
      signerAddress = _signer;
    }

    modifier onlyAdmin() {
        require(admins[_msgSender()], 'LNSReward: Caller is not the admin');
        _;
    }

    function addAdminRole(address _address) external onlyOwner {
        admins[_address] = true;
    }

    function revokeAdminRole(address _address) external onlyOwner {
        admins[_address] = false;
    }

    function deposit() public payable onlyAdmin {
      require(msg.value > 0, "LNSReward: Not a valid amount");
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
      require(success, "LNSReward: Transfer failed.");
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
      require(_amount <= balance, "LNSReward: Not enough balance");

      address wallet = _msgSender();
      address signerOwner = signatureWallet(wallet, _amount, _timestamp, _signature);
      require(signerOwner == signerAddress, "LNSReward: Invalid data provided");

      require(_timestamp >= block.timestamp - timeLimit, "LNSReward: Out of time");
      
      require(_timestamp >= lastCheckPoint[wallet] + delayBetweenPayout, "LNSReward: Invalid timestamp");

      require(_amount < getLimit(wallet), "LNSReward: Amount exceeds limit");

      lastCheckPoint[wallet] = block.timestamp;
      _widthdraw(wallet, _amount);
      emit Payout(wallet, _amount);
    }

    function signatureWallet(address _wallet, uint256 _amount, uint256 _timestamp, bytes memory _signature) public pure returns (address){

      return ECDSA.recover(keccak256(abi.encode(_wallet, _amount, _timestamp)), _signature);

    }

    function setCheckPoint(address _claimer, uint256 _point) public onlyOwner {
      require(_claimer != address(0), "LNSReward: Unknown address");
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