// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/*
 * @title Prime [PRIME] ERC20 Token
 * @notice PRIME is a core ERC20 token created by the Echelon Prime Foundation.
 *         PRIME powers the Echelon ecosystem's network of PlayFi games, governance protocols, and more.
 * @author Echelon Prime Foundation
 *
 * @dev Token Summary:
 *      - Symbol: PRIME
 *      - Name: Prime
 *      - Decimals: 18
 *      - Token supply: 111,111,111.111 PRIME
 *      - Burnable: total supply may decrease
 *      - Not mintable
 */

/*
 * @dev InvokeEchelonHandler: Another type of contract in the Echelon ecosystem that will be deployed after PRIME.
 *      Different InvokeEchelonHandler's will be deployed over time to facilitate expanding PRIME use cases.
 *      InvokeEchelonHandler.handleInvokeEchelon is called at the end of the invokeEchelon function (see below).
 *      handleInvokeEchelon enables additional functionality to execute after the movement of PRIME and/or ETH.
 *      A very similar concept is utilized in EchelonCache(1155) to enable Core Pack NFT holders to send NFTs + ETH
 *      and receive a different set of NFTs back, all within a single transaction (no approve necessary).
 * @param _from - The address of the caller of invokeEchelon
 * @param _ethDestination - The address to which ETH was collected to before calling handleInvokeEchelon
 * @param _primeDestination - The address to which PRIME was collected to before calling handleInvokeEchelon
 * @param _id - An id passed by the caller to represent any arbitrary and potentially off-chain event id
 * @param _ethValue - The amount of ETH that was sent to the invokeEchelon function (and was collected to _ethDestination)
 * @param _primeValue - The amount of PRIME that was sent to the invokeEchelon function (and was collected to _primeDestination)
 * @param _data - Catch-all param allowing callers to pass additional data
 */
abstract contract InvokeEchelonHandler {
    function handleInvokeEchelon(
        address _from,
        address _ethDestination,
        address _primeDestination,
        uint256 _id,
        uint256 _ethValue,
        uint256 _primeValue,
        bytes memory _data
    ) external virtual;
}

