// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/ICLeverToken.sol";

// solhint-disable-next-line contract-name-camelcase
contract CLeverToken is Ownable, ERC20, ICLeverToken {
  using SafeERC20 for ERC20;
  using SafeMath for uint256;

  event UpdateMinter(address indexed _minter, bool _status);
  event UpdateCeiling(address indexed _minter, uint128 _ceiling);

  struct MinterInfo {
    // The maximum amount of CLeverToken can mint.
    uint128 ceiling;
    // The number of CLeverToken minted so far.
    uint128 minted;
  }

  /// @dev Mapping from address to minter status, `true` means is a minter and `false` means not.
  mapping(address => bool) public isMinter;
  /// @dev Mapping from minter address to minter info.
  mapping(address => MinterInfo) public minterInfo;

  modifier onlyMinter() {
    require(isMinter[msg.sender], "CLeverToken: only minter");
    _;
  }

  constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

  /********************************** Mutated Functions **********************************/

  /// @dev Mint tokens to a recipient.
  /// @param _recipient the account to mint tokens to.
  /// @param _amount the amount of tokens to mint.
  function mint(address _recipient, uint256 _amount) external override onlyMinter {
    MinterInfo memory _info = minterInfo[msg.sender];
    uint256 _minted = _info.minted;
    uint256 _ceiling = _info.ceiling;
    require(_minted.add(_amount) <= _ceiling, "CLeverToken: reach mint ceiling");
    minterInfo[msg.sender].minted = uint128(_minted + _amount);

    _mint(_recipient, _amount);
  }

  /// @dev Burn tokens of caller.
  /// @param _amount the amount of tokens to burn.
  function burn(uint256 _amount) external override {
    _burn(msg.sender, _amount);
  }

  /// @dev Burn tokens of a account.
  /// @param _account the account to burn tokens.
  /// @param _amount the amount of tokens to burn.
  function burnFrom(address _account, uint256 _amount) external override {
    uint256 _decreasedAllowance = allowance(_account, msg.sender).sub(
      _amount,
      "CLeverToken: burn amount exceeds allowance"
    );

    _approve(_account, msg.sender, _decreasedAllowance);
    _burn(_account, _amount);
  }

  /********************************** Restricted Functions **********************************/

  /// @dev Update the status of a list of minters.
  /// @param _minters The address list of minters.
  /// @param _status The status to update.
  function updateMinters(address[] memory _minters, bool _status) external onlyOwner {
    for (uint256 i = 0; i < _minters.length; i++) {
      require(_minters[i] != address(0), "CLeverToken: zero minter address");
      isMinter[_minters[i]] = _status;

      emit UpdateMinter(_minters[i], _status);
    }
  }

  /// @dev Update the mint ceiling for minter.
  /// @param _minter the address of minter to set the ceiling.
  /// @param _ceiling the max amount of tokens the account is allowed to mint.
  function updateCeiling(address _minter, uint128 _ceiling) external onlyOwner {
    require(isMinter[_minter], "CLeverToken: not minter");

    minterInfo[_minter].ceiling = _ceiling;

    emit UpdateCeiling(_minter, _ceiling);
  }
}