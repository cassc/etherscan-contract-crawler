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

contract ZenaMigration is Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  IERC20 public oldToken;
  IERC20 public newToken;

  bytes32 private merkleRoot;
  bytes32 private claimMerkleRoot;
  uint256 private totalStaked;

  bool public claimable = false;

  struct UserInfo {
    uint256 amount;
    uint256 paidAmount;
  }
  mapping(address => UserInfo) public userInfo;

  event Deposit(address user, uint256 amount);
  event Claim(address user, uint256 amount);

  event claimEnabled();
  event HarvestOldToken(uint256 amount);
  event SetMigrationToken(address token);
  event SetSnapShot(bytes32 merkleRoot, bytes32 claimMerkleRoot);

  modifier canClaim() {
    require(claimable, "cannot claim");
    _;
  }

  /**
   * @notice Initialize the contract
   * @param _oldToken: token address
   * @param _newToken: new token address
   */
  constructor(address _oldToken, address _newToken) {
    oldToken = IERC20(_oldToken);
    newToken = IERC20(_newToken);
  }

  function deposit(uint256 _amount, bytes32[] memory _merkleProof) external nonReentrant {
    require(merkleRoot != "", "Migration not enabled");
    require(userInfo[msg.sender].amount == 0, "already migrated");

    // Verify the merkle proof.
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _amount));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid merkle proof.");

    oldToken.safeTransferFrom(msg.sender, address(this), _amount);

    UserInfo storage user = userInfo[msg.sender];
    user.amount = _amount;
    totalStaked += _amount;

    emit Deposit(msg.sender, _amount);
  }

  function claim(uint256 _amount, bytes32[] memory _merkleProof) external nonReentrant {
    UserInfo storage user = userInfo[msg.sender];
    require(claimable, "claim not enabled");
    require(user.amount > 0, "not migrate yet");
    require(user.paidAmount == 0, "already claimed");

    // Verify the merkle proof.
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _amount));
    require(MerkleProof.verify(_merkleProof, claimMerkleRoot, leaf), "Invalid merkle proof.");

    user.paidAmount = _amount;
    newToken.safeTransfer(msg.sender, _amount);

    emit Claim(msg.sender, _amount);
  }

  function setMigrationToken(address _newToken) external onlyOwner {
    require(!claimable, "claim was enabled");
    require(_newToken != address(0x0) && _newToken != address(newToken), "invalid new token");
    require(_newToken != address(oldToken), "cannot set old token address");

    newToken = IERC20(_newToken);
    emit SetMigrationToken(_newToken);
  }

  function setMerkleRoot(bytes32 _merkleRoot, bytes32 _claimMerkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
    claimMerkleRoot = _claimMerkleRoot;
    emit SetSnapShot(_merkleRoot, _claimMerkleRoot);
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
        uint256 _bnbAmount = address(this).balance;
        payable(msg.sender).transfer(_bnbAmount);
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