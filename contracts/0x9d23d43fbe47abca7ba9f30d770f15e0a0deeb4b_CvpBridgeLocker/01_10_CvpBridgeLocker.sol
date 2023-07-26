// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IDeBridgeGate.sol";
import "./interfaces/Flags.sol";
import "./interfaces/ICallProxy.sol";

contract CvpBridgeLocker is Ownable {
  using SafeERC20 for IERC20;
  using Flags for uint256;

  IDeBridgeGate public deBridgeGate;
  IERC20 public immutable cvp;

  mapping(uint256 => address) public destinationChainContracts;
  mapping(uint256 => address) public sourceChainsContracts;

  mapping(uint256 => uint256) public chainLimitPerDay;
  mapping(uint256 => mapping(uint256 => uint256)) public transfersPerDay;

  event SendToChain(address sender, uint256 amount, uint256 toChainID, address indexed receipient, uint32 indexed referralCode, bytes32 indexed submissionId);
  event Unlock(address indexed sender, uint256 amount, uint256 indexed fromChainID, address indexed receipient);

  constructor(IDeBridgeGate _deBridgeGate, IERC20 _cvp) Ownable() {
    deBridgeGate = _deBridgeGate;
    cvp = _cvp;
  }

  /**
    Returns the current chain ID, as an integer.
    @return cid uint256 representing the current chain ID.
  */
  function getChainId() public virtual view returns (uint256 cid) {
    assembly {
      cid := chainid()
    }
  }

  /**
    Send CVP Tokens to another blockchain
    @dev Sends CVP tokens to the specified recipient on the specified chain.
    @param _toChainID ID of the destination chain.
    @param _amount Amount of CVP tokens to be sent.
    @param _recipient Address of the recipient on the destination chain.
    @param _referralCode An optional referral code to include in the transaction.
  */
  function sendToChain(uint256 _toChainID, uint256 _amount, address _recipient, uint32 _referralCode) external payable {
    require(destinationChainContracts[_toChainID] != address(0), "Chain contract address not specified");
    _checkChainLimits(_toChainID, _amount);

    cvp.safeTransferFrom(msg.sender, address(this), _amount);

    bytes memory dstTxCall = _encodeUnlockCommand(_amount, _recipient);
    bytes32 submissionId = _send(dstTxCall, _toChainID, _referralCode);
    emit SendToChain(msg.sender, _amount, _toChainID, _recipient, _referralCode, submissionId);
  }

  /**
    Unlock CVP Tokens received from another blockchain
    @dev Unlocks CVP tokens received from the specified chain and sends them to the specified recipient.
    @param _fromChainID ID of the source chain.
    @param _amount Amount of CVP tokens to be unlocked.
    @param _recipient Address of the recipient of the unlocked CVP tokens.
  */
  function unlock(uint256 _fromChainID, uint256 _amount, address _recipient) external {
    require(sourceChainsContracts[_fromChainID] != address(0), "Chain contract address not specified");
    _onlyCrossChain(_fromChainID);
    _checkChainLimits(_fromChainID, _amount);

    cvp.safeTransfer(_recipient, _amount);
    emit Unlock(msg.sender, _amount, _fromChainID, _recipient);
  }

  /**
    Check chain limits for cross-chain transfers
    @dev Checks if the specified amount of tokens can be transferred to the specified chain based on the daily limit set for the chain.
    @param _chainID ID of the chain being checked for the transfer limit.
    @param _amount Amount of tokens to be transferred.
  */
  function _checkChainLimits(uint256 _chainID, uint256 _amount) internal {
    uint256 curEpoch = block.timestamp / 1 days;
    transfersPerDay[_chainID][curEpoch] += _amount;

    require(chainLimitPerDay[_chainID] >= transfersPerDay[_chainID][curEpoch], "Limit reached");
  }

  /**
    Check if function is called by a valid cross-chain contract
    @dev Checks if the function is being called by a valid cross-chain contract for the specified source chain.
    @param _fromChainID ID of the source chain.
  */
  function _onlyCrossChain(uint256 _fromChainID) internal {
    ICallProxy callProxy = ICallProxy(deBridgeGate.callProxy());

    // caller is CallProxy?
    require(address(callProxy) == msg.sender, "Not callProxy");

    uint256 chainIdFrom = callProxy.submissionChainIdFrom();
    require(chainIdFrom == _fromChainID, "Chain id does not match");
    bytes memory nativeSender = callProxy.submissionNativeSender();
    require(keccak256(abi.encodePacked(sourceChainsContracts[chainIdFrom])) == keccak256(nativeSender), "Not valid sender");
  }

  /**
    Encode the unlock command for cross-chain transfer
    @dev Encodes the unlock command with the specified amount and recipient address for the current chain ID.
    @param _amount Amount of tokens to be unlocked.
    @param _recipient Address of the recipient of the unlocked tokens.
    @return The encoded unlock command.
  */
  function _encodeUnlockCommand(uint256 _amount, address _recipient)
    internal
    view
    returns (bytes memory)
  {
    return
    abi.encodeWithSelector(
      CvpBridgeLocker.unlock.selector,
      getChainId(),
      _amount,
      _recipient
    );
  }

  /**
    Send the transaction to the specified chain
    @dev Sends the transaction to the specified chain using the deBridgeGate.
    @param _dstTransactionCall The encoded transaction to be sent to the destination chain.
    @param _toChainId The ID of the destination chain.
    @param _referralCode An optional referral code to include in the transaction.
  */
  function _send(bytes memory _dstTransactionCall, uint256 _toChainId, uint32 _referralCode) internal returns(bytes32 submissionId) {
    uint flags = uint(0)
      .setFlag(Flags.REVERT_IF_EXTERNAL_FAIL, true)
      .setFlag(Flags.PROXY_WITH_SENDER, true);

    return deBridgeGate.sendMessage{value : msg.value}(
      _toChainId, // _chainIdTo
      abi.encodePacked(destinationChainContracts[_toChainId]), // _targetContractAddress
      _dstTransactionCall, // _targetContractCalldata
      flags, // _flags
      _referralCode // _referralCode
    );
  }

  /**
    Allows the owner to set the address of the DeBridgeGate contract.
    @param _deBridgeGate Address of the new DeBridgeGate contract.
  */
  function setDeBridgeGate(IDeBridgeGate _deBridgeGate) external onlyOwner {
    deBridgeGate = _deBridgeGate;
  }

  /**
    @dev Allows the owner to set the address of the destination chain contract for a given chain ID.
    @param _chainId uint256 ID of the chain to set the destination chain contract for.
    @param _contract address Address of the destination chain contract to set.
  */
  function setDestinationChainContract(uint256 _chainId, address _contract) external onlyOwner {
    destinationChainContracts[_chainId] = _contract;
  }

  /**
    @dev Allows the owner to set the address of the source chain contract for a given chain ID.
    @param _chainId uint256 ID of the chain to set the source chain contract for.
    @param _contract address Address of the source chain contract to set.
  */
  function setSourceChainContract(uint256 _chainId, address _contract) external onlyOwner {
    sourceChainsContracts[_chainId] = _contract;
  }

  /**
    @dev Allows the owner to set the maximum transfer limit per day for a specific chain.
    @param _chainId uint256 ID of the chain for which the limit needs to be set.
    @param _amount uint256 Maximum amount that can be transferred per day.
  */
  function setChainLimitPerDay(uint256 _chainId, uint256 _amount) external onlyOwner {
    chainLimitPerDay[_chainId] = _amount;
  }

  /**
    @dev Transfers _amount tokens of _token to the _newBridge address for migration purposes.
    @param _token address of the token to be migrated.
    @param _newBridge address of the new bridge where the tokens will be migrated.
    @param _amount amount of tokens to be migrated.
  */
  function migrate(address _token, address _newBridge, uint256 _amount) external onlyOwner {
    IERC20(_token).safeTransfer(_newBridge, _amount);
  }
}