// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721UDS} from "UDS/tokens/ERC721UDS.sol";
import {OwnableUDS} from "UDS/auth/OwnableUDS.sol";
import {UUPSUpgrade} from "UDS/proxy/UUPSUpgrade.sol";
import {FxBaseRootTunnel} from "fx-contracts/base/FxBaseRootTunnel.sol";

bytes4 constant CONSECUTIVE_MINT_ERC721_SELECTOR = bytes4(keccak256("conescutiveMint(address)"));

error ExceedsLimit();
error InvalidBurnAmount();

/// @title Safe House Claim
/// @author phaze (https://github.com/0xPhaze)
contract SafeHouseClaim is OwnableUDS, FxBaseRootTunnel {
    string public constant name = "Safe House Claim";
    string public constant symbol = "SAFE";

    address public immutable troupe;
    uint256 public constant burnAmount = 5;
    address public constant burnAddress = 0x000000000000000000000000000000000000dEaD;

    constructor(
        address troupe_,
        address checkpointManager,
        address fxRoot
    ) FxBaseRootTunnel(checkpointManager, fxRoot) {
        __Ownable_init();

        troupe = troupe_;
    }

    /* ------------- external ------------- */

    function claim(uint256[][] calldata ids) external {
        if (ids.length > 20) revert ExceedsLimit();

        for (uint256 c; c < ids.length; ++c) {
            if (ids[c].length != burnAmount) revert InvalidBurnAmount();

            for (uint256 i; i < ids[c].length; ++i) {
                ERC721UDS(troupe).transferFrom(msg.sender, burnAddress, ids[c][i]);
            }

            _sendMessageToChild(abi.encodeWithSelector(CONSECUTIVE_MINT_ERC721_SELECTOR, msg.sender));
        }
    }

    /* ------------- overrides ------------- */

    function _authorizeTunnelController() internal override onlyOwner {}
}