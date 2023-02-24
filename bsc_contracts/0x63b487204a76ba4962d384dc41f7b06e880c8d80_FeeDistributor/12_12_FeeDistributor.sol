// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {SafeERC20, IERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";
import {Pausable} from "openzeppelin/security/Pausable.sol";
import {ReentrancyGuard} from "openzeppelin/security/ReentrancyGuard.sol";
import {EnumerableMap} from "openzeppelin/utils/structs/EnumerableMap.sol";
import {IPool} from "src/interfaces/IPool.sol";

/// @notice withdraw fee from pool then distribute to multiple reserve
contract FeeDistributor is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    IPool public immutable pool;
    address[] public feeTokens;

    EnumerableMap.AddressToUintMap private recipients;
    uint256 public totalWeight;

    constructor(address _pool, address[] memory _feeTokens) Ownable() Pausable() ReentrancyGuard() {
        if (_pool == address(0)) revert InvalidAddress();
        pool = IPool(_pool);
        _setFeeTokens(_feeTokens);
    }

    struct RecipientConfig {
        address recipient;
        uint256 weight;
    }

    function getRecipients() external view returns (uint256, RecipientConfig[] memory) {
        uint256 len = recipients.length();
        RecipientConfig[] memory configs = new RecipientConfig[](len);

        for (uint256 i = 0; i < len; ++i) {
            (address addr, uint256 weight) = recipients.at(i);
            configs[i] = RecipientConfig(addr, weight);
        }

        return (totalWeight, configs);
    }

    function withdrawFee() external whenNotPaused nonReentrant {
        if (recipients.length() == 0 || totalWeight == 0) {
            revert RecipientsEmpty();
        }
        for (uint256 i = 0; i < feeTokens.length; ++i) {
            address token = feeTokens[i];
            uint256 amount = _withdrawFee(token);
            _distribute(token, amount);
        }

        emit FeeWithdrawn();
    }

    // ======= ADMINISTRATIVE FUNCTIONS =======
    function setFeeTokens(address[] calldata _feeTokens) external onlyOwner {
        _setFeeTokens(_feeTokens);
    }

    function setRecipient(address _recipient, uint256 _weight) external onlyOwner {
        if (_recipient == address(0)) {
            revert InvalidAddress();
        }
        (bool exists, uint256 currentWeight) = recipients.tryGet(_recipient);
        recipients.set(_recipient, _weight);
        totalWeight = totalWeight + _weight - currentWeight;
        if (exists) {
            emit RecipientAdded(_recipient, _weight);
        } else {
            emit RecipientUpdated(_recipient, _weight);
        }
    }

    function removeRecipient(address _recipient) external onlyOwner {
        (bool exists, uint256 currentWeight) = recipients.tryGet(_recipient);
        if (!exists) {
            revert RecipientNotExists(_recipient);
        }

        recipients.remove(_recipient);
        totalWeight = totalWeight - currentWeight;
        emit RecipientRemoved(_recipient);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // ======= INTERNAL FUNCTIONS =======
    function _distribute(address _token, uint256 _amount) internal {
        if (_amount == 0) {
            return;
        }

        uint256 len = recipients.length();
        uint256 rest = _amount;
        for (uint256 i = 0; i < len; ++i) {
            (address recipient, uint256 weight) = recipients.at(i);
            uint256 shareAmount;
            if (i == len - 1) {
                shareAmount = rest;
            } else {
                shareAmount = _ratio(_amount, weight, totalWeight);
                rest -= shareAmount;
            }
            _transfer(_token, shareAmount, recipient);
        }
    }

    function _setFeeTokens(address[] memory _feeTokens) internal {
        for (uint256 i = 0; i < _feeTokens.length; ++i) {
            if (_feeTokens[i] == address(0)) {
                revert InvalidAddress();
            }
        }
        feeTokens = _feeTokens;
        emit FeeTokensSet(_feeTokens);
    }

    function _transfer(address _token, uint256 _amount, address _to) internal {
        if (_amount != 0) {
            IERC20(_token).safeTransfer(_to, _amount);
        }
    }

    function _withdrawFee(address _token) internal returns (uint256 withdrawnAmount) {
        (uint256 feeReserve,,,,) = pool.poolTokens(_token);
        if (feeReserve > 0) {
            uint256 balanceBefore = IERC20(_token).balanceOf(address(this));
            pool.withdrawFee(_token, address(this));
            withdrawnAmount = IERC20(_token).balanceOf(address(this)) - balanceBefore;
        }
    }

    function _ratio(uint256 _amount, uint256 _num, uint256 _denom) internal pure returns (uint256) {
        return _amount * _num / _denom;
    }

    // ======= ERROR =======
    error InvalidAddress();
    error InvalidRecipientConfig(address addr, uint256 ratio);
    error RecipientNotExists(address);
    error RecipientsEmpty();

    // ======= EVENTS =======
    event FeeWithdrawn();
    event FeeTokensSet(address[] feeTokens);
    event RecipientAdded(address recipient, uint256 weight);
    event RecipientUpdated(address recipient, uint256 weight);
    event RecipientRemoved(address recipient);
}