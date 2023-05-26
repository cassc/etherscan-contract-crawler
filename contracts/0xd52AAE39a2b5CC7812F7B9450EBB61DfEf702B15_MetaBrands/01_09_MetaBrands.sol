// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev MAGE: Metabrands official fungible token.
 */
contract MetaBrands is ERC20, ERC20Burnable, Ownable {
  using SafeERC20 for IERC20;

  // MageCreator contract address
  address public mageCreatorAddr;

  /**
   * @dev Initializes the contract setting the MageCreator contract address.
   */
  constructor(address _mageCreatorAddr) ERC20("MetaBrands", "MAGE") {
    _mint(msg.sender, 100_000_000 * 10**decimals());
    mageCreatorAddr = _mageCreatorAddr;
  }

  /**
   * @dev Sets the MageCreator contract address.
   *
   * Requirements:
   * - onlyOwner can call this function.
   */
  function setMageCreatorAddress(address _mageCreatorAddr) external onlyOwner {
    mageCreatorAddr = _mageCreatorAddr;
  }

  /**
   * @dev Gets balance of third party ERC20 token
   *
   */
  function getBalanceOfExternalERC20(address _erc20Address)
    external
    view
    returns (uint256)
  {
    return IERC20(_erc20Address).balanceOf(address(this));
  }

  /**
   * @dev Transfer third party ERC20 tokens.
   *
   * Requirements:
   * - onlyOwner can call this function.
   */
  function transferExternalERC20(
    address _erc20Address,
    address _recipient,
    uint256 _amount
  ) external onlyOwner {
    IERC20(_erc20Address).safeTransfer(_recipient, _amount);
  }

  /**
   * @dev Pre-approves the MageCreator contract address for token burning.
   *
   * Emits:
   * `Transfer` event.
   */
  function burnFrom(address account, uint256 amount) public override {
    if (_msgSender() != mageCreatorAddr) {
      return super.burnFrom(account, amount);
    }

    _burn(account, amount);
  }
}