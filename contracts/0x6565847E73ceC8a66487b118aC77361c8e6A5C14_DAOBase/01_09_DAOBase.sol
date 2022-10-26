//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.9;

import './interfaces/IDAOBase.sol';
import './interfaces/IDAOFactory.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

contract DAOBase is OwnableUpgradeable, IDAOBase {

    // @dev constant
    uint256 public constant SETTING_TYPE_GENERAL = 0;
    uint256 public constant SETTING_TYPE_TOKEN = 1;
    uint256 public constant SETTING_TYPE_GOVERNANCE = 2;

    // @dev dao factory address
    address public factoryAddress;

    // @dev DAO Base Info
    General public daoInfo;

    // @dev DAO Token Info
    Token public daoToken;

    // @dev DAO Governance
    Governance public daoGovernance;

    // @dev Manager
    // @dev contract owner: super admin
    mapping(address => bool) public admins;


    // @dev proposals slot
    uint256 public proposalIndex;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => mapping(uint256 => VoteInfo[])) public voteInfos;

    // @dev Event
    event Setting(uint256 indexed settingType);
    event Admin(address indexed admin, bool enable);
    event CreateProposal(uint256 indexed proposalId, address indexed proposer, uint256 startTime, uint256 endTime);
    event CancelProposal(uint256 indexed proposalId);
    event Vote(uint256 indexed proposalId, address indexed voter, uint256 indexed optionIndex, uint256 amount);

    // @dev Struct
    struct Proposal {
        bool cancel;
        address creator;
        string title;
        string introduction;
        string content;
        uint256 startTime;
        uint256 endTime;
        uint256 votingThresholdSnapshot;
        VotingType votingType;
        ProposalOption[] options;
    }

    struct ProposalOption {
        string name;
        uint256 amount;
    }

    struct VoteInfo {
        uint256 index;
        uint256 amount;
    }

    enum SignType { CreateProposal, Voting }
    struct SignInfo {
        uint256 chainId;
        address tokenAddress;
        uint256 balance;
        SignType signType;
        uint256 proposalIdOrDeadline;
    }

    struct ProposalInput {
        string title;
        string introduction;
        string content;
        uint256 startTime;
        uint256 endTime;
        VotingType votingType;
    }


    // @dev Modifier
    /**
     * @dev Throws if called by any account other than the owner or admin.
     */
    modifier onlyOwnerOrAdmin() {
        require(
            owner() == msg.sender || admins[msg.sender],
                "DAOBase: caller is not the owner or admin."
        );
        _;
    }


    //------------------------ initialize ------------------------//
    /**
     * @dev Initializes the contract by simple way.
     */
    function initialize(
        General calldata general_,
        Token calldata token_,
        Governance calldata governance_
    ) override external initializer {
        factoryAddress = msg.sender;
        OwnableUpgradeable.__Ownable_init();

        _setInfo(general_);
        _setToken(token_);
        _setGovernance(governance_);
    }


    //------------------------ owner or admin ------------------------//
    /**
     * @dev remove or add a admin.
     */
    function setAdmin(address admin_, bool enabled_) external onlyOwner {
        _setAdmin(admin_, enabled_);
    }

    /**
     * @dev set dao info
     */
    function setInfo(string[] calldata args) external onlyOwnerOrAdmin {
        require(args.length == 8, 'DAOBase: length mismatch.');
        _setInfo(General(args[0], daoInfo.handle, args[1], args[2], args[3], args[4], args[5], args[6], args[7]));
    }

    function setGovernance(Governance calldata governance_) external onlyOwnerOrAdmin {
        _setGovernance(governance_);
    }


    //------------------------ public ------------------------//
    /**
     * @dev create proposal
     */
    function createProposal(
        ProposalInput calldata input_,  // avoid stack too deep
        string[] calldata options_,
        SignInfo calldata signInfo_,
        bytes calldata signature_
    ) external {
        Governance memory _governance = daoGovernance;
        require(
            input_.votingType != VotingType.Any &&
            (_governance.votingType == VotingType.Any || _governance.votingType == input_.votingType),
                'DAOBase: invalid voting type.'
        );
        require(signInfo_.proposalIdOrDeadline >= block.timestamp, 'DAOBase: expired.');
        require(_verifySignature(signInfo_, signature_), 'DAOBase: invalid signer.');
        require(signInfo_.balance >= _governance.proposalThreshold, 'DAOBase: insufficient balance.');

        uint256 _endTime = input_.endTime;
        if (_governance.votingPeriod > 0) {
            _endTime = input_.startTime + _governance.votingPeriod;
        }
        require(input_.startTime < input_.endTime, 'DAOBase: startTime ge endTime.');
        require(options_.length > 0, 'DAOBase: dont have enough options.');

        uint256 _proposalIndex = proposalIndex;
        proposalIndex = _proposalIndex + 1;
        Proposal storage proposal = proposals[_proposalIndex];
        for (uint256 _index = 0; _index < options_.length; _index++) {
            proposal.options.push(ProposalOption({
                name: options_[_index],
                amount: 0
            }));
        }
        proposal.creator = msg.sender;
        proposal.title = input_.title;
        proposal.introduction = input_.introduction;
        proposal.content = input_.content;
        proposal.startTime = input_.startTime;
        proposal.endTime = _endTime;
        proposal.votingThresholdSnapshot = _governance.votingThreshold;
        proposal.votingType = input_.votingType;

        emit CreateProposal(_proposalIndex, msg.sender, input_.startTime, _endTime);
    }

    /**
     * @dev vote for proposal
     */
    function vote(
        uint256[] calldata optionIndexes_,
        uint256[] calldata amounts_,
        SignInfo calldata signInfo_,
        bytes calldata signature_
    ) external {
        uint256 _proposalId = signInfo_.proposalIdOrDeadline;
        Proposal memory _proposal = proposals[_proposalId];
        require(proposalIndex > _proposalId, 'DAOBase: proposal id not exists.');
        require(optionIndexes_.length == amounts_.length, 'DAOBase: invalid length.');
        require(voteInfos[msg.sender][_proposalId].length == 0, 'DAOBase: already voted.');

        require(_verifySignature(signInfo_, signature_), 'DAOBase: invalid signer.');
        require(block.timestamp >= _proposal.startTime && block.timestamp < _proposal.endTime, 'DAOBase: vote on a wrong time.');
        require(!_proposal.cancel, 'DAOBase: already canceled.');
        if (proposals[_proposalId].votingType == VotingType.Single)
            require(optionIndexes_.length == 1, 'DAOBase: invalid length.');

        uint256 _totalAmount = 0;
        uint256 _optionsLength = proposals[_proposalId].options.length;
        for (uint256 _index = 0; _index < optionIndexes_.length; _index++) {
            require(_optionsLength > optionIndexes_[_index], 'DAOBase: proposal option index not exists.');
            _totalAmount += amounts_[_index];
            proposals[_proposalId].options[optionIndexes_[_index]].amount += amounts_[_index];
            voteInfos[msg.sender][_proposalId].push(VoteInfo(optionIndexes_[_index], amounts_[_index]));

            emit Vote(_proposalId, msg.sender, optionIndexes_[_index], amounts_[_index]);
        }

        require(signInfo_.balance >= _totalAmount, 'DAOBase: insufficient balance.');
    }

    /**
     * @dev Cancel an active proposal
     */
    function cancelProposal(uint256 proposalId_) external {
        Proposal memory _proposal = proposals[proposalId_];
        require(proposalIndex > proposalId_, 'DAOBase: proposal id not exists.');
        require(block.timestamp < _proposal.startTime, 'DAOBase: already started.');
        require(msg.sender == _proposal.creator, 'DAOBase: sender is not the creator.');
        require(!_proposal.cancel, 'DAOBase: already canceled.');

        proposals[proposalId_].cancel = true;
        emit CancelProposal(proposalId_);
    }

    //------------------------ public get ------------------------//
    function getProposalOptionById(uint256 proposalId_) external view returns (ProposalOption[] memory) {
        return proposals[proposalId_].options;
    }

    function getVoteInfoByAccountAndProposalId(address account_, uint256 proposalId_) external view returns (VoteInfo[] memory) {
        return voteInfos[account_][proposalId_];
    }

    //------------------------ private ------------------------//
    function _setAdmin(address admin_, bool enabled_) private {
        admins[admin_] = enabled_;

        emit Admin(admin_, enabled_);
    }

    function _setInfo(General memory general_) private {
        daoInfo = general_;

        emit Setting(SETTING_TYPE_GENERAL);
    }

    function _setToken(Token calldata token_) private {
        daoToken = token_;

        emit Setting(SETTING_TYPE_TOKEN);
    }

    function _setGovernance(Governance calldata governance_) private {
        daoGovernance = governance_;

        emit Setting(SETTING_TYPE_GOVERNANCE);
    }

    function _verifySignature(SignInfo calldata signInfo_, bytes calldata signature_) private view returns (bool) {
        if (signInfo_.chainId != daoToken.chainId || signInfo_.tokenAddress != daoToken.tokenAddress) {
            return false;
        }
        bytes32 _hash = ECDSAUpgradeable.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    block.chainid,
                    address(this),
                    signInfo_.chainId,
                    signInfo_.tokenAddress,
                    signInfo_.proposalIdOrDeadline,
                    signInfo_.balance,
                    uint256(signInfo_.signType)
                )
            )
        );
        address _signer = ECDSAUpgradeable.recover(_hash, signature_);

        return IDAOFactory(factoryAddress).isSigner(_signer);
    }

    function daoVersion() external pure returns (string memory) {
        return 'v0.2.1';
    }
}