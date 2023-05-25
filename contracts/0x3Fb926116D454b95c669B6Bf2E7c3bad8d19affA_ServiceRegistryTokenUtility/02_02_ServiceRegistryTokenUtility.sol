// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IErrorsRegistries.sol";

// Generic token interface
interface IToken {
    /// @dev Gets the amount of tokens owned by a specified account.
    /// @param account Account address.
    /// @return Amount of tokens owned.
    function balanceOf(address account) external view returns (uint256);

    /// @dev Token allowance.
    /// @param account Account address that approves tokens.
    /// @param spender The target token spender address.
    function allowance(address account, address spender) external view returns (uint256);

    /// @dev Gets the owner of the token Id.
    /// @param tokenId Token Id.
    /// @return Token Id owner address.
    function ownerOf(uint256 tokenId) external view returns (address);
}

// Service Registry interface
interface IServiceUtility {
    /// @dev Gets the service instance from the map of services.
    /// @param serviceId Service Id.
    /// @return securityDeposit Registration activation deposit.
    /// @return multisig Service multisig address.
    /// @return configHash IPFS hashes pointing to the config metadata.
    /// @return threshold Agent instance signers threshold.
    /// @return maxNumAgentInstances Total number of agent instances.
    /// @return numAgentInstances Actual number of agent instances.
    /// @return state Service state.
    function mapServices(uint256 serviceId) external view returns (
        uint96 securityDeposit,
        address multisig,
        bytes32 configHash,
        uint32 threshold,
        uint32 maxNumAgentInstances,
        uint32 numAgentInstances,
        uint8 state
    );

    /// @dev Gets the operator address from the map of agent instance address => operator address
    function mapAgentInstanceOperators(address agentInstance) external view returns (address operator);
}

/// @dev The provided token is rejected.
/// @param token Token address.
error TokenRejected(address token);

/* This ServiceRegistryTokenUtility represents an optimistic ERC20-based version of the ServiceRegistry contract.
*  The contract serves as a means of the utility for the ServiceRegistry contract by storing ERC20-related data.
*  Considering that the service manipulation logic stays untouched as compared to the original ServiceRegistry contract,
*  and considering that each ServiceRegistryTokenUtility contract function is called in pair with the corresponding
*  ServiceRegistry contract one, the majority of the ServiceRegistry checks are not repeated in this contract.
*  For example, this contract does not track the correctness of agent Ids (since it is performed on the ServiceRegistry side),
*  or agent instance addresses (as they are recorded in the ServiceRegistry contract), and only writes ERC20 token provided
*  bonds that correspond to each agent Id.
*
*  Note that only formal verifications for the validity of provided ERC20 tokens are performed that insure the protocol
*  safety and stability. However, full checks for a specific token misbehavior are not performed. The service owner
*  bears their full responsibility to provide the correct ERC20 token that does not harm the protocol, engaged parties
*  and the DAO in general.
*
*  The following ERC20 token checks are performed:
*  - Existence of a `balanceOf()` view function;
*  - `transferFrom()` and `transfer()` functions return the expected output;
*  - The difference of `balanceOf()` before and after the transfer for the current contract instance (address(this))
*    matches the value of token amount declared in the transfer.
*/

