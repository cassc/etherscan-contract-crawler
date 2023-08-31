// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./interfaces/ISushiXSwapV2.sol";

contract SushiXSwapV2 is ISushiXSwapV2, Ownable, Multicall {
    using SafeERC20 for IERC20;

    IRouteProcessor public rp;

    mapping(address => bool) public approvedAdapters;
    mapping(address => bool) privilegedUsers;

    address constant NATIVE_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    IWETH public immutable weth;

    uint8 private unlocked = 1;
    uint8 private paused = 1;

    constructor(IRouteProcessor _rp, address _weth) {
        rp = _rp;
        weth = IWETH(_weth);
    }

    modifier onlyApprovedAdapters(address _adapter) {
        require(approvedAdapters[_adapter], "Not Approved Adatper");
        _;
    }

    modifier onlyOwnerOrPrivilegedUser() {
        require(
            msg.sender == owner() || privilegedUsers[msg.sender] == true,
            "SushiXSwapV2 not owner or privy user"
        );
        _;
    }

    modifier lock() {
        require(unlocked == 1, "SushiXSwapV2 is locked");
        require(paused == 1, "SushiXSwapV2 is paused");
        unlocked = 2;
        _;
        unlocked = 1;
    }

    function setPrivileged(address user, bool priviledge) external onlyOwner {
        privilegedUsers[user] = priviledge;
    }

    function pause() external onlyOwnerOrPrivilegedUser {
        paused = 2;
    }

    function resume() external onlyOwnerOrPrivilegedUser {
        paused = 1;
    }

    function updateAdapterStatus(
        address _adapter,
        bool _status
    ) external onlyOwner {
        approvedAdapters[_adapter] = _status;
    }

    function updateRouteProcessor(
        address newRouteProcessor
    ) external onlyOwner {
        rp = IRouteProcessor(newRouteProcessor);
    }

    function swap(bytes memory _swapData) external payable override lock {
        // just swap
        _swap(_swapData);
    }

    function _swap(bytes memory _swapData) internal {
        // internal just swap

        IRouteProcessor.RouteProcessorData memory rpd = abi.decode(
            _swapData,
            (IRouteProcessor.RouteProcessorData)
        );

        if (rpd.tokenIn != NATIVE_ADDRESS) {
            IERC20(rpd.tokenIn).safeTransferFrom(
                msg.sender,
                address(this),
                rpd.amountIn
            );
        } else {
            weth.deposit{value: rpd.amountIn}();
            rpd.tokenIn = address(weth);
        }

        // increase token approval to RP
        IERC20(rpd.tokenIn).safeIncreaseAllowance(address(rp), rpd.amountIn);

        rp.processRoute(
            rpd.tokenIn,
            rpd.amountIn,
            rpd.tokenOut,
            rpd.amountOutMin,
            rpd.to,
            rpd.route
        );
    }

    function sendMessage(
        address _adapter,
        bytes calldata _adapterData
    ) external payable override lock onlyApprovedAdapters(_adapter) {
        // send cross chain message
        ISushiXSwapV2Adapter(_adapter).sendMessage(_adapterData);
    }

    function bridge(
        BridgeParams calldata _bridgeParams,
        bytes calldata _swapPayload,
        bytes calldata _payloadData
    )
        external
        payable
        override
        lock
        onlyApprovedAdapters(_bridgeParams.adapter)
    {
        // bridge

        if (_bridgeParams.tokenIn != NATIVE_ADDRESS) {
            IERC20(_bridgeParams.tokenIn).safeTransferFrom(
                msg.sender,
                _bridgeParams.adapter,
                _bridgeParams.amountIn
            );
        }

        ISushiXSwapV2Adapter(_bridgeParams.adapter).adapterBridge{
            value: address(this).balance
        }(_bridgeParams.adapterData, _swapPayload, _payloadData);

        emit SushiXSwapOnSrc(
            _bridgeParams.refId,
            msg.sender,
            _bridgeParams.adapter,
            _bridgeParams.tokenIn,
            _bridgeParams.amountIn,
            _bridgeParams.to
        );
    }

    function swapAndBridge(
        BridgeParams calldata _bridgeParams,
        bytes calldata _swapData,
        bytes calldata _swapPayload,
        bytes calldata _payloadData
    )
        external
        payable
        override
        lock
        onlyApprovedAdapters(_bridgeParams.adapter)
    {
        // swap and bridge

        _swap(_swapData);

        ISushiXSwapV2Adapter(_bridgeParams.adapter).adapterBridge{
            value: address(this).balance
        }(_bridgeParams.adapterData, _swapPayload, _payloadData);

        emit SushiXSwapOnSrc(
            _bridgeParams.refId,
            msg.sender,
            _bridgeParams.adapter,
            _bridgeParams.tokenIn,
            _bridgeParams.amountIn,
            _bridgeParams.to
        );
    }

    function rescueTokens(address _token, address _to) external onlyOwner {
        if (_token != NATIVE_ADDRESS) {
            IERC20(_token).safeTransfer(
                _to,
                IERC20(_token).balanceOf(address(this))
            );
        } else {
            payable(_to).transfer(address(this).balance);
        }
    }
}