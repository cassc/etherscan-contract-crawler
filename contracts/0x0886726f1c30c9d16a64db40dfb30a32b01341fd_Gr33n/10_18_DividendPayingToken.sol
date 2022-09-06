// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./SignedSafeMath.sol";
import "./SafeCast.sol";
import "./DividendPayingTokenInterface.sol";
import "./DividendPayingTokenOptionalInterface.sol";

abstract contract DividendPayingToken is
    ERC20,
    DividendPayingTokenInterface,
    DividendPayingTokenOptionalInterface
{
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using SafeCast for uint256;
    using SafeCast for int256;
    uint256 internal constant magnitude = 2**128;

    uint256 internal magnifiedDividendPerShare;

    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;

    uint256 public pendingDividendsToDistribute;
    uint256 public totalDividendsDistributed;

    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {}

    receive() external payable {
        pendingDividendsToDistribute = pendingDividendsToDistribute.add(msg.value);
    }

    function distributeDividends() public payable {
        require(totalSupply() > 0);

        require(pendingDividendsToDistribute > 0, "There are no dividends currently available to distribute.");

        if (pendingDividendsToDistribute > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare.add(
                (pendingDividendsToDistribute).mul(magnitude) / totalSupply()
            );
            emit DividendsDistributed(msg.sender, pendingDividendsToDistribute);

            totalDividendsDistributed = totalDividendsDistributed.add(pendingDividendsToDistribute);
            pendingDividendsToDistribute = pendingDividendsToDistribute.sub(pendingDividendsToDistribute);
        }
    }

    function withdrawDividend() public virtual override {
        _withdrawDividendOfUser(payable(msg.sender), payable(msg.sender));
    }

    function _withdrawDividendOfUser(address payable user, address payable to)
        internal
        returns (uint256)
    {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user] = withdrawnDividends[user].add(
                _withdrawableDividend
            );
            emit DividendWithdrawn(user, _withdrawableDividend, to);
            (bool success, ) = to.call{value: _withdrawableDividend}("");

            if (!success) {
                withdrawnDividends[user] = withdrawnDividends[user].sub(
                    _withdrawableDividend
                );
                return 0;
            }

            return _withdrawableDividend;
        }

        return 0;
    }

    function dividendOf(address _owner) public view override returns (uint256) {
        return withdrawableDividendOf(_owner);
    }

    function withdrawableDividendOf(address _owner) public view override returns (uint256) {
        return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
    }

    function withdrawnDividendOf(address _owner) public view override returns (uint256) {
        return withdrawnDividends[_owner];
    }

    function accumulativeDividendOf(address _owner) public view override returns (uint256) {
        return
            magnifiedDividendPerShare
                .mul(balanceOf(_owner))
                .toInt256()
                .add(magnifiedDividendCorrections[_owner])
                .toUint256() / magnitude;
    }

    function _mint(address account, uint256 value) internal override {
        super._mint(account, value);

        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[
            account
        ].sub((magnifiedDividendPerShare.mul(value)).toInt256());
    }

    function _burn(address account, uint256 value) internal override {
        super._burn(account, value);
        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[
            account
        ].add((magnifiedDividendPerShare.mul(value)).toInt256());
    }

    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = balanceOf(account);

        if (newBalance > currentBalance) {
            uint256 mintAmount = newBalance.sub(currentBalance);
            _mint(account, mintAmount);

        } else if (newBalance < currentBalance) {
            uint256 burnAmount = currentBalance.sub(newBalance);
            _burn(account, burnAmount);
        }
    }

    function getAccount(address _account) public view returns (uint256 _withdrawableDividends, uint256 _withdrawnDividends) {
        _withdrawableDividends = withdrawableDividendOf(_account);
        _withdrawnDividends = withdrawnDividends[_account];
    }
}