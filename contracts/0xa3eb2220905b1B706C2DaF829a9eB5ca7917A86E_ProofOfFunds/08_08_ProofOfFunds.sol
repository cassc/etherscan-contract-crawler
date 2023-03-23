// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import './interface/IProofOfFunds.sol';
import '../main-collection/interface/ILilFarmBoy.sol';

contract ProofOfFunds is IProofOfFunds, OwnableUpgradeable {
  System public pof;

  mapping(Roles => address) public roleAddress;
  mapping(string => Token) public tokenData;
  mapping(address => Signers) public signerData;
  mapping(uint256 => WithdrawTransaction) public withdrawTransaction;
  mapping(uint256 => SignerTransaction) public signerTransaction;

  /**
   * Events
   */
  // Funds events
  event fundsDeposited(
    address indexed depositor,
    string indexed token,
    uint256 amount,
    string indexed reason
  );
  event fundsRequested(
    address indexed requestor,
    string indexed name,
    Roles receiver,
    uint256 amount,
    string indexed reason
  );
  event fundsWithdrawn(Roles indexed receiver, uint256 amount);
  event fundRequestSigned(address indexed signer, bool isApproved);
  event fundRequestCancelled(uint256 transactionID);

  //Signer events
  event signerRequested(
    uint256 transactionID,
    address signer,
    string name,
    string kyc
  );
  event signerAdded(address signer, string name, string kyc);
  event signerRequestSigned(address signer, bool isApproved);
  event signerRequestCancelled(uint256 transactionID);

  /**
   * Modifiers
   */

  modifier onlyRegisteredSigner() {
    require(signerData[msg.sender].allowed, 'PoF :: Invalid signer');
    _;
  }

  modifier onlyAcceptedTransaction(TransactionType _transaction) {
    uint256 withdrawID = pof.twTransaction;
    uint256 signerID = pof.tsTransaction;

    if (_transaction == TransactionType.WITHDRAW) {
      require(
        withdrawTransaction[withdrawID].signList[true].length >
          (pof.noOfSigners -
            withdrawTransaction[withdrawID].signList[true].length),
        'PoF :: Not enough signers that accepted'
      );
    } else {
      require(
        signerTransaction[signerID].signList[true].length >
          (pof.noOfSigners - signerTransaction[signerID].signList[true].length),
        'PoF :: Not enough signers that accepted'
      );
    }
    _;
  }

  modifier onlyDeclinedTransaction(TransactionType _transaction) {
    uint256 withdrawID = pof.twTransaction;
    uint256 signerID = pof.tsTransaction;

    if (_transaction == TransactionType.WITHDRAW) {
      require(
        withdrawTransaction[withdrawID].signList[false].length >
          (pof.noOfSigners -
            withdrawTransaction[withdrawID].signList[false].length) ||
          block.timestamp >
          (withdrawTransaction[withdrawID].timeCreated + pof.timeToSign),
        'POF :: Not enough signers that declined'
      );
    } else {
      require(
        signerTransaction[signerID].signList[false].length >
          (pof.noOfSigners -
            signerTransaction[signerID].signList[false].length) ||
          block.timestamp >
          (signerTransaction[signerID].timeCreated + pof.timeToSign),
        'POF :: Not enough signers that declined'
      );
    }

    _;
  }

  modifier onlyOneVote(TransactionType _transaction, uint256 _transactionID) {
    if (_transaction == TransactionType.WITHDRAW) {
      require(
        !withdrawTransaction[_transactionID].hasSigned[msg.sender],
        'PoF :: You already signed.'
      );
    } else {
      require(
        !signerTransaction[_transactionID].hasSigned[msg.sender],
        'PoF :: You already signed.'
      );
    }
    _;
  }

  /**
   * Initialize
   */
  function initialize(
    address[] memory _signers,
    string[] memory _name,
    string[] memory _kyc,
    uint256 _timeToSign
  ) external initializer {
    __Ownable_init();

    for (uint256 index = 0; index < _signers.length; index++) {
      signerData[_signers[index]].walletAddress = _signers[index];
      signerData[_signers[index]].allowed = true;
      signerData[_signers[index]].name = _name[index];
      signerData[_signers[index]].kyc = _kyc[index];
      pof.registeredSigners.push(_signers[index]);

      pof.noOfSigners++;
    }

    pof.timeToSign = _timeToSign;
  }

  /**
   * Signer
   */

  function requestAddSigner(
    address _signerAddress,
    string memory _name,
    string memory _kyc
  ) external onlyRegisteredSigner {
    require(
      !signerTransaction[pof.tsTransaction].active,
      'PoF :: There is still a pending transaction'
    );

    pof.tsTransaction++;
    uint256 signerID = pof.tsTransaction;

    signerTransaction[signerID].signerAddress = _signerAddress;
    signerTransaction[signerID].name = _name;
    signerTransaction[signerID].kyc = _kyc;
    signerTransaction[signerID].timeCreated = block.timestamp;
    signerTransaction[signerID].active = true;

    emit signerRequested(signerID, _signerAddress, _name, _kyc);
  }

  function signSignerRequest(
    uint256 _transactionID,
    bool _isApprove
  )
    external
    onlyRegisteredSigner
    onlyOneVote(TransactionType.SIGNER, _transactionID)
  {
    require(
      signerTransaction[_transactionID].active,
      'PoF :: Transaction is not active'
    );

    signerTransaction[_transactionID].signList[_isApprove].push(msg.sender);
    signerTransaction[_transactionID].hasSigned[msg.sender] = true;

    emit signerRequestSigned(msg.sender, false);
  }

  function processSignerRequest(
    uint256 _transactionID
  ) external onlyRegisteredSigner {
    SignerTransaction storage signer = signerTransaction[_transactionID];

    if (checkSignerDecision(_transactionID)) {
      signerData[signer.signerAddress].walletAddress = signer.signerAddress;
      signerData[signer.signerAddress].name = signer.name;
      signerData[signer.signerAddress].kyc = signer.kyc;
      signerData[signer.signerAddress].allowed = true;
    } else {
      signerTransaction[_transactionID].active = false;
    }
  }

  /**
   * Deposit
   */

  function depositNativeFund(string memory _reason) external payable {
    tokenData['eth'].balance += msg.value;
    emit fundsDeposited(msg.sender, 'eth', msg.value, _reason);
  }

  function depositFund(
    string memory _token,
    uint256 _amount,
    string memory _reason
  ) external {
    IERC20Upgradeable token = IERC20Upgradeable(
      tokenData[_token].contractAddress
    );
    token.transferFrom(msg.sender, address(this), _amount);
    emit fundsDeposited(msg.sender, _token, _amount, _reason);
  }

  /**
   * Withdraw
   */

  function requestFundWithdraw(
    string memory _token,
    uint256 _amount,
    Roles _receiver,
    string memory _reason
  ) external onlyRegisteredSigner {
    require(
      !withdrawTransaction[pof.twTransaction].active,
      'PoF :: There is still a pending transaction'
    );
    pof.twTransaction++;

    uint256 transactionID = pof.twTransaction;
    withdrawTransaction[transactionID].amount = _amount;
    withdrawTransaction[transactionID].timeCreated = block.timestamp;
    withdrawTransaction[transactionID].token = _token;
    withdrawTransaction[transactionID].receiver = _receiver;
    withdrawTransaction[transactionID].active = true;

    emit fundsRequested(
      msg.sender,
      signerData[msg.sender].name,
      _receiver,
      _amount,
      _reason
    );
  }

  function signFundRequest(
    uint256 _transactionID,
    bool _isApprove
  ) external onlyRegisteredSigner {
    require(
      withdrawTransaction[_transactionID].active,
      'PoF :: Transaction is not active'
    );

    withdrawTransaction[_transactionID].signList[_isApprove].push(msg.sender);
    withdrawTransaction[_transactionID].hasSigned[msg.sender] = true;

    emit fundRequestSigned(msg.sender, _isApprove);
  }

  function processFundRequest(
    uint256 _transactionID
  ) external onlyRegisteredSigner {
    WithdrawTransaction storage transaction = withdrawTransaction[
      _transactionID
    ];

    if (
      keccak256(abi.encodePacked(transaction.token)) ==
      keccak256(abi.encodePacked('eth'))
    ) {
      payable(roleAddress[transaction.receiver]).transfer(transaction.amount);
      withdrawTransaction[_transactionID].active = false;
      tokenData[transaction.token].balance -= transaction.amount;
      emit fundsWithdrawn(transaction.receiver, transaction.amount);

      return;
    }

    IERC20Upgradeable token = IERC20Upgradeable(
      tokenData[transaction.token].contractAddress
    );
    token.transfer(roleAddress[transaction.receiver], transaction.amount);
    withdrawTransaction[_transactionID].active = false;

    emit fundsWithdrawn(transaction.receiver, transaction.amount);
  }

  /**
   * View Functions
   */

  function checkSignerDecision(
    uint256 _transactionID
  ) public view returns (bool) {
    if (
      signerTransaction[_transactionID].signList[false].length >
      (pof.noOfSigners -
        signerTransaction[_transactionID].signList[false].length) ||
      block.timestamp >
      (signerTransaction[_transactionID].timeCreated + pof.timeToSign)
    ) {
      return false;
    } else if (
      signerTransaction[_transactionID].signList[true].length >
      (pof.noOfSigners -
        signerTransaction[_transactionID].signList[true].length)
    ) {
      return true;
    }

    revert('PoF :: No decision yet');
  }

  function checkWithdrawDecision(
    uint256 _transactionID
  ) public view returns (bool) {
    if (
      withdrawTransaction[_transactionID].signList[false].length >
      (pof.noOfSigners -
        withdrawTransaction[_transactionID].signList[false].length) ||
      block.timestamp >
      (withdrawTransaction[_transactionID].timeCreated + pof.timeToSign)
    ) {
      return false;
    } else if (
      withdrawTransaction[_transactionID].signList[true].length >
      (pof.noOfSigners -
        withdrawTransaction[_transactionID].signList[true].length)
    ) {
      return true;
    }

    revert('PoF :: No decision yet');
  }

  /**
   * Setter Function
   */

  function setTokenAddress(
    string memory _token,
    address _address
  ) external onlyOwner {
    tokenData[_token].contractAddress = _address;
  }

  function setRoleAddress(Roles _role, address _address) external onlyOwner {
    roleAddress[_role] = _address;
  }

  /**
   * fallback
   */

  receive() external payable {
    tokenData['eth'].balance += msg.value;
  }
}