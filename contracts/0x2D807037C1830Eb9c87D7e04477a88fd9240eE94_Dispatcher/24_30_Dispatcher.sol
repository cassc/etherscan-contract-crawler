// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "./interfaces/IService.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IDispatcher.sol";
import "./libraries/ExceptionsLibrary.sol";

/// @dev Protocol dispatcher (unification of Directory, Metadata, WhitelistedTokens, ProposalGateway)
contract Dispatcher is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    IDispatcher
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /// @dev Service address
    address public service;

    /**
     * @dev Contract information structure
     * @param addr Contract address
     * @param contractType Contract type
     * @param description Contract description
     */
    struct ContractInfo {
        address addr;
        ContractType contractType;
        string description;
    }

    mapping(uint256 => ContractInfo) public contractRecordAt;

    /// @dev Index of last contract record
    uint256 public lastContractRecordIndex;

    mapping(address => uint256) public indexOfContract;

    /**
     * @dev Proposal information structure
     * @param pool Pool address
     * @param proposalId Proposal ID
     * @param description Proposal description
     */
    struct ProposalInfo {
        address pool;
        uint256 proposalId;
        string description;
    }

    mapping(uint256 => ProposalInfo) public proposalRecordAt;

    /// @dev Index of last proposal record
    uint256 public lastProposalRecordIndex;

    /**
     * @dev Event information structure
     * @param eventType Event type
     * @param pool Pool address
     * @param proposalId Proposal ID
     * @param metaHash Hash value of event metadata
     */
    struct Event {
        EventType eventType;
        address pool;
        uint256 proposalId;
        string metaHash;
    }

    mapping(uint256 => Event) public events;

    /// @dev Index of last event record
    uint256 public lastEventIndex;

    /// @dev Last metadata ID
    uint256 public currentId;

    /// @dev Metadata queue
    mapping(uint256 => QueueInfo) public queueInfo;

    /**
     * @dev Token whitelist
     */
    EnumerableSetUpgradeable.AddressSet private _tokenWhitelist;

    /**
     * @dev Uniswap token swap path
     */
    mapping(address => bytes) public tokenSwapPath;

    /**
     * @dev Uniswap reverse swap path
     */
    mapping(address => bytes) public tokenSwapReversePath;

    /// @dev List of managers
    EnumerableSetUpgradeable.AddressSet private _managerWhitelist;

    // EVENTS

    /**
     * @dev Event emitted on creation of contract record
     * @param index Record index
     * @param addr Contract address
     * @param contractType Contract type
     */
    event ContractRecordAdded(
        uint256 index,
        address addr,
        ContractType contractType
    );

    /**
     * @dev Event emitted on creation of proposal record
     * @param index Record index
     * @param pool Pool address
     * @param proposalId Proposal ID
     */
    event ProposalRecordAdded(uint256 index, address pool, uint256 proposalId);

    /**
     * @dev Event emitted on creation of event
     * @param eventType Event type
     * @param pool Pool address
     * @param proposalId Proposal ID
     */
    event EventRecordAdded(EventType eventType, address pool, uint256 proposalId);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Constructor function, can only be called once
     */
    function initialize() public override initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();

        currentId = 0;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    // PUBLIC FUNCTIONS

    // Directory functions

    /**
     * @dev Add contract record
     * @param addr Contract address
     * @param contractType Contract type
     * @return index Record index
     */
    function addContractRecord(address addr, ContractType contractType, string memory description)
        external
        override
        onlyService
        returns (uint256 index)
    {
        index = ++lastContractRecordIndex;
        contractRecordAt[index] = ContractInfo({
            addr: addr,
            contractType: contractType,
            description: description
        });
        indexOfContract[addr] = index;

        emit ContractRecordAdded(index, addr, contractType);
    }

    /**
     * @dev Add proposal record
     * @param pool Pool address
     * @param proposalId Proposal ID
     * @return index Record index
     */
    function addProposalRecord(address pool, uint256 proposalId)
        external
        override
        onlyService
        returns (uint256 index)
    {
        index = ++lastProposalRecordIndex;
        proposalRecordAt[index] = ProposalInfo({
            pool: pool,
            proposalId: proposalId,
            description: ""
        });

        emit ProposalRecordAdded(index, pool, proposalId);
    }

    /**
     * @dev Add event record
     * @param pool Pool address
     * @param eventType Event type
     * @param proposalId Proposal ID
     * @param metaHash Hash value of event metadata
     * @return index Record index
     */
    function addEventRecord(
        address pool,
        EventType eventType,
        uint256 proposalId,
        string calldata metaHash
    ) external override onlyService returns (uint256 index) {
        index = ++lastEventIndex;
        events[index] = Event({
            eventType: eventType,
            pool: pool,
            proposalId: proposalId,
            metaHash: metaHash
        });

        emit EventRecordAdded(eventType, pool, proposalId);
    }

    /**
     * @dev Set Service in Dispatcher
     * @param service_ Service address
     */
    function setService(address service_) external onlyOwner {
        require(service_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);

        service = service_;
    }

    // Metadata functions

    /**
     * @dev Create metadata record
     * @param jurisdiction Jurisdiction
     * @param EIN EIN
     * @param dateOfIncorporation Date of incorporation
     * @param entityType Entity type
     * @param fee Fee for create pool
     */
    function createRecord(
        uint256 jurisdiction,
        string memory EIN,
        string memory dateOfIncorporation,
        uint256 entityType,
        uint256 fee
    ) public onlyPoolManager {
        require(
            jurisdiction > 0 && bytes(EIN).length != 0 && 
                bytes(dateOfIncorporation).length != 0 && entityType > 0,
            ExceptionsLibrary.VALUE_ZERO
        );
        bytes32 newHash = keccak256(abi.encodePacked(jurisdiction, EIN));
        uint256 lastId = ++currentId;
        for (uint256 i = 1; i < lastId; i++) {
            require(
                keccak256(abi.encodePacked(queueInfo[i].jurisdiction, queueInfo[i].EIN)) != newHash,
                ExceptionsLibrary.INVALID_EIN
            );
        }

        IPool pool = IPool(address(new BeaconProxy(IService(service).poolBeacon(), "")));
        pool.initialize(
            jurisdiction,
            EIN,
            dateOfIncorporation,
            entityType,
            lastId
        );

        queueInfo[lastId] = QueueInfo({
            jurisdiction: jurisdiction,
            EIN: EIN,
            dateOfIncorporation: dateOfIncorporation,
            entityType: entityType,
            status: Status.NotUsed,
            pool: address(pool),
            fee: fee
        });

        uint256 index = ++lastContractRecordIndex;
        contractRecordAt[index] = ContractInfo({
            addr: address(pool),
            contractType: IDispatcher.ContractType.Pool,
            description: ""
        });
        indexOfContract[address(pool)] = index;

        emit ContractRecordAdded(index, address(pool), IDispatcher.ContractType.Pool);
    }

    /**
     * @dev Lock metadata record
     * @param jurisdiction Jurisdiction
     * @param entityType Entity type
     * @return Record ID
     */
    function lockRecord(uint256 jurisdiction, uint256 entityType)
        external
        onlyService
        returns (address, uint256)
    {
        uint256 lastId = currentId;
        for (uint256 i = 1; i <= lastId; i++) {
            if (
                queueInfo[i].jurisdiction == jurisdiction &&
                queueInfo[i].entityType == entityType &&
                queueInfo[i].status == Status.NotUsed
            ) {
                queueInfo[i].status = Status.Used;
                return (queueInfo[i].pool, queueInfo[i].fee);
            }
        }
        return (address(0), 0);
    }

    /**
     * @dev Delete queue record
     * @param id Queue index
     */
    function deleteRecord(uint256 id) external onlyPoolManager {
        require(
            queueInfo[id].status == Status.NotUsed,
            ExceptionsLibrary.RECORD_IN_USE
        );

        delete queueInfo[id];
    }

    /**
     * @dev Update pool fee by metadata index
     * @param id Queue index
     * @param fee Fee to update
     */
    function updateFeeByIndex(uint256 id, uint256 fee) external onlyOwner {
        require(
            queueInfo[id].status == Status.NotUsed,
            ExceptionsLibrary.RECORD_IN_USE
        );
        queueInfo[id].fee = fee;
    }

    /**
     * @dev Update pool fee by pool contract
     * @param poolToUpdate Pool address
     * @param fee Fee to update
     */
    function updateFeeByPool(address poolToUpdate, uint256 fee) external onlyOwner {
        uint256 lastId = ++currentId;
        uint256 id = 0;
        for (uint256 i = 1; i < lastId; i++) {
            address pool = queueInfo[i].pool;
            if (queueInfo[i].status == Status.Used)
                continue;
            if (poolToUpdate == pool){
                id = i;
                break;
            }
        }
        require(id > 0, ExceptionsLibrary.NO_COMPANY);
        queueInfo[id].fee = fee;
    }

    /**
     * @dev Update pool fee by pool contract
     * @param jurisdiction company's jurisdiction
     * @param EIN company's EIN
     * @param fee Fee to update
     */
    function updateFeeByJE(address jurisdiction, string calldata EIN, uint256 fee) external onlyOwner {
        uint256 lastId = ++currentId;
        uint256 id = 0;
        bytes32 companyHash = keccak256(abi.encodePacked(jurisdiction, EIN));
        for (uint256 i = 1; i < lastId; i++) {
            bytes32 poolHash = keccak256(abi.encodePacked(queueInfo[i].jurisdiction, queueInfo[i].EIN));
            if (queueInfo[i].status == Status.Used)
                continue;
            if (companyHash == poolHash) {
                id = i;
                break;
            }
        }
        require(id > 0, ExceptionsLibrary.NO_COMPANY);
        queueInfo[id].fee = fee;
    }

    // WhitelistedTokens functions

    /**
     * @dev Add tokens to whitelist
     * @param tokens Tokens
     * @param swapPaths Token swap paths
     * @param swapReversePaths Reverse swap paths
     */
    function addTokensToWhitelist(
        address[] calldata tokens,
        bytes[] calldata swapPaths,
        bytes[] calldata swapReversePaths
    ) external onlyOwner {
        require(
            tokens.length == swapPaths.length && 
            tokens.length == swapReversePaths.length,
            ExceptionsLibrary.INVALID_VALUE
        );
        for (uint256 i = 0; i < tokens.length; i++) {
            require(
                _tokenWhitelist.add(tokens[i]),
                ExceptionsLibrary.ALREADY_WHITELISTED
            );

            tokenSwapPath[tokens[i]] = swapPaths[i];
            tokenSwapReversePath[tokens[i]] = swapReversePaths[i];
        }
    }

    /**
     * @dev Remove tokens from whitelist
     * @param tokens Tokens
     */
    function removeTokensFromWhitelist(address[] calldata tokens)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < tokens.length; i++) {
            require(
                _tokenWhitelist.remove(tokens[i]),
                ExceptionsLibrary.ALREADY_NOT_WHITELISTED
            );
        }
    }

    /**
     * @dev Add manager to whitelist
     * @param account Manager address
     */
    function addManagerToWhitelist(address account) external onlyOwner {
        require(
            _managerWhitelist.add(account),
            ExceptionsLibrary.ALREADY_WHITELISTED
        );
    }

    /**
     * @dev Remove manager from whitelist
     * @param account Manager address
     */
    function removeManagerFromWhitelist(address account) external onlyOwner {
        require(
            _managerWhitelist.remove(account),
            ExceptionsLibrary.ALREADY_NOT_WHITELISTED
        );
    }

    // PUBLIC VIEW FUNCTIONS

    // Directory functions

    /**
     * @dev Return type of contract for a given address
     * @param addr Contract index
     * @return ContractType
     */
    function typeOf(address addr)
        external
        view
        override
        returns (ContractType)
    {
        return contractRecordAt[indexOfContract[addr]].contractType;
    }

    /**
     * @dev Return global proposal ID
     * @param pool Pool address
     * @param proposalId Proposal ID
     * @return Global proposal ID
     */
    function getGlobalProposalId(address pool, uint256 proposalId)
        public
        view
        returns (uint256)
    {
        uint256 lastIndex = lastProposalRecordIndex;
        for (uint256 i = 1; i <= lastIndex; i++) {
            address poolRecord = proposalRecordAt[i].pool;
            uint256 proposalIdRecord = proposalRecordAt[i].proposalId;
            if (
                (poolRecord == pool) &&
                (proposalIdRecord == proposalId)
            ) {
                return i;
            }
        }
        return 0;
    }

    /**
     * @dev Return contract description
     * @param tge TGE address
     * @return Metadata uri
     */
    function getContractDescription(address tge) external view returns (string memory) {
        uint256 lastIndex = lastContractRecordIndex;
        for (uint256 i = 1; i <= lastIndex; i++) {
            if (tge == contractRecordAt[i].addr)
                return contractRecordAt[i].description;
        }
        return "";
    }

    // Metadata functions

    /**
     * @dev Check if pool available
     * @param jurisdiction Jurisdiction
     * @param entityType Entity type
     * @return (0, 0) if there are no available companies
     * (1, 0) if there are no available companies in current jurisdiction, but exists in other jurisdiction
     * (2, fee) if there are available companies in current jurisdiction
     */
    function poolAvailable(uint256 jurisdiction, uint256 entityType)
        external
        view
        returns (uint256, uint256)
    {
        uint256 flag = 0;
        uint256 lastId = currentId;
        for (uint256 i = 1; i <= lastId; i++) {
            uint256 idJurisdiction = queueInfo[i].jurisdiction;
            uint256 idEntityType = queueInfo[i].entityType;
            Status idStatus = queueInfo[i].status;

            if (
                (idJurisdiction != jurisdiction ||
                    idEntityType != entityType) &&
                idStatus == Status.NotUsed
            ) {
                flag = 1;
            }

            if (
                idJurisdiction == jurisdiction &&
                idEntityType == entityType &&
                idStatus == Status.NotUsed
            ) {
                return (2, queueInfo[i].fee);
            }
        }

        return (flag, 0);
    }

    function availableCompaniesCount(uint256 jurisdiction) external view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 1; i <= currentId; i++) {
            if (
                queueInfo[i].jurisdiction == jurisdiction &&
                queueInfo[i].status == Status.NotUsed
            ) {
                count += 1;
            }
        }
        return count;
    }

    function availableJurisdictions() external view returns (uint256[] memory) {
        uint256[] memory jurisdictions = new uint256[](currentId);
        uint256 lastIndex = 0;
        for (uint256 i = 1; i <= currentId; i++) {
            if (queueInfo[i].status == Status.Used)
                continue;
            uint256 jurisdiction = queueInfo[i].jurisdiction;

            for (uint256 j = 0; j < jurisdictions.length; j++) {
                if (jurisdiction == jurisdictions[j])
                    break;

                if (j + 1 == jurisdictions.length) {
                    jurisdictions[lastIndex] = jurisdiction;
                    lastIndex += 1;
                }
            }
        }

        return jurisdictions;
    }

    function allJursdictions() external view returns (uint256[] memory) {
        uint256[] memory jurisdictions = new uint256[](currentId);
        uint256 lastIndex = 0;
        for (uint256 i = 1; i <= currentId; i++) {
            uint256 jurisdiction = queueInfo[i].jurisdiction;

            for (uint256 j = 0; j < jurisdictions.length; j++) {
                if (jurisdiction == jurisdictions[j])
                    break;

                if (j + 1 == jurisdictions.length) {
                    jurisdictions[lastIndex] = jurisdiction;
                    lastIndex += 1;
                }
            }
        }

        return jurisdictions;
    }

    function existingCompanies(uint256 jurisdiction) external view returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](currentId);
        uint256 lastIndex = 0;
        for (uint256 i = 1; i <= currentId; i++) {
            if (jurisdiction == queueInfo[i].jurisdiction) {
                ids[lastIndex] = i;
                lastIndex += 1;
            }
        }

        return ids;
    }

    // WhitelistedTokens functions

    /**
     * @dev Return whitelisted tokens
     * @return Addresses of whitelisted tokens
     */
    function tokenWhitelist() external view returns (address[] memory) {
        return _tokenWhitelist.values();
    }

    /**
     * @dev Check if token is whitelisted
     * @param token Token
     * @return Is token whitelisted
     */
    function isTokenWhitelisted(address token)
        external
        view
        returns (bool)
    {
        return _tokenWhitelist.contains(token);
    }

    /**
     * @dev Return manager's whitelist status
     * @param account Manager's address
     * @return Whitelist status
     */
    function isManagerWhitelisted(address account) public view returns (bool) {
        return _managerWhitelist.contains(account);
    }

    function validateTGEInfo(
        ITGE.TGEInfo calldata info, 
        IToken.TokenType tokenType, 
        uint256 cap, 
        uint256 totalSupply
    ) public view returns (bool) {
        if (info.unitOfAccount != address(0))
            require(
                IERC20Upgradeable(info.unitOfAccount).totalSupply() > 0, 
                ExceptionsLibrary.INVALID_TOKEN
            );

        require(
            info.hardcap >= IService(service).getMinSoftCap(),
            ExceptionsLibrary.INVALID_HARDCAP
        );
        if (tokenType == IToken.TokenType.Governance) {
            uint256 remainingSupply = cap - totalSupply;
            require(
                info.hardcap <= remainingSupply,
                ExceptionsLibrary.HARDCAP_OVERFLOW_REMAINING_SUPPLY
            );
            require(
                info.hardcap +
                    IService(service).getProtocolTokenFee(
                        info.hardcap
                    ) <=
                    remainingSupply,
                ExceptionsLibrary.HARDCAP_AND_PROTOCOL_FEE_OVERFLOW_REMAINING_SUPPLY
            );
        }
        require(
            info.minPurchase >= 1000 &&
                (info.price * info.minPurchase >= 10**18 || info.price == 0),
            ExceptionsLibrary.INVALID_VALUE
        );
        return true;
    }

    function validateBallotParams(
        uint256 ballotQuorumThreshold,
        uint256 ballotDecisionThreshold,
        uint256 ballotLifespan,
        uint256[10] calldata ballotExecDelay
    ) public pure returns (bool) {
        require(
            ballotQuorumThreshold <= 10000,
            ExceptionsLibrary.INVALID_VALUE
        );
        require(
            ballotDecisionThreshold <= 10000,
            ExceptionsLibrary.INVALID_VALUE
        );
        require(ballotLifespan > 0, ExceptionsLibrary.INVALID_VALUE);

        // zero value allows FlashLoan attacks against executeBallot
        require(
            ballotExecDelay[1] > 0 && ballotExecDelay[1] < 20,
            ExceptionsLibrary.INVALID_VALUE
        );
        return true;
    }

    // MODIFIERS

    modifier onlyService() {
        require(msg.sender == service, ExceptionsLibrary.NOT_SERVICE);
        _;
    }

    modifier onlyPoolManager() {
        require(
            isManagerWhitelisted(msg.sender),
            ExceptionsLibrary.NOT_WHITELISTED
        );
        _;
    }

    // function test82312() external pure returns (uint256) {
    //     return 3;
    // }
}