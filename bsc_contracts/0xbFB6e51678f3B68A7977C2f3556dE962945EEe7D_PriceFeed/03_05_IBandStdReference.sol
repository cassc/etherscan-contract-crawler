pragma solidity 0.7.6;


interface IBandStdReference {

    /// Returns the price data for the given base/quote pair. Revert if not available.
    function getReferenceData(string memory _base, string memory _quote)
        external
        view
        returns (uint256 rate, uint256 lastUpdatedBase, uint256 lastUpdatedRate);

}