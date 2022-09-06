// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IWBNB.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2ERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "../libraries/Signature.sol";

contract AggregatorExecutor is Ownable {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;
    using ECDSA for bytes;
    using BitMaps for BitMaps.BitMap;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct SwapStep {
        address fromToken;
        address toToken;
        address pair;
        uint256 fee;
    }

    struct SignatureData {
        uint256 number;
        bytes data;
    }

    uint256 public DENOMINATOR_FEE = 10000;
    IWBNB public WBNB = IWBNB(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c); // mainnet

    address public BNB = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    EnumerableSet.AddressSet private signers;
    BitMaps.BitMap private usedNonce;

    modifier ensure(uint256 _deadline) {
        require(_deadline >= block.timestamp, 'AggregatorExecutor: EXPIRED');
        _;
    }

    //=========== external functions ============//
    function swap(SwapStep[] memory _steps, uint256 _amountIn, uint256 _amountOutMin, address payable _receiver, uint256 _deadline, SignatureData calldata _signature)
    external payable
    ensure(_deadline)
    {
        uint256 _length = _steps.length;
        checkSigner(_signature.data, _signature.number, _steps[0].fromToken, _steps[_length - 1].toToken);
        //check input eth
        if(_steps[0].fromToken == address(BNB) && msg.value > 0) {
            require(_amountIn == msg.value,"AggregatorExecutor: !msgValue");
            _steps[0].fromToken = address(WBNB);
            WBNB.deposit{value: _amountIn}();
        } else {
            IERC20(_steps[0].fromToken).safeTransferFrom(msg.sender, address(this), _amountIn);
        }

        //swap
        bool _needConvert = false;
        if (_steps[_length - 1].toToken == address(BNB)) {
            _steps[_length - 1].toToken = address(WBNB);
            _needConvert = true;
        }
        for (uint256 i = 0; i < _length; i++) {
            _swap(_steps[i], i == _length - 1, address(this));
        }

        uint256 _amountOut = IERC20(_steps[_length - 1].toToken).balanceOf(address(this));
        require(_amountOut >= _amountOutMin, "AggregatorExecutor: price impact too high");

        //send eth to user
        if (_needConvert) {
            WBNB.withdraw(_amountOut);
            (bool _sent,) = _receiver.call{value: _amountOut}("");
            require(_sent, "AggregatorExecutor: Failed to send BNB");
        } else {
            IERC20 _token = IERC20(_steps[_length - 1].toToken);
            _token.safeTransfer(_receiver, _token.balanceOf(address(this)));        }
    }

    function rescueFunds(IERC20 token, uint256 amount) external onlyOwner {
        token.safeTransfer(msg.sender, amount);
    }

    function destroy() external onlyOwner {
        selfdestruct(payable(msg.sender));
    }

    //=========== internal functions ============//
    function checkSigner(bytes memory _signature, uint256 _nonce, address _tokenIn, address _tokenOut) internal {
        require(!usedNonce.get(_nonce), "AggregatorExecutor: _nonce has been used");
        bytes32 _hash = keccak256(abi.encodePacked(address(this), _nonce, _tokenIn, _tokenOut)).toEthSignedMessageHash();
        address _signer = _hash.recover(_signature);
        require(signers.contains(_signer), "AggregatorExecutor: !verify signature fail");
        usedNonce.set(_nonce);
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
    internal returns(uint256 _amountOut){
        uint256 _amountInWithFee = _amountIn * (DENOMINATOR_FEE - _fee);
        if (_fromToken == _token0) {
            _amountOut = (_amountInWithFee * _reserve1) / (_reserve0 * DENOMINATOR_FEE + _amountInWithFee);
        } else {
            _amountOut = (_amountInWithFee * _reserve0) / (_reserve1 * DENOMINATOR_FEE + _amountInWithFee);
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
        (uint256 _reserve0, uint256 _reserve1, ) = _pair.getReserves();
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
        if(_action) {
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

    function nonceUsed(uint _nonce) external view returns(bool) {
        return usedNonce.get(_nonce);
    }

    function verifySignature(bytes memory _signature, uint256 _nonce, uint256 _amountOutMin) external view returns(bool) {
        require(!usedNonce.get(_nonce), "AggregatorExecutor: _nonce has been used");
        bytes32 _hash = keccak256(abi.encodePacked(address(this), _nonce, _amountOutMin)).toEthSignedMessageHash();
        address _signer = _hash.recover(_signature);
        return signers.contains(_signer);
    }

    //=========== Event ============//
    event TradeMining(address _user, address _pool, address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _amountOut);
    event SignerUpdated(address _signer, bool _action);
}