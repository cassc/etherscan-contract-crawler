// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../utils/Pausable.sol";

import "../GmexChefV2.sol";
import "./GmexValidators.sol";
import "./GmexVoters.sol";

// Governance contract of Global Market Exchange
contract GmexGovernance is
    Initializable,
    OwnableUpgradeable,
    Pausable,
    GmexValidators,
    GmexVoters
{
    using SafeMathUpgradeable for uint256;

    // Info of each project.
    struct Project {
        string name;
        string shortDescription;
        string tokenSymbol;
        address tokenContract;
        string preferredDEXPlatform;
        int256 totalLiquidity;
        string projectWebsite;
        string twitterLink;
        string telegramLink;
        string discordLink;
        string mediumLink;
        bool approved;
        address[] validatorVoters;
    }

    // Info of each governance.
    struct Governance {
        uint256 governanceVotingStart;
        uint256 governanceVotingEnd;
        address[] validators;
        address[] voters;
        Project[] projects;
        uint256 mostVotedProjectIndex;
        uint256 winningVoteCount;
    }

    Governance[] public pastGovernances;
    Governance public currentGovernance;
    GmexChefV2 public gmexChef;

    modifier onlyGmexChef() {
        require(
            msg.sender == address(gmexChef),
            "GmexGovernance: Only GmexChef can perform this action"
        );
        _;
    }

    modifier runningGovernanceOnly() {
        require(
            currentGovernance.governanceVotingEnd == 0 ||
                block.timestamp < currentGovernance.governanceVotingEnd,
            "GmexGovernance: Voting has already ended"
        );
        require(
            block.timestamp >= currentGovernance.governanceVotingStart &&
                currentGovernance.governanceVotingStart != 0,
            "GmexGovernance: Voitng hasn't started yet"
        );
        _;
    }

    function initialize(
        uint256 _governanceVotingStart,
        uint256 _governanceVotingEnd,
        GmexChefV2 _gmexChef,
        address[] memory _whitelisted
    ) public initializer {
        __Ownable_init();
        __PausableUpgradeable_init();
        __GmexValidators_init(_whitelisted);
        currentGovernance.governanceVotingStart = _governanceVotingStart;
        currentGovernance.governanceVotingEnd = _governanceVotingEnd;
        gmexChef = _gmexChef;
    }

    function getSlashingParameter() internal view returns (uint256) {
        address[] memory currentValidators = getValidators();
        address[]
            memory offlineValidators = getValidatorsWhoHaveNotCastedVotes();

        uint256 x = offlineValidators.length.mul(100);
        uint256 n = currentValidators.length.mul(100);
        uint256 slashingParameter = x.sub(n.div(50)).mul(4).div(n.div(100));

        if (slashingParameter > 100) {
            slashingParameter = 100;
        }

        return slashingParameter;
    }

    function slashOfflineValidators() internal {
        uint256 slashingParameter = getSlashingParameter();
        address[]
            memory offlineValidators = getValidatorsWhoHaveNotCastedVotes();
        address[] memory onlineValidators = getValidatorsWhoHaveCastedVotes();

        gmexChef.slashOfflineValidators(
            slashingParameter,
            offlineValidators,
            onlineValidators
        );
    }

    function evaluateThreeValidatorsNominatedByNominator() internal {
        address[] memory nominators = getVoters();
        uint256 slashingParameter = getSlashingParameter();

        gmexChef.evaluateThreeValidatorsNominatedByNominator(
            slashingParameter,
            nominators
        );
    }

    function vestVotesToDifferentValidator(
        address nominator,
        address previousValidator,
        address newValidator
    ) public onlyGmexChef whenNotPaused {
        _vestVotesToDifferentValidator(
            nominator,
            previousValidator,
            newValidator
        );
    }

    // To be called at the end of a Governance period
    function applySlashing() internal onlyOwner {
        slashOfflineValidators();
        evaluateThreeValidatorsNominatedByNominator();
    }

    function startNewGovernance() external onlyOwner whenNotPaused {
        applySlashing();
        currentGovernance.validators = getValidators();
        currentGovernance.voters = getVoters();
        pastGovernances.push(currentGovernance);
        delete currentGovernance;
        resetVoters();

        currentGovernance.governanceVotingStart = block.timestamp;
        currentGovernance.governanceVotingEnd = block.timestamp + 7776000; // 90 days
    }

    function getPastGovernances() external view returns (Governance[] memory) {
        return pastGovernances;
    }

    function getProjects() external view returns (Project[] memory) {
        return currentGovernance.projects;
    }

    function addProject(
        string memory _name,
        string memory _description,
        string memory _tokenSymbol,
        address _tokenContract,
        string memory _preferredDEXPlatform,
        int256 _totalLiquidity,
        string memory _projectWebsite,
        string memory _twitterLink,
        string memory _telegramLink,
        string memory _discordLink,
        string memory _mediumLink
    ) external runningGovernanceOnly whenNotPaused {
        uint256 index = currentGovernance.projects.length;
        currentGovernance.projects.push();
        Project storage project = currentGovernance.projects[index];
        project.name = _name;
        project.shortDescription = _description;
        project.tokenSymbol = _tokenSymbol;
        project.tokenContract = _tokenContract;
        project.preferredDEXPlatform = _preferredDEXPlatform;
        project.totalLiquidity = _totalLiquidity;
        project.projectWebsite = _projectWebsite;
        project.twitterLink = _twitterLink;
        project.telegramLink = _telegramLink;
        project.discordLink = _discordLink;
        project.mediumLink = _mediumLink;
    }

    function approveProject(uint256 index)
        external
        runningGovernanceOnly
        onlyOwner
        whenNotPaused
    {
        require(
            index < currentGovernance.projects.length,
            "Project index out of bounds"
        );
        Project storage project = currentGovernance.projects[index];
        project.approved = true;
    }

    function delegateValidator(address validator)
        public
        override
        runningGovernanceOnly
        whenNotPaused
    {
        require(
            getValidatorsExists(validator),
            "GmexGovernance: Validator is not a valid"
        );
        super.delegateValidator(validator);

        uint256 votingPower = gmexChef.getVotingPower(msg.sender);
        GmexVoters.vestVotes(votingPower);
        GmexValidators.vestVotes(validator, votingPower);
    }

    function applyForValidator() public virtual override whenNotPaused {
        if (haveDelagatedValidator(msg.sender)) {
            withdrawVotes(getValidatorsNominatedByNominator(msg.sender)[0]); // using 0 index as votes were accumulated with the first validator among the three returned ones

            unDelegateValidator();
        }
        super.applyForValidator();
        uint256 gmexStaked = gmexChef.getStakedAmountInPool(0, msg.sender);
        require(
            gmexStaked >= getValidatorsMinStake(),
            "Stake not enough to become validator"
        );
    }

    function castVote(uint256 index)
        external
        validValidatorsOnly
        whenNotPaused
    {
        require(
            getValidatorsExists(msg.sender),
            "GmexGovernance: Only validators can cast a vote"
        );
        require(
            !haveCastedVote(msg.sender),
            "GmexGovernance: You have already voted"
        );
        require(
            index < currentGovernance.projects.length,
            "GmexGovernance: Project index out of bounds"
        );
        Project storage project = currentGovernance.projects[index];
        require(
            project.approved,
            "GmexGovernance: Project is not approved yet"
        );
        project.validatorVoters.push(msg.sender);
        updateCastedVote(true);
    }

    function rewardMostVotedProject()
        external
        onlyOwner
        runningGovernanceOnly
        whenNotPaused
    {
        uint256 mostVotes = 0;
        uint256 mostVotedIndex = 0;
        for (
            uint256 index = 0;
            index < currentGovernance.projects.length;
            index++
        ) {
            Project storage project = currentGovernance.projects[index];
            if (project.validatorVoters.length > mostVotes) {
                mostVotes = project.validatorVoters.length;
                mostVotedIndex = index;
            }
        }
        currentGovernance.mostVotedProjectIndex = mostVotedIndex;
        currentGovernance.winningVoteCount = mostVotes;
    }

    function leftStakingAsValidator(address _validator)
        external
        onlyGmexChef
        whenNotPaused
    {
        removeFromValidator(_validator);
    }
}