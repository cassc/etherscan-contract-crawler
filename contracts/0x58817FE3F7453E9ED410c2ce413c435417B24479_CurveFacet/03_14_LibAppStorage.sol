// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IVaultRegistry} from "../interfaces/IVaultRegistry.sol";
import {IMigrationRegistry} from "../interfaces/IMigrationRegistry.sol";
import {HubInfo} from "./LibHub.sol";
import {MeTokenInfo} from "./LibMeToken.sol";
import {LibDiamond} from "./LibDiamond.sol";
import {LibMeta} from "./LibMeta.sol";

struct AppStorage {
    // Fees-specific
    uint256 mintFee;
    uint256 burnBuyerFee;
    uint256 burnOwnerFee;
    // Constants
    uint256 MAX_REFUND_RATIO;
    uint256 PRECISION;
    uint256 MAX_FEE;
    // MeTokenRegistry-specific
    uint256 meTokenWarmup;
    uint256 meTokenDuration;
    mapping(address => MeTokenInfo) meTokens;
    mapping(address => address) meTokenOwners;
    mapping(address => address) pendingMeTokenOwners;
    // Hub-specific
    uint256 hubWarmup;
    uint256 hubDuration;
    uint256 hubCooldown;
    uint256 hubCount;
    mapping(uint256 => HubInfo) hubs;
    // reentrancy guard
    uint256 NOT_ENTERED;
    uint256 ENTERED;
    uint256 reentrancyStatus;
    // Widely-used addresses/interfaces
    address diamond;
    address meTokenFactory;
    IVaultRegistry vaultRegistry;
    IMigrationRegistry migrationRegistry;
    // Controllers
    address diamondController;
    address trustedForwarder;
    address feesController;
    address durationsController;
    address registerController;
    address deactivateController;
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }

    function initControllers(address _firstController) internal {
        AppStorage storage s = diamondStorage();
        s.diamondController = _firstController;
        s.feesController = _firstController;
        s.durationsController = _firstController;
        s.registerController = _firstController;
        s.deactivateController = _firstController;
    }
}

contract Modifiers {
    AppStorage internal s;

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.

     * @dev Works identically to OZ's nonReentrant.
     * @dev Used to avoid state storage collision within diamond.
     */

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(
            s.reentrancyStatus != s.ENTERED,
            "ReentrancyGuard: reentrant call"
        );

        // Any calls to nonReentrant after this point will fail
        s.reentrancyStatus = s.ENTERED;
        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        s.reentrancyStatus = s.NOT_ENTERED;
    }

    modifier onlyDiamondController() {
        require(
            LibMeta.msgSender() == s.diamondController,
            "!diamondController"
        );
        _;
    }

    modifier onlyFeesController() {
        require(LibMeta.msgSender() == s.feesController, "!feesController");
        _;
    }

    modifier onlyDurationsController() {
        require(
            LibMeta.msgSender() == s.durationsController,
            "!durationsController"
        );
        _;
    }

    modifier onlyRegisterController() {
        require(
            LibMeta.msgSender() == s.registerController,
            "!registerController"
        );
        _;
    }

    modifier onlyDeactivateController() {
        require(
            LibMeta.msgSender() == s.deactivateController,
            "!deactivateController"
        );
        _;
    }
}