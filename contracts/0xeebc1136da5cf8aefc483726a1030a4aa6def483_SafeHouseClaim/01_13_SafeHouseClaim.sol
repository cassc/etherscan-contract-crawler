// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721UDS} from "UDS/tokens/ERC721UDS.sol";
import {OwnableUDS} from "UDS/auth/OwnableUDS.sol";
import {UUPSUpgrade} from "UDS/proxy/UUPSUpgrade.sol";
import {FxBaseRootTunnel} from "fx-contracts/base/FxBaseRootTunnel.sol";

bytes4 constant CONSECUTIVE_MINT_ERC721_SELECTOR = bytes4(keccak256("consecutiveMint(address)"));

error ExceedsLimit();
error AlreadyClaimed();
error IncorrectOwner();
error InvalidBurnAmount();

/// @title Safe House Claim
/// @author phaze (https://github.com/0xPhaze)
contract SafeHouseClaim is OwnableUDS, FxBaseRootTunnel {
    string public constant name = "Safe House Claim";
    string public constant symbol = "SAFE";

    address public immutable troupe;
    address public immutable genesis;
    uint256 public immutable claimEnd;
    uint256 public constant burnAmount = 5;
    address public constant burnAddress = 0x000000000000000000000000000000000000dEaD;

    mapping(uint256 => bool) public genesisClaimed;

    constructor(
        address genesis_,
        address troupe_,
        address checkpointManager,
        address fxRoot
    ) FxBaseRootTunnel(checkpointManager, fxRoot) {
        __Ownable_init();

        troupe = troupe_;
        genesis = genesis_;
        claimEnd = block.timestamp + 4 weeks;
    }

    /* ------------- external ------------- */

    function claim(uint256[][] calldata ids) external {
        unchecked {
            if (ids.length > 20) revert ExceedsLimit();

            for (uint256 c; c < ids.length; ++c) {
                if (ids[c].length != burnAmount) revert InvalidBurnAmount();

                for (uint256 i; i < ids[c].length; ++i) {
                    ERC721UDS(troupe).transferFrom(msg.sender, burnAddress, ids[c][i]);
                }

                _sendMessageToChild(abi.encodeWithSelector(CONSECUTIVE_MINT_ERC721_SELECTOR, msg.sender));
            }
        }
    }

    function claimGenesis(uint256[] calldata ids) external {
        unchecked {
            if (ids.length > 20) revert ExceedsLimit();

            for (uint256 i; i < ids.length; ++i) {
                if (genesisClaimed[ids[i]]) revert AlreadyClaimed();
                if (IGenesis(genesis).trueOwnerOf(ids[i]) != msg.sender) revert IncorrectOwner();

                genesisClaimed[ids[i]] = true;

                _sendMessageToChild(abi.encodeWithSelector(CONSECUTIVE_MINT_ERC721_SELECTOR, msg.sender));
            }
        }
    }

    /* ------------- owner ------------- */

    function setClaimEnd() internal onlyOwner {}

    /* ------------- overrides ------------- */

    function _authorizeTunnelController() internal override onlyOwner {}
}

interface IGenesis {
    function trueOwnerOf(uint256 id) external view returns (address);
}