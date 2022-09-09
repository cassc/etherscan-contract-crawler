// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @author Brewlabs
 * This contract has been developed by brewlabs.info
 */
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract ImpactXPMigration is Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  uint256 public constant MIGRATION_PRECISION = 10**20;
  uint256 public constant PERCENT_PRECISION = 10000;

  IERC20 public oldToken;
  IERC20 public newToken;
  uint256 public migrationRate;
  uint256 public taxOfOldToken = 1100;
  uint256 public bonusRate = 1000;

  bytes32 private merkleRoot;
  uint256 private totalStaked;
  uint256 private totalClaimed;

  bool public claimable = false;

  struct UserInfo {
    uint256 amount;
    uint256 claimed;
    uint256 paidAmount;
  }
  mapping(address => UserInfo) public userInfo;

  event Deposit(address user, uint256 amount);
  event Claim(address user, uint256 amount);

  event claimEnabled();
  event HarvestOldToken(uint256 amount);
  event SetMigrationToken(address token);
  event SetBonusRate(uint256 rate);
  event SetSnapShot(bytes32 merkleRoot);

  modifier canClaim() {
    require(claimable, "cannot claim");
    _;
  }

  /**
   * @notice Initialize the contract
   * @param _oldToken: token address
   * @param _newToken: reflection token address
   */
  constructor(address _oldToken, address _newToken) {
    oldToken = IERC20(_oldToken);
    newToken = IERC20(_newToken);

    migrationRate = (newToken.totalSupply() * MIGRATION_PRECISION) / oldToken.totalSupply();
  }

  function deposit(
    uint256 _amount,
    uint256 _max,
    bytes32[] memory _merkleProof
  ) external nonReentrant {
    require(merkleRoot != "", "Migration not enabled");

    // check if total deposits exceed snapshot
    uint256 prevAmt = (userInfo[msg.sender].amount * PERCENT_PRECISION) /
      (PERCENT_PRECISION - taxOfOldToken);
    require(_amount + prevAmt <= _max, "migration amount cannot exceed max");

    // Verify the merkle proof.
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _max));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid merkle proof.");

    uint256 beforeAmt = oldToken.balanceOf(address(this));
    oldToken.safeTransferFrom(msg.sender, address(this), _amount);
    uint256 afterAmt = oldToken.balanceOf(address(this));
    uint256 realAmt = afterAmt - beforeAmt;

    UserInfo storage user = userInfo[msg.sender];
    user.amount += realAmt;
    totalStaked += realAmt;

    emit Deposit(msg.sender, realAmt);
  }

  function claim() external nonReentrant {
    UserInfo storage user = userInfo[msg.sender];
    require(claimable, "claim not enabled");
    require(user.amount - user.claimed > 0, "not available to claim");

    uint256 pending = pendingClaim(msg.sender);
    if (pending > 0) {
      newToken.safeTransfer(msg.sender, pending);
    }

    user.claimed = user.amount;
    user.paidAmount += pending;
    totalClaimed += pending;
    emit Claim(msg.sender, pending);
  }

  function pendingClaim(address _user) public view returns (uint256) {
    UserInfo memory user = userInfo[_user];
    uint256 amount = user.amount - user.claimed;
    uint256 expectedAmt = (amount * (10000 + bonusRate)) / (10000 - taxOfOldToken);

    return (expectedAmt * migrationRate) / MIGRATION_PRECISION;
  }

  function insufficientClaims() external view returns (uint256) {
    uint256 tokenBal = newToken.balanceOf(address(this));
    uint256 expectedAmt = (totalStaked * (10000 + bonusRate)) / (10000 - taxOfOldToken);
    expectedAmt = (expectedAmt * migrationRate) / MIGRATION_PRECISION - totalClaimed;

    if (tokenBal > expectedAmt) return 0;
    return expectedAmt - tokenBal;
  }

  function setMigrationToken(address _newToken) external onlyOwner {
    require(!claimable, "claim was enabled");
    require(_newToken != address(0x0) && _newToken != address(newToken), "invalid new token");
    require(_newToken != address(oldToken), "cannot set old token address");

    newToken = IERC20(_newToken);
    migrationRate = (newToken.totalSupply() * MIGRATION_PRECISION) / oldToken.totalSupply();
    emit SetMigrationToken(_newToken);
  }

  function setBonusRate(uint256 _bonus) external onlyOwner {
    require(!claimable, "claim was enabled");
    require(_bonus < PERCENT_PRECISION, "invalid percent");
    bonusRate = _bonus;
    emit SetBonusRate(_bonus);
  }

  function setSnapShotMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
    emit SetSnapShot(_merkleRoot);
  }

  function enableClaim() external onlyOwner {
    require(!claimable, "already enabled");
    claimable = true;
    emit claimEnabled();
  }

  function harvestOldToken() external onlyOwner {
    uint256 amount = oldToken.balanceOf(address(this));
    oldToken.safeTransfer(msg.sender, amount);
    emit HarvestOldToken(amount);
  }

  /**
   * @notice It allows the admin to recover wrong tokens sent to the contract
   * @param _token: the address of the token to withdraw
   * @param _amount: the amount to withdraw, if amount is zero, all tokens will be withdrawn
   * @dev This function is only callable by admin.
   */
  function rescueTokens(address _token, uint256 _amount) external onlyOwner {
    if (_token == address(0x0)) {
      if (_amount > 0) {
        payable(msg.sender).transfer(_amount);
      } else {
        uint256 _tokenAmount = address(this).balance;
        payable(msg.sender).transfer(_tokenAmount);
      }
    } else {
      if (_amount > 0) {
        IERC20(_token).safeTransfer(msg.sender, _amount);
      } else {
        uint256 _tokenAmount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(msg.sender, _tokenAmount);
      }
    }
  }

  receive() external payable {}
}