// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./ERC20Base.sol";

abstract contract RewardToken is Ownable, ERC20Base {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 private constant MAX = ~uint256(0);

    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;

    EnumerableSet.AddressSet private _excluded;

    event ExcludedFromRewards(address indexed account, bool excluded);
    event TransferRewards(address indexed from, uint256 amount);

    constructor(uint256 supply_) {
        _tTotal = supply_;
        _rTotal = (MAX - (MAX % _tTotal));
        _rOwned[_msgSender()] = _rTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function totalRewardFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_excluded.contains(account)) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function isExcludedFromRewards(address account) public view returns (bool) {
        return _excluded.contains(account);
    }

    function _setIsExcludedFromRewards(address account, bool excluded) internal {
        require(_excluded.contains(account) != excluded, "Already set");

        if (excluded) {
            if (_rOwned[account] > 0) {
                _tOwned[account] = tokenFromReflection(_rOwned[account]);
            }
            _excluded.add(account);
        } else {
            _tOwned[account] = 0;
            _excluded.remove(account);
        }

        emit ExcludedFromRewards(account, excluded);
    }

    function setIsExcludedFromRewards(address account, bool excluded) external onlyOwner {
        _setIsExcludedFromRewards(account, excluded);
    }

    function tokenFromReflection(uint256 rAmount) private view returns (uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    function _executeTransfer(address from, address to, uint256 amount) internal virtual override {
        _executeTokenTransfer(from, to, amount, amount / 100);
    }

    function _executeTokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        uint256 rewards
    ) internal {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(
            amount,
            rewards
        );
        require(_rOwned[sender] >= rAmount, "ERC20: transfer amount exceeds balance");

        _rOwned[sender] -= rAmount;
        _rOwned[recipient] += rTransferAmount;
        if (_excluded.contains(sender)) {
            require(_tOwned[sender] >= amount, "ERC20: transfer amount exceeds balance");
            _tOwned[sender] -= amount;
        }
        if (_excluded.contains(recipient)) _tOwned[recipient] += tTransferAmount;

        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
        if (rewards > 0) {
            emit TransferRewards(sender, rewards);
        }
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal -= rFee;
        _tFeeTotal += tFee;
    }

    function _getValues(
        uint256 tAmount,
        uint256 tFee
    ) private view returns (uint256, uint256, uint256, uint256, uint256) {
        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        uint256 rTransferAmount = rAmount - rFee;
        return (rAmount, rTransferAmount, rFee, tAmount - tFee, tFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length(); i++) {
            address addr = _excluded.at(i);
            if (_rOwned[addr] > rSupply || _tOwned[addr] > tSupply) return (_rTotal, _tTotal);
            rSupply -= _rOwned[addr];
            tSupply -= _tOwned[addr];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
}