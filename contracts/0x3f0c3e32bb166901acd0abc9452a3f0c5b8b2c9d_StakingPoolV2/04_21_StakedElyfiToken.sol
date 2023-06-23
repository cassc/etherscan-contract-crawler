// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol';
import '../libraries/ERC20Metadata.sol';

contract StakedElyfiToken is ERC20, ERC20Permit, ERC20Votes {
  IERC20 public immutable underlying;

  constructor(IERC20 underlyingToken)
    ERC20(
      string(
        abi.encodePacked(
          'Staked',
          ERC20Metadata.tokenName(address(underlyingToken))
        )
      ),
      string(
        abi.encodePacked(
          's',
          ERC20Metadata.tokenSymbol(address(underlyingToken))
        )
      )
    )
    ERC20Permit(
      string(
        abi.encodePacked(
          'Staked',
          ERC20Metadata.tokenName(address(underlyingToken))
        )
      )
    )
  {
    underlying = underlyingToken;
  }

  /// @notice Transfer not supported
  function transfer(address recipient, uint256 amount)
    public
    virtual
    override(ERC20)
    returns (bool)
  {
    recipient;
    amount;
    revert();
  }

  /// @notice Transfer not supported
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override(ERC20) returns (bool) {
    sender;
    recipient;
    amount;
    revert();
  }

  /// @notice Approval not supported
  function approve(address spender, uint256 amount) public virtual override(ERC20) returns (bool) {
    spender;
    amount;
    revert();
  }

  /// @notice Allownace not supported
  function allowance(address owner, address spender)
    public
    view
    virtual
    override(ERC20)
    returns (uint256)
  {
    owner;
    spender;
    revert();
  }

  /// @notice Allownace not supported
  function increaseAllowance(address spender, uint256 addedValue)
    public
    virtual
    override(ERC20)
    returns (bool)
  {
    spender;
    addedValue;
    revert();
  }

  /// @notice Allownace not supported
  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    override(ERC20)
    returns (bool)
  {
    spender;
    subtractedValue;
    revert();
  }

  /// @dev Allow a user to deposit underlying tokens and mint the corresponding number of wrapped tokens.
  /// @notice This function is based on the openzeppelin ERC20Wrapper
  function _depositFor(address account, uint256 amount) internal virtual returns (bool) {
    SafeERC20.safeTransferFrom(underlying, _msgSender(), address(this), amount);
    _mint(account, amount);
    return true;
  }

  /// @dev Allow a user to burn a number of wrapped tokens and withdraw the corresponding number of underlying tokens.
  /// @notice This function is based on the openzeppelin ERC20Wrapper
  function _withdrawTo(address account, uint256 amount) internal virtual returns (bool) {
    _burn(_msgSender(), amount);
    SafeERC20.safeTransfer(underlying, account, amount);
    return true;
  }

  /// @notice The following functions are overrides required by Solidity.
  function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override(ERC20, ERC20Votes) {
    super._afterTokenTransfer(from, to, amount);
  }

  /// @notice The following functions are overrides required by Solidity.
  function _mint(address to, uint256 amount) internal override(ERC20, ERC20Votes) {
    super._mint(to, amount);
  }

  /// @notice The following functions are overrides required by Solidity.
  function _burn(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
    super._burn(account, amount);
  }
}