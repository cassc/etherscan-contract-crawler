//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {BasePaymaster, IPaymaster, IRelayHub, IForwarder, GsnTypes} from "@opengsn/contracts/src/BasePaymaster.sol";

import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

/**
 * A Token-based paymaster.
 * - each request is paid for by the caller.
 * - preRelayedCall - pre-pay the maximum possible price for the tx
 * - postRelayedCall - refund the caller for the unused gas
 */
contract TokenPaymasterERC20toAny is BasePaymaster {
    function versionPaymaster()
        external
        view
        virtual
        override
        returns (string memory)
    {
        return "3.0.0+opengsn.token.ipaymaster";
    }

    IUniswapV2Router02 private immutable _router;
    mapping(address => bool) private _isTokenWhitelisted;
    IERC20 private _paymentToken;
    uint256 private _fee;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 public gasUsedByPost = 200000;
    uint256 public minGas =
        gasUsedByPost + PRE_RELAYED_CALL_GAS_LIMIT + FORWARDER_HUB_OVERHEAD;
    address public target;
    uint256 public minBalance = 0.02 ether;

    function getGasAndDataLimits()
        public
        view
        virtual
        override
        returns (IPaymaster.GasAndDataLimits memory limits)
    {
        return
            IPaymaster.GasAndDataLimits(
                PRE_RELAYED_CALL_GAS_LIMIT + FORWARDER_HUB_OVERHEAD,
                PRE_RELAYED_CALL_GAS_LIMIT,
                gasUsedByPost,
                CALLDATA_SIZE_LIMIT
            );
    }

    constructor(
        address uniswapRouter,
        address forwarder,
        IERC20 paymentToken,
        uint256 fee,
        IRelayHub hub
    ) {
        _router = IUniswapV2Router02(uniswapRouter);
        _paymentToken = paymentToken;
        _fee = fee;
        setTrustedForwarder(forwarder);
        setRelayHub(hub);
    }

    function setMinBalance(uint256 _minBalance) external onlyOwner {
        require(_minBalance > 0, "Wrong min balance");
        minBalance = _minBalance;
    }

    function setPaymentToken(address paymentToken) external onlyOwner {
        require(paymentToken != address(0), "Wrong Payment Token");
        _paymentToken = IERC20(paymentToken);
    }

    function getPaymentData() external view returns (address, uint256) {
        return (address(_paymentToken), _fee);
    }

    function setFee(uint256 fee) external onlyOwner {
        _fee = fee;
    }

    function whitelistToken(address token, bool whitelist) external onlyOwner {
        require(token != address(0), "Token address is 0");
        _isTokenWhitelisted[token] = whitelist;
    }

    function isTokenWhitelisted(address token) external view returns (bool) {
        return _isTokenWhitelisted[token];
    }

    function setGasUsedByPost(uint256 _gasUsedByPost) external onlyOwner {
        gasUsedByPost = _gasUsedByPost;
    }

    function setMinGas(uint256 _minGas) external onlyOwner {
        minGas = _minGas;
    }

    function setTarget(address _target) external onlyOwner {
        target = _target;
    }

    function _verifyPreRelayed(
        IForwarder.ForwardRequest calldata request,
        address tokenIn,
        uint256 amount
    ) private view {
        require(request.to == target, "Unknown target");
        require(_isTokenWhitelisted[tokenIn], "Token not whitelisted");
        require(
            relayHub.balanceOf(address(this)) >= minBalance,
            "Not enough balance on Paymaster"
        );
        address from = request.from;

        if (address(_paymentToken) == tokenIn) {
            require(
                _paymentToken.allowance(from, target) >= _fee + amount,
                "Fee+amount: Not enough allowance"
            );
            require(
                _paymentToken.balanceOf(from) >= _fee + amount,
                "Fee+amount: Not enough balance"
            );
        } else {
            require(
                _paymentToken.allowance(from, target) >= _fee,
                "Fee: Not enough allowance"
            );
            require(
                _paymentToken.balanceOf(from) >= _fee,
                "Fee: Not enough balance"
            );

            IERC20 token = IERC20(tokenIn);
            require(
                token.allowance(from, target) >= amount,
                "Not enough allowance"
            );
            require(token.balanceOf(from) >= amount, "Not enough balance");
        }
    }

    function _preRelayedCall(
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata,
        bytes calldata,
        uint256 maxPossibleGas
    ) internal virtual override returns (bytes memory, bool) {
        IForwarder.ForwardRequest calldata request = relayRequest.request;

        (address[] memory path, uint256 amount) = abi.decode(
            request.data[4:],
            (address[], uint256)
        );

        require(path.length >= 1, "Wrong path");
        _verifyPreRelayed(request, path[0], amount);

        uint256 ethMaxCharge = relayHub.calculateCharge(
            maxPossibleGas + gasUsedByPost,
            relayRequest.relayData
        );

        uint256 pathLength = path.length;
        if (path[pathLength - 1] == WETH) {
            require(
                _router.getAmountsOut(amount, path)[pathLength - 1] >
                    ethMaxCharge,
                "Not enough to pay for tx"
            );
        } else {
            address[] memory newPath = new address[](pathLength + 1);
            for (uint256 i = 0; i < pathLength; i++) {
                newPath[i] = path[i];
            }
            newPath[pathLength] = WETH;
            require(
                _router.getAmountsOut(amount, newPath)[pathLength] >
                    ethMaxCharge,
                "Not enough to pay for tx"
            );
        }

        require(request.gas >= minGas, "Not enough gas");

        return (
            abi.encode(
                request.from,
                path[pathLength - 1],
                path[pathLength - 1] == WETH
            ),
            false
        );
    }

    function _postRelayedCall(
        bytes calldata context,
        bool success,
        uint256 gasUsedWithoutPost,
        GsnTypes.RelayData calldata relayData
    ) internal virtual override {
        require(success, "No success");
        (address payer, address tokenOut, bool toEth) = abi.decode(
            context,
            (address, address, bool)
        );

        IRelayHub _relayHub = relayHub;
        uint256 ethActualCharge = _relayHub.calculateCharge(
            gasUsedWithoutPost + gasUsedByPost,
            relayData
        );

        if (toEth) {
            uint256 balance = address(this).balance;
            if (balance > ethActualCharge) {
                payable(payer).transfer(balance - ethActualCharge);
            }
        } else {
            address[] memory path = new address[](2);
            path[0] = tokenOut;
            path[1] = WETH;
            uint256 balance = IERC20(tokenOut).balanceOf(address(this));

            IERC20(tokenOut).approve(address(_router), balance);
            uint256 tookTokenOut = _router.swapTokensForExactETH(
                ethActualCharge,
                balance,
                path,
                address(this),
                // solhint-disable-next-line not-rely-on-time
                block.timestamp
            )[0];

            if (balance > tookTokenOut) {
                IERC20(tokenOut).transfer(payer, balance - tookTokenOut);
            }
        }

        relayHub.depositFor{value: ethActualCharge}(address(this));
    }

    receive() external payable override {
        emit Received(msg.value);
    }

    event Received(uint256 eth);
}