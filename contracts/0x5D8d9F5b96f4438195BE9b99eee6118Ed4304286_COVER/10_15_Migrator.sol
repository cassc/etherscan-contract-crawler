// SPDX-License-Identifier: None

pragma solidity ^0.7.4;

import "./ERC20/IERC20.sol";
import "./ERC20/SafeERC20.sol";
import "./utils/Ownable.sol";
import "./utils/SafeMath.sol";
import "./utils/MerkleProof.sol";
import "./interfaces/ICOVER.sol";
import "./interfaces/IMigrator.sol";

/**
 * @title COVER token migrator
 * @author [email protected] + @Kiwi
 */
contract Migrator is Ownable, IMigrator {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  IERC20 public safe2;
  ICOVER public cover;
  address public governance;
  bytes32 public immutable merkleRoot;
  uint256 public safe2Migrated; // total: 52,689.18
  uint256 public safeClaimed; // total: 2160.76
  uint256 public constant migrationCap = 54850e18;
  uint256 public constant START_TIME = 1605830400; // 11/20/2020 12am UTC
  mapping(uint256 => uint256) private claimedBitMap;

  constructor (address _governance, address _coverAddress, address _safe2, bytes32 _merkleRoot) {
    governance = _governance;
    cover = ICOVER(_coverAddress);

    require(_safe2 == 0x250a3500f48666561386832f1F1f1019b89a2699, "Migrator: safe2 address not match");
    safe2 = IERC20(_safe2);

    merkleRoot = _merkleRoot;
  }

  function isSafeClaimed(uint256 _index) public view override returns (bool) {
    uint256 claimedWordIndex = _index / 256;	
    uint256 claimedBitIndex = _index % 256;	
    uint256 claimedWord = claimedBitMap[claimedWordIndex];	
    uint256 mask = (1 << claimedBitIndex);	
    return claimedWord & mask == mask;
  }

  function migrateSafe2() external override {
    require(block.timestamp >= START_TIME, "Migrator: not started");
    uint256 safe2Balance = safe2.balanceOf(msg.sender);

    require(safe2Balance > 0, "Migrator: no safe2 balance");
    safe2.transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, safe2Balance);
    cover.mint(msg.sender, safe2Balance);
    safe2Migrated = safe2Migrated.add(safe2Balance);
  }

  function claim(uint256 _index, uint256 _amount, bytes32[] calldata _merkleProof) external override {
    require(block.timestamp >= START_TIME, "Migrator: not started");
    require(_amount > 0, "Migrator: amount is 0");
    require(!isSafeClaimed(_index), 'Migrator: already claimed');
    require(safe2Migrated.add(safeClaimed).add(_amount) <= migrationCap, "Migrator: cap exceeded"); // SAFE2 take priority first

    // Verify the merkle proof.
    bytes32 node = keccak256(abi.encodePacked(_index, msg.sender, _amount));
    require(MerkleProof.verify(_merkleProof, merkleRoot, node), 'Migrator: invalid proof');

    // Mark it claimed and send the token.
    _setClaimed(_index);
    safeClaimed = safeClaimed.add(_amount);
    cover.mint(msg.sender, _amount);
  }

  /// @notice transfer minting right to new migrator if migrator has issues. Once all migration is done, transfer right to 0.
  function transferMintingRights(address _newAddress) external override {
    require(msg.sender == governance, "Migrator: caller not governance");
    cover.setMigrator(_newAddress);
  }

  function _setClaimed(uint256 _index) private {	
    uint256 claimedWordIndex = _index / 256;	
    uint256 claimedBitIndex = _index % 256;	
    claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);	
  }
}