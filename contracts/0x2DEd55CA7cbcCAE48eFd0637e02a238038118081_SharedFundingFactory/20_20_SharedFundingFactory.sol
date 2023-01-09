// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ISharedFundingFactory.sol";

/**
 * @title SharedFundingFactory
 * @author ChangeDao
 * @notice Generates SharedFunding clone
 * @dev ChangeDao admin is the owner
 */
contract SharedFundingFactory is ISharedFundingFactory, Ownable {
    /* ============== State Variables ============== */

    IController public override controller;
    ISharedFunding public override sharedFunding;
    IFundingAllocations public override allocations;

    /* ============== Constructor ============== */

    /**
     * @param _sharedFunding Sets SharedFunding address
     * @param _allocations Sets FundingAllocations address
     */
    constructor(ISharedFunding _sharedFunding, IFundingAllocations _allocations)
    {
        sharedFunding = _sharedFunding;
        allocations = _allocations;
    }

    /* ============== Factory Function ============== */

    /**
     * @notice Creates sharedFundingClone
     * @param _changeDaoNFTClone changeDaoNFTClone address
     * @param _mintPrice mintPrice
     * @param _totalMints totalMints
     * @param _maxMintAmountRainbow maxMintAmountRainbow
     * @param _maxMintAmountPublic maxMintAmountPublic
     * @param _rainbowDuration rainbowDuration
     * @param _rainbowMerkleRoot rainbowMerkleRoot
     * @param _fundingPSClone fundingPSClone address
     * @param _changeMaker Address of the changeMaker that is making the sharedFundingClone
     * @param _isPaused pause status
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
    ) external override returns (address) {
        require(
            _msgSender() == address(controller),
            "SFF: Controller is not caller"
        );

        address payable sharedFundingClone = payable(
            Clones.clone(address(sharedFunding))
        );

        ISharedFunding(sharedFundingClone).initialize(
            _changeDaoNFTClone,
            allocations,
            _mintPrice,
            _totalMints,
            _maxMintAmountRainbow,
            _maxMintAmountPublic,
            _rainbowDuration,
            _rainbowMerkleRoot,
            _fundingPSClone,
            _changeMaker,
            _isPaused
        );

        emit SharedFundingCreated(
            _changeDaoNFTClone,
            ISharedFunding(sharedFundingClone),
            _isPaused
        );
        return sharedFundingClone;
    }

    /* ============== Setter Functions ============== */

    /**
     * @notice Sets address for the SharedFunding implementation contract
     * @param _sharedFunding SharedFunding address
     */
    function setSharedFundingImplementation(ISharedFunding _sharedFunding)
        external
        override
        onlyOwner
    {
        sharedFunding = _sharedFunding;
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