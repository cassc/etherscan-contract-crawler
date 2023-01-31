pragma solidity ^0.7.0 || ^0.8.0;
import "./INFTFlashBorrower.sol";


interface INFTFlashLender {

    /**
     * @dev Initiate a flash loan.
     * @param rightsId The liquid delegation to flashloan the underlying escrow asset of.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        uint256 rightsId,
        INFTFlashBorrower receiver,
        bytes calldata data
    ) external;
}