// SPDX-License-Identifier: AGPL-3.0-only

/*      -.:````:::..        Arbor allows DAOs and other on-chain        .A
      /`:``-..-`   ..:.     entities to borrow stablecoins using       .AAA:
   ./`.:       \:``   :.    their tokens as collateral with fixed    .AAAAAA:
 ./`::`          \.--`` :.       rates and no liquidations.       .:AA.:AAAA:
./_.::            \.    .:                                       :AA..AAAAAA:
||  ::             |--``::.                                     :AA..AAAAAAA:
||_ ::             |.___.::                        ...         :AA..AAAAAAA`
|| `::             ||`|`:::                   .:AAAAAAAAA:.    .A..AAAAAAA`
||_\::             || | |::                  .AAAAAAAAAAAAAAA:  A..AAAA`
|| `::             ||\|/|::                .AAAAA.  AAAAAAAAAA:.:.``
||_\::             || | |::               .AAAAAAA```..........`:`..AA.
|| `:: An Arbor to ||/|\|::                    ``AAAAAAAAAAAAA` .AA..AAA.
||_\::  help DAOs  || | |::                          ``````     AAAA..ABG.
|| `::    Grow     ||\|/|::                                    .AAAAA..AAA.
||_\::             || | |::      For more information about    .AAAAAAA.AA.
|| `::             ||/|\|::         Arbor Finance, visit        .AAAAAAA.AA.
||_\::             ||_  |::         https://arbor.garden         .AAAAAA:AA.
`` `::                `` ::                                        .AAAAAAAA.
    ::                   ::                                            .AAAAA.
    ::                      Authors: Bookland Luckyrobot Namaskar          `*/

