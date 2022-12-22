// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IWBNB.sol";
import "../interfaces/IBakerySwapPair.sol";
import "../interfaces/IPool.sol";
import "../interfaces/ICurve.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2ERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract AggregatorExecutor is Ownable {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;
    using ECDSA for bytes;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 constant UNI_SWAP = 0;
    uint256 constant BAKERY_SWAP = 1;
    uint256 constant CURVE = 2;
    uint256 constant WOMBAT = 3;
    uint256 constant DODO = 4;
    uint256 constant CURVE_UNDERLYING = 5; // call to exchange_underlying function
    uint256 constant PANCAKE_STABLE_SWAP = 6;

    struct SwapStep {
        address fromToken;
        address toToken;
        address pair;
        uint256 fee;
        uint256 protocol;
    }

    uint256 public DENOMINATOR_FEE = 10000;
    IWBNB public WBNB = IWBNB(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c); // mainnet

    address public constant PANDORA_ROUTER = 0xf7E5756DA9e2e8C6F2254EAA20f7A4e7e09646e2;

    address public BNB = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    EnumerableSet.AddressSet private signers;
    mapping(bytes => bool) public oldSignatures;

    mapping(address => mapping(address => int128)) public curvePools;

    modifier ensure(uint256 _deadline) {
        require(_deadline >= block.timestamp, 'AggregatorExecutor: EXPIRED');
        _;
    }

    modifier onlyPandora() {
        require(msg.sender == PANDORA_ROUTER, "AggregatorExecutor: only PANDORA_ROUTER");
        _;
    }

    //=========== external functions ============//
    function rescueFunds(IERC20 token, uint256 amount) external onlyOwner {
        token.safeTransfer(msg.sender, amount);
    }

    function destroy() external onlyOwner {
        selfdestruct(payable(msg.sender));
    }

    //swap exact input
    function swapExactInput(SwapStep[] memory _steps, uint256 _amountIn, uint256 _amountOutMin, address payable _receiver) public payable onlyPandora {
        uint256 _length = _steps.length;
        //check input eth
        bool _isFromETH = _steps[0].fromToken == address(BNB);
        bool _isToETH = _steps[_length - 1].toToken == address(BNB);

        if (_isFromETH) {
            _steps[0].fromToken = address(WBNB);
        }
        if (_isToETH) {
            _steps[_length - 1].toToken = address(WBNB);
        }

        //payment
        if (_isFromETH) {
            require(msg.value >= _amountIn, "AggregatorExecutor: !input");
            WBNB.deposit{value : _amountIn}();
            //send eth exceed back
            if (msg.value > _amountIn) {
                //always success
                (bool _sent,) = payable(tx.origin).call{value : msg.value - _amountIn}("");
            }
        }

        for (uint256 i = 0; i < _length; i++) {
            _swap(_steps[i], address(this));
        }

        uint256 _amountOut = IERC20(_steps[_length - 1].toToken).balanceOf(address(this));
        require(_amountOut >= _amountOutMin, "AggregatorExecutor: price impact too high");

        //send eth to user
        if (_isToETH) {
            WBNB.withdraw(_amountOut);
            (bool _sent,) = _receiver.call{value : _amountOut}("");
            require(_sent, "AggregatorExecutor: Failed to send BNB");
        } else {
            IERC20 _token = IERC20(_steps[_length - 1].toToken);
            _token.safeTransfer(_receiver, _amountOut);
        }
        emit TradePath(_steps[0].fromToken, _steps[_length - 1].toToken, _amountIn, _amountOut);
    }

    //swap exact output
    function swapExactOutput(SwapStep[] memory _steps, uint256 _amountInMax, uint256 _exactAmountOut, address payable _receiver) public payable onlyPandora {
        uint256 _length = _steps.length;
        //replace eth address
        bool _isFromETH = _steps[0].fromToken == address(BNB);
        bool _isToETH = _steps[_length - 1].toToken == address(BNB);
        if (_isFromETH) {
            _steps[0].fromToken = address(WBNB);
        }
        if (_isToETH) {
            _steps[_length - 1].toToken = address(WBNB);
        }
        uint256 _amountIn = _getAmountIns(_steps, _exactAmountOut);
        require(_amountIn <= _amountInMax, "AggregatorExecutor: amount in");


        //payment
        if (_isFromETH) {
            require(msg.value >= _amountIn, "AggregatorExecutor: !input");
            WBNB.deposit{value : _amountIn}();
            //send eth exceed back
            if (msg.value > _amountIn) {
                //always success
                (bool _sent,) = payable(tx.origin).call{value : msg.value - _amountIn}("");
            }
        } else {
            // send exceed token
            if (_amountInMax > _amountIn) {
                IERC20 _token = IERC20(_steps[0].fromToken);
                _token.safeTransfer(tx.origin, _amountInMax - _amountIn);
            }
        }

        //swap
        for (uint256 i = 0; i < _length; i++) {
            _swap(_steps[i], address(this));
        }

        uint256 _amountOut = IERC20(_steps[_length - 1].toToken).balanceOf(address(this));
        require(_amountOut >= _exactAmountOut, "AggregatorExecutor: price impact too high");

        //send eth to user
        if (_isToETH) {
            WBNB.withdraw(_amountOut);
            (bool _sent,) = _receiver.call{value : _amountOut}("");
            require(_sent, "AggregatorExecutor: Failed to send BNB");
        } else {
            IERC20 _token = IERC20(_steps[_length - 1].toToken);
            _token.safeTransfer(_receiver, _amountOut);
        }
        emit TradePath(_steps[0].fromToken, _steps[_length - 1].toToken, _amountIn, _amountOut);
    }

    function callBytes(address _receiver, bytes calldata _data) external payable {
        (
        SwapStep[] memory _steps,
        bytes memory _signature,
        bytes4 _selector,
        uint256 _amountIn,
        uint256 _amountOut,
        uint256 _deadline
        ) = abi.decode(_data, (SwapStep[], bytes, bytes4, uint256, uint256, uint256));
        checkSigner(_signature, _steps, _deadline);
        if (_selector == this.swapExactInput.selector) {
            swapExactInput(_steps, _amountIn, _amountOut, payable(_receiver));
        } else if (_selector == this.swapExactOutput.selector) {
            swapExactOutput(_steps, _amountIn, _amountOut, payable(_receiver));
        } else {
            revert("AggregatorExecutor: !selector");
        }
    }

    function addTokenIndex(address _pool, address[] memory _tokens, int128[] memory _indexes) external onlyOwner {
        require(_tokens.length == _indexes.length, "AggregatorExecutor: !length");
        for (uint256 i = 0; i < _tokens.length; i++) {
            curvePools[_pool][_tokens[i]] = _indexes[i];
        }
    }


    //=========== internal functions ============//
    function checkSigner(bytes memory _signature, SwapStep[] memory _steps, uint256 _deadline) internal {
        require(_deadline >= block.timestamp, 'AggregatorExecutor: EXPIRED');
        bytes32 _hash = keccak256(abi.encode(address(this), _steps, _deadline)).toEthSignedMessageHash();
        address _signer = _hash.recover(_signature);
        require(signers.contains(_signer), "AggregatorExecutor: !verify signature fail");
        require(oldSignatures[_signature] == false, "AggregatorExecutor: signature is used");
        oldSignatures[_signature] = true;
    }

    function _getAmountOut
    (
        address _fromToken,
        address _toToken,
        uint256 _amountIn,
        uint256 _reserve0,
        uint256 _reserve1,
        uint256 _fee,
        address _token0)
    internal returns (uint256 _amountOut){
        uint256 _amountInWithFee = _amountIn * (DENOMINATOR_FEE - _fee);
        if (_fromToken == _token0) {
            _amountOut = (_amountInWithFee * _reserve1) / (_reserve0 * DENOMINATOR_FEE + _amountInWithFee);
        } else {
            _amountOut = (_amountInWithFee * _reserve0) / (_reserve1 * DENOMINATOR_FEE + _amountInWithFee);
        }
    }

    function _getAmountIn
    (
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 fee
    ) internal view returns (uint256 amountIn) {
        uint256 numerator = reserveIn * amountOut * DENOMINATOR_FEE;
        uint256 denominator = (reserveOut - amountOut) * (DENOMINATOR_FEE - fee);
        amountIn = numerator / denominator + 1;
    }

    function _getAmountIns(SwapStep[] memory _steps, uint256 _amountOut) internal view returns (uint256 amountIn) {
        amountIn = _amountOut;
        for (uint256 i = _steps.length; i > 0;) {
            --i;
            SwapStep memory _step = _steps[i];
            if (_step.protocol == BAKERY_SWAP || _step.protocol == UNI_SWAP) {
                IUniswapV2Pair _pair = IUniswapV2Pair(_step.pair);
                require(address(_pair) != address(0), "AggregatorExecutor: Pair address is zero");
                address _token0 = _pair.token0();
                (uint256 _reserve0, uint256 _reserve1,) = _pair.getReserves();
                amountIn = _token0 == _step.toToken ? _getAmountIn(amountIn, _reserve1, _reserve0, _step.fee) : _getAmountIn(amountIn, _reserve0, _reserve1, _step.fee);
            } else if (_step.protocol == WOMBAT) {
                (amountIn,) = IPool(_step.pair).quoteAmountIn(
                    _step.fromToken,
                    _step.toToken,
                    int256(amountIn)
                );
            }
        }
    }

    ////////////////////
    function _swap(
        SwapStep memory _step,
        address _receiver
    ) internal {
        //get info
        if (_step.protocol == BAKERY_SWAP || _step.protocol == UNI_SWAP) {
            _swapUni(_step, address(this));
        } else if (_step.protocol == WOMBAT) {
            _swapWombat(_step);
        } else if (_step.protocol == CURVE || _step.protocol == CURVE_UNDERLYING || _step.protocol == PANCAKE_STABLE_SWAP) {
            _swapCurve(_step);
        }
    }

    function _swapUni(SwapStep memory _step, address _receiver) internal returns (uint256 _amountOut) {
        //get info
        IUniswapV2Pair _pair = IUniswapV2Pair(_step.pair);
        require(address(_pair) != address(0), "AggregatorExecutor: Pair address is zero");
        address _token0 = _pair.token0();
        uint256 _amountIn = IERC20(_step.fromToken).balanceOf(address(this));

        //get reserve
        (uint256 _reserve0, uint256 _reserve1,) = _pair.getReserves();
        _amountOut = _getAmountOut(_step.fromToken, _step.toToken, _amountIn, _reserve0, _reserve1, _step.fee, _token0);

        // get amount out
        (uint256 _amount0Out, uint256 _amount1Out) = _step.fromToken == _token0 ? (uint256(0), _amountOut) : (_amountOut, uint256(0));

        //swap
        IERC20(_step.fromToken).safeTransfer(address(_pair), _amountIn);
        if (_step.protocol == BAKERY_SWAP) {
            IBakerySwapPair(address(_pair)).swap(_amount0Out, _amount1Out, _receiver);
        } else {
            _pair.swap(_amount0Out, _amount1Out, _receiver, new bytes(0));
        }
        //event trade mining
        emit TradeMining(tx.origin, address(_pair), _step.fromToken, _step.toToken, _amountIn, _amountOut);
    }

    function _swapWombat(SwapStep memory _step) internal {
        uint256 _amountIn = IERC20(_step.fromToken).balanceOf(address(this));
        (uint256 _amountOut,) = IPool(_step.pair).swap(
            _step.fromToken,
            _step.toToken,
            _amountIn,
            0, // minimum amount received is ensured on calling function
            address(this),
            type(uint256).max // deadline is ensured on calling function
        );
        emit TradeMining(tx.origin, address(_step.pair), _step.fromToken, _step.toToken, _amountIn, _amountOut);
    }

    function _swapCurve(SwapStep memory _step) internal {
        uint256 _amountIn = IERC20(_step.fromToken).balanceOf(address(this));
        if (_step.protocol == CURVE) {
            ICurve(_step.pair).exchange(curvePools[_step.pair][_step.fromToken], curvePools[_step.pair][_step.toToken], _amountIn, 0);

        } else if(_step.protocol == CURVE_UNDERLYING) {
            ICurve(_step.pair).exchange_underlying(curvePools[_step.pair][_step.fromToken], curvePools[_step.pair][_step.toToken], _amountIn, 0);

        } else if(_step.protocol == PANCAKE_STABLE_SWAP) {
            ICurve(_step.pair).exchange(uint256(uint128(curvePools[_step.pair][_step.fromToken])), uint256(uint128(curvePools[_step.pair][_step.toToken])), _amountIn, 0);
        }
       
        uint256 _amountOut = IERC20(_step.toToken).balanceOf(address(this));
        emit TradeMining(tx.origin, address(_step.pair), _step.fromToken, _step.toToken, _amountIn, _amountOut);
    }
    receive() external payable {}

    //=========== Restrict ============//
    function changeSigner(address _signer, bool _action) external onlyOwner {
        if (_action) {
            require(signers.add(_signer), "AggregatorExecutor: !added");
        } else {
            require(signers.remove(_signer), "AggregatorExecutor: !removed");
        }
        emit SignerUpdated(_signer, _action);
    }

    //=========== View functions ========//
    function getSigner() external view returns (address[] memory) {
        return signers.values();
    }

    function isSigner(address _operator) external view returns (bool) {
        return signers.contains(_operator);
    }

    function verifySignature(bytes memory _signature, SwapStep[] memory _steps) external view returns (bool) {
        bytes32 _hash = keccak256(abi.encode(address(this), _steps)).toEthSignedMessageHash();
        address _signer = _hash.recover(_signature);
        return signers.contains(_signer);
    }

    function approveSpendingByPool(address[] calldata tokens, address pool) external onlyOwner {
        for (uint256 i; i < tokens.length; ++i) {
            IERC20(tokens[i]).safeApprove(pool, 0);
            IERC20(tokens[i]).safeApprove(pool, type(uint256).max);
        }
    }

    function checkCallBytes(bytes memory _data) external pure returns (SwapStep[] memory, bytes memory, bytes4, uint256, uint256, uint256) {
        (
        SwapStep[] memory _steps,
        bytes memory _signature,
        bytes4 _selector,
        uint256 _amountIn,
        uint256 _amountOut,
        uint256 _deadline
        ) = abi.decode(_data, (SwapStep[], bytes, bytes4, uint256, uint256, uint256));
        return (_steps, _signature, _selector, _amountIn, _amountOut, _deadline);
    }

    function getAmountIns(bytes memory _data) external view returns (uint256) {
        (
        SwapStep[] memory _steps,
        bytes memory _signature,
        bytes4 _selector,
        uint256 _amountIn,
        uint256 _amountOut,
        uint256 _deadline
        ) = abi.decode(_data, (SwapStep[], bytes, bytes4, uint256, uint256, uint256));
        return _getAmountIns(_steps, _amountOut);
    }

    //=========== Event ============//
    event TradeMining(address _user, address _pool, address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _amountOut);
    event SignerUpdated(address _signer, bool _action);
    event TradePath(address _fromToken, address _toToken, uint256 _amountIn, uint256 _amountOut);
}