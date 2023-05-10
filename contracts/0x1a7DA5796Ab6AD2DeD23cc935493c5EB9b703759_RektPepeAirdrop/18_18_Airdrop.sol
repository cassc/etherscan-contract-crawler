// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract RektPepeAirdrop is Initializable, OwnableUpgradeable, UUPSUpgradeable {
  using SafeERC20 for IERC20;
  using ECDSA for bytes32;
  using ECDSA for bytes;

  address public signer;
  uint256 public deadline;
  address public rektPepe;
  mapping(address => bool) public claimedAddresses;

  event ClaimAirdrop(address _account);

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize() public initializer {
    __Ownable_init();
    __UUPSUpgradeable_init();
    rektPepe = 0x874bdE83cDA6Aa224527a3f43AEbC3CC60f49428;
  }

  function _authorizeUpgrade(
    address newImplementation
  ) internal override onlyOwner {}

  function claim(
    address _user,
    uint256 _amount,
    bytes32 _hashedMessage,
    bytes memory _signature
  ) public {
    require(
      _hashedMessage.toEthSignedMessageHash().recover(_signature) == signer,
      "InvalidSigner"
    );

    bytes32 msgHash = keccak256(abi.encodePacked(_user, _amount));
    require(msgHash == _hashedMessage, "InvalidSignature");

    require(block.timestamp < deadline, "Time has expired");

    require(!claimedAddresses[_user], "Already claimed");

    IERC20 rektPepeContract = IERC20(rektPepe);
    require(
      rektPepeContract.balanceOf(address(this)) >= _amount,
      "InvalidAmount"
    );

    rektPepeContract.safeTransfer(_user, _amount);
    claimedAddresses[_user] = true;

    emit ClaimAirdrop(_user);
  }

  function setREKTPEPE(address _rektPepe) public onlyOwner {
    rektPepe = _rektPepe;
  }

  function setSigner(address _signer) public onlyOwner {
    signer = _signer;
  }

  function setDeadline(uint256 _deadline) public onlyOwner {
    deadline = _deadline;
  }

  function withdraw(
    address payable receiver,
    uint256 amount
  ) public virtual onlyOwner {
    require(receiver != address(0x0), "BHP:E-403");
    IERC20 rektPepeContract = IERC20(rektPepe);
    require(
      rektPepeContract.balanceOf(address(this)) >= amount,
      "InvalidAmount"
    );
    rektPepeContract.safeTransfer(receiver, amount);
  }
}