/// @title Service Registry Token Utility - Smart contract for registering services that bond with ERC20 tokens
/// @author Aleksandr Kuperman - <[email protected]>
/// @author AL
contract ServiceRegistryTokenUtility is IErrorsRegistries {
    event OwnerUpdated(address indexed owner);
    event ManagerUpdated(address indexed manager);
    event DrainerUpdated(address indexed drainer);
    event TokenDeposit(address indexed account, address indexed token, uint256 amount);
    event TokenRefund(address indexed account, address indexed token, uint256 amount);
    event OperatorTokenSlashed(uint256 amount, address indexed operator, uint256 indexed serviceId);
    event TokenDrain(address indexed drainer, address indexed token, uint256 amount);

    // Struct for a token address and a security deposit
    struct TokenSecurityDeposit {
        // Token address
        address token;
        // Bond per agent instance, enough for 79b+ or 7e28+
        // We assume that the security deposit value will be bound by that value
        uint96 securityDeposit;
    }

    // Service Registry contract address
    address public immutable serviceRegistry;
    // Owner address
    address public owner;
    // Service Manager contract address;
    address public manager;
    // Drainer address: set by the government and is allowed to drain ETH funds accumulated in this contract
    address public drainer;
    // Reentrancy lock
    uint256 internal _locked = 1;
    // Map of service Id => address of a token and a security deposit
    mapping(uint256 => TokenSecurityDeposit) public mapServiceIdTokenDeposit;
    // Service Id and canonical agent Id => agent instance registration bond
    mapping(uint256 => uint256) public mapServiceAndAgentIdAgentBond;
    // Map of operator address and serviceId => agent instance bonding / escrow balance
    mapping(uint256 => uint256) public mapOperatorAndServiceIdOperatorBalances;
    // Map of token => slashed funds
    mapping(address => uint256) public mapSlashedFunds;

    /// @dev ServiceRegistryTokenUtility constructor.
    /// @param _serviceRegistry Service Registry contract address.
    constructor(address _serviceRegistry) {
        // Check for the zero address
        if (_serviceRegistry == address(0)) {
            revert ZeroAddress();
        }

        serviceRegistry = _serviceRegistry;
        owner = msg.sender;
    }

    /// @dev Safe token transferFrom implementation.
    /// @notice The implementation is fully copied from the audited MIT-licensed solmate code repository:
    ///         https://github.com/transmissions11/solmate/blob/v7/src/utils/SafeTransferLib.sol
    ///         The original library imports the `ERC20` abstract token contract, and thus embeds all that contract
    ///         related code that is not needed. In this version, `ERC20` is swapped with the `address` representation.
    ///         Also, the final `require` statement is modified with this contract own `revert` statement.
    /// @param token Token address.
    /// @param from Address to transfer tokens from.
    /// @param to Address to transfer tokens to.
    /// @param amount Token amount.
    function safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        bool success;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(4, from) // Append the "from" argument.
            mstore(36, to) // Append the "to" argument.
            mstore(68, amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because that's the total length of our calldata (4 + 32 * 3)
                // Counterintuitively, this call() must be positioned after the or() in the
                // surrounding and() because and() evaluates its arguments from right to left.
                call(gas(), token, 0, 0, 100, 0, 32)
            )

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }

        if (!success) {
            revert TransferFailed(token, from, to, amount);
        }
    }

    /// @dev Safe token transfer implementation.
    /// @notice The implementation is fully copied from the audited MIT-licensed solmate code repository:
    ///         https://github.com/transmissions11/solmate/blob/v7/src/utils/SafeTransferLib.sol
    ///         The original library imports the `ERC20` abstract token contract, and thus embeds all that contract
    ///         related code that is not needed. In this version, `ERC20` is swapped with the `address` representation.
    ///         Also, the final `require` statement is modified with this contract own `revert` statement.
    /// @param token Token address.
    /// @param to Address to transfer tokens to.
    /// @param amount Token amount.
    function safeTransfer(address token, address to, uint256 amount) internal {
        bool success;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(4, to) // Append the "to" argument.
            mstore(36, amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because that's the total length of our calldata (4 + 32 * 2)
                // Counterintuitively, this call() must be positioned after the or() in the
                // surrounding and() because and() evaluates its arguments from right to left.
                call(gas(), token, 0, 0, 68, 0, 32)
            )

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }

        if (!success) {
            revert TransferFailed(token, address(this), to, amount);
        }
    }

    /// @dev Changes the owner address.
    /// @param newOwner Address of a new owner.
    function changeOwner(address newOwner) external virtual {
        // Check for the ownership
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        // Check for the zero address
        if (newOwner == address(0)) {
            revert ZeroAddress();
        }

        owner = newOwner;
        emit OwnerUpdated(newOwner);
    }

    /// @dev Changes the unit manager.
    /// @param newManager Address of a new manager.
    function changeManager(address newManager) external virtual {
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        // Check for the zero address
        if (newManager == address(0)) {
            revert ZeroAddress();
        }

        manager = newManager;
        emit ManagerUpdated(newManager);
    }

    /// @dev Changes the drainer.
    /// @param newDrainer Address of a drainer.
    function changeDrainer(address newDrainer) external {
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        // Check for the zero address
        if (newDrainer == address(0)) {
            revert ZeroAddress();
        }

        drainer = newDrainer;
        emit DrainerUpdated(newDrainer);
    }

    /// @dev Creates a record with the token-related information for the specified service.
    /// @notice We assume that the token is checked for being a non-zero address and a non-ETH address representation
    ///         outside of this function. Here we optimistically check for the token to have a specific `balanceOf()`
    ///         view function. It is possible this is the attacker token that has all the required functions defined
    ///         correctly, so there is no point in checking that formality. All the required checks will be done in-place
    ///         where the possibility of misbehavior can be caught by return values of token function.
    /// @param serviceId Service Id.
    /// @param token Token address.
    /// @param agentIds Set of agent Ids.
    /// @param bonds Set of correspondent bonds.
    function createWithToken(
        uint256 serviceId,
        address token,
        uint32[] memory agentIds,
        uint256[] memory bonds
    ) external
    {
        // Check for the manager privilege for a service management
        if (manager != msg.sender) {
            revert ManagerOnly(msg.sender, manager);
        }

        // Check the provided token for the `balanceOf()` function
        bytes4 selector = bytes4(keccak256("balanceOf(address)"));
        bool success;
        bytes memory data = abi.encodeWithSelector(selector, address(0));

        if (token.code.length > 0) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                success := staticcall(
                    gas(),            // gas remaining
                    token,            // destination address
                    add(data, 32),    // input buffer (starts after the first 32 bytes in the `data` array)
                    mload(data),      // input length (loaded from the first 32 bytes in the `data` array)
                    0,                // output buffer
                    0                 // output length
                )
            }
        }
        // Check if the token check has passed
        if (!success) {
            revert TokenRejected(token);
        }

        uint256 securityDeposit;
        // Service is newly created and all the array lengths are checked by the original ServiceRegistry create() function
        for (uint256 i = 0; i < agentIds.length; ++i) {
            // Check for a non-zero bond value and skip those with zeros (possible when updating a service)
            if (bonds[i] == 0) {
                continue;
            }
            // Check for a bond limit value
            if (bonds[i] > type(uint96).max) {
                revert Overflow(bonds[i], type(uint96).max);
            }
            
            // Push a pair of key defining variables into one key. Service or agent Ids are not enough by themselves
            // As with other units, we assume that the system is not expected to support more than than 2^32-1 services
            // Need to carefully check pairings, since it's hard to find if something is incorrectly misplaced bitwise
            // serviceId occupies first 32 bits
            uint256 serviceAgent = serviceId;
            // agentId takes the second 32 bits
            serviceAgent |= uint256(agentIds[i]) << 32;
            // We follow the optimistic design where existing bonds are just overwritten without a clearing
            // bond values of agent Ids that are not going to be used in the service. This is coming from the fact
            // that all the checks are done on the original ServiceRegistry side
            mapServiceAndAgentIdAgentBond[serviceAgent] = bonds[i];
            
            // Calculating a security deposit
            if (bonds[i] > securityDeposit){
                securityDeposit = bonds[i];
            }
        }

        // Associate service Id with the provided token address
        mapServiceIdTokenDeposit[serviceId] = TokenSecurityDeposit(token, uint96(securityDeposit));
    }

    /// @dev Resets a record with token and security deposit data.
    /// @param serviceId Service Id.
    function resetServiceToken(uint256 serviceId) external {
        // Check for the manager privilege for a service management
        if (manager != msg.sender) {
            revert ManagerOnly(msg.sender, manager);
        }

        // Delete token and security deposit data
        delete mapServiceIdTokenDeposit[serviceId];
    }

    /// @dev Deposit a token security deposit for the service registration after its activation.
    /// @param serviceId Service Id.
    /// @return isTokenSecured True if the service Id is token secured, false if ETH secured otherwise.
    function activateRegistrationTokenDeposit(uint256 serviceId) external returns (bool isTokenSecured) {
        // Reentrancy guard
        if (_locked > 1) {
            revert ReentrancyGuard();
        }
        _locked = 2;

        // Check for the manager privilege for a service management
        if (manager != msg.sender) {
            revert ManagerOnly(msg.sender, manager);
        }

        // Token address and bond
        TokenSecurityDeposit memory tokenDeposit = mapServiceIdTokenDeposit[serviceId];
        address token = tokenDeposit.token;
        if (token != address(0)) {
            uint256 securityDeposit = tokenDeposit.securityDeposit;
            // Check for the allowance against this contract
            address serviceOwner = IToken(serviceRegistry).ownerOf(serviceId);

            // Get the service owner allowance to this contract in specified tokens
            uint256 allowance = IToken(token).allowance(serviceOwner, address(this));
            if (allowance < securityDeposit) {
                revert IncorrectRegistrationDepositValue(allowance, securityDeposit, serviceId);
            }
            // Set the token-secured flag for the service
            isTokenSecured = true;

            // Transfer tokens from the serviceOwner account
            uint256 balanceBefore = IToken(token).balanceOf(address(this));
            safeTransferFrom(token, serviceOwner, address(this), securityDeposit);
            uint256 balanceAfter = IToken(token).balanceOf(address(this));
            // Check the correctness of received funds
            if (balanceBefore > balanceAfter || (balanceAfter - balanceBefore) != securityDeposit) {
                // The first argument is set to zero because (balanceAfter - balanceBefore) can be negative
                // In that case there is some token manipulation happening, and the transfer is considered to be zero
                revert IncorrectRegistrationDepositValue(0, securityDeposit, serviceId);
            }
            emit TokenDeposit(serviceOwner, token, securityDeposit);
        }

        _locked = 1;
    }

    /// @dev Deposits bonded tokens from the operator during the agent instance registration.
    /// @notice This is an optimistic implementation corresponding to registering agent instances by the operator
    ///         assuming that this function is always called in pair with the original Service Registry agent instance
    ///         registration function, where all the necessary validity checks are provided.
    /// @param operator Operator address.
    /// @param serviceId Service Id.
    /// @param agentIds Set of agent Ids for corresponding agent instances opertor is registering.
    /// @return isTokenSecured True if the service Id is token secured, false if ETH secured otherwise.
    function registerAgentsTokenDeposit(
        address operator,
        uint256 serviceId,
        uint32[] memory agentIds
    ) external returns (bool isTokenSecured)
    {
        // Reentrancy guard
        if (_locked > 1) {
            revert ReentrancyGuard();
        }
        _locked = 2;

        // Check for the manager privilege for a service management
        if (manager != msg.sender) {
            revert ManagerOnly(msg.sender, manager);
        }

        // Token address
        address token = mapServiceIdTokenDeposit[serviceId].token;
        if (token != address(0)) {
            // Check for the sufficient amount of bond fee is provided
            uint256 numAgents = agentIds.length;
            uint256 totalBond = 0;
            for (uint256 i = 0; i < numAgents; ++i) {
                // Check if canonical agent Id exists in the service
                // Push a pair of key defining variables into one key. Service or agent Ids are not enough by themselves
                // serviceId occupies first 32 bits, agentId gets the next 32 bits
                uint256 serviceAgent = serviceId;
                serviceAgent |= uint256(agentIds[i]) << 32;
                uint256 bond = mapServiceAndAgentIdAgentBond[serviceAgent];
                totalBond += bond;
            }

            // Get the operator allowance to this contract in specified tokens
            uint256 allowance = IToken(token).allowance(operator, address(this));
            if (allowance < totalBond) {
                revert IncorrectAgentBondingValue(allowance, totalBond, serviceId);
            }

            // Record the total bond of the operator
            // Push a pair of key defining variables into one key. Service Id or operator are not enough by themselves
            // operator occupies first 160 bits
            uint256 operatorService = uint256(uint160(operator));
            // serviceId occupies next 32 bits
            operatorService |= serviceId << 160;
            // Update operator's bonding balance
            mapOperatorAndServiceIdOperatorBalances[operatorService] += totalBond;
            // Set the token-secured flag for the service
            isTokenSecured = true;

            // Transfer totalBond amount of tokens from the operator account
            uint256 balanceBefore = IToken(token).balanceOf(address(this));
            safeTransferFrom(token, operator, address(this), totalBond);
            uint256 balanceAfter = IToken(token).balanceOf(address(this));
            // Check the correctness of received funds
            if (balanceBefore > balanceAfter || (balanceAfter - balanceBefore) != totalBond) {
                // The first argument is set to zero because (balanceAfter - balanceBefore) can be negative
                // In that case there is some token manipulation happening, and the transfer is considered to be zero
                revert IncorrectAgentBondingValue(0, totalBond, serviceId);
            }
            emit TokenDeposit(operator, token, totalBond);
        }

        _locked = 1;
    }

    /// @dev Refunds a token security deposit to the service owner after the service termination.
    /// @param serviceId Service Id.
    /// @return securityRefund Returned token security deposit, or zero if the service is ETH-secured.
    function terminateTokenRefund(uint256 serviceId) external returns (uint256 securityRefund) {
        // Reentrancy guard
        if (_locked > 1) {
            revert ReentrancyGuard();
        }
        _locked = 2;

        // Check for the manager privilege for a service management
        if (manager != msg.sender) {
            revert ManagerOnly(msg.sender, manager);
        }

        // Token address and bond
        TokenSecurityDeposit memory tokenDeposit = mapServiceIdTokenDeposit[serviceId];
        address token = tokenDeposit.token;
        if (token != address(0)) {
            securityRefund = tokenDeposit.securityDeposit;
            // Check for the allowance against this contract
            address serviceOwner = IToken(serviceRegistry).ownerOf(serviceId);

            // Transfer tokens to the serviceOwner account
            // The transfer is not checked for correctness since it relies fully on the token implementation
            // The protocol is concerned about getting a correct amount and calling the transfer function to send it back
            safeTransfer(token, serviceOwner, securityRefund);
            emit TokenRefund(serviceOwner, token, securityRefund);
        }

        _locked = 1;
    }

    /// @dev Refunds bonded tokens to the operator during the unbond phase.
    /// @param operator Operator address.
    /// @param serviceId Service Id.
    /// @return refund Returned bonded token amount, or zero if the service is ETH-secured.
    function unbondTokenRefund(address operator, uint256 serviceId) external returns (uint256 refund) {
        // Reentrancy guard
        if (_locked > 1) {
            revert ReentrancyGuard();
        }
        _locked = 2;

        // Check for the manager privilege for a service management
        if (manager != msg.sender) {
            revert ManagerOnly(msg.sender, manager);
        }

        // Token address
        address token = mapServiceIdTokenDeposit[serviceId].token;
        if (token != address(0)) {
            // Check for the operator and unbond all its agent instances
            // Push a pair of key defining variables into one key. Service Id or operator are not enough by themselves
            // operator occupies first 160 bits
            uint256 operatorService = uint256(uint160(operator));
            // serviceId occupies next 32 bits
            operatorService |= serviceId << 160;
            // Get the total bond for agent Ids bonded by the operator corresponding to registered agent instances
            refund = mapOperatorAndServiceIdOperatorBalances[operatorService];

            // The zero refund scenario is possible if the operator was slashed for the agent instance misbehavior
            if (refund > 0) {
                // Operator's balance is essentially zero after the refund
                mapOperatorAndServiceIdOperatorBalances[operatorService] = 0;

                // Transfer tokens to the operator account
                // The transfer is not checked for correctness since it relies fully on the token implementation
                // The protocol is concerned about getting a correct amount and calling the transfer function to send it back
                safeTransfer(token, operator, refund);
                emit TokenRefund(operator, token, refund);
            }
        }

        _locked = 1;
    }

    /// @dev Slashes a specified agent instance.
    /// @param agentInstances Agent instances to slash.
    /// @param amounts Correspondent amounts to slash.
    /// @param serviceId Service Id.
    /// @return success True, if function executed successfully.
    function slash(address[] memory agentInstances, uint256[] memory amounts, uint256 serviceId) external
        returns (bool success)
    {
        // Check if the service is deployed
        (, address multisig, , , , , uint8 state) = IServiceUtility(serviceRegistry).mapServices(serviceId);
        // ServiceState.Deployed == 4 in the original ServiceRegistry contract
        if (state != 4) {
            revert WrongServiceState(uint256(state), serviceId);
        }

        // Check for the array size
        if (agentInstances.length == 0 || agentInstances.length != amounts.length) {
            revert WrongArrayLength(agentInstances.length, amounts.length);
        }

        // Only the multisig of a correspondent address can slash its agent instances
        if (msg.sender != multisig) {
            revert OnlyOwnServiceMultisig(msg.sender, multisig, serviceId);
        }

        // Token address
        address token = mapServiceIdTokenDeposit[serviceId].token;
        // This is to protect this slash function not to be called for ETH-secured services
        if (token == address(0)) {
            revert ZeroAddress();
        }

        // Loop over each agent instance
        uint256 numInstancesToSlash = agentInstances.length;
        uint256 slashedFunds;
        for (uint256 i = 0; i < numInstancesToSlash; ++i) {
            // Get the service Id from the agentInstance map
            address operator = IServiceUtility(serviceRegistry).mapAgentInstanceOperators(agentInstances[i]);
            // Push a pair of key defining variables into one key. Service Id or operator are not enough by themselves
            // operator occupies first 160 bits
            uint256 operatorService = uint256(uint160(operator));
            // serviceId occupies next 32 bits
            operatorService |= serviceId << 160;
            // Slash the balance of the operator, make sure it does not go below zero
            uint256 balance = mapOperatorAndServiceIdOperatorBalances[operatorService];
            // Skip the zero balance
            if (balance == 0) {
                continue;
            } else if (amounts[i] >= balance) {
                // We cannot add to the slashed amount more than the balance of the operator
                slashedFunds += balance;
                balance = 0;
            } else {
                // Slash the specified amount
                slashedFunds += amounts[i];
                balance -= amounts[i];
            }
            mapOperatorAndServiceIdOperatorBalances[operatorService] = balance;

            emit OperatorTokenSlashed(amounts[i], operator, serviceId);
        }
        slashedFunds += mapSlashedFunds[token];
        mapSlashedFunds[token] = slashedFunds;
        success = true;
    }

    /// @dev Drains slashed funds to the drainer address.
    /// @param token Token address.
    /// @return amount Drained amount.
    function drain(address token) external returns (uint256 amount) {
        // Reentrancy guard
        if (_locked > 1) {
            revert ReentrancyGuard();
        }
        _locked = 2;

        // Check for the drainer address
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        // Check for the zero address
        if (drainer == address(0)) {
            revert ZeroAddress();
        }

        // Drain the slashed funds
        amount = mapSlashedFunds[token];
        if (amount > 0) {
            mapSlashedFunds[token] = 0;
            // Send slashed funds to the drainer address
            safeTransfer(token, drainer, amount);
            emit TokenDrain(msg.sender, token, amount);
        }

        _locked = 1;
    }

    /// @dev Gets service token secured status.
    /// @param serviceId Service Id.
    /// @return True if the service Id is token secured.
    function isTokenSecuredService(uint256 serviceId) external view returns (bool) {
        return mapServiceIdTokenDeposit[serviceId].token != address(0);
    }

    /// @dev Gets the agent Id bond in a specified service.
    /// @param serviceId Service Id.
    /// @param serviceId Agent Id.
    /// @return bond Agent Id bond in a specified service Id.
    function getAgentBond(uint256 serviceId, uint256 agentId) external view returns (uint256 bond) {
        // serviceId occupies first 32 bits as serviceId is limited by the 2^32 - 1 value
        uint256 serviceAgent = serviceId;
        // agentId occupies next 32 bits as agentId is limited by the 2^32 - 1 value
        serviceAgent |= agentId << 32;
        bond = mapServiceAndAgentIdAgentBond[serviceAgent];
    }

    /// @dev Gets the operator's balance in a specified service.
    /// @param operator Operator address.
    /// @param serviceId Service Id.
    /// @return balance The balance of the operator.
    function getOperatorBalance(address operator, uint256 serviceId) external view returns (uint256 balance) {
        // operator occupies first 160 bits
        uint256 operatorService = uint256(uint160(operator));
        // serviceId occupies next 32 bits as serviceId is limited by the 2^32 - 1 value
        operatorService |= serviceId << 160;
        balance = mapOperatorAndServiceIdOperatorBalances[operatorService];
    }
}