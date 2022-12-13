// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./libraries/DateString.sol";

contract BondToken is ERC20Upgradeable, OwnableUpgradeable {
    address public underlying;
    // TODO: possible optimization, consider getting rid of following two
    string public localName;
    string public localSymbol;

    // `lockedAmount` means the amount of tokens in locked state.
    //--------------------------------------
    // `BondToken::_transfer` Behavior:
    // To avoid this problem:
    //     1. SmartYield::buyBond
    //     2. SmartYield::rolloverBond
    //     3. SmartYield::borrow
    //     4. SmartYield::repay, SmartYield will transfer BondToken back to users
    //     5. SmartYield::sell `locked` BondToken on secondary market via `transfer()`
    // `BondToken::_transfer` will not change `lockedAmount`
    //--------------------------------------
    //--------------------------------------
    // `BondToken::_burn` Behavior:
    // It does not make much sense to change `BondToken::lockedAmount` during `BondToken::_burn`, because:
    // Three functiosn in `SmartYield` are using `BondToken::_burn`.
    //     1. SmartYield::redeemBond: the term ended already
    //     2. SmartYield::rolloverBond: the term started already, meaning the `locked` state expires.
    //     3. SmartYield::withdraw: SmartYield needs to make sure users will not withdraw `lockedAmount`
    // It is safe NOT to change `BondToken::lockedAmount` during `BondToken::_burn`.
    //--------------------------------------
    mapping(address => uint256) internal lockedAmount;

    // `lock state` expiration. if `lock` expires, locked tokens can be transfered freely
    uint256 internal expireTimeStamp;

    function initialize(address _underlying, uint256 _timestamp) external initializer {
        __Ownable_init();
        __ERC20_init(_processName(_underlying, _timestamp), _processSymbol("bb_SY_s", _underlying, _timestamp));
        require(IERC20MetadataUpgradeable(_underlying).totalSupply() > 0, "invalid underlying");
        underlying = _underlying;
        expireTimeStamp = _timestamp;
    }

    function decimals() public view virtual override returns (uint8) {
        return IERC20MetadataUpgradeable(underlying).decimals();
    }

    function _processName(address _underlying, uint256 _timestamp) internal returns (string memory) {
        // Set the name in the super
        localName = "Barnbridge SmartYield Bond Token ";
        // Use the library to write the rest
        string memory prefix = IERC20MetadataUpgradeable(_underlying).name();

        DateString._encodeAndWriteTimestamp(prefix, _timestamp, localName);
        // load and return the name
        return localName;
    }

    function _processSymbol(
        string memory _symbol_,
        address _underlying,
        uint256 _timestamp
    ) internal returns (string memory) {
        // Set the symbol in the super
        string memory prefix = IERC20MetadataUpgradeable(_underlying).symbol();
        localSymbol = _symbol_;
        // Use the library to write the rest
        DateString._encodeAndWriteTimestamp(prefix, _timestamp, localSymbol);
        // load and return the name
        return localSymbol;
    }

    /// @dev Mints tokens to an address
    /// @param _account The account to mint to
    /// @param _amount The amount to mint
    function mint(address _account, uint256 _amount) external onlyOwner {
        _mint(_account, _amount);
    }

    function mintLocked(address _account, uint256 _amount) external onlyOwner {
        _mint(_account, _amount);
        lockedAmount[_account] += _amount;
    }

    /// @dev Burns tokens from an address
    /// @param _account The account to burn from
    /// @param _amount The amount of token to burn
    function burn(address _account, uint256 _amount) external onlyOwner {
        _burn(_account, _amount);
    }

    function freeBalanceOf(address account) public view returns (uint256) {
        uint256 balance = balanceOf(account);
        if (block.timestamp > expireTimeStamp) {
            // `lock` expires
            return balance;
        }
        // validate locked balance
        uint256 locked = lockedAmount[account];
        if (locked == 0) {
            // no tokens locked
            return balance;
        }
        if (locked > balance) {
            return 0;
        }
        return (balance - locked);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        uint256 freeBalance = freeBalanceOf(from);
        if (amount > freeBalance) {
            require(msg.sender == owner(), "only owner can transfer locked tokens");
        }
    }
}