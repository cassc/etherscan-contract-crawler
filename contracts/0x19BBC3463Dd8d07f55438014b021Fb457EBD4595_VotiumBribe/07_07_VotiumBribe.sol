// SPDX-License-Identifier: MIT
// Votium Bribe

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./Ownable.sol";

contract VotiumBribe is Ownable {

  using SafeERC20 for IERC20;

  /* ========== STATE VARIABLES ========== */

    // accepted tokens registry
    struct Token {
      bool whitelist;
      address distributor;
    }

    // proposal data
    struct Proposal {
      uint256 deadline;
      uint256 maxIndex;
    }

    mapping(bytes32 => Proposal) public proposalInfo;  // bytes32 of snapshot IPFS hash id for a given proposal
    mapping(address => Token) public tokenInfo;        // bribe token registry data

    mapping(bytes32 => bool) public delegationHash;    // approved hashes for EIP1271 delegated vote
    mapping(address => bool) public approvedTeam;      // for team functions that do not require multi-sig security

    address public feeAddress = 0xe39b8617D571CEe5e75e1EC6B2bb40DdC8CF6Fa3; // Votium multisig
    uint256 public platformFee = 400;             // 4%
    uint256 public constant DENOMINATOR = 10000;  // denominates weights 10000 = 100%

    bool public requireWhitelist = true;  // begin with erc20 whitelist in effect



  /* ========== CONSTRUCTOR ========== */

    constructor() {
      approvedTeam[msg.sender] = true;
      approvedTeam[0x540815B1892F888875E800d2f7027CECf883496a] = true;
    }

  /* ========== PUBLIC FUNCTIONS ========== */

    // Deposit bribe
    function depositBribe(address _token, uint256 _amount, bytes32 _proposal, uint256 _choiceIndex) public {
      if(requireWhitelist == true) {
        require(tokenInfo[_token].whitelist == true, "!whitelist");
      }
      require(proposalInfo[_proposal].deadline > block.timestamp, "invalid proposal");
      require(proposalInfo[_proposal].maxIndex >= _choiceIndex, "invalid choice");
      uint256 fee = _amount*platformFee/DENOMINATOR;
      uint256 bribeTotal = _amount-fee;
      IERC20(_token).safeTransferFrom(msg.sender, feeAddress, fee);
      if(tokenInfo[_token].distributor == address(0)) {
        IERC20(_token).safeTransferFrom(msg.sender, address(this), bribeTotal);  // if distributor contract is not set, store in this contract until ready
      } else {
        IERC20(_token).safeTransferFrom(msg.sender, tokenInfo[_token].distributor, bribeTotal); // if distributor contract is set, send directly to distributor
      }
      emit Bribed(_token, bribeTotal, _proposal, _choiceIndex);
    }

    // called by vote proxy contract as part of EIP1271 contract signing for delegated votes
    function isWinningSignature(bytes32 _hash, bytes memory _signature) public view returns (bool) {
      return delegationHash[_hash];
    }

  /* ========== APPROVED TEAM FUNCTIONS ========== */

    // initiate proposal for bribes
    function initiateProposal(bytes32 _proposal, uint256 _deadline, uint256 _maxIndex) public onlyTeam {
      require(proposalInfo[_proposal].deadline == 0, "exists");
      require(_deadline > block.timestamp, "invalid deadline");
      proposalInfo[_proposal].deadline = _deadline;
      proposalInfo[_proposal].maxIndex = _maxIndex;
      emit Initiated(_proposal);
    }

    // approve EIP1271 vote hash for delegated vlCVX
    function approveDelegationVote(bytes32 _hash) public onlyTeam {
      delegationHash[_hash] = true;
    }

    // transfer stored bribes to distributor (only pertains to bribes made before a token distributor has been set)
    function transferToDistributor(address _token) public onlyTeam {
      require(tokenInfo[_token].distributor != address(0), "no distributor");
      uint256 bal = IERC20(_token).balanceOf(address(this));
      IERC20(_token).safeTransfer(tokenInfo[_token].distributor, bal);
    }

    // whitelist token
    function whitelistToken(address _token) public onlyTeam {
      tokenInfo[_token].whitelist = true;
      emit Whitelisted(_token);
    }

    // whitelist multiple tokens
    function whitelistTokens(address[] memory _tokens) public onlyTeam {
      for(uint256 i=0;i<_tokens.length;i++) {
        tokenInfo[_tokens[i]].whitelist = true;
        emit Whitelisted(_tokens[i]);
      }
    }

  /* ========== MUTLI-SIG FUNCTIONS ========== */

    // toggle whitelist requirement
    function setWhitelistRequired(bool _requireWhitelist) public onlyOwner {
      requireWhitelist = _requireWhitelist;
      emit WhitelistRequirement(_requireWhitelist);
    }

    // update fee address
    function updateFeeAddress(address _feeAddress) public onlyOwner {
      feeAddress = _feeAddress;
    }

    // update fee amount
    function updateFeeAmount(uint256 _feeAmount) public onlyOwner {
      require(_feeAmount < 400, "max fee"); // Max fee 4%
      platformFee = _feeAmount;
      emit UpdatedFee(_feeAmount);
    }

    // add or remove address from team functions
    function modifyTeam(address _member, bool _approval) public onlyOwner {
      approvedTeam[_member] = _approval;
      emit ModifiedTeam(_member, _approval);
    }

    // update token distributor address
    function updateDistributor(address _token, address _distributor) public onlyOwner {
      // can be changed for future use in case of cheaper gas options than current merkle approach
      tokenInfo[_token].distributor = _distributor;
      emit UpdatedDistributor(_token, _distributor);
    }

  /* ========== MODIFIERS ========== */

    modifier onlyTeam() {
      require(approvedTeam[msg.sender] == true, "Team only");
      _;
    }

  /* ========== EVENTS ========== */

    event Bribed(address _token, uint256 _amount, bytes32 indexed _proposal, uint256 _choiceIndex);
    event Initiated(bytes32 _proposal);
    event Whitelisted(address _token);
    event WhitelistRequirement(bool _requireWhitelist);
    event UpdatedFee(uint256 _feeAmount);
    event ModifiedTeam(address _member, bool _approval);
    event UpdatedDistributor(address indexed _token, address _distributor);

}