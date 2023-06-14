/*solhint-disable avoid-low-level-calls*/
// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "./IRouter.sol";
import "../IAugustusSwapperV5.sol";
import "../adapters/IAdapter.sol";
import "../adapters/IBuyAdapter.sol";
import "../fee/FeeModel.sol";
import "../fee/IFeeClaimer.sol";

contract MultiPath is FeeModel, IRouter {
    using SafeMath for uint256;

    /*solhint-disable no-empty-blocks*/
    constructor(
        uint256 _partnerSharePercent,
        uint256 _maxFeePercent,
        uint256 _paraswapReferralShare,
        uint256 _paraswapSlippageShare,
        IFeeClaimer _feeClaimer
    )
        public
        FeeModel(_partnerSharePercent, _maxFeePercent, _paraswapReferralShare, _paraswapSlippageShare, _feeClaimer)
    {}

    /*solhint-enable no-empty-blocks*/

    function initialize(bytes calldata) external override {
        revert("METHOD NOT IMPLEMENTED");
    }

    function getKey() external pure override returns (bytes32) {
        return keccak256(abi.encodePacked("MULTIPATH_ROUTER", "1.0.0"));
    }

    /**
     * @dev The function which performs the multi path swap.
     * @param data Data required to perform swap.
     */
    function multiSwap(Utils.SellData memory data) public payable returns (uint256) {
        require(data.deadline >= block.timestamp, "Deadline breached");

        address fromToken = data.fromToken;
        uint256 fromAmount = data.fromAmount;
        require(msg.value == (fromToken == Utils.ethAddress() ? fromAmount : 0), "Incorrect msg.value");
        uint256 toAmount = data.toAmount;
        uint256 expectedAmount = data.expectedAmount;
        address payable beneficiary = data.beneficiary == address(0) ? msg.sender : data.beneficiary;
        Utils.Path[] memory path = data.path;
        address toToken = path[path.length - 1].to;

        require(toAmount > 0, "To amount can not be 0");

        //If source token is not ETH than transfer required amount of tokens
        //from sender to this contract
        transferTokensFromProxy(fromToken, fromAmount, data.permit);
        if (_isTakeFeeFromSrcToken(data.feePercent)) {
            // take fee from source token
            fromAmount = takeFromTokenFee(fromToken, fromAmount, data.partner, data.feePercent);
        }

        performSwap(fromToken, fromAmount, path);

        uint256 receivedAmount = Utils.tokenBalance(toToken, address(this));

        require(receivedAmount >= toAmount, "Received amount of tokens are less then expected");

        if (
            _getFixedFeeBps(data.partner, data.feePercent) != 0 &&
            !_isTakeFeeFromSrcToken(data.feePercent) &&
            !_isReferral(data.feePercent)
        ) {
            // take fee from dest token
            takeToTokenFeeAndTransfer(toToken, receivedAmount, beneficiary, data.partner, data.feePercent);
        } else if (receivedAmount > expectedAmount && !_isTakeFeeFromSrcToken(data.feePercent)) {
            takeSlippageAndTransferSell(
                toToken,
                beneficiary,
                data.partner,
                receivedAmount,
                expectedAmount,
                data.feePercent
            );
        } else {
            // Fee is already taken from fromToken
            // Transfer toToken to beneficiary
            Utils.transferTokens(toToken, beneficiary, receivedAmount);
        }

        emit SwappedV3(
            data.uuid,
            data.partner,
            data.feePercent,
            msg.sender,
            beneficiary,
            fromToken,
            toToken,
            fromAmount,
            receivedAmount,
            expectedAmount
        );

        return receivedAmount;
    }

    /**
     * @dev The function which performs the single path buy.
     * @param data Data required to perform swap.
     */
    function buy(Utils.BuyData memory data) public payable returns (uint256) {
        require(data.deadline >= block.timestamp, "Deadline breached");

        address fromToken = data.fromToken;
        uint256 fromAmount = data.fromAmount;
        require(msg.value == (fromToken == Utils.ethAddress() ? fromAmount : 0), "Incorrect msg.value");
        uint256 toAmount = data.toAmount;
        address payable beneficiary = data.beneficiary == address(0) ? msg.sender : data.beneficiary;
        address toToken = data.toToken;
        uint256 expectedAmount = data.expectedAmount;
        uint256 feePercent = data.feePercent;

        require(toAmount > 0, "To amount can not be 0");

        //If source token is not ETH than transfer required amount of tokens
        //from sender to this contract
        transferTokensFromProxy(fromToken, fromAmount, data.permit);

        uint256 receivedAmount = performBuy(data.adapter, fromToken, toToken, fromAmount, toAmount, data.route);

        uint256 remainingAmount = Utils.tokenBalance(fromToken, address(this));

        if (
            _getFixedFeeBps(data.partner, data.feePercent) != 0 &&
            !_isTakeFeeFromSrcToken(feePercent) &&
            !_isReferral(data.feePercent)
        ) {
            // take fee from dest token
            takeToTokenFeeAndTransfer(toToken, receivedAmount, beneficiary, data.partner, feePercent);

            // Transfer remaining token back to sender
            Utils.transferTokens(fromToken, msg.sender, remainingAmount);
        } else {
            Utils.transferTokens(toToken, beneficiary, receivedAmount);
            if (_getFixedFeeBps(data.partner, data.feePercent) != 0 && _isTakeFeeFromSrcToken(feePercent)) {
                //  take fee from source token and transfer remaining token back to sender
                takeFromTokenFeeAndTransfer(
                    fromToken,
                    fromAmount.sub(remainingAmount),
                    remainingAmount,
                    data.partner,
                    feePercent
                );
            } else if (fromAmount.sub(remainingAmount) < expectedAmount) {
                takeSlippageAndTransferBuy(
                    fromToken,
                    data.partner,
                    expectedAmount,
                    fromAmount.sub(remainingAmount),
                    remainingAmount,
                    feePercent
                );
            } else {
                // Transfer remaining token back to sender
                Utils.transferTokens(fromToken, msg.sender, remainingAmount);
            }
        }

        fromAmount = fromAmount.sub(remainingAmount);
        emit BoughtV3(
            data.uuid,
            data.partner,
            feePercent,
            msg.sender,
            beneficiary,
            fromToken,
            toToken,
            fromAmount,
            receivedAmount,
            expectedAmount
        );

        return receivedAmount;
    }

    /**
     * @dev The function which performs the mega path swap.
     * @param data Data required to perform swap.
     */
    function megaSwap(Utils.MegaSwapSellData memory data) public payable returns (uint256) {
        require(data.deadline >= block.timestamp, "Deadline breached");
        address fromToken = data.fromToken;
        uint256 fromAmount = data.fromAmount;
        require(msg.value == (fromToken == Utils.ethAddress() ? fromAmount : 0), "Incorrect msg.value");
        uint256 toAmount = data.toAmount;
        uint256 expectedAmount = data.expectedAmount;
        address payable beneficiary = data.beneficiary == address(0) ? msg.sender : data.beneficiary;
        Utils.MegaSwapPath[] memory path = data.path;
        address toToken = path[0].path[path[0].path.length - 1].to;

        require(toAmount > 0, "To amount can not be 0");

        //if fromToken is not ETH then transfer tokens from user to this contract
        transferTokensFromProxy(fromToken, fromAmount, data.permit);
        if (_isTakeFeeFromSrcToken(data.feePercent)) {
            // take fee from source token
            fromAmount = takeFromTokenFee(fromToken, fromAmount, data.partner, data.feePercent);
        }

        for (uint8 i = 0; i < uint8(path.length); i++) {
            uint256 _fromAmount = fromAmount.mul(path[i].fromAmountPercent).div(10000);
            if (i == path.length - 1) {
                _fromAmount = Utils.tokenBalance(address(fromToken), address(this));
            }
            performSwap(fromToken, _fromAmount, path[i].path);
        }

        uint256 receivedAmount = Utils.tokenBalance(toToken, address(this));

        require(receivedAmount >= toAmount, "Received amount of tokens are less then expected");

        if (
            _getFixedFeeBps(data.partner, data.feePercent) != 0 &&
            !_isTakeFeeFromSrcToken(data.feePercent) &&
            !_isReferral(data.feePercent)
        ) {
            // take fee from dest token
            takeToTokenFeeAndTransfer(toToken, receivedAmount, beneficiary, data.partner, data.feePercent);
        } else if (receivedAmount > expectedAmount && !_isTakeFeeFromSrcToken(data.feePercent)) {
            takeSlippageAndTransferSell(
                toToken,
                beneficiary,
                data.partner,
                receivedAmount,
                expectedAmount,
                data.feePercent
            );
        } else {
            // Fee is already taken from fromToken
            // Transfer toToken to beneficiary
            Utils.transferTokens(toToken, beneficiary, receivedAmount);
        }

        emit SwappedV3(
            data.uuid,
            data.partner,
            data.feePercent,
            msg.sender,
            beneficiary,
            fromToken,
            toToken,
            fromAmount,
            receivedAmount,
            expectedAmount
        );

        return receivedAmount;
    }

    //Helper function to perform swap
    function performSwap(
        address fromToken,
        uint256 fromAmount,
        Utils.Path[] memory path
    ) private {
        require(path.length > 0, "Path not provided for swap");

        //Assuming path will not be too long to reach out of gas exception
        for (uint256 i = 0; i < path.length; i++) {
            //_fromToken will be either fromToken or toToken of the previous path
            address _fromToken = i > 0 ? path[i - 1].to : fromToken;
            address _toToken = path[i].to;

            uint256 _fromAmount = i > 0 ? Utils.tokenBalance(_fromToken, address(this)) : fromAmount;

            for (uint256 j = 0; j < path[i].adapters.length; j++) {
                Utils.Adapter memory adapter = path[i].adapters[j];

                //Check if exchange is supported
                require(
                    IAugustusSwapperV5(address(this)).hasRole(WHITELISTED_ROLE, adapter.adapter),
                    "Exchange not whitelisted"
                );

                //Calculating tokens to be passed to the relevant exchange
                //percentage should be 200 for 2%
                uint256 fromAmountSlice = i > 0 && j == path[i].adapters.length.sub(1)
                    ? Utils.tokenBalance(address(_fromToken), address(this))
                    : _fromAmount.mul(adapter.percent).div(10000);

                //DELEGATING CALL TO THE ADAPTER
                (bool success, ) = adapter.adapter.delegatecall(
                    abi.encodeWithSelector(
                        IAdapter.swap.selector,
                        _fromToken,
                        _toToken,
                        fromAmountSlice,
                        uint256(0), //adapter.networkFee,
                        adapter.route
                    )
                );

                require(success, "Call to adapter failed");
            }
        }
    }

    //Helper function to perform swap
    function performBuy(
        address adapter,
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 toAmount,
        Utils.Route[] memory routes
    ) private returns (uint256) {
        //Check if exchange is supported
        require(IAugustusSwapperV5(address(this)).hasRole(WHITELISTED_ROLE, adapter), "Exchange not whitelisted");

        for (uint256 j = 0; j < routes.length; j++) {
            Utils.Route memory route = routes[j];

            uint256 fromAmountSlice;
            uint256 toAmountSlice;

            //last route
            if (j == routes.length.sub(1)) {
                toAmountSlice = toAmount.sub(Utils.tokenBalance(address(toToken), address(this)));

                fromAmountSlice = Utils.tokenBalance(address(fromToken), address(this));
            } else {
                fromAmountSlice = fromAmount.mul(route.percent).div(10000);
                toAmountSlice = toAmount.mul(route.percent).div(10000);
            }

            //delegate Call to the exchange
            (bool success, ) = adapter.delegatecall(
                abi.encodeWithSelector(
                    IBuyAdapter.buy.selector,
                    route.index,
                    fromToken,
                    toToken,
                    fromAmountSlice,
                    toAmountSlice,
                    route.targetExchange,
                    route.payload
                )
            );
            require(success, "Call to adapter failed");
        }

        uint256 receivedAmount = Utils.tokenBalance(toToken, address(this));
        require(receivedAmount >= toAmount, "Received amount of tokens are less then expected tokens");

        return receivedAmount;
    }

    function transferTokensFromProxy(
        address token,
        uint256 amount,
        bytes memory permit
    ) private {
        if (token != Utils.ethAddress()) {
            Utils.permit(token, permit);
            tokenTransferProxy.transferFrom(token, msg.sender, address(this), amount);
        }
    }
}