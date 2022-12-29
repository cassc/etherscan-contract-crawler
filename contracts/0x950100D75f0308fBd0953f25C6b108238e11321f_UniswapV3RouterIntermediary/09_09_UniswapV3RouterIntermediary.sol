// ███╗░░░███╗████████╗░█████╗░██████╗░░██████╗░██╗░░░░░░░██╗░█████╗░██████╗░
// ████╗░████║╚══██╔══╝██╔══██╗██╔══██╗██╔════╝░██║░░██╗░░██║██╔══██╗██╔══██╗
// ██╔████╔██║░░░██║░░░██║░░██║██████╔╝╚█████╗░░╚██╗████╗██╔╝███████║██████╔╝
// ██║╚██╔╝██║░░░██║░░░██║░░██║██╔═══╝░░╚═══██╗░░████╔═████║░██╔══██║██╔═══╝░
// ██║░╚═╝░██║░░░██║░░░╚█████╔╝██║░░░░░██████╔╝░░╚██╔╝░╚██╔╝░██║░░██║██║░░░░░
// ╚═╝░░░░░╚═╝░░░╚═╝░░░░╚════╝░╚═╝░░░░░╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝╚═╝░░░░░

// SPDX-License-Identifier: MIT
pragma solidity =0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/ISwapRouter.sol";
import "./interfaces/IWETH.sol";

/**
 * @dev UniswapV3RouterIntermediary is an interface between the 'real' UniswapV3Router
 * and MtopSwap's Dapp. This allows differentiating the transactions that come from MtopSwap
 * or other services. This is useful for e.g. DappRadar.
 *
 * The fee functions are intended to be used when a user hasn't subscribed to MtopSwap, but
 * already used the free trial.
 */
