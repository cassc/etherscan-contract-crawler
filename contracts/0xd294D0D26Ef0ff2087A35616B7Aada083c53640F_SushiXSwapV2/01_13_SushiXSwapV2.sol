// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import "./interfaces/ISushiXSwapV2.sol";

/// @title SushiXSwapV2
/// @notice Cross-chain swaps & general message passing through adapters
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

    error IncorrectoAmountIn();

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

    /// @notice Set an adddress as privileged user
    /// @param user The address to set
    /// @param privileged The status of users's privileged status
    function setPrivileged(address user, bool privileged) external onlyOwner {
        privilegedUsers[user] = privileged;
    }

    /// @notice pause the contract
    function pause() external onlyOwnerOrPrivilegedUser {
        paused = 2;
    }

    /// @notice resume the contract from paused state
    function resume() external onlyOwnerOrPrivilegedUser {
        paused = 1;
    }

    /// @inheritdoc ISushiXSwapV2
    function updateAdapterStatus(
        address _adapter,
        bool _status
    ) external onlyOwner {
        approvedAdapters[_adapter] = _status;
    }

    /// @inheritdoc ISushiXSwapV2
    function updateRouteProcessor(
        address newRouteProcessor
    ) external onlyOwner {
        rp = IRouteProcessor(newRouteProcessor);
    }

    /// @inheritdoc ISushiXSwapV2
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
                address(rp),
                rpd.amountIn
            );
        }

        rp.processRoute{
            value: rpd.tokenIn == NATIVE_ADDRESS ? rpd.amountIn : 0
        }(
            rpd.tokenIn,
            rpd.amountIn,
            rpd.tokenOut,
            rpd.amountOutMin,
            rpd.to,
            rpd.route
        );
    }

    /// @inheritdoc ISushiXSwapV2
    function sendMessage(
        address _adapter,
        bytes calldata _adapterData
    ) external payable override lock onlyApprovedAdapters(_adapter) {
        // send cross chain message
        ISushiXSwapV2Adapter(_adapter).sendMessage(_adapterData);
    }

    /// @inheritdoc ISushiXSwapV2
    function bridge(
        BridgeParams calldata _bridgeParams,
        address _refundAddress,
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
        }(_bridgeParams.adapterData, _refundAddress, _swapPayload, _payloadData);

        emit SushiXSwapOnSrc(
            _bridgeParams.refId,
            msg.sender,
            _bridgeParams.adapter,
            _bridgeParams.tokenIn,
            _bridgeParams.amountIn,
            _bridgeParams.to
        );
    }
    
    /// @inheritdoc ISushiXSwapV2
    function swapAndBridge(
        BridgeParams calldata _bridgeParams,
        address _refundAddress,
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
        }(_bridgeParams.adapterData, _refundAddress, _swapPayload, _payloadData);

        emit SushiXSwapOnSrc(
            _bridgeParams.refId,
            msg.sender,
            _bridgeParams.adapter,
            _bridgeParams.tokenIn,
            _bridgeParams.amountIn,
            _bridgeParams.to
        );
    }

    /// @notice Rescue tokens from the contract
    /// @param _token The address of the token to rescue
    /// @param _to The address to send the tokens to
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