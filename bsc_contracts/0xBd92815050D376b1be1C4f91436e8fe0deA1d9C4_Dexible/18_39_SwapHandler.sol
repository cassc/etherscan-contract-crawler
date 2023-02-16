//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "../interfaces/ISwapHandler.sol";
import "../DexibleStorage.sol";
import "./AdminBase.sol";
import "../../vault/interfaces/ICommunityVault.sol";
import "../LibFees.sol";

import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

abstract contract SwapHandler is AdminBase, ISwapHandler {

    using SafeERC20 for IERC20;

    struct SwapMeta {
        bool feeIsInput;
        bool isSelfSwap;
        //if a migration occurs during a swap, we don't want to charge
        //the trader for the txn if possible
        address preSwapVault;
        uint startGas;
        uint toProtocol;
        uint toRevshare;
        uint outToTrader;
        uint outAmount;
        uint bpsAmount;
        uint gasAmount;
        uint nativeGasAmount;
        uint preDXBLBalance;
        uint inputAmountDue;
    }


    function fill(SwapTypes.SwapRequest calldata request, SwapMeta memory meta) external onlySelf returns (SwapMeta memory)  {

        preCheck(request, meta);
        meta.outAmount = request.tokenOut.token.balanceOf(address(this));
        
        for(uint i=0;i<request.routes.length;++i) {
            SwapTypes.RouterRequest calldata rr = request.routes[i];
            IERC20(rr.routeAmount.token).safeApprove(rr.spender, rr.routeAmount.amount);
            (bool s, ) = rr.router.call(rr.routerData);

            if(!s) {
                revert("Failed to swap");
            }
        }
        uint out = request.tokenOut.token.balanceOf(address(this));
        if(meta.outAmount < out) {
            meta.outAmount = out - meta.outAmount;
        } else {
            meta.outAmount = 0;
        }
        
        console.log("Expected", request.tokenOut.amount, "Received", meta.outAmount);
        //first, make sure enough output was generated
        require(meta.outAmount >= request.tokenOut.amount, "Insufficient output generated");
        return meta;
    }

    function postFill(SwapTypes.SwapRequest memory request, SwapMeta memory meta, bool success) internal  {

        if(success) {
            //if we succeeded, then do successful post-swap ops
            handleSwapSuccess(request, meta); 
        }  else {
            //otherwise, handle as a failure
            handleSwapFailure(request, meta);
        }
        //pay the relayer their gas fee if we have funds for it
        payRelayGas(meta.nativeGasAmount);
    }

    /**
     * When a relay-based swap fails, we need to account for failure gas fees if the input
     * token is the fee token. That's what this function does
     */
    function handleSwapFailure(SwapTypes.SwapRequest memory request, SwapMeta memory meta) internal {
       
        DexibleStorage.DexibleData storage dd = DexibleStorage.load();
        uint gasInFeeToken = 0;
        if(meta.feeIsInput) {
            unchecked { 
                //the total gas used thus far plus some post-op stuff that needs to get done
                uint totalGas = (meta.startGas - gasleft());
                
                console.log("Estimated gas used for failed gas payment", totalGas);
                meta.nativeGasAmount = LibFees.computeGasCost(totalGas, false);
            }

            gasInFeeToken = dd.communityVault.convertGasToFeeToken(address(request.executionRequest.fee.feeToken), meta.nativeGasAmount);

            //console.log("Transferring partial input token to devteam for failure gas fees");
            
            //console.log("Failed gas fee", gasInFeeToken);

            //transfer input assets from trader to treasury. Recall that any previous transfer amount
            //to this contract was rolled back on failure, so we transfer the funds for gas only
            request.executionRequest.fee.feeToken.safeTransferFrom(request.executionRequest.requester, dd.treasury, gasInFeeToken);
        }
        
        emit SwapFailed(request.executionRequest.requester, address(request.executionRequest.fee.feeToken), gasInFeeToken);
    }

    /**
     * This is called when a relay-based swap is successful. It basically rewards DXBL tokens
     * to trader and pays appropriate fees.
     */
    function handleSwapSuccess(SwapTypes.SwapRequest memory request, 
                SwapMeta memory meta) internal {
        
        //reward trader with DXBL tokens
        collectDXBL(request, meta.feeIsInput, meta.outAmount);

        //pay fees
        payAndDistribute(request, meta);
    }

    /**
     * Reward DXBL to the trader
     */
    function collectDXBL(SwapTypes.SwapRequest memory request, bool feeIsInput, uint outAmount) internal {
        DexibleStorage.DexibleData storage dd = DexibleStorage.load();

        uint value = 0;
        if(feeIsInput) {
            //when input, the total input amount is used to determine reward rate
            value = request.tokenIn.amount;
        } else {
            //otherwise, it's the output generated from the swap
            value = outAmount;
        }
        //Dexible is the only one allowed to ask the vault to mint tokens on behalf of a trader
        //See RevshareVault for logic of minting rewards

        //NOTE: a migration to a new vault could occur as part of this call. It would just 
        //change the address of the vault in storage and all proceeds would be forwarded to 
        //the new vault address. All minting occurs before the migration so mint rates and 
        //token balances are all forwarded to the new vault as part of the migration. It is 
        //possible, however, that gas estimates would not account for the migration.
        dd.communityVault.rewardTrader(request.executionRequest.requester, address(request.executionRequest.fee.feeToken), value);
    }


    /**
     * Distribute payments to revshare pool, affiliates, treasury, and trader
     */
    function payAndDistribute(SwapTypes.SwapRequest memory request, 
                                SwapMeta memory meta) internal  {
        allocateRevshareAndAffiliate(request, meta);
        payProtocolAndTrader(request, meta);
    }

    /**
     * Allocate bps portions to revshare pool and any associated affiliate
     */
    function allocateRevshareAndAffiliate(SwapTypes.SwapRequest memory request, 
                                SwapMeta memory meta) internal view {

        DexibleStorage.DexibleData storage dd = DexibleStorage.load();

        //assume trader gets all output
        meta.outToTrader = meta.outAmount;

        //the bps portion of fee. 
        meta.bpsAmount = computeBpsFee(request, meta.feeIsInput, meta.preDXBLBalance, meta.outAmount);
    
        //console.log("Total bps fee", payments.bpsAmount);
        uint minFee = LibFees.computeMinFeeUnits(address(request.executionRequest.fee.feeToken));
        if(minFee > meta.bpsAmount) {
            //console.log("Trade too small. Charging minimum flat fee", minFee);
            meta.bpsAmount = minFee;
        }

        //revshare pool gets portion of bps fee collected
        meta.toRevshare = (meta.bpsAmount * dd.revshareSplitRatio) / 100;

        //console.log("To revshare", meta.toRevshare);

        //protocol gets remaining bps but affiliate fees come out of its portion. Will revert if
        //Dexible miscalculated the affiliate reward portion. However, the call would revert here and
        //Dexible relay would pay the gas fee for its mistake. Self-swap has no affiliate so no revert
        //would happen.
        require(request.executionRequest.fee.affiliatePortion < meta.bpsAmount-meta.toRevshare, "Miscalculated affiliate portion");
        meta.toProtocol = (meta.bpsAmount-meta.toRevshare) - request.executionRequest.fee.affiliatePortion;

        //console.log("Protocol pre-gas", meta.toProtocol);

        //fees accounted for thus far
        uint total = meta.toRevshare + meta.toProtocol + request.executionRequest.fee.affiliatePortion;
            
        if(!meta.feeIsInput) {
            //this is an interim calculation. Gas fees get deducted later as well. This will
            //also revert if insufficient output was generated to cover all fees
            //console.log("Out amount", meta.outAmount, "Total fees so far", total);
            if(meta.outAmount < total) {
                revert(
                    string(
                        abi.encodePacked(
                            _concatUintString("Insufficient output to pay bps fees. Required: ", total),
                            _concatUintString(" Output amount: ", meta.outAmount)
                        )
                    )
                );
            }
            meta.outToTrader = meta.outAmount - total;
        } else {
            //input debits are handled later so we keep track of what's due so far in bps fees
            meta.inputAmountDue = total;
        }
    }

    /**
     * Final step to compute gas consumption for trader and pay the vault, protocol, affiliate, and trader 
     * their portions.
     */
    function payProtocolAndTrader(SwapTypes.SwapRequest memory request,
                            SwapMeta memory meta) internal {
        
        DexibleStorage.DexibleData storage dd = DexibleStorage.load();

        if(!meta.isSelfSwap) {
            //If this was a relay-based swap, we need to pay treasury an estimated gas fee
            
            //we leave unguarded for gas savings since we know start gas is always higher 
            //than used and will never rollover without costing an extremely large amount of $$
            unchecked { 
                //console.log("Start gas", meta.startGas, "Left", gasleft());

                //the total gas used thus far plus some post-op buffer for transfers and events
                uint totalGas = (meta.startGas - gasleft());
                if(address(dd.communityVault) != meta.preSwapVault && totalGas > 200_000) {
                    totalGas -= 200_000; //give credit for estimated migration gas
                }
                
                console.log("Estimated gas used for trader gas payment", totalGas);
                meta.nativeGasAmount = LibFees.computeGasCost(totalGas, true); //(totalGas * tx.gasprice);
            }
            //use price oracle in vault to get native price in fee token
            meta.gasAmount = dd.communityVault.convertGasToFeeToken(address(request.executionRequest.fee.feeToken), meta.nativeGasAmount);
            //console.log("Gas paid by trader in fee token", meta.gasAmount);

            //add gas payment to treasury portion
            meta.toProtocol += meta.gasAmount;
            //console.log("Payment to protocol", meta.toProtocol);

            if(!meta.feeIsInput) {
                //if output was fee, deduct gas payment from proceeds, revert if there isn't enough output
                //for it (should have been caught offchain before submit). We make sure the trader gets 
                //something out of the deal by ensuring output is more than gas.
                if(meta.outToTrader <= meta.gasAmount) {
                    revert(
                        string(
                            abi.encodePacked(
                                _concatUintString("Insufficient output to pay gas fees. Required: ", meta.gasAmount),
                                _concatUintString(" Trader output proceeds: ", meta.outToTrader)
                            )
                        )
                    );
                }
                meta.outToTrader -= meta.gasAmount;
            } else {
                //other make sure it's account for as input debit
                meta.inputAmountDue += meta.gasAmount;
            }
            //console.log("Proceeds to trader", payments.outToTrader);
        }

        //now distribute fees
        IERC20 feeToken = request.executionRequest.fee.feeToken;
        if(meta.feeIsInput) {
            //make sure we didn't overspend on trading input amount and not have enough to cover
            //fees
            uint totalInputSpent = request.routes[0].routeAmount.amount + meta.inputAmountDue;
            //console.log("Total input spent", totalInputSpent, "Expected input amount", request.tokenIn.amount);
            if(totalInputSpent > request.tokenIn.amount) {
                revert(
                    string(
                        abi.encodePacked(_concatUintString("Attempt to spend more input than anticipated. Total required: ", totalInputSpent),
                                        _concatUintString(" Max input: ", request.tokenIn.amount))
                    )
                );
            }
            //pay protocol from input token
            feeToken.safeTransferFrom(request.executionRequest.requester, dd.treasury, meta.toProtocol);

            //pay vault from input token
            feeToken.safeTransferFrom(request.executionRequest.requester, address(dd.communityVault), meta.toRevshare);
            if(request.executionRequest.fee.affiliatePortion > 0) {
                //pay affiliate their portion which was deducted from protocol's bps portion
                feeToken.safeTransferFrom(request.executionRequest.requester, request.executionRequest.fee.affiliate, request.executionRequest.fee.affiliatePortion);
                emit AffiliatePaid(request.executionRequest.fee.affiliate, address(feeToken), request.executionRequest.fee.affiliatePortion);
            }
        } else {
            //otherwise, transfer directly from generated output
            //console.log("Total output spent", (meta.toProtocol + meta.toRevshare + request.executionRequest.fee.affiliatePortion));
            //console.log("Total output generated", meta.outAmount);
            feeToken.safeTransfer(dd.treasury, meta.toProtocol);
            feeToken.safeTransfer(address(dd.communityVault), meta.toRevshare);
            if(request.executionRequest.fee.affiliatePortion > 0) {
                //pay affiliate their portion
                feeToken.safeTransfer(request.executionRequest.fee.affiliate, request.executionRequest.fee.affiliatePortion);
                emit AffiliatePaid(request.executionRequest.fee.affiliate, address(feeToken), request.executionRequest.fee.affiliatePortion);
            }
        }
        
        //and send trader their proceeds
        request.tokenOut.token.safeTransfer(request.executionRequest.requester, meta.outToTrader);
        
        emit SwapSuccess(request.executionRequest.requester,
                    request.executionRequest.fee.affiliate,
                    request.tokenOut.amount,
                    meta.outToTrader, 
                    address(request.executionRequest.fee.feeToken),
                    meta.gasAmount,
                    request.executionRequest.fee.affiliatePortion,
                    meta.bpsAmount); 
    }

    function preCheck(SwapTypes.SwapRequest calldata request, SwapMeta memory meta) internal {
        //make sure fee token is allowed
        address fToken = address(request.executionRequest.fee.feeToken);
        DexibleStorage.DexibleData storage dd = DexibleStorage.load();
        require(
            dd.communityVault.isFeeTokenAllowed(fToken), 
            "Fee token is not allowed"
        );

        //and that it's one of the tokens swapped
        require(fToken == address(request.tokenIn.token) ||
                fToken == address(request.tokenOut.token), 
                "Fee token must be input or output token");

         //get the current DXBL balance at the start to apply discounts
        meta.preDXBLBalance = dd.dxblToken.balanceOf(request.executionRequest.requester);
        
        //flag whether the input token is the fee token
        meta.feeIsInput = address(request.tokenIn.token) == address(request.executionRequest.fee.feeToken);
        
        //transfer input tokens for router so it can perform swap
        //console.log("Transfering input for trading:", request.routes[0].routeAmount.amount);
        request.tokenIn.token.safeTransferFrom(request.executionRequest.requester, address(this), request.routes[0].routeAmount.amount);
        //console.log("Expected output", request.tokenOut.amount);
    }


    /**
     * Pay the relay with gas funds stored in this contract. The gas used provided 
     * does not include arbitrum multiplier but may include additional amount for post-op
     * gas estimates.
     */
    function payRelayGas(uint gasFee) internal {
        if(gasFee == 0) {
            return;
        }
        
        //console.log("Relay Gas Reimbursement", gasFee);
        //if there is ETH in the contract, reimburse the relay that called the fill function
        if(address(this).balance < gasFee) {
            //console.log("Cannot reimburse relay since do not have enough funds");
            emit InsufficientGasFunds(msg.sender, gasFee);
        } else {
            //console.log("Transfering gas fee to relay");
            payable(msg.sender).transfer(gasFee);
            emit PaidGasFunds(msg.sender, gasFee);
        }
    }

    /**
     * Compute the bps to charge for the swap. This leverages the DXBL token to compute discounts
     * based on trader balances and discount rates applied per DXBL token.
     */
    function computeBpsFee(SwapTypes.SwapRequest memory request, bool feeIsInput, uint preDXBL, uint outAmount) internal view returns (uint) {
        //apply any discounts
        DexibleStorage.DexibleData storage ds = DexibleStorage.load();
        
        return ds.dxblToken.computeDiscountedFee(
            IDXBL.FeeRequest({
                trader: request.executionRequest.requester,
                amt: feeIsInput ? request.tokenIn.amount : outAmount,
                referred: request.executionRequest.fee.affiliate != address(0),
                dxblBalance: preDXBL,
                stdBpsRate: ds.stdBpsRate,
                minBpsRate: ds.minBpsRate
            }));
    }

    function _concatUintString(string memory s, uint val) private pure returns(string memory) {
        return string(abi.encodePacked(s, Strings.toString(val)));
    }
}