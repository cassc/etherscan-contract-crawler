// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

import "./lib/AccountTokenLib.sol";
import "./lib/BitmapLib.sol";
import "./config/Constant.sol";
import "./interfaces/IGlobalConfig.sol";
import "../interfaces/IGemGlobalConfig.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract Accounts is Constant, Initializable {
    using AccountTokenLib for AccountTokenLib.TokenInfo;
    using BitmapLib for uint128;
    using SafeMath for uint256;
    using Math for uint256;

    // globalConfig should initialized per pool
    IGlobalConfig public globalConfig;
    IGemGlobalConfig public gemGlobalConfig;

    mapping(address => Account) public accounts;
    mapping(address => uint256) public finAmount;

    modifier onlyAuthorized() {
        _isAuthorized();
        _;
    }

    struct Account {
        // Note, it's best practice to use functions minusAmount, addAmount, totalAmount
        // to operate tokenInfos instead of changing it directly.
        mapping(address => AccountTokenLib.TokenInfo) tokenInfos;
        uint128 depositBitmap;
        uint128 borrowBitmap;
        uint128 collateralBitmap;
        bool isCollInit;
    }

    event CollateralFlagChanged(address indexed _account, uint8 _index, bool _enabled);

    function _isAuthorized() internal view {
        require(
            msg.sender == address(globalConfig.savingAccount()) || msg.sender == address(globalConfig.bank()),
            "not authorized"
        );
    }

    /**
     * Initialize the Accounts
     * @param _globalConfig the global configuration contract
     */
    function initialize(IGlobalConfig _globalConfig, IGemGlobalConfig _gemGlobalConfig) public initializer {
        globalConfig = _globalConfig;
        gemGlobalConfig = _gemGlobalConfig;
    }

    /**
     * @dev Initialize the Collateral flag Bitmap for given account
     * @notice This function is required for the contract upgrade, as previous users didn't
     *         have this collateral feature. So need to init the collateralBitmap for each user.
     * @param _account User account address
     */
    function initCollateralFlag(address _account) public {
        Account storage account = accounts[_account];

        // For all users by default `isCollInit` will be `false`
        if (account.isCollInit == false) {
            // Two conditions:
            // 1) An account has some position previous to this upgrade
            //    THEN: copy `depositBitmap` to `collateralBitmap`
            // 2) A new account is setup after this upgrade
            //    THEN: `depositBitmap` will be zero for that user, so don't copy

            // all deposited tokens be treated as collateral
            if (account.depositBitmap > 0) account.collateralBitmap = account.depositBitmap;
            account.isCollInit = true;
        }

        // when isCollInit == true, function will just return after if condition check
    }

    /**
     * @dev Enable/Disable collateral for a given token
     * @param _tokenIndex Index of the token
     * @param _enable `true` to enable the collateral, `false` to disable
     */
    function setCollateral(uint8 _tokenIndex, bool _enable) public {
        address accountAddr = msg.sender;
        initCollateralFlag(accountAddr);
        Account storage account = accounts[accountAddr];

        if (_enable) {
            account.collateralBitmap = account.collateralBitmap.setBit(_tokenIndex);
            // when set new collateral, no need to evaluate borrow power
        } else {
            account.collateralBitmap = account.collateralBitmap.unsetBit(_tokenIndex);
            // when unset collateral, evaluate borrow power, only when user borrowed already
            if (account.borrowBitmap > 0) {
                require(getBorrowETH(accountAddr) <= getBorrowPower(accountAddr), "Insufficient collateral");
            }
        }

        emit CollateralFlagChanged(msg.sender, _tokenIndex, _enable);
    }

    function setCollateral(uint8[] calldata _tokenIndexArr, bool[] calldata _enableArr) external {
        require(_tokenIndexArr.length == _enableArr.length, "array length does not match");
        for (uint256 i = 0; i < _tokenIndexArr.length; i++) {
            setCollateral(_tokenIndexArr[i], _enableArr[i]);
        }
    }

    function getCollateralStatus(address _account)
        external
        view
        returns (address[] memory tokens, bool[] memory status)
    {
        Account storage account = accounts[_account];
        ITokenRegistry tokenRegistry = globalConfig.tokenRegistry();
        tokens = tokenRegistry.getTokens();
        uint256 tokensCount = tokens.length;
        status = new bool[](tokensCount);
        uint128 collBitmap = account.collateralBitmap;
        for (uint256 i = 0; i < tokensCount; i++) {
            // Example: 0001 << 1 => 0010 (mask for 2nd position)
            uint128 mask = uint128(1) << uint128(i);
            bool isEnabled = (collBitmap & mask) > 0;
            if (isEnabled) status[i] = true;
        }
    }

    /**
     * Check if the user has deposit for any tokens
     * @param _account address of the user
     * @return true if the user has positive deposit balance
     */
    function isUserHasAnyDeposits(address _account) public view returns (bool) {
        Account storage account = accounts[_account];
        return account.depositBitmap > 0;
    }

    /**
     * Check if the user has deposit for a token
     * @param _account address of the user
     * @param _index index of the token
     * @return true if the user has positive deposit balance for the token
     */
    function isUserHasDeposits(address _account, uint8 _index) public view returns (bool) {
        Account storage account = accounts[_account];
        return account.depositBitmap.isBitSet(_index);
    }

    /**
     * Check if the user has borrowed a token
     * @param _account address of the user
     * @param _index index of the token
     * @return true if the user has borrowed the token
     */
    function isUserHasBorrows(address _account, uint8 _index) public view returns (bool) {
        Account storage account = accounts[_account];
        return account.borrowBitmap.isBitSet(_index);
    }

    /**
     * Check if the user has collateral flag set
     * @param _account address of the user
     * @param _index index of the token
     * @return true if the user has collateral flag set for the given index
     */
    function isUserHasCollateral(address _account, uint8 _index) public view returns (bool) {
        Account storage account = accounts[_account];
        return account.collateralBitmap.isBitSet(_index);
    }

    /**
     * Set the deposit bitmap for a token.
     * @param _account address of the user
     * @param _index index of the token
     */
    function setInDepositBitmap(address _account, uint8 _index) internal {
        Account storage account = accounts[_account];
        account.depositBitmap = account.depositBitmap.setBit(_index);
    }

    /**
     * Unset the deposit bitmap for a token
     * @param _account address of the user
     * @param _index index of the token
     */
    function unsetFromDepositBitmap(address _account, uint8 _index) internal {
        Account storage account = accounts[_account];
        account.depositBitmap = account.depositBitmap.unsetBit(_index);
    }

    /**
     * Set the borrow bitmap for a token.
     * @param _account address of the user
     * @param _index index of the token
     */
    function setInBorrowBitmap(address _account, uint8 _index) internal {
        Account storage account = accounts[_account];
        account.borrowBitmap = account.borrowBitmap.setBit(_index);
    }

    /**
     * Unset the borrow bitmap for a token
     * @param _account address of the user
     * @param _index index of the token
     */
    function unsetFromBorrowBitmap(address _account, uint8 _index) internal {
        Account storage account = accounts[_account];
        account.borrowBitmap = account.borrowBitmap.unsetBit(_index);
    }

    function getDepositPrincipal(address _accountAddr, address _token) public view returns (uint256) {
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        return tokenInfo.getDepositPrincipal();
    }

    function getBorrowPrincipal(address _accountAddr, address _token) public view returns (uint256) {
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        return tokenInfo.getBorrowPrincipal();
    }

    function getLastDepositBlock(address _accountAddr, address _token) public view returns (uint256) {
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        return tokenInfo.getLastDepositBlock();
    }

    function getLastBorrowBlock(address _accountAddr, address _token) public view returns (uint256) {
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        return tokenInfo.getLastBorrowBlock();
    }

    /**
     * Get deposit interest of an account for a specific token
     * @param _account account address
     * @param _token token address
     * @dev The deposit interest may not have been updated in AccountTokenLib, so we need to explicited calcuate it.
     */
    function getDepositInterest(address _account, address _token) public view returns (uint256) {
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_account].tokenInfos[_token];
        // If the account has never deposited the token, return 0.
        uint256 lastDepositBlock = tokenInfo.getLastDepositBlock();
        if (lastDepositBlock == 0) return 0;
        else {
            // As the last deposit block exists, the block is also a check point on index curve.
            uint256 accruedRate = globalConfig.bank().getDepositAccruedRate(_token, lastDepositBlock);
            return tokenInfo.calculateDepositInterest(accruedRate);
        }
    }

    function getBorrowInterest(address _accountAddr, address _token) public view returns (uint256) {
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        // If the account has never borrowed the token, return 0
        uint256 lastBorrowBlock = tokenInfo.getLastBorrowBlock();
        if (lastBorrowBlock == 0) return 0;
        else {
            // As the last borrow block exists, the block is also a check point on index curve.
            uint256 accruedRate = globalConfig.bank().getBorrowAccruedRate(_token, lastBorrowBlock);
            return tokenInfo.calculateBorrowInterest(accruedRate);
        }
    }

    function borrow(
        address _accountAddr,
        address _token,
        uint256 _amount
    ) external onlyAuthorized {
        initCollateralFlag(_accountAddr);
        require(_amount != 0, "borrow amount is 0");
        require(isUserHasAnyDeposits(_accountAddr), "no user deposits");
        (uint8 tokenIndex, uint256 tokenDivisor, uint256 tokenPrice, ) = globalConfig
            .tokenRegistry()
            .getTokenInfoFromAddress(_token);
        require(
            getBorrowETH(_accountAddr).add(_amount.mul(tokenPrice).div(tokenDivisor)) <= getBorrowPower(_accountAddr),
            "Insufficient collateral when borrow"
        );

        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        uint256 blockNumber = getBlockNumber();
        uint256 lastBorrowBlock = tokenInfo.getLastBorrowBlock();

        if (lastBorrowBlock == 0) tokenInfo.borrow(_amount, INT_UNIT, blockNumber);
        else {
            calculateBorrowFIN(lastBorrowBlock, _token, _accountAddr, blockNumber);
            uint256 accruedRate = globalConfig.bank().getBorrowAccruedRate(_token, lastBorrowBlock);
            // Update the token principla and interest
            tokenInfo.borrow(_amount, accruedRate, blockNumber);
        }

        // Since we have checked that borrow amount is larget than zero. We can set the borrow
        // map directly without checking the borrow balance.
        setInBorrowBitmap(_accountAddr, tokenIndex);
    }

    /**
     * Update token info for withdraw. The interest will be withdrawn with higher priority.
     */
    function withdraw(
        address _accountAddr,
        address _token,
        uint256 _amount
    ) public onlyAuthorized returns (uint256) {
        initCollateralFlag(_accountAddr);
        (, uint256 tokenDivisor, uint256 tokenPrice, uint256 borrowLTV) = globalConfig
            .tokenRegistry()
            .getTokenInfoFromAddress(_token);

        // if user borrowed before then only check for under liquidation
        Account storage account = accounts[_accountAddr];
        if (account.borrowBitmap > 0) {
            uint256 withdrawETH = _amount.mul(tokenPrice).mul(borrowLTV).div(tokenDivisor).div(100);
            require(
                getBorrowETH(_accountAddr) <= getBorrowPower(_accountAddr).sub(withdrawETH),
                "Insufficient collateral"
            );
        }

        (uint256 amountAfterCommission, ) = _withdraw(_accountAddr, _token, _amount, true);

        return amountAfterCommission;
    }

    /**
     * This function is called in liquidation function. There two difference between this function and
     * the Account.withdraw function: 1) It doesn't check the user's borrow power, because the user
     * is already borrowed more than it's borrowing power. 2) It doesn't take commissions.
     */
    function _withdrawLiquidate(
        address _accountAddr,
        address _token,
        uint256 _amount
    ) internal {
        _withdraw(_accountAddr, _token, _amount, false);
    }

    function _withdraw(
        address _accountAddr,
        address _token,
        uint256 _amount,
        bool _isCommission
    ) internal returns (uint256, uint256) {
        uint256 calcAmount = _amount;
        // Check if withdraw amount is less than user's balance
        require(calcAmount <= getDepositBalanceCurrent(_token, _accountAddr), "Insufficient balance");

        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        uint256 lastBlock = tokenInfo.getLastDepositBlock();
        uint256 blockNumber = getBlockNumber();
        calculateDepositFIN(lastBlock, _token, _accountAddr, blockNumber);

        uint256 principalBeforeWithdraw = tokenInfo.getDepositPrincipal();

        if (lastBlock == 0) tokenInfo.withdraw(calcAmount, INT_UNIT, blockNumber);
        else {
            // As the last deposit block exists, the block is also a check point on index curve.
            uint256 accruedRate = globalConfig.bank().getDepositAccruedRate(_token, lastBlock);
            tokenInfo.withdraw(calcAmount, accruedRate, blockNumber);
        }

        uint256 principalAfterWithdraw = tokenInfo.getDepositPrincipal();
        if (principalAfterWithdraw == 0) {
            uint8 tokenIndex = globalConfig.tokenRegistry().getTokenIndex(_token);
            unsetFromDepositBitmap(_accountAddr, tokenIndex);
        }

        uint256 commission = 0;
        if (_isCommission && _accountAddr != gemGlobalConfig.deFinerCommunityFund()) {
            // DeFiner takes 10% commission on the interest a user earn
            commission = calcAmount
                .sub(principalBeforeWithdraw.sub(principalAfterWithdraw))
                .mul(globalConfig.deFinerRate())
                .div(100);
            deposit(gemGlobalConfig.deFinerCommunityFund(), _token, commission);
            calcAmount = calcAmount.sub(commission);
        }

        return (calcAmount, commission);
    }

    /**
     * Update token info for deposit
     */
    function deposit(
        address _accountAddr,
        address _token,
        uint256 _amount
    ) public onlyAuthorized {
        initCollateralFlag(_accountAddr);
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        if (tokenInfo.getDepositPrincipal() == 0) {
            uint8 tokenIndex = globalConfig.tokenRegistry().getTokenIndex(_token);
            setInDepositBitmap(_accountAddr, tokenIndex);
        }

        uint256 blockNumber = getBlockNumber();
        uint256 lastDepositBlock = tokenInfo.getLastDepositBlock();
        if (lastDepositBlock == 0) tokenInfo.deposit(_amount, INT_UNIT, blockNumber);
        else {
            calculateDepositFIN(lastDepositBlock, _token, _accountAddr, blockNumber);
            uint256 accruedRate = globalConfig.bank().getDepositAccruedRate(_token, lastDepositBlock);
            tokenInfo.deposit(_amount, accruedRate, blockNumber);
        }
    }

    function repay(
        address _accountAddr,
        address _token,
        uint256 _amount
    ) public onlyAuthorized returns (uint256) {
        initCollateralFlag(_accountAddr);
        // Update tokenInfo
        uint256 amountOwedWithInterest = getBorrowBalanceCurrent(_token, _accountAddr);
        uint256 amount = _amount > amountOwedWithInterest ? amountOwedWithInterest : _amount;
        uint256 remain = _amount > amountOwedWithInterest ? _amount.sub(amountOwedWithInterest) : 0;
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        // Sanity check
        uint256 borrowPrincipal = tokenInfo.getBorrowPrincipal();
        uint256 lastBorrowBlock = tokenInfo.getLastBorrowBlock();
        require(borrowPrincipal > 0, "BorrowPrincipal not gt 0");
        if (lastBorrowBlock == 0) tokenInfo.repay(amount, INT_UNIT, getBlockNumber());
        else {
            calculateBorrowFIN(lastBorrowBlock, _token, _accountAddr, getBlockNumber());
            uint256 accruedRate = globalConfig.bank().getBorrowAccruedRate(_token, lastBorrowBlock);
            tokenInfo.repay(amount, accruedRate, getBlockNumber());
        }

        if (borrowPrincipal == 0) {
            uint8 tokenIndex = globalConfig.tokenRegistry().getTokenIndex(_token);
            unsetFromBorrowBitmap(_accountAddr, tokenIndex);
        }
        return remain;
    }

    function getDepositBalanceCurrent(address _token, address _accountAddr)
        public
        view
        returns (uint256 depositBalance)
    {
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        IBank bank = globalConfig.bank();
        uint256 accruedRate;
        uint256 depositRateIndex = bank.depositeRateIndex(_token, tokenInfo.getLastDepositBlock());
        if (tokenInfo.getDepositPrincipal() == 0) {
            return 0;
        } else {
            if (depositRateIndex == 0) {
                accruedRate = INT_UNIT;
            } else {
                accruedRate = bank.depositeRateIndexNow(_token).mul(INT_UNIT).div(depositRateIndex);
            }
            return tokenInfo.getDepositBalance(accruedRate);
        }
    }

    /**
     * Get current borrow balance of a token
     * @param _token token address
     * @dev This is an estimation. Add a new checkpoint first, if you want to derive the exact balance.
     */
    function getBorrowBalanceCurrent(address _token, address _accountAddr) public view returns (uint256 borrowBalance) {
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        IBank bank = globalConfig.bank();
        uint256 accruedRate;
        uint256 borrowRateIndex = bank.borrowRateIndex(_token, tokenInfo.getLastBorrowBlock());
        if (tokenInfo.getBorrowPrincipal() == 0) {
            return 0;
        } else {
            if (borrowRateIndex == 0) {
                accruedRate = INT_UNIT;
            } else {
                accruedRate = bank.borrowRateIndexNow(_token).mul(INT_UNIT).div(borrowRateIndex);
            }
            return tokenInfo.getBorrowBalance(accruedRate);
        }
    }

    /**
     * Calculate an account's borrow power based on token's LTV
     */
    /*
    function getBorrowPower(address _borrower) public view returns (uint256 power) {
        TokenRegistry tokenRegistry = globalConfig.tokenInfoRegistry();
        uint256 tokenNum = tokenRegistry.getCoinLength();
        for(uint256 i = 0; i < tokenNum; i++) {
            if (isUserHasDeposits(_borrower, uint8(i))) {
                (address token, uint256 divisor, uint256 price, uint256 borrowLTV) =
                    tokenRegistry.getTokenInfoFromIndex(i);

                uint256 depositBalanceCurrent = getDepositBalanceCurrent(token, _borrower);
                power = power.add(depositBalanceCurrent.mul(price).mul(borrowLTV).div(100).div(divisor));
            }
        }
        return power;
    }
    */

    function getBorrowPower(address _borrower) public view returns (uint256 power) {
        Account storage account = accounts[_borrower];

        // if a user have deposits in some tokens and collateral enabled for some
        // then we need to iterate over his deposits for which collateral is also enabled.
        // Hence, we can derive this information by perorming AND bitmap operation
        // hasCollnDepositBitmap = collateralEnabled & hasDeposit
        // Example:
        // collateralBitmap         = 0101
        // depositBitmap            = 0110
        // ================================== OP AND
        // hasCollnDepositBitmap    = 0100 (user can only use his 3rd token as borrow power)
        uint128 hasCollnDepositBitmap = account.collateralBitmap & account.depositBitmap;

        // When no-collateral enabled and no-deposits just return '0' power
        if (hasCollnDepositBitmap == 0) return power;

        ITokenRegistry tokenRegistry = globalConfig.tokenRegistry();

        // This loop has max "O(n)" complexity where "n = TokensLength", but the loop
        // calculates borrow power only for the `hasCollnDepositBitmap` bit, hence the loop
        // iterates only till the highest bit set. Example 00000100, the loop will iterate
        // only for 4 times, and only 1 time to calculate borrow the power.
        // NOTE: When transaction gas-cost goes above the block gas limit, a user can
        //      disable some of his collaterals so that he can perform the borrow.
        //      Earlier loop implementation was iterating over all tokens, hence the platform
        //      were not able to add new tokens
        for (uint256 i = 0; i < 128; i++) {
            // if hasCollnDepositBitmap = 0000 then break the loop
            if (hasCollnDepositBitmap > 0) {
                // hasCollnDepositBitmap = 0100
                // mask                  = 0001
                // =============================== OP AND
                // result                = 0000
                bool isEnabled = (hasCollnDepositBitmap & uint128(1)) > 0;
                // Is i(th) token enabled?
                if (isEnabled) {
                    // continue calculating borrow power for i(th) token
                    (address token, uint256 divisor, uint256 price, uint256 borrowLTV) = tokenRegistry
                        .getTokenInfoFromIndex(i);

                    // avoid some gas consumption when borrowLTV == 0
                    if (borrowLTV != 0) {
                        uint256 depositBalanceCurrent = getDepositBalanceCurrent(token, _borrower);
                        power = power.add(depositBalanceCurrent.mul(price).mul(borrowLTV).div(100).div(divisor));
                    }
                }

                // right shift by 1
                // hasCollnDepositBitmap = 0100
                // BITWISE RIGHTSHIFT 1 on hasCollnDepositBitmap = 0010
                hasCollnDepositBitmap = hasCollnDepositBitmap >> 1;
                // continue loop and repeat the steps until `hasCollnDepositBitmap == 0`
            } else {
                break;
            }
        }

        return power;
    }

    function getCollateralETH(address _account) public view returns (uint256 collETH) {
        ITokenRegistry tokenRegistry = globalConfig.tokenRegistry();
        Account storage account = accounts[_account];
        uint128 hasDeposits = account.depositBitmap;
        for (uint8 i = 0; i < 128; i++) {
            if (hasDeposits > 0) {
                bool isEnabled = (hasDeposits & uint128(1)) > 0;
                if (isEnabled) {
                    (address token, uint256 divisor, uint256 price, uint256 borrowLTV) = tokenRegistry
                        .getTokenInfoFromIndex(i);
                    if (borrowLTV != 0) {
                        uint256 depositBalanceCurrent = getDepositBalanceCurrent(token, _account);
                        collETH = collETH.add(depositBalanceCurrent.mul(price).div(divisor));
                    }
                }
                hasDeposits = hasDeposits >> 1;
            } else {
                break;
            }
        }

        return collETH;
    }

    /**
     * Get current deposit balance of a token
     * @dev This is an estimation. Add a new checkpoint first, if you want to derive the exact balance.
     */
    function getDepositETH(address _accountAddr) public view returns (uint256 depositETH) {
        ITokenRegistry tokenRegistry = globalConfig.tokenRegistry();
        Account storage account = accounts[_accountAddr];
        uint128 hasDeposits = account.depositBitmap;
        for (uint8 i = 0; i < 128; i++) {
            if (hasDeposits > 0) {
                bool isEnabled = (hasDeposits & uint128(1)) > 0;
                if (isEnabled) {
                    (address token, uint256 divisor, uint256 price, ) = tokenRegistry.getTokenInfoFromIndex(i);

                    uint256 depositBalanceCurrent = getDepositBalanceCurrent(token, _accountAddr);
                    depositETH = depositETH.add(depositBalanceCurrent.mul(price).div(divisor));
                }
                hasDeposits = hasDeposits >> 1;
            } else {
                break;
            }
        }

        return depositETH;
    }

    /**
     * Get borrowed balance of a token in the uint256 of Wei
     */
    function getBorrowETH(address _accountAddr) public view returns (uint256 borrowETH) {
        ITokenRegistry tokenRegistry = globalConfig.tokenRegistry();
        Account storage account = accounts[_accountAddr];
        uint128 hasBorrows = account.borrowBitmap;
        for (uint8 i = 0; i < 128; i++) {
            if (hasBorrows > 0) {
                bool isEnabled = (hasBorrows & uint128(1)) > 0;
                if (isEnabled) {
                    (address token, uint256 divisor, uint256 price, ) = tokenRegistry.getTokenInfoFromIndex(i);

                    uint256 borrowBalanceCurrent = getBorrowBalanceCurrent(token, _accountAddr);
                    borrowETH = borrowETH.add(borrowBalanceCurrent.mul(price).div(divisor));
                }
                hasBorrows = hasBorrows >> 1;
            } else {
                break;
            }
        }

        return borrowETH;
    }

    /**
     * Check if the account is liquidatable
     * @param _borrower borrower's account
     * @return true if the account is liquidatable
     */
    function isAccountLiquidatable(address _borrower) public returns (bool) {
        ITokenRegistry tokenRegistry = globalConfig.tokenRegistry();
        IBank bank = globalConfig.bank();

        // Add new rate check points for all the collateral tokens from borrower in order to
        // have accurate calculation of liquidation oppotunites.
        Account storage account = accounts[_borrower];
        uint128 hasBorrowsOrDeposits = account.borrowBitmap | account.depositBitmap;
        for (uint8 i = 0; i < 128; i++) {
            if (hasBorrowsOrDeposits > 0) {
                bool isEnabled = (hasBorrowsOrDeposits & uint128(1)) > 0;
                if (isEnabled) {
                    address token = tokenRegistry.addressFromIndex(i);
                    bank.newRateIndexCheckpoint(token);
                }
                hasBorrowsOrDeposits = hasBorrowsOrDeposits >> 1;
            } else {
                break;
            }
        }

        uint256 liquidationThreshold = globalConfig.liquidationThreshold();

        uint256 totalBorrow = getBorrowETH(_borrower);
        uint256 totalCollateral = getCollateralETH(_borrower);

        // It is required that LTV is larger than LIQUIDATE_THREADHOLD for liquidation
        // return totalBorrow.mul(100) > totalCollateral.mul(liquidationThreshold);
        return totalBorrow.mul(100) > totalCollateral.mul(liquidationThreshold);
    }

    struct LiquidationVars {
        uint256 borrowerCollateralValue;
        uint256 targetTokenBalance;
        uint256 targetTokenBalanceBorrowed;
        uint256 targetTokenPrice;
        uint256 liquidationDiscountRatio;
        uint256 totalBorrow;
        uint256 borrowPower;
        uint256 liquidateTokenBalance;
        uint256 liquidateTokenPrice;
        uint256 limitRepaymentValue;
        uint256 borrowTokenLTV;
        uint256 repayAmount;
        uint256 payAmount;
    }

    function liquidate(
        address _liquidator,
        address _borrower,
        address _borrowedToken,
        address _collateralToken
    ) external onlyAuthorized returns (uint256, uint256) {
        initCollateralFlag(_liquidator);
        initCollateralFlag(_borrower);
        require(isAccountLiquidatable(_borrower), "borrower is not liquidatable");

        // It is required that the liquidator doesn't exceed it's borrow power.
        // if liquidator has any borrows, then only check for borrowPower condition
        Account storage liquidateAcc = accounts[_liquidator];
        if (liquidateAcc.borrowBitmap > 0) {
            require(getBorrowETH(_liquidator) < getBorrowPower(_liquidator), "No extra funds used for liquidation");
        }

        LiquidationVars memory vars;

        ITokenRegistry tokenRegistry = globalConfig.tokenRegistry();

        // _borrowedToken balance of the liquidator (deposit balance)
        vars.targetTokenBalance = getDepositBalanceCurrent(_borrowedToken, _liquidator);
        require(vars.targetTokenBalance > 0, "amount must be > 0");

        // _borrowedToken balance of the borrower (borrow balance)
        vars.targetTokenBalanceBorrowed = getBorrowBalanceCurrent(_borrowedToken, _borrower);
        require(vars.targetTokenBalanceBorrowed > 0, "borrower not own any debt token");

        // _borrowedToken available for liquidation
        uint256 borrowedTokenAmountForLiquidation = vars.targetTokenBalance.min(vars.targetTokenBalanceBorrowed);

        // _collateralToken balance of the borrower (deposit balance)
        vars.liquidateTokenBalance = getDepositBalanceCurrent(_collateralToken, _borrower);

        uint256 targetTokenDivisor;
        (, targetTokenDivisor, vars.targetTokenPrice, vars.borrowTokenLTV) = tokenRegistry.getTokenInfoFromAddress(
            _borrowedToken
        );

        uint256 liquidateTokendivisor;
        uint256 collateralLTV;
        (, liquidateTokendivisor, vars.liquidateTokenPrice, collateralLTV) = tokenRegistry.getTokenInfoFromAddress(
            _collateralToken
        );

        // _collateralToken to purchase so that borrower's balance matches its borrow power
        vars.totalBorrow = getBorrowETH(_borrower);
        vars.borrowPower = getBorrowPower(_borrower);
        vars.liquidationDiscountRatio = globalConfig.liquidationDiscountRatio();
        vars.limitRepaymentValue = vars.totalBorrow.sub(vars.borrowPower).mul(100).div(
            vars.liquidationDiscountRatio.sub(collateralLTV)
        );

        uint256 collateralTokenValueForLiquidation = vars.limitRepaymentValue.min(
            vars.liquidateTokenBalance.mul(vars.liquidateTokenPrice).div(liquidateTokendivisor)
        );

        uint256 liquidationValue = collateralTokenValueForLiquidation.min(
            borrowedTokenAmountForLiquidation.mul(vars.targetTokenPrice).mul(100).div(targetTokenDivisor).div(
                vars.liquidationDiscountRatio
            )
        );

        vars.repayAmount = liquidationValue.mul(vars.liquidationDiscountRatio).mul(targetTokenDivisor).div(100).div(
            vars.targetTokenPrice
        );
        vars.payAmount = vars.repayAmount.mul(liquidateTokendivisor).mul(100).mul(vars.targetTokenPrice);
        vars.payAmount = vars.payAmount.div(targetTokenDivisor).div(vars.liquidationDiscountRatio).div(
            vars.liquidateTokenPrice
        );

        deposit(_liquidator, _collateralToken, vars.payAmount);
        _withdrawLiquidate(_liquidator, _borrowedToken, vars.repayAmount);
        _withdrawLiquidate(_borrower, _collateralToken, vars.payAmount);
        repay(_borrower, _borrowedToken, vars.repayAmount);

        return (vars.repayAmount, vars.payAmount);
    }

    /**
     * Get current block number
     * @return the current block number
     */
    function getBlockNumber() private view returns (uint256) {
        return block.number;
    }

    /**
     * An account claim all mined FIN token.
     * @dev If the FIN mining index point doesn't exist, we have to calculate the FIN amount
     * accurately. So the user can withdraw all available FIN tokens.
     */
    function claim(address _account) public onlyAuthorized returns (uint256) {
        ITokenRegistry tokenRegistry = globalConfig.tokenRegistry();
        IBank bank = globalConfig.bank();

        uint256 currentBlock = getBlockNumber();

        Account storage account = accounts[_account];
        uint128 depositBitmap = account.depositBitmap;
        uint128 borrowBitmap = account.borrowBitmap;
        uint128 hasDepositOrBorrow = depositBitmap | borrowBitmap;

        for (uint8 i = 0; i < 128; i++) {
            if (hasDepositOrBorrow > 0) {
                if ((hasDepositOrBorrow & uint128(1)) > 0) {
                    address token = tokenRegistry.addressFromIndex(i);
                    AccountTokenLib.TokenInfo storage tokenInfo = accounts[_account].tokenInfos[token];
                    bank.updateMining(token);
                    if (depositBitmap.isBitSet(i)) {
                        bank.updateDepositFINIndex(token);
                        uint256 lastDepositBlock = tokenInfo.getLastDepositBlock();
                        calculateDepositFIN(lastDepositBlock, token, _account, currentBlock);
                        tokenInfo.deposit(0, bank.getDepositAccruedRate(token, lastDepositBlock), currentBlock);
                    }

                    if (borrowBitmap.isBitSet(i)) {
                        bank.updateBorrowFINIndex(token);
                        uint256 lastBorrowBlock = tokenInfo.getLastBorrowBlock();
                        calculateBorrowFIN(lastBorrowBlock, token, _account, currentBlock);
                        tokenInfo.borrow(0, bank.getBorrowAccruedRate(token, lastBorrowBlock), currentBlock);
                    }
                }
                hasDepositOrBorrow = hasDepositOrBorrow >> 1;
            } else {
                break;
            }
        }

        uint256 _finAmount = finAmount[_account];
        finAmount[_account] = 0;
        return _finAmount;
    }

    function claimForToken(address _account, address _token) public onlyAuthorized returns (uint256) {
        Account storage account = accounts[_account];
        uint8 index = globalConfig.tokenRegistry().getTokenIndex(_token);
        bool isDeposit = account.depositBitmap.isBitSet(index);
        bool isBorrow = account.borrowBitmap.isBitSet(index);
        if (!(isDeposit || isBorrow)) return 0;

        IBank bank = globalConfig.bank();
        uint256 currentBlock = getBlockNumber();

        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_account].tokenInfos[_token];
        bank.updateMining(_token);

        if (isDeposit) {
            bank.updateDepositFINIndex(_token);
            uint256 lastDepositBlock = tokenInfo.getLastDepositBlock();
            calculateDepositFIN(lastDepositBlock, _token, _account, currentBlock);
            tokenInfo.deposit(0, bank.getDepositAccruedRate(_token, lastDepositBlock), currentBlock);
        }
        if (isBorrow) {
            bank.updateBorrowFINIndex(_token);
            uint256 lastBorrowBlock = tokenInfo.getLastBorrowBlock();
            calculateBorrowFIN(lastBorrowBlock, _token, _account, currentBlock);
            tokenInfo.borrow(0, bank.getBorrowAccruedRate(_token, lastBorrowBlock), currentBlock);
        }

        uint256 _finAmount = finAmount[_account];
        finAmount[_account] = 0;
        return _finAmount;
    }

    /**
     * Accumulate the amount FIN mined by depositing between _lastBlock and _currentBlock
     */
    function calculateDepositFIN(
        uint256 _lastBlock,
        address _token,
        address _accountAddr,
        uint256 _currentBlock
    ) internal {
        IBank bank = globalConfig.bank();

        uint256 indexDifference = bank.depositFINRateIndex(_token, _currentBlock).sub(
            bank.depositFINRateIndex(_token, _lastBlock)
        );
        uint256 getFIN = getDepositBalanceCurrent(_token, _accountAddr).mul(indexDifference).div(
            bank.depositeRateIndex(_token, _currentBlock)
        );
        finAmount[_accountAddr] = finAmount[_accountAddr].add(getFIN);
    }

    /**
     * Accumulate the amount FIN mined by borrowing between _lastBlock and _currentBlock
     */
    function calculateBorrowFIN(
        uint256 _lastBlock,
        address _token,
        address _accountAddr,
        uint256 _currentBlock
    ) internal {
        IBank bank = globalConfig.bank();

        uint256 indexDifference = bank.borrowFINRateIndex(_token, _currentBlock).sub(
            bank.borrowFINRateIndex(_token, _lastBlock)
        );
        uint256 getFIN = getBorrowBalanceCurrent(_token, _accountAddr).mul(indexDifference).div(
            bank.borrowRateIndex(_token, _currentBlock)
        );
        finAmount[_accountAddr] = finAmount[_accountAddr].add(getFIN);
    }

    function version() public pure returns (string memory) {
        return "v2.0.0";
    }
}