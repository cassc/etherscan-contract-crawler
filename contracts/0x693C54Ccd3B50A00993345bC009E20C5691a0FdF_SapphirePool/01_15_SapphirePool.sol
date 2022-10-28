// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import {ISapphirePool} from "./ISapphirePool.sol";
import {SapphirePoolStorage} from "./SapphirePoolStorage.sol";
import {SharedPoolStructs} from "./SharedPoolStructs.sol";

import {SafeERC20} from "../../lib/SafeERC20.sol";
import {ReentrancyGuard} from "../../lib/ReentrancyGuard.sol";
import {Adminable} from "../../lib/Adminable.sol";
import {Address} from "../../lib/Address.sol";
import {Math} from "../../lib/Math.sol";
import {IERC20Metadata} from "../../token/IERC20Metadata.sol";
import {InitializableBaseERC20} from "../../token/InitializableBaseERC20.sol";

/**
 * @notice A pool of stablecoins where the public can deposit assets and borrow them through
 * SapphireCores
 * A portion of the interest made from the loans by the Cores is deposited into this contract, and
 * shared among the lenders.
 */
contract SapphirePool is
    Adminable,
    InitializableBaseERC20,
    ISapphirePool,
    ReentrancyGuard,
    SapphirePoolStorage
{

    /* ========== Libraries ========== */

    using Address for address;

    /* ========== Structs ========== */

    // Used in _getWithdrawAmounts to get around the stack too deep error.
    struct WithdrawAmountInfo {
        uint256 poolValue;
        uint256 totalSupply;
        uint256 withdrawAmount;
        uint256 scaledWithdrawAmount;
        uint256 userDeposit;
        uint256 assetUtilization;
        uint256 scaledAssetUtilization;
    }

    /* ========== Events ========== */

    event CoreBorrowLimitSet(address _core, uint256 _limit);

    event DepositLimitSet(address _asset, uint256 _limit);

    event TokensDeposited(
        address indexed _user,
        address indexed _token,
        uint256 _depositAmount,
        uint256 _lpTokensAmount
    );

    event TokensWithdrawn(
        address indexed _user,
        address indexed _token,
        uint256 _lpAmount,
        uint256 _withdrawAmount
    );

    event TokensBorrowed(
        address indexed _core,
        address indexed _stablecoin,
        uint256 _borrowedAmount,
        address _receiver
    );

    event TokensRepaid(
        address indexed _core,
        address indexed _stablecoin,
        uint256 _repaidAmount,
        uint256 _debtRepaid
    );

    event StablesLentDecreased(
        address indexed _core,
        uint256 _amountDecreased,
        uint256 _newStablesLentAmount
    );

    /* ========== Modifiers ========== */

    modifier checkKnownToken (address _token) {
        require(
            _isKnownToken(_token),
            "SapphirePool: unknown token"
        );
        _;
    }

    modifier onlyCores () {
        require(
            _coreBorrowUtilization[msg.sender].limit > 0,
            "SapphirePool: sender is not a Core"
        );
        _;
    }

    /* ========== Restricted functions ========== */

    function init(
        string memory _name,
        string memory _symbol
    )
        external
        onlyAdmin
        initializer
    {
        _init(_name, _symbol, 18);
    }

    /**
     * @notice Sets the limit for how many stables can be borrowed by the given core.
     * The sum of the core limits cannot be greater than the sum of the deposit limits.
     */
    function setCoreBorrowLimit(
        address _coreAddress,
        uint256 _limit
    )
        external
        override
        onlyAdmin
    {
        (
            uint256 sumOfDepositLimits,
            uint256 sumOfCoreLimits,
            bool isCoreKnown
        ) = _getSumOfLimits(_coreAddress, _coreAddress, address(0));

        require(
            sumOfCoreLimits + _limit <= sumOfDepositLimits,
            "SapphirePool: sum of the deposit limits exceeds sum of borrow limits"
        );

        if (!isCoreKnown) {
            _knownCores.push(_coreAddress);
        }

        _coreBorrowUtilization[_coreAddress].limit = _limit;

        emit CoreBorrowLimitSet(_coreAddress, _limit);
    }

    /**
     * @notice Sets the limit for the deposit token. If the limit is > 0, the token is added to
     * the list of the known deposit assets. These assets also become available for being
     * borrowed by Cores, unless their limit is set to 0 later on.
     * The sum of the deposit limits cannot be smaller than the sum of the core limits.
     *
     * @param _tokenAddress The address of the deposit token.
     * @param _limit The limit for the deposit token, in its own native decimals.
     */
    function setDepositLimit(
        address _tokenAddress,
        uint256 _limit
    )
        external
        override
        onlyAdmin
    {
        bool isKnownToken = _isKnownToken(_tokenAddress);

        require(
            _limit > 0 || isKnownToken,
            "SapphirePool: cannot set the limit of an unknown asset to 0"
        );

        (
            uint256 sumOfDepositLimits,
            uint256 sumOfCoreLimits,
        ) = _getSumOfLimits(address(0), address(0), _tokenAddress);

        // Add the token to the known assets array if limit is > 0
        if (_limit > 0 && !isKnownToken) {
            _knownDepositAssets.push(_tokenAddress);

            // Save token decimals to later compute the token scalar
            _tokenDecimals[_tokenAddress] = IERC20Metadata(_tokenAddress).decimals();
        }

        uint256 scaledNewLimit = _getScaledAmount(
            _limit,
            _tokenDecimals[_tokenAddress],
            _decimals
        );

        // The new sum of deposit limits cannot be zero, otherwise the pool will become
        // unusable (_deposits will be disabled).
        require(
            sumOfDepositLimits + scaledNewLimit > 0,
            "SapphirePool: at least 1 deposit asset must have a positive limit"
        );

        require(
            sumOfDepositLimits + scaledNewLimit >= sumOfCoreLimits,
            "SapphirePool: sum of borrow limits exceeds sum of deposit limits"
        );

        _assetDepositUtilization[_tokenAddress].limit = _limit;

        emit DepositLimitSet(_tokenAddress, _limit);
    }

    /**
     * @notice Borrows the specified tokens from the pool. Available only to approved cores.
     */
    function borrow(
        address _stablecoinAddress,
        uint256 _scaledBorrowAmount,
        address _receiver
    )
        external
        override
        onlyCores
        nonReentrant
    {
        uint256 amountOut = _borrow(
            _stablecoinAddress,
            _scaledBorrowAmount,
            _receiver
        );

        emit TokensBorrowed(
            msg.sender,
            _stablecoinAddress,
            amountOut,
            _receiver
        );
    }

    /**
     * @notice Repays the specified stablecoins to the pool. Available only to approved cores.
     * This function should only be called to repay principal, without interest.
     */
    function repay(
        address _stablecoinAddress,
        uint256 _repayAmount
    )
        external
        override
        onlyCores
        nonReentrant
    {
        uint256 debtDecreaseAmt = _repay(
            _stablecoinAddress,
            _repayAmount
        );

        emit TokensRepaid(
            msg.sender,
            _stablecoinAddress,
            _repayAmount,
            debtDecreaseAmt
        );
    }

    /**
     * @notice Decreases the stables lent by the given amount. Only available to approved cores.
     * This is used to make the lenders pay for the bad debt following a liquidation
     */
    function decreaseStablesLent(
        uint256 _debtDecreaseAmount
    )
        external
        override
        onlyCores
    {
        stablesLent -= _debtDecreaseAmount;

        emit StablesLentDecreased(
            msg.sender,
            _debtDecreaseAmount,
            stablesLent
        );
    }

    /**
     * @notice Removes the given core from the list of the known cores. Can only be called by
     * the admin. This function does not affect any limits. Use setCoreBorrowLimit for that instead.
     */
    function removeActiveCore(
        address _coreAddress
    )
        external
        onlyAdmin
    {
        for (uint8 i = 0; i < _knownCores.length; i++) {
            if (_knownCores[i] == _coreAddress) {
                _knownCores[i] = _knownCores[_knownCores.length - 1];
                _knownCores.pop();
            }
        }
    }


    /* ========== Public functions ========== */

    /**
     * @notice Deposits the given amount of tokens into the pool.
     * The token must have a deposit limit > 0.
     */
    function deposit(
        address _token,
        uint256 _amount
    )
        external
        override
        nonReentrant
    {
        SharedPoolStructs.AssetUtilization storage utilization = _assetDepositUtilization[_token];

        require(
            utilization.amountUsed + _amount <= utilization.limit,
            "SapphirePool: cannot deposit more than the limit"
        );

        uint256 scaledAmount = _getScaledAmount(
            _amount,
            _tokenDecimals[_token],
            _decimals
        );
        uint256 poolValue = getPoolValue();

        uint256 lpToMint;
        if (poolValue > 0) {
            lpToMint = Math.roundUpDiv(
                scaledAmount * totalSupply() / 10 ** _decimals,
                poolValue
            );
        } else {
            lpToMint = scaledAmount;
        }

        utilization.amountUsed += _amount;
        _deposits[msg.sender] += scaledAmount;

        _mint(msg.sender, lpToMint);

        SafeERC20.safeTransferFrom(
            IERC20Metadata(_token),
            msg.sender,
            address(this),
            _amount
        );

        emit TokensDeposited(
            msg.sender,
            _token,
            _amount,
            lpToMint
        );
    }

    /**
     * @notice Exchanges the given amount of LP tokens for the equivalent amount of the given token,
     * plus the proportional rewards. The tokens exchanged are burned.
     * @param _lpAmount The amount of LP tokens to exchange.
     * @param _withdrawToken The token to exchange for.
     */
    function withdraw(
        uint256 _lpAmount,
        address _withdrawToken
    )
        external
        override
        checkKnownToken(_withdrawToken)
        nonReentrant
    {
        (
            uint256 assetUtilizationReduceAmt,
            uint256 userDepositReduceAmt,
            uint256 withdrawAmount
        ) = _getWithdrawAmounts(_lpAmount, _withdrawToken);

        _assetDepositUtilization[_withdrawToken].amountUsed -= assetUtilizationReduceAmt;
        _deposits[msg.sender] -= userDepositReduceAmt;

        _burn(msg.sender, _lpAmount);

        SafeERC20.safeTransfer(
            IERC20Metadata(_withdrawToken),
            msg.sender,
            withdrawAmount
        );

        emit TokensWithdrawn(
            msg.sender,
            _withdrawToken,
            _lpAmount,
            withdrawAmount
        );
    }

    /* ========== View functions ========== */

    /**
     * @notice Returns the rewards accumulated into the pool
     */
    function accumulatedRewardAmount()
        external
        override
        view
        returns (uint256)
    {
        uint256 poolValue = getPoolValue();

        uint256 depositValue;

        for (uint8 i = 0; i < _knownDepositAssets.length; i++) {
            address token = _knownDepositAssets[i];
            depositValue += _getScaledAmount(
                _assetDepositUtilization[token].amountUsed,
                _tokenDecimals[token],
                18
            );
        }

        return poolValue - depositValue;
    }

    /**
     * @notice Returns the list of the available deposit and borrow assets.
     * If an asset has a limit of 0, it will be excluded from the list.
     */
    function getDepositAssets()
        external
        view
        override
        returns (address[] memory)
    {
        uint8 validAssetCount = 0;

        for (uint8 i = 0; i < _knownDepositAssets.length; i++) {
            address token = _knownDepositAssets[i];

            if (_assetDepositUtilization[token].limit > 0) {
                validAssetCount++;
            }
        }

        address[] memory result = new address[](validAssetCount);

        uint8 currentIndex = 0;
        for (uint8 i = 0; i < _knownDepositAssets.length; i++) {
            address token = _knownDepositAssets[i];

            if (_assetDepositUtilization[token].limit > 0) {
                result[currentIndex] = token;
                currentIndex++;
            }
        }

        return result;
    }

    /**
     * @notice Returns the value of the pool in terms of the deposited stablecoins and stables lent
     */
    function getPoolValue()
        public
        view
        override
        returns (uint256)
    {
        uint256 result;

        for (uint8 i = 0; i < _knownDepositAssets.length; i++) {
            address token = _knownDepositAssets[i];
            uint8 decimals = _tokenDecimals[token];

            result += _getScaledAmount(
                IERC20Metadata(token).balanceOf(address(this)),
                decimals,
                18
            );
        }

        result += stablesLent;

        return result;
    }

    /**
     * @notice Determines the amount of stables the cores can borrow. The amounts are stored in
     * 18 decimals.
     */
    function coreBorrowUtilization(
        address _coreAddress
    )
        external
        view
        override
        returns (SharedPoolStructs.AssetUtilization memory)
    {
        return _coreBorrowUtilization[_coreAddress];
    }

    /**
     * @notice Determines the amount of tokens that can be deposited by
     * liquidity providers. The amounts are stored in the asset's native decimals.
     */
    function assetDepositUtilization(
        address _tokenAddress
    )
        external
        view
        override
        returns (SharedPoolStructs.AssetUtilization memory)
    {
        return _assetDepositUtilization[_tokenAddress];
    }

    function deposits(
        address _userAddress
    )
        external
        view
        override
        returns (uint256)
    {
        return _deposits[_userAddress];
    }

    /**
     * @notice Returns an array of core addresses that have a positive borrow limit
     */
    function getActiveCores()
        external
        view
        override
        returns (address[] memory _activeCores)
    {
        uint8 validCoresCount;
        
        for (uint8 i = 0; i < _knownCores.length; i++) {
            address coreAddress = _knownCores[i];

            if (_coreBorrowUtilization[coreAddress].limit > 0) {
                validCoresCount++;
            }
        }

        _activeCores = new address[](validCoresCount);
        uint8 currentIndex;

        for (uint8 i = 0; i < _knownCores.length; i++) {
            address coreAddress = _knownCores[i];

            if (_coreBorrowUtilization[coreAddress].limit > 0) {
                _activeCores[currentIndex] = coreAddress;
                currentIndex++;
            }
        }

        return _activeCores;
    }

    /* ========== Private functions ========== */

    /**
     * @dev Used to compute the amount of LP tokens to mint
     */
    function _getScaledAmount(
        uint256 _amount,
        uint8 _decimalsIn,
        uint8 _decimalsOut
    )
        internal
        pure
        returns (uint256)
    {
        if (_decimalsIn == _decimalsOut) {
            return _amount;
        }

        if (_decimalsIn > _decimalsOut) {
            return _amount / 10 ** (_decimalsIn - _decimalsOut);
        } else {
            return _amount * 10 ** (_decimalsOut - _decimalsIn);
        }
    }

    function _borrow(
        address _borrowTokenAddress,
        uint256 _scaledBorrowAmount,
        address _receiver
    )
        private
        checkKnownToken(_borrowTokenAddress)
        returns (uint256)
    {
        SharedPoolStructs.AssetUtilization storage utilization = _coreBorrowUtilization[msg.sender];

        require(
            utilization.amountUsed + _scaledBorrowAmount <= utilization.limit,
            "SapphirePool: core borrow limit exceeded"
        );

        uint256 expectedOutAmount = _getScaledAmount(
            _scaledBorrowAmount,
            _decimals,
            _tokenDecimals[_borrowTokenAddress]
        );

        // Increase core utilization
        utilization.amountUsed += _scaledBorrowAmount;
        stablesLent += _scaledBorrowAmount;

        SafeERC20.safeTransfer(
            IERC20Metadata(_borrowTokenAddress),
            _receiver,
            expectedOutAmount
        );

        return expectedOutAmount;
    }

    function _repay(
        address _repayTokenAddress,
        uint256 _repayAmount
    )
        private
        checkKnownToken(_repayTokenAddress)
        returns (uint256)
    {
        require(
            _assetDepositUtilization[_repayTokenAddress].limit > 0,
            "SapphirePool: cannot repay with the given token"
        );

        uint8 stableDecimals = _tokenDecimals[_repayTokenAddress];
        uint256 debtDecreaseAmt = _getScaledAmount(
            _repayAmount,
            stableDecimals,
            _decimals
        );
        SharedPoolStructs.AssetUtilization storage utilization = _coreBorrowUtilization[msg.sender];

        utilization.amountUsed -= debtDecreaseAmt;
        stablesLent -= debtDecreaseAmt;

        SafeERC20.safeTransferFrom(
            IERC20Metadata(_repayTokenAddress),
            msg.sender,
            address(this),
            _repayAmount
        );

        return debtDecreaseAmt;
    }

    /**
     * @dev Returns the sum of the deposit limits and the sum of the core borrow limits
     * @param _optionalCoreCheck An optional parameter to check if the core has a borrow limit > 0
     * @param _excludeCore An optional parameter to exclude the core from the sum
     * @param _excludeDepositToken An optional parameter to exclude the deposit token from the sum
     */
    function _getSumOfLimits(
        address _optionalCoreCheck,
        address _excludeCore,
        address _excludeDepositToken
    )
        private
        view
        returns (uint256, uint256, bool)
    {
        uint256 sumOfDepositLimits;
        uint256 sumOfCoreLimits;
        bool isCoreKnown;

        for (uint8 i = 0; i < _knownDepositAssets.length; i++) {
            address token = _knownDepositAssets[i];
            if (token == _excludeDepositToken) {
                continue;
            }

            sumOfDepositLimits += _getScaledAmount(
                _assetDepositUtilization[token].limit,
                _tokenDecimals[token],
                18
            );
        }

        for (uint8 i = 0; i < _knownCores.length; i++) {
            address core = _knownCores[i];

            if (core == _optionalCoreCheck) {
                isCoreKnown = true;
            }

            if (core == _excludeCore) {
                continue;
            }

            sumOfCoreLimits += _coreBorrowUtilization[core].limit;
        }

        return (
            sumOfDepositLimits,
            sumOfCoreLimits,
            isCoreKnown
        );
    }

    /**
     * @dev Returns the amount to be reduced from the user's deposit mapping, token deposit
     * usage and the amount of tokens to be withdrawn, in the withdraw token decimals.
     */
    function _getWithdrawAmounts(
        uint256 _lpAmount,
        address _withdrawToken
    )
        private
        view
        returns (uint256, uint256, uint256)
    {
        WithdrawAmountInfo memory info = _getWithdrawAmountsVars(_lpAmount, _withdrawToken);

        if (info.userDeposit > 0) {
            // User didn't withdraw their initial deposit yet
            if (info.userDeposit > info.scaledWithdrawAmount) {
                // Reduce the user's deposit amount and the asset utilization
                // by the amount withdrawn

                // In the scenario where a new token was added and the previous one removed,
                // it is possible for the asset utilization to be smaller than the withdraw amount.
                // In that case, reduce reduce the asset utilization to 0.
                return (
                    info.assetUtilization < info.withdrawAmount
                        ? info.assetUtilization
                        : info.withdrawAmount,
                    info.scaledWithdrawAmount,
                    info.withdrawAmount
                );
            }

            // The withdraw amount is bigger than the user's initial deposit. This happens when the
            // rewards claimable by the user are greater than the amount of tokens they have
            // deposited.
            if (info.scaledAssetUtilization > info.userDeposit) {
                // There's more asset utilization than the user's initial deposit. Reduce it by
                // the amount of the user's initial deposit.
                return (
                    _getScaledAmount(
                        info.userDeposit,
                        _decimals,
                        _tokenDecimals[_withdrawToken]
                    ),
                    info.userDeposit,
                    info.withdrawAmount
                );
            }

            // The asset utilization is smaller or equal to the user's initial deposit.
            // Set both to 0. This can happen when the user deposited in one token, and withdraws
            // in another.
            return (
                info.assetUtilization,
                info.userDeposit,
                info.withdrawAmount
            );
        }

        // User deposit is 0, meaning they have withdrawn their initial deposit, and now they're
        // withdrawing pure profit.
        return (
            0,
            0,
            info.withdrawAmount
        );
    }

    function _getWithdrawAmountsVars(
        uint256 _lpAmount,
        address _withdrawToken
    )
        private
        view
        returns (WithdrawAmountInfo memory)
    {
        WithdrawAmountInfo memory info;

        info.poolValue = getPoolValue();
        info.totalSupply = totalSupply();

        info.scaledWithdrawAmount = _lpAmount * info.poolValue / info.totalSupply;
        info.withdrawAmount = _getScaledAmount(
            info.scaledWithdrawAmount,
            _decimals,
            _tokenDecimals[_withdrawToken]
        );

        info.userDeposit = _deposits[msg.sender];
        info.assetUtilization = _assetDepositUtilization[_withdrawToken].amountUsed;
        info.scaledAssetUtilization = _getScaledAmount(
            info.assetUtilization,
            _tokenDecimals[_withdrawToken],
            _decimals
        );

        return info;
    }

    /**
     * @dev Returns true if the token was historically added as a deposit token
     */
    function _isKnownToken(
        address _token
    )
        private
        view
        returns (bool)
    {
        return _tokenDecimals[_token] > 0;
    }
}