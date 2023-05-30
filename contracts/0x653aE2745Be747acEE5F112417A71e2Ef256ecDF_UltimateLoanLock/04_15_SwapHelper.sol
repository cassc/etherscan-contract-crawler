pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "./ISwapRouter.sol";
import "../PriceOracle.sol";
import "../EIP20NonStandardInterface.sol";
import "../EIP20Interface.sol";
import "../ExponentialNoError.sol";

contract SwapHelper is ExponentialNoError {
    uint256 public XSDShare = 0.6e18;
    address payable public XSDAddress;
    uint256 public ULShare = 0.4e18;
    address payable public ULAddress;

    ISwapRouter public swapRouter;
    PriceOracle public priceOracle;

    address public admin;

    constructor(
        address payable _XSDAddress,
        address payable _ULAddress,
        address _swapRouter,
        address _priceOracle
    ) public {
        XSDAddress = _XSDAddress;
        ULAddress = _ULAddress;
        swapRouter = ISwapRouter(_swapRouter);
        priceOracle = PriceOracle(_priceOracle);
        admin = msg.sender;
    }

    function _setSwapRouter(address _swapRouter) external {

        require(msg.sender == admin, "Only admin can set the swap router!");

        swapRouter = ISwapRouter(_swapRouter);
    }

    function performReservesSwap(bytes memory data) public {
        (
            uint256 totalAmount,
            address inputToken,
            bytes[] memory swapParams
        ) = abi.decode(data, (uint256, address, bytes[]));

        doTransferInApprove(inputToken, msg.sender, totalAmount);

        for (uint8 i = 0; i < swapParams.length; i++) {
            (
                bool singleHop,
                address outputToken,
                bytes memory SwapInputParams
            ) = abi.decode(swapParams[i], (bool, address, bytes));

            uint256 amountReceived;
            if (singleHop) {
                ISwapRouter.ExactInputSingleParams memory inputParams = abi
                    .decode(
                        SwapInputParams,
                        (ISwapRouter.ExactInputSingleParams)
                    );
                inputParams.amountOutMinimum = getAmountOutMinimum(
                    inputToken,
                    outputToken,
                    inputParams.amountIn,
                    0.97e18 // enforce a maximum slippage of 3%
                );
                amountReceived = swapRouter.exactInputSingle(inputParams);
            } else {
                ISwapRouter.ExactInputParams memory inputParams = abi.decode(
                    SwapInputParams,
                    (ISwapRouter.ExactInputParams)
                );
                inputParams.amountOutMinimum = getAmountOutMinimum(
                    inputToken,
                    outputToken,
                    inputParams.amountIn,
                    0.97e18 // enforce a maximum slippage of 3%
                );
                amountReceived = swapRouter.exactInput(inputParams);
            }
            uint256 XSDTransferAmount = mul_(
                Exp({mantissa: amountReceived}),
                Exp({mantissa: XSDShare})
            ).mantissa;

            doTransferOut(outputToken, XSDAddress, XSDTransferAmount);
            doTransferOut(
                outputToken,
                ULAddress,
                amountReceived - XSDTransferAmount
            );
        }
    }

    function getAmountOutMinimum(
        address inputToken,
        address outputToken,
        uint256 amountIn,
        uint256 slippage
    ) internal returns (uint256) {
        return
            mul_(
                div_(
                    mul_(
                        Exp({mantissa: amountIn}),
                        Exp({mantissa: priceOracle.assetPrices(inputToken)})
                    ),
                    Exp({mantissa: priceOracle.assetPrices(outputToken)})
                ),
                Exp({mantissa: slippage})
            ).mantissa; // (amountIn * inputTokenPrice / outputTokenPrice) * slippage
    }

    // function performSwap(address tokenAddress, uint256 amount) public {
    //     EIP20NonStandardInterface token = EIP20NonStandardInterface(
    //         tokenAddress
    //     );
    // }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
     *      This will revert due to insufficient balance or insufficient allowance.
     *      This function returns the actual amount received,
     *      which may be less than `amount` if there is a fee attached to the transfer.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function doTransferInApprove(
        address tokenAddress,
        address from,
        uint256 amount
    ) internal {
        EIP20NonStandardInterface token = EIP20NonStandardInterface(
            tokenAddress
        );
        uint256 balanceBefore = EIP20Interface(tokenAddress).balanceOf(
            address(this)
        );
        token.transferFrom(from, address(this), amount);

        bool success;
        assembly {
            switch returndatasize()
            case 0 {
                // This is a non-standard ERC-20
                success := not(0) // set success to true
            }
            case 32 {
                // This is a compliant ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of external call
            }
            default {
                // This is an excessively non-compliant ERC-20, revert.
                revert(0, 0)
            }
        }
        require(success, "TOKEN_TRANSFER_IN_FAILED");

        // Calculate the amount that was *actually* transferred
        uint256 balanceAfter = EIP20Interface(tokenAddress).balanceOf(
            address(this)
        );
        require(balanceAfter >= balanceBefore, "TOKEN_TRANSFER_IN_OVERFLOW");

        //Approve the swapRouter to use the transferred funds for the actual swap
        token.approve(address(swapRouter), balanceAfter - balanceBefore);
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False success from `transfer` and returns an explanatory
     *      error code rather than reverting. If caller has not called checked protocol's balance, this may revert due to
     *      insufficient cash held in this contract. If caller has checked protocol's balance prior to this call, and verified
     *      it is >= amount, this should not revert in normal conditions.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function doTransferOut(
        address tokenAddress,
        address payable to,
        uint256 amount
    ) internal {
        EIP20NonStandardInterface token = EIP20NonStandardInterface(
            tokenAddress
        );
        token.transfer(to, amount);

        bool success;
        assembly {
            switch returndatasize()
            case 0 {
                // This is a non-standard ERC-20
                success := not(0) // set success to true
            }
            case 32 {
                // This is a compliant ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of external call
            }
            default {
                // This is an excessively non-compliant ERC-20, revert.
                revert(0, 0)
            }
        }
        require(success, "TOKEN_TRANSFER_OUT_FAILED");
    }
}