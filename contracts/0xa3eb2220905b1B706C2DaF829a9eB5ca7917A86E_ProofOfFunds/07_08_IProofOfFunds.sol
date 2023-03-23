// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IProofOfFunds {
  enum Roles {
    TEAM,
    PRODUCT,
    COMMUNITY,
    OPERATIONS
  }

  enum TransactionType {
    SIGNER,
    WITHDRAW
  }

  struct Token {
    address contractAddress;
    uint256 balance;
  }

  struct System {
    uint256 noOfSigners;
    uint256 twTransaction; // total withdraw transactions
    uint256 tsTransaction; // total signer transactions
    uint256 timeToSign;
    address[] registeredSigners;
    string[] registeredToken;
  }

  struct Signers {
    address walletAddress;
    bool allowed;
    string name;
    string kyc;
  }

  struct WithdrawTransaction {
    mapping(bool => address[]) signList;
    mapping(address => bool) hasSigned;
    uint256 amount;
    uint256 timeCreated;
    string token;
    Roles receiver;
    bool active;
  }

  struct SignerTransaction {
    mapping(bool => address[]) signList;
    mapping(address => bool) hasSigned;
    address signerAddress;
    string name;
    string kyc;
    uint256 timeCreated;
    bool active;
  }

  function depositFund(string memory _token, uint256 _amount, string memory _reason) external;
  function depositNativeFund(string memory _reaason) external payable;
}