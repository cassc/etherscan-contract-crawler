// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./interfaces/IVotingWeightSource.sol";
import "./interfaces/IGovernanceRegistry.sol";
import "./interfaces/IGovernance.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Kapital DAO Vesting
 * @author Playground Labs
 * @custom:security-contact [email protected]
 * @notice Used to lock and linearly vest KAP
 */
contract KapVesting is AccessControlEnumerable, IVotingWeightSource {
    bytes32 public constant VESTING_CREATOR = keccak256("VESTING_CREATOR"); // role to call {createVestingAgreement}
    bytes32 public constant REGISTRY_SETTER = keccak256("REGISTRY_SETTER"); // role to set {governanceRegistry}

    using SafeERC20 for IERC20;
    IERC20 public immutable kapToken; // vesting asset
    IGovernanceRegistry public governanceRegistry; // used to query the latest governance address

    struct VestingAgreement {
        uint64 vestStart; // timestamp at which vesting starts, acts as a vesting delay
        uint64 vestPeriod; // time period over which vesting occurs
        uint96 totalAmount; // total KAP amount to which the beneficiary is promised
        uint96 amountCollected; // portion of `totalAmount` which has already been collected
    }

    event CreateVestingAgreement(
        address indexed beneficiary, 
        uint256 vestStart, 
        uint256 vestPeriod, 
        uint256 amount
    );
    event Collect(address indexed beneficiary, uint256 vestingAgreementId);
    event AppointDelegate(address indexed beneficiary, address newDelegate);
    event Undelegate(address indexed beneficiary);

    mapping(address => VestingAgreement[]) public vestingAgreements;
    mapping(address => uint256) public balances; // uncollected vesting balances
    mapping(address => address) public delegates; // governance voting delegates
    mapping(address => uint256) public votingWeight; // track voting weights based on delegate choice
    mapping(address => uint256) public lastUndelegated; // timestamp of last {undelegate} call

    constructor(
        address _teamMultisig,
        address _foundationMultisig,
        address _kapToken
    ) {
        require(_teamMultisig != address(0), "Vesting: Zero address");
        require(_foundationMultisig != address(0), "Vesting: Zero address");
        require(_kapToken != address(0), "Vesting: Zero address");

        kapToken = IERC20(_kapToken);
        _grantRole(VESTING_CREATOR, _teamMultisig);
        _grantRole(VESTING_CREATOR, _foundationMultisig);
        _grantRole(REGISTRY_SETTER, _foundationMultisig);
    }

    /**
     * @notice Called by role {VESTING_CREATOR} to create a new vesting
     * agreement
     * @param beneficiary Address which is allowed to collect the KAP
     * @param vestStart Timestamp after which linear vesting starts
     * @param vestPeriod Time period over which vesting occurs
     * @param amount Total amount of KAP promised to beneficiary
     */
    function createVestingAgreement(
        address beneficiary,
        uint256 vestStart,
        uint256 vestPeriod,
        uint256 amount
    ) external onlyRole(VESTING_CREATOR) {
        require(beneficiary != address(0), "Vesting: Zero address");
        require(vestStart >= block.timestamp, "Vesting: Invalid vest start");
        require(vestPeriod > 0, "Vesting: Invalid vest period");
        require(amount > 0, "Vesting: Invalid amount");

        balances[beneficiary] += amount;
        votingWeight[delegates[beneficiary]] += amount;
        vestingAgreements[beneficiary].push(
            VestingAgreement({
                vestStart: SafeCast.toUint64(vestStart),
                vestPeriod: SafeCast.toUint64(vestPeriod),
                totalAmount: SafeCast.toUint96(amount),
                amountCollected: SafeCast.toUint96(0)
            })
        );

        emit CreateVestingAgreement(beneficiary, vestStart, vestPeriod, amount);
        kapToken.safeTransferFrom(msg.sender, address(this), amount); // caller provides KAP for the vesting agreement
    }

    /**
     * @notice Called at will by the beneficiary of a vesting agreement
     * to collect the available portion of KAP
     * @param vestingAgreementId Index in `vestingAgreements[beneficiary]`
     */
    function collect(uint256 vestingAgreementId) external {
        require(vestingAgreementId < vestingAgreements[msg.sender].length, "Vesting: Invalid Id");
        VestingAgreement storage vestingAgreement = vestingAgreements[msg.sender][vestingAgreementId];
        require(block.timestamp > vestingAgreement.vestStart, "Vesting: Not started"); // enforce vesting cliff
        
        uint256 amountUnlocked; // will calculate portion of `totalAmount` currently unlocked
        if (block.timestamp >= (vestingAgreement.vestStart + vestingAgreement.vestPeriod)) {
            amountUnlocked = vestingAgreement.totalAmount; // if `vestingAgreement.vestPeriod` has passed, the entire `totalAmount` is unlocked
        } else {
            amountUnlocked =
                (vestingAgreement.totalAmount *
                    (block.timestamp - vestingAgreement.vestStart)) /
                vestingAgreement.vestPeriod; // otherwise, we find the portion of `totalAmount` currently available
        }
        require(
            amountUnlocked > vestingAgreement.amountCollected,
            "Vesting: Collection limit"
        ); // make sure some of `amountUnlocked` has not yet been collected
        uint256 collectionAmount = amountUnlocked - vestingAgreement.amountCollected; // calculate amount available for collection
        
        balances[msg.sender] -= collectionAmount;
        votingWeight[delegates[msg.sender]] -= collectionAmount;
        vestingAgreement.amountCollected += SafeCast.toUint96(collectionAmount);

        emit Collect(msg.sender, vestingAgreementId);
        kapToken.safeTransfer(msg.sender, collectionAmount);
    }

    /**
     * @notice Used by beneficary to appoint new voting delegate
     * @param newDelegate The address to which voting weight is delegated
     */
    function appointDelegate(address newDelegate) external {
        require(newDelegate != address(0), "Vesting: Zero address");
        require(delegates[msg.sender] == address(0), "Vesting: Must undelegate first");
        uint256 votingPeriod = IGovernance(
            governanceRegistry.governance()
        ).votingPeriod();
        require(
            block.timestamp > lastUndelegated[msg.sender] + votingPeriod,
            "Vesting: Undelegate cooldown"
        ); // prohibit switching delegates and voting again on same proposal
        _appointDelegate(newDelegate);
        emit AppointDelegate(msg.sender, newDelegate);
    }

    /**
     * @notice Used by beneficiary prior to changing their delegate
     * @dev Protects against double voting by requiring beneficiary to
     * delegate to the zero address for {Governance.votingPeriod} before
     * changing to a new delegate
     */
    function undelegate() external {
        require(delegates[msg.sender] != address(0), "Vesting: Delegate already zero");
        lastUndelegated[msg.sender] = block.timestamp;
        _appointDelegate(address(0));
        emit Undelegate(msg.sender);
    }

    /**
     * @dev Internal function used in {appointDelegate} and {undelegate} to
     * update `msg.sender`'s delegate without restriction
     * @param newDelegate The address to which voting weight is delegated
     */
    function _appointDelegate(address newDelegate) internal {
        address oldDelegate = delegates[msg.sender];
        delegates[msg.sender] = newDelegate;
        uint256 balance = balances[msg.sender];
        if (balance > 0) {
            votingWeight[oldDelegate] -= balance;
            votingWeight[newDelegate] += balance;
        }
    }

    /**
     * @dev Used by role `REGISTRY_SETTER` to set {governanceRegistry}
     * @param _governanceRegistry The address which will become {governanceRegistry}
     */
    function setRegistry(address _governanceRegistry) external onlyRole(REGISTRY_SETTER) {
        require(_governanceRegistry != address(0), "Vesting: Zero address");
        governanceRegistry = IGovernanceRegistry(_governanceRegistry);
    }
}