// SPDX-License-Identifier: Business Source License 1.1 see LICENSE.txt
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

import "./libraries/UniERC20.sol";
import "./libraries/Sqrt.sol";
import "./libraries/ApprovalInterface.sol";
import "./libraries/SafeAggregatorInterface.sol";


import "./ClipperPool.sol";

/*
    This exchange interface implements the Matcha PLP API

    Also controls swapFee and approvalContract (to minimize gas)

    It must be created before the Pool contract
    because it gets passed to the Pool contract constructor.

    Then setPoolAddress should be called to link this contract and destroy ownership.
*/
contract ClipperExchangeInterface is ReentrancyGuard, Ownable {
    using Sqrt for uint256;
    using UniERC20 for ERC20;
    using SafeAggregatorInterface for AggregatorV3Interface;

    ClipperPool public theExchange;
    ApprovalInterface public approvalContract;

    uint256 public swapFee;
    uint256 constant MAXIMUM_SWAP_FEE = 500;
    uint256 constant ONE_IN_DEFAULT_DECIMALS_DIVIDED_BY_ONE_HUNDRED_SQUARED = 1e14;
    uint256 constant ONE_IN_TEN_DECIMALS = 1e10;
    uint256 constant ONE_HUNDRED_PERCENT_IN_BPS = 1e4;
    uint256 constant ONE_BASIS_POINT_IN_TEN_DECIMALS = 1e6;

    address constant MATCHA_ETH_SIGIL = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    address constant CLIPPER_ETH_SIGIL = address(0);
    address immutable myAddress;

    event Swapped(
        address inAsset,
        address outAsset,
        address recipient,
        uint256 inAmount,
        uint256 outAmount,
        bytes auxiliaryData
    );

    event SwapFeeModified(
        uint256 swapFee
    );

    modifier poolOwnerOnly() {
        require(msg.sender == theExchange.owner(), "Clipper: Only owner");
        _;
    }


    constructor(ApprovalInterface initialApprovalContract, uint256 initialSwapFee) {
        require(initialSwapFee < MAXIMUM_SWAP_FEE, "Clipper: Maximum swap fee exceeded");
        approvalContract = initialApprovalContract;
        swapFee = initialSwapFee;
        myAddress = address(this);
    }

    // This function should be called immediately after the pool is initialzied
    // It can only be called once because of renouncing ownership
    function setPoolAddress(address payable poolAddress) external onlyOwner {
        theExchange = ClipperPool(poolAddress);
        renounceOwnership();
    }

    function modifyApprovalContract(ApprovalInterface newApprovalContract) external poolOwnerOnly {
        approvalContract = newApprovalContract;
    }

    function modifySwapFee(uint256 newSwapFee) external poolOwnerOnly {
        require(newSwapFee < MAXIMUM_SWAP_FEE, "Clipper: Maximum swap fee exceeded");
        swapFee = newSwapFee;
        emit SwapFeeModified(newSwapFee);
    }

    // Used for deposits and withdrawals, but not swaps
    function invariant() public view returns (uint256) {
        (uint256 balance, uint256 M, uint256 marketWeight) = theExchange.findBalanceAndMultiplier(ERC20(CLIPPER_ETH_SIGIL));
        uint256 cumulant = (M*balance).sqrt()/marketWeight;
        uint i;
        uint n = theExchange.nTokens();
        while(i < n){
            ERC20 the_token = ERC20(theExchange.tokenAt(i));
            (balance, M, marketWeight) = theExchange.findBalanceAndMultiplier(the_token);
            cumulant = cumulant + (M*balance).sqrt()/marketWeight;
            i++;
        }
        // Divide to put everything on a 1e18 track...
        return (cumulant*cumulant)/ONE_IN_DEFAULT_DECIMALS_DIVIDED_BY_ONE_HUNDRED_SQUARED;
    }

    // Closed-form invariant swap expression
    // solves: (sqrt(Mx)/X + sqrt(Ny)/Y) == (sqrt(M(x+a)/X) + sqrt(N(y-b))/Y) for b
    function invariantSwap(uint256 x, uint256 y, uint256 M, uint256 N, uint256 a, uint256 marketWeightX, uint256 marketWeightY) internal pure returns(uint256) {
        uint256 Ma = M*a;
        uint256 Mx = M*x;
        uint256 rMax = (Ma+Mx).sqrt();
        // Since rMax >= rMx, we can start with a great guess
        uint256 rMx = Mx.sqrt(rMax+1);
        uint256 rNy = (N*y).sqrt();
        uint256 X2 = marketWeightX*marketWeightX;
        uint256 XY = marketWeightX*marketWeightY;
        uint256 Y2 = marketWeightY*marketWeightY;

        // multiply by X*Y to get: 
        if(rMax*marketWeightY >= (rNy*marketWeightX+rMx*marketWeightY)) {
            return y;
        } else {
            return (2*((XY*rNy*(rMax-rMx)) + Y2*(rMx*rMax-Mx)) - Y2*Ma)/(N*X2);
        }
    }

    // For gas savings, we query the existing balance of the input token exactly once, which is why this function needs to return
    // both output AND input
    function calculateSwapAmount(ERC20 inputToken, ERC20 outputToken, uint256 totalInputToken) public view returns(uint256 outputAmount, uint256 inputAmount) {
        // balancesAndMultipliers checks for tradability
        (uint256 x, uint256 y, uint256 M, uint256 N, uint256 weightX, uint256 weightY) = theExchange.balancesAndMultipliers(inputToken, outputToken);
        inputAmount = totalInputToken-x;
        uint256 b = invariantSwap(x, y, M, N, inputAmount, weightX, weightY);
        // trader gets back b-swapFee*b/10000 (swapFee is in basis points)
        outputAmount = b-((b*swapFee)/10000);
    }

    // Swaps between input and output, where ERC20 can be ERC20 or pure ETH
    // emits a Swapped event
    function unifiedSwap(ERC20 _input, ERC20 _output, address recipient, uint256 totalInputToken, uint256 minBuyAmount, bytes calldata auxiliaryData) internal returns (uint256 boughtAmount) {
        require(address(this)==myAddress && approvalContract.approveSwap(recipient), "Clipper: Recipient not approved");
        uint256 inputTokenAmount;
        (boughtAmount, inputTokenAmount) = calculateSwapAmount(_input, _output, totalInputToken);
        require(boughtAmount >= minBuyAmount, "Clipper: Not enough output");
        
        theExchange.syncAndTransfer(_input, _output, recipient, boughtAmount);
        
        emit Swapped(address(_input), address(_output), recipient, inputTokenAmount, boughtAmount, auxiliaryData);
    }

    /* These next four functions are the Matcha PLP API */
    
    // Returns how much of the 'outputToken' would be returned if 'sellAmount'
    // of 'inputToken' was sold.
    function getSellQuote(address inputToken, address outputToken, uint256 sellAmount) external view returns (uint256 outputTokenAmount){
        ERC20 _input = ERC20(inputToken==MATCHA_ETH_SIGIL ? CLIPPER_ETH_SIGIL : inputToken);
        ERC20 _output = ERC20(outputToken==MATCHA_ETH_SIGIL ? CLIPPER_ETH_SIGIL : outputToken);
        (outputTokenAmount, ) = calculateSwapAmount(_input, _output, sellAmount+theExchange.lastBalance(_input));
    }

    function sellTokenForToken(address inputToken, address outputToken, address recipient, uint256 minBuyAmount, bytes calldata auxiliaryData) external returns (uint256 boughtAmount) {
        ERC20 _input = ERC20(inputToken);
        ERC20 _output = ERC20(outputToken);
        
        uint256 inputTokenAmount = _input.balanceOf(address(theExchange));
        boughtAmount = unifiedSwap(_input, _output, recipient, inputTokenAmount, minBuyAmount, auxiliaryData);
    }

    // Matcha allows for either ETH pre-deposit, or msg.value transfer. We support both.
    function sellEthForToken(address outputToken, address recipient, uint256 minBuyAmount, bytes calldata auxiliaryData) external payable returns (uint256 boughtAmount){
        ERC20 _input = ERC20(CLIPPER_ETH_SIGIL);
        ERC20 _output = ERC20(outputToken);
        // Will no-op if msg.value == 0
        _input.uniTransferFromSender(msg.value, address(theExchange));
        uint256 inputETHAmount = address(theExchange).balance;
        boughtAmount = unifiedSwap(_input, _output, recipient, inputETHAmount, minBuyAmount, auxiliaryData);
    }

    function sellTokenForEth(address inputToken, address payable recipient, uint256 minBuyAmount, bytes calldata auxiliaryData) external returns (uint256 boughtAmount){
        ERC20 _input = ERC20(inputToken);
        uint256 inputTokenAmount = _input.balanceOf(address(theExchange));
        boughtAmount = unifiedSwap(_input, ERC20(CLIPPER_ETH_SIGIL), recipient, inputTokenAmount, minBuyAmount, auxiliaryData);
    }


    // Allows a trader to convert their Pool token into a single pool asset
    // This is essentially a swap between the pool token and something else
    // Note that it is the responsibility of the trader to tender an offer that does not decrease the invariant
    function withdrawInto(uint256 amount, ERC20 outputToken, uint256 outputTokenAmount) external nonReentrant {
        require(theExchange.isTradable(outputToken) && outputTokenAmount > 0, "Clipper: Unsupported withdrawal");
        // Have to sync before calculating the invariant
        // Otherwise, we may run into issues if someone erroneously transferred this outputToken to us
        // Immediately before the withdraw call.
        theExchange.sync(outputToken);
        uint256 initialFullyDilutedSupply = theExchange.fullyDilutedSupply();
        uint256 beforeWithdrawalInvariant = invariant();

        // This will fail if the sender doesn't have enough
        theExchange.swapBurn(msg.sender, amount);
        
        // This will fail if we don't have enough
        // Also syncs automatically
        theExchange.transferAsset(outputToken, msg.sender, outputTokenAmount);
        // so the invariant will have changed....
        uint256 afterWithdrawalInvariant = invariant();

        // TOKEN FRACTION BURNED:
        // amount / initialFullyDilutedSupply
        // INVARIANT FRACTION BURNED:
        // (before-after) / before
        // TOKEN_FRACTION_BURNED >= INVARIANT_FRACTION_BURNED + FEE
        // where fee is swapFee basis points of TOKEN_FRACTION_BURNED

        uint256 tokenFractionBurned = (ONE_IN_TEN_DECIMALS*amount)/initialFullyDilutedSupply;
        uint256 invariantFractionBurned = (ONE_IN_TEN_DECIMALS*(beforeWithdrawalInvariant-afterWithdrawalInvariant))/beforeWithdrawalInvariant;
        uint256 feeFraction = (tokenFractionBurned*swapFee*ONE_BASIS_POINT_IN_TEN_DECIMALS)/ONE_IN_TEN_DECIMALS;
        require(tokenFractionBurned >= (invariantFractionBurned+feeFraction), "Too much taken");
        // This is essentially a swap between the pool token into the output token
        emit Swapped(address(theExchange), address(outputToken), msg.sender, amount, outputTokenAmount, "");
    }

    // myFraction is a ten-decimal fraction
    // theFee is in Basis Points
    function _withdraw(uint256 myFraction, uint256 theFee) internal {
        ERC20 the_token;
        uint256 toTransfer;
        uint256 fee;

        uint i;
        uint n = theExchange.nTokens();
        while(i < n) {
            the_token = ERC20(theExchange.tokenAt(i));
            toTransfer = (myFraction*the_token.uniBalanceOf(address(theExchange))) / ONE_IN_TEN_DECIMALS;
            fee = (toTransfer*theFee)/ONE_HUNDRED_PERCENT_IN_BPS;
            // syncs done automatically on transfer
            theExchange.transferAsset(the_token, msg.sender, toTransfer-fee);
            i++;
        }
        the_token = ERC20(CLIPPER_ETH_SIGIL);
        toTransfer = (myFraction*the_token.uniBalanceOf(address(theExchange))) / ONE_IN_TEN_DECIMALS;
        fee = (toTransfer*theFee)/ONE_HUNDRED_PERCENT_IN_BPS;
        // syncs done automatically on transfer
        theExchange.transferAsset(the_token, msg.sender, toTransfer-fee);
    }

    // Can pull out all assets without fees if you are the exclusive of tokens
    function withdrawAll() external nonReentrant {
        // This will fail if the sender doesn't own the entire pool
        theExchange.swapBurn(msg.sender, theExchange.fullyDilutedSupply());
        // ONE_IN_TEN_DECIMALS = 100% of the pool's assets, no fees
        _withdraw(ONE_IN_TEN_DECIMALS, 0);
    }

    // Proportional withdrawal into ALL contracts
    function withdraw(uint256 amount) external nonReentrant {
        // Multiply by 1e10 for decimals, then divide before transfer
        uint256 myFraction = (amount*ONE_IN_TEN_DECIMALS)/theExchange.fullyDilutedSupply();
        require(myFraction > 1, "Clipper: Not enough to withdraw");

        // This will fail if the sender doesn't have enough
        theExchange.swapBurn(msg.sender, amount);
        _withdraw(myFraction, swapFee);
    }
}