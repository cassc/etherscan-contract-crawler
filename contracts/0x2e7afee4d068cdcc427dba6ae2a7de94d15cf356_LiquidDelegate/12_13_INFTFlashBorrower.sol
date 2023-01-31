pragma solidity ^0.7.0 || ^0.8.0;


interface INFTFlashBorrower {

    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param id The tokenId lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "INFTFlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 id,
        bytes calldata data
    ) external returns (bytes32);
}