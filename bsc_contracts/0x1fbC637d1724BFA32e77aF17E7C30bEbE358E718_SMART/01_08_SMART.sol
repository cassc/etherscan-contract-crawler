//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @title ERC20 token with fee per transfers
contract SMART is ERC20, Ownable {
  using SafeMath for uint256;

  /// @notice Address allowed to change fees and wallets to receive them.
  address public manager;
  /// @notice Contract that makes the staking.
  address public staking;
  /// @notice Airdrop Vault wallet.
  address public airdropVault;
  /// @notice Burning wallet.
  address public burningWallet;
  /// @notice Percentage fee that applies with each transaction of the token.
  /// e.g. 1000 = 1%, 500 = 0.5%
  uint256 public fee;

  constructor(
    address _manager,
    uint256 _initsupply,
    string memory _name,
    string memory _symbol,
    uint256 _fee,
    address _airdropVault,
    address _burningWallet
  ) ERC20(_name, _symbol) {
    ERC20._mint(_manager, _initsupply);
    manager = _manager;
    fee = _fee;
    airdropVault = _airdropVault;
    burningWallet = _burningWallet;
  }

  /// @notice Allow the ´manager´ to change the wallets that receives the fee.
  function setStakingAddress(address _staking) external onlyOwner {
    staking = _staking;
  }

  /// @notice set Airdrop Vault wallet
  function setTreasureWallet(address _airdropVault) external onlyOwner {
    airdropVault = _airdropVault;
  }

  /// @notice set Burning wallet
  function setStructureWallet(address _burningWallet) external onlyOwner {
    burningWallet = _burningWallet;
  }

  /// @notice Allow the ´manager´ to change the ´fee´.
  function setFee(uint256 _fee) external onlyOwner {
    fee = _fee;
  }

  /// @notice Transfer applying the fee.
  /// fee is adicional to the ´amount´ sended.
  function transfer(address recipient, uint256 amount)
    public
    override
    returns (bool)
  {
    uint256 _fee = (amount.mul(fee)).div(10000);
    _transfer(_msgSender(), recipient, amount);
    if (_msgSender() != staking) {
      _transfer(_msgSender(), airdropVault, _fee);
      _transfer(_msgSender(), burningWallet, _fee);
    }
    return true;
  }

  /// @notice TransferFrom applying the fee.
  /// fee is adicional to the ´amount´ sended.
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    // e.g. 50 = 0.005%
    uint256 _fee = (amount.mul(fee)).div(10000);
    _transfer(sender, recipient, amount);
    _transfer(sender, airdropVault, _fee);
    _transfer(sender, burningWallet, _fee);

    uint256 currentAllowance = allowance(sender, _msgSender());
    require(
      currentAllowance >= amount,
      "ERC20: transfer amount exceeds allowance"
    );
    unchecked {
      _approve(sender, _msgSender(), currentAllowance.sub(amount));
    }

    return true;
  }
}