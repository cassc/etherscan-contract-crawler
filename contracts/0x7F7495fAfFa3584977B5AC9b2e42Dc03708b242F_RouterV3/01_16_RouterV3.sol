//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-4.7.3/access/Ownable.sol";
import "@openzeppelin/contracts-4.7.3/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-4.7.3/token/ERC20/utils/SafeERC20.sol";
import "./../../interfaces/ISwapRouter02.sol";
import "./../../interfaces/IV3SwapRouter.sol";
import "./../../interfaces/IV2SwapRouter.sol";
import "./../../interfaces/IWETH.sol";

contract RouterV3 is Ownable {
    using SafeERC20 for IERC20;

    ISwapRouter02 public router;
    address public feeRecipient;
    address public uniswapRouterV3Address;
    address public wethAddress;
    bytes32 private constant FEE_RECIPIENT = keccak256(abi.encodePacked("FEE_RECIPIENT"));
    mapping(address => uint256) private tokenBalances;
    mapping(bytes32 => mapping(address => bool)) public roles;

    event TransferFailedToken(address tokenAddress);
    event TransferFailedBytes(bytes reason);
    event TransferFailedString(string reason);
    event GrantRole(bytes32 indexed role, address indexed account);
    event RevokeRole(bytes32 indexed role, address indexed account);
    event AddressChanged(address indexed newAddress);
    event FeeRecipientChanged(address indexed feeRecipient);
    event RouterSwap(address indexed receiver, uint256 indexed receivedAmount);
    event ReceivedEth(address indexed receiver, uint256 indexed receivedAmount);
    event ReceivedToken(address indexed tokenAddress, address indexed receiver, uint256 indexed receivedAmount);
    error ZeroAddress();
    error Unauthorized();

    constructor(
        address initialFeeRecipient,
        address initialUniswapRouterV3Address,
        address initialWethAddress
    )
        noZeroAddress(initialFeeRecipient)
        noZeroAddress(initialUniswapRouterV3Address)
        noZeroAddress(initialWethAddress)
    {
        grantRole(FEE_RECIPIENT, initialFeeRecipient);
        feeRecipient = initialFeeRecipient;
        uniswapRouterV3Address = initialUniswapRouterV3Address;
        router = ISwapRouter02(uniswapRouterV3Address);
        wethAddress = initialWethAddress;
    }

    modifier noZeroAddress(address addr) {
        if (addr == address(0)) {
            revert ZeroAddress();
        }
        _;
    }

    modifier onlyRole(bytes32 _role) {
        if (roles[_role][msg.sender] == false) {
            revert Unauthorized();
        }
        _;
    }

    function grantRole(bytes32 _role, address _account) public onlyOwner {
        roles[_role][_account] = true;

        emit GrantRole(_role, _account);
    }

    function revokeRole(bytes32 _role, address _account) public onlyOwner {
        roles[_role][_account] = false;

        emit RevokeRole(_role, _account);
    }

    function toUint160(uint256 value) public pure returns (uint160) {
        require(value <= type(uint160).max, "value does not fit in 160 bits");
        return uint160(value);
    }

    function toUint24(uint256 value) public pure returns (uint24) {
        require(value <= type(uint24).max, "value does not fit in 24 bits");
        return uint24(value);
    }

    function changeFeeRecipient(address newFeeRecipient) public onlyOwner noZeroAddress(newFeeRecipient) {
        revokeRole(FEE_RECIPIENT, feeRecipient);
        grantRole(FEE_RECIPIENT, newFeeRecipient);
        feeRecipient = newFeeRecipient;

        emit FeeRecipientChanged(newFeeRecipient);
    }

    function changeUniswapV3RouterAddress(address newUniswapV3RouterAddress)
        external
        onlyOwner
        noZeroAddress(newUniswapV3RouterAddress)
    {
        uniswapRouterV3Address = newUniswapV3RouterAddress;
        router = ISwapRouter02(uniswapRouterV3Address);

        emit AddressChanged(newUniswapV3RouterAddress);
    }

    function changeWethAddress(address newWethAddress) external onlyOwner noZeroAddress(newWethAddress) {
        wethAddress = newWethAddress;

        emit AddressChanged(newWethAddress);
    }

    function payOutToken(address[] memory tokenAddresses) external onlyRole(FEE_RECIPIENT) {
        uint256 length = tokenAddresses.length;
        for (uint256 i; i < length; ) {
            IERC20 token = IERC20(tokenAddresses[i]);
            uint256 amount = token.balanceOf(address(this));

            try token.transfer(msg.sender, amount) returns (bool success) {
                if (success) {
                    emit ReceivedToken(tokenAddresses[i], msg.sender, amount);
                } else {
                    emit TransferFailedToken(tokenAddresses[i]);
                }
            } catch Error(string memory reason) {
                emit TransferFailedString(reason);
            } catch (bytes memory reason) {
                emit TransferFailedBytes(reason);
            }

            unchecked {
                i++;
            }
        }
    }

    function payOutEth() external onlyRole(FEE_RECIPIENT) {
        uint256 ethBalance = address(this).balance;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            pop(call(gas(), caller(), selfbalance(), 0, 0, 0, 0))
        }

        emit ReceivedEth(msg.sender, ethBalance);
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 fee
    ) external payable returns (uint256 amountOut) {
        IERC20 token = IERC20(path[0]);
        token.safeTransferFrom(msg.sender, address(this), amountIn + fee);
        _checkAllowance(token, amountIn);
        amountOut = router.swapExactTokensForTokens(amountIn, amountOutMin, path, to);

        emit RouterSwap(to, amountOut);
    }

    function exactInputSingle(
        address tokenIn,
        address tokenOut,
        uint256 fee,
        address recipient,
        uint256 amountIn,
        uint256 amountOutMinimum,
        uint256 sqrtPriceLimitX96,
        uint256 serviceFee
    ) external payable returns (uint256 amountOut) {
        ISwapRouter02.ExactInputSingleParams memory params = IV3SwapRouter.ExactInputSingleParams(
            tokenIn,
            tokenOut,
            toUint24(fee),
            recipient,
            amountIn,
            amountOutMinimum,
            toUint160(sqrtPriceLimitX96)
        );

        if (wethAddress == tokenIn) {
            amountOut = router.exactInputSingle{ value: msg.value - serviceFee }(params);
        } else {
            IERC20 token = IERC20(tokenIn);
            token.safeTransferFrom(msg.sender, address(this), amountIn + serviceFee);
            _checkAllowance(token, amountIn);

            if (wethAddress == tokenOut) {
                params.recipient = address(this);
                amountOut = router.exactInputSingle(params);
                IWETH(wethAddress).withdraw(amountOut);
                payable(recipient).transfer(amountOut);
            } else {
                amountOut = router.exactInputSingle(params);
            }
        }

        emit RouterSwap(recipient, amountOut);
    }

    function exactInput(
        bytes memory path,
        address recipient,
        uint256 amountIn,
        uint256 amountOutMinimum,
        uint256 serviceFee,
        address tokenIn,
        address tokenOut
    ) external payable returns (uint256 amountOut) {
        ISwapRouter02.ExactInputParams memory params = IV3SwapRouter.ExactInputParams({
            path: path,
            recipient: recipient,
            amountIn: amountIn,
            amountOutMinimum: amountOutMinimum
        });

        if (wethAddress == tokenIn) {
            amountOut = router.exactInput{ value: msg.value - serviceFee }(params);
        } else {
            IERC20 token = IERC20(tokenIn);
            token.safeTransferFrom(msg.sender, address(this), amountIn + serviceFee);
            _checkAllowance(token, amountIn);

            if (wethAddress == tokenOut) {
                params.recipient = address(this);
                amountOut = router.exactInput(params);
                IWETH(wethAddress).withdraw(amountOut);
                payable(recipient).transfer(amountOut);
            } else {
                amountOut = router.exactInput(params);
            }
        }

        emit RouterSwap(recipient, amountOut);
    }

    receive() external payable {}

    function _checkAllowance(IERC20 inputToken, uint256 amount) private {
        if (inputToken.allowance(address(this), uniswapRouterV3Address) < amount) {
            inputToken.safeApprove(uniswapRouterV3Address, type(uint256).max);
        }
    }
}