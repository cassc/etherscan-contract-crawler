// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity =0.8.19;

import { IAzorius } from "./interfaces/IAzorius.sol";
import { IBaseStrategy } from "./interfaces/IBaseStrategy.sol";
import { FactoryFriendly } from "@gnosis.pm/zodiac/contracts/factory/FactoryFriendly.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * The base abstract contract for all voting strategies in Azorius.
 */
abstract contract BaseStrategy is OwnableUpgradeable, FactoryFriendly, IBaseStrategy {

    event AzoriusSet(address indexed azoriusModule);
    event StrategySetUp(address indexed azoriusModule, address indexed owner);

    error OnlyAzorius();

    IAzorius public azoriusModule;

    /**
     * Ensures that only the [Azorius](./Azorius.md) contract that pertains to this 
     * [BaseStrategy](./BaseStrategy.md) can call functions on it.
     */
    modifier onlyAzorius() {
        if (msg.sender != address(azoriusModule)) revert OnlyAzorius();
        _;
    }

    constructor() {
      _disableInitializers();
    }

    /** @inheritdoc IBaseStrategy*/
    function setAzorius(address _azoriusModule) external onlyOwner {
        azoriusModule = IAzorius(_azoriusModule);
        emit AzoriusSet(_azoriusModule);
    }

    /** @inheritdoc IBaseStrategy*/
    function initializeProposal(bytes memory _data) external virtual;

    /** @inheritdoc IBaseStrategy*/
    function isPassed(uint32 _proposalId) external view virtual returns (bool);

    /** @inheritdoc IBaseStrategy*/
    function isProposer(address _address) external view virtual returns (bool);

    /** @inheritdoc IBaseStrategy*/
    function votingEndBlock(uint32 _proposalId) external view virtual returns (uint32);

    /**
     * Sets the address of the [Azorius](Azorius.md) module contract.
     *
     * @param _azoriusModule address of the Azorius module
     */
    function _setAzorius(address _azoriusModule) internal {
        azoriusModule = IAzorius(_azoriusModule);
        emit AzoriusSet(_azoriusModule);
    }
}