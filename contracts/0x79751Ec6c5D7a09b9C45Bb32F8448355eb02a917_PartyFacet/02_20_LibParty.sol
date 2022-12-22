// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {LibAppStorage, AppStorage} from "./LibAppStorage.sol";
import {LibERC20} from "./LibERC20.sol";
import {LibSignatures} from "./LibSignatures.sol";
import {LibSharedStructs} from "./LibSharedStructs.sol";
import {LibAddressArray} from "./LibAddressArray.sol";

/// "Deposit is not enough"
error DepositNotEnough();
/// "Deposit exceeds maximum required"
error DepositExceeded();
/// "User balance is not enough"
error UserBalanceNotEnough();
/// "Failed approve reset"
error FailedAproveReset();
/// "Failed approving sellToken"
error FailedAprove();
/// "0x Protocol: SWAP_CALL_FAILED"
error ZeroXFail();
/// "Invalid approval signature"
error InvalidSignature();
/// "Only one swap at a time"
error InvalidSwap();

library LibParty {
    /**
     * @notice Emitted when quotes are filled by 0x for allocation of funds
     * @dev SwapToken is not included on this event, since its have the same information
     * @param member Address of the user
     * @param sellTokens Array of sell tokens
     * @param buyTokens Array of buy tokens
     * @param soldAmounts Array of sold amount of tokens
     * @param boughtAmounts Array of bought amount of tokens
     * @param partyValueDA The party value in denomination asset prior to the allocation
     */
    event AllocationFilled(
        address member,
        address[] sellTokens,
        address[] buyTokens,
        uint256[] soldAmounts,
        uint256[] boughtAmounts,
        uint256 partyValueDA
    );

    /**
     * @notice Emitted when a member redeems shares from a party
     * @param member Address of the user
     * @param burnedPT Burned party tokens for redemption
     * @param liquidate Redemption by liquitating shares into denomination asset
     * @param redeemedAssets Array of asset addresses
     * @param redeemedAmounts Array of asset amounts
     * @param redeemedFees Array of asset fees
     * @param redeemedNetAmounts Array of net asset amounts
     */
    event RedeemedShares(
        address member,
        uint256 burnedPT,
        bool liquidate,
        address[] redeemedAssets,
        uint256[] redeemedAmounts,
        uint256[] redeemedFees,
        uint256[] redeemedNetAmounts
    );

    /***************
    PLATFORM COLLECTOR
    ***************/
    /**
     * @notice Retrieves the Platform fee to be taken from an amount
     * @param amount Base amount to calculate fees
     */
    function getPlatformFee(uint256 amount, uint256 feeBps)
        internal
        pure
        returns (uint256 fee)
    {
        fee = (amount * feeBps) / 10000;
    }

    /**
     * @notice Transfers a fee amount of an ERC20 token to the platform collector address
     * @param amount Base amount to calculate fees
     * @param token ERC-20 token address
     */
    function collectPlatformFee(uint256 amount, address token)
        internal
        returns (uint256 fee)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        fee = getPlatformFee(amount, s.platformFee);
        IERC20Metadata(token).transfer(s.platformFeeCollector, fee);
    }

    /***************
    PARTY TOKEN FUNCTIONS
    ***************/
    /**
     * @notice Swap a token using 0x Protocol
     * @param allocation The swap allocation
     * @param approval The platform signature approval for the allocation
     */
    function swapToken(
        LibSignatures.Allocation memory allocation,
        LibSignatures.Sig memory approval
    )
        internal
        returns (
            uint256 soldAmount,
            uint256 boughtAmount,
            uint256 fee
        )
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (allocation.sellTokens.length != 1) revert InvalidSwap();
        // -> Validate authenticity of assets allocation
        if (
            !LibSignatures.isValidAllocation(
                msg.sender,
                s.platformSentinel,
                allocation,
                approval
            )
        ) {
            revert InvalidSignature();
        }
        // Fill 0x Quote
        LibSharedStructs.FilledQuote memory filledQuote = fillQuote(
            allocation.sellTokens[0],
            allocation.sellAmounts[0],
            allocation.buyTokens[0],
            allocation.spenders[0],
            allocation.swapsTargets[0],
            allocation.swapsCallData[0]
        );
        soldAmount = filledQuote.soldAmount;
        boughtAmount = filledQuote.boughtAmount;
        // Collect fees
        fee = collectPlatformFee(
            filledQuote.boughtAmount,
            allocation.buyTokens[0]
        );
        // Check if bought asset is new
        if (!LibAddressArray.contains(s.tokens, allocation.buyTokens[0])) {
            // Adding new asset to list
            s.tokens.push(allocation.buyTokens[0]);
        }
    }

    /**
     * @notice Mints PartyTokens in exchange for a deposit
     * @param user User address
     * @param amountDA The deposit amount in DA
     * @param allocation The deposit allocation
     * @param approval The platform signature approval for the allocation
     */
    function mintPartyTokens(
        address user,
        uint256 amountDA,
        LibSignatures.Allocation memory allocation,
        LibSignatures.Sig memory approval
    ) internal returns (uint256 fee, uint256 mintedPT) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        // 1) Handle deposit amount is between min-max range
        if (amountDA < s.partyInfo.minDeposit) revert DepositNotEnough();
        if (s.partyInfo.maxDeposit > 0 && amountDA > s.partyInfo.maxDeposit)
            revert DepositExceeded();

        // 2) Calculate Platform Fee
        fee = getPlatformFee(amountDA, s.platformFee);

        // 3) Transfer DA from user (deposit + fees)
        IERC20Metadata(s.denominationAsset).transferFrom(
            user,
            address(this),
            amountDA + fee
        );

        // 4) Collect protocol fees
        collectPlatformFee(amountDA, s.denominationAsset);

        // 5) Allocate deposit assets
        allocateAssets(user, allocation, approval, s.platformSentinel);

        // 6) Mint PartyTokens to user
        if (s.totalSupply == 0 || allocation.partyTotalSupply == 0) {
            mintedPT =
                amountDA *
                10**(18 - IERC20Metadata(s.denominationAsset).decimals());
        } else {
            uint256 adjPartyValueDA = allocation.partyValueDA;
            /// Handle any totalSupply changes
            /// @dev Which will indicate the the allocated partyValueDA was updated in the same block by another tx
            if (allocation.partyTotalSupply != s.totalSupply) {
                // Since there has been a change in the totalSupply, we need to get the adjusted party value in DA
                /// @dev Example case:
                //          - allocation.totalSupply: 500
                //          - allocation.partyValueDA is 1000
                //          - totalSupply is 750
                //       This means that the current partyValueDA is no longer 1000, since there was a change in the totalSupply.
                //       The totalSupply delta is 50%. So the current partyValueDA should be 1500.
                adjPartyValueDA =
                    (adjPartyValueDA * s.totalSupply) /
                    allocation.partyTotalSupply;
            }
            mintedPT = (s.totalSupply * amountDA) / adjPartyValueDA;
        }
        LibERC20._mint(user, mintedPT);
    }

    /**
     * @notice Redeems funds in exchange for PartyTokens
     * @param amountPT The PartyTokens amount
     * @param _memberAddress The member's address to redeem PartyTokens in
     * @param allocation The withdraw allocation
     * @param approval The platform signature approval for the allocation
     * @param liquidate Whether to withdraw by swapping funds into DA or not
     */
    function redeemPartyTokens(
        uint256 amountPT,
        address _memberAddress,
        LibSignatures.Allocation memory allocation,
        LibSignatures.Sig memory approval,
        bool liquidate
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // 1) Check if user has PartyTokens balance to redeem
        if (amountPT > s.balances[_memberAddress])
            revert UserBalanceNotEnough();

        // 2) Get the total supply of PartyTokens
        uint256 totalSupply = s.totalSupply;

        // 3) Burn PartyTokens
        LibERC20._burn(_memberAddress, amountPT);

        if (amountPT > 0) {
            // 4) Handle holdings redemption: liquidate holdings or redeem as it is
            if (liquidate) {
                liquidateHoldings(
                    amountPT,
                    totalSupply,
                    _memberAddress,
                    allocation,
                    approval,
                    s.denominationAsset,
                    s.platformSentinel
                );
            } else {
                redeemHoldings(amountPT, totalSupply, _memberAddress, s.tokens);
            }
        }
    }

    /***************
    HELPER FUNCTIONS
    ***************/
    /**
     * @notice Redeems assets without liquidating them
     * @param amountPT The PartyTokens amount
     * @param totalSupply The current totalSupply of the PartyTokens
     * @param _memberAddress The member's address to redeem PartyTokens in
     * @param tokens Current tokens in the party
     */
    function redeemHoldings(
        uint256 amountPT,
        uint256 totalSupply,
        address _memberAddress,
        address[] storage tokens
    ) private {
        uint256[] memory redeemedAmounts = new uint256[](tokens.length);
        uint256[] memory redeemedFees = new uint256[](tokens.length);
        uint256[] memory redeemedNetAmounts = new uint256[](tokens.length);

        // 1) Handle token holdings
        for (uint256 i = 0; i < tokens.length; i++) {
            // 2) Get token amount to redeem
            uint256 tBalance = IERC20Metadata(tokens[i]).balanceOf(
                address(this)
            );
            redeemedAmounts[i] = ((tBalance * amountPT) / totalSupply);

            if (redeemedAmounts[i] > 0) {
                // 3) Collect fees
                redeemedFees[i] = collectPlatformFee(
                    redeemedAmounts[i],
                    tokens[i]
                );
                redeemedNetAmounts[i] = (redeemedAmounts[i] - redeemedFees[i]);

                // 4) Transfer relative asset funds to user
                IERC20Metadata(tokens[i]).transfer(
                    _memberAddress,
                    redeemedNetAmounts[i]
                );
            }
        }
        emit RedeemedShares(
            _memberAddress,
            amountPT,
            false,
            tokens,
            redeemedAmounts,
            redeemedFees,
            redeemedNetAmounts
        );
    }

    /**
     * @notice Redeems assets by liquidating them into DA
     * @param amountPT The PartyTokens amount
     * @param totalSupply The current totalSupply of the PartyTokens
     * @param _memberAddress The member's address to redeem PartyTokens in
     * @param allocation The liquidation allocation
     * @param approval The platform signature approval for the allocation
     * @param denominationAsset The party's denomination asset address
     * @param sentinel The platform sentinel address
     */
    function liquidateHoldings(
        uint256 amountPT,
        uint256 totalSupply,
        address _memberAddress,
        LibSignatures.Allocation memory allocation,
        LibSignatures.Sig memory approval,
        address denominationAsset,
        address sentinel
    ) private {
        uint256[] memory redeemedAmounts = new uint256[](1);
        uint256[] memory redeemedFees = new uint256[](1);
        uint256[] memory redeemedNetAmounts = new uint256[](1);

        // 1) Get the portion of denomination asset to withdraw (before allocation)
        uint256 daBalance = IERC20Metadata(denominationAsset).balanceOf(
            address(this)
        );
        redeemedAmounts[0] = ((daBalance * amountPT) / totalSupply);

        // 2) Swap member's share of other assets into the denomination asset
        LibSharedStructs.Allocated memory allocated = allocateAssets(
            _memberAddress,
            allocation,
            approval,
            sentinel
        );

        // 3) Iterate through allocation and accumulate pending withdrawal for the user
        for (uint256 i = 0; i < allocated.boughtAmounts.length; i++) {
            // Double check that bought tokens are same as DA
            if (allocated.buyTokens[i] == denominationAsset) {
                redeemedAmounts[0] += allocated.boughtAmounts[i];
            }
        }

        // 4) Collect fees
        redeemedFees[0] = collectPlatformFee(
            redeemedAmounts[0],
            denominationAsset
        );

        // 5) Transfer relative DA funds to user
        redeemedNetAmounts[0] = redeemedAmounts[0] - redeemedFees[0];
        IERC20Metadata(denominationAsset).transfer(
            _memberAddress,
            redeemedNetAmounts[0]
        );

        emit RedeemedShares(
            _memberAddress,
            amountPT,
            true,
            allocated.sellTokens,
            redeemedAmounts,
            redeemedFees,
            redeemedNetAmounts
        );
    }

    /**
     * @notice Allocates multiple 0x quotes
     * @param sender The user's address
     * @param allocation The allocation
     * @param approval The platform signature approval for the allocation
     * @param sentinel The platform sentinel address
     */
    function allocateAssets(
        address sender,
        LibSignatures.Allocation memory allocation,
        LibSignatures.Sig memory approval,
        address sentinel
    ) private returns (LibSharedStructs.Allocated memory allocated) {
        if (
            !LibSignatures.isValidAllocation(
                sender,
                sentinel,
                allocation,
                approval
            )
        ) {
            revert InvalidSignature();
        }

        // Declaring array with a known length
        allocated.sellTokens = new address[](allocation.sellTokens.length);
        allocated.buyTokens = new address[](allocation.sellTokens.length);
        allocated.soldAmounts = new uint256[](allocation.sellTokens.length);
        allocated.boughtAmounts = new uint256[](allocation.sellTokens.length);
        for (uint256 i = 0; i < allocation.sellTokens.length; i++) {
            LibSharedStructs.FilledQuote memory filledQuote = fillQuote(
                allocation.sellTokens[i],
                allocation.sellAmounts[i],
                allocation.buyTokens[i],
                allocation.spenders[i],
                allocation.swapsTargets[i],
                allocation.swapsCallData[i]
            );
            allocated.sellTokens[i] = address(allocation.sellTokens[i]);
            allocated.buyTokens[i] = address(allocation.buyTokens[i]);
            allocated.soldAmounts[i] = filledQuote.soldAmount;
            allocated.boughtAmounts[i] = filledQuote.boughtAmount;
        }

        // Emit AllocationFilled
        emit AllocationFilled(
            sender,
            allocated.sellTokens,
            allocated.buyTokens,
            allocated.soldAmounts,
            allocated.boughtAmounts,
            allocation.partyValueDA
        );
    }

    /**
     * @notice Swap a token held by this contract using a 0x-API quote.
     * @param sellToken The token address to sell
     * @param sellAmount The token amount to sell
     * @param buyToken The token address to buy
     * @param spender The spender address
     * @param swapTarget The swap target to interact (0x Exchange Proxy)
     * @param swapCallData The swap calldata to pass
     */
    function fillQuote(
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        address spender,
        address payable swapTarget,
        bytes memory swapCallData
    ) private returns (LibSharedStructs.FilledQuote memory filledQuote) {
        if (!IERC20Metadata(sellToken).approve(spender, 0))
            revert FailedAproveReset();
        if (!IERC20Metadata(sellToken).approve(spender, sellAmount))
            revert FailedAprove();

        // Track initial balance of the sellToken to determine how much we've sold.
        filledQuote.initialSellBalance = IERC20Metadata(sellToken).balanceOf(
            address(this)
        );

        // Track initial balance of the buyToken to determine how much we've bought.
        filledQuote.initialBuyBalance = IERC20Metadata(buyToken).balanceOf(
            address(this)
        );
        // Execute 0xSwap
        (bool success, ) = swapTarget.call{value: msg.value}(swapCallData);
        if (!success) revert ZeroXFail();

        // Get how much we've sold.
        filledQuote.soldAmount =
            filledQuote.initialSellBalance -
            IERC20Metadata(sellToken).balanceOf(address(this));

        // Get how much we've bought.
        filledQuote.boughtAmount =
            IERC20Metadata(buyToken).balanceOf(address(this)) -
            filledQuote.initialBuyBalance;
    }
}