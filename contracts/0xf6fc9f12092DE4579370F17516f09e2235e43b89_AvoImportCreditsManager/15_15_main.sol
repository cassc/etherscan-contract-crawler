// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IAvoFactory } from "../common/interfaces/IAvoFactory.sol";
import { IAvoWallet } from "../common/interfaces/IAvoWallet.sol";
import { IInstaList } from "../common/interfaces/IInstaList.sol";
import { InstaFlashAggregatorInterface } from "../common/interfaces/InstaFlashAggregator.sol";

/// @title    AvoImportCreditsManager
/// @notice   Handles Gas Credits for import of DeFi positions
contract AvoImportCreditsManager is Initializable, PausableUpgradeable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    struct ExecuteOperationParams {
        IAvoWallet.Action[] actions; 
        address avoSafe;
        address sender;
        uint256 protocolId;
    }

    struct ImportParams {
        address avoSafe;
        address sender;
        uint256 protocolId;
        address[] tokens;
        uint256[] amounts;
        uint256 route;
        bytes data;
        bytes instaData;
    }

    /***********************************|
    |        IMMUTABLE VARIABLES        |
    |__________________________________*/
    
    /// @notice address of the AvoFactory (proxy)
    IAvoFactory public immutable avoFactory;

    /// @notice address of the InstaFlashloanAggregator (proxy)
    InstaFlashAggregatorInterface public immutable instaFlashAggregator;

    /// @notice address of the InstaList
    IInstaList public immutable instaList;

    /***********************************|
    |           STATE VARIABLES         |
    |__________________________________*/

    /// @notice allowed connector list (1 = allowed). Configurable by owner
    mapping(address => uint256) public connectors;

    /// @notice import mark. avoSafe -> sender -> protocolId -> imported status (0 -> not imported, 1 -> in process, 2 -> imported)
    mapping(address => mapping(address => mapping(uint256 => uint8))) public imports;

    /***********************************|
    |                EVENTS             |
    |__________________________________*/

    /// @notice emitted whenever an DSA Import occurs through Import.
    event AvoImport(address indexed sender, address indexed avoSafe, uint256 indexed protocolId);

    /// @notice emitted whenever an MakerDAO vault Import occurs through Import.
    event AvoDSAImport(address indexed dsa, address indexed avoSafe, uint256 indexed protocolId, address owner);

    /// @notice emitted whenever an Import occurs through Import.
    event AvoDSAMakerImport(address indexed dsa, address indexed avoSafe, uint256 indexed vaultId, address owner);


    // Admin events
    /// @notice emitted whenever the connectors are modified by owner
    event AvoConnectorToggle(address indexed connector, bool indexed allowed);

    /***********************************|
    |                ERRORS             |
    |__________________________________*/

    /// @notice thrown when msg.sender is not authorized to access requested functionality
    error AvoImportCreditsManager__Unauthorized();

    /// @notice thrown when invalid params for a method are submitted, e.g. 0x00 address
    error AvoImportCreditsManager__InvalidParams();

    /// @notice thrown when connector is not authorized
    error AvoImportCreditsManager__UnauthorizedConnector();

    /// @notice thrown when connector is not authorized
    error AvoImportCreditsManager__ImportStatusNotValid(uint256 errorCode);

    /***********************************|
    |              MODIFIERS            |
    |__________________________________*/

    /// @notice checks if an address is not 0x000...
    modifier validAddress(address address_) {
        if (address_ == address(0)) {
            revert AvoImportCreditsManager__InvalidParams();
        }
        _;
    }

    /// @notice checks if address_ is an AvoSafe through AvoFactory
    modifier onlyAvoSafe(address address_) {
        if (avoFactory.isAvoSafe(address_) == false) {
            revert AvoImportCreditsManager__Unauthorized();
        }
        _;
    }

    /// @notice checks if address_ is an DSA through InstaList
    modifier onlyDSA(address address_) {
        if (instaList.accountID(address_) == 0) {
            revert AvoImportCreditsManager__Unauthorized();
        }
        _;
    }

    /***********************************|
    |    CONSTRUCTOR / INITIALIZERS     |
    |__________________________________*/

    constructor(address avoFactory_, address instaFlashAggregator_, address instaList_)
        validAddress(avoFactory_)
        validAddress(instaFlashAggregator_)
    {
        avoFactory = IAvoFactory(avoFactory_);
        instaFlashAggregator = InstaFlashAggregatorInterface(instaFlashAggregator_);
        instaList = IInstaList(instaList_);

        // ensure logic contract initializer is not abused by disabling initializing
        // see https://forum.openzeppelin.com/t/security-advisory-initialize-uups-implementation-contracts/15301
        // and https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializing_the_implementation_contract
        _disableInitializers();
    }

    /// @notice initializes the contract for owner_ as owner and initial connectors
    /// @param owner_           address of owner_ authorized to withdraw funds
    /// @param connectors_      addresses of initial connectors
    function initialize(
        address owner_,
        address[] calldata connectors_
    ) public initializer validAddress(owner_) {
        _transferOwnership(owner_);

        for (uint i = 0; i < connectors_.length; i++) {
            address connector_ = connectors_[i];
            connectors[connector_] = 1;
            emit AvoConnectorToggle(connector_, true);
        }
    }

    /***********************************|
    |            PUBLIC API             |
    |__________________________________*/

    /// @notice              checks if a certain address is an allowed connector
    /// @param connector_    address to check
    /// @return              true if address is allowed connector
    function isConnector(address connector_) public view returns (bool) {
        return connectors[connector_] == 1;
    }

    /// @notice Similar interface as flashloan aggregator
    /// @param tokens_ token addresses for flashloan.
    /// @param amounts_ list of amounts for the corresponding assets.
    /// @param route_ route for flashloan.
    /// @param data_ actions encoded data.
    /// @param instaData_ extra data passed.
    /// @param protocolId_ protocol Id for import.
    function flashLoan(
        address[] calldata tokens_,
        uint256[] calldata amounts_,
        uint256 route_,
        bytes calldata data_,
        bytes calldata instaData_,
        uint256 protocolId_
    ) external onlyAvoSafe(msg.sender) whenNotPaused() {
        // owner of AvoSafe
        address owner_ = IAvoWallet(msg.sender).owner();

       _import(ImportParams(
            msg.sender,
            owner_,
            protocolId_,
            tokens_,
            amounts_,
            route_,
            data_,
            instaData_
        ));

        // emit event
        emit AvoImport(owner_, msg.sender, protocolId_);
    }

    function dsaImport(
        address[] calldata tokens_,
        uint256[] calldata amounts_,
        uint256 route_,
        bytes calldata data_,
        bytes calldata instaData_,
        address dsa_,
        uint256 protocolId_
    ) external onlyAvoSafe(msg.sender) onlyDSA(dsa_) whenNotPaused() {
        _import(ImportParams(
            msg.sender,
            dsa_,
            protocolId_,
            tokens_,
            amounts_,
            route_,
            data_,
            instaData_
        ));

        // emit event
        emit AvoDSAImport(dsa_, msg.sender, protocolId_, IAvoWallet(msg.sender).owner());
    }

    function dsaMakerImport(uint256 vaultId_, address avoSafe_, address auth_) external onlyDSA(msg.sender) whenNotPaused() {
        // verify import is allowed for the avocado
        uint256 protocolId_ = vaultId_ + 1000;
        if (imports[avoSafe_][msg.sender][protocolId_] != 0) {
            // revert AvoImportCreditsManager__ImportStatusNotValid(0);
        }
        imports[avoSafe_][msg.sender][protocolId_] == 1;
        emit AvoDSAMakerImport(msg.sender, avoSafe_, vaultId_, auth_);
    }

    /// @notice Executes an operation after receiving the flash-borrowed assets
    /// @param tokens_ The addresses of the flash-borrowed assets
    /// @param amounts_ The amounts of the flash-borrowed assets
    /// @param initiator_ The address of the flashloan initiator
    /// @param data_ The byte-encoded params passed when initiating the flashloan
    /// @return True if the execution of the operation succeeds, false otherwise
    function executeOperation(
        address[] calldata tokens_,
        uint256[] calldata amounts_,
        uint256[] calldata, /*  premiums_ */
        address initiator_,
        bytes calldata data_
    ) external whenNotPaused() returns (bool) {
        // check if msg.sender is instaFlashAggregator and `initiator_` is address(this)
        if (!(msg.sender == address(instaFlashAggregator) && address(this) == initiator_)) {
            revert AvoImportCreditsManager__Unauthorized();
        }

        // decode data_ -> ExecuteOperationParams(actions_, avoSafe_, owner_, protocolId_)
        ExecuteOperationParams memory executeOperationParams_ = abi.decode(data_, (ExecuteOperationParams));

        // verify import status is `1` i.e import in process
        if (imports[executeOperationParams_.avoSafe][executeOperationParams_.sender][executeOperationParams_.protocolId] != 1) {
            // revert AvoImportCreditsManager__ImportStatusNotValid(1);
        }

        // send received flashloan tokens to avoSafe_
        uint256 arrayLength_ = tokens_.length;
        for(uint256 i; i < arrayLength_; i++) {
            IERC20(tokens_[i]).safeTransfer(executeOperationParams_.avoSafe, amounts_[i]);
        }

        // verify connectors are whitelisted
        arrayLength_ = executeOperationParams_.actions.length;
        for(uint256 i = 0; i < arrayLength_; i++) {
            if (!isConnector(executeOperationParams_.actions[i].target)) {
                revert AvoImportCreditsManager__UnauthorizedConnector();
            }
        }

        // call flashloan fallback function on avoSafe to execute import
        return IAvoWallet(executeOperationParams_.avoSafe).executeOperation(new address[](0), new uint256[](0), new uint256[](0), executeOperationParams_.avoSafe, abi.encode(executeOperationParams_.actions));
    }

    function _import(
        ImportParams memory importParams_
    ) internal {
        if (imports[importParams_.avoSafe][importParams_.sender][importParams_.protocolId] != 0) {
            // revert AvoImportCreditsManager__ImportStatusNotValid(0);
        }

        // set import status as `1` i.e in process
        imports[importParams_.avoSafe][importParams_.sender][importParams_.protocolId] = 1;

        if (importParams_.tokens.length > 0) {
            // call Flashloan aggregator
            instaFlashAggregator.flashLoan(
                importParams_.tokens,
                importParams_.amounts,
                importParams_.route,
                abi.encode(
                    ExecuteOperationParams(
                        abi.decode(importParams_.data, (IAvoWallet.Action[])),
                        importParams_.avoSafe,
                        importParams_.sender,
                        importParams_.protocolId
                    )
                ),
                importParams_.instaData)
            ;
        } else {
            // verify connectors are whitelisted
            IAvoWallet.Action[] memory actions_ = abi.decode(importParams_.data, (IAvoWallet.Action[]));
            for(uint256 i = 0; i < actions_.length; i++) {
                if (!isConnector(actions_[i].target)) {
                    revert AvoImportCreditsManager__UnauthorizedConnector();
                }
            }

            // call flashloan fallback function on avoSafe to execute import
            IAvoWallet(msg.sender).executeOperation(new address[](0), new uint256[](0), new uint256[](0), msg.sender, importParams_.data);
        }

        // set import status as `2` i.e completed
        imports[importParams_.avoSafe][importParams_.sender][importParams_.protocolId] = 2;
    }

    /***********************************|
    |            ONLY OWNER             |
    |__________________________________*/

    /// @notice                   Toggle an connector is allowed or not
    /// @param connector_         address of the connector
    /// @param allowed_           bool flag for whether address is allowed as connector or not
    function toggleConnector(address connector_, bool allowed_) public onlyOwner validAddress(connector_) {
        connectors[connector_] = allowed_ ? 1 : 0;
        emit AvoConnectorToggle(connector_, allowed_);
    }

    /// @notice unpause imports
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice pause imports
    function pause() external onlyOwner {
        _pause();
    }
}