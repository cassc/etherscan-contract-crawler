// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../PaymentSplitter/PaymentSplitter.sol";
import "./IChangeDaoNFT.sol";
import "./ISharedFunding.sol";
import "./IFundingAllocations.sol";
import "./IController.sol";
import "./IPaymentSplitter.sol";

/**
 * @title ISharedFundingFactory
 * @author ChangeDao
 */
interface ISharedFundingFactory {
    /* ============== Events ============== */

    /**
     * @notice Emitted when a sharedFundingClone is created
     */
    event SharedFundingCreated(
        IChangeDaoNFT indexed changeDaoNFTClone,
        ISharedFunding indexed sharedFundingClone,
        bool isPaused
    );

    /* ============== Getter Functions ============== */

    function controller() external view returns (IController);

    function sharedFunding() external view returns (ISharedFunding);

    function allocations() external view returns (IFundingAllocations);

    /* ============== Factory Function ============== */

    /**
     * @dev Needs to return address type, not ISharedFunding type!!!
     * @dev NOTE: sharedFundingClone must be of address type.  This will be stored on the changeDaoNFTClone.  Future versions of the application might have different funding contracts, and so the type must remain agnostic (use address) instead of being tied to a specific contract interface (do not use ISharedFunding).
     */
    function createSharedFundingClone(
        IChangeDaoNFT _changeDaoNFTClone,
        uint256 _mintPrice,
        uint64 _totalMints,
        uint32 _maxMintAmountRainbow,
        uint32 _maxMintAmountPublic,
        uint256 _rainbowDuration,
        bytes32 _rainbowMerkleRoot,
        PaymentSplitter _fundingPSClone,
        address _changeMaker,
        bool _isPaused
    ) external returns (address); // must return address type!

    /* ============== Setter Functions ============== */

    function setSharedFundingImplementation(ISharedFunding _sharedFunding)
        external;

    function setFundingAllocations(IFundingAllocations _allocations) external;

    function setController(IController _controller) external;
}