// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.3;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "contracts/interfaces/ITrancheToken.sol";
import "contracts/OndoRegistryClientInitializable.sol";

/**
 * @title Fixed duration tokens representing tranches
 * @notice For every Vault, for every tranche, this ERC20 token enables trading.
 * @dev Since these are short-lived tokens and we are producing lots
 *      of them, this uses clones to cheaply create many instance.  in
 *      practice this is not upgradeable, we use openzeppelin's clone
 */
contract TrancheToken is ERC20Upgradeable, ITrancheToken, OwnableUpgradeable {
  OndoRegistryClientInitializable public vault;
  uint256 public vaultId;

  modifier whenNotPaused {
    require(!vault.paused(), "Global pause in effect");
    _;
  }

  modifier onlyRegistry {
    require(
      address(vault.registry()) == msg.sender,
      "Invalid access: Only Registry can call"
    );
    _;
  }

  function initialize(
    uint256 _vaultId,
    string calldata _name,
    string calldata _symbol,
    address _vault
  ) external initializer {
    __Ownable_init();
    __ERC20_init(_name, _symbol);
    vault = OndoRegistryClientInitializable(_vault);
    vaultId = _vaultId;
  }

  function mint(address _account, uint256 _amount)
    external
    override
    whenNotPaused
    onlyOwner
  {
    _mint(_account, _amount);
  }

  function burn(address _account, uint256 _amount)
    external
    override
    whenNotPaused
    onlyOwner
  {
    _burn(_account, _amount);
  }

  function transfer(address _account, uint256 _amount)
    public
    override(ERC20Upgradeable, IERC20Upgradeable)
    whenNotPaused
    returns (bool)
  {
    return super.transfer(_account, _amount);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _amount
  )
    public
    override(ERC20Upgradeable, IERC20Upgradeable)
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(_from, _to, _amount);
  }

  function approve(address _account, uint256 _amount)
    public
    override(ERC20Upgradeable, IERC20Upgradeable)
    whenNotPaused
    returns (bool)
  {
    return super.approve(_account, _amount);
  }

  function destroy(address payable _receiver)
    external
    override
    whenNotPaused
    onlyRegistry
  {
    selfdestruct(_receiver);
  }

  function increaseAllowance(address spender, uint256 addedValue)
    public
    override(ERC20Upgradeable)
    whenNotPaused
    returns (bool)
  {
    return super.increaseAllowance(spender, addedValue);
  }

  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    override(ERC20Upgradeable)
    whenNotPaused
    returns (bool)
  {
    return super.decreaseAllowance(spender, subtractedValue);
  }
}