// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.6;

import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { PackedBooleanArray } from "packed-solidity-arrays/contracts/PackedBooleanArray.sol";

contract MerkleDrop is Ownable {
  using SafeERC20 for IERC20;
  using PackedBooleanArray for PackedBooleanArray.PackedArray;

  event Claimed(address claimant, uint256 tranche, uint256 balance);
  event TrancheAdded(uint256 tranche, bytes32 merkleRoot, uint256 totalAmount, string uri);
  event TrancheExpired(uint256 tranche);
  event FunderAdded(address indexed _address);
  event FunderRemoved(address indexed _address);

  IERC20 public immutable token;

  mapping(uint256 => bytes32) public merkleRoots;
  mapping(address => PackedBooleanArray.PackedArray) internal claimed;
  mapping(address => bool) public funders;
  uint256 tranches;

  /**
   * @dev Modifier to allow function calls only from funder addresses.
   */
  modifier onlyFunder() {
    require(funders[msg.sender], "Must be a funder");
    _;
  }

  constructor(IERC20 _token) {
    token = _token;
  }

  function hasClaimed(address _user, uint256 _tranche) external view returns (bool) {
    return claimed[_user].getValue(_tranche);
  }

  /***************************************
                    ADMIN
  ****************************************/

  /**
   * @dev Add a tranche with new allocations to claim.
   * @param _merkleRoot  Merkle root of the tree of accounts/balances
   * @param _totalAllocation Total tokens allocated in the tranche
   * @param _uri URI representing the tranche, e.g. an IPFS hash of the allocations
   */
  function seedNewAllocations(
    bytes32 _merkleRoot,
    uint256 _totalAllocation,
    string memory _uri
  ) public onlyFunder returns (uint256 trancheId) {
    token.safeTransferFrom(msg.sender, address(this), _totalAllocation);

    trancheId = tranches;
    merkleRoots[trancheId] = _merkleRoot;

    tranches += 1;

    emit TrancheAdded(trancheId, _merkleRoot, _totalAllocation, _uri);
  }

  function expireTranche(uint256 _trancheId) public onlyFunder {
    merkleRoots[_trancheId] = bytes32(0);

    emit TrancheExpired(_trancheId);
  }

  /**
   * @dev Allows the owner to add a new funder
   * @param _address  Funder to add
   */
  function addFunder(address _address) public onlyOwner {
    require(_address != address(0), "Address is zero");
    require(!funders[_address], "Already a funder");

    funders[_address] = true;

    emit FunderAdded(_address);
  }

  /**
   * @dev Allows the owner to remove an inactive funder
   * @param _address  Funder to remove
   */
  function removeFunder(address _address) external onlyOwner {
    require(_address != address(0), "Address is zero");
    require(funders[_address], "Address is not a funder");

    funders[_address] = false;

    emit FunderRemoved(_address);
  }

  /***************************************
                  CLAIMING
  ****************************************/

  function claimTranche(
    address _claimer,
    uint256 _tranche,
    uint256 _balance,
    bytes32[] memory _merkleProof
  ) public {
    _claimTranche(_claimer, _tranche, _balance, _merkleProof);
    _disburse(_claimer, _balance);
  }

  function claimTranches(
    address _claimer,
    uint256[] memory _ids,
    uint256[] memory _balances,
    bytes32[][] memory _merkleProofs
  ) public {
    uint256 len = _ids.length;

    require(len > 0, "Must claim some tranches");
    require(len == _balances.length && len == _merkleProofs.length, "Mismatching inputs");

    uint256 totalBalance = 0;
    for (uint256 i = 0; i < len; i++) {
      _claimTranche(_claimer, _ids[i], _balances[i], _merkleProofs[i]);
      totalBalance += _balances[i];
    }

    _disburse(_claimer, totalBalance);
  }

  function verifyClaim(
    address _claimer,
    uint256 _tranche,
    uint256 _balance,
    bytes32[] memory _merkleProof
  ) public view returns (bool valid) {
    return _verifyClaim(_claimer, _tranche, _balance, _merkleProof);
  }

  /***************************************
              CLAIMING - INTERNAL
  ****************************************/

  function _claimTranche(
    address _claimer,
    uint256 _tranche,
    uint256 _balance,
    bytes32[] memory _merkleProof
  ) private {
    require(_tranche < tranches, "Tranche cannot be in the future");
    require(!claimed[_claimer].getValue(_tranche), "Address has already claimed");
    require(_verifyClaim(_claimer, _tranche, _balance, _merkleProof), "Incorrect merkle proof");
    claimed[_claimer].setValue(_tranche, true);
    emit Claimed(_claimer, _tranche, _balance);
  }

  function _verifyClaim(
    address _claimer,
    uint256 _tranche,
    uint256 _balance,
    bytes32[] memory _merkleProof
  ) private view returns (bool valid) {
    bytes32 leaf = keccak256(abi.encodePacked(_claimer, _balance));
    return MerkleProof.verify(_merkleProof, merkleRoots[_tranche], leaf);
  }

  function _disburse(address _claimer, uint256 _balance) private {
    if (_balance > 0) {
      token.safeTransfer(_claimer, _balance);
    } else {
      revert("No balance would be transferred - not going to waste your gas");
    }
  }
}