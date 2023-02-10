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

import "./interfaces/IUniswapV2Router01.sol";

/**
 * @dev UniswapV2Router01IntermediaryV2 is an interface between the 'real' UniswapV2Router01
 * and MtopSwap's Dapp. This allows differentiating the transactions that come from MtopSwap
 * or other services. This is useful for e.g. DappRadar.
 *
 * The fee functions are intended to be used when a user hasn't subscribed to MtopSwap, but
 * already used the free trial.
 */
contract UniswapV2Router01IntermediaryV2 is Ownable {
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

    /*****************
     ** Constructor **
     *****************/

    constructor(address feeReceiver_) {
        _setFeeReceiver(feeReceiver_);
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
        IUniswapV2Router01 router;
        string swapFunc;
        uint256 amountIn;
        uint256 amountOutMin;
        address[] path;
        address to;
        uint256 deadline;
        bool withFee;
    }

    /***************
     ** Modifiers **
     ***************/

    modifier pathMinLength2(address[] memory _path) {
        _pathMinLength2(_path);
        _;
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
            "UniswapV2Router01IntermediaryV2: feeBP > FEE_DENOMINATOR"
        );
        require(
            _feeBP <= MAX_FEE_BP,
            "UniswapV2Router01IntermediaryV2: feeBP > MAX_FEE_BP"
        );

        emit FeeBPChange(feeBP, _feeBP);

        feeBP = _feeBP;
    }

    /************************
     ** External Functions **
     ************************/

    function getFeeDetails(uint256 _amount)
        external
        view
        returns (uint256 _fee, uint256 _left)
    {
        return _getFeeDetails(_amount);
    }

    function swapExactTokensForTokens(
        IUniswapV2Router01 router,
        string memory swapFunc,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256) {
        return
            _swapExactTokensForTokens(
                SwapDesc({
                    router: router,
                    swapFunc: swapFunc,
                    amountIn: amountIn,
                    amountOutMin: amountOutMin,
                    path: path,
                    to: to,
                    deadline: deadline,
                    withFee: false
                })
            );
    }

    function swapExactETHForTokens(
        IUniswapV2Router01 router,
        string memory swapFunc,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256) {
        return
            _swapExactETHForTokens(
                SwapDesc({
                    router: router,
                    swapFunc: swapFunc,
                    amountIn: address(this).balance,
                    amountOutMin: amountOutMin,
                    path: path,
                    to: to,
                    deadline: deadline,
                    withFee: false
                })
            );
    }

    function swapExactTokensForETH(
        IUniswapV2Router01 router,
        string memory swapFunc,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256) {
        return
            _swapExactTokensForETH(
                SwapDesc({
                    router: router,
                    swapFunc: swapFunc,
                    amountIn: amountIn,
                    amountOutMin: amountOutMin,
                    path: path,
                    to: to,
                    deadline: deadline,
                    withFee: false
                })
            );
    }

    function swapExactTokensForTokensWithFee(
        IUniswapV2Router01 router,
        string memory swapFunc,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256) {
        return
            _swapExactTokensForTokens(
                SwapDesc({
                    router: router,
                    swapFunc: swapFunc,
                    amountIn: amountIn,
                    amountOutMin: amountOutMin,
                    path: path,
                    to: to,
                    deadline: deadline,
                    withFee: true
                })
            );
    }

    function swapExactETHForTokensWithFee(
        IUniswapV2Router01 router,
        string memory swapFunc,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256) {
        return
            _swapExactETHForTokens(
                SwapDesc({
                    router: router,
                    swapFunc: swapFunc,
                    amountIn: address(this).balance,
                    amountOutMin: amountOutMin,
                    path: path,
                    to: to,
                    deadline: deadline,
                    withFee: true
                })
            );
    }

    function swapExactTokensForETHWithFee(
        IUniswapV2Router01 router,
        string memory swapFunc,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256) {
        return
            _swapExactTokensForETH(
                SwapDesc({
                    router: router,
                    swapFunc: swapFunc,
                    amountIn: amountIn,
                    amountOutMin: amountOutMin,
                    path: path,
                    to: to,
                    deadline: deadline,
                    withFee: true
                })
            );
    }

    /************************
     ** Internal Functions **
     ************************/

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

    function _pathMinLength2(address[] memory _path) internal pure {
        /// @dev path always has min. 2 tokens
        require(_path.length >= 2, "UniswapV2Router01IntermediaryV2: path < 2");
    }

    function _swapExactTokensForTokens(SwapDesc memory swapDesc)
        internal
        pathMinLength2(swapDesc.path)
        returns (uint256)
    {
        /// @dev if `path[0]` is zero the tx will fail because of SafeERC20
        IERC20 _fromToken = IERC20(swapDesc.path[0]);

        uint amountIn = swapDesc.amountIn;
        uint fee = 0;
        if (swapDesc.withFee) {
            (uint256 _fee, uint256 _left) = _getFeeDetails(swapDesc.amountIn);

            /// @dev send tokens to this contract for swapping (minus fees)
            _fromToken.safeTransferFrom(_msgSender(), address(this), _left);
            /// @dev send fees to fee receiver
            _fromToken.safeTransferFrom(_msgSender(), feeReceiver, _fee);

            /// @dev approve tx to router
            _fromToken.safeIncreaseAllowance(address(swapDesc.router), _left);

            amountIn = _left;
            fee = _fee;
        } else {
            /// @dev send tokens to this contract for swapping
            _fromToken.safeTransferFrom(
                _msgSender(),
                address(this),
                swapDesc.amountIn
            );

            /// @dev approve tx to router
            _fromToken.safeIncreaseAllowance(
                address(swapDesc.router),
                swapDesc.amountIn
            );
        }

        emit Swap(
            address(swapDesc.router),
            swapDesc.path[0],
            swapDesc.path[swapDesc.path.length - 1],
            swapDesc.amountIn,
            fee
        );

        bytes memory payload = abi.encodeWithSignature(
            string.concat(
                swapDesc.swapFunc,
                "(uint256,uint256,address[],address,uint256)"
            ),
            amountIn,
            swapDesc.amountOutMin,
            swapDesc.path,
            swapDesc.to,
            swapDesc.deadline
        );

        (bool success, bytes memory returnData) = address(swapDesc.router).call(
            payload
        );

        require(success, "UniswapV2Router01IntermediaryV2: !success");

        return uint256(bytes32(returnData));
    }

    function _swapExactETHForTokens(SwapDesc memory swapDesc)
        internal
        pathMinLength2(swapDesc.path)
        returns (uint256)
    {
        uint amountIn = swapDesc.amountIn;
        uint fee = 0;

        if (swapDesc.withFee) {
            (uint256 _fee, uint256 _left) = _getFeeDetails(swapDesc.amountIn);

            /// @dev send fees to fee receiver
            (bool sent, ) = feeReceiver.call{value: _fee}("");
            /// @dev check if Ether have been sent
            require(
                sent,
                "UniswapV2Router01IntermediaryV2: Failed to send Ether"
            );

            amountIn = _left;
            fee = _fee;
        }

        emit Swap(
            address(swapDesc.router),
            swapDesc.path[0],
            swapDesc.path[swapDesc.path.length - 1],
            swapDesc.amountIn,
            fee
        );

        bytes memory payload = abi.encodeWithSignature(
            string.concat(
                swapDesc.swapFunc,
                "(uint256,address[],address,uint256)"
            ),
            swapDesc.amountOutMin,
            swapDesc.path,
            swapDesc.to,
            swapDesc.deadline
        );

        (bool success, bytes memory returnData) = address(swapDesc.router).call{
            value: amountIn
        }(payload);

        require(success, "UniswapV2Router01IntermediaryV2: !success");

        return uint256(bytes32(returnData));
    }

    function _swapExactTokensForETH(SwapDesc memory swapDesc)
        internal
        pathMinLength2(swapDesc.path)
        returns (uint256)
    {
        /// @dev if `path[0]` is zero the tx will fail because of SafeERC20
        IERC20 _fromToken = IERC20(swapDesc.path[0]);

        uint amountIn = swapDesc.amountIn;
        uint fee = 0;

        if (swapDesc.withFee) {
            (uint256 _fee, uint256 _left) = _getFeeDetails(swapDesc.amountIn);

            /// @dev send tokens to this contract for swapping (minus fees)
            _fromToken.safeTransferFrom(_msgSender(), address(this), _left);
            /// @dev send fees to fee receiver
            _fromToken.safeTransferFrom(_msgSender(), feeReceiver, _fee);

            /// @dev approve tx to router
            _fromToken.safeIncreaseAllowance(address(swapDesc.router), _left);

            amountIn = _left;
            fee = _fee;
        } else {
            /// @dev send tokens to this contract for swapping
            _fromToken.safeTransferFrom(
                _msgSender(),
                address(this),
                swapDesc.amountIn
            );

            /// @dev approve tx to router
            _fromToken.safeIncreaseAllowance(
                address(swapDesc.router),
                swapDesc.amountIn
            );
        }

        emit Swap(
            address(swapDesc.router),
            swapDesc.path[0],
            swapDesc.path[swapDesc.path.length - 1],
            swapDesc.amountIn,
            fee
        );

        bytes memory payload = abi.encodeWithSignature(
            string.concat(
                swapDesc.swapFunc,
                "(uint256,uint256,address[],address,uint256)"
            ),
            amountIn,
            swapDesc.amountOutMin,
            swapDesc.path,
            swapDesc.to,
            swapDesc.deadline
        );

        (bool success, bytes memory returnData) = address(swapDesc.router).call(
            payload
        );

        require(success, "UniswapV2Router01IntermediaryV2: !success");

        return uint256(bytes32(returnData));
    }
}