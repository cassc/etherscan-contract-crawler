/// @notice Error codes description saved in ErrorCodes.md
pragma solidity 0.8.17;

import "./libraries/TickMath.sol";
import "./libraries/PoolAddress.sol";
import "./libraries/LiquidityAmounts.sol";
import "./interfaces/INonfungiblePositionManager.sol";
import "./interfaces/IWETH9.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/// @dev Contract use UUPS proxy.
contract OptimizedController is Initializable,UUPSUpgradeable,AccessControlUpgradeable,PausableUpgradeable{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    enum OrderType {
        TAKE_PROFIT ,
        BUY_LIMIT,
        TAKE_PROFIT_FILLED,
        BUY_LIMIT_FILLED,
        TAKE_PROFIT_CANCELLED,
        BUY_LIMIT_CANCELLED
    }
    
    /// @notice Address of UniswapV3 position manager
    INonfungiblePositionManager public nftPositionManager;
    /// @notice Address of UniswapV3 factory
    address public uniswapV3Factory;
    /// @notice Address of wrapped ether
    IWETH9 public weth;
    /// @notice Address of UniswapV3 position nft
    address public uniV3Nft;
    /// @notice Amount of eth which whould be payd for execution
    uint256 public executionFee;

    uint256 public SLIPPAGE;
    uint256 public SLIPPAGE_ACCURACY;

    /** @dev the digital representation of the commission in the Uniswap V3 
    is indicated as: 100 = 0.01%, 500 = 0.05%, 3000 = 0.3%, 10_000 = 1%. */
    /// @notice struct which contains data for createOrder function
    /// @param fee fee in uniswapV3 pool
    /// @param token0 token0 in uniswapV3 pool
    /// @param token1 token1 in uniswapV3 pool
    /// @param tickLower the lower tick of the range
    /// @param tickUpper the upper tick of the range
    /// @param amountOfToken0 amount of token0 for order creation
    /// @dev if amountOfToken0 > 0, token1 should be 0
    /// @param amountOfToken1 amount of token0 for order creation
    /// @dev if amountOfToken1 > 0, token0 should be 0
    /// @param recievedAmountOfToken0 amount of token0 to receive
    /// @dev if recievedAmountOfToken0 > 0, recievedAmountOfToken1 should be 0
    /// @param recievedAmountOfToken1 amount of token0 to receive
    /// @dev if recievedAmountOfToken1 > 0, recievedAmountOfToken0 should be 0
    /// @param deadline deadline for order creation
    /// @param orderType type of order
    /// @dev orderType must be 0 if order type is TAKE_PROFIT
    /// @dev orderType must be 1 if order type is BUY_LIMIT
   struct OrderParams {
        uint24 fee;
        address token0;
        address token1;
        int24 tickLower;
        int24 tickUpper;
        uint256 amountOfToken0;
        uint256 amountOfToken1;
        uint256 recievedAmountOfToken0;
        uint256 recievedAmountOfToken1;
        uint256 deadline;
        OrderType orderType;
    }

    /// @notice struct which contains data for createOrder function
    /// @param tokenId ID of the order being modified.
    /// @param pool address of the pool in which the order was created
    /// @param amountOfToken amount of token for increase or decrease liquidity
    struct EditOrderParams {
        uint256 tokenId;
        address poolAddress;
        uint256 amountOfToken;
    }

    /// @notice struct which contains order data
    struct Order {
        address owner;
        address token0;
        address token1;
        int24 tickLower;
        int24 tickUpper;
        uint24 fee;
        uint256 amountOfToken0;
        uint256 amountOfToken1;
        uint256 recievedAmount;
        uint128 liquidity;
        OrderType orderType;
    }


    /// @notice poolAddress => positionNFT_ID => orderData
    /// @dev pool_address -> tokenId -> trade data.
    mapping(address => mapping(uint256 => Order)) public orders;
    // Amount of ETH for executer order. orderId -> ETH
    mapping(uint256 => uint256) public ethForExecute;

    event CreateOrder(address indexed user,address indexed poolAddress,uint256 tokenId,int24 tickLower,int24 tickUpper,OrderType orderType);
    event CancelOrder(address indexed user,uint256 tokenId,address indexed poolAddress,uint256 transferedToken0,uint256 transferedToken1);
    event ExecuteOrder(address indexed user,uint256 tokenId,address indexed poolAddress,uint256 transferedToken0,uint256 transferedToken1);
    

    modifier allowedOrder(uint256 tokenId, address poolAddress) {
        require(
            orders[poolAddress][tokenId].orderType == OrderType.BUY_LIMIT ||
                orders[poolAddress][tokenId].orderType ==
                OrderType.TAKE_PROFIT,
            "OT"
        );
        _;
    }

    /// @notice Initialyze necessary data
    /// @param _nftPositionManager address of  UniswapV3 position manager
    /// @param _uniswapV3Factory address of UniswapV3 factory
    /// @param _weth address of wrapepd ether
    /// @param _uniV3Nft address of UniswapV3 position nft
    /// @param _executionFee amount of eth which whould be payd for execution
    function initialize(address _nftPositionManager,address _uniswapV3Factory,address _weth,address _uniV3Nft,uint256 _executionFee) public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        /// Storage variable initialization.
        nftPositionManager = INonfungiblePositionManager(_nftPositionManager);
        uniswapV3Factory = _uniswapV3Factory;
        uniV3Nft = _uniV3Nft;
        weth = IWETH9(_weth);
        executionFee = _executionFee;
        SLIPPAGE = 9999;
        SLIPPAGE_ACCURACY = 1e5;
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();
    }

    /// @notice return received amount for TAKE_PROFIT order
    /// @param _amount0 amount of tokens to swap
    /// @param _tickLower the lower tick of the range
    /// @param _tickUpper the upper tick of the range
    /// @return _amount1 received amount
    function getAmount1FromAmount0(uint256 _amount0,int24 _tickLower,int24 _tickUpper) external pure returns (uint256 _amount1) {
        uint128 liquidity = LiquidityAmounts.getLiquidityForAmount0(
            TickMath.getSqrtRatioAtTick(_tickLower),
            TickMath.getSqrtRatioAtTick(_tickUpper),
            _amount0
        );
        _amount1 = LiquidityAmounts.getAmount1ForLiquidity(
            TickMath.getSqrtRatioAtTick(_tickLower),
            TickMath.getSqrtRatioAtTick(_tickUpper),
            liquidity
        );
    }

    /// @notice return received amount for BUY_LIMIT order
    /// @param _amount1 amount of tokens to swap
    /// @param _tickLower the lower tick of the range
    /// @param _tickUpper the upper tick of the range
    /// @return _amount0 received amount
    function getAmount0FromAmount1(uint256 _amount1,int24 _tickLower,int24 _tickUpper) external pure returns (uint256 _amount0) {
        uint128 liquidity = LiquidityAmounts.getLiquidityForAmount1(
            TickMath.getSqrtRatioAtTick(_tickLower),
            TickMath.getSqrtRatioAtTick(_tickUpper),
            _amount1
        );
        _amount0 = LiquidityAmounts.getAmount0ForLiquidity(
            TickMath.getSqrtRatioAtTick(_tickLower),
            TickMath.getSqrtRatioAtTick(_tickUpper),
            liquidity
        );
    }

    /// @notice Sets new executionFee
    /// @param _executionFee new executionFee
    function setExecutionFee(uint256 _executionFee)external onlyRole(DEFAULT_ADMIN_ROLE){
        executionFee = _executionFee;
    }

    /// @notice Transfer any tokens left on contract
    /// @param _token address of token
    /// @param _to address of reciever
    /// @param _amount amount to transfer
    function sweepTokens(address _token,address _to,uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_token != uniV3Nft, "SWET1");
        IERC20Upgradeable(_token).transfer(_to, _amount);
    }

    function setPause(bool _newPauseState)external onlyRole(DEFAULT_ADMIN_ROLE){
        _newPauseState ? _pause() : _unpause();
    }

    function setSlippage(uint256 _newSlippage, uint256 _newSlippageAccuracy)external onlyRole(DEFAULT_ADMIN_ROLE){
        require(_newSlippageAccuracy > _newSlippage, "STSL1");
        SLIPPAGE = _newSlippage;
        SLIPPAGE_ACCURACY = _newSlippageAccuracy;
    }

    /// @notice creates order on uniswap v3 position manager
    /// @param _params order type parameters
    function createOrder(OrderParams memory _params)external payable whenNotPaused returns (uint256){
        require(_params.token0 < _params.token1, "CREO1");
        require(_params.orderType == OrderType.TAKE_PROFIT ||  _params.orderType == OrderType.BUY_LIMIT,"CREO2");
        require(msg.value >= executionFee, "CREO3");
        // Get pool.
        address poolAddress = PoolAddress.computeAddress(uniswapV3Factory,PoolAddress.getPoolKey(_params.token0, _params.token1, _params.fee));
        require(AddressUpgradeable.isContract(poolAddress), "CREO4");
        int24 tickSpacing = IUniswapV3Pool(poolAddress).tickSpacing();
        // Prepare to add liquidity.
        (, int24 tick, , , , , ) = IUniswapV3Pool(poolAddress).slot0();
        if (_params.orderType == OrderType.TAKE_PROFIT) {
            require(_params.tickLower > tick, "CREO5");
            require(_params.tickLower <= TickMath.MAX_TICK - tickSpacing,"CREO6");
            require(_params.amountOfToken0 > 0, "CREO7");
            require(_params.amountOfToken1 == 0, "CREO8");
            require(_params.recievedAmountOfToken0 == 0, "CREO9");
            require(_params.recievedAmountOfToken1 > 0, "CREO10");
            require(_params.tickUpper == 0, "CREO11");
            // Transfer tokens from user to us.
            IERC20Upgradeable(_params.token0).safeTransferFrom(_msgSender(),address(this),_params.amountOfToken0);
            IERC20Upgradeable(_params.token0).safeIncreaseAllowance(address(nftPositionManager),_params.amountOfToken0);
            _params.tickUpper = _params.tickLower + tickSpacing;
        } else if (_params.orderType == OrderType.BUY_LIMIT) {
            require(_params.tickUpper < tick, "CREO12");
            require(
                _params.tickUpper >= TickMath.MIN_TICK + tickSpacing,
                "CREO13"
            );
            require(_params.amountOfToken1 > 0, "CREO14");
            require(_params.amountOfToken0 == 0, "CREO15");
            require(_params.recievedAmountOfToken1 == 0, "CREO16");
            require(_params.recievedAmountOfToken0 > 0, "CREO17");
            require(_params.tickLower == 0, "CREO18");
            // Transfer tokens from user to us.
            IERC20Upgradeable(_params.token1).safeTransferFrom(_msgSender(),address(this),_params.amountOfToken1);
            IERC20Upgradeable(_params.token1).safeIncreaseAllowance(address(nftPositionManager),_params.amountOfToken1);
            _params.tickLower = _params.tickUpper - tickSpacing;
        }

        // Create order.
        (uint256 tokenId, uint128 liquidity, , ) = nftPositionManager.mint(
            INonfungiblePositionManager.MintParams({
                token0: _params.token0,
                token1: _params.token1,
                tickLower: _params.tickLower,
                tickUpper: _params.tickUpper,
                fee: _params.fee,
                amount0Desired: _params.amountOfToken0,
                amount1Desired: _params.amountOfToken1,
                amount0Min: (_params.amountOfToken0 * SLIPPAGE) /
                    SLIPPAGE_ACCURACY,
                amount1Min: (_params.amountOfToken1 * SLIPPAGE) /
                    SLIPPAGE_ACCURACY,
                recipient: address(this),
                deadline: _params.deadline
            })
        );
        // Save ETH for execute order.
        ethForExecute[tokenId] = msg.value;
        // Save order data.
        orders[poolAddress][tokenId] = Order({
            owner: _msgSender(),
            token0: _params.token0,
            token1: _params.token1,
            tickLower: _params.tickLower,
            tickUpper: _params.tickUpper,
            fee: _params.fee,
            amountOfToken0: _params.amountOfToken0,
            amountOfToken1: _params.amountOfToken1,
            recievedAmount: _params.recievedAmountOfToken1 == 0
                ? _params.recievedAmountOfToken0
                : _params.recievedAmountOfToken1,
            liquidity: liquidity,
            orderType: _params.orderType
        });
        // Check that Uniswap take all of tokens.
        emit CreateOrder(_msgSender(),poolAddress,tokenId,_params.tickLower,_params.tickUpper,_params.orderType);

        return tokenId;
    }

    /// @notice cancel order and transfer all possible funds to receiver
    /// @param _tokenId tokenId of uniswapV3 nft
    /// @param _poolAddress address of uniswapV3 pool
    function cancelOrder(uint256 _tokenId, address _poolAddress)public allowedOrder(_tokenId, _poolAddress)
    {
        Order storage order = orders[_poolAddress][_tokenId];
        require(order.token0 != address(0), "CANO1");
        require(order.owner == _msgSender(), "CANO2");
        if (order.orderType == OrderType.BUY_LIMIT) {
            order.orderType = OrderType.BUY_LIMIT_CANCELLED;
        } else if (order.orderType == OrderType.TAKE_PROFIT) {
            order.orderType = OrderType.TAKE_PROFIT_CANCELLED;
        }
        (uint256 transferedToken0, uint256 transferedToken1) = _closeOrder(_tokenId,order);
        emit CancelOrder(order.owner,_tokenId,_poolAddress,transferedToken0,transferedToken1);
        AddressUpgradeable.sendValue(payable(_msgSender()),ethForExecute[_tokenId]);
    }

    /** @notice close order and transfer funds to receiver
                funds must be more than recievedAmountOfToken **/
    /// @param _tokenId tokenId of uniswapV3 nft
    /// @param _poolAddress address of uniswapV3 pool
    function executeOrder(uint256 _tokenId, address _poolAddress)public allowedOrder(_tokenId, _poolAddress)
    {
        (bool isClosable, , , , , ) = checkOrder(_tokenId, _poolAddress);
        Order storage order = orders[_poolAddress][_tokenId];
        require(order.token0 != address(0), "EXEO1");
        require(isClosable, "EXEO4");
        (uint256 transferedToken0, uint256 transferedToken1) = _closeOrder(_tokenId,order);
        if (order.orderType == OrderType.BUY_LIMIT) {
            require(transferedToken0 >= order.recievedAmount, "EXEO5");
        } else if (order.orderType == OrderType.TAKE_PROFIT) {
            require(transferedToken1 >= order.recievedAmount, "EXEO5");
        }
        if (order.orderType == OrderType.BUY_LIMIT) {
            order.orderType = OrderType.BUY_LIMIT_FILLED;
        } else if (order.orderType == OrderType.TAKE_PROFIT) {
            order.orderType = OrderType.TAKE_PROFIT_FILLED;
        }
        emit ExecuteOrder(order.owner,_tokenId,_poolAddress,transferedToken0,transferedToken1);
        AddressUpgradeable.sendValue(payable(_msgSender()),ethForExecute[_tokenId]);
    }

    /// @notice returns current order state
    /// @param _tokenId tokenId of uniswapV3 nft
    /// @param _poolAddress address of uniswapV3 pool
    /// @return isClosable true if order is complete
    /// @return owner address receiver of funds
    /// @return quoteToken address of token which whould be received
    /// @return quoteAmount amount of quoteToken
    /// @return baseToken address of token which was used for creating order
    /// @return baseAmount amount of baseToken
    function checkOrder(uint256 _tokenId, address _poolAddress)public view returns (bool isClosable,address owner,address quoteToken,uint256 quoteAmount,address baseToken,uint256 baseAmount){
        (baseAmount, quoteAmount) = _getBaseTokenAmount(_tokenId,_poolAddress);
        Order memory order = orders[_poolAddress][_tokenId];
        isClosable = baseAmount == 0;
        owner = order.owner;
        if (
            order.orderType == OrderType.BUY_LIMIT_FILLED ||
            order.orderType == OrderType.TAKE_PROFIT_FILLED ||
            order.orderType == OrderType.BUY_LIMIT_CANCELLED ||
            order.orderType == OrderType.TAKE_PROFIT_CANCELLED
        ) {
            isClosable = false;
        }
        if (
            order.orderType == OrderType.BUY_LIMIT ||
            order.orderType == OrderType.BUY_LIMIT_FILLED ||
            order.orderType == OrderType.BUY_LIMIT_CANCELLED
        ) {
            quoteToken = order.token0;
            baseToken = order.token1;
        } else if (
            order.orderType == OrderType.TAKE_PROFIT ||
            order.orderType == OrderType.TAKE_PROFIT_FILLED ||
            order.orderType == OrderType.TAKE_PROFIT_CANCELLED
        ) {
            quoteToken = order.token1;
            baseToken = order.token0;
        }
    }

    // TODO: Update error codes after tests
    // TODO: Add deadline to EditOrderParams
    /// @notice return new order state
    /// @param _editParams edit order parameters
    /// @return newAmountOfToken0 new amount after order editing
    /// @dev newAmountOfToken0an can be 0 if order type is BUY_LIMIT
    /// @return newAmountOfToken1 new amount after order editing
    /// @dev newAmountOfToken1an can be 0 if order type is TAKE_PROFIT
    function editOrder(EditOrderParams memory _editParams)public allowedOrder(_editParams.tokenId, _editParams.poolAddress) whenNotPaused returns (uint256 newAmountOfToken0, uint256 newAmountOfToken1){
        // Check that order is exist.
        require(_editParams.tokenId > 0, "EDIT0");
        require(_editParams.poolAddress != address(0), "EDIT1");
        // Check that user can edit order.
        Order storage order = orders[_editParams.poolAddress][_editParams.tokenId];
        uint128 liquidity;
        (, , , uint256 quoteAmount, , ) = checkOrder(_editParams.tokenId,_editParams.poolAddress);
        require(quoteAmount == 0, "EDIT3");
        require(order.owner == _msgSender(), "EDIT4");
        if (_editParams.amountOfToken == 0) {
            cancelOrder(_editParams.tokenId, _editParams.poolAddress);
        } else {
            // Transfer tokens from user to us.
            if (
                order.orderType == OrderType.TAKE_PROFIT &&
                _editParams.amountOfToken > order.amountOfToken0
            ) {
                IERC20Upgradeable(order.token0).safeTransferFrom(_msgSender(),address(this),_editParams.amountOfToken - order.amountOfToken0);
                IERC20Upgradeable(order.token0).safeIncreaseAllowance(address(nftPositionManager),_editParams.amountOfToken - order.amountOfToken0);
            } else if (
                order.orderType == OrderType.BUY_LIMIT &&
                _editParams.amountOfToken > order.amountOfToken1
            ) {
                IERC20Upgradeable(order.token1).safeTransferFrom(_msgSender(),address(this),_editParams.amountOfToken - order.amountOfToken1);
                IERC20Upgradeable(order.token1).safeIncreaseAllowance(address(nftPositionManager),_editParams.amountOfToken - order.amountOfToken1);
            }

            // Increase or decrease liquidity.
            if (order.orderType == OrderType.TAKE_PROFIT) {
                if (_editParams.amountOfToken < order.amountOfToken0) {
                    INonfungiblePositionManager.DecreaseLiquidityParams
                        memory params = INonfungiblePositionManager
                            .DecreaseLiquidityParams({
                                tokenId: _editParams.tokenId,
                                liquidity: LiquidityAmounts
                                    .getLiquidityForAmount0(TickMath.getSqrtRatioAtTick(order.tickLower),
                                        TickMath.getSqrtRatioAtTick(order.tickUpper),
                                        order.amountOfToken0 - _editParams.amountOfToken),
                                amount0Min: ((order.amountOfToken0 - _editParams.amountOfToken) * SLIPPAGE) / SLIPPAGE_ACCURACY,
                                amount1Min: 0,
                                deadline: block.timestamp
                            });
                    (newAmountOfToken0, newAmountOfToken1) = nftPositionManager.decreaseLiquidity(params);
                    INonfungiblePositionManager(nftPositionManager).collect(
                        INonfungiblePositionManager.CollectParams({
                            tokenId: _editParams.tokenId,
                            recipient: address(this),
                            amount0Max: type(uint128).max,
                            amount1Max: type(uint128).max
                        })
                    );
                    // Send decreased tokens to user.
                    IERC20Upgradeable(order.token0).safeTransfer(_msgSender(),newAmountOfToken0);
                    order.recievedAmount = order.recievedAmount - LiquidityAmounts
                        .getAmount0ForLiquidity(
                            TickMath.getSqrtRatioAtTick(order.tickLower),
                            TickMath.getSqrtRatioAtTick(order.tickUpper),
                            LiquidityAmounts.getLiquidityForAmount0(
                                TickMath.getSqrtRatioAtTick(order.tickLower),
                                TickMath.getSqrtRatioAtTick(order.tickUpper),
                                newAmountOfToken0
                            )
                        );
                    order.liquidity =order.liquidity - LiquidityAmounts.getLiquidityForAmount0(
                        TickMath.getSqrtRatioAtTick(order.tickLower),
                        TickMath.getSqrtRatioAtTick(order.tickUpper),
                        order.amountOfToken0 - _editParams.amountOfToken
                    );
                    order.amountOfToken0 = order.amountOfToken0 - newAmountOfToken0;
                } else if (_editParams.amountOfToken > order.amountOfToken0) {
                    INonfungiblePositionManager.IncreaseLiquidityParams
                        memory params = INonfungiblePositionManager
                            .IncreaseLiquidityParams({
                                tokenId: _editParams.tokenId,
                                amount0Desired: _editParams.amountOfToken -
                                    order.amountOfToken0,
                                amount1Desired: 0,
                                amount0Min: ((_editParams.amountOfToken -
                                    order.amountOfToken0) * SLIPPAGE) /
                                    SLIPPAGE_ACCURACY,
                                amount1Min: 0,
                                deadline: block.timestamp
                            });
                    (
                        liquidity,
                        newAmountOfToken0,
                        newAmountOfToken1
                    ) = nftPositionManager.increaseLiquidity(params);
                    // Update data in our storage.
                    order.recievedAmount =order.recievedAmount + LiquidityAmounts
                        .getAmount0ForLiquidity(
                            TickMath.getSqrtRatioAtTick(order.tickLower),
                            TickMath.getSqrtRatioAtTick(order.tickUpper),
                            liquidity
                        );
                    order.liquidity = order.liquidity + liquidity;
                    order.amountOfToken0 = order.amountOfToken0+ newAmountOfToken0;
                } else {
                    revert("EDIT5");
                }
            } else if (order.orderType == OrderType.BUY_LIMIT) {
                if (_editParams.amountOfToken < order.amountOfToken1) {
                    INonfungiblePositionManager.DecreaseLiquidityParams
                        memory params = INonfungiblePositionManager
                            .DecreaseLiquidityParams({
                                tokenId: _editParams.tokenId,
                                liquidity: LiquidityAmounts
                                    .getLiquidityForAmount1(
                                        TickMath.getSqrtRatioAtTick(order.tickLower),
                                        TickMath.getSqrtRatioAtTick(order.tickUpper),
                                        order.amountOfToken1 - _editParams.amountOfToken
                                    ),
                                amount0Min: 0,
                                amount1Min: ((order.amountOfToken1 - _editParams.amountOfToken) * SLIPPAGE) /SLIPPAGE_ACCURACY,
                                deadline: block.timestamp
                            });
                    (newAmountOfToken0, newAmountOfToken1) = nftPositionManager.decreaseLiquidity(params);
                    // Send decreased tokens to user.
                    INonfungiblePositionManager(nftPositionManager).collect(
                        INonfungiblePositionManager.CollectParams({
                            tokenId: _editParams.tokenId,
                            recipient: address(this),
                            amount0Max: type(uint128).max,
                            amount1Max: type(uint128).max
                        })
                    );
                    // Send decreased tokens to user.
                    IERC20Upgradeable(order.token1).safeTransfer(_msgSender(),newAmountOfToken1);
                    order.recievedAmount = order.recievedAmount - LiquidityAmounts
                        .getAmount0ForLiquidity(
                            TickMath.getSqrtRatioAtTick(order.tickLower),
                            TickMath.getSqrtRatioAtTick(order.tickUpper),
                            LiquidityAmounts.getLiquidityForAmount1(
                                TickMath.getSqrtRatioAtTick(order.tickLower),
                                TickMath.getSqrtRatioAtTick(order.tickUpper),
                                newAmountOfToken1
                            )
                        );
                    order.liquidity = order.liquidity - LiquidityAmounts.getLiquidityForAmount1(
                        TickMath.getSqrtRatioAtTick(order.tickLower),
                        TickMath.getSqrtRatioAtTick(order.tickUpper),
                        order.amountOfToken1 - _editParams.amountOfToken
                    );
                    order.amountOfToken1 = order.amountOfToken1- newAmountOfToken1;
                } else if (_editParams.amountOfToken > order.amountOfToken1) {
                    INonfungiblePositionManager.IncreaseLiquidityParams
                        memory params = INonfungiblePositionManager
                            .IncreaseLiquidityParams({
                                tokenId: _editParams.tokenId,
                                amount0Desired: 0,
                                amount1Desired: _editParams.amountOfToken -
                                    order.amountOfToken1,
                                amount0Min: 0,
                                amount1Min: ((_editParams.amountOfToken -
                                    order.amountOfToken1) * SLIPPAGE) /
                                    SLIPPAGE_ACCURACY,
                                deadline: block.timestamp
                            });
                    (liquidity,newAmountOfToken0,newAmountOfToken1) = nftPositionManager.increaseLiquidity(params);
                    // Update data in our storage.
                    order.recievedAmount =order.recievedAmount + LiquidityAmounts
                        .getAmount0ForLiquidity(
                            TickMath.getSqrtRatioAtTick(order.tickLower),
                            TickMath.getSqrtRatioAtTick(order.tickUpper),
                            liquidity
                        );
                    order.liquidity = order.liquidity + liquidity;
                    order.amountOfToken1 = order.amountOfToken1 + newAmountOfToken1;
                } else {
                    revert("EDIT5");
                }
            }
            // Update data in our storage.
        }
    }

    /// @notice return current amounts of base and quote tokens on given pool
    /// @param _tokenId tokenId of uniswapV3 nft
    /// @param _poolAddress address of uniswapV3 pool
    /// @return baseAmount amount of base token
    /// @return quoteAmount amount of quote token
    function _getBaseTokenAmount(uint256 _tokenId, address _poolAddress)private view returns (uint256 baseAmount, uint256 quoteAmount){
        Order memory order = orders[_poolAddress][_tokenId];
        (uint160 sqrtPriceCurrentX96, , , , , , ) = IUniswapV3Pool(_poolAddress).slot0();
        uint160 sqrtPriceLowerX96 = TickMath.getSqrtRatioAtTick(order.tickLower);
        uint160 sqrtPriceUpperX96 = TickMath.getSqrtRatioAtTick(order.tickUpper);
        (uint256 amount0, uint256 amount1) = LiquidityAmounts
            .getAmountsForLiquidity(sqrtPriceCurrentX96,sqrtPriceLowerX96,sqrtPriceUpperX96,order.liquidity);

        if (
            order.orderType == OrderType.BUY_LIMIT ||
            order.orderType == OrderType.BUY_LIMIT_FILLED ||
            order.orderType == OrderType.BUY_LIMIT_CANCELLED
        ) {
            quoteAmount = amount0;
            baseAmount = amount1;
        } else if (
            order.orderType == OrderType.TAKE_PROFIT ||
            order.orderType == OrderType.TAKE_PROFIT_FILLED ||
            order.orderType == OrderType.TAKE_PROFIT_CANCELLED
        ) {
            baseAmount = amount0;
            quoteAmount = amount1;
        }
    }

    /// @notice Collect all rewards and remove liquidity from uniswap v3 pool
    /// @param _tokenId tokenId of uniswapV3 nft
    /// @param _order order data
    /// @return token0Amount amount of removed and collected tokens of token0
    /// @return token1Amount amount of removed and collected tokens of token1
    function _closeOrder(uint256 _tokenId, Order storage _order)internal returns (uint256 token0Amount, uint256 token1Amount)
    {
        uint256 balanceOfToken0Before = IERC20Upgradeable(_order.token0)
            .balanceOf(address(this));
        uint256 balanceOfToken1Before = IERC20Upgradeable(_order.token1)
            .balanceOf(address(this));

        INonfungiblePositionManager(nftPositionManager).decreaseLiquidity(
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: _tokenId,
                liquidity: _order.liquidity,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            })
        );
        INonfungiblePositionManager(nftPositionManager).collect(
            INonfungiblePositionManager.CollectParams({
                tokenId: _tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );
        uint256 balanceOfToken0After = IERC20Upgradeable(_order.token0)
            .balanceOf(address(this));
        uint256 balanceOfToken1After = IERC20Upgradeable(_order.token1)
            .balanceOf(address(this));

        if (balanceOfToken0After > balanceOfToken0Before) {
            IERC20Upgradeable(_order.token0).transfer(
                _order.owner,
                balanceOfToken0After - balanceOfToken0Before
            );
        }
        if (balanceOfToken1After > balanceOfToken1Before) {
            IERC20Upgradeable(_order.token1).transfer(
                _order.owner,
                balanceOfToken1After - balanceOfToken1Before
            );
        }
        return (
            balanceOfToken0After > balanceOfToken0Before
                ? balanceOfToken0After - balanceOfToken0Before
                : 0,
            balanceOfToken1After > balanceOfToken1Before
                ? balanceOfToken1After - balanceOfToken1Before
                : 0
        );
    }

    /// @notice interface support
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}
}