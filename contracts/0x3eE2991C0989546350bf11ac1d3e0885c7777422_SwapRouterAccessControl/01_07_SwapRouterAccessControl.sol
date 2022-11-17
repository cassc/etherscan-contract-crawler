pragma solidity ^0.8.0;

import "./AddressAccessControl.sol";
import "./BaseCoboSafeModuleAcl.sol";

// import "./libraries/Path.sol";

contract SwapRouterAccessControl is
    BaseCoboSafeModuleAcl,
    AddressAccessControl
{
    uint256 private constant ADDR_SIZE = 20;
    uint256 private constant FEE_SIZE = 3;
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;

    constructor(
        address _safeAddress,
        address _safeModule,
        address[] memory tokens
    ) {
        _setSafeAddressAndSafeModule(_safeAddress, _safeModule);
        _addAddresses(tokens);
    }

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        view
        onlySelf
    {
        onlySafeAddress(params.recipient);
        _checkAddress(params.tokenIn);
        _checkAddress(params.tokenOut);
    }

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(ExactInputParams calldata params)
        external
        view
        onlySelf
    {
        onlySafeAddress(params.recipient);
        _checkPath(params.path);
    }

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    function exactOutputSingle(ExactOutputSingleParams calldata params)
        external
        view
        onlySelf
    {
        onlySafeAddress(params.recipient);
        _checkAddress(params.tokenIn);
        _checkAddress(params.tokenOut);
    }

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    function exactOutput(ExactOutputParams calldata params) external view {
        onlySafeAddress(params.recipient);
        _checkPath(params.path);
    }

    function toAddress(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (address)
    {
        require(_start + 20 >= _start, "toAddress_overflow");
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(
                mload(add(add(_bytes, 0x20), _start)),
                0x1000000000000000000000000
            )
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint24)
    {
        require(_start + 3 >= _start, "toUint24_overflow");
        require(_bytes.length >= _start + 3, "toUint24_outOfBounds");
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }

    function _checkPath(bytes memory path) internal view returns (uint256 i) {
        i = 0;
        uint256 len = path.length;

        while (true) {
            _checkAddress(toAddress(path, i * 23));
            i++;
            if (len <= 23 * i) break;
        }
    }
}