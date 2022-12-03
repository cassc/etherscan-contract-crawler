// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IPancakeRouter02.sol";

contract MetaGold is AccessControl, Pausable {

    struct SwapData {
        uint amountIn;
        uint amountOut;
        bool exactOutput;
    }

    uint256 public constant MAX_INT = 2**256 - 1;

    // role that can withdraw funds from the contract
    bytes32 public constant BENEFICIARY_ROLE = keccak256("BENEFICIARY_ROLE");
    // can pause minting and transfers
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    IPancakeRouter02 public pancakeRouter;
    address public fpsTokenAddress;
    address public reserveTokenAddress;

    mapping(address => address[]) private _reserveConvertPaths;
    mapping(address => address[]) private _fpsConvertPaths;

    event AcceptedTokenAdded(address[] reserveConvertPath, address[] fpsConvertPath);

    event AcceptedTokenRemoved(address tokenAddress);

    event MetaGoldTransaction(
        address inputTokenAddress,
        SwapData reserveSwap,
        SwapData fpsSwap,
        SwapData reserveSwapActual,
        SwapData fpsSwapActual,
        bytes data,
        uint deadline
    );

    constructor(
        address admin,
        address beneficiary,
        address pauser,
        address pancakeRouterAddress,
        address _fpsTokenAddress,
        address _reserveTokenAddress
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(BENEFICIARY_ROLE, beneficiary);
        _grantRole(PAUSER_ROLE, pauser);
        pancakeRouter = IPancakeRouter02(pancakeRouterAddress);
        fpsTokenAddress = _fpsTokenAddress;
        reserveTokenAddress = _reserveTokenAddress;
    }

    receive() external payable {}

    /**
    * @notice Facilitates the purchase of MetaGold - a proprietary web2 asset - for crypto currencies
    * @notice DO NOT attempt to call this from anywhere other than the official front-end, as it can lead to your funds being stuck
    */
    function metaGoldTransaction(
        address inputTokenAddress,
        SwapData calldata reserveSwap,
        SwapData calldata fpsSwap,
        bytes memory data,
        uint deadline
    ) external payable whenNotPaused returns (SwapData memory reserveSwapActual, SwapData memory fpsSwapActual) {
        require(
            _reserveConvertPaths[inputTokenAddress].length > 0 && _fpsConvertPaths[inputTokenAddress].length > 0,
            "MetaGold: Token not accepted"
        );

        if (pancakeRouter.WETH() != inputTokenAddress) {
            require(msg.value == 0, "MetaGold: Only send ETH if inputTokenAddress is WETH");
            // transferring the maximum amount of input tokens needed from the user to this contract
            IERC20(inputTokenAddress).transferFrom(msg.sender, address(this), reserveSwap.amountIn + fpsSwap.amountIn);
        } else {
            require(msg.value == reserveSwap.amountIn + fpsSwap.amountIn, "MetaGold: Incorrect ETH amount sent");
        }

        // reserve swap
        reserveSwapActual = _processSwapData(
            reserveSwap,
            _reserveConvertPaths[inputTokenAddress],
            deadline
        );

        // fps swap
        fpsSwapActual = _processSwapData(
            fpsSwap,
            _fpsConvertPaths[inputTokenAddress],
            deadline
        );

        // refunding leftover tokens or ETH to the user
        uint totalAmountIn = reserveSwap.amountIn + fpsSwap.amountIn;
        uint totalAmountInActual = reserveSwapActual.amountIn + fpsSwapActual.amountIn;
        if (totalAmountInActual < totalAmountIn) {
            if (inputTokenAddress == pancakeRouter.WETH()) {
                payable(msg.sender).transfer(totalAmountIn - totalAmountInActual);
            } else {
                IERC20(inputTokenAddress).transfer(msg.sender, totalAmountIn - totalAmountInActual);
            }
        }

        emit MetaGoldTransaction(
            inputTokenAddress,
            reserveSwap,
            fpsSwap,
            reserveSwapActual,
            fpsSwapActual,
            data,
            deadline
        );
    }

    function _processSwapData(
        SwapData memory swapData,
        address[] storage path,
        uint deadline
    ) internal returns (SwapData memory actualSwapData) {
        actualSwapData = swapData;
        if (path[0] != path[path.length - 1] && swapData.amountIn > 0) {
            uint[] memory amounts = _swap(
                swapData.exactOutput,
                swapData.amountIn,
                swapData.amountOut,
                path,
                deadline
            );
            if (swapData.exactOutput) {
                actualSwapData.amountIn = amounts[0];
            } else {
                actualSwapData.amountOut = amounts[amounts.length - 1];
            }
        }
    }

    function _swap(
        bool exactOutput,
        uint amountIn,
        uint amountOut,
        address[] storage path,
        uint deadline
    ) internal returns (uint256[] memory) {
        if (pancakeRouter.WETH() == path[0]) {
            if (exactOutput) {
                return pancakeRouter.swapETHForExactTokens{value: amountIn}(amountOut, path, address(this), deadline);
            } else {
                return pancakeRouter.swapExactETHForTokens{value: amountIn}(amountOut, path, address(this), deadline);
            }
        } else if (pancakeRouter.WETH() == path[path.length - 1]) {
            if (exactOutput) {
                return pancakeRouter.swapTokensForExactETH(amountOut, amountIn, path, address(this), deadline);
            }  else {
                return pancakeRouter.swapExactTokensForETH(amountIn, amountOut, path, address(this), deadline);
            }
        } else {
            if (exactOutput) {
                return pancakeRouter.swapTokensForExactTokens(amountOut, amountIn, path, address(this), deadline);
            } else {
                return pancakeRouter.swapExactTokensForTokens(amountIn, amountOut, path, address(this), deadline);
            }
        }
    }

    function setPancakeRouter(address pancakeRouterAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        pancakeRouter = IPancakeRouter02(pancakeRouterAddress);
    }

    function setReserveTokenAddress(address _reserveTokenAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        reserveTokenAddress = _reserveTokenAddress;
    }

    function setFpsTokenAddress(address _fpsTokenAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        fpsTokenAddress = _fpsTokenAddress;
    }

    function setPaused(bool _paused) external onlyRole(PAUSER_ROLE) {
        if (_paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    function addAcceptedToken(
        address[] calldata reserveConvertPath,
        address[] calldata fpsConvertPath
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            reserveConvertPath[reserveConvertPath.length - 1] == reserveTokenAddress,
            "MetaGold: Can only add reserveConvertPath ending in the reserveTokenAddress"
        );
        require(
            fpsConvertPath[fpsConvertPath.length - 1] == fpsTokenAddress,
            "MetaGold: Can only add fpsConvertPath ending in the fpsTokenAddress"
        );
        require(
            reserveConvertPath[0] == fpsConvertPath[0],
            "MetaGold: fpsConvertPath and reserveConvertPath must start from the same address"
        );

        // approve token
        IERC20(reserveConvertPath[0]).approve(address(pancakeRouter), MAX_INT);

        _reserveConvertPaths[reserveConvertPath[0]] = reserveConvertPath;
        _fpsConvertPaths[fpsConvertPath[0]] = fpsConvertPath;

        emit AcceptedTokenAdded(reserveConvertPath, fpsConvertPath);
    }

    function removeAcceptedToken(address tokenAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _reserveConvertPaths[tokenAddress].length > 0 && _fpsConvertPaths[tokenAddress].length > 0,
            "MetaGold: Cannot remove token that was not added"
        );

        // revoke approval
        IERC20(tokenAddress).approve(address(pancakeRouter), 0);

        delete _reserveConvertPaths[tokenAddress];
        delete _fpsConvertPaths[tokenAddress];

        emit AcceptedTokenRemoved(tokenAddress);
    }

    function withdrawEth(uint amount, address beneficiary) external onlyRole(BENEFICIARY_ROLE) {
        payable(beneficiary).transfer(amount);
    }

    function withdrawTokens(address tokenAddress, uint amount, address beneficiary) external onlyRole(BENEFICIARY_ROLE) {
        IERC20(tokenAddress).transfer(beneficiary, amount);
    }

    function getReserveConvertPath(address tokenAddress) external view returns (address[] memory) {
        return _reserveConvertPaths[tokenAddress];
    }

    function getFpsConvertPath(address tokenAddress) external view returns (address[] memory) {
        return _fpsConvertPaths[tokenAddress];
    }
}