// This interface should be implemented by any token contract
// that pairs to a taxable token (such as WETH etc.)
// It provides methods for tax communication between us (the router) and you (your contract).
// Basically just a bunch of callback methods.
interface ITaxToken {
    /// @notice Called after you claimed tokens (manually or automatically)
    /// @dev Keep logic small. Your users (eventually) pay the gas for it.
    /// @param taxableToken The token you've been sent (like WETH)
    /// @param amount The amount transferred
    function onTaxClaimed(address taxableToken, uint amount) external;
    /// @notice Called when someone takes out (sell) or puts in (buy) the taxable token.
    /// @notice We basically tell you the amount processed and ask you how many tokens
    /// @notice you want to take as fees. This gives you ULTIMATE control and flexibility.
    /// @notice You're welcome.
    /// @dev DEVs, please kiss (look up this abbreviation).
    /// @dev This function is called on every taxable transfer so logic should be as minimal as possible.
    /// @param taxableToken The taxable token (like WETH)
    /// @param from Who is selling or buying (allows wallet-specific taxes)
    /// @param isBuy True if `from` bought your token (they sold WETH for example). False if it is a sell.
    /// @param amount The amount bought or sold.
    /// @return taxToTake The tax we should take. Must be lower than or equal to `amount`.
    function takeTax(address taxableToken, address from, bool isBuy, uint amount) external returns(uint taxToTake);
    /// @notice Used to withdraw the token taxes.
    /// @notice DEVs must not forget to implement such a function, otherwise funds may not be recoverable
    /// @notice unless they send their taxes to wallets during `onTaxClaimed`.
    /// @param token The token to withdraw.
    /// @param to Token receiver.
    /// @param amount The amount to withdraw.
    function withdrawTax(address token, address to, uint amount) external;
}