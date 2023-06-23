// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { IConnext } from "@connext/smart-contracts/contracts/core/connext/interfaces/IConnext.sol";
import { IXReceiver } from "@connext/smart-contracts/contracts/core/connext/interfaces/IXReceiver.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { iMultiTB } from "./interfaces/iMultiTB.sol";

contract MultiTB is IXReceiver, iMultiTB, Ownable {
    using SafeERC20 for IERC20;

    address immutable rescuer;

    address immutable connext;

    address immutable uniswapRouter;

    address immutable defaultToken;

    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    mapping(address => bool) public whitelisted;

    event Whitelisted(address indexed addr, bool indexed value);
    event TotalFail(
        bytes32 indexed transferId,
        address indexed sourceSender,
        uint32 indexed source
    );
    event PartialFail(
        bytes32 indexed transferId,
        address indexed sourceSender,
        uint32 indexed source
    );

    constructor(
        address _rescuer,
        address _connext,
        address _uniswapRouter,
        address[] memory whitelist,
        address _defaultToken
    ) {
        rescuer = _rescuer;
        connext = _connext;
        uniswapRouter = _uniswapRouter;
        defaultToken = _defaultToken;

        for (uint256 i = 0; i < whitelist.length; i++) {
            _setWhitelist(whitelist[i], true);
        }
    }

    /// @dev Add or remove addresses from whitelist
    /// @param addrs List of addresses
    /// @param values List of values - true for adding to whitelist, false for removing from whitelist
    function setWhitelist(
        address[] calldata addrs,
        bool[] calldata values
    ) external onlyOwner {
        require(addrs.length == values.length, "Wrong params. Unequal lengths");

        for (uint256 i = 0; i < addrs.length; i++) {
            _setWhitelist(addrs[i], values[i]);
        }
    }

    function _setWhitelist(address addr, bool value) internal {
        whitelisted[addr] = value;
        emit Whitelisted(addr, value);
    }

    //////////////////////////////////////// SOURCE CHAIN CODE //////////////////////////////////////////////////////

    /// @dev Call connext xcall
    /// @param destinationDomain Id(not chain id) of destination chain
    /// @param target Address of contract on destination chain to be called
    /// @param token Address of token, that will be bridged
    /// @param amount Amount of {token} tokens
    /// @param delegate Address of account, that can change bridge params
    /// @param slippage Max slippage on destination chain
    /// @param callDataParam Params for calling contract on destination chain
    function multiRun(
        uint32 destinationDomain,
        address target,
        address token,
        uint256 amount,
        address delegate,
        uint256 slippage,
        CallDataParam calldata callDataParam
    ) external payable {
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        _multiRun(
            msg.value,
            destinationDomain,
            target,
            token,
            amount,
            delegate,
            slippage,
            callDataParam
        );
    }

    /// @dev Same as multiRun, but token = usdc, delegate = msg.sender and check of callDataParam
    /// @param destinationDomain Id(not chain id) of destination chain
    /// @param target Address of contract on destination chain to be called
    /// @param amount Amount of {token} tokens
    /// @param slippage Max slippage on destination chain
    /// @param callDataParam Params for calling contract on destination chain
    function defaultMultiRun(
        uint32 destinationDomain,
        address target,
        // address token, // == defaultToken
        uint256 amount,
        // address delegate, // == msg.sender
        uint256 slippage,
        CallDataParam calldata callDataParam
    ) external payable {
        require(
            callDataParam.account == msg.sender,
            "Wrong receiver. Use multiRun for custom setup"
        );
        IERC20(defaultToken).transferFrom(msg.sender, address(this), amount);

        _multiRun(
            msg.value,
            destinationDomain,
            target,
            defaultToken,
            amount,
            msg.sender,
            slippage,
            callDataParam
        );
    }

    /// @dev Perform swap to {token} token and call connext xcall
    /// @param swapData Params to perform swap
    /// @param destinationDomain Id(not chain id) of destination chain
    /// @param target Address of contract on destination chain to be called
    /// @param token Address of token, that will be bridged
    /// @param delegate Address of account, that can change bridge params
    /// @param slippage Max slippage on destination chain
    /// @param callDataParam Params for calling contract on destination chain
    function multiSwapRun(
        SwapData calldata swapData,
        uint32 destinationDomain,
        address target,
        address token,
        address delegate,
        uint256 slippage,
        CallDataParam calldata callDataParam
    ) external payable {
        _multiSwapRun(
            swapData,
            destinationDomain,
            target,
            token,
            delegate,
            slippage,
            callDataParam
        );
    }

    /// @dev Same as multiSwawRun but with token = usdc, delegate = msg.sender and cllDataParam cheks
    /// @param destinationDomain Id(not chain id) of destination chain
    /// @param target Address of contract on destination chain to be called
    /// @param slippage Max slippage on destination chain
    /// @param callDataParam Params for calling contract on destination chain
    function defaultMultiSwapRun(
        SwapData calldata swapData,
        uint32 destinationDomain,
        address target,
        // address token, = usdc
        // address delegate, = msg.sender
        uint256 slippage,
        CallDataParam calldata callDataParam
    ) external payable {
        require(
            callDataParam.account == msg.sender,
            "Wrong receiver. Use multiSwapRun for custom setup"
        );

        _multiSwapRun(
            swapData,
            destinationDomain,
            target,
            defaultToken,
            msg.sender,
            slippage,
            callDataParam
        );
    }

    function _multiSwapRun(
        SwapData calldata swapData,
        uint32 destinationDomain,
        address target,
        address token,
        address delegate,
        uint256 slippage,
        CallDataParam calldata callDataParam
    ) internal {
        require(whitelisted[swapData.swapper], "Swapper is not whitelisted");
        require(_isCallDataSafe(swapData.swapCallData), "Unsafe calldata");

        uint256 rellayerFee = msg.value;
        if (swapData.token != ETH) {
            IERC20(swapData.token).transferFrom(
                msg.sender,
                address(this),
                swapData.amount
            );
            _approveIfNeeded(swapData.token, swapData.swapper);
        }

        uint256 swapEthValue;
        if (swapData.token == ETH) {
            swapEthValue = swapData.amount;
            rellayerFee -= swapData.amount;
        }

        (bool success, ) = swapData.swapper.call{value: swapEthValue}(
            swapData.swapCallData
        );

        require(success, "Can't swap");

        uint256 tokenBalance = IERC20(token).balanceOf(address(this));

        _multiRun(
            rellayerFee,
            destinationDomain,
            target,
            token,
            tokenBalance,
            delegate,
            slippage,
            callDataParam
        );
    }

    function _multiRun(
        uint256 rellayerFee,
        uint32 destinationDomain,
        address target,
        address token, // Can be immutable
        uint256 amount,
        address delegate,
        uint256 slippage,
        CallDataParam calldata callDataParam
    ) internal {
        require(msg.value > 0, "Zero relayer fee. Send some coins.");
        require(amount > 0, "Zero amount");

        require(
            callDataParam.refuleAmount <= amount,
            "Refule amount can't be grater, than amount"
        );

        _approveIfNeeded(token, connext);

        bytes memory callData = abi.encode(callDataParam);

        IConnext(connext).xcall{value: rellayerFee}(
            destinationDomain,
            target,
            token,
            delegate,
            amount,
            slippage,
            callData
        );
    }

    //////////////////////////////////////// DESTINATION CHAIN CODE //////////////////////////////////////////////////////

    /// @dev Function that connext will call on destination chain. Call arbitray contract depending on callData. Transfer tokens to rescuer, if call fails
    /// @param transferId Connext transferId
    /// @param amount Amount of {asset} that was transfered on this contract before call
    /// @param asset Address of token that was transfered
    /// @param originSender Address of caller on source chain
    /// @param origin Id(not chain id) of source chain
    /// @param callData If called as a result of MultiTB._multiRun, equal to abi.encode(CallDataParam)
    function xReceive(
        bytes32 transferId,
        uint256 amount,
        address asset,
        address originSender,
        uint32 origin,
        bytes memory callData
    ) external returns (bytes memory result) {
        try
            iMultiTB(address(this)).decodeAndRun(
                transferId,
                amount,
                asset,
                originSender,
                origin,
                callData
            )
        {} catch {
            // This happen if callData can't be decoded
            // This case should never happen, as long as xcall called from this contract
            // In such scenario we don't know user address
            // So we send it to address, ontrolled by us, to later send back user funds
            IERC20(asset).transfer(rescuer, amount);
            emit TotalFail(transferId, originSender, origin);
        }
    }

    /// @dev Decode callData and perform logic. Transfer tokens to params.account, if call fails. Needs to be external, so it can be used in try/catch block.
    /// @param transferId Connext transferId
    /// @param amount Amount of {asset} that was transfered on this contract before call
    /// @param asset Address of token that was transfered
    /// @param originSender Address of caller on source chain
    /// @param origin Id(not chain id) of source chain
    /// @param callData If called as a result of MultiTB._multiRun, equal to abi.encode(CallDataParam)
    function decodeAndRun(
        bytes32 transferId,
        uint256 amount,
        address asset,
        address originSender,
        uint32 origin,
        bytes memory callData
    ) external {
        CallDataParam memory params = abi.decode(callData, (CallDataParam));

        try iMultiTB(address(this)).run(amount, asset, params) {} catch {
            // Just send tokens to user, if call fails
            IERC20(asset).transfer(params.account, amount);
            emit PartialFail(transferId, originSender, origin);
        }
    }

    /// @dev Performs refule(if params.refule == true) and run code on params.target. Needs to be external, so it can be used in try/catch block.
    /// @param amount Amount of {asset} that was transfered on this contract before call
    /// @param asset Address of token that was transfered
    /// @param params Params of action to be run
    function run(
        uint256 amount,
        address asset,
        CallDataParam memory params
    ) external {
        if (params.refule) {
            amount -= params.refuleAmount;
            _refule(
                asset,
                params.refuleAmount,
                params.minEthOut,
                params.account
            );
        }

        _approveIfNeeded(asset, params.approveTarget);

        bytes memory targetCallData = _packCallData(params.chunks, amount);
        require(_isMemoryCallDataSafe(targetCallData), "Not safe callData");

        (bool success, ) = params.target.call(targetCallData);

        require(success, "Can't call contract");

        uint256 balance;
        if (params.finalToken == ETH) {
            balance = address(this).balance;
            if (balance > 0) {
                (bool transferSuccess, ) = payable(params.account).call{
                    value: balance
                }("");
                require(transferSuccess, "Can't transfer ether");
            }
        } else {
            balance = IERC20(params.finalToken).balanceOf(address(this));
            if (balance > 0) {
                IERC20(params.finalToken).safeTransfer(params.account, balance);
            }
        }
    }

    /// @dev Swap some tokens to coins using uniswap
    function _refule(
        address asset,
        uint256 amount,
        uint256 minEthOut,
        address account
    ) internal {
        _approveIfNeeded(asset, uniswapRouter);

        address[] memory path = new address[](2);
        path[0] = asset;
        path[1] = IUniswapV2Router02(uniswapRouter).WETH();

        IUniswapV2Router02(uniswapRouter).swapExactTokensForETH(
            amount,
            minEthOut,
            path,
            account,
            type(uint256).max
        );
    }

    /// @dev Same as chunks.join(value) in js
    function _packCallData(
        bytes[] memory chunks,
        uint256 value
    ) internal pure returns (bytes memory callData) {
        uint256 n = chunks.length;

        if (n == 1) {
            callData = abi.encodePacked(chunks[0]);
        } else if (n == 2) {
            callData = abi.encodePacked(chunks[0], value, chunks[1]);
        } else if (n == 3) {
            callData = abi.encodePacked(
                chunks[0],
                value,
                chunks[1],
                value,
                chunks[2]
            );
        } else if (n == 4) {
            callData = abi.encodePacked(
                chunks[0],
                value,
                chunks[1],
                value,
                chunks[2],
                value,
                chunks[3]
            );
        } else if (n == 5) {
            callData = abi.encodePacked(
                chunks[0],
                value,
                chunks[1],
                value,
                chunks[2],
                value,
                chunks[3],
                value,
                chunks[4]
            );
        } else if (n == 6) {
            callData = abi.encodePacked(
                chunks[0],
                value,
                chunks[1],
                value,
                chunks[2],
                value,
                chunks[3],
                value,
                chunks[4],
                value,
                chunks[5]
            );
        } else {
            callData = _packAnyCallData(chunks, value);
        }
    }

    /// @dev Do same as `packCallData`, but for arbitrary amount of chunks. Not gas efficient
    function _packAnyCallData(
        bytes[] memory chunks,
        uint256 value
    ) internal pure returns (bytes memory callData) {
        uint i;

        for (i = 0; i < chunks.length - 1; i++) {
            callData = abi.encodePacked(callData, chunks[i], value);
        }

        callData = abi.encodePacked(callData, chunks[i]);
    }

    /// @dev Check if funiction is not transferFrom
    function _isCallDataSafe(
        bytes calldata callData
    ) internal pure returns (bool) {
        bytes4 sig;

        assembly {
            sig := calldataload(callData.offset)
        }

        if (sig == IERC20.transferFrom.selector) {
            return false;
        }

        return true;
    }

    /// @dev Check if funiction is not transferFrom
    function _isMemoryCallDataSafe(
        bytes memory callData
    ) internal pure returns (bool) {
        bytes4 sig = bytes4(callData);

        if (sig == IERC20.transferFrom.selector) {
            return false;
        }

        return true;
    }

    function _approveIfNeeded(address token, address to) internal {
        if (
            IERC20(token).allowance(address(this), to) !=
            type(uint256).max
        ) {
            IERC20(token).approve(to, type(uint256).max);
        }
    }

    receive() external payable {}
}