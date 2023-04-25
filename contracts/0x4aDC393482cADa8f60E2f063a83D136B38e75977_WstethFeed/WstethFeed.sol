/**
 *Submitted for verification at Etherscan.io on 2023-04-24
*/

pragma solidity 0.6.7;

abstract contract WSTETH {
    function stEthPerToken() external view virtual returns (uint256);
}

// WSTETH / STETH feed following GEB's DSValue interface
contract WstethFeed {
    // --- Variables ---
    WSTETH public immutable wsteth;

    bytes32 public constant symbol = "wsteth-steth";

    constructor(address wstethAddress) public {
        wsteth = WSTETH(wstethAddress);
        require(WSTETH(wstethAddress).stEthPerToken() > 0, "invalid wsteth address");
    }

    // --- Main Getters ---
    /**
     * @notice Fetch the latest result or revert if is is null
     **/
    function read() external view returns (uint256 result) {
        result = wsteth.stEthPerToken();
        require(result > 0, "invalid wsteth price");
    }

    /**
     * @notice Fetch the latest result and whether it is valid or not
     **/
    function getResultWithValidity()
        external
        view
        returns (uint256 result, bool valid)
    {
        result = wsteth.stEthPerToken();
        valid = result > 0;
    }

    // --- Median Updates ---
    /*cd 
     * @notice Remnant from other GEB medians
     */
    function updateResult(address feeReceiver) external {}
}