// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Base} from "../base/Base.sol";
import {IMint} from "../interfaces/IMint.sol";
import {LibMint} from "../libraries/LibMint.sol";


contract AirdropsFacet is Base, IMint {

    function airdrop(address[] calldata receivers)
        external
    {
        for (uint256 i = 0; i < receivers.length; i++) {
            if (LibMint.minted(receivers[i])) revert AlreadyMinted();
            LibMint.setMinted(receivers[i]);
            LibMint.mint(receivers[i], s);
        }
    }
}