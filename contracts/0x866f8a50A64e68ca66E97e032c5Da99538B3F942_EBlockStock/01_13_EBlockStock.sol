// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import './EBlockStockACL.sol';

/// @author Blockben
/// @title EBlockStock
/// @notice EBlockStock implementation
contract EBlockStock is ERC20, EBlockStockACL {
  using SafeMath for uint256;

  constructor(address _superadmin) ERC20('EBlockStock', 'EBSO') EBlockStockACL(_superadmin) {}

  /**
   * Set the decimals of token to 4.
   */
  function decimals() public view virtual override returns (uint8) {
    return 4;
  }

  /**
   * @param _to Recipient address
   * @param _value Value to send to the recipient from the caller account
   */
  function transfer(address _to, uint256 _value) public override whenNotPaused returns (bool) {
    _transfer(_msgSender(), _to, _value);
    return true;
  }

  /**
   * @param _from Sender address
   * @param _to Recipient address
   * @param _value Value to send to the recipient from the sender account
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) public override whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  /**
   * @param _spender Spender account
   * @param _value Value to approve
   */
  function approve(address _spender, uint256 _value) public override whenNotPaused returns (bool) {
    require((_value == 0) || (allowance(_msgSender(), _spender) == 0), 'Approve: zero first');
    return super.approve(_spender, _value);
  }

  /**
   * @param _spender Account that allows the spending
   * @param _addedValue Amount which will increase the total allowance
   */
  function increaseAllowance(address _spender, uint256 _addedValue) public override whenNotPaused returns (bool) {
    return super.increaseAllowance(_spender, _addedValue);
  }

  /**
   * @param _spender Account that allows the spending
   * @param _subtractValue Amount which will decrease the total allowance
   */
  function decreaseAllowance(address _spender, uint256 _subtractValue) public override whenNotPaused returns (bool) {
    return super.decreaseAllowance(_spender, _subtractValue);
  }

  /**
   * @notice Only account with TREASURY_ADMIN is able to mint!
   * @param _account Mint eBSO to this account
   * @param _amount The mintig amount
   */
  function mint(address _account, uint256 _amount) external onlyRole(TREASURY_ADMIN) whenNotPaused returns (bool) {
    _mint(_account, _amount);
    return true;
  }

  /**
   * Burn eBSO from treasury account
   * @notice Only account with TREASURY_ADMIN is able to burn!
   * @param _amount The burning amount
   */
  function burn(uint256 _amount) external onlyRole(TREASURY_ADMIN) whenNotPaused {
    require(!getSourceAccountBL(treasuryAddress), 'Blacklist: treasury');
    _burn(treasuryAddress, _amount);
  }

  /**
   * @notice Account must not be on blacklist
   * @param _account Mint eBSO to this account
   * @param _amount The minting amount
   */
  function _mint(address _account, uint256 _amount) internal override {
    require(!getDestinationAccountBL(_account), 'Blacklist: target');
    super._mint(_account, _amount);
  }

  /**
   * Transfer token between accounts, based on eBSO TOS.
   * - bsoFee% of the transferred amount is going to bsoPoolAddress
   * - generalFee% of the transferred amount is going to amountGeneral
   *
   * @param _sender The address from where the token sent
   * @param _recipient Recipient address
   * @param _amount The amount to be transferred
   */
  function _transfer(
    address _sender,
    address _recipient,
    uint256 _amount
  ) internal override {
    require(!getSourceAccountBL(_sender), 'Blacklist: sender');
    require(!getDestinationAccountBL(_recipient), 'Blacklist: recipient');

    if ((_sender == treasuryAddress) || (_recipient == treasuryAddress)) {
      super._transfer(_sender, _recipient, _amount);
    } else {
      /**
       * Three decimal in percent.
       * The decimal correction is 100.000, but to avoid rounding errors, first divide by 10.000
       * and after that the calculation must add 5 and divide 10 at the end.
       */
      uint256 decimalCorrection = 10000;
      uint256 generalFeePercent256 = generalFee;
      uint256 bsoFeePercent256 = bsoFee;
      uint256 totalFeePercent = generalFeePercent256.add(bsoFeePercent256);

      uint256 totalFeeAmount = _amount.mul(totalFeePercent).div(decimalCorrection).add(5).div(10);
      uint256 amountBso = _amount.mul(bsoFeePercent256).div(decimalCorrection).add(5).div(10);
      uint256 amountGeneral = totalFeeAmount.sub(amountBso);

      uint256 recipientTransferAmount = _amount.sub(totalFeeAmount);

      super._transfer(_sender, _recipient, recipientTransferAmount);

      if (amountGeneral > 0) {
        super._transfer(_sender, feeAddress, amountGeneral);
      }

      if (amountBso > 0) {
        super._transfer(_sender, bsoPoolAddress, amountBso);
      }
    }
  }
}