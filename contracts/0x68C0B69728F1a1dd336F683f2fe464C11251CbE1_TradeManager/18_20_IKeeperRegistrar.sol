// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

struct RegistrationParams {
    string name;
    bytes encryptedEmail;
    address upkeepContract;
    uint32 gasLimit;
    address adminAddress;
    bytes checkData;
    bytes offchainConfig;
    uint96 amount;
}

/**
 * @notice Contract to accept requests for upkeep registrations
 * @dev There are 2 registration workflows in this contract
 * Flow 1. auto approve OFF / manual registration - UI calls `register` function on this contract, this contract owner at a later time then manually
 *  calls `approve` to register upkeep and emit events to inform UI and others interested.
 * Flow 2. auto approve ON / real time registration - UI calls `register` function as before, which calls the `registerUpkeep` function directly on
 *  keeper registry and then emits approved event to finish the flow automatically without manual intervention.
 * The idea is to have same interface(functions,events) for UI or anyone using this contract irrespective of auto approve being enabled or not.
 * they can just listen to `RegistrationRequested` & `RegistrationApproved` events and know the status on registrations.
 */
interface IKeeperRegistrar {
    /**
     * @notice register can only be called through transferAndCall on LINK contract
     * @param name string of the upkeep to be registered
     * @param encryptedEmail email address of upkeep contact
     * @param upkeepContract address to perform upkeep on
     * @param gasLimit amount of gas to provide the target contract when performing upkeep
     * @param adminAddress address to cancel upkeep and withdraw remaining funds
     * @param checkData data passed to the contract when checking for upkeep
     * @param amount quantity of LINK upkeep is funded with (specified in Juels)
     * @param source application sending this request
     * @param sender address of the sender making the request
     */
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

    function registerUpkeep(RegistrationParams calldata requestParams) external returns (uint256);
}