// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../interfaces/hub/IMuffinHub.sol";
import "../../interfaces/hub/positions/IMuffinHubPositions.sol";
import "../../interfaces/manager/IPositionManager.sol";
import "../../libraries/math/PoolMath.sol";
import "../../libraries/math/TickMath.sol";
import "../../libraries/math/UnsafeMath.sol";
import "../../libraries/Pools.sol";
import "../../libraries/Positions.sol";
import "./ManagerBase.sol";
import "./ERC721Extended.sol";

abstract contract PositionManager is IPositionManager, ManagerBase, ERC721Extended {
    struct PositionInfo {
        address owner;
        uint40 pairId;
        uint8 tierId;
        int24 tickLower;
        int24 tickUpper;
    }
    /// @notice Mapping of token id to position managed by this contract
    mapping(uint256 => PositionInfo) public positionsByTokenId;

    struct Pair {
        address token0;
        address token1;
    }
    /// @dev Next pair id. skips 0
    uint40 internal nextPairId = 1;
    /// @notice Mapping of pair id to its underlying tokens
    mapping(uint40 => Pair) public pairs;
    /// @notice Mapping of pool id to pair id
    mapping(bytes32 => uint40) public pairIdsByPoolId;

    constructor() ERC721Extended("Muffin Position", "MUFFIN-POS") {}

    modifier checkApproved(uint256 tokenId) {
        _checkApproved(tokenId);
        _;
    }

    function _checkApproved(uint256 tokenId) internal view {
        require(_isApprovedOrOwner(msg.sender, tokenId), "NOT_APPROVED");
    }

    function _getPoolId(address token0, address token1) internal pure returns (bytes32) {
        return keccak256(abi.encode(token0, token1));
    }

    /// @dev Cache the underlying tokens of a pool and return an id of the cache
    function _cacheTokenPair(address token0, address token1) internal returns (uint40 pairId) {
        bytes32 poolId = _getPoolId(token0, token1);
        pairId = pairIdsByPoolId[poolId];
        if (pairId == 0) {
            pairIdsByPoolId[poolId] = (pairId = nextPairId++);
            pairs[pairId] = Pair(token0, token1);
        }
    }

    /*===============================================================
     *                      CREATE POOL / TIER
     *==============================================================*/

    /// @notice             Create a pool for token0 and token1 if it hasn't been created
    /// @dev                DO NOT create pool with rebasing tokens or multiple-address tokens as it will cause loss of funds
    /// @param token0       Address of token0 of the pool
    /// @param token1       Address of token1 of the pool
    /// @param sqrtGamma    Sqrt of (1 - percentage swap fee of the 1st tier)
    /// @param sqrtPrice    Sqrt price of token0 denominated in token1
    function createPool(
        address token0,
        address token1,
        uint24 sqrtGamma,
        uint128 sqrtPrice,
        bool useAccount
    ) external payable {
        IMuffinHub _hub = IMuffinHub(hub);
        // check tick spacing. zero means the pool is not created
        (uint8 tickSpacing, ) = _hub.getPoolParameters(_getPoolId(token0, token1));
        if (tickSpacing == 0) {
            _depositForTierCreation(token0, token1, sqrtPrice, useAccount);
            _hub.createPool(token0, token1, sqrtGamma, sqrtPrice, getAccRefId(msg.sender));
        }
        _cacheTokenPair(token0, token1);
    }

    /// @notice             Add a tier to a pool
    /// @dev                This function is subject to sandwitch attack which costs more tokens to add a tier, but the extra cost
    ///                     should be small in common token pairs. Also, users can multicall with "mint" to do slippage check.
    /// @param token0       Address of token0 of the pool
    /// @param token1       Address of token1 of the pool
    /// @param sqrtGamma    Sqrt of (1 - percentage swap fee of the 1st tier)
    /// @param expectedTierId Expected id of the new tier. Revert if unmatched. Set to type(uint8).max for skipping the check.
    function addTier(
        address token0,
        address token1,
        uint24 sqrtGamma,
        bool useAccount,
        uint8 expectedTierId
    ) external payable {
        IMuffinHub _hub = IMuffinHub(hub);
        // get first tier's sqrtPrice. revert if pool is not created.
        uint128 sqrtPrice = _hub.getTier(_getPoolId(token0, token1), 0).sqrtPrice;
        _depositForTierCreation(token0, token1, sqrtPrice, useAccount);

        uint8 tierId = _hub.addTier(token0, token1, sqrtGamma, getAccRefId(msg.sender));
        require(tierId == expectedTierId || expectedTierId == type(uint8).max);
        _cacheTokenPair(token0, token1);
    }

    /// @dev Deposit tokens required to create a tier
    function _depositForTierCreation(
        address token0,
        address token1,
        uint128 sqrtPrice,
        bool useAccount
    ) internal {
        unchecked {
            uint256 amount0 = UnsafeMath.ceilDiv(uint256(Pools.BASE_LIQUIDITY_D8) << (72 + 8), sqrtPrice);
            uint256 amount1 = UnsafeMath.ceilDiv(uint256(Pools.BASE_LIQUIDITY_D8) * sqrtPrice, 1 << (72 - 8));

            if (useAccount) {
                bytes32 accHash = keccak256(abi.encode(address(this), getAccRefId(msg.sender)));
                uint256 amt0Acc = _getAccountBalance(token0, accHash);
                uint256 amt1Acc = _getAccountBalance(token1, accHash);
                if (amount0 > amt0Acc) deposit(msg.sender, token0, amount0 - amt0Acc);
                if (amount1 > amt1Acc) deposit(msg.sender, token1, amount1 - amt1Acc);
            } else {
                deposit(msg.sender, token0, amount0);
                deposit(msg.sender, token1, amount1);
            }
        }
    }

    function _getAccountBalance(address token, bytes32 accHash) internal view returns (uint256) {
        return IMuffinHub(hub).accounts(token, accHash);
    }

    /*===============================================================
     *                        ADD LIQUIDITY
     *==============================================================*/

    /// @dev Called by hub contract
    function muffinMintCallback(
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external fromHub {
        address payer = abi.decode(data, (address));
        if (amount0 > 0) payHub(token0, payer, amount0);
        if (amount1 > 0) payHub(token1, payer, amount1);
    }

    /**
     * @notice              Mint a position NFT
     * @param params        MintParams struct
     * @return tokenId      Id of the NFT
     * @return liquidityD8  Amount of liquidity added (divided by 2^8)
     * @return amount0      Token0 amount paid
     * @return amount1      Token1 amount paid
     */
    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint96 liquidityD8,
            uint256 amount0,
            uint256 amount1
        )
    {
        tokenId = _mintNext(params.recipient);

        PositionInfo memory info = PositionInfo({
            owner: params.recipient,
            pairId: _cacheTokenPair(params.token0, params.token1),
            tierId: params.tierId,
            tickLower: params.tickLower,
            tickUpper: params.tickUpper
        });
        positionsByTokenId[tokenId] = info;

        (liquidityD8, amount0, amount1) = _addLiquidity(
            info,
            Pair(params.token0, params.token1),
            tokenId,
            params.amount0Desired,
            params.amount1Desired,
            params.amount0Min,
            params.amount1Min,
            params.useAccount
        );
    }

    /**
     * @notice              Add liquidity to an existing position
     * @param params        AddLiquidityParams struct
     * @return liquidityD8  Amount of liquidity added (divided by 2^8)
     * @return amount0      Token0 amount paid
     * @return amount1      Token1 amount paid
     */
    function addLiquidity(AddLiquidityParams calldata params)
        external
        payable
        checkApproved(params.tokenId)
        returns (
            uint96 liquidityD8,
            uint256 amount0,
            uint256 amount1
        )
    {
        PositionInfo memory info = positionsByTokenId[params.tokenId];
        (liquidityD8, amount0, amount1) = _addLiquidity(
            info,
            pairs[info.pairId],
            params.tokenId,
            params.amount0Desired,
            params.amount1Desired,
            params.amount0Min,
            params.amount1Min,
            params.useAccount
        );
    }

    function _addLiquidity(
        PositionInfo memory info,
        Pair memory pair,
        uint256 tokenId,
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min,
        bool useAccount
    )
        internal
        returns (
            uint96 liquidityD8,
            uint256 amount0,
            uint256 amount1
        )
    {
        liquidityD8 = PoolMath.calcLiquidityForAmts(
            IMuffinHub(hub).getTier(_getPoolId(pair.token0, pair.token1), info.tierId).sqrtPrice,
            TickMath.tickToSqrtPrice(info.tickLower),
            TickMath.tickToSqrtPrice(info.tickUpper),
            amount0Desired,
            amount1Desired
        );
        (amount0, amount1) = IMuffinHubPositions(hub).mint(
            IMuffinHubPositionsActions.MintParams({
                token0: pair.token0,
                token1: pair.token1,
                tierId: info.tierId,
                tickLower: info.tickLower,
                tickUpper: info.tickUpper,
                liquidityD8: liquidityD8,
                recipient: address(this),
                positionRefId: tokenId,
                senderAccRefId: useAccount ? getAccRefId(msg.sender) : 0,
                data: abi.encode(msg.sender)
            })
        );
        require(amount0 >= amount0Min && amount1 >= amount1Min, "Price slippage");
    }

    /*===============================================================
     *                       REMOVE LIQUIDITY
     *==============================================================*/

    /**
     * @notice              Remove liquidity from a position
     * @param params        RemoveLiquidityParams struct
     * @return amount0      Token0 amount from the removed liquidity
     * @return amount1      Token1 amount from the removed liquidity
     * @return feeAmount0   Token0 fee collected from the position
     * @return feeAmount1   Token1 fee collected from the position
     */
    function removeLiquidity(RemoveLiquidityParams calldata params)
        external
        payable
        checkApproved(params.tokenId)
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 feeAmount0,
            uint256 feeAmount1
        )
    {
        PositionInfo storage info = positionsByTokenId[params.tokenId];
        Pair memory pair = pairs[info.pairId];
        IMuffinHubPositionsActions.BurnParams memory burnParams = IMuffinHubPositionsActions.BurnParams({
            token0: pair.token0,
            token1: pair.token1,
            tierId: info.tierId,
            tickLower: info.tickLower,
            tickUpper: info.tickUpper,
            liquidityD8: params.liquidityD8,
            positionRefId: params.tokenId,
            accRefId: getAccRefId(info.owner),
            collectAllFees: params.collectAllFees
        });

        (amount0, amount1, feeAmount0, feeAmount1) = params.settled
            ? IMuffinHubPositions(hub).collectSettled(burnParams)
            : IMuffinHubPositions(hub).burn(burnParams);

        require(amount0 >= params.amount0Min && amount1 >= params.amount1Min, "Price slippage");

        if (params.withdrawTo != address(0)) {
            uint256 sumAmt0 = amount0 + feeAmount0;
            uint256 sumAmt1 = amount1 + feeAmount1;
            if (sumAmt0 > 0) withdraw(params.withdrawTo, pair.token0, sumAmt0);
            if (sumAmt1 > 0) withdraw(params.withdrawTo, pair.token1, sumAmt1);
        }
    }

    /*===============================================================
     *                         LIMIT ORDER
     *==============================================================*/

    /// @notice                 Set position's limit order type
    /// @param tokenId          Id of the position NFT. Or set to zero to indicate the latest NFT id in this contract
    ///                         (useful for chaining this function after `mint` in a multicall)
    /// @param limitOrderType   Direction of limit order (0: N/A, 1: zero->one, 2: one->zero)
    function setLimitOrderType(uint256 tokenId, uint8 limitOrderType) external payable {
        // zero is the magic number to indicate the latest token id
        if (tokenId == 0) tokenId = latestTokenId();
        _checkApproved(tokenId);

        PositionInfo storage info = positionsByTokenId[tokenId];
        Pair storage pair = pairs[info.pairId];
        IMuffinHubPositions(hub).setLimitOrderType(
            pair.token0,
            pair.token1,
            info.tierId,
            info.tickLower,
            info.tickUpper,
            tokenId,
            limitOrderType
        );
    }

    /*===============================================================
     *                          BURN NFT
     *==============================================================*/

    /// @notice Burn NFTs of empty positions
    /// @param tokenIds Array of NFT id
    function burn(uint256[] calldata tokenIds) external payable {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            // check existance + approval
            _checkApproved(tokenId);

            // check if position is empty
            PositionInfo storage info = positionsByTokenId[tokenId];
            Pair storage pair = pairs[info.pairId];
            Positions.Position memory position = IMuffinHub(hub).getPosition(
                _getPoolId(pair.token0, pair.token1),
                address(this),
                tokenId,
                info.tierId,
                info.tickLower,
                info.tickUpper
            );
            require(position.liquidityD8 == 0, "NOT_EMPTY");

            _burn(tokenId);
            delete positionsByTokenId[tokenId];
        }
    }

    /*===============================================================
     *                       VIEW FUNCTIONS
     *==============================================================*/

    /// @notice Get the position info of an NFT
    /// @param tokenId Id of the NFT
    function getPosition(uint256 tokenId)
        external
        view
        returns (
            address owner,
            address token0,
            address token1,
            uint8 tierId,
            int24 tickLower,
            int24 tickUpper,
            Positions.Position memory position
        )
    {
        PositionInfo storage info = positionsByTokenId[tokenId];
        (owner, tierId, tickLower, tickUpper) = (info.owner, info.tierId, info.tickLower, info.tickUpper);
        require(info.owner != address(0), "NOT_EXISTS");

        Pair storage pair = pairs[info.pairId];
        (token0, token1) = (pair.token0, pair.token1);

        position = IMuffinHub(hub).getPosition(_getPoolId(token0, token1), address(this), tokenId, tierId, tickLower, tickUpper);
    }

    /*===============================================================
     *                 OVERRIDE FUNCTIONS IN ERC721
     *==============================================================*/

    /// @dev override `_getOwner` in ERC721.sol
    function _getOwner(uint256 tokenId) internal view override returns (address owner) {
        owner = positionsByTokenId[tokenId].owner;
    }

    /// @dev override `_setOwner` in ERC721.sol
    function _setOwner(uint256 tokenId, address owner) internal override {
        positionsByTokenId[tokenId].owner = owner;
    }
}