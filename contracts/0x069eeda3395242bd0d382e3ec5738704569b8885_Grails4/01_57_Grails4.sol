// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.15;

import {GenArt721CoreV3_Engine_Flex_PROOF} from "artblocks-contracts/GenArt721CoreV3_Engine_Flex_PROOF.sol";
import {Address} from "openzeppelin-contracts/utils/Address.sol";

import {IGenArt721CoreContractV3_Mintable} from "proof/artblocks/IGenArt721CoreContractV3_Mintable.sol";
import {ABProjectPoolSellable, ProjectPoolSellable} from "proof/presets/pool/ABProjectPoolSellable.sol";

/**
 * @notice Grails IV
 * @author David Huber (@cxkoda)
 * @custom:reviewer Arran Schlosberg (@divergencearran)
 * @custom:reviewer Josh Laird (@jbmlaird)
 */
contract Grails4 is ABProjectPoolSellable {
    using Address for address payable;

    // =================================================================================================================
    //                          Storage
    // =================================================================================================================

    address payable public primaryReceiver;

    // =================================================================================================================
    //                          Construction
    // =================================================================================================================

    constructor(
        ProjectPoolSellable.Init memory init,
        GenArt721CoreV3_Engine_Flex_PROOF flex_,
        IGenArt721CoreContractV3_Mintable flexMintGateway_,
        address payable primaryReceiver_
    ) ABProjectPoolSellable(init, flex_, flexMintGateway_) {
        primaryReceiver = primaryReceiver_;
    }

    /**
     * @inheritdoc ABProjectPoolSellable
     */
    function _isLongformProject(uint128 projectId) internal view virtual override returns (bool) {
        return projectId == 0 || projectId == 5 || projectId == 9;
    }

    function isLongformProject(uint128 projectId) external view returns (bool) {
        return _isLongformProject(projectId);
    }

    /**
     * @inheritdoc ABProjectPoolSellable
     * @dev This function is tightly coupled to the implementation of `_isLongformProject`. Any changes there MUST be
     * reflected here.
     */
    function _artblocksProjectId(uint128 projectId) internal view virtual override returns (uint256) {
        assert(_isLongformProject(projectId));
        
        if (projectId == 0) {
            return 3;
        }
        if (projectId == 5) {
            return 1;
        }
        if (projectId == 9) {
            return 2;
        }

        // We can't get here because of the earlier assert, but the compiler
        // otherwise gives a warning about not returning a value. The
        // alternative of simply returning 2 above, without checking project ID,
        // is less explicit.
        assert(false);
        return 0;
    }

    function artblocksProjectId(uint128 projectId) external view returns (uint256) {
        return _artblocksProjectId(projectId);
    }

    /**
     * @inheritdoc ProjectPoolSellable
     */
    function _numProjects() internal view virtual override returns (uint128) {
        return 20;
    }

    /**
     * @notice Returns the number of projects.
     */

    function numProjects() external view returns (uint128) {
        return _numProjects();
    }

    /**
     * @inheritdoc ProjectPoolSellable
     */
    function _maxNumPerProject(uint128 projectId) internal view virtual override returns (uint64) {
        return [150, 50, 50, 50, 50, 150, 50, 50, 50, 150, 50, 150, 150, 50, 50, 50, 50, 50, 25, 50][projectId];
    }

    /**
     * @notice Returns the max number of tokens per project.
     */
    function maxNumPerProject(uint128 projectId) external view returns (uint64) {
        return _maxNumPerProject(projectId);
    }

    function _handleSale(address to, uint64 num, bytes calldata data) internal virtual override {
        super._handleSale(to, num, data);
        primaryReceiver.sendValue(msg.value);
    }

    /**
     * @notice Allows a holder to burn their token
     */
    function burn(uint256 tokenId) public {
        _burn(tokenId, true);
    }

    /**
     * @notice Set the primary receiver of funds
     */
    function setPrimaryReceiver(address payable newPrimaryReceiver) public onlyRole(DEFAULT_STEERING_ROLE) {
        primaryReceiver = newPrimaryReceiver;
    }
}