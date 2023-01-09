// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IController.sol";

/**
 * @title Controller
 * @author ChangeDao
 * @dev This contract provides the functions for a changeMaker to create the four clone contracts needed in a ChangeDao project.  The four clones can be created in two separate transactions in this order:
  createNFTAndPSClones()
  callSharedFundingFactory()
 */

contract Controller is IController, Ownable, Pausable {
    /* ============== State Variables ============== */

    IChangeDaoNFTFactory public override changeDaoNFTFactory;
    IPaymentSplitterFactory public override paymentSplitterFactory;
    ISharedFundingFactory public override sharedFundingFactory;
    IChangeMakers public override changeMakers;

    /* ============ Modifier ============ */

    /**
     * @dev Limits access to either the Controller contract owner or to any address stored in approvedChangeMakers
     */
    modifier onlyChangeMakerOrOwner() {
        require(
            changeMakers.approvedChangeMakers(_msgSender()) ||
                _msgSender() == owner(),
            "CR: _msgSender is not changemaker or owner"
        );
        _;
    }

    /* ============== Constructor ============== */

    /**
     * @notice Sets contract addresses
     * @param _changeDaoNFTFactory changeDaoNFTFactory address
     * @param _paymentSplitterFactory paymentSplitterFactory address
     * @param _sharedFundingFactory sharedFundingFactory address
     * @param _changeMakers changeMakers address
     */
    constructor(
        IChangeDaoNFTFactory _changeDaoNFTFactory,
        IPaymentSplitterFactory _paymentSplitterFactory,
        ISharedFundingFactory _sharedFundingFactory,
        IChangeMakers _changeMakers
    ) {
        changeDaoNFTFactory = _changeDaoNFTFactory;
        paymentSplitterFactory = _paymentSplitterFactory;
        sharedFundingFactory = _sharedFundingFactory;
        changeMakers = _changeMakers;
    }

    /* ============== Clone Creation Functions ============== */

    /**
     * @notice Convenience function for creating and configuring a changeDaoNFTClone, royaltiesPSClone and fundingPSClone in one transaction.  This function, along with callSharedFundingFactory(), are the only two calls needed for a changeMaker to create all four clones for a project.
     * @param _movementName Movement name
     * @param _projectName Project name
     * @param _creators Array of creator addresses
     * @param _baseURI Base URI
     * @param _royaltiesPayees Array of royalties recipient addresses
     * @param _royaltiesShares Array of share amounts for royalties recipients
     * @param _fundingPayees Array of funding recipient addresses
     * @param _fundingShares Array of share amounts for funding recipients
     */
    function createNFTAndPSClones(
        string calldata _movementName,
        string calldata _projectName,
        address[] memory _creators,
        string memory _baseURI,
        address[] memory _royaltiesPayees,
        uint256[] memory _royaltiesShares,
        address[] memory _fundingPayees,
        uint256[] memory _fundingShares
    ) external override whenNotPaused onlyChangeMakerOrOwner {
        /// @dev Create changeDaoNFTClone
        IChangeDaoNFT changeDaoNFTClone = changeDaoNFTFactory
            .createChangeDaoNFT(
                _msgSender(),
                _movementName,
                _projectName,
                _creators,
                _baseURI
            );
        /// @dev Create royaltiesPSClone
        IPaymentSplitter royaltiesPSClone = paymentSplitterFactory
            .createRoyaltiesPSClone(
                changeDaoNFTClone,
                _royaltiesPayees,
                _royaltiesShares,
                _msgSender()
            );
        /// @dev Configure changeDaoNFTClone
        changeDaoNFTClone.setDefaultRoyalty(
            royaltiesPSClone,
            changeDaoNFTClone,
            _msgSender()
        );
        /// @dev Create fundingPSClone
        paymentSplitterFactory.createFundingPSClone(
            changeDaoNFTClone,
            _fundingPayees,
            _fundingShares,
            _msgSender()
        );
    }

    /**
     * @notice Create a sharedFundingClone as part of the project creation
     * @param _changeDaoNFTClone changeDaoNFTClone address
     * @param _mintPrice mintPrice
     * @param _totalMints totalMints
     * @param _maxMintAmountRainbow maxMintAmountRainbow
     * @param _maxMintAmountPublic maxMintAmountPublic
     * @param _rainbowDuration rainbowDuration
     * @param _rainbowMerkleRoot rainbowMerkleRoot
     * @param _fundingPSClone fundingPSClone address
     * @param _isPaused initial pause status
     */
    function callSharedFundingFactory(
        IChangeDaoNFT _changeDaoNFTClone,
        uint256 _mintPrice,
        uint64 _totalMints,
        uint32 _maxMintAmountRainbow,
        uint32 _maxMintAmountPublic,
        uint256 _rainbowDuration,
        bytes32 _rainbowMerkleRoot,
        PaymentSplitter _fundingPSClone,
        bool _isPaused
    ) external override whenNotPaused onlyChangeMakerOrOwner {
        ///@dev Create sharedFundingClone
        address sharedFundingClone = sharedFundingFactory
            .createSharedFundingClone(
                _changeDaoNFTClone,
                _mintPrice,
                _totalMints,
                _maxMintAmountRainbow,
                _maxMintAmountPublic,
                _rainbowDuration,
                _rainbowMerkleRoot,
                _fundingPSClone,
                _msgSender(),
                _isPaused
            );
        ///@dev Configure changeDaoNFTClone
        _changeDaoNFTClone.setFundingClone(
            sharedFundingClone, // use address type, not ISharedFunding type
            _changeDaoNFTClone,
            _msgSender()
        );
    }

    /* ============== Pause Functions ============== */

    /**
     * @notice Suspends all use of the platform
     */
    function pause() public override onlyOwner {
        _pause();
    }

    /**
     * @notice Resumes possiblity for using the platform
     */
    function unpause() public override onlyOwner {
        _unpause();
    }

    /* ============== Contract Setter Functions ============== */

    /**
     * @notice Set the ChangeDaoNFTFactory contract
     * @param _newChangeDaoNFTFactory ChangeDaoNFTFactory address
     */
    function setChangeDaoNFTFactory(
        IChangeDaoNFTFactory _newChangeDaoNFTFactory
    ) external override onlyOwner {
        changeDaoNFTFactory = _newChangeDaoNFTFactory;
    }

    /**
     * @notice Set the PaymentSplitterFactory contract
     * @param _newPSFactory PaymentSplitterFactory address
     */
    function setPaymentSplitterFactory(IPaymentSplitterFactory _newPSFactory)
        external
        override
        onlyOwner
    {
        paymentSplitterFactory = _newPSFactory;
    }

    /**
     * @notice Set the SharedFundingFactory contract
     * @param _newSFFactory SharedFundingFactory address
     */
    function setSharedFundingFactory(ISharedFundingFactory _newSFFactory)
        external
        override
        onlyOwner
    {
        sharedFundingFactory = _newSFFactory;
    }

    /**
     * @notice Set the ChangeMakers contract
     * @param _newChangeMakers ChangeMakers address
     */
    function setChangeMakers(IChangeMakers _newChangeMakers)
        external
        override
        onlyOwner
    {
        changeMakers = _newChangeMakers;
    }
}