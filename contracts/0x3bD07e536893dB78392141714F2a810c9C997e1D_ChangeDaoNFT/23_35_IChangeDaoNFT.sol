// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IPaymentSplitter.sol";
import "./IChangeDaoNFTFactory.sol";
import "./IController.sol";

/**
 * @title IChangeDaoNFT
 * @author ChangeDao
 */
interface IChangeDaoNFT {
    /* ============== Events ============== */

    /**
     * @notice Emitted when a baseURI is set
     */
    event BaseURISet(string oldBaseURI, string newBaseURI);

    /**
     * @notice Emitted when a fundingClone is set
     * @dev This needs to be the address type so that the fundingClone variable can accommodate other types of contracts in the future other than SharedFunding.sol. Do not set it to a contract type (ex, ISharedFunding).
     */
    event FundingCloneSet(address indexed fundingClone);

    /**
     * @notice Emitted when the default royalty is set
     */
    event DefaultRoyaltySet(
        IPaymentSplitter indexed receiver,
        uint96 indexed feeNumerator
    );

    /**
     * @notice Emitted when a creator is registered
     */
    event CreatorRegistered(address indexed creator);

    /**
     * @notice Emitted when a changeDaoNFTclone is initialized
     */
    event ChangeDaoNFTInitialized(
        address indexed changeMaker,
        IChangeDaoNFT indexed changeDaoNFTImplementation,
        IChangeDaoNFT changeDaoNFTClone,
        string movementName,
        string projectName,
        string baseURI
    );

    /* ============== Implementation Getter Functions ============== */

    function feeNumerator() external view returns (uint96);

    function changeDaoNFTFactory() external view returns (IChangeDaoNFTFactory);

    function controller() external view returns (IController);

    /* ============== Clone Getter Functions ============== */

    function changeDaoNFTImplementation() external view returns (IChangeDaoNFT);

    function changeMaker() external view returns (address);

    function hasSetFundingClone() external view returns (bool);

    function baseURI() external view returns (string memory);

    ///@dev This needs to be the address type so that the fundingClone variable can accommodate other types of contracts in the future other than SharedFunding.sol.
    function fundingClone() external view returns (address);

    function tokenURI(uint256 _tokenId) external view returns (string memory);

    /* ============== Initialize ============== */

    function initialize(
        address _changeMaker,
        IChangeDaoNFT _changeDaoNFTImplementation,
        string memory _movementName,
        string memory _projectName,
        address[] memory _creators,
        string memory baseURI_
    ) external;

    /* ============== Mint Function ============== */

    function mint(uint256 _tokenId, address _owner) external;

    /* ============== NFT Configuration Functions--Clone ============== */

    function setBaseURI(string memory _newBaseURI) external;

    function setFundingClone(
        address _fundingClone, // use address type, not interface or contract type
        IChangeDaoNFT _changeDaoNFTClone,
        address _changeMaker
    ) external;

    function setDefaultRoyalty(
        IPaymentSplitter _receiver,
        IChangeDaoNFT _changeDaoNFTClone,
        address _changeMaker
    ) external;

    /* ============== NFT Configuration Function--Implementation ============== */

    function setFeeNumerator(uint96 _feeNumerator) external;

    /* ============== Contract Address Setter Functions ============== */

    function setChangeDaoNFTFactory(IChangeDaoNFTFactory _changeDaoNFTFactory)
        external;

    function setController(IController _controller) external;
}