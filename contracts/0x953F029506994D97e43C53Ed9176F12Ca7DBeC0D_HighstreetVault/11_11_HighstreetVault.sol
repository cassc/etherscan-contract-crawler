// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract HighstreetVault is Ownable, Pausable, ReentrancyGuard {

  struct Input {
    uint16 chainId;
    uint256 deadline;
    bytes32 salt;
    address user;
    address token;
    uint256 price;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  struct Record {
    address user;
    address token;
    uint256 price;
    bool refund;
  }

  address public signer;
  address superOwner;
  mapping(address => bool) public tokenTable;
  mapping(bytes32 => Record) public recordTable;

  /**
   * @dev Fired in updateTokenTable()
   *
   * @param token a erc20 token address
   * @param isRemoved a bool represented token is removed or not
   */
  event UpdateTokenTable(address indexed token, bool isRemoved);

  /**
   * @dev Fired in updateSuperOwner()
   *
   * @param superOwner new super owner address
   */
  event UpdateSuperOwner(address superOwner);

  /**
   * @dev Fired in updateSigner()
   *
   * @param signer new signer address
   */
  event UpdateSigner(address signer);

  /**
   * @dev Fired in deposit()
   * @param user user address
   * @param salt a random hash to prevent input message collision
   * @param token a erc20 token address
   * @param price a number expected to receive
   */
  event Deposit(address indexed user, bytes32 indexed salt, address indexed token, uint256 price);

  /**
   * @dev Fired in withdraw()
   *
   * @param token a erc20 token address
   * @param balance a number of balance is been withdraw
   */
  event Withdraw(address indexed token, uint256 balance);

  /**
   * @dev Fired in refund()
   * @param sender owner address
   * @param user user address
   * @param salt a random hash to prevent input message collision
   * @param token a erc20 token address
   * @param price a number expected to receive
   */
  event Refund(address sender, address indexed user, bytes32 indexed salt, address indexed token, uint256 price);

  constructor(
    address signer_,
    address superOwner_,
    address [] memory tokens_
  ) {
    require(signer_ != address(0), "Invalid signer");
    require(superOwner_ != address(0), "Invalid superOwner");
    signer = signer_;
    superOwner = superOwner_;
    for (uint256 index = 0; index < tokens_.length; index++) {
      tokenTable[tokens_[index]] = true;
    }
  }

  function deposit(Input memory input_) external payable nonReentrant whenNotPaused {
    require(_msgSender() == input_.user, "Invalid sender");
    require(block.timestamp <= input_.deadline, "Execution exceed deadline");
    require(recordTable[input_.salt].user == address(0), "salt already exist");
    _verifyInputSignature(input_);

    if(input_.token != address(0)) {
      require(tokenTable[input_.token], "Unsupported token");
      SafeERC20.safeTransferFrom(IERC20(input_.token), input_.user, address(this), input_.price);
    } else {
      require(msg.value >= input_.price, "insufficient ether");
      uint256 change = msg.value - input_.price;
      if (change > 0) {
        payable(_msgSender()).transfer(change);
      }
    }

    recordTable[input_.salt] = Record({
      user: input_.user,
      token: input_.token,
      price: input_.price,
      refund: false
    });

    emit Deposit(input_.user, input_.salt, input_.token, input_.price);
  }

  function _verifyInputSignature(Input memory input_) internal view {
    uint chainId;
    assembly {
      chainId := chainid()
    }
    require(input_.chainId == chainId, "Invalid network");
    bytes32 hash_ = keccak256(abi.encode(input_.chainId, input_.deadline, input_.salt , input_.user, input_.token, input_.price));
    bytes32 appendEthSignedMessageHash = ECDSA.toEthSignedMessageHash(hash_);
    address inputSigner = ECDSA.recover(appendEthSignedMessageHash, input_.v, input_.r, input_.s);
    require(signer == inputSigner, "Invalid signer");
  }

  function updateSuperOwner(address superOwner_) external onlyOwner {
    require(superOwner_ != address(0), "invalid address");
    superOwner = superOwner_;
    emit UpdateSuperOwner(superOwner);
  }

  function updateSigner(address signer_) external onlyOwner {
    require(signer_ != address(0), "invalid address");
    signer = signer_;
    emit UpdateSigner(signer);
  }

  function updateTokenTable(address[] calldata toAdd_, address[] calldata toRemove_) external onlyOwner {
    for (uint256 i = 0; i < toAdd_.length; i++) {
      tokenTable[toAdd_[i]] = true;
      emit UpdateTokenTable(toAdd_[i], false);
    }
    for (uint256 i = 0; i < toRemove_.length; i++) {
      delete tokenTable[toRemove_[i]];
      emit UpdateTokenTable(toRemove_[i], true);
    }
  }

  function refund(bytes32 salt_, uint256 fee_) external {
    require(_msgSender() == superOwner|| _msgSender() == owner(), "Invalid caller");
    Record memory record = recordTable[salt_];
    require(record.user != address(0), "Invalid salt");
    require(!record.refund, "already refund");
    require(fee_ <= record.price, "refund exceed price");

    if(record.token != address(0)) {
      SafeERC20.safeTransfer(IERC20(record.token), record.user, fee_);
    } else {
      payable(record.user).transfer(fee_);
    }
    recordTable[salt_].refund = true;

    emit Refund(_msgSender(), record.user, salt_, record.token, fee_);
  }

  /**
   * @dev withdraw all ether to super owner
   *
   * @notice this function could only call by super owner
   */
  function withdraw() external {
    require(_msgSender() == superOwner|| _msgSender() == owner(), "Invalid caller");
    uint256 balance = address(this).balance;
    payable(superOwner).transfer(balance);
    emit Withdraw(address(0), balance);
  }

  /**
   * @dev withdraw all balance of token to super owner
   *
   * @notice this function could only call by super owner
   */
  function withdraw(address tokenAddr_) external {
    require(_msgSender() == superOwner || _msgSender() == owner(), "Invalid caller");
    require(tokenTable[tokenAddr_], "Unsupported token");
    IERC20 token = IERC20(tokenAddr_);
    uint256 balance = token.balanceOf(address(this));
    SafeERC20.safeTransfer( token, superOwner, balance);
    emit Withdraw(tokenAddr_, balance);
  }

  /**
   * @dev pause the minting process
   *
   * @notice this function could only call by owner
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * @dev unpause the minting process
   *
   * @notice this function could only call by owner
   */
  function unpause() external onlyOwner {
    _unpause();
  }

  receive() external payable {}
}