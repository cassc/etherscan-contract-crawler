// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import { VaultStorage } from "../../protocol/tokenization/VaultStorage.sol";
import { Modifiers } from "../../protocol/earn-protocol-configuration/contracts/Modifiers.sol";
import { VersionedInitializable } from "../../dependencies/openzeppelin/VersionedInitializable.sol";
import { TestStorage } from "../../protocol/earn-protocol-configuration/contracts/mocks/contracts/TestStorage.sol";
import { IncentivisedERC20 } from "../../protocol/tokenization/IncentivisedERC20.sol";
import { IRegistry } from "../../protocol/earn-protocol-configuration/contracts/interfaces/opty/IRegistry.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract TestVaultNewImplementation is
    VersionedInitializable,
    IncentivisedERC20,
    Modifiers,
    ReentrancyGuard,
    VaultStorage,
    TestStorage
{
    /**
     * @dev The version of the Vault business logic
     */
    uint256 public constant opTOKEN_REVISION = 0x3;

    /* solhint-disable no-empty-blocks */
    constructor(
        address _registry,
        string memory _name,
        string memory _symbol,
        string memory _riskProfile
    )
        public
        IncentivisedERC20(
            string(abi.encodePacked("op ", _name, " ", _riskProfile, " vault")),
            string(abi.encodePacked("op", _symbol, _riskProfile, "Vault"))
        )
        Modifiers(_registry)
    {}

    /**
     * @dev Initialize the vault
     * @param _registry the address of registry for helping get the protocol configuration
     */
    function initialize(address _registry) external virtual initializer {
        registryContract = IRegistry(_registry);
    }

    function isNewContract() external pure returns (bool) {
        return isNewVariable;
    }

    function getRevision() internal pure virtual override returns (uint256) {
        return opTOKEN_REVISION;
    }
}