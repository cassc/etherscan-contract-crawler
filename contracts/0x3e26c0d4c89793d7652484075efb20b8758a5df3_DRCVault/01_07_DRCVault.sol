// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.8.4;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IDRCVault.sol";

/**
 * @dev Implementation of DRC Vault.
 */
contract DRCVault is IDRCVault {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    constructor(address _drcAddress) {
        _drcToken = IERC20(_drcAddress);
    }

    string private constant _name = "DRC Vault";
    IERC20 private immutable _drcToken;
    mapping(address => uint256) private _balanceOf;
    EnumerableSet.AddressSet private _holders;
    uint256 private _totalAmountLocked;

    /**
     * @dev See {IDRCVault-name}.
     */
    function name() external pure override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IDRCVault-drcAddress}.
     */
    function drcAddress() external view override returns (address) {
        return address(_drcToken);
    }

    /**
     * @dev See {IDRCVault-totalAmountLocked}.
     */
    function totalAmountLocked() external view override returns (uint256) {
        return _totalAmountLocked;
    }

    /**
     * @dev See {IDRCVault-balanceOf}.
     */
    function balanceOf(address account) external view override returns (uint256) {
        return _balanceOf[account];
    }

    /**
     * @dev See {IDRCVault-holders}.
     */
    function holders() external view override returns (address[] memory) {
        address[] memory accounts = new address[](_holders.length());
        for (uint256 i = 0; i < _holders.length(); i++) {
            accounts[i] = _holders.at(i);
        }
        return accounts;
    }

    /**
     * @dev See {IDRCVault-deposit}.
     */
    function deposit(address account, uint256 amount) external override {
        require(_drcToken.balanceOf(msg.sender) >= amount, "User doesn't own enough DRC to deposit");
        require(
            _drcToken.allowance(msg.sender, address(this)) >= amount,
            "User hasn't approved this contract to spend DRC"
        );

        SafeERC20.safeTransferFrom(_drcToken, msg.sender, address(this), amount);
        _balanceOf[account] = _balanceOf[account].add(amount);
        _holders.add(account);
        _totalAmountLocked = _totalAmountLocked.add(amount);

        emit Deposit(account, amount);
    }

    /**
     * @dev See {IDRCVault-withdraw}.
     */
    function withdraw(uint256 amount) external override {
        require(_balanceOf[msg.sender] >= amount, "User doesn't have enough share to withdraw");

        SafeERC20.safeTransfer(_drcToken, msg.sender, amount);
        _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(amount);
        _totalAmountLocked = _totalAmountLocked.sub(amount);

        if (_balanceOf[msg.sender] == 0) {
            _holders.remove(msg.sender);
        }

        emit Withdraw(msg.sender, amount);
    }
}