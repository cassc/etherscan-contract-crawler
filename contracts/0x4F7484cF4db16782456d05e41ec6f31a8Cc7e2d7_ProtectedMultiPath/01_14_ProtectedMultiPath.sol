/*solhint-disable avoid-low-level-calls*/
// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "./IRouter.sol";
import "../IAugustusSwapperV5.sol";
import "../adapters/IAdapter.sol";
import "../fee/FeeModel.sol";
import "../fee/IFeeClaimer.sol";

contract ProtectedMultiPath is FeeModel, IRouter {
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
        return keccak256(abi.encodePacked("PROTECTED_MULTIPATH_ROUTER", "1.0.0"));
    }

    /**
     * @dev The function which performs the multi path swap.
     * @param data Data required to perform swap.
     */
    function protectedMultiSwap(Utils.SellData memory data) public payable returns (uint256) {
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

        retrieveEth();

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
     * @dev The function which performs the mega path swap.
     * @param data Data required to perform swap.
     */
    function protectedMegaSwap(Utils.MegaSwapSellData memory data) public payable returns (uint256) {
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

        retrieveEth();

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

    function retrieveEth() private {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool result, ) = msg.sender.call{ value: balance, gas: 10000 }("");
            require(result, "Failed to transfer Ether");
        }
    }
}