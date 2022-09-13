// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IWBNB.sol";
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

    struct SwapStep {
        address fromToken;
        address toToken;
        address pair;
        uint256 fee;
    }

    uint256 public DENOMINATOR_FEE = 10000;
    IWBNB public WBNB = IWBNB(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c); // mainnet

    address public BNB = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    EnumerableSet.AddressSet private signers;
    mapping(bytes => bool) public oldSignatures;

    modifier ensure(uint256 _deadline) {
        require(_deadline >= block.timestamp, 'AggregatorExecutor: EXPIRED');
        _;
    }

    //=========== external functions ============//
    function swap(SwapStep[] memory _steps, uint256 _amountIn, uint256 _amountOutMin, address payable _receiver, uint256 _deadline, bytes calldata _signature)
    external payable
    ensure(_deadline)
    {
        uint256 _length = _steps.length;
        checkSigner(_signature, _steps, _deadline);
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
        } else {
            IERC20(_steps[0].fromToken).safeTransferFrom(msg.sender, address(this), _amountIn);
        }

        for (uint256 i = 0; i < _length; i++) {
            _swap(_steps[i], i == _length - 1, address(this));
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

    function swapExactOutput(SwapStep[] memory _steps, uint256 _amountInMax, uint256 _exactAmountOut, address payable _receiver, uint256 _deadline, bytes calldata _signature)
    external payable
    ensure(_deadline)
    {
        uint256 _length = _steps.length;
        checkSigner(_signature, _steps, _deadline);

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
            IERC20(_steps[0].fromToken).safeTransferFrom(msg.sender, address(this), _amountIn);
        }

        //swap
        for (uint256 i = 0; i < _length; i++) {
            _swap(_steps[i], i == _length - 1, address(this));
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


    function rescueFunds(IERC20 token, uint256 amount) external onlyOwner {
        token.safeTransfer(msg.sender, amount);
    }

    function destroy() external onlyOwner {
        selfdestruct(payable(msg.sender));
    }

    //=========== internal functions ============//
    function checkSigner(bytes memory _signature, SwapStep[] memory _steps, uint256 _deadline) internal {
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
            IUniswapV2Pair _pair = IUniswapV2Pair(_step.pair);
            require(address(_pair) != address(0), "AggregatorExecutor: Pair address is zero");
            address _token0 = _pair.token0();
            (uint256 _reserve0, uint256 _reserve1,) = _pair.getReserves();
            amountIn = _token0 == _step.toToken ? _getAmountIn(amountIn, _reserve1, _reserve0, _step.fee) : _getAmountIn(amountIn, _reserve0, _reserve1, _step.fee);
        }
    }

    function _swap(
        SwapStep memory _step,
        bool _finish,
        address _receiver
    ) internal returns (uint256 _amountOut) {

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
        _pair.swap(_amount0Out, _amount1Out, _receiver, new bytes(0));

        //event trade mining
        emit TradeMining(tx.origin, address(_pair), _step.fromToken, _step.toToken, _amountIn, _amountOut);
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

    function getAmountIns(SwapStep[] memory _steps, uint256 _amountOut) external view returns (uint256 _amountIn) {
        return _getAmountIns(_steps, _amountOut);
    }

    function getAmountIn(uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 fee) external view returns (uint256 amountIn)
    {
        amountIn = _getAmountIn(amountOut, reserveIn, reserveOut, fee);
    }
    //=========== Event ============//
    event TradeMining(address _user, address _pool, address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _amountOut);
    event SignerUpdated(address _signer, bool _action);
    event TradePath(address _fromToken, address _toToken, uint256 _amountIn, uint256 _amountOut);
}