pragma solidity 0.8.9;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IBond {
    /// @notice Operation restricted because the Bond has matured.
    error BondPastMaturity();

    /**
        @notice Bond redemption is impossible because the grace period has not
            yet passed and the bond has not been fully paid.
    */
    error BondBeforeGracePeriodAndNotPaid();

    /// @notice Attempted to pay after payment was met.
    error PaymentAlreadyMet();

    /// @notice Attempted to sweep a token used in the contract.
    error SweepDisallowedForToken();

    /// @notice Attempted to perform an action that would do nothing.
    error ZeroAmount();

    /// @notice Attempted to withdraw with no excess payment in the contract.
    error NoPaymentToWithdraw();

    /// @notice Attempted to withdraw more collateral than available.
    error NotEnoughCollateral();

    /**
        @notice Emitted when bond shares are converted by a Bond holder.
        @param from The address converting their tokens.
        @param collateralToken The address of the collateralToken.
        @param amountOfBondsConverted The number of burnt bond shares.
        @param amountOfCollateralTokens The number of collateralTokens received.
    */
    event Convert(
        address indexed from,
        address indexed collateralToken,
        uint256 amountOfBondsConverted,
        uint256 amountOfCollateralTokens
    );

    /**
        @notice Emitted when collateral is withdrawn.
        @param from The address withdrawing the collateralTokens.
        @param receiver The address receiving the collateralTokens.
        @param token The address of the collateralToken.
        @param amount The number of collateralTokens withdrawn.
    */
    event CollateralWithdraw(
        address indexed from,
        address indexed receiver,
        address indexed token,
        uint256 amount
    );

    /**
        @notice Emitted when a portion of the Bond's principal is paid.
        @param from The address depositing payment.
        @param amount Amount paid.
        @dev The amount could be incorrect if the token takes a fee on transfer. 
    */
    event Payment(address indexed from, uint256 amount);

    /**
        @notice Emitted when a bond share is redeemed.
        @param from The Bond holder whose bond shares are burnt.
        @param paymentToken The address of the paymentToken.
        @param collateralToken The address of the collateralToken.
        @param amountOfBondsRedeemed The number of bond shares burned for
            redemption.
        @param amountOfPaymentTokensReceived The number of paymentTokens.
        @param amountOfCollateralTokens The number of collateralTokens.
    */
    event Redeem(
        address indexed from,
        address indexed paymentToken,
        address indexed collateralToken,
        uint256 amountOfBondsRedeemed,
        uint256 amountOfPaymentTokensReceived,
        uint256 amountOfCollateralTokens
    );

    /**
        @notice Emitted when payment over the required amount is withdrawn.
        @param from The caller withdrawing the excess payment amount.
        @param receiver The address receiving the paymentTokens.
        @param token The address of the paymentToken being withdrawn.
        @param amount The amount of paymentToken withdrawn.
    */
    event ExcessPaymentWithdraw(
        address indexed from,
        address indexed receiver,
        address indexed token,
        uint256 amount
    );

    /**
        @notice Emitted when a token is swept by the contract owner.
        @param from The owner's address.
        @param receiver The address receiving the swept tokens.
        @param token The address of the token that was swept.
        @param amount The number of tokens swept.
    */
    event TokenSweep(
        address from,
        address indexed receiver,
        IERC20Metadata token,
        uint256 amount
    );

    /**
        @notice The amount of paymentTokens required to fully pay the contract.
        @return paymentTokens The number of paymentTokens unpaid.
    */
    function amountUnpaid() external view returns (uint256 paymentTokens);

    /**
        @notice The external balance of the ERC20 collateral token.
        @return collateralTokens The number of collateralTokens in the contract.
    */
    function collateralBalance()
        external
        view
        returns (uint256 collateralTokens);

    /**
        @notice The number of collateralTokens per Bond.
        @dev This ratio is calculated as a deviation from 1-to-1 multiplied by
            the decimals of the collateralToken. See BondFactory's `CreateBond`.
        @return The number of collateralTokens per Bond.
    */
    function collateralRatio() external view returns (uint256);

    /**
        @notice The ERC20 token used as collateral backing the bond.
        @return The collateralToken's address.
    */
    function collateralToken() external view returns (address);

    /**
        @notice For convertible Bonds (ones with a convertibilityRatio > 0),
            the Bond holder may convert their bond to underlying collateral at
            the convertibleRatio. The bond must also have not past maturity
            for this to be possible.
        @dev Emits `Convert` event.
        @param bonds The number of bonds which will be burnt and converted
            into the collateral at the convertibleRatio.
    */
    function convert(uint256 bonds) external;

    /**
        @notice The number of convertibleTokens the bonds will convert into.
        @dev This ratio is calculated as a deviation from 1-to-1 multiplied by
            the decimals of the collateralToken. See BondFactory's `CreateBond`.
            The "convertibleTokens" are a subset of the collateralTokens, based
            on this ratio. If this ratio is 0, the bond is not convertible.
        @return The number of convertibleTokens per Bond.
    */
    function convertibleRatio() external view returns (uint256);

    /**
        @notice This one-time setup initiated by the BondFactory initializes the
            Bond with the given configuration.
        @dev New Bond contract deployed via clone. See `BondFactory`.
        @dev During initialization, __Ownable_init is not called because the
            owner would be set to the BondFactory's Address. Additionally,
            __ERC20Burnable_init is not called because it generates an empty
            function.
        @param bondName Passed into the ERC20 token to define the name.
        @param bondSymbol Passed into the ERC20 token to define the symbol.
        @param bondOwner Ownership of the created Bond is transferred to this
            address by way of _transferOwnership and also the address that
            tokens are minted to. See `initialize` in `Bond`.
        @param _maturity The timestamp at which the Bond will mature.
        @param _paymentToken The ERC20 token address the Bond is redeemable for.
        @param _collateralToken The ERC20 token address the Bond is backed by.
        @param _collateralRatio The amount of collateral tokens per bond.
        @param _convertibleRatio The amount of convertible tokens per bond.
        @param maxSupply The amount of Bonds given to the owner during the one-
            time mint during this initialization.
    */
    function initialize(
        string memory bondName,
        string memory bondSymbol,
        address bondOwner,
        uint256 _maturity,
        address _paymentToken,
        address _collateralToken,
        uint256 _collateralRatio,
        uint256 _convertibleRatio,
        uint256 maxSupply
    ) external;

    /**
        @notice Checks if the maturity timestamp has passed.
        @return isBondMature Whether or not the Bond has reached maturity.
    */
    function isMature() external view returns (bool isBondMature);

    /**
        @notice A date set at Bond creation when the Bond will mature.
        @return The maturity date as a timestamp.
    */
    function maturity() external view returns (uint256);

    /**
        @notice One week after the maturity date. Bond collateral can be 
            redeemed after this date.
        @return gracePeriodEndTimestamp The grace period end date as 
            a timestamp. This is always one week after the maturity date
    */
    function gracePeriodEnd()
        external
        view
        returns (uint256 gracePeriodEndTimestamp);

    /**
        @notice Allows the owner to pay the bond by depositing paymentTokens.
        @dev Emits `Payment` event.
        @param amount The number of paymentTokens to deposit.
    */
    function pay(uint256 amount) external;

    /**
        @notice Gets the external balance of the ERC20 paymentToken.
        @return paymentTokens The number of paymentTokens in the contract.
    */
    function paymentBalance() external view returns (uint256 paymentTokens);

    /**
        @notice This is the token the borrower deposits into the contract and
            what the Bond holders will receive when redeemed.
        @return The address of the token.
    */
    function paymentToken() external view returns (address);

    /**
        @notice Before maturity, if the given bonds are converted, this would be
            the number of collateralTokens received. This function rounds down
            the number of returned collateral.
        @param bonds The number of bond shares burnt and converted into
            collateralTokens.
        @return collateralTokens The number of collateralTokens the Bonds would
            be converted into.
    */
    function previewConvertBeforeMaturity(uint256 bonds)
        external
        view
        returns (uint256 collateralTokens);

    /**
        @notice At maturity, if the given bond shares are redeemed, this would
            be the number of collateralTokens and paymentTokens received by the
            bond holder. The number of paymentTokens to receive is rounded down.
        @param bonds The number of Bonds to burn and redeem for tokens.
        @return paymentTokensToSend The number of paymentTokens that the bond
            shares would be redeemed for.
        @return collateralTokensToSend The number of collateralTokens that would
            be redeemed for.
    */
    function previewRedeemAtMaturity(uint256 bonds)
        external
        view
        returns (uint256 paymentTokensToSend, uint256 collateralTokensToSend);

    /** 
        @notice The number of collateralTokens that the owner would be able to 
            withdraw from the contract. This function rounds up the number 
            of collateralTokens required in the contract and therefore may round
            down the amount received.
        @dev This function calculates the amount of collateralTokens that are
            able to be withdrawn by the owner. The amount of tokens can
            increase when Bonds are burnt and converted as well when payment is
            made. Each Bond is covered by a certain amount of collateral to
            the collateralRatio. In addition to covering the collateralRatio,
            convertible Bonds (ones with a convertibleRatio greater than 0) must
            have enough convertibleTokens in the contract to the totalSupply of
            Bonds as well. That means even if all of the Bonds were covered by
            payment, there must still be enough collateral in the contract to
            cover the portion of collateral that would be required to convert
            the totalSupply of outstanding Bonds. At the maturity date, however,
            all collateral will be able to be withdrawn as the Bond would no
            longer be convertible.

            There are the following scenarios:
            bond IS paid AND mature (Paid)
                to cover collateralRatio: 0
                to cover convertibleRatio: 0

            bond IS paid AND NOT mature (PaidEarly)
                to cover collateralRatio: 0
                to cover convertibleRatio: totalSupply * convertibleRatio

            * totalUncoveredSupply: Bonds not covered by paymentTokens *

            bond is NOT paid AND NOT mature (Active)
                to cover collateralRatio: totalUncoveredSupply * collateralRatio
                to cover convertibleRatio: totalSupply * convertibleRatio

            bond is NOT paid AND mature (Defaulted)
                to cover collateralRatio: totalUncoveredSupply * collateralRatio
                to cover convertibleRatio: 0
        @param payment The number of paymentTokens to add when previewing a
            withdraw.
        @return collateralTokens The number of collateralTokens that would be
            withdrawn.
     */
    function previewWithdrawExcessCollateralAfterPayment(uint256 payment)
        external
        view
        returns (uint256 collateralTokens);

    /**
        @notice The number of collateralTokens that the owner would be able to 
            withdraw from the contract. This does not take into account an
            amount of payment like `previewWithdrawExcessCollateralAfterPayment`
            does. See that function for more information.
        @dev Calls `previewWithdrawExcessCollateralAfterPayment` with a payment
            amount of 0.
        @return collateralTokens The number of collateralTokens that would be
            withdrawn.
    */
    function previewWithdrawExcessCollateral()
        external
        view
        returns (uint256 collateralTokens);

    /**
        @notice The number of excess paymentTokens that the owner would be able
            to withdraw from the contract.
        @return paymentTokens The number of paymentTokens that would be
            withdrawn.
    */
    function previewWithdrawExcessPayment()
        external
        view
        returns (uint256 paymentTokens);

    /**
        @notice The Bond holder can burn bond shares in return for their portion
            of paymentTokens and collateralTokens backing the Bonds. These
            portions of tokens depends on the number of paymentTokens deposited.
            When the Bond is fully paid, redemption will result in all 
            paymentTokens. If the Bond has reached maturity without being fully
            paid, a portion of the collateralTokens will be available.
        @dev Emits Redeem event.
        @param bonds The number of bond shares to redeem and burn.
    */
    function redeem(uint256 bonds) external;

    /**
        @notice Sends ERC20 tokens to the owner that are in this contract.
        @dev The collateralToken and paymentToken cannot be swept. Emits 
            `TokenSweep` event.
        @param sweepingToken The ERC20 token to sweep and send to the receiver.
        @param receiver The address that is transferred the swept token.
    */
    function sweep(IERC20Metadata sweepingToken, address receiver) external;

    /**
        @notice The Owner may withdraw excess collateral from the Bond contract.
            The number of collateralTokens remaining in the contract must be
            enough to cover the total supply of Bonds in accordance to both the collateralRatio and convertibleRatio.
        @dev Emits `CollateralWithdraw` event.
        @param amount The number of collateralTokens to withdraw. Reverts if
            the amount is greater than available in the contract. 
        @param receiver The address transferred the excess collateralTokens.
    */
    function withdrawExcessCollateral(uint256 amount, address receiver)
        external;

    /**
        @notice The owner can withdraw any excess paymentToken in the contract.
        @param receiver The address that is transferred the excess paymentToken.
    */
    function withdrawExcessPayment(address receiver) external;
}