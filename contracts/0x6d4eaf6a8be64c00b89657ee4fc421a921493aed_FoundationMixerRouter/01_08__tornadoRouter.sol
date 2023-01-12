// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface IMixerInstance {
  function token() external view returns (address);

  function denomination() external view returns (uint256);

  function deposit(bytes32 commitment) external payable;

  function withdraw(
    bytes calldata proof,
    bytes32 root,
    bytes32 nullifierHash,
    address payable recipient,
    address payable relayer,
    uint256 fee,
    uint256 refund
  ) external payable;
}

contract FoundationMixerRouter is Initializable, OwnableUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  event EncryptedNote(address indexed sender, bytes encryptedNote);

  mapping(address => Instance) public instances;

  struct Instance {
    bool isERC20;
    IERC20Upgradeable token;
    uint8 state;
    uint256 fee;
  }

  function initialize() public initializer {
    __Ownable_init();
  }

  function deposit(
    address _mixer,
    bytes32 _commitment,
    bytes calldata _encryptedNote
  ) public payable virtual {
    Instance memory _instance = instances[_mixer];
    require(_instance.state != 0, "The instance is not supported");

    if (_instance.isERC20) {
      _instance.token.safeTransferFrom(msg.sender, address(this), IMixerInstance(_mixer).denomination());
    }
    IMixerInstance(_mixer).deposit{ value: msg.value }(_commitment);
    emit EncryptedNote(msg.sender, _encryptedNote);
  }

  function withdraw(
    IMixerInstance _mixer,
    bytes calldata _proof,
    bytes32 _root,
    bytes32 _nullifierHash,
    address payable _recipient,
    address payable _relayer,
    uint256 _fee,
    uint256 _refund
  ) public payable virtual {
    Instance memory _instance = instances[address(_mixer)];
    require(_instance.state != 0, "The instance is not supported");
    _mixer.withdraw{ value: msg.value }(_proof, _root, _nullifierHash, _recipient, _relayer, _fee, _refund);
  }

  /**
   * @notice Manually backup encrypted notes
   */
  function backupNotes(bytes[] calldata _encryptedNotes) external virtual {
    for (uint256 i = 0; i < _encryptedNotes.length; i++) {
      emit EncryptedNote(msg.sender, _encryptedNotes[i]);
    }
  }

  /// @dev Method to claim junk and accidentally sent tokens
  function rescueTokens(
    IERC20Upgradeable _token,
    address payable _to,
    uint256 _amount
  ) external virtual onlyOwner {
    require(_to != address(0), "Can not send to zero address");

    if (address(_token) == address(0)) {
      // for Ether
      uint256 totalBalance = address(this).balance;
      uint256 balance = totalBalance < _amount ? totalBalance : _amount;
      _to.transfer(balance);
    } else {
      // any other erc20
      uint256 totalBalance = _token.balanceOf(address(this));
       uint256 balance = totalBalance < _amount ? totalBalance : _amount;
      require(balance > 0, "Trying to send 0 balance");
      _token.safeTransfer(_to, balance);
    }
  }

  function manageInstance(
    address _mixer,
    bool _isERC20,
    IERC20Upgradeable _token,
    uint8 _state,
    uint256 _fee
  ) external virtual onlyOwner {
    instances[_mixer] = Instance(_isERC20, _token, _state, _fee);
  }

}