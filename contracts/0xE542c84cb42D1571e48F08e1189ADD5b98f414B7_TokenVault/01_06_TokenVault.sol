// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

contract TokenVault is Ownable {
  IERC20 public tokenContract;

  address private _signerAddress;
  uint256 private _withdrawalExpiration;

  mapping(address => uint256) private _lastNonce;

  event Withdrawal(
    address indexed recipient,
    uint256 amount,
    uint256 tax,
    uint256 nonce
  );

  constructor(address tokenAddress) {
    tokenContract = IERC20(tokenAddress);
  }

  function withdraw(
    uint256 amount,
    uint256 tax,
    uint256 nonce,
    uint256 timestamp,
    bytes calldata signature
  ) external {
    address recipient = _msgSender();
    require(
      timestamp + _withdrawalExpiration > block.timestamp,
      'Expired withdrawal timestamp'
    );
    require(nonce > _lastNonce[recipient], 'Invalid nonce');
    require(amount >= tax, 'Invalid tax amount');
    require(
      _validateWithdrawalSignature(
        recipient,
        amount,
        tax,
        nonce,
        timestamp,
        signature
      ),
      'Invalid signature'
    );

    _lastNonce[recipient] = nonce;
    tokenContract.transfer(recipient, amount - tax);
    emit Withdrawal(recipient, amount, tax, nonce);
  }

  function setSignerAddress(address signerAddress) external onlyOwner {
    _signerAddress = signerAddress;
  }

  function setWithdrawalExpiration(uint256 expiration) external onlyOwner {
    _withdrawalExpiration = expiration;
  }

  function tokenBalance() external view returns (uint256) {
    return tokenContract.balanceOf(address(this));
  }

  function withdrawAll() external onlyOwner {
    uint256 balance = tokenContract.balanceOf(address(this));
    tokenContract.transfer(_msgSender(), balance);
  }

  function _validateWithdrawalSignature(
    address recipient,
    uint256 amount,
    uint256 tax,
    uint256 nonce,
    uint256 timestamp,
    bytes calldata signature
  ) internal view returns (bool) {
    bytes32 dataHash = keccak256(
      abi.encodePacked(recipient, amount, tax, nonce, timestamp)
    );
    bytes32 message = ECDSA.toEthSignedMessageHash(dataHash);

    address signer = ECDSA.recover(message, signature);
    return (signer == _signerAddress);
  }
}