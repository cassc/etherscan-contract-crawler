/// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "../interfaces/ISTOToken.sol";

/// @title STOErrors
/// @custom:security-contact [email protected]
abstract contract STOErrors {
    /// User `caller` is not the owner of the contract
    error CallerIsNotOwner(address caller);
    /// User `caller` is not the issuer of the contract
    error CallerIsNotIssuer(address caller);
	/// User `caller` is not the same address of the Claimer Address
    error CallerIsNotClaimer(address caller);
    /// Issuer `issuer` can't start a new Issuance Process if the Previous one has not been Finalized and Withdrawn
    error IssuanceNotFinalized(address issuer);
    /// Issuance start date has not been reached 
    error IssuanceNotStarted(address issuer);
    /// The Initialization of the Issuance Process sent by the Issuer `issuer` is not valid
    error InitialValueWrong(address issuer);
    /// This transaction exceed the Max Supply of STO Token
    error MaxSupplyExceeded();
    /// The issuance collected funds are not withdrawn yet
    error IssuanceNotWithdrawn(address issuer);
    /// The issuance process is not in rollback state
    error IssuanceNotInRollback(uint256 index);
    /// Fired when fees are over 100%
    error FeeOverLimits(uint256 newFee);
    /// The Issuer `issuer` tried to Whitelisted not valid ERC20 Smart Contract (`token`)
    error AddressIsNotContract(address token, address issuer);
    /// The Issuer `issuer` tried to Finalize the Issuance Process before to End Date `endDate`
    error IssuanceNotEnded(address issuer, uint256 endDate);
    /// The Issuer `issuer` tried to Finalize the Issuance Process was Finalized
    error IssuanceWasFinalized(address issuer);
    /// The Issuer `issuer` tried to Withdraw the Issuance Process was Withdrawn
    error IssuanceWasWithdrawn(address issuer);
    /// The Issuer `issuer` tried to Rollback the Issuance Process was Rollbacked
    error IssuanceWasRollbacked(address issuer);
    /// The User `user` tried to refund the ERC20 Token in the Issuance Process was Successful
    error IssuanceWasSuccessful(address user);
    /// The User `user` tried to redeem the STO Token in the Issuance Process was not Successful
    error IssuanceWasNotSuccessful(address user);
    /// The User `user` tried to buy STO Token in the Issuance Process was ended in `endDate`
    error IssuanceEnded(address user, uint256 endDate);
    /// The User `user` tried to buy with ERC20 `token` is not WhiteListed in the Issuance Process
    error TokenIsNotWhitelisted(address token, address user);
    /// The User `user` tried to buy STO Token, and the Amount `amount` exceed the Maximal Ticket `maxTicket`
    error AmountExceeded(address user, uint256 amount, uint256 maxTicket);
	/// the User `user` tried to buy STO Token, and the Amount `amount` is under the Minimal Ticket `minTicket`
	error InsufficientAmount(address user, uint256 amount, uint256 minTicket);
    /// The user `user` tried to buy STO Token, and the Amount `amount` exceed the Amount Available `amountAvailable`
	/// @param user The user address
	/// @param amount The amount of token to buy
	/// @param amountAvailable The amount of token available
    error HardCapExceeded(
        address user,
        uint256 amount,
        uint256 amountAvailable
    );
    /// The User `user` has not enough balance `amount` in the ERC20 Token `token`
    error InsufficientBalance(address user, address token, uint256 amount);
    /// The User `user` tried to buy USDC Token, and the Swap with ERC20 Token `tokenERC20` was not Successful
    error SwapFailure(address user, address tokenERC20, uint256 priceInUSD, uint256 balanceAfter);
    /// The User `user` tried to redeem the ERC20 Token Again! in the Issuance Process with Index `index`
    error RedeemedAlready(address user, uint256 index);
    /// The User `user` tried to be refunded with payment tokend Again! in the Issuance Process with Index `index`
    error RefundedAlready(address user, uint256 index);
    /// The User `user` is not Investor in the Issuance Process with Index `index`
    error NotInvestor(address user, uint256 index);
    /// The Max Amount of STO Token in the Issuance Process will be Raised
    error HardCapRaised();
    /// User `user`,don't have permission to reinitialize the contract
    error UserIsNotOwner(address user);
    /// User is not Whitelisted, User `user`,don't have permission to transfer or call some functions
    error UserIsNotWhitelisted(address user);
	/// At least pair of arrays have a different length
    error LengthsMismatch();
	/// The premint Amount of STO Tokens in the Issuance Process exceeds the Max Amount of STO Tokens
    error PremintGreaterThanMaxSupply();
	/// The Address can't be zero address
	error NotZeroAddress();
	/// The Variable can't be zero
	error NotZeroValue();
	/// The Address is not a Contract
	error NotContractAddress();
	/// The Dividend Amount can't be zero
	error DividendAmountIsZero();
	/// The Wallet `claimer` is not Available to Claim Dividend
	error NotAvailableToClaim(address claimer);
	/// The User `claimer` can't claim
	error NotAmountToClaim(address claimer);
	///The User `user` try to claim an amount `amountToClaim` more than the amount available `amountAvailable`
	error ExceedAmountAvailable(address claimer, uint256 amountAvailable, uint256 amountToClaim);
	/// The User `user` is not the Minter of the STO Token
	error NotMinter(address user);
	/// The Transaction sender by User `user`, with Token ERC20 `tokenERC20` is not valid
	error ApproveFailed(address user, address tokenERC20);
    /// Confiscation Feature is Disabled
    error ConfiscationDisabled();
    // The token is not the payment token
	error InvalidPaymentToken(address token);
}