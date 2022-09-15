//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

abstract contract Relayer is Ownable {
  mapping(address => bool) private _relayers;

  function relayer(address _address) public view virtual returns (bool) {
    return _relayers[_address];
  }
  
  /**
   * @dev Throws if called by any account other than the relayer.
   */
  modifier onlyRelayer() {
    require(relayer(_msgSender()), "Relayer: caller is not the relayer");
    _;
  }

  /**
   * @dev Adds a relayer.
   */
  function addRelayer(address _address) public virtual onlyOwner {
    require(_address != address(0), "Relayer: the relayer is the zero address");   
    _relayers[_address] = true;
  }

  /**
   * @dev Adds one or more relayers.
   */
  function addRelayers(address[] memory _addresses) public virtual onlyOwner {
    for (uint256 i = 0; i < _addresses.length; i++) {
      addRelayer(_addresses[i]);
    }
  }

  /**
   * @dev Removes a relayer.
   */
  function removeRelayer(address _address) public virtual onlyOwner {
    require(_address != address(0), "Relayer: the relayer is the zero address");   
    _relayers[_address] = false;
  }

  /**
   * @dev Removes one or more approvers.
   */
  function removeRelayers(address[] memory _addresses) public virtual onlyOwner {
    for (uint256 i = 0; i < _addresses.length; i++) {
      removeRelayer(_addresses[i]);
    }
  }
}

abstract contract Approver is Ownable {
  mapping(address => bool) private _approvers;

  function approver(address _address) public view virtual returns (bool) {
    return _approvers[_address];
  }

  /**
   * @dev Adds an approver.
   */
  function addApprover(address _address) public virtual onlyOwner {
    require(_address != address(0), "Approver: the approver is the zero address");   
    _approvers[_address] = true;
  }

  /**
   * @dev Adds one or more approvers.
   */
  function addApprovers(address[] memory _addresses) public virtual onlyOwner {
    for (uint256 i = 0; i < _addresses.length; i++) {
      addApprover(_addresses[i]);
    }
  }

  /**
   * @dev Removes an approver.
   */
  function removeApprover(address _address) public virtual onlyOwner {
    require(_address != address(0), "Approver: the approver is the zero address");   
    _approvers[_address] = false;
  }

  /**
   * @dev Removes one or more approvers.
   */
  function removeApprovers(address[] memory _addresses) public virtual onlyOwner {
    for (uint256 i = 0; i < _addresses.length; i++) {
      removeApprover(_addresses[i]);
    }
  }
}

contract Swap is Relayer, Approver, EIP712 {
  using ECDSA for bytes32;

  IERC20 public token;
  mapping(bytes32 => bool) private _batches;
  mapping(uint256 => bytes32) private _requests;
  
  constructor(address _token, address _relayer, address _approver) EIP712("ShareRingSwap", "2.0") {
    require(_token != address(0), "Swap: the token is the zero address");
    token = IERC20(_token);
    require(token.balanceOf(address(this)) == 0, "Swap: the token must be an ERC20 contract");
    addRelayer(_relayer);
    addApprover(_approver);
  }

  event SwapCompleted(uint256[] indexed ids);

  /**
   * @dev Returns the token balance of the contract.
   */
  function tokensAvailable() public view returns (uint256) {
    return token.balanceOf(address(this));
  }

  /**
   * @dev Withdraws all remaining balance to owner's account.
   *
   * Currently it transfers ALL balance.
   * TBC: support partial withdraw?
   */
  function withdraw() public onlyOwner {
    uint256 balance = tokensAvailable();
    assert(balance > 0);
    token.transfer(owner(), balance);
  }

  /**
   * @dev Deposits token into the contract address.
   *
   * There are two options for transferring tokens into the contract:
   * - By transfer from address to contract address
   * - By approve allowance for this contract to transfer with this function 
   *
   * NOTE: The function only works when the allowance is approved.
   */
  function deposit(uint256 _amount) public onlyOwner {
    assert(_amount > 0);
    token.transferFrom(msg.sender, address(this), _amount);
  }

  /**
   * @dev Get a specified batch.
   */
  function batch(bytes32 _digest) external view returns (bool) {
    return _batches[_digest];
  }

  /**
   * @dev Get a specified request.
   */
  function request(uint256 _id) external view returns (bytes32) {
    return _requests[_id];
  }

  /**
   * @dev Returns the digest.
   *
   * NOTE: This function does not actually do any state change.
   *       It is just there for generating the approval digest.
   *
   * TBC: make it internal
   */
  function digest(uint256[] memory _ids, address[] memory _tos, uint256[] memory _amounts) public view returns(bytes32) {
    return _hashTypedDataV4(
      keccak256(
        abi.encode(
          keccak256("Swap(uint256[] ids,address[] tos,uint256[] amounts)"),
          keccak256(abi.encodePacked(_ids)),
          keccak256(abi.encodePacked(_tos)),
          keccak256(abi.encodePacked(_amounts))
        )
      )
    );
  }

  /**
   * @dev Returns the signer's address if signature is valid, otherwise a strange address (or 0x0).
   *
   * NOTE: This function does not actually do any state change.
   *       It is just there for verifying the approval signature.
   *
   * TBC: make it internal
   */
  function verify(uint256[] memory _ids, address[] memory _tos, uint256[] memory _amounts, bytes memory signature) public view returns(address) {
    bytes32 hash = digest(_ids, _tos, _amounts);
    return verify(hash, signature);
  }

  function verify(bytes32 _digest, bytes memory signature) internal pure returns(address) {
    return _digest.recover(signature);
  }

  /**
   * @dev Proceeds the swaps and transfer tokens.
   */
  function swap(uint256[] memory _ids, address[] memory _tos, uint256[] memory _amounts, bytes memory _signature) public onlyRelayer {
    // 1. validate inputs
    require(_ids.length > 0 && _tos.length > 0 && _amounts.length > 0, "Swap: one or more inputs are empty");
    require(_tos.length == _amounts.length && _ids.length == _tos.length, "Swap: the input lengths do not match");
    bytes32 _digest = digest(_ids, _tos, _amounts);
    require(_batches[_digest] == false, "Swap: batch already exists");
    // 2. validate signature
    address signer = verify(_digest, _signature);
    require(signer != address(0), "ECDSA: signature is not valid");
    require(approver(signer) == true, "Swap: the signer is not an approver");
    _batches[_digest] = true;
    // 3. proceed with sending tokens
    for (uint256 i = 0; i < _tos.length; i++) {
      // additional check if request already proceeded
      require(_requests[_ids[i]] == 0, "Swap: request already exists");
      _requests[_ids[i]] = _digest;
      token.transfer(_tos[i], _amounts[i]);
    }
    emit SwapCompleted(_ids);
  }
}