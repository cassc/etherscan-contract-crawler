// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

// Uncomment if needed.
// import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../libraries/UniswapOracle.sol";
import "../libraries/FixedPoints.sol";

import "../multicall.sol";

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

/// @title Simple math library for Max and Min.
library Math {
    function max(int24 a, int24 b) internal pure returns (int24) {
        return a >= b ? a : b;
    }

    function min(int24 a, int24 b) internal pure returns (int24) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function tickFloor(int24 tick, int24 tickSpacing)
        internal
        pure
        returns (int24)
    {
        int24 c = tick / tickSpacing;
        if (tick < 0 && tick % tickSpacing != 0) {
            c = c - 1;
        }
        c = c * tickSpacing;
        return c;
    }

    function tickUpper(int24 tick, int24 tickSpacing)
        internal
        pure
        returns (int24)
    {
        int24 c = tick / tickSpacing;
        if (tick > 0 && tick % tickSpacing != 0) {
            c = c + 1;
        }
        c = c * tickSpacing;
        return c;
    }
}

/// @title Uniswap V3 Liquidity Mining Main Contract
contract MiningOneSideBoost is Ownable, Multicall, ReentrancyGuard {
    // using Math for int24;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    using UniswapOracle for address;

    int24 internal constant TICK_MAX = 500000;
    int24 internal constant TICK_MIN = -500000;

    struct PoolInfo {
        address token0;
        address token1;
        uint24 fee;
    }

    bool uniIsETH;

    address uniToken;
    address lockToken;

    /// @dev Contract of the uniV3 Nonfungible Position Manager.
    address uniV3NFTManager;
    address uniFactory;
    address swapPool;
    PoolInfo public rewardPool;

    /// @dev Last block number that the accRewardRerShare is touched.
    uint256 lastTouchBlock;

    /// @dev The block number when NFT mining rewards starts/ends.
    uint256 startBlock;
    uint256 endBlock;

    uint256 lockBoostMultiplier;

    struct RewardInfo {
        /// @dev Contract of the reward erc20 token.
        address rewardToken;
        /// @dev who provides reward
        address provider;
        /// @dev Accumulated Reward Tokens per share, times Q128.
        uint256 accRewardPerShare;
        /// @dev Reward amount for each block.
        uint256 rewardPerBlock;
    }

    mapping(uint256 => RewardInfo) public rewardInfos;
    uint256 public rewardInfosLen;

    /// @dev Store the owner of the NFT token
    mapping(uint256 => address) public owners;
    /// @dev The inverse mapping of owners.
    mapping(address => EnumerableSet.UintSet) private tokenIds;

    /// @dev Record the status for a certain token for the last touched time.
    struct TokenStatus {
        uint256 nftId;
        // bool isDepositWithNFT;
        uint128 uniLiquidity;
        uint256 lockAmount;
        uint256 vLiquidity;
        uint256 validVLiquidity;
        uint256 nIZI;
        uint256 lastTouchBlock;
        uint256[] lastTouchAccRewardPerShare;
    }

    mapping(uint256 => TokenStatus) public tokenStatus;

    receive() external payable {}

    /// @dev token to lock, 0 for not boost
    IERC20 public iziToken;
    /// @dev current total nIZI.
    uint256 public totalNIZI;

    /// @dev Current total virtual liquidity.
    uint256 public totalVLiquidity;
    /// @dev Current total lock token
    uint256 public totalLock;

    // Events
    event Deposit(address indexed user, uint256 tokenId, uint256 nIZI);
    event Withdraw(address indexed user, uint256 tokenId);
    event CollectReward(address indexed user, uint256 tokenId, address token, uint256 amount);
    event ModifyEndBlock(uint256 endBlock);
    event ModifyRewardPerBlock(address indexed rewardToken, uint256 rewardPerBlock);
    event ModifyProvider(address indexed rewardToken, address provider);

    function _setRewardPool(
        address _uniToken,
        address _lockToken,
        uint24 fee
    ) internal {
        address token0;
        address token1;
        if (_uniToken < _lockToken) {
            token0 = _uniToken;
            token1 = _lockToken;
        } else {
            token0 = _lockToken;
            token1 = _uniToken;
        }
        rewardPool.token0 = token0;
        rewardPool.token1 = token1;
        rewardPool.fee = fee;
    }

    struct PoolParams {
        address uniV3NFTManager;
        address uniTokenAddr;
        address lockTokenAddr;
        uint24 fee;
    }

    constructor(
        PoolParams memory poolParams,
        RewardInfo[] memory _rewardInfos,
        uint256 _lockBoostMultiplier,
        address iziTokenAddr,
        uint256 _startBlock,
        uint256 _endBlock
    ) {
        uniV3NFTManager = poolParams.uniV3NFTManager;

        _setRewardPool(
            poolParams.uniTokenAddr,
            poolParams.lockTokenAddr,
            poolParams.fee
        );

        address weth = INonfungiblePositionManager(uniV3NFTManager).WETH9();
        require(weth != poolParams.lockTokenAddr, "WETH NOT SUPPORT");
        uniFactory = INonfungiblePositionManager(uniV3NFTManager).factory();

        uniToken = poolParams.uniTokenAddr;

        uniIsETH = (uniToken == weth);
        lockToken = poolParams.lockTokenAddr;

        IERC20(uniToken).safeApprove(uniV3NFTManager, type(uint256).max);

        swapPool = IUniswapV3Factory(uniFactory).getPool(
            lockToken,
            uniToken,
            poolParams.fee
        );
        require(swapPool != address(0), "NO UNI POOL");

        rewardInfosLen = _rewardInfos.length;
        require(rewardInfosLen > 0, "NO REWARD");
        require(rewardInfosLen < 3, "AT MOST 2 REWARDS");

        for (uint256 i = 0; i < rewardInfosLen; i++) {
            rewardInfos[i] = _rewardInfos[i];
            rewardInfos[i].accRewardPerShare = 0;
        }

        require(_lockBoostMultiplier > 0, "M>0");
        require(_lockBoostMultiplier < 4, "M<4");

        lockBoostMultiplier = _lockBoostMultiplier;

        // iziTokenAddr == 0 means not boost
        iziToken = IERC20(iziTokenAddr);

        startBlock = _startBlock;
        endBlock = _endBlock;

        lastTouchBlock = startBlock;

        totalVLiquidity = 0;
        totalNIZI = 0;
    }

    /// @notice Get the overall info for the mining contract.
    function getMiningContractInfo()
        external
        view
        returns (
            address uniToken_,
            address lockToken_,
            uint24 fee_,
            uint256 lockBoostMultiplier_,
            address iziTokenAddr_,
            uint256 lastTouchBlock_,
            uint256 totalVLiquidity_,
            uint256 totalLock_,
            uint256 totalNIZI_,
            uint256 startBlock_,
            uint256 endBlock_
        )
    {
        return (
            uniToken,
            lockToken,
            rewardPool.fee,
            lockBoostMultiplier,
            address(iziToken),
            lastTouchBlock,
            totalVLiquidity,
            totalLock,
            totalNIZI,
            startBlock,
            endBlock
        );
    }

    /// @dev compute amount of lockToken
    /// @param sqrtPriceX96 sqrtprice value viewed from uniswap pool
    /// @param uniAmount amount of uniToken user deposits
    ///    or amount computed corresponding to deposited uniswap NFT
    /// @return lockAmount amount of lockToken
    function _getLockAmount(uint160 sqrtPriceX96, uint256 uniAmount)
        private
        view
        returns (uint256 lockAmount)
    {
        // uniAmount is less than Q96, checked before
        uint256 precision = FixedPoints.Q96;
        uint256 sqrtPriceXP = sqrtPriceX96;

        // if price > 1, we discard the useless precision
        if (sqrtPriceX96 > FixedPoints.Q96) {
            precision = FixedPoints.Q32;
            // sqrtPriceXP <= Q96 after >> operation
            sqrtPriceXP = (sqrtPriceXP >> 64);
        }
        // priceXP <= Q160 if price >= 1
        // priceXP <= Q96  if price < 1
        uint256 priceXP = (sqrtPriceXP * sqrtPriceXP) / precision;
    
        if (priceXP > 0) {
            if (uniToken < lockToken) {
                // price is lockToken / uniToken
                lockAmount = (uniAmount * priceXP) / precision;
            } else {
                lockAmount = (uniAmount * precision) / priceXP;
            }
        } else {
             // in this case sqrtPriceXP <= Q48, precision = Q96
            if (uniToken < lockToken) {
                // price is lockToken / uniToken
                // lockAmount = uniAmount * sqrtPriceXP * sqrtPriceXP / precision / precision;
                // the above expression will always get 0
                lockAmount = 0;
            } else {
                lockAmount = uniAmount * precision / sqrtPriceXP / sqrtPriceXP; 
                // lockAmount is always < Q128, since sqrtPriceXP > Q32
                // we still add the require statement to double check
                require(lockAmount < FixedPoints.Q160, "TOO MUCH LOCK");
                lockAmount *= precision;
            }
        }
        require(lockAmount > 0, "LOCK 0");
    }

    /// @notice new a token status when touched.
    function _newTokenStatus(TokenStatus memory newTokenStatus) internal {
        tokenStatus[newTokenStatus.nftId] = newTokenStatus;
        TokenStatus storage t = tokenStatus[newTokenStatus.nftId];

        t.lastTouchBlock = lastTouchBlock;
        t.lastTouchAccRewardPerShare = new uint256[](rewardInfosLen);
        for (uint256 i = 0; i < rewardInfosLen; i++) {
            t.lastTouchAccRewardPerShare[i] = rewardInfos[i].accRewardPerShare;
        }
    }

    /// @notice update a token status when touched
    function _updateTokenStatus(
        uint256 tokenId,
        uint256 validVLiquidity,
        uint256 nIZI
    ) internal {
        TokenStatus storage t = tokenStatus[tokenId];

        // when not boost, validVL == vL
        t.validVLiquidity = validVLiquidity;
        t.nIZI = nIZI;

        t.lastTouchBlock = lastTouchBlock;
        for (uint256 i = 0; i < rewardInfosLen; i++) {
            t.lastTouchAccRewardPerShare[i] = rewardInfos[i].accRewardPerShare;
        }
    }

    /// @notice Update reward variables to be up-to-date.
    function _updateVLiquidity(uint256 vLiquidity, bool isAdd) internal {
        if (isAdd) {
            totalVLiquidity = totalVLiquidity + vLiquidity;
        } else {
            totalVLiquidity = totalVLiquidity - vLiquidity;
        }

        // max lockBoostMultiplier is 3
        require(totalVLiquidity <= FixedPoints.Q128 * 3, "TOO MUCH LIQUIDITY STAKED");
    }

    function _updateNIZI(uint256 nIZI, bool isAdd) internal {
        if (isAdd) {
            totalNIZI = totalNIZI + nIZI;
        } else {
            totalNIZI = totalNIZI - nIZI;
        }
    }

    /// @notice Update the global status.
    function _updateGlobalStatus() internal {
        if (block.number <= lastTouchBlock) {
            return;
        }
        if (lastTouchBlock >= endBlock) {
            return;
        }
        uint256 currBlockNumber = Math.min(block.number, endBlock);
        if (totalVLiquidity == 0) {
            lastTouchBlock = currBlockNumber;
            return;
        }

        for (uint256 i = 0; i < rewardInfosLen; i++) {
            // tokenReward < 2^25 * 2^64 * 2*10, 15 years, 1000 r/block
            uint256 tokenReward = (currBlockNumber - lastTouchBlock) * rewardInfos[i].rewardPerBlock;
            // tokenReward * Q128 < 2^(25 + 64 + 10 + 128)
            rewardInfos[i].accRewardPerShare = rewardInfos[i].accRewardPerShare + ((tokenReward * FixedPoints.Q128) / totalVLiquidity);
        }
        lastTouchBlock = currBlockNumber;
    }

    function _computeValidVLiquidity(uint256 vLiquidity, uint256 nIZI)
        internal
        view
        returns (uint256)
    {
        if (totalNIZI == 0) {
            return vLiquidity;
        }
        uint256 iziVLiquidity = (vLiquidity * 4 + (totalVLiquidity * nIZI * 6) / totalNIZI) / 10;
        return Math.min(iziVLiquidity, vLiquidity);
    }

    /// @dev get sqrtPrice of pool(uniToken/tokenSwap/fee)
    ///    and compute tick range converted from [TICK_MIN, PriceUni] or [PriceUni, TICK_MAX]
    /// @return sqrtPriceX96 current sqrtprice value viewed from uniswap pool, is a 96-bit fixed point number
    ///    note this value might mean price of lockToken/uniToken (if uniToken < lockToken)
    ///    or price of uniToken / lockToken (if uniToken > lockToken)
    /// @return tickLeft
    /// @return tickRight
    function _getPriceAndTickRange()
        private
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tickLeft,
            int24 tickRight
        )
    {
        (int24 avgTick, uint160 avgSqrtPriceX96, int24 currTick, ) = swapPool
            .getAvgTickPriceWithin2Hour();
        int24 tickSpacing = IUniswapV3Factory(uniFactory).feeAmountTickSpacing(
            rewardPool.fee
        );
        if (uniToken < lockToken) {
            // price is lockToken / uniToken
            // uniToken is X
            tickLeft = Math.max(currTick + 1, avgTick);
            tickRight = TICK_MAX;
            tickLeft = Math.tickUpper(tickLeft, tickSpacing);
            tickRight = Math.tickUpper(tickRight, tickSpacing);
        } else {
            // price is uniToken / lockToken
            // uniToken is Y
            tickRight = Math.min(currTick, avgTick);
            tickLeft = TICK_MIN;
            tickLeft = Math.tickFloor(tickLeft, tickSpacing);
            tickRight = Math.tickFloor(tickRight, tickSpacing);
        }
        require(tickLeft < tickRight, "L<R");
        sqrtPriceX96 = avgSqrtPriceX96;
    }

    function getOraclePrice()
        external
        view
        returns (
            int24 avgTick,
            uint160 avgSqrtPriceX96
        )
    {
        (avgTick, avgSqrtPriceX96, , ) = swapPool.getAvgTickPriceWithin2Hour();
    }

    // fill INonfungiblePositionManager.MintParams struct to call INonfungiblePositionManager.mint(...)
    function _mintUniswapParam(
        uint256 uniAmount,
        int24 tickLeft,
        int24 tickRight,
        uint256 deadline
    )
        private
        view
        returns (INonfungiblePositionManager.MintParams memory params)
    {
        params.fee = rewardPool.fee;
        params.tickLower = tickLeft;
        params.tickUpper = tickRight;
        params.deadline = deadline;
        params.recipient = address(this);
        if (uniToken < lockToken) {
            params.token0 = uniToken;
            params.token1 = lockToken;
            params.amount0Desired = uniAmount;
            params.amount1Desired = 0;
            params.amount0Min = 1;
            params.amount1Min = 0;
        } else {
            params.token0 = lockToken;
            params.token1 = uniToken;
            params.amount0Desired = 0;
            params.amount1Desired = uniAmount;
            params.amount0Min = 0;
            params.amount1Min = 1;
        }
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "STE");
    }

    function depositWithuniToken(
        uint256 uniAmount,
        uint256 numIZI,
        uint256 deadline
    ) external payable nonReentrant {
        require(uniAmount >= 1e7, "TOKENUNI AMOUNT TOO SMALL");
        require(uniAmount < FixedPoints.Q96 / 3, "TOKENUNI AMOUNT TOO LARGE");
        if (uniIsETH) {
            require(msg.value >= uniAmount, "ETHER INSUFFICIENT");
        } else {
            IERC20(uniToken).safeTransferFrom(
                msg.sender,
                address(this),
                uniAmount
            );
        }
        (
            uint160 sqrtPriceX96,
            int24 tickLeft,
            int24 tickRight
        ) = _getPriceAndTickRange();

        TokenStatus memory newTokenStatus;

        INonfungiblePositionManager.MintParams
            memory uniParams = _mintUniswapParam(
                uniAmount,
                tickLeft,
                tickRight,
                deadline
            );
        uint256 actualAmountUni;

        if (uniToken < lockToken) {
            (
                newTokenStatus.nftId,
                newTokenStatus.uniLiquidity,
                actualAmountUni,

            ) = INonfungiblePositionManager(uniV3NFTManager).mint{
                value: msg.value
            }(uniParams);
        } else {
            (
                newTokenStatus.nftId,
                newTokenStatus.uniLiquidity,
                ,
                actualAmountUni
            ) = INonfungiblePositionManager(uniV3NFTManager).mint{
                value: msg.value
            }(uniParams);
        }

        // mark owners and append to list
        owners[newTokenStatus.nftId] = msg.sender;
        bool res = tokenIds[msg.sender].add(newTokenStatus.nftId);
        require(res);

        if (actualAmountUni < uniAmount) {
            if (uniIsETH) {
                // refund uniToken
                // from uniswap to this
                INonfungiblePositionManager(uniV3NFTManager).refundETH();
                // from this to msg.sender
                if (address(this).balance > 0)
                    safeTransferETH(msg.sender, address(this).balance);
            } else {
                // refund uniToken
                IERC20(uniToken).safeTransfer(
                    msg.sender,
                    uniAmount - actualAmountUni
                );
            }
        }

        _updateGlobalStatus();
        newTokenStatus.vLiquidity = actualAmountUni * lockBoostMultiplier;
        newTokenStatus.lockAmount = _getLockAmount(
            sqrtPriceX96,
            newTokenStatus.vLiquidity
        );

        // make vLiquidity lower
        newTokenStatus.vLiquidity = newTokenStatus.vLiquidity / 1e6;

        IERC20(lockToken).safeTransferFrom(
            msg.sender,
            address(this),
            newTokenStatus.lockAmount
        );
        totalLock += newTokenStatus.lockAmount;
        _updateVLiquidity(newTokenStatus.vLiquidity, true);

        newTokenStatus.nIZI = numIZI;
        if (address(iziToken) == address(0)) {
            // boost is not enabled
            newTokenStatus.nIZI = 0;
        }
        _updateNIZI(newTokenStatus.nIZI, true);
        newTokenStatus.validVLiquidity = _computeValidVLiquidity(
            newTokenStatus.vLiquidity,
            newTokenStatus.nIZI
        );
        require(newTokenStatus.nIZI < FixedPoints.Q128 / 6, "NIZI O");
        _newTokenStatus(newTokenStatus);
        if (newTokenStatus.nIZI > 0) {
            // lock izi in this contract
            iziToken.safeTransferFrom(
                msg.sender,
                address(this),
                newTokenStatus.nIZI
            );
        }

        emit Deposit(msg.sender, newTokenStatus.nftId, newTokenStatus.nIZI);
    }

    function _withdrawUniswapParam(
        uint256 uniPositionID,
        uint128 liquidity,
        uint256 deadline
    )
        private
        pure
        returns (
            INonfungiblePositionManager.DecreaseLiquidityParams memory params
        )
    {
        params.tokenId = uniPositionID;
        params.liquidity = liquidity;
        params.amount0Min = 0;
        params.amount1Min = 0;
        params.deadline = deadline;
    }

    /// @notice deposit iZi to an nft token
    /// @param tokenId nft already deposited
    /// @param deltaNIZI amount of izi to deposit
    function depositIZI(uint256 tokenId, uint256 deltaNIZI)
        external
        nonReentrant
    {
        require(owners[tokenId] == msg.sender, "NOT OWNER or NOT EXIST");
        require(address(iziToken) != address(0), "NOT BOOST");
        require(deltaNIZI > 0, "DEPOSIT IZI MUST BE POSITIVE");
        _collectReward(tokenId);
        TokenStatus memory t = tokenStatus[tokenId];
        _updateNIZI(deltaNIZI, true);
        uint256 nIZI = t.nIZI + deltaNIZI;
        // update validVLiquidity
        uint256 validVLiquidity = _computeValidVLiquidity(t.vLiquidity, nIZI);
        _updateTokenStatus(tokenId, validVLiquidity, nIZI);

        // transfer iZi from user
        iziToken.safeTransferFrom(msg.sender, address(this), deltaNIZI);
    }

    // fill INonfungiblePositionManager.CollectParams struct to call INonfungiblePositionManager.collect(...)
    function _collectUniswapParam(uint256 uniPositionID, address recipient)
        private
        pure
        returns (INonfungiblePositionManager.CollectParams memory params)
    {
        params.tokenId = uniPositionID;
        params.recipient = recipient;
        params.amount0Max = 0xffffffffffffffffffffffffffffffff;
        params.amount1Max = 0xffffffffffffffffffffffffffffffff;
    }

    /// @notice Widthdraw a single position.
    /// @param tokenId The related position id.
    /// @param noReward true if use want to withdraw without reward
    function withdraw(uint256 tokenId, bool noReward) external nonReentrant {
        require(owners[tokenId] == msg.sender, "NOT OWNER OR NOT EXIST");

        if (noReward) {
            _updateGlobalStatus();
        } else {
            _collectReward(tokenId);
        }
        TokenStatus storage t = tokenStatus[tokenId];

        _updateVLiquidity(t.vLiquidity, false);
        if (t.nIZI > 0) {
            _updateNIZI(t.nIZI, false);
            // refund iZi to user
            iziToken.safeTransfer(msg.sender, t.nIZI);
        }
        if (t.lockAmount > 0) {
            // refund lockToken to user
            IERC20(lockToken).safeTransfer(msg.sender, t.lockAmount);
            totalLock -= t.lockAmount;
        }

        INonfungiblePositionManager(uniV3NFTManager).decreaseLiquidity(
            _withdrawUniswapParam(tokenId, t.uniLiquidity, type(uint256).max)
        );

        if (!uniIsETH) {
            INonfungiblePositionManager(uniV3NFTManager).collect(
                _collectUniswapParam(tokenId, msg.sender)
            );
        } else {
            (uint256 amount0, uint256 amount1) = INonfungiblePositionManager(
                uniV3NFTManager
            ).collect(
                    _collectUniswapParam(
                        tokenId,
                        address(this)
                    )
                );
            (uint256 amountUni, uint256 amountLock) = (uniToken < lockToken)? (amount0, amount1) : (amount1, amount0);
            if (amountLock > 0) {
                IERC20(lockToken).safeTransfer(msg.sender, amountLock);
            }

            if (amountUni > 0) {
                IWETH9(uniToken).withdraw(amountUni);
                safeTransferETH(msg.sender, amountUni);
            }
        }

        owners[tokenId] = address(0);
        bool res = tokenIds[msg.sender].remove(tokenId);
        require(res);

        emit Withdraw(msg.sender, tokenId);
    }

    /// @notice Collect pending reward for a single position.
    /// @param tokenId The related position id.
    function _collectReward(uint256 tokenId) internal {
        TokenStatus memory t = tokenStatus[tokenId];

        _updateGlobalStatus();
        for (uint256 i = 0; i < rewardInfosLen; i++) {
            // multiplied by Q128 before
            uint256 _reward = (t.validVLiquidity * (rewardInfos[i].accRewardPerShare - t.lastTouchAccRewardPerShare[i])) / FixedPoints.Q128;
            if (_reward > 0) {
                IERC20(rewardInfos[i].rewardToken).safeTransferFrom(
                    rewardInfos[i].provider,
                    msg.sender,
                    _reward
                );
            }
            emit CollectReward(
                msg.sender,
                tokenId,
                rewardInfos[i].rewardToken,
                _reward
            );
        }

        // update validVLiquidity
        uint256 validVLiquidity = _computeValidVLiquidity(t.vLiquidity, t.nIZI);
        _updateTokenStatus(tokenId, validVLiquidity, t.nIZI);
    }

    /// @notice Collect pending reward for a single position.
    /// @param tokenId The related position id.
    function collect(uint256 tokenId) external nonReentrant {
        require(owners[tokenId] == msg.sender, "NOT OWNER or NOT EXIST");
        _collectReward(tokenId);
        INonfungiblePositionManager.CollectParams
            memory params = _collectUniswapParam(tokenId, msg.sender);
        // collect swap fee from uniswap
        INonfungiblePositionManager(uniV3NFTManager).collect(params);
    }

    /// @notice Collect all pending rewards.
    function collectAllTokens() external nonReentrant {
        EnumerableSet.UintSet storage ids = tokenIds[msg.sender];
        for (uint256 i = 0; i < ids.length(); i++) {
            require(owners[ids.at(i)] == msg.sender, "NOT OWNER");
            _collectReward(ids.at(i));
            INonfungiblePositionManager.CollectParams
                memory params = _collectUniswapParam(ids.at(i), msg.sender);
            // collect swap fee from uniswap
            INonfungiblePositionManager(uniV3NFTManager).collect(params);
        }
    }

    /// @notice View function to get position ids staked here for an user.
    /// @param _user The related address.
    function getTokenIds(address _user)
        external
        view
        returns (uint256[] memory)
    {
        EnumerableSet.UintSet storage ids = tokenIds[_user];
        // push could not be used in memory array
        // we set the tokenIdList into a fixed-length array rather than dynamic
        uint256[] memory tokenIdList = new uint256[](ids.length());
        for (uint256 i = 0; i < ids.length(); i++) {
            tokenIdList[i] = ids.at(i);
        }
        return tokenIdList;
    }

    /// @notice Return reward multiplier over the given _from to _to block.
    /// @param _from The start block.
    /// @param _to The end block.
    function _getRewardBlockNum(uint256 _from, uint256 _to)
        internal
        view
        returns (uint256)
    {
        if (_from > _to) {
            return 0;
        }
        if (_to <= endBlock) {
            return _to - _from;
        } else if (_from >= endBlock) {
            return 0;
        } else {
            return endBlock - _from;
        }
    }

    /// @notice View function to see pending Reward for a single position.
    /// @param tokenId The related position id.
    function pendingReward(uint256 tokenId)
        public
        view
        returns (uint256[] memory)
    {
        TokenStatus memory t = tokenStatus[tokenId];
        uint256[] memory _reward = new uint256[](rewardInfosLen);
        for (uint256 i = 0; i < rewardInfosLen; i++) {
            uint256 tokenReward = _getRewardBlockNum(
                lastTouchBlock,
                block.number
            ) * rewardInfos[i].rewardPerBlock;
            uint256 rewardPerShare = rewardInfos[i].accRewardPerShare + (tokenReward * FixedPoints.Q128) / totalVLiquidity;
            // l * (currentAcc - lastAcc)
            _reward[i] = (t.validVLiquidity * (rewardPerShare - t.lastTouchAccRewardPerShare[i])) / FixedPoints.Q128;
        }
        return _reward;
    }

    /// @notice View function to see pending Rewards for an address.
    /// @param _user The related address.
    function pendingRewards(address _user)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory _reward = new uint256[](rewardInfosLen);
        for (uint256 j = 0; j < rewardInfosLen; j++) {
            _reward[j] = 0;
        }

        for (uint256 i = 0; i < tokenIds[_user].length(); i++) {
            uint256[] memory r = pendingReward(tokenIds[_user].at(i));
            for (uint256 j = 0; j < rewardInfosLen; j++) {
                _reward[j] += r[j];
            }
        }
        return _reward;
    }

    // Control fuctions for the contract owner and operators.

    /// @notice If something goes wrong, we can send back user's nft and locked assets
    /// @param tokenId The related position id.
    function emergenceWithdraw(uint256 tokenId) external onlyOwner {
        address owner = owners[tokenId];
        require(owner != address(0));
        INonfungiblePositionManager(uniV3NFTManager).safeTransferFrom(
            address(this),
            owner,
            tokenId
        );

        TokenStatus storage t = tokenStatus[tokenId];
        if (t.nIZI > 0) {
            // we should ensure nft refund to user
            // omit the case when transfer() returns false unexpectedly
            iziToken.transfer(owner, t.nIZI);
        }
        if (t.lockAmount > 0) {
            // we should ensure nft refund to user
            // omit the case when transfer() returns false unexpectedly
            IERC20(lockToken).transfer(owner, t.lockAmount);
        }
        // makesure user cannot withdraw/depositIZI or collect reward on this nft
        owners[tokenId] = address(0);
    }

    /// @notice Set new reward end block.
    /// @param _endBlock New end block.
    function modifyEndBlock(uint256 _endBlock) external onlyOwner {
        require(_endBlock > block.number, "OUT OF DATE");
        _updateGlobalStatus();
        // jump if origin endBlock < block.number
        lastTouchBlock = block.number;
        endBlock = _endBlock;
        emit ModifyEndBlock(endBlock);
    }

    /// @notice Set new reward per block.
    /// @param rewardIdx which rewardInfo to modify
    /// @param _rewardPerBlock new reward per block
    function modifyRewardPerBlock(uint256 rewardIdx, uint256 _rewardPerBlock)
        external
        onlyOwner
    {
        require(rewardIdx < rewardInfosLen, "OUT OF REWARD INFO RANGE");
        _updateGlobalStatus();
        rewardInfos[rewardIdx].rewardPerBlock = _rewardPerBlock;
        emit ModifyRewardPerBlock(
            rewardInfos[rewardIdx].rewardToken,
            _rewardPerBlock
        );
    }


    /// @notice Set new reward provider.
    /// @param rewardIdx which rewardInfo to modify
    /// @param provider New provider
    function modifyProvider(uint256 rewardIdx, address provider)
        external
        onlyOwner
    {
        require(rewardIdx < rewardInfosLen, "OUT OF REWARD INFO RANGE");
        rewardInfos[rewardIdx].provider = provider;
        emit ModifyProvider(rewardInfos[rewardIdx].rewardToken, provider);
    }
}