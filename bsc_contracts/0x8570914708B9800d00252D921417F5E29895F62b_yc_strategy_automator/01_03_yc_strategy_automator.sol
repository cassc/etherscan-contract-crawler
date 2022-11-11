// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/*
 * Importing required Chainlink automation interfaces
 **/
import {AutomationRegistryInterface, State, Config} from "../chainlink/contracts/src/v0.8/interfaces/AutomationRegistryInterface1_2.sol";
import {LinkTokenInterface} from "../chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

/*
 * @dev a generic interface for Chainlink automation registry
 */
interface KeeperRegistrarInterface {
    function register(
        string memory name,
        bytes calldata encryptedEmail,
        address upkeepContract,
        uint32 gasLimit,
        address adminAddress,
        bytes calldata checkData,
        uint96 amount,
        uint8 source,
        address sender
    ) external;
}

contract yc_strategy_automator {
    // Linktoken interface type variable
    LinkTokenInterface public immutable i_link;

    // Address of the CL Registrar (Constructed)
    address public immutable registrar;

    // AutomationRegistryInterface type variable
    AutomationRegistryInterface public immutable i_registry;

    // Generic registrartion signature
    bytes4 registerSig = KeeperRegistrarInterface.register.selector;

    // Address of the current chain's Chainlink registry
    address public immutable registryAddress;

    /*
     * @dev Mappings to keep track of Upkeep IDs, strategy addresses, and latest call data
     **/
    mapping(uint256 => address) public upkeepIdToAddress;
    mapping(address => uint256) public strategyAddressToUpkeepId;
    mapping(uint256 => bytes) public upkeepidToLatestData;

    /*
     * @notice
     * @dev
     * In the consturctor, you need to input a Linktokeinterface type variable, an address for Chainlink registrar,
     * An automationRegistryinterface type, and an address for the CL registry on the current chain.
     * this sets up the contract, the contract is responsible for registering, keeping track of & funding
     * Yieldchain strategies, to automate them and allow easy gas funding by platform users
     **/
    constructor(
        LinkTokenInterface _link,
        address _registrar,
        AutomationRegistryInterface _registry,
        address _registryAddress
    ) {
        i_link = _link;
        registrar = _registrar;
        i_registry = _registry;
        registryAddress = _registryAddress;
    }

    /*
     * @dev
     * @notice
     * Main function for registering an Upkeep, only Yieldchain strategy contracts are supposed to call it, it
     * takes in 2 arguements:
     * 1) Name - The name of the Upkeep (The strategy's configured name, does not make a difference)
     * 2) The amount - An amount of chainlink ERC-677 tokens to initially fund the Upkeep with, must be above 5 LINK
     * It registers an Upkeep on the calling contract, the caller contract must be Chainlink Automation-compatible
     * And have the required checkUpkeep() & performUpkeep() functions implemented
     **/
    function registerAndPredictID(string memory name, uint96 amount) public {
        (State memory state, Config memory _c, address[] memory _k) = i_registry
            .getState();
        uint256 oldNonce = state.nonce;
        require(
            amount > 5000000000000000000,
            "Not enough LINK tokens funded, min 5 LINK (ERC-677)"
        );
        bytes memory payload = abi.encode(
            name,
            "[email protected]",
            msg.sender,
            999999999,
            msg.sender,
            "0x",
            amount,
            0,
            address(this)
        );

        i_link.transferAndCall(
            registrar,
            amount,
            bytes.concat(registerSig, payload)
        );
        (state, _c, _k) = i_registry.getState();
        uint256 newNonce = state.nonce;
        if (newNonce == oldNonce + 1) {
            uint256 upkeepID = uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 1),
                        address(i_registry),
                        uint32(oldNonce)
                    )
                )
            );

            /*
             * @dev
             * String details about the caller & the Upkeep ID in mappings after registration
             **/
            strategyAddressToUpkeepId[msg.sender] = upkeepID;
            upkeepIdToAddress[upkeepID] = msg.sender;
            address strategyContract = msg.sender;
            (bool success, bytes memory result) = strategyContract.call(
                abi.encodeWithSignature("setUpkeepId(uint)", upkeepID)
            );
            upkeepidToLatestData[upkeepID] = result;
            require(success, "Call failed on %s");
        } else {
            revert("auto-approve disabled");
        }
    }

    /*
     * @dev
     * This function allows users to fund the LINK gas balance of any strategy contract, the last function have set
     * The UpKeepID on the StrategyContract, so users only need to input an amount when funding.
     **/
    function fundStrategyGasBalance(
        uint256 _upkeepId,
        uint256 _amountLinkTokens
    ) public {
        (bool success, bytes memory result) = registryAddress.call(
            abi.encodeWithSignature(
                "addFunds(uint256, uint96)",
                _upkeepId,
                _amountLinkTokens
            )
        );
        require(success, "Funding gas balance failed");
        upkeepidToLatestData[_upkeepId] = result;
    }
}