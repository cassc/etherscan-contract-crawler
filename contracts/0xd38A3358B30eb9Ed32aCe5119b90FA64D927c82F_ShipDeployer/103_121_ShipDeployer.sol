// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {GnosisSafeProxyFactory, GnosisSafeProxy} from "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";
import {ModuleProxyFactory} from "@gnosis.pm/zodiac/contracts/factory/ModuleProxyFactory.sol";
import {GnosisSafe, ModuleManager} from "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
import {ShipModule, ShipSetupArgs} from "szns/zodiac/modules/ShipModule.sol";
import {CaptainPassNFT} from "szns/CaptainPassNFT.sol";
import {IDeployerEvents} from "szns/interfaces/IDeployerEvents.sol";
import {IDeployerActions, SetupReturnVars, SetupVars} from "szns/interfaces/IDeployerActions.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ShipDeployer
 * @dev Contract used to deploy new safes
 * @author Szns
 * @notice The contract is used to deploy new safes
 */
contract ShipDeployer is IDeployerEvents, IDeployerActions, Ownable {
    /**
     * @notice Thrown when min raise is less than or equal to zero
     */
    error MinRaiseLteZero();

    /**
     * @notice Thrown when raise duration is in the past
     */
    error RaiseDurationInPast();

    /**
     * @notice Thrown when nfts allowed is empty
     */
    error NFTAllowedEmpty();

    /**
     * @notice Thrown when the msg.sender is not allowed
     */
    error NotAllowedError();

    /**
     * @notice Thrown when allow list is disabled
     */
    error AllowListDisabled();

    /**
     * @notice Thrown when the address is zero
     */
    error ZeroAddressShipDeployer();

    /**
     * @notice Event fired when an address is set to allowed
     * @param addr address that was set
     * @param allowed boolean value of allowed status
     */
    event SetAllowed(address addr, bool allowed);

    /**
     * @notice Event fired when the bypass check is set
     * @param bypassCheck boolean value of bypass check status
     */
    event SetBypassCheck(bool bypassCheck);

    /**
     * @dev Used to deploy new safes
     */
    GnosisSafeProxyFactory public immutable GNOSIS_SAFE_PROXY_FACTORY;
    ModuleProxyFactory public immutable GNOSIS_SAFE_MODULE_PROXY_FACTORY;

    /**
     * @dev Addresses of Gnosis Safe contracts
     */
    address public immutable GNOSIS_SAFE_TEMPLATE_ADDRESS;
    address public immutable GNOSIS_SAFE_FALLBACK_HANDLER;
    address public immutable SZNS_DAO;
    address public immutable SHIP_MODULE_TEMPLATE;

    address public immutable CAPTAIN_PASS_NFT;
    uint256 public constant TOKENS_PER_ETH = 1000;

    uint256 public SZNS_DAO_FEE_RATE = 1e18; // 1%
    bool public bypassCheck;

    constructor(
        address _sznsDao,
        address _captainPassNFT,
        address _gnosisSafeProxyFactory,
        address _gnosisSafeTemplate,
        address _gnosisSafeFallbackHandler,
        address _gnosisSafeModuleProxyFactory,
        address _shipModuleTemplate
    ) {
        if (
            _sznsDao == address(0) ||
            _captainPassNFT == address(0) ||
            _gnosisSafeTemplate == address(0) ||
            _gnosisSafeFallbackHandler == address(0) ||
            _shipModuleTemplate == address(0) ||
            _gnosisSafeModuleProxyFactory == address(0) ||
            _gnosisSafeProxyFactory == address(0)
        ) {
            revert ZeroAddressShipDeployer();
        }

        SZNS_DAO = _sznsDao;
        CAPTAIN_PASS_NFT = _captainPassNFT;
        GNOSIS_SAFE_PROXY_FACTORY = GnosisSafeProxyFactory(
            _gnosisSafeProxyFactory
        );
        GNOSIS_SAFE_TEMPLATE_ADDRESS = _gnosisSafeTemplate;
        GNOSIS_SAFE_FALLBACK_HANDLER = _gnosisSafeFallbackHandler;

        GNOSIS_SAFE_MODULE_PROXY_FACTORY = ModuleProxyFactory(
            _gnosisSafeModuleProxyFactory
        );

        SHIP_MODULE_TEMPLATE = _shipModuleTemplate;
    }

    /**
     * @dev Create and set up a new ship.
     * @param s SetupVars containing all the parameters for the ship
     * @return rv containing the address of the new ship and the ship module
     * @notice throws NotAllowedError if msg.sender is not allowed to create new ships
     * @notice throws MinRaiseLteZero if s.minRaise is less than or equal to 0
     * @notice throws RaiseDurationInPast if s.endDuration is less than or equal to block.timestamp
     * @notice throws NFTAllowedEmpty if s.nftsAllowed is an empty array
     */
    function createAndSetup(
        SetupVars calldata s
    ) external returns (SetupReturnVars memory rv) {
        if (!getIsAllowed(msg.sender)) {
            revert NotAllowedError();
        }
        // Check params
        if (s.minRaise <= 0) {
            revert MinRaiseLteZero();
        }
        if (s.endDuration <= block.timestamp) {
            revert RaiseDurationInPast();
        }
        if (s.nftsAllowed.length == 0) {
            revert NFTAllowedEmpty();
        }

        // Create and deploy safe
        rv.safeAddress = address(
            GNOSIS_SAFE_PROXY_FACTORY.createProxyWithNonce(
                GNOSIS_SAFE_TEMPLATE_ADDRESS,
                "",
                uint256(
                    keccak256(abi.encode(s.name, msg.sender, address(this)))
                )
            )
        );

        ShipSetupArgs memory setupArgs = ShipSetupArgs({
            name: s.name,
            symbol: s.symbol,
            endDuration: s.endDuration,
            tokensPerEth: TOKENS_PER_ETH,
            minRaise: s.minRaise,
            captainFeeRate: s.captainFeeRate,
            sznsDAOFeeRate: SZNS_DAO_FEE_RATE,
            captain: s.captain,
            nfts: s.nftsAllowed
        });

        // Deploy modifier for the ship
        rv.shipModuleAddress = GNOSIS_SAFE_MODULE_PROXY_FACTORY.deployModule(
            SHIP_MODULE_TEMPLATE,
            abi.encodeWithSignature(
                "setUp(bytes)",
                abi.encode(rv.safeAddress, rv.safeAddress, setupArgs)
            ),
            0 // salt
        );

        // initialze safe and add buy module
        address[] memory owners = new address[](1);
        owners[0] = 0x000000000000000000000000000000000000dEaD;

        GnosisSafe(payable(rv.safeAddress)).setup(
            owners, // owners
            1, // threshold
            address(this), // to
            abi.encodeCall(this.initSafe, (rv.shipModuleAddress)), // data
            GNOSIS_SAFE_FALLBACK_HANDLER, // fallbackHandler
            address(0), // paymentToken
            0, // payment
            payable(0) // paymentReceiver
        );

        emit NewShipCreated(
            block.timestamp,
            s.captain,
            s.nftsAllowed,
            s.minRaise,
            s.name,
            s.symbol,
            s.endDuration,
            rv
        );
    }

    /**
     * @dev Initializes the safe by enabling the ship module
     * @param shipModule The address of the ship module to be enabled
     */
    function initSafe(address shipModule) external {
        ModuleManager(address(this)).enableModule(shipModule);
    }

    /**
     * @dev Allows anyone to interact directly with the ship deployer
     * @param _bypassCheck Boolean if true, bypasses the allow list
     * @notice emits SetAllowed(address, bool) when the allowance is set for an address.
     */
    function setBypassCheck(bool _bypassCheck) public onlyOwner {
        bypassCheck = _bypassCheck;
        emit SetBypassCheck(_bypassCheck);
    }

    /**
     * @dev Checks if an address is allowed to use the createAndSetup() function.
     * @param addr check if this address is allowed
     */
    function getIsAllowed(address addr) public view returns (bool) {
        return
            bypassCheck || CaptainPassNFT(CAPTAIN_PASS_NFT).balanceOf(addr) > 0;
    }

    /**
     * @dev Allows the owner to set the fee rate for ships
     * @param _feeRate amount the fee rate should be set to
     */
    function setDAOFeeRate(uint256 _feeRate) public onlyOwner {
        SZNS_DAO_FEE_RATE = _feeRate;
    }

}