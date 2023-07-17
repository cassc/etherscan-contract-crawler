/**
 *Submitted for verification at Etherscan.io on 2023-06-28
*/

// SPDX-License-Identifier: GPL-3.0 AND MIT
/** 
 *  SourceUnit: /home/dos/dev/clients/cointinum/vaultContract/contracts/AdminMultiSig.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.17;
interface VaultInterface {
    // Events
    event Minted(address indexed minter, uint256 amount);
    event BRX_Supplied(address indexed depositer, uint256 amount, uint256 timestamp);
    event BRXPurchased(
        address indexed purchaser,
        uint256 usdcAmount,
        uint256 cmtAllotedAmount
    );
    event TokenWithdraw(address indexed user, bytes32 token, uint256 payment);
    function setPaymentToken(address token) external;
    function setPenaltyAmount(uint256 _amount) external;
    function setFundsAddress(address _fundsAddress) external;
    function supplyBRX (uint256 _amount) external;
    function removeBRX (uint256 _amount) external;
    function removePaymentTokens(uint256 _amount) external;
    function addPaymentTokens(uint256 _amount) external;
    function buyBRX(address _user, uint256 _usdcAmount, uint256 _brxAmount) external;
    function refund(address _buyer, uint256 _amount, uint256 _brxAdjustment) external;
    function withdraw(address _user, uint256 _amount, uint256 _usdcAdjustment) external;
    function penalty() external returns(uint256);
}




/** 
 *  SourceUnit: /home/dos/dev/clients/cointinum/vaultContract/contracts/AdminMultiSig.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.17;
interface SwapInterface {
  event MadeDeposit (address indexed customer, uint256 BRXqty, uint256 USDCqty, uint16 tranche);
  enum TrancheState {
    paused,
    active,
    completed,
    deleted
  }
  function addTranche (uint256 total, uint256 available, uint256 lockDuration, uint16 price) external returns (uint256);
  function getTrancheParams (uint16 trancheNumber) external returns (uint256, uint256, uint16, TrancheState);
  function addWhitelist (address[] memory accounts) external;
  function changeTrancheState (uint16 trancheNumber, TrancheState newstate) external;
  function removeWhitelist (address[] memory accounts) external;
  function setMaxBRXAllowed (uint256 _amount) external;
  function setMinPurchase (uint32 _minPurchase) external;
  function setAdminAddress(address _address) external;
  function setMaxPerTranche (uint16 trancheNumber, uint256 max) external;
}


/** 
 *  SourceUnit: /home/dos/dev/clients/cointinum/vaultContract/contracts/AdminMultiSig.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: GPL-3.0
pragma solidity ^0.8.17;

////import {SwapInterface} from "./interfaces/SwapInterface.sol";
////import {VaultInterface} from "./interfaces/VaultInterface.sol";
contract AdminMultiSig {
  error NotOwnerError();
  address owner;
  SwapInterface public swap;
  VaultInterface public vault;
  uint32 tx_count;

  address swapAddr;
  address vaultAddr;

  // MultiSig Functions
  event Deposit(address indexed sender, uint256 amount);
  event Submit(uint256 indexed txId);
  event Approve(address indexed owner, uint256 indexed txId);
  event Revoke(address indexed owner, uint256 indexed txId);
  event Execute(uint256 indexed txId);

  struct Transaction {
    string txName;
    string contractName;
    uint32 index;
    bytes data;
    bool executed;
    bool revoked;
  }

  address[] public owners;
  mapping(address => bool) public isOwner;
  uint256 public required;

  Transaction[] public transactions;
  mapping(uint256 => mapping(address => bool)) public approved;

  constructor(
    address swapAddress, 
    address vaultAddress, 
    address[] memory _owners, 
    uint256 _required
  ) {
    require(_owners.length > 0, "At least 2 owners are required");
    require(
      _required > 0 && _required <= _owners.length,
      "Invalid required number of owners"
    );

    for(uint16 i; i < _owners.length; i++) {
      address singleOwner = _owners[i];
      require(singleOwner != address(0), "Invalid owner");
      require(!isOwner[singleOwner], "Owner is not unique");
      isOwner[singleOwner] = true;
      owners.push(singleOwner);
    }

    required = _required;
    owner = msg.sender;
    swap = SwapInterface(swapAddress);
    vault = VaultInterface(vaultAddress);
    swapAddr = swapAddress;
    vaultAddr = vaultAddress;
  }

  function unsafe_increment16(uint16 x) private pure returns (uint16) {
    unchecked {return x + 1;}
  }
  // More gas efficient than modifier
  function onlyOwner() public view {
    if (!isOwner[msg.sender]) {
      revert NotOwnerError();
    }
  }

  function txExists(uint16 _txId) internal view {
    require(_txId < transactions.length, "Tx does not exist");
  }

  function notApproved(uint16 _txId) internal view {
    require(!approved[_txId][msg.sender], "Tx does not exist");
  }

  function notExecuted(uint16 _txId) internal view {
    require(!transactions[_txId].executed, "tx already executed");
  }

  function submit(bytes memory _data, string memory name, string memory tx_name) internal {
    onlyOwner();
    transactions.push(Transaction({
      txName: tx_name,
      contractName: name,
      index: tx_count,
      data: _data,
      executed: false,
      revoked: false
    }));
    tx_count++;
    emit Submit(transactions.length - 1);
  }

  function approve(uint16 _txId) external {
    onlyOwner();
    txExists(_txId);
    notApproved(_txId);
    notExecuted(_txId);

    approved[_txId][msg.sender] = true;
    emit Approve(msg.sender, _txId);
  }

  function _getApprovalCount(uint16 _txId) private view returns (uint32 count) {
    for(uint16 i; i < owners.length; i = unsafe_increment16(i)) {
      if (approved[_txId][owners[i]]) {
        count++;
      }
    }    
  }

  function revoke(uint16 _txId) external {
    onlyOwner();
    txExists(_txId);
    notExecuted(_txId);
    // require(approved[_txId][msg.sender], "tx not approved");
    approved[_txId][msg.sender] = false;
    Transaction storage transaction = transactions[_txId];
    transaction.revoked = true;
    emit Revoke(msg.sender, _txId);
  }

  function execute(uint16 _txId) external {
    onlyOwner();
    txExists(_txId);
    notExecuted(_txId);
    require(_getApprovalCount(_txId) >= required, "approvals < required");
    Transaction storage transaction = transactions[_txId];

    transaction.executed = true;

    // (bool success, ) = vaultAddr.call(transaction.data);
    (bool success, ) = msg.sender.call{gas: 10000000}(transaction.data);

    require(success, "tx failed");

    emit Execute(_txId);
  }

  function executeSwap(uint16 _txId) external {
    onlyOwner();
    txExists(_txId);
    notExecuted(_txId);
    require(_getApprovalCount(_txId) >= required, "approvals < required");
    Transaction storage transaction = transactions[_txId];

    transaction.executed = true;

    (bool success, ) = swapAddr.call{gas: 10000000}(transaction.data);

    require(success, "tx failed");

    emit Execute(_txId);
  }

  function executeVault(uint16 _txId) external {
    onlyOwner();
    txExists(_txId);
    notExecuted(_txId);
    require(_getApprovalCount(_txId) >= required, "approvals < required");
    Transaction storage transaction = transactions[_txId];

    transaction.executed = true;

    (bool success, ) = vaultAddr.call{gas: 10000000}(transaction.data);

    require(success, "tx failed");

    emit Execute(_txId);
  }

  function transaction_amt() external view returns(uint256) {
    return transactions.length;
  }

  function transaction_item(uint16 _id) external view returns(Transaction memory) {
    return transactions[_id];
  }

  function transaction_all() external view returns(Transaction[] memory) {
    return transactions;
  }

  function transactions_pending() external view returns (Transaction[] memory) {
    uint256 pendingCount = 0;
    for (uint16 i = 0; i < transactions.length; i = unsafe_increment16(i)) {
      if (!transactions[i].executed && !transactions[i].revoked) {
        pendingCount++;
      }
    }

    Transaction[] memory stack = new Transaction[](pendingCount);
    uint256 index = 0;
    for (uint16 i = 0; i < transactions.length; i = unsafe_increment16(i)) {
      if (!transactions[i].executed && !transactions[i].revoked) {
        stack[index] = transactions[i];
        index++;
      }
    }
    return stack;
  }

  function getTranche(uint16 _trancheNumber) external returns (uint256, uint256, uint16, SwapInterface.TrancheState) {
    return swap.getTrancheParams(_trancheNumber);
  }

  function addTranche(uint256 total, uint256 available, uint256 lockDuration, uint16 price) external {
    bytes memory data = abi.encodeCall(swap.addTranche,
     (total, available, lockDuration, price)
    );
    submit(data, 'swap', 'Add New Tranche');
  }

  function setMaxPerTranche(uint16 trancheNumber, uint256 max) external {
    bytes memory data = abi.encodeCall(swap.setMaxPerTranche,
     (trancheNumber, max)
    );
    submit(data, 'swap', 'Set max BRX per tranche');
  }

  function addWhitelist(address[] memory accounts) external {
    bytes memory data = abi.encodeCall(swap.addWhitelist,
     (accounts)
    );
    submit(data, 'swap', 'Add address to whitelist');
  }

  function changeTrancheState (uint16 trancheNumber, SwapInterface.TrancheState newstate) external {
    bytes memory data = abi.encodeCall(swap.changeTrancheState,
     (trancheNumber, newstate)
    );
    submit(data, 'swap', 'Change the tranche state');
  }

  function removeWhitelist (address[] memory accounts) external {
    bytes memory data = abi.encodeCall(swap.removeWhitelist,
     (accounts)
    );
    submit(data, 'swap', 'Remove an address from the whitelist');
  }

  function setMaxBRXAllowed (uint256 _amount) external {
    bytes memory data = abi.encodeCall(swap.setMaxBRXAllowed,
     (_amount)
    );
    submit(data, 'swap', 'Set the max BRX allowed for purchase');
  }

  function setMinPurchase(uint32 _minPurchase) external {
    bytes memory data = abi.encodeCall(swap.setMinPurchase,
     (_minPurchase)
    );
    submit(data, 'swap', 'Set the minimum BRX purchase');
  }

  // Vault Functions
  
  /// @notice Sets the percentage penalty that will not be refunded
  /// @param _amount - this number is in human readable base 10 eg. 20%
  function setPenaltyAmount(uint256 _amount) external {
    bytes memory data = abi.encodeCall(vault.setPenaltyAmount,
     (_amount)
    );
    submit(data, 'vault', 'Set refund penalty percentage');
  }

  /// @notice Adds BRX token to the vault to facilitate swaps
  function supplyBRX (uint256 _amount) external {
    bytes memory data = abi.encodeCall(vault.supplyBRX,
     (_amount)
    );
    submit(data, 'vault', 'Supply BRX to the vault');
  }

  /// @notice This removes BRX from the vault
  /// @param _amount This is the amount of BRX to be removed by contract owner
  function removeBRX(uint256 _amount) external {
    bytes memory data = abi.encodeCall(vault.removeBRX,
     (_amount)
    );
    submit(data, 'vault', 'Remove BRX from the vault');
  }

  /// @notice This adds USDC to the vault
  /// @param _amount - This is the amount of USDC to be added
  function addPaymentTokens(uint256 _amount) external {
    bytes memory data = abi.encodeCall(vault.addPaymentTokens,
     (_amount)
    );
    submit(data, 'vault', 'Add USDC to the vault');
  }

  /// @notice This removes USDC from the vault
  /// @param _amount This is the amount of USDC to be removed
  function removePaymentTokens(uint256 _amount) external {
    bytes memory data = abi.encodeCall(vault.removePaymentTokens,
     (_amount)
    );
    submit(data, 'vault', 'Remove USDC from the vault');
  }

/// @param _fundsAddress - Address for penalties to get routed to upon BRX purchase
  function setFundsAddress(address _fundsAddress) external {
    bytes memory data = abi.encodeCall(vault.setFundsAddress,
     (_fundsAddress)
    );
    submit(data, 'vault', 'Change treasury address');
  }
}