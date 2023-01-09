// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../PaymentSplitter/PaymentSplitter.sol";
import "./IFundingAllocations.sol";
import "./IPaymentSplitter.sol";
import "./IChangeDaoNFT.sol";
import "./IController.sol";

/**
 * @title IPaymentSplitterFactory
 * @author ChangeDao
 */
interface IPaymentSplitterFactory {
    /* ============== Events ============== */

    /**
     * @notice Emitted when a fundingPSClone is created
     */
    event FundingPSCloneDeployed(
        PaymentSplitter indexed fundingPSClone,
        IChangeDaoNFT indexed changeDaoNFTClone
    );

    /**
     * @notice Emitted when a royaltiesPSClone is created
     */
    event RoyaltiesPSCloneDeployed(
        IPaymentSplitter indexed royaltiesPSClone,
        IChangeDaoNFT indexed changeDaoNFTClone
    );

    /* ============== Getter Functions ============== */

    function paymentSplitter() external view returns (IPaymentSplitter);

    function allocations() external view returns (IFundingAllocations);

    function controller() external view returns (IController);

    /* ============== Factory Functions ============== */

    function createRoyaltiesPSClone(
        IChangeDaoNFT _changeDaoNFTClone,
        address[] memory _payees,
        uint256[] memory _shares,
        address _changeMaker
    ) external returns (IPaymentSplitter);

    function createFundingPSClone(
        IChangeDaoNFT _changeDaoNFTClone,
        address[] memory _payees,
        uint256[] memory _shares,
        address _changeMaker
    ) external returns (PaymentSplitter);

    /* ============== Setter Functions ============== */

    function setPaymentSplitterImplementation(IPaymentSplitter _paymentSplitter)
        external;

    function setFundingAllocations(IFundingAllocations _allocations) external;

    function setController(IController _controller) external;
}