contract PrimeToken is ERC20PresetFixedSupply, AccessControl, ReentrancyGuard {
    /**
     * @notice ERC20 Name of the token: Prime
     * @dev ERC20 function name() public view returns (string)
     * @dev Field is declared public: getter name() is created when compiled,
     *      it returns the name of the token.
     */
    string public constant NAME = "Prime";

    /**
     * @notice ERC20 Symbol of the token: PRIME
     * @dev ERC20 function symbol() public view returns (string)
     * @dev Field is declared public: getter symbol() is created when compiled,
     *      it returns the symbol of the token
     */
    string public constant SYMBOL = "PRIME";

    /**
     * @notice Total supply of the token: 111,111,111.111
     * @dev ERC20 `function totalSupply() public view returns (uint256)`
     * @dev Field is declared public: getter totalSupply() is created when compiled,
     *      it returns the amount of tokens in existence.
     */
    uint256 public constant SUPPLY = 111111111111000000000000000;

    /**
     * @notice EchelonGateway record stores the details of an InvokeEchelonHandler contract
     */
    struct EchelonGateway {
        address ethDestinationAddress;
        address primeDestinationAddress;
        InvokeEchelonHandler invokeEchelonHandler;
    }

    /**
     * @notice a record of all EchelonGateways
     */
    mapping(address => EchelonGateway) public echelonGateways;

    /**
     * @notice Addresses that can send PRIME tokens when transferability is not enabled
     */
    mapping(address => bool) public isAllowlistFrom;

    /**
     * @notice Addresses that can receive PRIME tokens when transferability is not enabled
     */
    mapping(address => bool) public isAllowlistTo;

    /**
     * @notice Constant for checking if transferring for general public is unlocked
     */
    bool public unlocked = false;

    /**
     * @dev Use ECHELON_INVOKER_CONFIGURATION_ROLE as DEFAULT_ADMIN_ROLE.
     *      Addresses with this role can set the invokeEchelonHandlerContractAddress, set the
     *      invokeEchelonDestination, and grant/revoke the ECHELON_INVOKER_CONFIGURATION_ROLE to other addresses
     */
    bytes32 public constant INVOKE_ECHELON_CONFIGURATION_ROLE =
        DEFAULT_ADMIN_ROLE;

    /**
     * @dev Governance address that will enable transferability
     *
     */
    bytes32 public constant UNLOCK_ROLE = keccak256("UNLOCK_ROLE");

    /**
     * @dev Transferability cannot be enabled before this time
     *
     */
    uint256 public _unlockTimestamp;

    /**
     * @dev Fired when a new gateway (i.e. echelon handler contract) is registered
     * @param contractAddress - The address of the newly registered invokeEchelon handler contract
     * @param ethDestinationAddress - The address to which ETH was collected
     * @param primeDestinationAddress - The address to which PRIME was collected
     */
    event EchelonGatewayRegistered(
        address indexed contractAddress,
        address indexed ethDestinationAddress,
        address indexed primeDestinationAddress
    );

    /**
     * @dev initialize a standard openzeppelin ERC20 with Fixed Supply
     *      grant deployer address ECHELON_INVOKER_CONFIGURATION_ROLE
     */
    constructor(
        address[] memory allowlistFrom,
        address[] memory allowlistTo,
        uint256 unlockTimestamp
    ) ERC20PresetFixedSupply(NAME, SYMBOL, SUPPLY, msg.sender) {
        _setupRole(INVOKE_ECHELON_CONFIGURATION_ROLE, msg.sender);
        _unlockTimestamp = unlockTimestamp;
        for (uint16 i = 0; i < allowlistFrom.length; i++) {
            isAllowlistFrom[allowlistFrom[i]] = true;
        }
        for (uint16 i = 0; i < allowlistTo.length; i++) {
            isAllowlistTo[allowlistTo[i]] = true;
        }
    }

    /**
     * @notice Allow the caller to send PRIME and/or ETH to the Echelon Ecosystem of smart contracts
     *         PRIME and ETH are collected to the destination address, handler is invoked to trigger downstream logic and events
     * @param _handlerAddress - The address of the deployed and registered InvokeEchelonHandler contract
     * @param _id - An id passed by the caller to represent any arbitrary and potentially off-chain event id
     * @param _primeValue - The amount of PRIME that was sent to the invokeEchelon function (and was collected to _destination)
     * @param _data - Catch-all param to allow the caller to pass additional data to the handler
     */
    function invokeEchelon(
        address _handlerAddress,
        uint256 _id,
        uint256 _primeValue,
        bytes memory _data
    ) public payable nonReentrant {
        require(msg.value + _primeValue > 0, "Must send ETH and/or PRIME");
        require(
            echelonGateways[_handlerAddress].primeDestinationAddress !=
                address(0),
            "No handler for given _handlerAddress"
        );

        EchelonGateway memory echelonGateway = echelonGateways[_handlerAddress];

        // send ETH to the ETH destination address if transaction includes ETH
        if (msg.value > 0) {
            (bool sent, bytes memory data) = echelonGateway
                .ethDestinationAddress
                .call{ value: msg.value }("");
            require(sent, "Failed to send ETH");
        }

        // send PRIME to the PRIME destination address if transaction includes PRIME
        if (_primeValue > 0) {
            _transfer(
                msg.sender,
                echelonGateway.primeDestinationAddress,
                _primeValue
            );
        }

        // invoke the handler function with all transaction data
        echelonGateway.invokeEchelonHandler.handleInvokeEchelon(
            msg.sender,
            echelonGateway.ethDestinationAddress,
            echelonGateway.primeDestinationAddress,
            _id,
            msg.value,
            _primeValue,
            _data
        );
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Preventing renouncing role.
     */
    function renounceRole(bytes32, address) public virtual override {
        revert("Cannot renounce role");
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     * - the caller must not be the account
     */
    function revokeRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        require(account != _msgSender(), "Cannot revoke role from self");
        _revokeRole(role, account);
    }

    /**
     * @notice Enable transferability of PRIME tokens
     */
    function executeUnlock() external onlyRole(UNLOCK_ROLE) {
        require(
            block.timestamp > _unlockTimestamp,
            "Must be after _unlockTimestamp"
        );
        unlocked = true;
    }

    /**
     * @notice Allow an address with ECHELON_INVOKER_CONFIGURATION_ROLE to add a handler contract for invokeEchelon
     * @dev additional handler contracts will be added to support new use cases, existing handler contracts can never be
     *      deleted nor replaced
     * @param _contractAddress - The address of the new invokeEchelon handler contract to be registered
     * @param _ethDestinationAddress - The address to which ETH is collected
     * @param _primeDestinationAddress - The address to which PRIME is collected
     */
    function addEchelonHandlerContract(
        address _contractAddress,
        address _ethDestinationAddress,
        address _primeDestinationAddress
    ) public onlyRole(INVOKE_ECHELON_CONFIGURATION_ROLE) {
        require(
            _ethDestinationAddress != address(0) &&
                _primeDestinationAddress != address(0),
            "Destination addresses cannot be 0x0"
        );
        require(
            echelonGateways[_contractAddress].primeDestinationAddress ==
                address(0),
            "Can't overwrite existing gateway"
        );
        echelonGateways[_contractAddress] = EchelonGateway({
            ethDestinationAddress: _ethDestinationAddress,
            primeDestinationAddress: _primeDestinationAddress,
            invokeEchelonHandler: InvokeEchelonHandler(_contractAddress)
        });
        emit EchelonGatewayRegistered(
            _contractAddress,
            _ethDestinationAddress,
            _primeDestinationAddress
        );
    }

    /**
     * @notice Toggling allowlistFrom addresses for transferring
     * @param _allowlistAddresses - Addresses to be enabled/disabled in allowlistFrom
     * @param _toggle - Toggle on or off
     */
    function toggleAllowlistFrom(
        address[] memory _allowlistAddresses,
        bool _toggle
    ) external onlyRole(INVOKE_ECHELON_CONFIGURATION_ROLE) {
        for (uint256 i = 0; i < _allowlistAddresses.length; i++) {
            isAllowlistFrom[_allowlistAddresses[i]] = _toggle;
        }
    }

    /**
     * @notice Toggling allowlistTo addresses for transferring
     * @param _allowlistAddresses - Addresses to be enabled/disabled in allowlistTo
     * @param _toggle - Toggle on or off
     */
    function toggleAllowlistTo(
        address[] memory _allowlistAddresses,
        bool _toggle
    ) external onlyRole(INVOKE_ECHELON_CONFIGURATION_ROLE) {
        for (uint256 i = 0; i < _allowlistAddresses.length; i++) {
            isAllowlistTo[_allowlistAddresses[i]] = _toggle;
        }
    }

    /**
     * @notice Only allow transfer of PRIME if transfers are enabled or sender and/or receiver are allowlisted
     * @dev Hook that is called after any transfer of tokens. This includes minting and burning.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal virtual override {
        require(
            unlocked ||
                (isAllowlistFrom[from] || isAllowlistTo[to]) ||
                (from == address(0)),
            "Transfers not currently supported"
        );
    }
}