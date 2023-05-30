// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./DividendPayingTokenInterface.sol";
import "./DividendPayingTokenOptionalInterface.sol";
import "./math/SafeMathUint.sol";
import "./math/SafeMathInt.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @title Dividend-Paying Token
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev A mintable ERC20 token that allows anyone to pay and distribute tokens
///  to token holders as dividends and allows token holders to withdraw their dividends.
///  Reference: the source code of PoWH3D: https://etherscan.io/address/0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe#code
abstract contract DividendPayingToken is ERC20, Ownable, DividendPayingTokenInterface, DividendPayingTokenOptionalInterface {
    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    address public REWARD_TOKEN1;
    address public REWARD_TOKEN2;

    // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
    // For more discussion about choosing the value of `magnitude`,
    //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
    uint256 internal constant magnitude = 2 ** 128;

    uint256 internal magnifiedDividend1PerShare;
    uint256 internal magnifiedDividend2PerShare;

    // About dividendCorrection:
    // If the token balance of a `_user` is never changed, the dividend of `_user` can be computed with:
    //   `dividendOf(_user) = dividendPerShare * balanceOf(_user)`.
    // When `balanceOf(_user)` is changed (via minting/burning/transferring tokens),
    //   `dividendOf(_user)` should not be changed,
    //   but the computed value of `dividendPerShare * balanceOf(_user)` is changed.
    // To keep the `dividendOf(_user)` unchanged, we add a correction term:
    //   `dividendOf(_user) = dividendPerShare * balanceOf(_user) + dividendCorrectionOf(_user)`,
    //   where `dividendCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
    //   `dividendCorrectionOf(_user) = dividendPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
    // So now `dividendOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
    mapping(address => int256) internal magnifiedDividend1Corrections;
    mapping(address => uint256) internal withdrawnDividends1;
    mapping(address => int256) internal magnifiedDividend2Corrections;
    mapping(address => uint256) internal withdrawnDividends2;

    uint256 public totalDividends1Distributed;
    uint256 public totalDividends2Distributed;

    constructor(
        string memory _name,
        string memory _symbol,
        address _rewardToken1Address,
        address _rewardToken2Address
    ) ERC20(_name, _symbol) {
        REWARD_TOKEN1 = _rewardToken1Address;
        REWARD_TOKEN2 = _rewardToken2Address;
    }

    function afterReceivedUSDC(uint256 amount) public onlyOwner {
        if (totalSupply() > 0 && amount > 0) {
            magnifiedDividend1PerShare = magnifiedDividend1PerShare.add(
                (amount).mul(magnitude) / totalSupply()
            );
            emit Dividends1Distributed(msg.sender, amount);

            totalDividends1Distributed = totalDividends1Distributed.add(amount);
        }
    }

    // This doesn't check we were actually given these tokens
    function afterReceivedExotix(uint256 amount) public onlyOwner {
        if (totalSupply() > 0 && amount > 0) {
            magnifiedDividend2PerShare = magnifiedDividend2PerShare.add(
                (amount).mul(magnitude) / totalSupply()
            );
            emit Dividends2Distributed(msg.sender, amount);

            totalDividends2Distributed = totalDividends2Distributed.add(amount);
        }
    }
    

    /// @notice Withdraws the ether distributed to the sender.
    /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
    function withdrawDividend1() public virtual override {
        _withdrawDividend1OfUser(payable(msg.sender));
    }

    /// @notice Withdraws the ether distributed to the sender.
    /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
    function withdrawDividend2() public virtual override {
        _withdrawDividend2OfUser(payable(msg.sender));
    }

    /// @notice Withdraws the ether distributed to the sender.
    /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
    function _withdrawDividend1OfUser(
        address payable user
    ) internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividend1Of(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends1[user] = withdrawnDividends1[user].add(
                _withdrawableDividend
            );
            emit Dividend1Withdrawn(user, _withdrawableDividend);
            bool success = IERC20(REWARD_TOKEN1).transfer(
                user,
                _withdrawableDividend
            );

            if (!success) {
                withdrawnDividends1[user] = withdrawnDividends1[user].sub(
                    _withdrawableDividend
                );
                return 0;
            }

            return _withdrawableDividend;
        }

        return 0;
    }

    /// @notice Withdraws the ether distributed to the sender.
    /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
    function _withdrawDividend2OfUser(address payable user) internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividend2Of(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends2[user] = withdrawnDividends2[user].add(
                _withdrawableDividend
            );
            emit Dividend1Withdrawn(user, _withdrawableDividend);
            bool success = IERC20(REWARD_TOKEN2).transfer(
                user,
                _withdrawableDividend
            );

            if (!success) {
                withdrawnDividends2[user] = withdrawnDividends2[user].sub(
                    _withdrawableDividend
                );
                return 0;
            }

            return _withdrawableDividend;
        }

        return 0;
    }

    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function dividend1Of(address _owner) public view override returns (uint256) {
        return withdrawableDividend1Of(_owner);
    }

    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function dividend2Of(address _owner) public view override returns (uint256) {
        return withdrawableDividend2Of(_owner);
    }

    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function withdrawableDividend1Of(
        address _owner
    ) public view override returns (uint256) {
        return accumulativeDividend1Of(_owner).sub(withdrawnDividends1[_owner]);
    }

     /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function withdrawableDividend2Of(
        address _owner
    ) public view override returns (uint256) {
        return accumulativeDividend2Of(_owner).sub(withdrawnDividends1[_owner]);
    }

    /// @notice View the amount of dividend in wei that an address has withdrawn.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has withdrawn.
    function withdrawnDividend1Of(
        address _owner
    ) public view override returns (uint256) {
        return withdrawnDividends1[_owner];
    }

    /// @notice View the amount of dividend in wei that an address has withdrawn.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has withdrawn.
    function withdrawnDividend2Of(
        address _owner
    ) public view override returns (uint256) {
        return withdrawnDividends2[_owner];
    }

    /// @notice View the amount of dividend in wei that an address has earned in total.
    /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
    /// = (magnifiedDividend1PerShare * balanceOf(_owner) + magnifiedDividend1Corrections[_owner]) / magnitude
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has earned in total.
    function accumulativeDividend1Of(address _owner) public view override returns (uint256) {
        return
            magnifiedDividend1PerShare
                .mul(balanceOf(_owner))
                .toInt256Safe()
                .add(magnifiedDividend1Corrections[_owner])
                .toUint256Safe() / magnitude;
    }

    /// @notice View the amount of dividend in wei that an address has earned in total.
    /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
    /// = (magnifiedDividend1PerShare * balanceOf(_owner) + magnifiedDividend1Corrections[_owner]) / magnitude
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has earned in total.
    function accumulativeDividend2Of(address _owner) public view override returns (uint256) {
        return
            magnifiedDividend2PerShare
                .mul(balanceOf(_owner))
                .toInt256Safe()
                .add(magnifiedDividend2Corrections[_owner])
                .toUint256Safe() / magnitude;
    }

    /// @dev Internal function that transfer tokens from one address to another.
    /// Update magnifiedDividend1Corrections to keep dividends unchanged.
    /// @param from The address to transfer from.
    /// @param to The address to transfer to.
    /// @param value The amount to be transferred.
    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual override {
        require(false);
        // Seems to be disabled?
        int256 _magCorrection1 = magnifiedDividend1PerShare.mul(value).toInt256Safe();
        int256 _magCorrection2 = magnifiedDividend2PerShare.mul(value).toInt256Safe();
        magnifiedDividend1Corrections[from] = magnifiedDividend1Corrections[from].add(_magCorrection1);
        magnifiedDividend1Corrections[to] = magnifiedDividend1Corrections[to].sub(_magCorrection1);
        magnifiedDividend2Corrections[from] = magnifiedDividend2Corrections[from].add(_magCorrection2);
        magnifiedDividend2Corrections[to] = magnifiedDividend2Corrections[to].sub(_magCorrection2);
    }

    /// @dev Internal function that mints tokens to an account.
    /// Update magnifiedDividend1Corrections to keep dividends unchanged.
    /// @param account The account that will receive the created tokens.
    /// @param value The amount that will be created.
    function _mint(address account, uint256 value) internal override {
        super._mint(account, value);
        magnifiedDividend1Corrections[account] = magnifiedDividend1Corrections[account].sub((magnifiedDividend1PerShare.mul(value)).toInt256Safe());
        magnifiedDividend2Corrections[account] = magnifiedDividend2Corrections[account].sub((magnifiedDividend2PerShare.mul(value)).toInt256Safe()); 
    }

    /// @dev Internal function that burns an amount of the token of a given account.
    /// Update magnifiedDividend1Corrections to keep dividends unchanged.
    /// @param account The account whose tokens will be burnt.
    /// @param value The amount that will be burnt.
    function _burn(address account, uint256 value) internal override {
        super._burn(account, value);

        magnifiedDividend1Corrections[account] = magnifiedDividend1Corrections[account].add((magnifiedDividend1PerShare.mul(value)).toInt256Safe());
        magnifiedDividend2Corrections[account] = magnifiedDividend2Corrections[account].add((magnifiedDividend2PerShare.mul(value)).toInt256Safe());
        
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
}