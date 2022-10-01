pragma solidity ^0.8.9;

/// @title A title that should describe the contract/interface
/// @author The name of the author
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
abstract contract SaleStrategyBase {
    /// @dev Can purchase the bond? The inherit contract must implement
    function canPurchase() public view virtual returns (bool);

    /// @dev Get the issue price, inherit contract must implement
    /// @return the issue price
    function issuePrice() public view virtual returns (uint256);

    /// @dev Calculate the bond amount returns to purchaser base on purchase amount.
    /// inherit contract must implement
    /// @param amount The "face asset" amount
    /// @return bondAmount and faceAmount
    function getBondAmount(uint256 amount)
        public
        view
        virtual
        returns (uint256 bondAmount, uint256 faceAmount);

    modifier purchasable() {
        require(canPurchase(), "not purchasable");
        _;
    }
}