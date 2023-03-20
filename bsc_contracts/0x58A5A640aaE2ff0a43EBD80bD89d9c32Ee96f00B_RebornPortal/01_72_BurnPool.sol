// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {IBurnPool} from "src/interfaces/IBurnPool.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {RBT} from "./RBT.sol";

contract BurnPool is IBurnPool, Ownable {
    RBT rebornToken;

    constructor(address owner_, address rebornToken_) {
        if (owner_ == address(0)) {
            revert ZeroOwnerSet();
        }

        if (rebornToken_ == address(0)) {
            revert ZeroRebornTokenSet();
        }

        _transferOwnership(owner_);
        rebornToken = RBT(rebornToken_);
    }

    function burn(uint256 amount) external override onlyOwner {
        rebornToken.burn(amount);

        emit Burn(amount);
    }
}