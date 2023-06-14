// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import { LibDiamondStorageDerivaDEX } from "../storage/LibDiamondStorageDerivaDEX.sol";
import { LibDiamondStorage } from "../diamond/LibDiamondStorage.sol";
import { IERC165 } from "./IERC165.sol";

contract OwnershipFacet {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @notice This function transfers ownership to self. This is done
     *         so that we can ensure upgrades (using diamondCut) and
     *         various other critical parameter changing scenarios
     *         can only be done via governance (a facet).
     */
    function transferOwnershipToSelf() external {
        LibDiamondStorageDerivaDEX.DiamondStorageDerivaDEX storage dsDerivaDEX =
            LibDiamondStorageDerivaDEX.diamondStorageDerivaDEX();
        require(msg.sender == dsDerivaDEX.admin, "Not authorized");
        dsDerivaDEX.admin = address(this);

        emit OwnershipTransferred(msg.sender, address(this));
    }

    /**
     * @notice This gets the admin for the diamond.
     * @return Admin address.
     */
    function getAdmin() external view returns (address) {
        LibDiamondStorageDerivaDEX.DiamondStorageDerivaDEX storage dsDerivaDEX =
            LibDiamondStorageDerivaDEX.diamondStorageDerivaDEX();
        return dsDerivaDEX.admin;
    }
}