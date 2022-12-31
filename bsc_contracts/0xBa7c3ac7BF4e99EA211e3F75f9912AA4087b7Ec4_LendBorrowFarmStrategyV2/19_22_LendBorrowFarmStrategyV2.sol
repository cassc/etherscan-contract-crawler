// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./../utils/LogicUpgradeable.sol";
import "./../Interfaces/ILogicContract.sol";
import "./../Interfaces/IXToken.sol";
import "./../Interfaces/ICompoundVenus.sol";
import "./../Interfaces/ISwap.sol";
import "./../Interfaces/IMultiLogicProxy.sol";
import "./../Interfaces/ILendBorrowFarmingPair.sol";

contract LendBorrowFarmStrategyV2 is LogicUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address private blid;
    address private comptroller;
    address public logic;
    address public farmingPair;
    address private multiLogicProxy;
    address private rewardsSwapRouter;
    address private rewardsToken;
    address[] private pathToSwapRewardsToBNB;
    address[] private pathToSwapBNBToBLID;

    mapping(address => address) private vTokens;
    mapping(uint256 => address) lendingTokens;
    uint256 lendingTokensCount;

    event SetBLID(address _blid);
    event SetMultiLogicProxy(address multiLogicProxy);
    event AddLendingToken(address token);
    event ReleaseToken(address token, uint256 amount);
    event Build(uint256);
    event Destroy(uint256);
    event DestroyAll();
    event ClaimRewards(uint256 amount);

    function __LendBorrowFarmStrategy_init(
        address _comptroller,
        address _rewardsSwapRouter,
        address _rewardsToken,
        address _logic,
        address _farmingPair
    ) public initializer {
        LogicUpgradeable.initialize();
        comptroller = _comptroller;
        rewardsSwapRouter = _rewardsSwapRouter;
        rewardsToken = _rewardsToken;
        logic = _logic;
        farmingPair = _farmingPair;
    }

    receive() external payable {}

    fallback() external payable {}

    /*** Owner functions ***/

    modifier onlyMultiLogicProxy() {
        require(msg.sender == multiLogicProxy, "F1");
        _;
    }

    /**
     * @notice Set blid in contract
     * @param blid_ Address of BLID
     */
    function setBLID(address blid_) external onlyOwner {
        blid = blid_;
        emit SetBLID(blid_);
    }

    /**
     * @notice Set MultiLogicProxy, you can call the function once
     * @param _multiLogicProxy Address of Storage Contract
     */
    function setMultiLogicProxy(address _multiLogicProxy) external onlyOwner {
        require(multiLogicProxy == address(0), "F5");
        multiLogicProxy = _multiLogicProxy;

        emit SetMultiLogicProxy(_multiLogicProxy);
    }

    /**
     * @notice Set pathToSwapRewardsToBNB
     * @param path path to rewards to BNB
     */
    function setPathToSwapRewardsToBNB(
        address[] calldata path
    ) external onlyOwner {
        uint256 length = path.length;
        require(length >= 2, "F16");
        require(path[0] == rewardsToken, "F17");

        pathToSwapRewardsToBNB = path;
    }

    /**
     * @notice Set pathToSwapBNBToBLID
     * @param path path to BNB to BLID
     */
    function setPathToSwapBNBToBLID(
        address[] calldata path
    ) external onlyOwner {
        uint256 length = path.length;
        require(length >= 2, "F16");
        require(path[length - 1] == blid, "F18");

        pathToSwapBNBToBLID = path;
    }

    /**
     * @notice Add vToken in Contract and approve token
     * this token will be used for Lending
     * Approve token for storage, venus, pancakeswap/apeswap/biswap router,
     * and pancakeswap/apeswap/biswap master(Main Staking contract)
     * Approve rewardsToken for swap
     * @param token Address of underlying token
     * @param vToken Address of vToken
     */
    function addLendingToken(address token, address vToken) public onlyOwner {
        require(vTokens[token] == address(0), "F6");

        address _logic = logic;
        vTokens[token] = vToken;

        // Add token/oToken to Logic
        ILogicContract(_logic).addXTokens(token, vToken, 0);

        // Entermarkets with token/vtoken
        address[] memory tokens = new address[](1);
        tokens[0] = vToken;
        ILogicContract(_logic).enterMarkets(tokens, 0);

        // Add LendingTokens
        lendingTokens[lendingTokensCount++] = vToken;

        emit AddLendingToken(token);
    }

    /*** Strategy functions ***/

    /**
     * @notice Take all available token from storage and mint
     */
    function lendToken() external onlyOwnerAndAdmin {
        address _logic = logic;

        // Get all tokens in storage
        address[] memory tokens = IMultiLogicProxy(multiLogicProxy)
            .getUsedTokensStorage();
        uint256 length = tokens.length;

        // For each token
        for (uint256 i = 0; i < length; ) {
            address token = tokens[i];

            // Get available amount
            uint256 amount = IMultiLogicProxy(multiLogicProxy)
                .getTokenAvailable(token, _logic);

            if (amount > 0) {
                // Check token has been inited
                require(vTokens[token] != address(0), "F2");

                // Take token from storage
                ILogicContract(_logic).takeTokenFromStorage(amount, token);

                // Mint
                ILogicContract(_logic).mint(vTokens[token], amount);
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Build Strategy
     * @param usdAmount Amount of USD to borrow : decimal = 18
     */
    function build(uint256 usdAmount) external onlyOwnerAndAdmin {
        // Get Farming Pairs, Percentages
        FarmingPair[] memory reserves = ILendBorrowFarmingPair(farmingPair)
            .getFarmingPairs();

        // Check percentage and farmingPair are matched
        ILendBorrowFarmingPair(farmingPair).checkPercentages();

        uint256 index;

        // Array of token borrow
        address[] memory arrBorrowToken = new address[](reserves.length * 2);
        uint256[] memory arrBorrowAmount = new uint256[](reserves.length * 2);

        // Array of token amount for addLiquidity
        uint256[] memory arrToken0Amount = new uint256[](reserves.length);
        uint256[] memory arrToken1Amount = new uint256[](reserves.length);
        uint256 pos;
        uint256 posBNB;

        // For each pair, calculate build, borrow amount
        for (index = 0; index < reserves.length; ) {
            // Calculate the build, borrow amount
            (arrToken0Amount[index], arrToken1Amount[index]) = _calcBuildAmount(
                reserves[index],
                (usdAmount * reserves[index].percentage) / 10000
            );

            // Store borrow token and borrow amount in array
            uint256 i;
            for (i = 0; i < pos + 1; i++) {
                if (arrBorrowToken[i] == reserves[index].xTokenA) {
                    arrBorrowAmount[i] += arrToken0Amount[index];
                    break;
                }
            }
            if (i == pos + 1) {
                arrBorrowToken[pos] = reserves[index].xTokenA;
                arrBorrowAmount[pos] = arrToken0Amount[index];
                pos++;
            }

            for (i = 0; i < pos + 1; i++) {
                if (arrBorrowToken[i] == reserves[index].xTokenB) {
                    arrBorrowAmount[i] += arrToken1Amount[index];
                    break;
                }
            }
            if (i == pos + 1) {
                arrBorrowToken[pos] = reserves[index].xTokenB;
                arrBorrowAmount[pos] = arrToken1Amount[index];
                if (reserves[index].tokenB == address(0)) posBNB = pos;
                pos++;
            }

            unchecked {
                ++index;
            }
        }

        address _logic = logic;

        // Borrow Tokens
        for (index = 0; index < pos; ) {
            if (arrBorrowAmount[index] > 0) {
                uint256 balance = index == posBNB
                    ? address(_logic).balance
                    : IERC20Upgradeable(
                        IXToken(arrBorrowToken[index]).underlying()
                    ).balanceOf(_logic);

                if (arrBorrowAmount[index] > balance) {
                    uint256 borrowResult = ILogicContract(_logic).borrow(
                        arrBorrowToken[index],
                        arrBorrowAmount[index] - balance,
                        0
                    );

                    require(borrowResult == 0, "F13"); // Borrow should be successed
                }
            }

            unchecked {
                ++index;
            }
        }

        // Add Liquidity, Deposit
        for (index = 0; index < reserves.length; ) {
            // Add Liquidity
            uint256 liquidity;
            if (reserves[index].tokenB == address(0)) {
                // If tokenB is BNB
                (, , liquidity) = ILogicContract(_logic).addLiquidityETH(
                    reserves[index].swap,
                    reserves[index].tokenA,
                    arrToken0Amount[index],
                    arrToken1Amount[index],
                    0,
                    0,
                    block.timestamp + 1 hours
                );
            } else {
                // If tokenA, tokenB are not BNB
                (, , liquidity) = ILogicContract(_logic).addLiquidity(
                    reserves[index].swap,
                    reserves[index].tokenA,
                    reserves[index].tokenB,
                    arrToken0Amount[index],
                    arrToken1Amount[index],
                    0,
                    0,
                    block.timestamp + 1 hours
                );
            }

            // Deposit to masterchief
            ILogicContract(_logic).deposit(
                reserves[index].swapMaster,
                reserves[index].poolID,
                liquidity
            );

            unchecked {
                ++index;
            }
        }

        emit Build(usdAmount);
    }

    /**
     * @notice Destory Strategy
     * @param _percentage % that sould be destoried for all pairs < 10000
     */
    function destroy(uint256 _percentage) public onlyOwnerAndAdmin {
        require(_percentage <= 10000, "F11");

        // Get Farming Pairs, Percentages
        FarmingPair[] memory reserves = ILendBorrowFarmingPair(farmingPair)
            .getFarmingPairs();

        // Calculate the total amount of each pair
        address _logic = logic;
        uint256 count = reserves.length;
        uint256 index;

        // For each pair, process the build
        for (index = 0; index < count; ) {
            FarmingPair memory reserve = reserves[index];

            (uint256 depositedLp, ) = IMasterChef(reserve.swapMaster).userInfo(
                reserve.poolID,
                _logic
            );

            // Withdraw LP token from masterchef and repayborrow
            if (depositedLp > 0)
                _withdrawAndRepay(reserve, (depositedLp * _percentage) / 10000);

            unchecked {
                ++index;
            }
        }

        emit Destroy(_percentage);
    }

    /**
     * @notice Destory Strategy All
     */
    function destroyAll() public onlyOwnerAndAdmin {
        // Get Farming Pairs, Percentages
        FarmingPair[] memory reserves = ILendBorrowFarmingPair(farmingPair)
            .getFarmingPairs();

        // Calculate the total amount of each pair
        address _logic = logic;
        uint256 count = reserves.length;
        uint256 index;

        // Claim and swap rewards to BNB
        _claimInternal(0);

        // Destory all pairs
        destroy(10000);

        // For each pair Swap remained tokens to BNB
        uint256 deadline = block.timestamp + 100;
        uint256 balance;
        for (index = 0; index < count; ) {
            FarmingPair memory reserve = reserves[index];

            // Check TokenA
            balance = IERC20Upgradeable(reserve.tokenA).balanceOf(_logic);
            if (balance > 0) {
                ILogicContract(_logic).swapExactTokensForETH(
                    reserve.swap,
                    balance,
                    0,
                    reserve.pathTokenA2BNB,
                    deadline
                );
            }

            // Check TokenB
            if (reserve.tokenB != address(0)) {
                balance = IERC20Upgradeable(reserve.tokenB).balanceOf(_logic);
                if (balance > 0) {
                    ILogicContract(_logic).swapExactTokensForETH(
                        reserve.swap,
                        balance,
                        0,
                        reserve.pathTokenB2BNB,
                        deadline
                    );
                }
            }

            unchecked {
                ++index;
            }
        }

        // For each pair if there is unpaid borrow, repay it using BNB
        uint256 borrowAmount;
        uint256 length;
        address[] memory pathToBNBToToken;
        uint256 i;
        for (index = 0; index < count; ) {
            FarmingPair memory reserve = reserves[index];

            // For TokenA
            borrowAmount = IXToken(reserve.xTokenA).borrowBalanceCurrent(
                _logic
            );
            if (borrowAmount > 0) {
                // Get path BNB to token
                length = reserve.pathTokenA2BNB.length;
                pathToBNBToToken = new address[](length);
                for (i = 0; i < length; i++)
                    pathToBNBToToken[i] = reserve.pathTokenA2BNB[
                        length - i - 1
                    ];

                // Swap BNB for token
                balance = address(_logic).balance;
                ILogicContract(_logic).swapETHForExactTokens(
                    reserve.swap,
                    balance,
                    borrowAmount,
                    pathToBNBToToken,
                    deadline
                );

                // Repayborrow
                ILogicContract(_logic).repayBorrow(
                    reserve.xTokenA,
                    borrowAmount
                );
            }

            // For TokenB
            borrowAmount = IXToken(reserve.xTokenB).borrowBalanceCurrent(
                _logic
            );
            if (borrowAmount > 0) {
                // Get path BNB to token
                if (reserve.tokenB != address(0)) {
                    length = reserve.pathTokenB2BNB.length;
                    pathToBNBToToken = new address[](length);
                    for (i = 0; i < length; i++)
                        pathToBNBToToken[i] = reserve.pathTokenB2BNB[
                            length - i - 1
                        ];

                    // Swap BNB for token
                    balance = address(_logic).balance;
                    ILogicContract(_logic).swapETHForExactTokens(
                        reserve.swap,
                        balance,
                        borrowAmount,
                        pathToBNBToToken,
                        deadline
                    );
                }

                // Repayborrow
                ILogicContract(_logic).repayBorrow(
                    reserve.xTokenB,
                    borrowAmount
                );
            }

            unchecked {
                ++index;
            }
        }

        // Swap all available BNB
        uint256 balanceBNBNew = address(_logic).balance;
        if (balanceBNBNew > 0) {
            _sendRewardsToStorage(balanceBNBNew);
        }

        emit DestroyAll();
    }

    /**
     * @notice Destory All, RedeemUnderlying, return all Tokens to storage
     */
    function returnAllTokensToStorage() external onlyOwnerAndAdmin {
        address _logic = logic;

        // Destroy All
        destroyAll();

        // Get all tokens in storage
        address[] memory tokens = IMultiLogicProxy(multiLogicProxy)
            .getUsedTokensStorage();
        uint256 length = tokens.length;

        // For each token
        for (uint256 i = 0; i < length; ) {
            address token = tokens[i];

            // Get token balance registered to MultiLogic
            uint256 balance = IMultiLogicProxy(multiLogicProxy).getTokenTaken(
                token,
                _logic
            );

            if (balance > 0) {
                // Check token has been inited
                require(vTokens[token] != address(0), "F2");

                // Calculate redeem amount
                uint256 redeemAmount = balance;
                if (token != address(0))
                    redeemAmount -= IERC20Upgradeable(token).balanceOf(_logic); // Logic doesn't have BNB after destroyAll();

                // RedeemUnderlying
                if (redeemAmount > 0)
                    ILogicContract(_logic).redeemUnderlying(
                        vTokens[token],
                        redeemAmount
                    );

                // Return existing Token To Storage
                ILogicContract(_logic).returnTokenToStorage(balance, token);
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Claim Rewards and send BLID to Storage
     * @param mode 0 : all, 1 : Venus only, 2 : Farm only
     */
    function claimRewards(uint8 mode) external onlyOwnerAndAdmin {
        require(pathToSwapBNBToBLID.length >= 2, "F15");

        address _logic = logic;

        // Keep BNB balance
        uint256 balanceBNBOld = address(_logic).balance;

        // Claim Rewards token
        _claimInternal(mode);

        // Check rewards BNB
        uint256 balanceBNBNew = address(_logic).balance;

        if (balanceBNBNew > balanceBNBOld) {
            // Convert BNB to BLID and send to storage
            uint256 amountBLID = _sendRewardsToStorage(
                balanceBNBNew - balanceBNBOld
            );

            emit ClaimRewards(amountBLID);
        }
    }

    /**
     * @notice multicall to Logic
     */
    function multicall(
        bytes[] memory callDatas
    )
        public
        onlyOwnerAndAdmin
        returns (uint256 blockNumber, bytes[] memory returnData)
    {
        blockNumber = block.number;
        uint256 length = callDatas.length;
        returnData = new bytes[](length);
        for (uint256 i = 0; i < length; ) {
            (bool success, bytes memory ret) = address(logic).call(
                callDatas[i]
            );
            require(success, "F99");
            returnData[i] = ret;

            unchecked {
                ++i;
            }
        }
    }

    /*** MultiLogicProxy Function ***/

    /**
     * @notice Frees up tokens for the user, but Storage doesn't transfer token for the user,
     * only Storage can this function, after calling this function Storage transfer
     * from Logic to user token.
     * @param _amount Amount of token
     * @param token Address of token
     */
    function releaseToken(
        uint256 _amount,
        address token
    ) external payable onlyMultiLogicProxy {
        require(vTokens[token] != address(0), "F2");

        // Get Farming Pairs
        FarmingPair[] memory reserves = ILendBorrowFarmingPair(farmingPair)
            .getFarmingPairs();

        uint256 takeFromVenus = 0;
        uint256 length = reserves.length;
        address _logic = logic;
        address vToken = vTokens[token];

        // check logic balance
        uint256 amount;

        if (token == address(0)) {
            amount = address(_logic).balance;
        } else {
            amount = IERC20Upgradeable(token).balanceOf(_logic);
        }
        if (amount >= _amount) {
            if (token == address(0)) {
                ILogicContract(_logic).returnETHToMultiLogicProxy(_amount);
            }

            emit ReleaseToken(token, _amount);
            return;
        }

        // decrease redeemAmount
        amount = _amount - amount;

        //loop by reserves lp token
        for (uint256 i = 0; i < length; ) {
            address[] memory path = ILendBorrowFarmingPair(farmingPair)
                .findPath(i, token); // get path for router
            FarmingPair memory reserve = reserves[i];
            uint256 lpAmount = ILendBorrowFarmingPair(farmingPair)
                .getPriceFromTokenToLp(
                    reserve.lpToken,
                    amount - takeFromVenus,
                    token,
                    reserve.swap,
                    path
                ); //get amount of lp token that need for reedem liqudity

            //get how many deposited to farming
            (uint256 depositedLp, ) = IMasterChef(reserve.swapMaster).userInfo(
                reserve.poolID,
                _logic
            );
            if (depositedLp == 0) continue;
            // if deposited LP tokens don't enough  for repay borrow and for reedem token then only repay
            // borow and continue loop, else repay borow, reedem token and break loop
            if (lpAmount >= depositedLp) {
                takeFromVenus += ILendBorrowFarmingPair(farmingPair)
                    .getPriceFromLpToToken(
                        reserve.lpToken,
                        depositedLp,
                        token,
                        reserve.swap,
                        path
                    );
                _withdrawAndRepay(reserve, depositedLp);
            } else {
                _withdrawAndRepay(reserve, lpAmount);

                // get supplied token and break loop
                ILogicContract(_logic).redeemUnderlying(vToken, amount);

                if (token == address(0)) {
                    ILogicContract(_logic).returnETHToMultiLogicProxy(amount);
                }
                emit ReleaseToken(token, _amount);
                return;
            }

            unchecked {
                ++i;
            }
        }

        //try get supplied token
        ILogicContract(_logic).redeemUnderlying(vToken, amount);
        //if get money
        if (
            token != address(0) &&
            IERC20Upgradeable(token).balanceOf(_logic) >= _amount
        ) {
            emit ReleaseToken(token, _amount);
            return;
        }

        if (token == address(0) && address(_logic).balance >= _amount) {
            ILogicContract(_logic).returnETHToMultiLogicProxy(amount);
            emit ReleaseToken(token, _amount);
            return;
        }

        // redeem remaind vToken
        uint256 vTokenBalance; // balance of cToken
        uint256 exchangeRateMantissa; //conversion rate from cToken to token

        // Get vToken information and redeem
        (, vTokenBalance, , exchangeRateMantissa) = IXToken(vToken)
            .getAccountSnapshot(_logic);

        if (vTokenBalance > 0) {
            uint256 supplyBalance = (vTokenBalance * exchangeRateMantissa) /
                10 ** 18;

            ILogicContract(_logic).redeemUnderlying(vToken, supplyBalance);
        }

        if (
            token != address(0) &&
            IERC20Upgradeable(token).balanceOf(_logic) >= _amount
        ) {
            emit ReleaseToken(token, _amount);
            return;
        }

        if (token == address(0) && address(_logic).balance >= _amount) {
            ILogicContract(_logic).returnETHToMultiLogicProxy(amount);
            emit ReleaseToken(token, _amount);
            return;
        }

        revert("no money");
    }

    /*** Prive Functions ***/

    /**
     * Calculate borrow amount for each pair
     * @param reserve FarmingPair
     * @param borrowUSDAmount required borrow amount in USD for this pair
     * @return token0Amount token0 build amount
     * @return token1Amount token1 build amount
     */
    function _calcBuildAmount(
        FarmingPair memory reserve,
        uint256 borrowUSDAmount
    ) private view returns (uint256 token0Amount, uint256 token1Amount) {
        address _comptroller = comptroller;
        uint256 balance0;
        uint256 balance1;

        // Token convertion rate to USD : decimal = 18 + (18 - token.decimals)
        uint256 token0Price = IOracleVenus(
            IComptrollerVenus(_comptroller).oracle()
        ).getUnderlyingPrice(reserve.xTokenA);
        uint256 token1Price = IOracleVenus(
            IComptrollerVenus(_comptroller).oracle()
        ).getUnderlyingPrice(reserve.xTokenB);

        // get Reserves
        (balance0, balance1, ) = IPancakePair(reserve.lpToken).getReserves();

        // Calculate Reserves in USD Amount, token0 cannot be BNB (0x000000000000000)
        balance0 =
            ((
                IPancakePair(reserve.lpToken).token0() == reserve.tokenA
                    ? balance0
                    : balance1
            ) * token0Price) /
            (10 ** 18);
        balance1 =
            ((
                IPancakePair(reserve.lpToken).token0() == reserve.tokenA
                    ? balance1
                    : balance0
            ) * token1Price) /
            (10 ** 18);

        // Calculate build amount for addToLiquidity
        token0Amount =
            (borrowUSDAmount * (10 ** 18) * balance0) /
            (token0Price * (balance0 + balance1));
        token1Amount =
            (borrowUSDAmount * (10 ** 18) * balance1) /
            (token1Price * (balance0 + balance1));
    }

    /**
     * @notice Claim rewards and swap to BNB
     * @param mode 0 : all, 1 : Venus only, 2 : Farm only
     */
    function _claimInternal(uint8 mode) private {
        require(pathToSwapRewardsToBNB.length >= 2, "F14");

        address _logic = logic;
        uint256 _lendingTokensCount = lendingTokensCount;
        uint256 index;
        uint256 deadline = block.timestamp + 100;
        uint256 balance;

        // claim XVS
        if (mode == 0 || mode == 1) {
            address[] memory vTokensToClaim = new address[](
                _lendingTokensCount
            );
            for (index = 0; index < _lendingTokensCount; ) {
                vTokensToClaim[index] = lendingTokens[index];

                unchecked {
                    ++index;
                }
            }
            ILogicContract(_logic).claim(vTokensToClaim, 0);

            // Swap XVS to BNB
            balance = IERC20Upgradeable(rewardsToken).balanceOf(_logic);
            if (balance > 0) {
                ILogicContract(_logic).swapExactTokensForETH(
                    rewardsSwapRouter,
                    balance,
                    0,
                    pathToSwapRewardsToBNB,
                    deadline
                );
            }
        }

        // For each pair, claim CAKE/BSW
        if (mode == 0 || mode == 2) {
            // Get Farming Pairs
            FarmingPair[] memory reserves = ILendBorrowFarmingPair(farmingPair)
                .getFarmingPairs();
            uint256 count = reserves.length;

            for (index = 0; index < count; ) {
                FarmingPair memory reserve = reserves[index];

                // call MasterChef.deposit(0);
                ILogicContract(_logic).deposit(
                    reserve.swapMaster,
                    reserve.poolID,
                    0
                );

                // Swap rewards token to BNB
                balance = IERC20Upgradeable(reserve.rewardsToken).balanceOf(
                    _logic
                );
                if (balance > 0) {
                    ILogicContract(_logic).swapExactTokensForETH(
                        reserve.swap,
                        balance,
                        0,
                        reserve.pathRewards2BNB,
                        deadline
                    );
                }

                unchecked {
                    ++index;
                }
            }
        }
    }

    /**
     * @notice Swap BNB to BLID and send to storage
     * @param amountBNB reward BNB amount
     * @return amountBLID reward BLID amount
     */
    function _sendRewardsToStorage(
        uint256 amountBNB
    ) internal returns (uint256 amountBLID) {
        address _logic = logic;

        // Convert BNB to BLID
        if (amountBNB > 0) {
            uint256 amountOutMin = 0;
            uint256 deadline = block.timestamp + 100;

            ILogicContract(_logic).swapExactETHForTokens(
                rewardsSwapRouter,
                amountBNB,
                amountOutMin,
                pathToSwapBNBToBLID,
                deadline
            );

            // Add BLID earn to storage
            amountBLID = IERC20Upgradeable(blid).balanceOf(_logic);
            if (amountBLID > 0)
                ILogicContract(_logic).addEarnToStorage(amountBLID);
        }
    }

    /**
     * @notice Withdraw lp token from farms and repay borrow
     */
    function _withdrawAndRepay(
        FarmingPair memory reserve,
        uint256 lpAmount
    ) private {
        ILogicContract(logic).withdraw(
            reserve.swapMaster,
            reserve.poolID,
            lpAmount
        );
        if (reserve.tokenB == address(0)) {
            //if tokenB is BNB
            _repayBorrowBNBandToken(
                reserve.swap,
                reserve.tokenA,
                reserve.xTokenB,
                reserve.xTokenA,
                lpAmount
            );
        } else {
            //if token A and B is not BNB
            _repayBorrowOnlyTokens(
                reserve.swap,
                reserve.tokenA,
                reserve.tokenB,
                reserve.xTokenA,
                reserve.xTokenB,
                lpAmount
            );
        }
    }

    /**
     * @notice Repay borrow when in farms  erc20 and BNB
     */
    function _repayBorrowBNBandToken(
        address swap,
        address tokenB,
        address xTokenA,
        address xTokenB,
        uint256 lpAmount
    ) private {
        address _logic = logic;

        (uint256 amountToken, uint256 amountETH) = ILogicContract(_logic)
            .removeLiquidityETH(
                swap,
                tokenB,
                lpAmount,
                0,
                0,
                block.timestamp + 1 days
            );
        {
            uint256 totalBorrow = IXTokenETH(xTokenA).borrowBalanceCurrent(
                _logic
            );
            if (totalBorrow >= amountETH) {
                ILogicContract(_logic).repayBorrow(xTokenA, amountETH);
            } else {
                ILogicContract(_logic).repayBorrow(xTokenA, totalBorrow);
            }

            totalBorrow = IXToken(xTokenB).borrowBalanceCurrent(_logic);
            if (totalBorrow >= amountToken) {
                ILogicContract(_logic).repayBorrow(xTokenB, amountToken);
            } else {
                ILogicContract(_logic).repayBorrow(xTokenB, totalBorrow);
            }
        }
    }

    /**
     * @notice Repay borrow when in farms only erc20
     */
    function _repayBorrowOnlyTokens(
        address swap,
        address tokenA,
        address tokenB,
        address xTokenA,
        address xTokenB,
        uint256 lpAmount
    ) private {
        address _logic = logic;

        (uint256 amountA, uint256 amountB) = ILogicContract(_logic)
            .removeLiquidity(
                swap,
                tokenA,
                tokenB,
                lpAmount,
                0,
                0,
                block.timestamp + 1 days
            );
        {
            uint256 totalBorrow = IXToken(xTokenA).borrowBalanceCurrent(_logic);
            if (totalBorrow >= amountA) {
                ILogicContract(_logic).repayBorrow(xTokenA, amountA);
            } else {
                ILogicContract(_logic).repayBorrow(xTokenA, totalBorrow);
            }

            totalBorrow = IXToken(xTokenB).borrowBalanceCurrent(_logic);
            if (totalBorrow >= amountB) {
                ILogicContract(_logic).repayBorrow(xTokenB, amountB);
            } else {
                ILogicContract(_logic).repayBorrow(xTokenB, totalBorrow);
            }
        }
    }
}

contract LendBorrowFarmStrategyV2Old is LogicUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address private blid;
    address private comptroller;
    address private logic;
    address private farmingPair;
    address private multiLogicProxy;
    address private rewardsSwapRouter;
    address private rewardsToken;
    address[] private pathToSwapRewardsToBNB;
    address[] private pathToSwapBNBToBLID;

    mapping(address => address) private vTokens;
    mapping(uint256 => address) lendingTokens;
    uint256 lendingTokensCount;

    event SetBLID(address _blid);
    event SetMultiLogicProxy(address multiLogicProxy);
    event AddLendingToken(address token);
    event ReleaseToken(address token, uint256 amount);
    event Build(uint256);
    event Destroy(uint256);
    event DestroyAll();
    event ClaimRewards(uint256 amount);

    function __LendBorrowFarmStrategy_init(
        address _comptroller,
        address _rewardsSwapRouter,
        address _rewardsToken,
        address _logic,
        address _farmingPair
    ) public initializer {
        LogicUpgradeable.initialize();
        comptroller = _comptroller;
        rewardsSwapRouter = _rewardsSwapRouter;
        rewardsToken = _rewardsToken;
        logic = _logic;
        farmingPair = _farmingPair;
    }

    receive() external payable {}

    fallback() external payable {}

    modifier onlyMultiLogicProxy() {
        require(msg.sender == multiLogicProxy, "F1");
        _;
    }

    /**
     * @notice Set blid in contract
     * @param blid_ Address of BLID
     */
    function setBLID(address blid_) external onlyOwner {
        blid = blid_;
        emit SetBLID(blid_);
    }

    /**
     * @notice Set MultiLogicProxy, you can call the function once
     * @param _multiLogicProxy Address of Storage Contract
     */
    function setMultiLogicProxy(address _multiLogicProxy) external onlyOwner {
        require(multiLogicProxy == address(0), "F5");
        multiLogicProxy = _multiLogicProxy;

        emit SetMultiLogicProxy(_multiLogicProxy);
    }

    /**
     * @notice Set pathToSwapRewardsToBNB
     * @param path path to rewards to BNB
     */
    function setPathToSwapRewardsToBNB(
        address[] calldata path
    ) external onlyOwner {
        uint256 length = path.length;
        require(length >= 2, "F16");
        require(path[0] == rewardsToken, "F17");

        pathToSwapRewardsToBNB = path;
    }

    /**
     * @notice Set pathToSwapBNBToBLID
     * @param path path to BNB to BLID
     */
    function setPathToSwapBNBToBLID(
        address[] calldata path
    ) external onlyOwner {
        uint256 length = path.length;
        require(length >= 2, "F16");
        require(path[length - 1] == blid, "F18");

        pathToSwapBNBToBLID = path;
    }

    /**
     * @notice Add vToken in Contract and approve token
     * this token will be used for Lending
     * Approve token for storage, venus, pancakeswap/apeswap/biswap router,
     * and pancakeswap/apeswap/biswap master(Main Staking contract)
     * Approve rewardsToken for swap
     * @param token Address of underlying token
     * @param vToken Address of vToken
     */
    function addLendingToken(address token, address vToken) public onlyOwner {
        require(vTokens[token] == address(0), "F6");

        address _logic = logic;
        vTokens[token] = vToken;

        // Add token/oToken to Logic
        ILogicContract(_logic).addXTokens(token, vToken, 0);

        // Entermarkets with token/vtoken
        address[] memory tokens = new address[](1);
        tokens[0] = vToken;
        ILogicContract(_logic).enterMarkets(tokens, 0);

        // Add LendingTokens
        lendingTokens[lendingTokensCount++] = vToken;

        emit AddLendingToken(token);
    }

    /**
     * @notice Take all available token from storage and mint
     */
    function lendToken() external onlyOwnerAndAdmin {
        address _logic = logic;

        // Get all tokens in storage
        address[] memory tokens = IMultiLogicProxy(multiLogicProxy)
            .getUsedTokensStorage();
        uint256 length = tokens.length;

        // For each token
        for (uint256 i = 0; i < length; ) {
            address token = tokens[i];

            // Get available amount
            uint256 amount = IMultiLogicProxy(multiLogicProxy)
                .getTokenAvailable(token, _logic);

            if (amount > 0) {
                // Check token has been inited
                require(vTokens[token] != address(0), "F2");

                // Take token from storage
                ILogicContract(_logic).takeTokenFromStorage(amount, token);

                // Mint
                ILogicContract(_logic).mint(vTokens[token], amount);
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Build Strategy
     * @param usdAmount Amount of USD to borrow : decimal = 18
     */
    function build(uint256 usdAmount) external onlyOwnerAndAdmin {
        // Get Farming Pairs, Percentages
        FarmingPair[] memory reserves = ILendBorrowFarmingPair(farmingPair)
            .getFarmingPairs();

        // Check percentage and farmingPair are matched
        ILendBorrowFarmingPair(farmingPair).checkPercentages();

        uint256 index;

        // Array of token borrow
        address[] memory arrBorrowToken = new address[](reserves.length * 2);
        uint256[] memory arrBorrowAmount = new uint256[](reserves.length * 2);

        // Array of token amount for addLiquidity
        uint256[] memory arrToken0Amount = new uint256[](reserves.length);
        uint256[] memory arrToken1Amount = new uint256[](reserves.length);
        uint256 pos;
        uint256 posBNB;

        // For each pair, calculate build, borrow amount
        for (index = 0; index < reserves.length; ) {
            // Calculate the build, borrow amount
            (
                arrToken0Amount[index],
                arrToken1Amount[index]
            ) = _calcBorrowAmount(
                reserves[index],
                (usdAmount * reserves[index].percentage) / 10000
            );

            // Store borrow token and borrow amount in array
            uint256 i;
            for (i = 0; i < pos + 1; i++) {
                if (arrBorrowToken[i] == reserves[index].xTokenA) {
                    arrBorrowAmount[i] += arrToken0Amount[index];
                    break;
                }
            }
            if (i == pos + 1) {
                arrBorrowToken[pos] = reserves[index].xTokenA;
                arrBorrowAmount[pos] = arrToken0Amount[index];
                pos++;
            }

            for (i = 0; i < pos + 1; i++) {
                if (arrBorrowToken[i] == reserves[index].xTokenB) {
                    arrBorrowAmount[i] += arrToken1Amount[index];
                    break;
                }
            }
            if (i == pos + 1) {
                arrBorrowToken[pos] = reserves[index].xTokenB;
                arrBorrowAmount[pos] = arrToken1Amount[index];
                if (reserves[index].tokenB == address(0)) posBNB = pos;
                pos++;
            }

            unchecked {
                ++index;
            }
        }

        address _logic = logic;

        // Borrow Tokens
        for (index = 0; index < pos; ) {
            if (arrBorrowAmount[index] > 0) {
                uint256 balance = index == posBNB
                    ? address(_logic).balance
                    : IERC20Upgradeable(
                        IXToken(arrBorrowToken[index]).underlying()
                    ).balanceOf(_logic);

                uint256 borrowAmount = ILogicContract(_logic).borrow(
                    arrBorrowToken[index],
                    arrBorrowAmount[index] - balance,
                    0
                );

                require(borrowAmount == 0, "F13"); // Borrow should be successed
            }

            unchecked {
                ++index;
            }
        }

        // Add Liquidity, Deposit
        for (index = 0; index < reserves.length; ) {
            // Add Liquidity
            uint256 liquidity;
            if (reserves[index].tokenB == address(0)) {
                // If tokenB is BNB
                (, , liquidity) = ILogicContract(_logic).addLiquidityETH(
                    reserves[index].swap,
                    reserves[index].tokenA,
                    arrToken0Amount[index],
                    arrToken1Amount[index],
                    0,
                    0,
                    block.timestamp + 1 hours
                );
            } else {
                // If tokenA, tokenB are not BNB
                (, , liquidity) = ILogicContract(_logic).addLiquidity(
                    reserves[index].swap,
                    reserves[index].tokenA,
                    reserves[index].tokenB,
                    arrToken0Amount[index],
                    arrToken1Amount[index],
                    0,
                    0,
                    block.timestamp + 1 hours
                );
            }

            // Deposit to masterchief
            ILogicContract(_logic).deposit(
                reserves[index].swapMaster,
                reserves[index].poolID,
                liquidity
            );

            unchecked {
                ++index;
            }
        }

        emit Build(usdAmount);
    }

    /**
     * @notice Destory Strategy
     * @param _percentage % that sould be destoried for all pairs < 10000
     */
    function destroy(uint256 _percentage) public onlyOwnerAndAdmin {
        require(_percentage <= 10000, "F11");

        // Get Farming Pairs, Percentages
        FarmingPair[] memory reserves = ILendBorrowFarmingPair(farmingPair)
            .getFarmingPairs();

        // Calculate the total amount of each pair
        address _logic = logic;
        uint256 count = reserves.length;
        uint256 index;

        // For each pair, process the build
        for (index = 0; index < count; ) {
            FarmingPair memory reserve = reserves[index];

            (uint256 depositedLp, ) = IMasterChef(reserve.swapMaster).userInfo(
                reserve.poolID,
                _logic
            );

            // Withdraw LP token from masterchef and repayborrow
            if (depositedLp > 0)
                _withdrawAndRepay(reserve, (depositedLp * _percentage) / 10000);

            unchecked {
                ++index;
            }
        }

        emit Destroy(_percentage);
    }

    /**
     * @notice Destory Strategy All
     */
    function destroyAll() public onlyOwnerAndAdmin {
        // Get Farming Pairs, Percentages
        FarmingPair[] memory reserves = ILendBorrowFarmingPair(farmingPair)
            .getFarmingPairs();

        // Calculate the total amount of each pair
        address _logic = logic;
        uint256 count = reserves.length;
        uint256 index;

        // Claim and swap rewards to BNB
        _claimInternal(0);

        // Destory all pairs
        destroy(10000);

        // For each pair Swap remained tokens to BNB
        uint256 deadline = block.timestamp + 100;
        uint256 balance;
        for (index = 0; index < count; ) {
            FarmingPair memory reserve = reserves[index];

            // Check TokenA
            balance = IERC20Upgradeable(reserve.tokenA).balanceOf(_logic);
            if (balance > 0) {
                ILogicContract(_logic).swapExactTokensForETH(
                    reserve.swap,
                    balance,
                    0,
                    reserve.pathTokenA2BNB,
                    deadline
                );
            }

            // Check TokenB
            if (reserve.tokenB != address(0)) {
                balance = IERC20Upgradeable(reserve.tokenB).balanceOf(_logic);
                if (balance > 0) {
                    ILogicContract(_logic).swapExactTokensForETH(
                        reserve.swap,
                        balance,
                        0,
                        reserve.pathTokenB2BNB,
                        deadline
                    );
                }
            }

            unchecked {
                ++index;
            }
        }

        // For each pair if there is unpaid borrow, repay it using BNB
        uint256 borrowAmount;
        uint256 length;
        address[] memory pathToBNBToToken;
        uint256 i;
        for (index = 0; index < count; ) {
            FarmingPair memory reserve = reserves[index];

            // For TokenA
            borrowAmount = IXToken(reserve.xTokenA).borrowBalanceCurrent(
                _logic
            );
            if (borrowAmount > 0) {
                // Get path BNB to token
                length = reserve.pathTokenA2BNB.length;
                pathToBNBToToken = new address[](length);
                for (i = 0; i < length; i++)
                    pathToBNBToToken[i] = reserve.pathTokenA2BNB[
                        length - i - 1
                    ];

                // Swap BNB for token
                balance = address(_logic).balance;
                ILogicContract(_logic).swapETHForExactTokens(
                    reserve.swap,
                    balance,
                    borrowAmount,
                    pathToBNBToToken,
                    deadline
                );

                // Repayborrow
                ILogicContract(_logic).repayBorrow(
                    reserve.xTokenA,
                    borrowAmount
                );
            }

            // For TokenB
            borrowAmount = IXToken(reserve.xTokenB).borrowBalanceCurrent(
                _logic
            );
            if (borrowAmount > 0) {
                // Get path BNB to token
                if (reserve.tokenB != address(0)) {
                    length = reserve.pathTokenB2BNB.length;
                    pathToBNBToToken = new address[](length);
                    for (i = 0; i < length; i++)
                        pathToBNBToToken[i] = reserve.pathTokenB2BNB[
                            length - i - 1
                        ];

                    // Swap BNB for token
                    balance = address(_logic).balance;
                    ILogicContract(_logic).swapETHForExactTokens(
                        reserve.swap,
                        balance,
                        borrowAmount,
                        pathToBNBToToken,
                        deadline
                    );
                }

                // Repayborrow
                ILogicContract(_logic).repayBorrow(
                    reserve.xTokenB,
                    borrowAmount
                );
            }

            unchecked {
                ++index;
            }
        }

        // Swap all available BNB
        uint256 balanceBNBNew = address(_logic).balance;
        if (balanceBNBNew > 0) {
            _sendRewardsToStorage(balanceBNBNew);
        }

        emit DestroyAll();
    }

    /**
     * @notice Destory All, RedeemUnderlying, return all Tokens to storage
     */
    function returnAllTokensToStorage() external onlyOwnerAndAdmin {
        address _logic = logic;

        // Destroy All
        destroyAll();

        // Get all tokens in storage
        address[] memory tokens = IMultiLogicProxy(multiLogicProxy)
            .getUsedTokensStorage();
        uint256 length = tokens.length;

        // For each token
        for (uint256 i = 0; i < length; ) {
            address token = tokens[i];

            // Get token balance registered to MultiLogic
            uint256 balance = IMultiLogicProxy(multiLogicProxy).getTokenBalance(
                token,
                _logic
            );

            if (balance > 0) {
                // Check token has been inited
                require(vTokens[token] != address(0), "F2");

                // Calculate redeem amount
                uint256 redeemAmount = balance;
                if (token != address(0))
                    redeemAmount -= IERC20Upgradeable(token).balanceOf(_logic); // Logic doesn't have BNB after destroyAll();

                // RedeemUnderlying
                if (redeemAmount > 0)
                    ILogicContract(_logic).redeemUnderlying(
                        vTokens[token],
                        redeemAmount
                    );

                // Return existing Token To Storage
                ILogicContract(_logic).returnTokenToStorage(balance, token);
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Claim Rewards and send BLID to Storage
     * @param mode 0 : all, 1 : Venus only, 2 : Farm only
     */
    function claimRewards(uint8 mode) external onlyOwnerAndAdmin {
        require(pathToSwapBNBToBLID.length >= 2, "F15");

        address _logic = logic;

        // Keep BNB balance
        uint256 balanceBNBOld = address(_logic).balance;

        // Claim Rewards token
        _claimInternal(mode);

        // Check rewards BNB
        uint256 balanceBNBNew = address(_logic).balance;

        if (balanceBNBNew > balanceBNBOld) {
            // Convert BNB to BLID and send to storage
            uint256 amountBLID = _sendRewardsToStorage(
                balanceBNBNew - balanceBNBOld
            );

            emit ClaimRewards(amountBLID);
        }
    }

    /**
     * @notice multicall to Logic
     */
    function multicall(
        bytes[] memory callDatas
    )
        public
        onlyOwnerAndAdmin
        returns (uint256 blockNumber, bytes[] memory returnData)
    {
        blockNumber = block.number;
        uint256 length = callDatas.length;
        returnData = new bytes[](length);
        for (uint256 i = 0; i < length; ) {
            (bool success, bytes memory ret) = address(logic).call(
                callDatas[i]
            );
            require(success, "F99");
            returnData[i] = ret;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Frees up tokens for the user, but Storage doesn't transfer token for the user,
     * only Storage can this function, after calling this function Storage transfer
     * from Logic to user token.
     * @param _amount Amount of token
     * @param token Address of token
     */
    function releaseToken(
        uint256 _amount,
        address token
    ) external payable onlyMultiLogicProxy {
        require(vTokens[token] != address(0), "F2");

        // Get Farming Pairs
        FarmingPair[] memory reserves = ILendBorrowFarmingPair(farmingPair)
            .getFarmingPairs();

        uint256 takeFromVenus = 0;
        uint256 length = reserves.length;
        address _logic = logic;
        address vToken = vTokens[token];

        // check logic balance
        uint256 amount;

        if (token == address(0)) {
            amount = address(_logic).balance;
        } else {
            amount = IERC20Upgradeable(token).balanceOf(_logic);
        }
        if (amount >= _amount) {
            if (token == address(0)) {
                ILogicContract(_logic).returnETHToMultiLogicProxy(_amount);
            }

            emit ReleaseToken(token, _amount);
            return;
        }

        // decrease redeemAmount
        amount = _amount - amount;

        //loop by reserves lp token
        for (uint256 i = 0; i < length; ) {
            address[] memory path = ILendBorrowFarmingPair(farmingPair)
                .findPath(i, token); // get path for router
            FarmingPair memory reserve = reserves[i];
            uint256 lpAmount = ILendBorrowFarmingPair(farmingPair)
                .getPriceFromTokenToLp(
                    reserve.lpToken,
                    amount - takeFromVenus,
                    token,
                    reserve.swap,
                    path
                ); //get amount of lp token that need for reedem liqudity

            //get how many deposited to farming
            (uint256 depositedLp, ) = IMasterChef(reserve.swapMaster).userInfo(
                reserve.poolID,
                _logic
            );
            if (depositedLp == 0) continue;
            // if deposited LP tokens don't enough  for repay borrow and for reedem token then only repay
            // borow and continue loop, else repay borow, reedem token and break loop
            if (lpAmount >= depositedLp) {
                takeFromVenus += ILendBorrowFarmingPair(farmingPair)
                    .getPriceFromLpToToken(
                        reserve.lpToken,
                        depositedLp,
                        token,
                        reserve.swap,
                        path
                    );
                _withdrawAndRepay(reserve, depositedLp);
            } else {
                _withdrawAndRepay(reserve, lpAmount);

                // get supplied token and break loop
                ILogicContract(_logic).redeemUnderlying(vToken, amount);

                if (token == address(0)) {
                    ILogicContract(_logic).returnETHToMultiLogicProxy(amount);
                }
                emit ReleaseToken(token, _amount);
                return;
            }

            unchecked {
                ++i;
            }
        }

        //try get supplied token
        ILogicContract(_logic).redeemUnderlying(vToken, amount);
        //if get money
        if (
            token != address(0) &&
            IERC20Upgradeable(token).balanceOf(_logic) >= _amount
        ) {
            emit ReleaseToken(token, _amount);
            return;
        }

        if (token == address(0) && address(_logic).balance >= _amount) {
            ILogicContract(_logic).returnETHToMultiLogicProxy(amount);
            emit ReleaseToken(token, _amount);
            return;
        }

        // redeem remaind vToken
        uint256 vTokenBalance; // balance of cToken
        uint256 exchangeRateMantissa; //conversion rate from cToken to token

        // Get vToken information and redeem
        (, vTokenBalance, , exchangeRateMantissa) = IXToken(vToken)
            .getAccountSnapshot(_logic);

        if (vTokenBalance > 0) {
            uint256 supplyBalance = (vTokenBalance * exchangeRateMantissa) /
                10 ** 18;

            ILogicContract(_logic).redeemUnderlying(vToken, supplyBalance);
        }

        if (
            token != address(0) &&
            IERC20Upgradeable(token).balanceOf(_logic) >= _amount
        ) {
            emit ReleaseToken(token, _amount);
            return;
        }

        if (token == address(0) && address(_logic).balance >= _amount) {
            ILogicContract(_logic).returnETHToMultiLogicProxy(amount);
            emit ReleaseToken(token, _amount);
            return;
        }

        revert("no money");
    }

    /*** Prive Function ***/

    /**
     * Calculate borrow amount, build amount for each pair
     * @param reserve FarmingPair
     * @param borrowUSDAmount required borrow amount in USD for this pair
     * @return token0Amount token0 build amount
     * @return token1Amount token1 build amount
     */
    function _calcBorrowAmount(
        FarmingPair memory reserve,
        uint256 borrowUSDAmount
    ) private view returns (uint256 token0Amount, uint256 token1Amount) {
        address _comptroller = comptroller;
        uint256 balance0;
        uint256 balance1;

        // Token convertion rate to USD : decimal = 18 + (18 - token.decimals)
        uint256 token0Price = IOracleVenus(
            IComptrollerVenus(_comptroller).oracle()
        ).getUnderlyingPrice(reserve.xTokenA);
        uint256 token1Price = IOracleVenus(
            IComptrollerVenus(_comptroller).oracle()
        ).getUnderlyingPrice(reserve.xTokenB);

        // get Reserves
        (balance0, balance1, ) = IPancakePair(reserve.lpToken).getReserves();

        // Calculate Reserves in USD Amount
        balance0 =
            ((
                IPancakePair(reserve.lpToken).token0() == reserve.tokenA
                    ? balance0
                    : balance1
            ) * token0Price) /
            (10 ** 18);
        balance1 =
            ((
                IPancakePair(reserve.lpToken).token0() == reserve.tokenA
                    ? balance1
                    : balance0
            ) * token1Price) /
            (10 ** 18);

        // Calculate build amount for addToLiquidity
        token0Amount =
            (borrowUSDAmount * (10 ** 18) * balance0) /
            (token0Price * (balance0 + balance1));
        token1Amount =
            (borrowUSDAmount * (10 ** 18) * balance1) /
            (token1Price * (balance0 + balance1));
    }

    /**
     * @notice Claim rewards and swap to BNB
     * @param mode 0 : all, 1 : Venus only, 2 : Farm only
     */
    function _claimInternal(uint8 mode) private {
        require(pathToSwapRewardsToBNB.length >= 2, "F14");

        address _logic = logic;
        uint256 _lendingTokensCount = lendingTokensCount;
        uint256 index;
        uint256 deadline = block.timestamp + 100;
        uint256 balance;

        // claim XVS
        if (mode == 0 || mode == 1) {
            address[] memory vTokensToClaim = new address[](
                _lendingTokensCount
            );
            for (index = 0; index < _lendingTokensCount; ) {
                vTokensToClaim[index] = lendingTokens[index];

                unchecked {
                    ++index;
                }
            }
            ILogicContract(_logic).claim(vTokensToClaim, 0);

            // Swap XVS to BNB
            balance = IERC20Upgradeable(rewardsToken).balanceOf(_logic);
            if (balance > 0) {
                ILogicContract(_logic).swapExactTokensForETH(
                    rewardsSwapRouter,
                    balance,
                    0,
                    pathToSwapRewardsToBNB,
                    deadline
                );
            }
        }

        // For each pair, claim CAKE/BSW
        if (mode == 0 || mode == 2) {
            // Get Farming Pairs
            FarmingPair[] memory reserves = ILendBorrowFarmingPair(farmingPair)
                .getFarmingPairs();
            uint256 count = reserves.length;

            for (index = 0; index < count; ) {
                FarmingPair memory reserve = reserves[index];

                // call MasterChef.deposit(0);
                ILogicContract(_logic).deposit(
                    reserve.swapMaster,
                    reserve.poolID,
                    0
                );

                // Swap rewards token to BNB
                balance = IERC20Upgradeable(reserve.rewardsToken).balanceOf(
                    _logic
                );
                if (balance > 0) {
                    ILogicContract(_logic).swapExactTokensForETH(
                        reserve.swap,
                        balance,
                        0,
                        reserve.pathRewards2BNB,
                        deadline
                    );
                }

                unchecked {
                    ++index;
                }
            }
        }
    }

    /**
     * @notice Swap BNB to BLID and send to storage
     * @param amountBNB reward BNB amount
     * @return amountBLID reward BLID amount
     */
    function _sendRewardsToStorage(
        uint256 amountBNB
    ) internal returns (uint256 amountBLID) {
        address _logic = logic;

        // Convert BNB to BLID
        if (amountBNB > 0) {
            uint256 amountOutMin = 0;
            uint256 deadline = block.timestamp + 100;

            ILogicContract(_logic).swapExactETHForTokens(
                rewardsSwapRouter,
                amountBNB,
                amountOutMin,
                pathToSwapBNBToBLID,
                deadline
            );

            // Add BLID earn to storage
            amountBLID = IERC20Upgradeable(blid).balanceOf(_logic);
            if (amountBLID > 0)
                ILogicContract(_logic).addEarnToStorage(amountBLID);
        }
    }

    /**
     * @notice Withdraw lp token from farms and repay borrow
     */
    function _withdrawAndRepay(
        FarmingPair memory reserve,
        uint256 lpAmount
    ) private {
        ILogicContract(logic).withdraw(
            reserve.swapMaster,
            reserve.poolID,
            lpAmount
        );
        if (reserve.tokenB == address(0)) {
            //if tokenB is BNB
            _repayBorrowBNBandToken(
                reserve.swap,
                reserve.tokenA,
                reserve.xTokenB,
                reserve.xTokenA,
                lpAmount
            );
        } else {
            //if token A and B is not BNB
            _repayBorrowOnlyTokens(
                reserve.swap,
                reserve.tokenA,
                reserve.tokenB,
                reserve.xTokenA,
                reserve.xTokenB,
                lpAmount
            );
        }
    }

    /**
     * @notice Repay borrow when in farms  erc20 and BNB
     */
    function _repayBorrowBNBandToken(
        address swap,
        address tokenB,
        address xTokenA,
        address xTokenB,
        uint256 lpAmount
    ) private {
        address _logic = logic;

        (uint256 amountToken, uint256 amountETH) = ILogicContract(_logic)
            .removeLiquidityETH(
                swap,
                tokenB,
                lpAmount,
                0,
                0,
                block.timestamp + 1 days
            );
        {
            uint256 totalBorrow = IXTokenETH(xTokenA).borrowBalanceCurrent(
                _logic
            );
            if (totalBorrow >= amountETH) {
                ILogicContract(_logic).repayBorrow(xTokenA, amountETH);
            } else {
                ILogicContract(_logic).repayBorrow(xTokenA, totalBorrow);
            }

            totalBorrow = IXToken(xTokenB).borrowBalanceCurrent(_logic);
            if (totalBorrow >= amountToken) {
                ILogicContract(_logic).repayBorrow(xTokenB, amountToken);
            } else {
                ILogicContract(_logic).repayBorrow(xTokenB, totalBorrow);
            }
        }
    }

    /**
     * @notice Repay borrow when in farms only erc20
     */
    function _repayBorrowOnlyTokens(
        address swap,
        address tokenA,
        address tokenB,
        address xTokenA,
        address xTokenB,
        uint256 lpAmount
    ) private {
        address _logic = logic;

        (uint256 amountA, uint256 amountB) = ILogicContract(_logic)
            .removeLiquidity(
                swap,
                tokenA,
                tokenB,
                lpAmount,
                0,
                0,
                block.timestamp + 1 days
            );
        {
            uint256 totalBorrow = IXToken(xTokenA).borrowBalanceCurrent(_logic);
            if (totalBorrow >= amountA) {
                ILogicContract(_logic).repayBorrow(xTokenA, amountA);
            } else {
                ILogicContract(_logic).repayBorrow(xTokenA, totalBorrow);
            }

            totalBorrow = IXToken(xTokenB).borrowBalanceCurrent(_logic);
            if (totalBorrow >= amountB) {
                ILogicContract(_logic).repayBorrow(xTokenB, amountB);
            } else {
                ILogicContract(_logic).repayBorrow(xTokenB, totalBorrow);
            }
        }
    }
}