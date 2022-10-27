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

contract LendBorrowFarmStrategy is LogicUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct ReserveLiquidity {
        address tokenA;
        address tokenB;
        address xTokenA;
        address xTokenB;
        address swap;
        address swapMaster;
        address lpToken;
        uint256 poolID;
        address[][] path;
    }

    ReserveLiquidity[] reserves;

    address private blid;
    address private comptroller;
    address private rewardsSwapRouter;
    address private rewardsToken;
    address private logic;
    address private multiLogicProxy;

    bool private rewardsInit;

    mapping(address => address) private vTokens;

    event SetBLID(address _blid);
    event SetMultiLogicProxy(address multiLogicProxy);
    event Init(address token);
    event ReleaseToken(address token, uint256 amount);

    function __LendBorrowFarmStrategy_init(
        address _comptroller,
        address _rewardsSwapRouter,
        address _rewardsToken,
        address _logic
    ) public initializer {
        LogicUpgradeable.initialize();
        comptroller = _comptroller;
        rewardsSwapRouter = _rewardsSwapRouter;
        rewardsToken = _rewardsToken;
        logic = _logic;
        rewardsInit = false;
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
        require(blid == address(0), "F3");
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
     * @notice Add XToken in Contract and approve token
     * Approve token for storage, venus, pancakeswap/apeswap/biswap router,
     * and pancakeswap/apeswap/biswap master(Main Staking contract)
     * Approve rewardsToken for swap
     * @param token Address of underlying token
     * @param vToken Address of vToken
     */
    function init(address token, address vToken) public onlyOwner {
        require(vTokens[token] == address(0), "F6");

        address _logic = logic;
        vTokens[token] = vToken;

        // Add token/oToken to Logic
        ILogicContract(_logic).addXTokens(token, vToken, 0);

        // Entermarkets with token/vtoken
        address[] memory tokens = new address[](1);
        tokens[0] = vToken;
        ILogicContract(_logic).enterMarkets(tokens, 0);

        // Approve rewards token
        if (!rewardsInit) {
            ILogicContract(_logic).approveTokenForSwap(rewardsToken);

            rewardsInit = true;
        }

        emit Init(token);
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

            // Check token has been inited
            require(vTokens[token] != address(0), "F2");

            // Get available amount
            uint256 amount = IMultiLogicProxy(multiLogicProxy).getTokenBalance(
                token,
                _logic
            );

            // Take token from storage
            ILogicContract(_logic).takeTokenFromStorage(amount, token);

            // Mint
            ILogicContract(_logic).mint(vTokens[token], amount);

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
    function releaseToken(uint256 _amount, address token)
        external
        payable
        onlyMultiLogicProxy
    {
        require(vTokens[token] != address(0), "F2");

        uint256 takeFromVenus = 0;
        uint256 length = reserves.length;
        address _logic = logic;
        uint256 amount = _amount;
        address vToken = vTokens[token];

        // check logic balance
        uint256 balance;

        if (token == address(0)) {
            balance = address(_logic).balance;
        } else {
            balance = IERC20Upgradeable(token).balanceOf(_logic);
        }
        if (balance >= amount) {
            if (token == address(0)) {
                ILogicContract(_logic).returnETHToMultiLogicProxy(amount);
            }

            emit ReleaseToken(token, _amount);
            return;
        }

        // decrease redeemAmount
        amount -= balance;

        //loop by reserves lp token
        for (uint256 i = 0; i < length; ) {
            address[] memory path = findPath(i, token); // get path for router
            ReserveLiquidity memory reserve = reserves[i];
            uint256 lpAmount = getPriceFromTokenToLp(
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
                takeFromVenus += getPriceFromLpToToken(
                    reserve.lpToken,
                    depositedLp,
                    token,
                    reserve.swap,
                    path
                );
                withdrawAndRepay(reserve, depositedLp);
            } else {
                withdrawAndRepay(reserve, lpAmount);

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
        uint256 borrowBalance; // balance of borrowed amount
        uint256 exchangeRateMantissa; //conversion rate from cToken to token

        // Get vToken information and redeem
        (, vTokenBalance, borrowBalance, exchangeRateMantissa) = IXToken(vToken)
            .getAccountSnapshot(_logic);

        if (vTokenBalance > 0) {
            uint256 supplyBalance = (vTokenBalance * exchangeRateMantissa) /
                10**18;

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

    /**
     * @notice Add reserve staked lp token to end list
     * @param reserveLiquidity Data is about staked lp in farm
     */
    function addReserveLiquidity(ReserveLiquidity memory reserveLiquidity)
        external
        onlyOwnerAndAdmin
    {
        reserves.push(reserveLiquidity);
    }

    /**
     * @notice Add reserve staked lp token list to end list
     * @param reserveLiquidityList Data is about staked lp in farm
     */
    function addReserveLiquidityList(
        ReserveLiquidity[] memory reserveLiquidityList
    ) external onlyOwnerAndAdmin {
        uint256 length = reserveLiquidityList.length;
        for (uint256 i = 0; i < length; ) {
            reserves.push(reserveLiquidityList[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Delete last ReserveLiquidity from list of ReserveLiquidity
     */
    function deleteLastReserveLiquidity() external onlyOwnerAndAdmin {
        reserves.pop();
    }

    /**
     * @notice Delete a number of last ReserveLiquidity from list of ReserveLiquidity
     * @param length number of reservedLiquidity to be deleted
     */
    function deleteLastReserveLiquidityList(uint256 length)
        external
        onlyOwnerAndAdmin
    {
        for (uint256 i = 0; i < length; ) {
            reserves.pop();

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Return count reserves staked lp tokens for return users their tokens.
     */
    function getReservesCount() external view returns (uint256) {
        return reserves.length;
    }

    /**
     * @notice Return reserves staked lp tokens for return user their tokens. return ReserveLiquidity
     */
    function getReserve(uint256 id)
        external
        view
        returns (ReserveLiquidity memory)
    {
        return reserves[id];
    }

    /**
     * @notice multicall to Logic
     */
    function multicall(bytes[] memory callDatas)
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

    /*** Prive Function ***/

    /**
     * @notice Withdraw lp token from farms and repay borrow
     */
    function withdrawAndRepay(ReserveLiquidity memory reserve, uint256 lpAmount)
        private
    {
        ILogicContract(logic).withdraw(
            reserve.swapMaster,
            reserve.poolID,
            lpAmount
        );
        if (reserve.tokenA == address(0) || reserve.tokenB == address(0)) {
            //if tokenA is BNB
            if (reserve.tokenA == address(0)) {
                repayBorrowBNBandToken(
                    reserve.swap,
                    reserve.tokenB,
                    reserve.xTokenA,
                    reserve.xTokenB,
                    lpAmount
                );
            }
            //if tokenB is BNB
            else {
                repayBorrowBNBandToken(
                    reserve.swap,
                    reserve.tokenA,
                    reserve.xTokenB,
                    reserve.xTokenA,
                    lpAmount
                );
            }
        }
        //if token A and B is not BNB
        else {
            repayBorrowOnlyTokens(
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
    function repayBorrowBNBandToken(
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
    function repayBorrowOnlyTokens(
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

    /*** Prive View Function ***/
    /**
     * @notice Convert Lp Token To Token
     */
    function getPriceFromLpToToken(
        address lpToken,
        uint256 value,
        address token,
        address swap,
        address[] memory path
    ) private view returns (uint256) {
        //make price returned not affected by slippage rate
        uint256 totalSupply = IERC20Upgradeable(lpToken).totalSupply();
        address token0 = IPancakePair(lpToken).token0();
        uint256 totalTokenAmount = IERC20Upgradeable(token0).balanceOf(
            lpToken
        ) * (2);
        uint256 amountIn = (value * totalTokenAmount) / (totalSupply);

        if (amountIn == 0 || token0 == token) {
            return amountIn;
        }

        uint256[] memory price = IPancakeRouter01(swap).getAmountsOut(
            amountIn,
            path
        );
        return price[price.length - 1];
    }

    /**
     * @notice Convert Token To Lp Token
     */
    function getPriceFromTokenToLp(
        address lpToken,
        uint256 value,
        address token,
        address swap,
        address[] memory path
    ) private view returns (uint256) {
        //make price returned not affected by slippage rate
        uint256 totalSupply = IERC20Upgradeable(lpToken).totalSupply();
        address token0 = IPancakePair(lpToken).token0();
        uint256 totalTokenAmount = IERC20Upgradeable(token0).balanceOf(lpToken);

        if (token0 == token) {
            return (value * (totalSupply)) / (totalTokenAmount) / 2;
        }

        uint256[] memory price = IPancakeRouter01(swap).getAmountsOut(
            (1 gwei),
            path
        );
        return
            (value * (totalSupply)) /
            ((price[price.length - 1] * 2 * totalTokenAmount) / (1 gwei));
    }

    /**
     * @notice FindPath for swap router
     */
    function findPath(uint256 id, address token)
        private
        view
        returns (address[] memory path)
    {
        ReserveLiquidity memory reserve = reserves[id];
        uint256 length = reserve.path.length;

        for (uint256 i = 0; i < length; ) {
            if (reserve.path[i][reserve.path[i].length - 1] == token) {
                return reserve.path[i];
            }
            unchecked {
                ++i;
            }
        }
    }
}