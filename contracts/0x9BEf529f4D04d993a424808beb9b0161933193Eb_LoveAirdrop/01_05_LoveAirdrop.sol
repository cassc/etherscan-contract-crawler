// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

interface ILoveMarketplace {
  function checkRole(address accountToCheck, string memory role) external view returns (bool);
}

contract LoveAirdrop is Ownable {
  struct LoveDrop {
    address creator;
    bytes32 root;
    uint256 total;
    uint256 claimed;
    bool cancelled;
  }

  mapping(bytes32 => LoveDrop) public drops;
  mapping(bytes32 => mapping(address => bool)) public isClaimed;

  IERC20 private _token;
  ILoveMarketplace private _marketplace;
  uint256 public reservedBalance;

  event LoveDropCreated(string dropName, address indexed creator, bytes32 root, uint256 total);
  event LoveClaimed(string indexed dropName, address indexed recipient, uint256 amount);
  event LoveDropCancelled(string dropName);
  event TokensWithdrawn(uint256 amount);

  constructor(address tokenAddress, address marketplace, address admin) {
    _marketplace = ILoveMarketplace(marketplace);
    _token = IERC20(tokenAddress);
    transferOwnership(admin);
  }

  modifier onlyAdmin() {
    bool isAdmin = _marketplace.checkRole(msg.sender, 'admin');
    require(isAdmin || msg.sender == owner(), 'only admin');
    _;
  }

  function createLoveDrop(string calldata dropName, bytes32 root, uint256 total) external onlyAdmin {
    uint256 reservedTotal = reservedBalance + total;
    require(_getLoveBalance() >= reservedTotal, 'insufficient balance');
    bytes32 nameHash = keccak256(bytes(dropName));
    require(drops[nameHash].creator == address(0), 'name already exists');

    drops[nameHash] = LoveDrop({creator: msg.sender, root: root, total: total, claimed: 0, cancelled: false});
    reservedBalance = reservedTotal;

    emit LoveDropCreated(dropName, msg.sender, root, total);
  }

  function cancelLoveDrop(string calldata dropName) external onlyAdmin {
    bytes32 nameHash = keccak256(bytes(dropName));
    LoveDrop storage drop = drops[nameHash];
    require(drop.creator != address(0), 'LoveDrop does not exist');
    require(!drop.cancelled, 'LoveDrop is cancelled');

    reservedBalance -= drop.total - drop.claimed;
    drop.cancelled = true;

    emit LoveDropCancelled(dropName);
  }

  function claim(string memory dropName, address recipient, uint256 amount, bytes32[] calldata proof) external {
    bytes32 nameHash = keccak256(bytes(dropName));
    require(drops[nameHash].creator != address(0), 'LoveDrop does not exist');

    LoveDrop storage drop = drops[nameHash];

    require(!drop.cancelled, 'LoveDrop is cancelled');
    require(!isClaimed[nameHash][recipient], 'already claimed');
    require(verifyClaim(proof, drop.root, recipient, amount), 'invalid proof');

    isClaimed[nameHash][recipient] = true;
    drop.claimed += amount;
    reservedBalance -= amount;
    require(_token.transfer(recipient, amount), 'transfer failed');

    emit LoveClaimed(dropName, recipient, amount);
  }

  function withdrawTokens(uint256 amount) external onlyOwner {
    require(amount > 0, 'Invalid amount');
    require(_getLoveBalance() - reservedBalance >= amount, 'Insufficient balance (reserved)');
    require(_token.transfer(owner(), amount), 'Transfer failed');

    emit TokensWithdrawn(amount);
  }

  function verifyClaim(
    bytes32[] memory proof,
    bytes32 root,
    address recipient,
    uint256 amount
  ) public pure returns (bool) {
    bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(recipient, amount))));

    return MerkleProof.verify(proof, root, leaf);
  }

  function _getLoveBalance() internal view returns (uint256) {
    return _token.balanceOf(address(this));
  }
}