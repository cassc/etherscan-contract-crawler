// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.0 <0.9.0;

import "../immutable/MixinStorage.sol";
import "../../interfaces/IKyc.sol";

abstract contract MixinActions is MixinStorage {
    /*
     * MODIFIERS
     */
    /// @notice Functions with this modifer cannot be reentered. The mutex will be locked before function execution and unlocked after.
    modifier nonReentrant() {
        // Ensure mutex is unlocked
        Pool storage pool = pool();
        require(pool.unlocked, "REENTRANCY_ILLEGAL");

        // Lock mutex before function call
        pool.unlocked = false;

        // Perform function call
        _;

        // Unlock mutex after function call
        pool.unlocked = true;
    }

    /*
     * EXTERNAL METHODS
     */
    /// @inheritdoc IRigoblockV3PoolActions
    function mint(
        address recipient,
        uint256 amountIn,
        uint256 amountOutMin
    ) public payable override nonReentrant returns (uint256 recipientAmount) {
        address kycProvider = poolParams().kycProvider;

        // require whitelisted user if kyc is enforced
        if (kycProvider != address(0)) {
            require(IKyc(kycProvider).isWhitelistedUser(recipient), "POOL_CALLER_NOT_WHITELISTED_ERROR");
        }

        _assertBiggerThanMinimum(amountIn);

        if (pool().baseToken == address(0)) {
            require(msg.value == amountIn, "POOL_MINT_AMOUNTIN_ERROR,");
        } else {
            _safeTransferFrom(msg.sender, address(this), amountIn);
        }

        uint256 markup = (amountIn * _getSpread()) / _SPREAD_BASE;
        amountIn -= markup;
        uint256 mintedAmount = (amountIn * 10**decimals()) / _getUnitaryValue();
        require(mintedAmount > amountOutMin, "POOL_MINT_OUTPUT_AMOUNT_ERROR");
        poolTokens().totalSupply += mintedAmount;

        /// @notice allocate pool token transfers and log events.
        recipientAmount = _allocateMintTokens(recipient, mintedAmount);
    }

    /// @inheritdoc IRigoblockV3PoolActions
    function burn(uint256 amountIn, uint256 amountOutMin) external override nonReentrant returns (uint256 netRevenue) {
        require(amountIn > 0, "POOL_BURN_NULL_AMOUNT_ERROR");
        UserAccount memory userAccount = accounts().userAccounts[msg.sender];
        require(userAccount.userBalance >= amountIn, "POOL_BURN_NOT_ENOUGH_ERROR");
        require(block.timestamp >= userAccount.activation, "POOL_MINIMUM_PERIOD_NOT_ENOUGH_ERROR");

        /// @notice allocate pool token transfers and log events.
        uint256 burntAmount = _allocateBurnTokens(amountIn);
        poolTokens().totalSupply -= burntAmount;

        uint256 markup = (burntAmount * _getSpread()) / _SPREAD_BASE;
        burntAmount -= markup;
        netRevenue = (burntAmount * _getUnitaryValue()) / 10**decimals();
        require(netRevenue >= amountOutMin, "POOL_BURN_OUTPUT_AMOUNT_ERROR");

        if (pool().baseToken == address(0)) {
            payable(msg.sender).transfer(netRevenue);
        } else {
            _safeTransfer(msg.sender, netRevenue);
        }
    }

    /*
     * PUBLIC METHODS
     */
    function decimals() public view virtual override returns (uint8);

    /*
     * INTERNAL METHODS
     */
    function _getFeeCollector() internal view virtual returns (address);

    function _getMinPeriod() internal view virtual returns (uint48);

    function _getSpread() internal view virtual returns (uint16);

    function _getUnitaryValue() internal view virtual returns (uint256);

    /*
     * PRIVATE METHODS
     */
    /// @notice Allocates tokens to recipient. Fee tokens are locked too.
    /// @dev Each new mint on same recipient sets new activation on all owned tokens.
    /// @param recipient Address of the recipient.
    /// @param mintedAmount Value of issued tokens.
    /// @return recipientAmount Number of new tokens issued to recipient.
    function _allocateMintTokens(address recipient, uint256 mintedAmount) private returns (uint256 recipientAmount) {
        recipientAmount = mintedAmount;
        Accounts storage accounts = accounts();
        uint208 recipientBalance = accounts.userAccounts[recipient].userBalance;
        uint48 activation;
        // it is safe to use unckecked as max min period is 30 days
        unchecked {
            activation = uint48(block.timestamp) + _getMinPeriod();
        }
        uint16 transactionFee = poolParams().transactionFee;

        if (transactionFee != 0) {
            address feeCollector = _getFeeCollector();

            if (feeCollector == recipient) {
                // it is safe to use unckecked as recipientAmount requires user holding enough base tokens.
                unchecked {
                    recipientBalance += uint208(recipientAmount);
                }
            } else {
                uint208 feeCollectorBalance = accounts.userAccounts[feeCollector].userBalance;
                uint256 feePool = (mintedAmount * transactionFee) / _FEE_BASE;
                recipientAmount -= feePool;
                unchecked {
                    feeCollectorBalance += uint208(feePool);
                    recipientBalance += uint208(recipientAmount);
                }
                //fee tokens are locked as well
                accounts.userAccounts[feeCollector] = UserAccount({
                    userBalance: feeCollectorBalance,
                    activation: activation
                });
                emit Transfer(address(0), feeCollector, feePool);
            }
        } else {
            unchecked {
                recipientBalance += uint208(recipientAmount);
            }
        }

        accounts.userAccounts[recipient] = UserAccount({userBalance: recipientBalance, activation: activation});
        emit Transfer(address(0), recipient, recipientAmount);
    }

    /// @notice Destroys tokens of holder.
    /// @dev Fee is paid in pool tokens.
    /// @param amountIn Value of tokens to be burnt.
    /// @return burntAmount Number of net burnt tokens.
    function _allocateBurnTokens(uint256 amountIn) private returns (uint256 burntAmount) {
        burntAmount = amountIn;
        Accounts storage accounts = accounts();
        uint208 holderBalance = accounts.userAccounts[msg.sender].userBalance;

        if (poolParams().transactionFee != uint256(0)) {
            address feeCollector = _getFeeCollector();

            if (msg.sender == feeCollector) {
                holderBalance -= uint208(burntAmount);
            } else {
                uint256 feePool = (amountIn * poolParams().transactionFee) / _FEE_BASE;
                burntAmount -= feePool;
                holderBalance -= uint208(burntAmount);

                // allocate fee tokens to fee collector
                uint208 feeCollectorBalance = accounts.userAccounts[feeCollector].userBalance;
                uint48 activation;
                unchecked {
                    feeCollectorBalance += uint208(feePool);
                    activation = uint48(block.timestamp + 1);
                }
                accounts.userAccounts[feeCollector] = UserAccount({
                    userBalance: feeCollectorBalance,
                    activation: uint48(block.timestamp + 1)
                });
                emit Transfer(msg.sender, feeCollector, feePool);
            }
        } else {
            holderBalance -= uint208(burntAmount);
        }

        // clear storage is user account has sold all held tokens
        if (holderBalance == 0) {
            delete accounts.userAccounts[msg.sender];
        } else {
            accounts.userAccounts[msg.sender].userBalance = holderBalance;
        }

        emit Transfer(msg.sender, address(0), burntAmount);
    }

    function _assertBiggerThanMinimum(uint256 amount) private view {
        require(amount >= 10**decimals() / _MINIMUM_ORDER_DIVISOR, "POOL_AMOUNT_SMALLER_THAN_MINIMUM_ERROR");
    }

    function _safeTransfer(address to, uint256 amount) private {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = pool().baseToken.call(
            abi.encodeWithSelector(_TRANSFER_SELECTOR, to, amount)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "POOL_TRANSFER_FAILED_ERROR");
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 amount
    ) private {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = pool().baseToken.call(
            abi.encodeWithSelector(_TRANSFER_FROM_SELECTOR, from, to, amount)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "POOL_TRANSFER_FROM_FAILED_ERROR");
    }
}