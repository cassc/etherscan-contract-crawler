// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IChangeDaoNFTFactory.sol";

/**
 * @title ChangeDaoNFTFactory
 * @author ChangeDao
 * @notice Generates ChangeDaoNFT clone
 * @dev ChangeDao admin is the owner
 */

contract ChangeDaoNFTFactory is IChangeDaoNFTFactory, Ownable {
    /* ============== State Variables ============== */

    IController public override controller;
    IChangeDaoNFT public override changeDaoNFTImplementation;

    /* ============== Constructor ============== */

    /**
     * @param _changeDaoNFTImplementation Sets changeDaoNFTImplementation address
     */
    constructor(IChangeDaoNFT _changeDaoNFTImplementation) {
        changeDaoNFTImplementation = _changeDaoNFTImplementation;
    }

    /* ============== Factory Function ============== */

    /**
     * @notice Creates a ChangeDaoNFT clone with metadata (_movementName, _projectName, _creators).
     * @dev Must be called by the controller contract
     * @param _changeMaker Address of the changeMaker that is making the project
     * @param _movementName Movement with which the project is associated
     * @param _projectName Project name
     * @param _creators Array of addresses associated with the creation of the project
     * @param _baseURI Base URI
     */
    function createChangeDaoNFT(
        address _changeMaker,
        string memory _movementName,
        string memory _projectName,
        address[] calldata _creators,
        string memory _baseURI
    ) external override returns (IChangeDaoNFT) {
        require(
            _msgSender() == address(controller),
            "NFTF: _msgSender is not controller contract"
        );
        require(
            bytes(_movementName).length != 0,
            "NFTF: Movement name is empty"
        );
        require(bytes(_projectName).length != 0, "NFTF: Project name is empty");
        require(_creators.length > 0, "NFTF: Must be at least one creator");

        address changeDaoNFTClone = Clones.clone(
            address(changeDaoNFTImplementation)
        );
        IChangeDaoNFT(changeDaoNFTClone).initialize(
            _changeMaker,
            changeDaoNFTImplementation,
            _movementName,
            _projectName,
            _creators,
            _baseURI
        );

        emit ChangeDaoNFTCloneCreated(
            IChangeDaoNFT(changeDaoNFTClone),
            _changeMaker
        );
        return IChangeDaoNFT(changeDaoNFTClone);
    }

    /* ============== Setter Functions ============== */

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

    /**
     * @notice Sets the ChangeDaoNFT implementation contract
     * @param _newCDNFTImplementation CDNFTImplementation address
     */
    function setChangeDaoNFTImplementation(
        IChangeDaoNFT _newCDNFTImplementation
    ) external override onlyOwner {
        changeDaoNFTImplementation = _newCDNFTImplementation;
    }
}