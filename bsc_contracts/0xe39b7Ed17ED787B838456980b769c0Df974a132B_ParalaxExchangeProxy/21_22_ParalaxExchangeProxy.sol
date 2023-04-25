// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Storage.sol";
import "./interfaces/IParalaxExchange.sol";
import "contracts/ParalaxExchange.sol";

contract ParalaxExchangeProxy is Storage, IParalaxExchange {
    error SwapDexError(bytes error);
    event SetFee(TypeFee TypeFee, uint256 value, address account);
    event RemoveLimitOrderP2P(bytes sign);
    event LimitOrderP2PError(bytes sign1, bytes sign2, bytes error);
    event LimitOrderDEXError(bytes sign1, bytes error);
    event InitOrderDCAError(bytes sign, bytes error);
    event DCAError(bytes sign, bytes error);

    struct OrderLMP2P {
        bytes sign1;
        bytes sign2;
        SignerData signerData1;
        SignerData signerData2;
    }

    struct LimitOrderDEX {
        bytes sign;
        SignerData signerData;
        address[] path;
    }
    struct InitOrderDCA {
        bytes sign;
        Order order;
        address[] path;
    }

    string public constant DCA = "dca(bytes)";

    string public constant SWAP_DEX = "swapDex(uint256,uint256,address[])";

    string public constant SWAP_DEX_ETH =
        "swapDexETH(uint256,uint256,address[])";

    string public constant LIMIT_ORDER_P2P =
        "limitOrderP2P(bytes,bytes,(address,address,uint96,address,uint96,uint256,uint256),(address,address,uint96,address,uint96,uint256,uint256))";

    string public constant DCA_TM = "dcaTM(bytes)";

    string public constant INIT_TIME_MULTIPLIER =
        "initTimeMultiplier(bytes,((uint256,uint128,uint64,uint64,uint96,address,uint96,address,address,uint256),(uint256,uint256)))";

    string constant LIMIT_ORDER_DEX =
        "limitOrderDEX(bytes,(address,address,uint96,address,uint96,uint256,uint256),address[])";

    string constant INIT_ORDER_DCA =
        "orderDCA(bytes,((uint256,uint128,uint64,uint64,uint96,address,uint96,address,address,uint256),(uint256,uint256)))";

    string constant ORDER_DCA_TM =
        "orderDCATM(bytes,((uint256,uint128,uint64,uint64,uint96,address,uint96,address,address,uint256),(uint256,uint256)),address[])";

    receive() external payable {}

    constructor(
        address adapter,
        address treasure,
        uint256 delta,
        address implementation,
        address weth
    ) {
        EIP712._init("ParalaxExchange", "1");
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);

        _adapter = adapter;
        _treasure = treasure;
        _delta = delta;
        _implementation = implementation;
        _wETH = weth;
    }

    //-------------------------------------------------------------------------------------
    //--------------------------------- EXTERNAL FUNCTION ---------------------------------
    //-------------------------------------------------------------------------------------

    /* ---------------------------------- ADMIN FUNCTION ---------------------------------- */
    function setFeeDEX(uint256 fee) external onlyRole(ADMIN_ROLE) {
        feeDEX = fee;
        emit SetFee(TypeFee.FeeDEX, fee, msg.sender);
    }

    function setFeeLMDEX(uint256 fee) external onlyRole(ADMIN_ROLE) {
        feeLMDEX = fee;
        emit SetFee(TypeFee.FeeLMDEX, fee, msg.sender);
    }

    function setFeeLMP2P(uint256 fee) external onlyRole(ADMIN_ROLE) {
        feeLMP2P = fee;
        emit SetFee(TypeFee.FeeLMP2P, fee, msg.sender);
    }

    function setFeeDCA(uint256 fee) external onlyRole(ADMIN_ROLE) {
        feeDCA = fee;
        emit SetFee(TypeFee.FeeDCA, fee, msg.sender);
    }

    /* ----------------------------------- GENERAL FUNCTION ---------------------------------- */

    function swapDex(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path
    ) external {
        (bool success, bytes memory data) = _implementation.delegatecall(
            abi.encodeWithSignature(SWAP_DEX, amountIn, amountOutMin, path)
        );

        if (!success) {
            revert SwapDexError(data); //TODO: change to bytes
        }
    }

    function swapDexETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path
    ) external payable {
        (bool success, bytes memory data) = _implementation.delegatecall(
            abi.encodeWithSignature(SWAP_DEX_ETH, amountIn, amountOutMin, path)
        );

        if (!success) {
            revert SwapDexError(data); //TODO: change to bytes
        }
    }

    function limitOrderP2P(OrderLMP2P[] calldata orders) external {
        for (uint256 i = 0; i < orders.length; i++) {
            (bool success, bytes memory data) = _implementation.delegatecall(
                abi.encodeWithSignature(
                    LIMIT_ORDER_P2P,
                    orders[i].sign1,
                    orders[i].sign2,
                    orders[i].signerData1,
                    orders[i].signerData2
                )
            );

            if (!success) {
                emit LimitOrderP2PError(orders[i].sign1, orders[i].sign2, data);
            }
        }
    }

    function limitOrderDEX(LimitOrderDEX[] calldata limitOrdersDEX) external {
        for (uint256 i = 0; i < limitOrdersDEX.length; i++) {
            (bool success, bytes memory data) = _implementation.delegatecall(
                abi.encodeWithSignature(
                    LIMIT_ORDER_DEX,
                    limitOrdersDEX[i].sign,
                    limitOrdersDEX[i].signerData,
                    limitOrdersDEX[i].path
                )
            );
            if (!success) {
                emit LimitOrderDEXError(limitOrdersDEX[i].sign, data);
            }
        }
    }

    function orderDCATM(InitOrderDCA[] calldata dataInitOrderDCA) public {
        bool isRevert = true;
        for (uint256 i = 0; i < dataInitOrderDCA.length; i++) {
            (bool success, bytes memory data) = _implementation.delegatecall(
                abi.encodeWithSignature(
                    ORDER_DCA_TM,
                    dataInitOrderDCA[i].sign,
                    dataInitOrderDCA[i].order,
                    dataInitOrderDCA[i].path
                )
            );
            if (!success) {
                emit InitOrderDCAError(dataInitOrderDCA[i].sign, data);
            } else {
                isRevert = false;
            }
        }
        if (isRevert) {
            revert("DCA EROOR");
        }
    }

    function removeLimitOrderP2P(bytes calldata sign) external {
        require(msg.sender == _signerDatas[sign].account, "Access Error");
        _signerDatas[sign].deadline = 0;
        emit RemoveLimitOrderP2P(sign);
    }

    //-------------------------------------------------------------------------------------
    //------------------------------ EXTERNAL FUNCTION VIEW -------------------------------
    //-------------------------------------------------------------------------------------

    function getOrder(
        bytes calldata sign
    ) external view returns (SignerData memory) {
        return _signerDatas[sign];
    }

    function getOrderDCA(
        bytes calldata sign
    ) external view returns (OrderDCA memory) {
        return _ordersDCA[sign];
    }

    function getTimeMultiplier(
        bytes calldata sign
    ) external view returns (TimeMultiplier memory) {
        return _timeMultipliers[sign];
    }

    function getProcessingDCA(
        bytes calldata sign
    ) external view returns (ProcessingDCA memory) {
        return _processingDCA[sign];
    }

    //-------------------------------------------------------------------------------------
    //---------------------------------- PUBLIC FUNCTION ----------------------------------
    //-------------------------------------------------------------------------------------

    /**
     * @dev UniswapV2Router02 getAmountsOut function
     */
    function getAmountsOut(
        address[] memory path,
        uint256 amount
    ) public view returns (uint256[] memory amountsOut) {
        amountsOut = IUniswapV2Router02(_adapter).getAmountsOut(amount, path);
    }

    /**
     * @dev UniswapV2Router02 getAmountsIn function
     */
    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path
    ) public view returns (uint256[] memory amountsIn) {
        amountsIn = IUniswapV2Router02(_adapter).getAmountsIn(amountOut, path);
    }
}