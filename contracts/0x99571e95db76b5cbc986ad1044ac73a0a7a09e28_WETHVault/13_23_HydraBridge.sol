// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IVault.sol";
import "./HydraAccessControl.sol";

contract HydraBridge is Pausable, HydraAccessControl {
    enum ProposalStatus {
        Inactive,
        Active,
        Confirmed,
        Completed,
        Cancelled
    }

    bytes32 public constant FEE_ADMIN = keccak256("FEE_ADMIN");
    bytes32 public constant OBSERVER_ROLE = keccak256("OBSERVER_ROLE");
    bytes32 public constant DEFENDER = keccak256("DEFENDER");

    uint256 public constant MAX_OBSERVERS = 128;
    uint256 public constant DELAY_LIMIT = 3 * 5400;

    uint256 public feeAmount;
    uint8 public chainId;
    uint8 public votesTreshold;
    uint256 public delayInBlocks;

    struct Proposal {
        uint256 votes;
        uint256 delayUntilBlock;
        uint256 proposedInBlock;
        uint128 hasVotedBitMap;
        ProposalStatus status;
    }

    // destination chain id => number of locks
    mapping(uint8 => uint64) public depositCount;

    // asset id => vault contract address
    mapping(bytes32 => address) public assetIdToVault;

    // destination chain id + lock nonce => data => Proposal
    mapping(uint72 => mapping(bytes32 => Proposal)) private proposals;

    event VotesTresholdChanged(uint256 newThreshold);
    event ObserverAdded(address observer);
    event ObserverRemoved(address observer);
    event Deposit(uint8 destinationChainId, bytes32 assetId, uint64 depositCount);
    event Voted(uint8 originChainId, uint64 depositCount, ProposalStatus status, bytes32 dataHash);
    event StatusChanged(uint8 originChainId, uint64 depositCount, ProposalStatus status, bytes32 dataHash);

    constructor(
        uint8 _chainID,
        uint8 _votesTreshold,
        uint256 _feeAmount,
        uint256 _delayInBlocks,
        address _feeAdmin,
        address _admin,
        address _defender,
        address[] memory _observers
    ) {
        chainId = _chainID;
        votesTreshold = _votesTreshold;
        feeAmount = _feeAmount;
        delayInBlocks = _delayInBlocks;

        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(FEE_ADMIN, _feeAdmin);
        _setupRole(DEFENDER, _defender);

        uint256 observersCount = _observers.length;
        for (uint256 i; i < observersCount; i++) {
            grantRole(OBSERVER_ROLE, _observers[i]);
        }
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "HydraBridge: Only Admin Role");
        _;
    }

    modifier onlyObservers() {
        require(hasRole(OBSERVER_ROLE, msg.sender), "HydraBridge: Only Observer Role");
        _;
    }

    modifier onlyFeeAdmin() {
        require(hasRole(FEE_ADMIN, msg.sender), "HydraBridge: Only Fee Admin Role");
        _;
    }

    modifier onlyDefender() {
        require(hasRole(DEFENDER, msg.sender), "HydraBridge: Only Defender Role");
        _;
    }

    function hasVotedOnProposal(
        uint72 _destinationChainIdAndNonce,
        bytes32 _dataHash,
        address _observer
    ) public view returns (bool) {
        return hasVoted(proposals[_destinationChainIdAndNonce][_dataHash], _observer);
    }

    function isObserver(address _observer) external view returns (bool) {
        return hasRole(OBSERVER_ROLE, _observer);
    }

    function getProposal(
        uint8 _originChainId,
        uint64 _depositCount,
        bytes32 _dataHash
    ) external view returns (Proposal memory) {
        uint72 key = (uint72(_depositCount) << 8) | uint72(_originChainId);
        return proposals[key][_dataHash];
    }

    function totalObservers() public view returns (uint256) {
        return getRoleMemberCount(OBSERVER_ROLE);
    }

    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }

    function setFee(uint256 _feeAmount) external onlyFeeAdmin {
        require(_feeAmount < 5e17, "fee must be less than 0.5 eth");
        feeAmount = _feeAmount;
    }

    function setDelay(uint256 _delayInBlocks) external onlyAdmin {
        require(_delayInBlocks <= DELAY_LIMIT, "delay must be less than 3 days");
        delayInBlocks = _delayInBlocks;
    }

    function changeVoteTreshold(uint8 _votesTreshold) external onlyAdmin {
        votesTreshold = _votesTreshold;
        emit VotesTresholdChanged(_votesTreshold);
    }

    function addObserver(address _observer) external onlyAdmin {
        require(!hasRole(OBSERVER_ROLE, _observer), "HydraBridge: user is already an observer");
        require(totalObservers() < MAX_OBSERVERS, "HydraBridge: max observers reached");
        grantRole(OBSERVER_ROLE, _observer);
        emit ObserverAdded(_observer);
    }

    function removeObserver(address _observer) external onlyAdmin {
        require(hasRole(OBSERVER_ROLE, _observer), "HydraBridge: user is not observer");
        revokeRole(OBSERVER_ROLE, _observer);
        emit ObserverRemoved(_observer);
    }

    function setAssetForVault(
        address _vaultAddress,
        bytes32 _assetId,
        address _tokenAddress
    ) external onlyAdmin {
        assetIdToVault[_assetId] = _vaultAddress;
        IVault vault = IVault(_vaultAddress);
        vault.setAsset(_assetId, _tokenAddress);
    }

    function setAssetBurnable(address handlerAddress, address tokenAddress) external onlyAdmin {
        IVault handler = IVault(handlerAddress);
        handler.setBurnable(tokenAddress);
    }

    function setAssetNotBurnable(address handlerAddress, address tokenAddress) external onlyAdmin {
        IVault handler = IVault(handlerAddress);
        handler.setNotBurnable(tokenAddress);
    }

    function deposit(
        uint8 _destinationChainId,
        bytes32 _assetId,
        bytes calldata data
    ) external payable whenNotPaused {
        uint256 _fee = feeAmount;
        require(msg.value >= _fee, "HydraBridge: fee insufficient");
        address vaultAddress = assetIdToVault[_assetId];
        require(vaultAddress != address(0), "HydraBridge: vault not found");

        uint64 nonce = ++depositCount[_destinationChainId];

        IVault vault = IVault(vaultAddress);
        vault.lock{ value: msg.value - _fee }(_assetId, _destinationChainId, nonce, msg.sender, data);

        emit Deposit(_destinationChainId, _assetId, nonce);
    }

    function vote(
        uint8 _originChainId,
        uint64 _depositCount,
        bytes32 _assetId,
        bytes32 _dataHash
    ) external onlyObservers whenNotPaused {
        uint72 nonceAndOriginChainId = (uint72(_depositCount) << 8) | uint72(_originChainId);
        Proposal memory proposal = proposals[nonceAndOriginChainId][_dataHash];

        require(assetIdToVault[_assetId] != address(0), "HydraBridge: Invalid Vault");
        require(uint256(proposal.status) <= 1, "HydraBridge: Invalid proposal status");
        require(!hasVoted(proposal, msg.sender), "HydraBridge: Observer already voted");

        // Inactive -> Active
        if (proposal.status == ProposalStatus.Inactive) {
            proposal = Proposal(0, 0, block.number, 0, ProposalStatus.Active);
            emit StatusChanged(_originChainId, _depositCount, ProposalStatus.Active, _dataHash);
        }

        proposal.hasVotedBitMap = (proposal.hasVotedBitMap | uint128(observerBit(msg.sender)));
        proposal.votes++;

        emit Voted(_originChainId, _depositCount, proposal.status, _dataHash);

        // Confirmed
        if (proposal.votes >= votesTreshold) {
            proposal.status = ProposalStatus.Confirmed;
            proposal.delayUntilBlock = block.number + delayInBlocks;
            emit StatusChanged(_originChainId, _depositCount, ProposalStatus.Confirmed, _dataHash);
        }

        proposals[nonceAndOriginChainId][_dataHash] = proposal;
    }

    function execute(
        uint8 _originChainId,
        uint64 _depositCount,
        bytes calldata _data,
        bytes32 _assetId
    ) external onlyObservers whenNotPaused {
        address vaultAddress = assetIdToVault[_assetId];
        bytes32 dataHash = keccak256(abi.encodePacked(vaultAddress, _data));
        uint72 nonceAndOriginChainId = (uint72(_depositCount) << 8) | uint72(_originChainId);

        Proposal storage proposal = proposals[nonceAndOriginChainId][dataHash];
        require(proposal.status == ProposalStatus.Confirmed, "HydraBridge: Proposal not found or not confirmed");
        require(block.number > proposal.delayUntilBlock, "HydraBridge: Proposal is in delayed state");

        proposal.status = ProposalStatus.Completed;

        IVault vault = IVault(vaultAddress);
        vault.execute(_assetId, _data);

        emit StatusChanged(_originChainId, _depositCount, ProposalStatus.Completed, dataHash);
    }

    function cancel(
        uint8 _originChainId,
        uint64 _depositCount,
        bytes32 _dataHash
    ) external onlyDefender {
        uint72 nonceAndOriginChainId = (uint72(_depositCount) << 8) | uint72(_originChainId);

        Proposal storage proposal = proposals[nonceAndOriginChainId][_dataHash];
        require(proposal.status != ProposalStatus.Cancelled, "HydraBridge: Proposal already cancelled");
        require(block.number <= proposal.delayUntilBlock, "HydraBridge: Cancellation time has expired");

        proposal.status = ProposalStatus.Cancelled;

        emit StatusChanged(_originChainId, _depositCount, ProposalStatus.Cancelled, _dataHash);
    }

    function observerBit(address _observer) private view returns (uint256) {
        return uint256(1) << (getRoleMemberIndex(OBSERVER_ROLE, _observer) - 1);
    }

    function hasVoted(Proposal memory proposal, address _observer) private view returns (bool) {
        return (observerBit(_observer) & uint256(proposal.hasVotedBitMap)) > 0;
    }

    function claimFees(address payable[] calldata addrs, uint256[] calldata amounts) external onlyFeeAdmin {
        uint256 addrCount = addrs.length;
        for (uint256 i = 0; i < addrCount; i++) {
            addrs[i].transfer(amounts[i]);
        }
    }
}