// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {GenericManager} from "./GenericManager.sol";
import {OperatorSignedHashes} from "./utils/OperatorSignedHashes.sol";
import "./interfaces/IService.sol";
import "./interfaces/IServiceTokenUtility.sol";

// Operator whitelist interface
interface IOperatorWhitelist {
    /// @dev Gets operator whitelisting status.
    /// @param serviceId Service Id.
    /// @param operator Operator address.
    /// @return status Whitelisting status.
    function isOperatorWhitelisted(uint256 serviceId, address operator) external view returns (bool status);
}

// Generic token interface
interface IToken {
    /// @dev Gets the owner of the token Id.
    /// @param tokenId Token Id.
    /// @return Token Id owner address.
    function ownerOf(uint256 tokenId) external view returns (address);
}

/// @title Service Manager - Periphery smart contract for managing services with custom ERC20 tokens or ETH
/// @author Aleksandr Kuperman - <[email protected]>
/// @author AL
contract ServiceManagerToken is GenericManager, OperatorSignedHashes {
    event OperatorWhitelistUpdated(address indexed operatorWhitelist);
    event CreateMultisig(address indexed multisig);

    // Service Registry address
    address public immutable serviceRegistry;
    // Service Registry Token Utility address
    address public immutable serviceRegistryTokenUtility;
    // A well-known representation of ETH as an address
    address public constant ETH_TOKEN_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    // Bond wrapping constant
    uint96 public constant BOND_WRAPPER = 1;
    // Operator whitelist address
    address public operatorWhitelist;

    /// @dev ServiceRegistryTokenUtility constructor.
    /// @param _serviceRegistry Service Registry contract address.
    /// @param _serviceRegistryTokenUtility Service Registry Token Utility contract address.
    constructor(address _serviceRegistry, address _serviceRegistryTokenUtility, address _operatorWhitelist)
        OperatorSignedHashes("Service Manager Token", "1.1.1")
    {
        // Check for the Service Registry related contract zero addresses
        if (_serviceRegistry == address(0) || _serviceRegistryTokenUtility == address(0)) {
            revert ZeroAddress();
        }

        serviceRegistry = _serviceRegistry;
        serviceRegistryTokenUtility = _serviceRegistryTokenUtility;
        operatorWhitelist = _operatorWhitelist;
        owner = msg.sender;
    }

    /// @dev Sets the operator whitelist contract address.
    /// @param newOperatorWhitelist New operator whitelist contract address.
    function setOperatorWhitelist(address newOperatorWhitelist) external {
        // Check for the contract ownership
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        operatorWhitelist = newOperatorWhitelist;
        emit OperatorWhitelistUpdated(newOperatorWhitelist);
    }

    /// @dev Creates a new service.
    /// @param serviceOwner Individual that creates and controls a service.
    /// @param token ERC20 token address for the security deposit, or ETH.
    /// @param configHash IPFS hash pointing to the config metadata.
    /// @param agentIds Canonical agent Ids.
    /// @param agentParams Number of agent instances and required bond to register an instance in the service.
    /// @param threshold Threshold for a multisig composed by agents.
    /// @return serviceId Created service Id.
    function create(
        address serviceOwner,
        address token,
        bytes32 configHash,
        uint32[] memory agentIds,
        IService.AgentParams[] memory agentParams,
        uint32 threshold
    ) external returns (uint256 serviceId)
    {
        // Check if the minting is paused
        if (paused) {
            revert Paused();
        }

        // Check for the zero address
        if (token == address(0)) {
            revert ZeroAddress();
        }

        // Check for the custom ERC20 token or ETH based bond
        if (token == ETH_TOKEN_ADDRESS) {
            // Call the original ServiceRegistry contract function
            serviceId = IService(serviceRegistry).create(serviceOwner, configHash, agentIds, agentParams, threshold);
        } else {
            // Wrap agent params with just 1 WEI bond going to the original ServiceRegistry contract,
            // and actual token bonds being recorded with the ServiceRegistryTokenUtility contract
            uint256 numAgents = agentParams.length;
            uint256[] memory bonds = new uint256[](numAgents);
            for (uint256 i = 0; i < numAgents; ++i) {
                // Check for the zero bond value
                if (agentParams[i].bond == 0) {
                    revert ZeroValue();
                }

                // Copy actual bond values for each agent Id
                bonds[i] = agentParams[i].bond;
                // Wrap bonds with the BOND_WRAPPER value for the original ServiceRegistry contract
                agentParams[i].bond = BOND_WRAPPER;
            }

            // Call the original ServiceRegistry contract function
            serviceId = IService(serviceRegistry).create(serviceOwner, configHash, agentIds, agentParams, threshold);
            // Create a token-related record for the service
            IServiceTokenUtility(serviceRegistryTokenUtility).createWithToken(serviceId, token, agentIds, bonds);
        }
    }

    /// @dev Updates a service in a CRUD way.
    /// @param token ERC20 token address for the security deposit, or ETH.
    /// @param configHash IPFS hash pointing to the config metadata.
    /// @param agentIds Canonical agent Ids.
    /// @param agentParams Number of agent instances and required bond to register an instance in the service.
    /// @param threshold Threshold for a multisig composed by agents.
    /// @param serviceId Service Id to be updated.
    /// @return success True, if function executed successfully.
    function update(
        address token,
        bytes32 configHash,
        uint32[] memory agentIds,
        IService.AgentParams[] memory agentParams,
        uint32 threshold,
        uint256 serviceId
    ) external returns (bool success)
    {
        // Check for the zero address
        if (token == address(0)) {
            revert ZeroAddress();
        }

        uint256 numAgents = agentParams.length;
        if (token == ETH_TOKEN_ADDRESS) {
            // If any of the slots is a non-zero, the correspondent bond cannot be zero
            for (uint256 i = 0; i < numAgents; ++i) {
                // Check for the zero bond value
                if (agentParams[i].slots > 0 && agentParams[i].bond == 0) {
                        revert ZeroValue();
                }
            }
            // Call the original ServiceRegistry contract function
            success = IService(serviceRegistry).update(msg.sender, configHash, agentIds, agentParams, threshold, serviceId);
            // Reset the service token-based data
            // This function still needs to be called as the previous token could be a custom ERC20 token
            IServiceTokenUtility(serviceRegistryTokenUtility).resetServiceToken(serviceId);
        } else {
            // Wrap agent params with just 1 WEI bond going to the original ServiceRegistry contract,
            // and actual token bonds being recorded with the ServiceRegistryTokenUtility contract
            uint256[] memory bonds = new uint256[](numAgents);
            for (uint256 i = 0; i < numAgents; ++i) {
                // Copy actual bond values for each agent Id that has at least one slot in the updated service
                if (agentParams[i].slots > 0) {
                    // Check for the zero bond value
                    if (agentParams[i].bond == 0) {
                        revert ZeroValue();
                    }
                    bonds[i] = agentParams[i].bond;
                    // Wrap bonds with the BOND_WRAPPER value for the original ServiceRegistry contract
                    agentParams[i].bond = BOND_WRAPPER;
                }
            }

            // Call the original ServiceRegistry contract function
            success = IService(serviceRegistry).update(msg.sender, configHash, agentIds, agentParams, threshold, serviceId);
            // Update relevant data in the ServiceRegistryTokenUtility contract
            // We follow the optimistic design where existing bonds are just overwritten without a clearing
            // bond values of agent Ids that are not going to be used in the service. This is coming from the fact
            // that all the checks are done on the original ServiceRegistry side
            IServiceTokenUtility(serviceRegistryTokenUtility).createWithToken(serviceId, token, agentIds, bonds);
        }
    }

    /// @dev Activates the service and its sensitive components.
    /// @param serviceId Correspondent service Id.
    /// @return success True, if function executed successfully.
    function activateRegistration(uint256 serviceId) external payable returns (bool success) {
        // Record the actual ERC20 security deposit
        bool isTokenSecured = IServiceTokenUtility(serviceRegistryTokenUtility).activateRegistrationTokenDeposit(serviceId);

        // Activate registration in the original ServiceRegistry contract
        if (isTokenSecured) {
            // If the service Id is based on the ERC20 token, the provided value to the standard registration is 1
            success = IService(serviceRegistry).activateRegistration{value: BOND_WRAPPER}(msg.sender, serviceId);
        } else {
            // Otherwise follow the standard msg.value path
            success = IService(serviceRegistry).activateRegistration{value: msg.value}(msg.sender, serviceId);
        }
    }

    /// @dev Registers agent instances.
    /// @param serviceId Service Id to be updated.
    /// @param agentInstances Agent instance addresses.
    /// @param agentIds Canonical Ids of the agent correspondent to the agent instance.
    /// @return success True, if function executed successfully.
    function registerAgents(
        uint256 serviceId,
        address[] memory agentInstances,
        uint32[] memory agentIds
    ) external payable returns (bool success) {
        if (operatorWhitelist != address(0)) {
            // Check if the operator is whitelisted
            if (!IOperatorWhitelist(operatorWhitelist).isOperatorWhitelisted(serviceId, msg.sender)) {
                revert WrongOperator(serviceId);
            }
        }

        // Record the actual ERC20 bond
        bool isTokenSecured = IServiceTokenUtility(serviceRegistryTokenUtility).registerAgentsTokenDeposit(msg.sender,
            serviceId, agentIds);

        // Register agent instances in a main ServiceRegistry contract
        if (isTokenSecured) {
            // If the service Id is based on the ERC20 token, the provided value to the standard registration is 1
            // multiplied by the number of agent instances
            success = IService(serviceRegistry).registerAgents{value: agentInstances.length * BOND_WRAPPER}(msg.sender,
                serviceId, agentInstances, agentIds);
        } else {
            // Otherwise follow the standard msg.value path
            success = IService(serviceRegistry).registerAgents{value: msg.value}(msg.sender, serviceId, agentInstances, agentIds);
        }
    }

    /// @dev Creates multisig instance controlled by the set of service agent instances and deploys the service.
    /// @param serviceId Correspondent service Id.
    /// @param multisigImplementation Multisig implementation address.
    /// @param data Data payload for the multisig creation.
    /// @return multisig Address of the created multisig.
    function deploy(
        uint256 serviceId,
        address multisigImplementation,
        bytes memory data
    ) external returns (address multisig)
    {
        multisig = IService(serviceRegistry).deploy(msg.sender, serviceId, multisigImplementation, data);
        emit CreateMultisig(multisig);
    }

    /// @dev Terminates the service.
    /// @param serviceId Service Id.
    /// @return success True, if function executed successfully.
    /// @return refund Refund for the service owner.
    function terminate(uint256 serviceId) external returns (bool success, uint256 refund) {
        // Withdraw the ERC20 token if the service is token-based
        uint256 tokenRefund = IServiceTokenUtility(serviceRegistryTokenUtility).terminateTokenRefund(serviceId);

        // Terminate the service with the regular service registry routine
        (success, refund) = IService(serviceRegistry).terminate(msg.sender, serviceId);

        // If the service is token-based, the actual refund is provided via the serviceRegistryTokenUtility contract
        if (tokenRefund > 0) {
            refund = tokenRefund;
        }
    }

    /// @dev Unbonds agent instances of the operator from the service.
    /// @param serviceId Service Id.
    /// @return success True, if function executed successfully.
    /// @return refund The amount of refund returned to the operator.
    function unbond(uint256 serviceId) external returns (bool success, uint256 refund) {
        // Withdraw the ERC20 token if the service is token-based
        uint256 tokenRefund = IServiceTokenUtility(serviceRegistryTokenUtility).unbondTokenRefund(msg.sender, serviceId);

        // Unbond with the regular service registry routine
        (success, refund) = IService(serviceRegistry).unbond(msg.sender, serviceId);

        // If the service is token-based, the actual refund is provided via the serviceRegistryTokenUtility contract
        if (tokenRefund > 0) {
            refund = tokenRefund;
        }
    }

    /// @dev Unbonds agent instances of the operator by the service owner via the operator's pre-signed message hash.
    /// @notice Note that this function accounts for the operator being the EOA, or the contract that has an
    ///         isValidSignature() function that would confirm the message hash was signed by the operator contract.
    ///         Otherwise, if the message hash has been pre-approved, the corresponding map of hashes is going to
    ///         to verify the signed hash, similar to the Safe contract implementation in v1.3.0:
    ///         https://github.com/safe-global/safe-contracts/blob/186a21a74b327f17fc41217a927dea7064f74604/contracts/GnosisSafe.sol#L240-L304
    ///         Also note that only the service owner is able to call this function on behalf of the operator.
    /// @param operator Operator address that signed the unbond message hash.
    /// @param serviceId Service Id.
    /// @param signature Signature byte array associated with operator message hash signature.
    /// @return success True, if the function executed successfully.
    /// @return refund The amount of refund returned to the operator.
    function unbondWithSignature(
        address operator,
        uint256 serviceId,
        bytes memory signature
    ) external returns (bool success, uint256 refund)
    {
        // Check the service owner
        address serviceOwner = IToken(serviceRegistry).ownerOf(serviceId);
        if (msg.sender != serviceOwner) {
            revert OwnerOnly(msg.sender, serviceOwner);
        }

        // Get the (operator | serviceId) nonce for the unbond message
        // Push a pair of key defining variables into one key. Service Id or operator are not enough by themselves
        // as another service might use the operator address at the same time frame
        // operator occupies first 160 bits
        uint256 operatorService = uint256(uint160(operator));
        // serviceId occupies next 32 bits
        operatorService |= serviceId << 160;
        uint256 nonce = mapOperatorUnbondNonces[operatorService];
        // Get the unbond message hash
        bytes32 msgHash = getUnbondHash(operator, serviceOwner, serviceId, nonce);

        // Verify the signed hash against the operator address
        _verifySignedHash(operator, msgHash, signature);

        // Update corresponding nonce value
        nonce++;
        mapOperatorUnbondNonces[operatorService] = nonce;

        // Withdraw the ERC20 token if the service is token-based
        uint256 tokenRefund = IServiceTokenUtility(serviceRegistryTokenUtility).unbondTokenRefund(operator, serviceId);

        // Unbond with the regular service registry routine
        (success, refund) = IService(serviceRegistry).unbond(operator, serviceId);

        // If the service is token-based, the actual refund is provided via the serviceRegistryTokenUtility contract
        if (tokenRefund > 0) {
            refund = tokenRefund;
        }
    }

    /// @dev Registers agent instances of the operator by the service owner via the operator's pre-signed message hash.
    /// @notice Note that this function accounts for the operator being the EOA, or the contract that has an
    ///         isValidSignature() function that would confirm the message hash was signed by the operator contract.
    ///         Otherwise, if the message hash has been pre-approved, the corresponding map of hashes is going to
    ///         to verify the signed hash, similar to the Safe contract implementation in v1.3.0:
    ///         https://github.com/safe-global/safe-contracts/blob/186a21a74b327f17fc41217a927dea7064f74604/contracts/GnosisSafe.sol#L240-L304
    ///         Also note that only the service owner is able to call this function on behalf of the operator.
    /// @param operator Operator address that signed the register agents message hash.
    /// @param serviceId Service Id.
    /// @param agentInstances Agent instance addresses.
    /// @param agentIds Canonical Ids of the agent correspondent to the agent instance.
    /// @param signature Signature byte array associated with operator message hash signature.
    /// @return success True, if the the function executed successfully.
    function registerAgentsWithSignature(
        address operator,
        uint256 serviceId,
        address[] memory agentInstances,
        uint32[] memory agentIds,
        bytes memory signature
    ) external payable returns (bool success) {
        // Check the service owner
        address serviceOwner = IToken(serviceRegistry).ownerOf(serviceId);
        if (msg.sender != serviceOwner) {
            revert OwnerOnly(msg.sender, serviceOwner);
        }

        // Get the (operator | serviceId) nonce for the registerAgents message
        // Push a pair of key defining variables into one key. Service Id or operator are not enough by themselves
        // as another service might use the operator address at the same time frame
        // operator occupies first 160 bits
        uint256 operatorService = uint256(uint160(operator));
        // serviceId occupies next 32 bits as serviceId is limited by the 2^32 - 1 value
        operatorService |= serviceId << 160;
        uint256 nonce = mapOperatorRegisterAgentsNonces[operatorService];
        // Get register agents message hash
        bytes32 msgHash = getRegisterAgentsHash(operator, serviceOwner, serviceId, agentInstances, agentIds, nonce);

        // Verify the signed hash against the operator address
        _verifySignedHash(operator, msgHash, signature);

        // Update corresponding nonce value
        nonce++;
        mapOperatorRegisterAgentsNonces[operatorService] = nonce;

        // Record the actual ERC20 bond
        bool isTokenSecured = IServiceTokenUtility(serviceRegistryTokenUtility).registerAgentsTokenDeposit(operator,
            serviceId, agentIds);

        // Register agent instances in a main ServiceRegistry contract
        if (isTokenSecured) {
            // If the service Id is based on the ERC20 token, the provided value to the standard registration is 1
            // multiplied by the number of agent instances
            success = IService(serviceRegistry).registerAgents{value: agentInstances.length * BOND_WRAPPER}(operator,
                serviceId, agentInstances, agentIds);
        } else {
            // Otherwise follow the standard msg.value path
            success = IService(serviceRegistry).registerAgents{value: msg.value}(operator, serviceId, agentInstances, agentIds);
        }
    }
}