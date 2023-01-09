// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "../interfaces/IPaymentSplitterFactory.sol";

/**
 * @title PaymentSplitterFactory
 * @author ChangeDao
 * @notice Generates PaymentSplitter clone
 * @dev ChangeDao admin is the owner
 */
contract PaymentSplitterFactory is IPaymentSplitterFactory, Ownable {
    /* ============== State Variables ============== */

    IPaymentSplitter public override paymentSplitter;
    IFundingAllocations public override allocations;
    IController public override controller;
    bytes32 constant private _CHANGEDAO_FUNDING = "CHANGEDAO_FUNDING";
    bytes32 constant private _CHANGEDAO_ROYALTIES = "CHANGEDAO_ROYALTIES";

    /* ============== Constructor ============== */

    /**
     * @param _paymentSplitter Sets PaymentSplitter address
     * @param _allocations Sets FundingAllocations address
     */
    constructor(
        IPaymentSplitter _paymentSplitter,
        IFundingAllocations _allocations
    ) {
        paymentSplitter = _paymentSplitter;
        allocations = _allocations;
    }

    /* ============== Factory Functions ============== */

    /**
     * @dev The royaltiesPSClone must be created before the fundingPSClone.  The royaltiesPSClone address is set on the changeDaoNFTClone.  When creating a fundingPSClone, the factory checks that the royaltiesPSClone address has been set on the changeDaoNFTClone.
     * @param _changeDaoNFTClone changeDaoNFTClone address
     * @param _payees Array of recipient addresses
     * @param _shares Array of share amounts received by the recipients
     * @param _changeMaker Address of the changeMaker that is making the project
     */
    function createRoyaltiesPSClone(
        IChangeDaoNFT _changeDaoNFTClone,
        address[] memory _payees,
        uint256[] memory _shares,
        address _changeMaker
    ) external override returns (IPaymentSplitter) {
        require(
            _msgSender() == address(controller),
            "PSF: Controller is not caller"
        );
        require(
            address(_changeDaoNFTClone) != address(0x0),
            "PSF: _changeDaoNFTClone is zero address"
        );

        address payable royaltiesPSClone = payable(
            Clones.clone(address(paymentSplitter))
        );

        IPaymentSplitter(royaltiesPSClone).initialize(
            _changeMaker,
            _CHANGEDAO_ROYALTIES,
            allocations,
            _payees,
            _shares
        );

        emit RoyaltiesPSCloneDeployed(
            IPaymentSplitter(royaltiesPSClone),
            _changeDaoNFTClone
        );

        return IPaymentSplitter(royaltiesPSClone);
    }

    /**
     * @dev Any fundingPSClone that is set on a sharedFundingClone will be checked that it is of type PaymentSplitter.
     * @param _changeDaoNFTClone changeDaoNFTClone address
     * @param _payees Array of recipient addresses
     * @param _shares Array of share amounts received by the recipients
     * @param _changeMaker Address of the changeMaker that is making the project
     */
    function createFundingPSClone(
        IChangeDaoNFT _changeDaoNFTClone,
        address[] memory _payees,
        uint256[] memory _shares,
        address _changeMaker
    ) public override returns (PaymentSplitter) {
        require(
            _msgSender() == address(controller),
            "PSF: Controller is not caller"
        );
        require(
            address(_changeDaoNFTClone) != address(0x0),
            "PSF: _changeDaoNFTClone is zero address"
        );

        /// Requires that the royaltiesPSClone be created before the fundingPSClone
        (address royaltyReceiver, ) = IERC2981(address(_changeDaoNFTClone))
            .royaltyInfo(0, 0);
        require(royaltyReceiver != address(0), "PSF: royaltiesPSClone not set");

        address payable fundingPSClone = payable(
            Clones.clone(address(paymentSplitter))
        );

        PaymentSplitter(fundingPSClone).initialize(
            _changeMaker,
            _CHANGEDAO_FUNDING,
            allocations,
            _payees,
            _shares
        );

        emit FundingPSCloneDeployed(
            PaymentSplitter(fundingPSClone),
            _changeDaoNFTClone
        );

        return PaymentSplitter(fundingPSClone);
    }

    /* ============== Setter Functions ============== */

    /**
     * @notice Sets PaymentSplitter implementation contract
     * @param _paymentSplitter PaymentSplitter address
     */
    function setPaymentSplitterImplementation(IPaymentSplitter _paymentSplitter)
        external
        override
        onlyOwner
    {
        paymentSplitter = _paymentSplitter;
    }

    /**
     * @notice Sets address for the FundingAllocations contract
     * @param _allocations FundingAllocations address
     */
    function setFundingAllocations(IFundingAllocations _allocations)
        external
        override
        onlyOwner
    {
        allocations = _allocations;
    }

    /**
     * @notice Sets address for the Controller contract
     * @param _controller Controller address
     */
    function setController(IController _controller)
        external
        override
        onlyOwner
    {
        controller = _controller;
    }
}