contract UniswapV3RouterIntermediary is Ownable {
    using SafeERC20 for IERC20;

    /***************
     ** Variables **
     ***************/

    address public feeReceiver;
    uint16 public feeBP = 25; // = 0.25 %

    /***************
     ** Constants **
     ***************/

    /**
     * @dev BP = Percent * 100
     * @notice BP has to be <= FEE_DENOMINATOR
     * BP = FEE_DENOMINATOR -> 100 %
     */
    uint16 public constant FEE_DENOMINATOR = 10000;
    uint16 public constant MAX_FEE_BP = 100; // = 1 %

    IWETH WETH;

    /*****************
     ** Constructor **
     *****************/

    constructor(address feeReceiver_, IWETH weth_) {
        _setFeeReceiver(feeReceiver_);
        WETH = weth_;
    }

    /************
     ** Events **
     ************/

    event FeeBPChange(uint16 indexed fromFeeBP, uint16 indexed toFeeBP);
    event FeeReceiverChange(
        address indexed fromFeeReceiver,
        address indexed toFeeReceiver
    );
    event Swap(
        address indexed router,
        address indexed fromToken,
        address indexed toToken,
        uint256 amountIn,
        uint256 feesPaid
    );

    /****************
     ** Structures **
     ****************/

    struct SwapDesc {
        ISwapRouter router;
        string swapFunc;
        uint256 amountIn;
        uint256 amountOutMin;
        bytes path;
        address to;
        uint256 deadline;
        bool withFee;
        IERC20 fromToken;
        IERC20 toToken;
        address payer;
    }

    /***********************
     ** Ownable Functions **
     ***********************/

    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        _setFeeReceiver(_feeReceiver);
    }

    function setFeeBP(uint16 _feeBP) external onlyOwner {
        require(
            _feeBP <= FEE_DENOMINATOR,
            "UniswapV3RouterIntermediary: feeBP > FEE_DENOMINATOR"
        );
        require(
            _feeBP <= MAX_FEE_BP,
            "UniswapV3RouterIntermediary: feeBP > MAX_FEE_BP"
        );

        emit FeeBPChange(feeBP, _feeBP);

        feeBP = _feeBP;
    }

    /************************
     ** External Functions **
     ************************/

    receive() external payable {}

    function getFeeDetails(uint256 _amount)
        external
        view
        returns (uint256 _fee, uint256 _left)
    {
        return _getFeeDetails(_amount);
    }

    function swapExactTokensForTokens(
        ISwapRouter router,
        string memory swapFunc,
        uint256 amountIn,
        uint256 amountOutMin,
        bytes calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256) {
        return
            _swapExactTokensForTokens(
                router,
                swapFunc,
                amountIn,
                amountOutMin,
                path,
                to,
                deadline,
                false
            );
    }

    function swapExactETHForTokens(
        ISwapRouter router,
        string memory swapFunc,
        uint256 amountIn,
        uint256 amountOutMin,
        bytes calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256) {
        return
            _swapExactETHForTokens(
                router,
                swapFunc,
                amountIn,
                amountOutMin,
                path,
                to,
                deadline,
                false
            );
    }

    function swapExactTokensForETH(
        ISwapRouter router,
        string memory swapFunc,
        uint256 amountIn,
        uint256 amountOutMin,
        bytes calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256) {
        return
            _swapExactTokensForETH(
                router,
                swapFunc,
                amountIn,
                amountOutMin,
                path,
                to,
                deadline,
                false
            );
    }

    function swapExactTokensForTokensWithFee(
        ISwapRouter router,
        string memory swapFunc,
        uint256 amountIn,
        uint256 amountOutMin,
        bytes calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256) {
        return
            _swapExactTokensForTokens(
                router,
                swapFunc,
                amountIn,
                amountOutMin,
                path,
                to,
                deadline,
                true
            );
    }

    function swapExactETHForTokensWithFee(
        ISwapRouter router,
        string memory swapFunc,
        uint256 amountIn,
        uint256 amountOutMin,
        bytes calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256) {
        return
            _swapExactETHForTokens(
                router,
                swapFunc,
                amountIn,
                amountOutMin,
                path,
                to,
                deadline,
                true
            );
    }

    function swapExactTokensForETHWithFee(
        ISwapRouter router,
        string memory swapFunc,
        uint256 amountIn,
        uint256 amountOutMin,
        bytes calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256) {
        return
            _swapExactTokensForETH(
                router,
                swapFunc,
                amountIn,
                amountOutMin,
                path,
                to,
                deadline,
                true
            );
    }

    /************************
     ** Internal Functions **
     ************************/

    function _swapExactTokensForTokens(
        ISwapRouter router,
        string memory swapFunc,
        uint256 amountIn,
        uint256 amountOutMin,
        bytes calldata path,
        address to,
        uint256 deadline,
        bool withFee
    ) internal returns (uint256) {
        (IERC20 _fromToken, IERC20 _toToken) = _fromAndToToken(path);

        uint256 _outAmount = _swap(
            SwapDesc({
                router: router,
                swapFunc: swapFunc,
                amountIn: amountIn,
                amountOutMin: amountOutMin,
                path: path,
                to: to,
                deadline: deadline,
                withFee: withFee,
                fromToken: _fromToken,
                toToken: _toToken,
                payer: msg.sender
            })
        );

        return _outAmount;
    }

    function _swapExactETHForTokens(
        ISwapRouter router,
        string memory swapFunc,
        uint256 amountIn,
        uint256 amountOutMin,
        bytes calldata path,
        address to,
        uint256 deadline,
        bool withFee
    ) internal returns (uint256) {
        (IERC20 _fromToken, IERC20 _toToken) = _fromAndToToken(path);

        require(
            address(_fromToken) == address(WETH),
            "UniswapV3RouterIntermediary: fromToken != weth"
        );

        require(
            msg.value == amountIn,
            "UniswapV3RouterIntermediary: value != amountIn"
        );

        WETH.deposit{value: msg.value}();

        uint256 _outAmount = _swap(
            SwapDesc({
                router: router,
                swapFunc: swapFunc,
                amountIn: amountIn,
                amountOutMin: amountOutMin,
                path: path,
                to: to,
                deadline: deadline,
                withFee: withFee,
                fromToken: _fromToken,
                toToken: _toToken,
                payer: address(this)
            })
        );

        return _outAmount;
    }

    function _swapExactTokensForETH(
        ISwapRouter router,
        string memory swapFunc,
        uint256 amountIn,
        uint256 amountOutMin,
        bytes calldata path,
        address to,
        uint256 deadline,
        bool withFee
    ) internal returns (uint256) {
        (IERC20 _fromToken, IERC20 _toToken) = _fromAndToToken(path);

        require(
            address(_toToken) == address(WETH),
            "UniswapV3RouterIntermediary: toToken != weth"
        );

        uint256 _outAmount = _swap(
            SwapDesc({
                router: router,
                swapFunc: swapFunc,
                amountIn: amountIn,
                amountOutMin: amountOutMin,
                path: path,
                /// @dev WETH needs to be sent to this address and then converted to ETH
                to: address(this),
                deadline: deadline,
                withFee: withFee,
                fromToken: _fromToken,
                toToken: _toToken,
                payer: msg.sender
            })
        );

        WETH.withdraw(_outAmount);

        (bool sent, bytes memory data) = to.call{value: _outAmount}("");
        data; /// remove unsued variable
        require(sent, "UniswapV3RouterIntermediary: Failed to send Ether");

        return _outAmount;
    }

    function _convertToAddress(bytes memory _path, uint256 _start)
        internal
        pure
        returns (address)
    {
        require(
            _start + 20 >= _start,
            "UniswapV3RouterIntermediary: toAddress_overflow"
        );
        require(
            _path.length >= _start + 20,
            "UniswapV3RouterIntermediary: toAddress_outOfBounds"
        );
        address tempAddress;

        assembly {
            tempAddress := div(
                mload(add(add(_path, 0x20), _start)),
                0x1000000000000000000000000
            )
        }

        return tempAddress;
    }

    function _fromAndToToken(bytes memory _path)
        internal
        pure
        returns (IERC20 _fromToken, IERC20 _toToken)
    {
        /// @dev addresses have a bytes length of 20
        return (
            IERC20(_convertToAddress(_path, 0)),
            IERC20(_convertToAddress(_path, _path.length - 20))
        );
    }

    function _setFeeReceiver(address _feeReceiver) internal {
        /// @dev avoid misuse by checking for zero address
        require(_feeReceiver != address(0));

        emit FeeReceiverChange(feeReceiver, _feeReceiver);

        feeReceiver = _feeReceiver;
    }

    function _getFeeDetails(uint256 _amount)
        internal
        view
        returns (uint256 _fee, uint256 _left)
    {
        _fee = (_amount * feeBP) / FEE_DENOMINATOR;
        _left = _amount - _fee;
    }

    function _swap(SwapDesc memory swapDesc) internal returns (uint256) {
        uint256 amountIn = swapDesc.amountIn;
        uint256 fee = 0;

        if (swapDesc.withFee) {
            (uint256 _fee, uint256 _left) = _getFeeDetails(swapDesc.amountIn);

            /// @dev send tokens to this contract for swapping (minus fees)
            /// If the payer is already THIS contract, then THIS contract
            /// already has the funds

            if (swapDesc.payer != address(this))
                swapDesc.fromToken.safeTransferFrom(
                    swapDesc.payer,
                    address(this),
                    _left
                );

            /// @dev send fees to fee receiver
            swapDesc.fromToken.safeTransferFrom(
                swapDesc.payer,
                feeReceiver,
                _fee
            );

            /// @dev approve tx to router
            swapDesc.fromToken.safeIncreaseAllowance(
                address(swapDesc.router),
                _left
            );

            amountIn = _left;
            fee = _fee;
        } else {
            /// @dev send tokens to this contract for swapping
            /// If the payer is already THIS contract, then THIS contract
            /// already has the funds

            if (swapDesc.payer != address(this))
                swapDesc.fromToken.safeTransferFrom(
                    swapDesc.payer,
                    address(this),
                    swapDesc.amountIn
                );

            /// @dev approve tx to router
            swapDesc.fromToken.safeIncreaseAllowance(
                address(swapDesc.router),
                swapDesc.amountIn
            );
        }

        emit Swap(
            address(swapDesc.router),
            address(swapDesc.fromToken),
            address(swapDesc.toToken),
            swapDesc.amountIn,
            fee
        );

        ISwapRouter.ExactInputParams memory params = ISwapRouter
            .ExactInputParams({
                path: swapDesc.path,
                recipient: swapDesc.to,
                deadline: swapDesc.deadline,
                amountIn: amountIn,
                amountOutMinimum: swapDesc.amountOutMin
            });

        bytes memory payload = abi.encodeWithSignature(
            string.concat(
                swapDesc.swapFunc,
                "((bytes,address,uint256,uint256,uint256))"
            ),
            params
        );

        (bool success, bytes memory returnData) = address(swapDesc.router).call(
            payload
        );

        require(success, "UniswapV3RouterIntermediary: !success");

        return uint256(bytes32(returnData));
    }
}