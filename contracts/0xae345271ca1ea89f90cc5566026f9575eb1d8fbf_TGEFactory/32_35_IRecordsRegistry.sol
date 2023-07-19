// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IRecordsRegistry {
    /**
     * @notice In the section of the Registry contract that contains records of the type of deployed user contract, the following numeric encoding of contract types is used.
     * @dev TGE is both a type of user contract and an event for which the contract was deployed.
     **/
    enum ContractType {
        None,
        Pool,
        GovernanceToken,
        PreferenceToken,
        TGE
    }
    /**
     * @notice Encoding of the registered event type
     */
    enum EventType {
        None,
        Transfer,
        TGE,
        GovernanceSettings
    }

    /**
     * @notice This structure is used for contracts storing in the CompanyDAO ecosystem.
     * @dev The Registry contract stores data about deployed user contracts in `ContractInfo[] public contractRecords`, where records receive a sequential and pool-independent numbering.
     * @param addr Deployed contract address
     * @param contractType Digital code of contract type
     * @param description Contract description
     */
    struct ContractInfo {
        address addr;
        ContractType contractType;
        string description;
    }

    /**
     * @notice Using this data, you can refer to the contract of a specific pool to get more detailed information about the proposal.
     * @dev The Registry contract stores data about proposals launched by users in `ProposalInfo[] public proposalRecords`, where records receive a sequential and pool-independent numbering.
     * @param pool Pool contract in which the proposal was launched
     * @param proposalId Internal proposal identifier for the pool
     * @param description Proposal description
     */
    struct ProposalInfo {
        address pool;
        uint256 proposalId;
        string description;
    }

    /**
     * @dev The Registry contract stores data about all events that have taken place in `Event[] public events`, where records receive a sequential and pool-independent numbering.
     * @param eventType Code of event type
     * @param pool Address of the pool to which this event relates
     * @param eventContract Address of the event contract, if the event type implies the deployment of a separate contract
     * @param proposalId Internal proposal identifier for the pool, the execution of which led to the launch of this event
     * @param metaHash Hash identifier of the private description stored on the backend
     */
    struct Event {
        EventType eventType;
        address pool;
        address eventContract;
        uint256 proposalId;
        string metaHash;
    }

    function addContractRecord(
        address addr,
        ContractType contractType,
        string memory description
    ) external returns (uint256 index);

    function addProposalRecord(
        address pool,
        uint256 proposalId
    ) external returns (uint256 index);

    function addEventRecord(
        address pool,
        EventType eventType,
        address eventContract,
        uint256 proposalId,
        string calldata metaHash
    ) external returns (uint256 index);

    function typeOf(address addr) external view returns (ContractType);
}