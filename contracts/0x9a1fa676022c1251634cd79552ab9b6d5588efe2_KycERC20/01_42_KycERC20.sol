// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

import "../interfaces/IKycERC20.sol";
import "../integration/KeyringGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Wrapper.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 @notice This contract illustrates how an immutable KeyringGuard can be wrapped around collateral tokens 
 (e.g. DAI Token). Specify the token to wrap and the new name/symbol of the wrapped token - then good to go!
 Tokens can only be transferred to an address that maintains compliance with the configured policy.
 */

contract KycERC20 is IKycERC20, ERC20Permit, ERC20Wrapper, KeyringGuard {
        
    using SafeERC20 for IERC20;

    string private constant MODULE = "KycERC20";

    /**
     * @param config Keyring contract addresses. See IKycERC20. 
     * @param policyId_ The unique identifier of a Policy.
     * @param maximumConsentPeriod_ The upper limit for user consent deadlines. 
     * @param name_ The name of the new wrapped token. Passed to ERC20.constructor to set the ERC20.name
     * @param symbol_ The symbol for the new wrapped token. Passed to ERC20.constructor to set the ERC20.symbol
     */
    constructor(
        KeyringConfig memory config,
        uint32 policyId_,
        uint32 maximumConsentPeriod_,
        string memory name_,
        string memory symbol_
    )
        ERC20(name_, symbol_)
        ERC20Permit(name_)
        ERC20Wrapper(IERC20(config.collateralToken))
        KeyringGuard(config, policyId_, maximumConsentPeriod_)
    {
        if (config.collateralToken == NULL_ADDRESS)
            revert Unacceptable({
                reason: "collateral token cannot be empty"
            });
        if (bytes(name_).length == 0)
            revert Unacceptable({
                reason: "name_ cannot be empty"
            });
        if (bytes(symbol_).length == 0)
            revert Unacceptable({
                reason: "symbol_ cannot be empty"
            });
    }

    /**
     * @notice Returns decimals based on the underlying token decimals
     * @return uint8 decimals integer
     */
    function decimals() public view override(ERC20, ERC20Wrapper) returns (uint8) {
        return ERC20Wrapper.decimals();
    }

    /**
     * @notice Deposit underlying tokens and mint the same number of wrapped tokens.
     * @param trader Recipient of the wrapped tokens
     * @param amount Quantity of underlying tokens from _msgSender() to exchange for wrapped tokens (to account) at 1:1
     */
    function depositFor(address trader, uint256 amount)
        public
        override(IKycERC20, ERC20Wrapper)
        returns (bool)
    {
        if(trader != _msgSender()) {
            if (!isAuthorized(_msgSender(), trader)) 
                revert Unacceptable({
                    reason: "trader not authorized"
                });
            }
        return ERC20Wrapper.depositFor(trader, amount);
    }

    /**
     * @notice Burn a number of wrapped tokens and withdraw the same number of underlying tokens.
     * @param trader Recipient of the underlying tokens
     * @param amount Quantity of wrapped tokens from _msgSender() to exchange for underlying tokens (to account) at 1:1
     */
    function withdrawTo(address trader, uint256 amount)
        public
        override(IKycERC20, ERC20Wrapper)
        returns (bool)
    {
        if(trader != _msgSender()) {
            if (!isAuthorized(_msgSender(), trader)) 
                revert Unacceptable({
                    reason: "trader not authorized"
                });
            }
        return ERC20Wrapper.withdrawTo(trader, amount);
    }

    /**
     * @notice Wraps the inherited ERC20.transfer function with the keyringCompliance guard.
     * @param to The recipient of amount 
     * @param amount The amount to transfer.
     * @return bool True if successfully executed.
     */
    function transfer(address to, uint256 amount)
        public
        override(IERC20, ERC20)
        checkKeyring(_msgSender(), to)
        returns (bool)
    {
        return ERC20.transfer(to, amount);
    }

    /**
     * @notice Wraps the inherited ERC20.transferFrom function with the keyringCompliance guard.
     * @param from The sender of amount 
     * @param to The recipient of amount 
     * @param amount The amount to be deducted from the to's allowance.
     * @return bool True if successfully executed.
     */
    function transferFrom(address from, address to, uint256 amount) 
        public 
        override(IERC20, ERC20)
        checkKeyring(from, to)
        returns (bool)
    {
        return ERC20.transferFrom(from, to, amount);
    }

    /**
     * @notice Returns ERC2771 signer if msg.sender is a trusted forwarder, otherwise returns msg.sender.
     * @return sender User deemed to have signed the transaction.
     */
    function _msgSender()
        internal
        view
        virtual
        override(KeyringAccessControl, Context)
        returns (address sender)
    {
        return ERC2771Context._msgSender();
    }

    /**
     * @notice Returns msg.data if not from a trusted forwarder, or truncated msg.data if the signer was 
     * appended to msg.data
     * @dev Although not currently used, this function forms part of ERC2771 so is included for completeness.
     * @return data Data deemed to be the msg.data
     */
    function _msgData()
        internal
        view
        virtual
        override(KeyringAccessControl, Context)
        returns (bytes calldata)
    {
        return ERC2771Context._msgData();
    }
    
}