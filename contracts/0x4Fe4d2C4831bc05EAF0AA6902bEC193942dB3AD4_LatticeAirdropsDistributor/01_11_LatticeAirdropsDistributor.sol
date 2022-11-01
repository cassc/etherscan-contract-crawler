//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';

contract LatticeAirdropsDistributor is Ownable, ReentrancyGuard, Pausable {
  using SafeERC20 for IERC20;

  struct Airdrop {
    IERC20 token;
    uint256 amountTotal;
    uint256 amountClaimed;
    uint64 airdropStartsAt;
    uint64 vestingPeriod;
    bytes32 merkleRoot;
  }

  // AirdropId -> Token Interface
  mapping(uint256 => Airdrop) private _airdrops;

  // AirdropId -> ClaimingUser -> Total Claimed;
  mapping(uint256 => mapping(address => uint256)) private _claimedAmounts;

  event AirdropCreated(
    uint256 indexed airdropId,
    address indexed token,
    uint256 amount,
    address debitAccount
  );
  event AirdropConfigured(
    uint256 indexed airdropId,
    bytes32 indexed merkleRoot,
    uint64 airdropStartsAt,
    uint64 vestingPeriod
  );
  event AirdropClaimed(
    address indexed user,
    uint256 totalAmount,
    uint256 totalAmountClaimed
  );

  function createAirdrop(
    uint256 airdropId,
    IERC20 token,
    uint256 amount,
    address debitAccount
  ) public onlyOwner {
    require(
      address(_airdrops[airdropId].token) == address(0),
      'Airdrop at specified id exists'
    );
    require(
      token.balanceOf(debitAccount) >= amount,
      'Holding pool does not have enough tokens'
    );
    require(
      token.allowance(debitAccount, address(this)) >= amount,
      'Spender does not have enough allowance'
    );

    Airdrop memory airdrop;
    airdrop.token = token;
    airdrop.amountTotal = amount;

    _airdrops[airdropId] = airdrop;

    token.safeTransferFrom(debitAccount, address(this), amount);

    emit AirdropCreated(airdropId, address(token), amount, debitAccount);
  }

  function configureAirdrop(
    uint256 airdropId,
    uint64 airdropStartsAt,
    uint64 vestingPeriod,
    bytes32 merkleRoot,
    bool _force
  ) public onlyOwner {
    require(
      address(_airdrops[airdropId].token) != address(0),
      'Airdrop at specified id does not exist'
    );
    require(
      _airdrops[airdropId].airdropStartsAt == 0 || _force,
      'Airdrop is already live'
    );

    _airdrops[airdropId].airdropStartsAt = airdropStartsAt;
    _airdrops[airdropId].vestingPeriod = vestingPeriod;
    _airdrops[airdropId].merkleRoot = merkleRoot;

    emit AirdropConfigured(
      airdropId,
      merkleRoot,
      airdropStartsAt,
      vestingPeriod
    );
  }

  function getAirdropById(uint256 airdropId)
    public
    view
    returns (Airdrop memory)
  {
    require(
      address(_airdrops[airdropId].token) != address(0),
      'Airdrop at specified id does not exist'
    );
    return _airdrops[airdropId];
  }

  function verifyClaim(
    uint256 airdropId,
    address claimingUser,
    uint256 totalAmount,
    bytes32 merkleRoot,
    bytes32[] memory merkleProof
  ) public pure returns (bool) {
    bytes32 computedHash = sha256(
      abi.encodePacked(airdropId, claimingUser, totalAmount)
    );

    for (uint256 i = 0; i < merkleProof.length; i++) {
      bytes32 proofElement = merkleProof[i];

      if (computedHash <= proofElement) {
        // Hash(current computed hash + current element of the proof)
        computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
      } else {
        // Hash(current element of the proof + current computed hash)
        computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
      }
    }

    // Check if the computed hash (root) is equal to the provided root
    return computedHash == merkleRoot;
  }

  function amountAvailableToClaim(
    uint256 airdropId,
    address claimingUser,
    uint256 totalAmount,
    bool discountClaimedAmount
  ) public view returns (uint256) {
    require(
      address(_airdrops[airdropId].token) != address(0),
      'Airdrop at specified id does not exist'
    );
    require(
      _airdrops[airdropId].airdropStartsAt != 0,
      'Airdrop is not live / configured'
    );
    require(
      block.timestamp >= _airdrops[airdropId].airdropStartsAt,
      'Airdrop has not started yet'
    );

    uint256 _timePassedSinceStart = block.timestamp -
      _airdrops[airdropId].airdropStartsAt;
    uint64 vestingPeriod = _airdrops[airdropId].vestingPeriod;
    uint256 _amountAvailable = 0;

    if (vestingPeriod > 0) {
      _amountAvailable = (totalAmount / vestingPeriod) * _timePassedSinceStart;
      _amountAvailable = _amountAvailable > totalAmount
        ? totalAmount
        : _amountAvailable;
    } else {
      _amountAvailable = totalAmount;
    }

    if (discountClaimedAmount) {
      uint256 _amountClaimed = _claimedAmounts[airdropId][claimingUser];
      return _amountAvailable - _amountClaimed;
    } else {
      return _amountAvailable;
    }
  }

  function amountClaimedByUser(uint256 airdropId, address claimingUser)
    public
    view
    returns (uint256)
  {
    require(
      address(_airdrops[airdropId].token) != address(0),
      'Airdrop at specified id does not exist'
    );
    require(
      _airdrops[airdropId].airdropStartsAt != 0,
      'Airdrop is not live / configured'
    );
    require(
      block.timestamp >= _airdrops[airdropId].airdropStartsAt,
      'Airdrop has not started yet'
    );

    return _claimedAmounts[airdropId][claimingUser];
  }

  function claim(
    uint256 airdropId,
    uint256 totalAmount,
    bytes32[] memory merkleProof
  ) public whenNotPaused nonReentrant {
    require(
      address(_airdrops[airdropId].token) != address(0),
      'Airdrop at specified id does not exist'
    );
    require(
      _airdrops[airdropId].airdropStartsAt != 0,
      'Airdrop is not live / configured'
    );
    require(
      block.timestamp >= _airdrops[airdropId].airdropStartsAt,
      'Airdrop has not started yet'
    );
    require(
      this.verifyClaim(
        airdropId,
        msg.sender,
        totalAmount,
        _airdrops[airdropId].merkleRoot,
        merkleProof
      ),
      'Merkle proof is invalid'
    );

    uint256 _amountToClaim = this.amountAvailableToClaim(
      airdropId,
      msg.sender,
      totalAmount,
      true
    );

    require(_amountToClaim > 0, 'There is no amount available to claim');

    IERC20 token = _airdrops[airdropId].token;

    token.safeTransfer(msg.sender, _amountToClaim);

    _airdrops[airdropId].amountClaimed += _amountToClaim;
    _claimedAmounts[airdropId][msg.sender] += _amountToClaim;

    emit AirdropClaimed(msg.sender, totalAmount, _amountToClaim);
  }
}