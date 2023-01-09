// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../PaymentSplitter/PaymentSplitter.sol";
import "./IChangeMakers.sol";
import "./IPaymentSplitterFactory.sol";
import "./ISharedFundingFactory.sol";
import "./IChangeDaoNFTFactory.sol";
import "./IChangeDaoNFT.sol";
import "./IPaymentSplitter.sol";

/**
 * @title IController
 * @author ChangeDao
 */
interface IController {
    /* ============== Getter Functions ============== */

    function changeDaoNFTFactory() external view returns (IChangeDaoNFTFactory);

    function paymentSplitterFactory()
        external
        view
        returns (IPaymentSplitterFactory);

    function sharedFundingFactory()
        external
        view
        returns (ISharedFundingFactory);

    function changeMakers() external view returns (IChangeMakers);

    /* ============== Clone Creation Functions ============== */

    function createNFTAndPSClones(
        string memory _movementName,
        string memory _projectName,
        address[] memory _creators,
        string memory _baseURI,
        address[] memory _royaltiesPayees,
        uint256[] memory _royaltiesShares,
        address[] memory _fundingPayees,
        uint256[] memory _fundingShares
    ) external;

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
    ) external;

    /* ============== Pause Functions ============== */

    function pause() external;

    function unpause() external;

    /* ============== Contract Setter Functions ============== */

    function setChangeDaoNFTFactory(
        IChangeDaoNFTFactory _newChangeDaoNFTFactory
    ) external;

    function setChangeMakers(IChangeMakers _newChangeMakers) external;

    function setPaymentSplitterFactory(IPaymentSplitterFactory _newPSFactory)
        external;

    function setSharedFundingFactory(ISharedFundingFactory _newSFFactory)
        external;
}