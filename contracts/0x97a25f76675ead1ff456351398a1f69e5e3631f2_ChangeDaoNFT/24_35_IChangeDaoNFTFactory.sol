// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IChangeDaoNFT.sol";
import "./IController.sol";

/**
 * @title IChangeDaoNFTFactory
 * @author ChangeDao
 */
interface IChangeDaoNFTFactory {
    /* ============== Events ============== */

    /**
     * @notice Emitted when a changeDaoNFT clone is created
     */
    event ChangeDaoNFTCloneCreated(
        IChangeDaoNFT indexed changeDaoNFTClone,
        address indexed changeMaker
    );

    /* ============== Getter Functions ============== */

    function controller() external view returns (IController);

    function changeDaoNFTImplementation() external view returns (IChangeDaoNFT);

    /* ============== Factory Function ============== */

    function createChangeDaoNFT(
        address _changeMaker,
        string memory _movementName,
        string memory _projectName,
        address[] memory _creators,
        string memory _baseURI
    ) external returns (IChangeDaoNFT);

    /* ============== Setter Functions ============== */

    function setController(IController _controller) external;

    function setChangeDaoNFTImplementation(
        IChangeDaoNFT _newCDNFTImplementation
    ) external;
}