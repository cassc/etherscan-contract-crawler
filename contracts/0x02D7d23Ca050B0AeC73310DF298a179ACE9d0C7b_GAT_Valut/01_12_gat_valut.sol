pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

interface IMint {
  function getMintAddresses(address _address) external view returns(uint256 [] memory);
}

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "hardhat/console.sol";


contract GAT_Valut is Ownable, ReentrancyGuard{
  using ECDSA for bytes32;    

  IMint mintContractaddress;
  address private _signer;
  address public mintContract;
  uint totalRoyaltyDistributed=0;
  mapping(address => uint) public lastWithdrawDate;
  mapping(address => uint) private withdrawIn30Days;
  uint totalWithdrawAllowed=10000000000000000000;
  uint days30 = 2592000; 
  uint256 total_distributed=0;
  bool public paused = true;
  mapping(string => bool) private usedMessages;
  mapping(address => uint) public addressMintAmountTotal;
  
  event TransferReceived(address _from, uint _amount);
  event TransferSent(address _from, address _destAddr, uint _amount);
  event SignerUpdated(address newSigner);
  error withdrawNoAllowed();
  error InvalidSignature();
  error saltAlreadyUsed();  
  error cannotWithdrawMoreThan10Eth();
  error notAuthorize();
    
  receive() payable external {
      emit TransferReceived(msg.sender, msg.value);
  }
  function setMintContractAddress(address _mintContractAddress) external onlyOwner {
    mintContractaddress = IMint(_mintContractAddress);
    
  }

  function setPaused(bool _state) external onlyOwner {
    paused = _state;
  }
  function setDays30(uint256 _days30)  external onlyOwner {
    days30 = _days30;

  }

  function setTotalWithdrawAllowed(uint _totalWithdrawAllowed) external onlyOwner {
    totalWithdrawAllowed = _totalWithdrawAllowed;
  }

  function getBalance() external  view returns (uint256) {
      return totalRoyaltyDistributed;
  }

  function _setSigner(address _newSigner) external onlyOwner {
    _signer = _newSigner;
    emit SignerUpdated(_signer);
  }
  function _verify(bytes32 hash, bytes memory token)
      internal
      view
      returns (bool)
  {
      return (_recover(hash, token) == _signer);
  }

  function _recover(bytes32 hash, bytes memory token)
      internal
      pure
      returns (address)
  {
      return hash.toEthSignedMessageHash().recover(token);
  }

  function verifyTokenForAddress(
      string calldata _salt,
      bytes calldata _token,
      address _address,
      uint256 _amount
  ) internal view returns (bool) {
      return _verify(keccak256(abi.encode(_salt, _address, _amount, address(this))), _token);
  }

  modifier withdrawCompliance(string calldata _salt, address destAddr) {
    if (tx.origin != msg.sender)
      revert withdrawNoAllowed();
    if(usedMessages[_salt] == true)  
      revert saltAlreadyUsed();
      if(mintContractaddress.getMintAddresses(destAddr).length < 1)      
        revert notAuthorize();
    _;
  }

  function withdraw(uint amount, address payable destAddr, string calldata _salt, bytes calldata _token) external nonReentrant withdrawCompliance(_salt, destAddr) {
      require(amount <= address(this).balance, "Insufficient funds");
      require(!paused, "Paused");      
      if (!verifyTokenForAddress(_salt, _token, msg.sender, amount))
        revert InvalidSignature();

      if(((block.timestamp - lastWithdrawDate[msg.sender]) < days30) &&  ((withdrawIn30Days[msg.sender]+amount) > totalWithdrawAllowed )) {
        revert cannotWithdrawMoreThan10Eth();
      }

      usedMessages[_salt] = true;
      destAddr.transfer(amount);

      if((block.timestamp - lastWithdrawDate[msg.sender]) > days30){
        withdrawIn30Days[msg.sender]=0;
      }
      
      withdrawIn30Days[msg.sender]+=amount;
      lastWithdrawDate[msg.sender]=block.timestamp;

      totalRoyaltyDistributed+=amount;
      addressMintAmountTotal[msg.sender]+=amount;
      emit TransferSent(msg.sender, destAddr, amount);
  }
  function withdrawFailProof(address _address) public onlyOwner{
        (bool os, ) = payable(_address).call{value: address(this).balance}("");
        require(os);
  }      
}