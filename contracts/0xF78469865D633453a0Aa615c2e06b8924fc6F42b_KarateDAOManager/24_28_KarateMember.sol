//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Token.sol";
import "./KarateClaim.sol";
import "./KaratePool.sol";
import "./Signatures.sol";


interface IUpgradableDAOContract {
  function finalizeUpgrade() external returns (bool);
}

interface ISignatureNonceStorage {
  function sigNonceMapping(uint256 nonce) external returns (bool);
  function setSigNonceMapping(uint256 nonce) external;
}

contract KarateDAOStorage is Ownable {

    struct Member {
        address addr; 
        string ipfs_metadata;
        bool isActive;
    }

    struct EventCard { 
        uint256 idx_pos;
        bool exists;
        uint256 eventStart;
        string info_ipfs;
        string results_ipfs;
        string snapshotProposalIPFS;
        bool deleted;
        uint64 outcomes;
        uint256 snapshotId;
    }

    struct Match {
        address fighter_1;
        address fighter_2;
        uint8 result;
    }

    mapping(uint256 => bool) public sigNonceMapping;

    mapping(address => Member) public membersMapping;
    mapping(uint256 => mapping(address => bool) ) public eventNumToStakeholdersMapping;
    mapping(uint256 => Match[]) public eventNumToMatches;
    mapping(uint256 => address[]) public eventNumToStakeholderAddresses;

    KaratePool[] public karatePools;

    mapping(uint256 => KarateClaim) public snapshotIdToClaimContract;

    mapping(string => uint256) public proposalIdToSnapshotId;

    mapping(uint256 => uint256) public snapshotIdToEventNum;

    mapping(uint256 => uint64) public snapshotIdToMatchOutcome;

    mapping(uint256 => uint256[]) public snapshotIdToVoteBalances;

    mapping(uint256 => uint256) public totalVotingBalanceAtSnapshotId;
    mapping( address => mapping(uint256 => bool) ) public claimedSnapshotIds;

    mapping(uint256 => bytes) public eventMetadata;

    //Should very rarely be used, privilege new storage instances over this in designs
    mapping(bytes32 => bytes32) arbitraryMapping;

    uint256 public nextPool;
    uint256 public _nonce;

    EventCard[] public events;
    address public oracleService;

    function incrementPool() onlyOwner public {
        nextPool += 1;
    }

    function setSigNonceMapping(uint256 nonce) onlyOwner public {
        sigNonceMapping[nonce] = true;
    }

    function setSnapshotIdToClaimContract(uint256 snapshotId, KarateClaim karateClaim) onlyOwner public {
        snapshotIdToClaimContract[snapshotId] = karateClaim;
    }

    function getSnapshotIdToClaimContract(uint256 snapshotId) public view returns (KarateClaim karateClaim){
        return snapshotIdToClaimContract[snapshotId];
    }

    function setSnapshotIdToEventNum(uint256 snapshotId, uint256 eventNum) onlyOwner public {
        snapshotIdToEventNum[snapshotId] = eventNum;
    }

    function getSnapshotIdToEvent(uint256 snapshotId) public view returns (EventCard memory eventCard) {
        return events[ snapshotIdToEventNum[snapshotId] ];
    }

    function setProposalIdToSnapshotId(string calldata proposalCID, uint256 snapshotId) onlyOwner public {
        proposalIdToSnapshotId[proposalCID] = snapshotId;
    }

    function getProposalIdToSnapshotId(string calldata proposalCID) onlyOwner public view returns (uint256 snapshotId) {
        return proposalIdToSnapshotId[proposalCID];
    }

    function setEventMetadata(uint256 eventNum, bytes memory metadata) onlyOwner public {
        eventMetadata[eventNum] = metadata;
    }

    function getEventMetadata(uint256 eventNum) onlyOwner public view returns (bytes memory metadata) {
        return eventMetadata[eventNum];
    }

    function setArbitaryMapping(bytes32 key, bytes32 data) onlyOwner public {
        arbitraryMapping[key] = data;
    }

    function getArbitraryMapping(bytes32 key) onlyOwner public view returns (bytes32 data) {
        return arbitraryMapping[key];
    }

    function setOracleService(address _oracleService) onlyOwner external {
        oracleService = _oracleService;
    }

    function getEvent(uint256 eventCardIdx) public view returns (EventCard memory eventCard) {
        return events[eventCardIdx];
    }

    function setEvent(EventCard memory eventCard) onlyOwner public returns (uint256 eventCardIdx) {
      if(eventCard.exists) {
          events[eventCard.idx_pos] = eventCard;
          return eventCard.idx_pos;
      }
      eventCard.idx_pos = events.length;
      eventCard.exists = true;
      events.push(eventCard);
      return eventCard.idx_pos;
    }

    function eventsLength() public view returns (uint256 eventsLen) {
        return events.length;
    }

    function setStakeHolders(uint256 eventIdx, address[] calldata stakeholders) onlyOwner public {
      for(uint256 i=0; i < stakeholders.length; i++) {
          eventNumToStakeholdersMapping[eventIdx][stakeholders[i]] = true;
      }
      eventNumToStakeholderAddresses[eventIdx] = stakeholders;
    }

    function getStakeHolders(uint256 eventIdx) public view returns (address[] memory stakeholders) {
      return eventNumToStakeholderAddresses[eventIdx];
    }

    function setMatch(uint256 eventIdx, Match memory matchStruct, uint256 matchIdx) onlyOwner public {
        eventNumToMatches[eventIdx][matchIdx] = matchStruct;
    }

    function setMatch(uint256 eventIdx, Match memory matchCard) onlyOwner public returns (uint256 matchCardIdx) {
        eventNumToMatches[eventIdx].push(matchCard);
        return eventNumToMatches[eventIdx].length - 1;
    }

    function getMatches(uint256 eventIdx) public view returns (Match[] memory matches) {
        return eventNumToMatches[eventIdx];
    }


    function setMember(Member calldata member) onlyOwner public {
		membersMapping[member.addr] = member;
	}

    function getMember(address memberAddr) public view returns (Member memory member) {
        return membersMapping[memberAddr];
    }

    function setClaimedSnapshotId(address voter, uint256 _claimedSnapshotId) public onlyOwner {
		claimedSnapshotIds[voter][_claimedSnapshotId] = true;
	}

    function setSnapshotIdToVoteBalances(uint256 snapshotId, uint256[] calldata voteBals) public onlyOwner {
        snapshotIdToVoteBalances[snapshotId] = voteBals; 
    }

    function getSnapshotIdToVoteBalances(uint256 snapshotId) public view returns (uint256[] memory voteBalances) {
        return snapshotIdToVoteBalances[snapshotId];
    }

    function addKaratePool(KaratePool karatePool) onlyOwner public {
        karatePools.push(karatePool);
    }

    function getKaratePool(uint256 karatePoolIdx) public view returns (KaratePool karatePool) {
        return karatePools[karatePoolIdx];
    }


    function setNonce(uint256 nonce) onlyOwner public {
      _nonce = nonce; 
      return;
    }
}

contract KarateDAOManager is AccessControlEnumerable {
    bytes32 public constant KC_DELEGATE_ROLE = keccak256("KC_DELEGATE_ROLE");
    bytes32 public constant KC_FIGHTER_ROLE = keccak256("KC_FIGHTER_ROLE");
    bytes32 public constant KC_JUDGE_ROLE = keccak256("KC_JUDGE_ROLE");
    bytes32 public constant KC_HEAD_JUDGE_ROLE = keccak256("KC_HEAD_JUDGE_ROLE");
    bytes32 public constant KC_ORACLE_SERVICE_ROLE = keccak256("KC_ORACLE_SERVICE_ROLE");
    bytes32 public constant KC_MARKETING_MANAGER_ROLE = keccak256("KC_MARKETING_MANAGER_ROLE");
    mapping(bytes32 => uint256) public roleHierarchy;


    bytes32[] public AVAIL_ROLES = [DEFAULT_ADMIN_ROLE, KC_DELEGATE_ROLE, KC_FIGHTER_ROLE, KC_JUDGE_ROLE, KC_HEAD_JUDGE_ROLE];
    bytes32 NO_ROLE_VALUE = ~bytes32(0);

    string constant MEMBER_DNE_ERR = "ME1"; //"Member Does not Exist";
    string constant MEMBER_DE_ERR = "ME2"; //"Member Already Exists";
    string constant MEMBER_PERM_INVALID = "ME3"; //"Member's Permission is invalid";
    string constant UPGRADE_REQ_ERR = "SC1";//"Storage Contract's owner differs from Smart Contract";

    uint256 internal _nonce;
    uint8 internal minEventDelegateCount;
    uint8 internal minEventJudgeCount;


    modifier requireRole(bytes32 role) {
       require( 
           hasRole( DEFAULT_ADMIN_ROLE, _msgSender() ) || hasRole( role, _msgSender() ),
           MEMBER_PERM_INVALID
       );
       _;
    }


    modifier preventReplay(uint256 nonce, address nonceStorageAddress) {
        require(ISignatureNonceStorage(nonceStorageAddress).sigNonceMapping(nonce) == false, "SIGUSED");
        _;
        ISignatureNonceStorage(nonceStorageAddress).setSigNonceMapping(nonce);
    }


    KarateDAOStorage public daoStorage;
    KarateERC20 public token;
    KarateClaimFactory kcFactory;
    bool public eventOpened;
    uint256 public currentEvent;

    using Signatures for Signatures.SigData;

    event NewFightEvent(uint256 indexed eventNum, KarateDAOStorage.EventCard eventCard);
    event DeletedFightEvent(uint256 indexed eventNum, KarateDAOStorage.EventCard eventCard);
    event NewEventResult(address indexed memberAddr, string ipfs, uint256 indexed eventNum);
    event NewEventSnapshot(uint256 indexed eventNum, uint256 indexed snapshotId, uint256 indexed timestamp);
    event NewMember(address indexed memberAddr, string indexed ipfs, KarateDAOStorage.Member member);
    event Error(string msg);
    error UpgradeFailed(address currentOwner, address contractAddress);
    error MismatchedEventHash(string eventInfoIpfs, bytes32 expectedHash, bytes32 receivedHash);


    /// @custom:oz-upgrades-unsafe-allow constructorgNonceMapping*
    
    function _addPools(uint256[] memory prizePoolAmounts) internal {
         for(uint256 i=0; i < prizePoolAmounts.length; i++) {
             KaratePool kp = new KaratePool(address(token), address(daoStorage));
             token.transfer(address(kp), prizePoolAmounts[i]);
             daoStorage.addKaratePool(kp);
         }
    }

    constructor(uint256[] memory prizePoolAmounts, KarateClaimFactory _kcFactory) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(KC_DELEGATE_ROLE, _msgSender());

        _nonce = uint(keccak256(abi.encodePacked(_msgSender(), blockhash(block.number - 1)))); 

        roleHierarchy[DEFAULT_ADMIN_ROLE] = 1;
        roleHierarchy[KC_DELEGATE_ROLE] = 2;
        roleHierarchy[KC_MARKETING_MANAGER_ROLE] = 2;

        minEventDelegateCount = 3;
        minEventJudgeCount = 3;
        kcFactory = _kcFactory;

		daoStorage = new KarateDAOStorage();
        token = new KarateERC20();
        _addPools(prizePoolAmounts);

   }

   function addPools(uint256[] memory prizePoolAmounts) public requireRole(DEFAULT_ADMIN_ROLE) {
       _addPools(prizePoolAmounts);
   }

   function setMinEventDelegateCount(uint8 count) public requireRole(DEFAULT_ADMIN_ROLE) {
       minEventDelegateCount = count;
   }

   function setMinEventJudgeCount(uint8 count) public requireRole(DEFAULT_ADMIN_ROLE) {
       minEventJudgeCount = count;
   }

   function createEventCard(uint256 eventStart, string calldata info_ipfs, address[] calldata stakeholders) external virtual requireRole(KC_DELEGATE_ROLE) {
       KarateDAOStorage.EventCard memory eventCard = KarateDAOStorage.EventCard(0, false, eventStart, info_ipfs, "", "", false, 0, 0);
       eventCard.eventStart = eventStart;
       eventCard.info_ipfs = info_ipfs;
       uint256 eventIdx = daoStorage.setEvent(eventCard);
       daoStorage.setStakeHolders(eventIdx, stakeholders);
       emit NewFightEvent(eventIdx, eventCard);
   }

   function addMember(address addr, bytes32 role) public virtual requireRole(KC_DELEGATE_ROLE) {
       string memory empty_ipfs_metadata;
       addMemberInternal(addr, role, empty_ipfs_metadata);
   }

   function addMember(address addr, bytes32 role, string calldata ipfs_metadata) external virtual requireRole(KC_DELEGATE_ROLE) {
       addMemberInternal(addr, role, ipfs_metadata);
   }

   function getRoleHierarchy(bytes32 role) internal view returns (uint256 roleNum) {
       return roleHierarchy[role] > 0 ? roleHierarchy[role] : 9999;
   }

   function addMemberInternal(address addr, bytes32 role, string memory ipfs_metadata) internal {
       require(!hasRole(role, addr), MEMBER_DE_ERR);
       require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || getRoleHierarchy( KC_DELEGATE_ROLE ) < getRoleHierarchy(role), "NOPERM");
       _grantRole(role, addr);
       KarateDAOStorage.Member memory newMember = KarateDAOStorage.Member(addr, ipfs_metadata, true);
       daoStorage.setMember(newMember);
       emit NewMember(newMember.addr, newMember.ipfs_metadata, newMember);
   }

   function deleteMember(address addr) public requireRole(DEFAULT_ADMIN_ROLE) {
       KarateDAOStorage.Member memory member = daoStorage.getMember(addr);
       require(member.isActive == true, "MEMDEL"); //deleted already
       /*
       bytes32[] memory roles = getMemberRoles(addr);
       bytes32[] senderRoles = getMemberRoles(msg.sender);
       uint256 lowestRole = 9999;

       for(uint256 i=0; i < senderRoles.length; i++) {

           if(senderRoles[i] == NO_ROLE_VALUE) {
               continue;
           }

           if(getRoleHierarchy(senderRoles[i]) <  lowestRole) {
               lowestRole = getRoleHierarchy(senderRoles[i]);
           }
       }
       
       for(uint256 k=0; k < roles.length; k++) {

           if(roles[k] == NO_ROLE_VALUE) {
               continue;
           }

           if(!isSenderAdmin && getRoleHierarchy(roles[k]) <= lowestRole) {
               revert("MEMLOWR");
           } else {
               _revokeRole(roles[k], addr);
           }
       }
      */
       member.isActive = false;
       daoStorage.setMember(member);
   }

   function finalizeUpgrade() external virtual requireRole(DEFAULT_ADMIN_ROLE) returns (bool success) {
     daoStorage.setNonce(_nonce);
	 return true;
   }

   
   function populateMatchData(KarateDAOStorage.EventCard memory eventCard, address[] calldata fighters) internal virtual {
       require(fighters.length % 2 == 0, 'EVQTY'); //Must be even quantity of fighters
       for(uint i=0; i < fighters.length; i+=2) {
           address fighterA = fighters[i];
           address fighterB = fighters[i+1];
           require(hasRole(KC_FIGHTER_ROLE, fighterA) && hasRole(KC_FIGHTER_ROLE, fighterB),  'BADROLE');//Fighters must have the correct role

           KarateDAOStorage.Match memory matchCard = KarateDAOStorage.Match(fighters[i], fighters[i+1], 0);
           daoStorage.setMatch(eventCard.idx_pos, matchCard);
       }
   }

   function createSnapshot(uint256 eventNum) internal returns (uint256 snapshotId) { //external virtual requireRole(KC_DELEGATE_ROLE) returns (uint256 unixTime) {
       uint256 _snapshotId = token.createSnapshot();
       daoStorage.setSnapshotIdToEventNum(_snapshotId, eventNum);
       emit NewEventSnapshot(eventNum, _snapshotId, block.timestamp);
       return _snapshotId;
   }

   function getEventStakeholders(uint256 eventNum) public view returns (address[] memory) {
       return daoStorage.getStakeHolders(eventNum);
   }

   function validateOpenEventSignatures(uint256 eventNum, bytes32 eventCardHash, Signatures.SigData[] calldata delegates) internal view {
      uint8 approvedDelegates = 0;
      address[] memory signedDelegates = new address[](delegates.length);
      for(uint8 i=0; i < delegates.length; i+=1) {
          address signer = delegates[i].verifyMessage(eventCardHash);
          require(signer != address(0), "SIG0"); // Signature cannot be 0
          require(daoStorage.eventNumToStakeholdersMapping(eventNum, signer), 'NSE'); //Not a stakeholder for the event
          require(hasRole(KC_DELEGATE_ROLE, signer), 'NDR'); //Not Delegate Role

          bool alreadyExists; 
          uint256 pos;
          while(pos < signedDelegates.length) {
              if(signedDelegates[pos] == address(0)){
                  break;
              }

              if(signer == signedDelegates[pos]) {
                  alreadyExists = true;
                  break;
              }
              pos++;
          }

          if(alreadyExists) {
            continue;
          }

          approvedDelegates += 1;
          signedDelegates[pos] = signer;
      }
      require(approvedDelegates >= minEventDelegateCount, 'NEA'); //Not enough approvals
   }

   function openEvent(uint256 eventNum, string calldata snapshotProposalIPFSCID, address[] calldata fighters, uint256 nonce, Signatures.SigData[] calldata delegates) preventReplay(nonce, address(daoStorage)) requireRole(KC_DELEGATE_ROLE) external virtual { 
      require(!eventOpened, 'ALRDYOPN');
      currentEvent = eventNum;
      KarateDAOStorage.EventCard memory eventCard = daoStorage.getEvent(eventNum);
      require(eventCard.exists == true, 'Event Number DNE');
      bytes32 eventCardHash = keccak256(abi.encodePacked(eventCard.info_ipfs, snapshotProposalIPFSCID, fighters, nonce)); 

      validateOpenEventSignatures(eventNum, eventCardHash, delegates);

      uint256 snapshotId = createSnapshot(eventNum);

      eventCard.snapshotId = snapshotId;
      eventCard.snapshotProposalIPFS = snapshotProposalIPFSCID;
      daoStorage.setEvent(eventCard);


      populateMatchData(eventCard, fighters);
      eventOpened = true;
   }

   struct SigToScore {
       Signatures.SigData delegateSig;
       string resultIPFSCID;
       uint64 matchOutcomes;
   }

   function flattenGetMatches(uint256 eventNum) internal view returns (address[] memory matches) {
       KarateDAOStorage.Match[] memory typedMatches = daoStorage.getMatches(eventNum);
       matches = new address[](typedMatches.length*2);
       uint256 matchIdx;
       for(uint256 i=0; i < typedMatches.length; i++) {
           matches[matchIdx] = typedMatches[i].fighter_1;
           matches[matchIdx + 1] = typedMatches[i].fighter_2;
           matchIdx += 2;
       }
   }

   struct DidSignAndPos {
       uint256 pos;
       bool didSign;
   }

   function checkIfSignedAlready(address signer, address[] memory signedDelegates) internal pure returns (DidSignAndPos memory didSignAndPos) {
          while(didSignAndPos.pos < signedDelegates.length) {
              if(signedDelegates[didSignAndPos.pos] == address(0)){
                  break;
              }

              if(signer == signedDelegates[didSignAndPos.pos]) {
                  didSignAndPos.didSign = true;
                  break;
              }
              didSignAndPos.pos++;
          }
   }

   function validateCloseEventSignatures(uint256 eventNum, string memory info_ipfs, uint256 nonce, SigToScore[] memory delegateAndScores) internal returns (SigToScore memory headJudgeSigToScore) {
      uint8 approvedDelegates = 0;
      bool commissionApproved = false;
      address[] memory signedDelegates = new address[](delegateAndScores.length);
      for(uint8 i=0; i < delegateAndScores.length; i+=1) {
          SigToScore memory sigToScore = delegateAndScores[i];

          bool isFinalResult = sigToScore.matchOutcomes > 0;
          bytes32 eventCardHash;

          if(isFinalResult) {
            eventCardHash = keccak256(abi.encodePacked(info_ipfs, sigToScore.resultIPFSCID, sigToScore.matchOutcomes, nonce)); 
          } else {
            eventCardHash = keccak256(abi.encodePacked(info_ipfs, sigToScore.resultIPFSCID, nonce)); 
          }

          address signer = sigToScore.delegateSig.verifyMessage(eventCardHash);
          DidSignAndPos memory didSignAndPos = checkIfSignedAlready(signer, signedDelegates);

          if(didSignAndPos.didSign) {
            continue;
          }
         
          require(daoStorage.eventNumToStakeholdersMapping(eventNum, signer), 'NSE'); //Not a stakeholder for the event
          bool isHeadJudge = hasRole(KC_HEAD_JUDGE_ROLE, signer);
          require(hasRole(KC_JUDGE_ROLE, signer) || isHeadJudge, 'NJR');//Not Judge Role
          if(isHeadJudge) { 
            headJudgeSigToScore = sigToScore;
            commissionApproved = true;
          } else {
            approvedDelegates += 1;
          }
          signedDelegates[didSignAndPos.pos] = signer;
          emit NewEventResult(signer, sigToScore.resultIPFSCID, eventNum);
      }
      require(approvedDelegates >= minEventJudgeCount && commissionApproved, 'NEA');//Not enough approvals
   }


   function closeEvent(uint256 eventNum, uint256 nonce, SigToScore[] memory delegateAndScores) preventReplay(nonce, address(daoStorage)) requireRole(KC_DELEGATE_ROLE) external virtual {
      //(bool memory exists, string memory info_ipfs, mapping(address => bool) memory stakeholders) = daoStorage.events(eventNum);
      //require(exists == true, 'Event Number DNE');
      require(eventOpened, 'NOEVENTOPEN');
      require(eventNum == currentEvent, "EVNTNOPN");

      KarateDAOStorage.EventCard memory eventCard = daoStorage.getEvent(eventNum);


      SigToScore memory headJudgeSigToScore = validateCloseEventSignatures(eventNum, eventCard.info_ipfs, nonce, delegateAndScores);
      eventCard.results_ipfs = headJudgeSigToScore.resultIPFSCID;
      eventCard.outcomes = headJudgeSigToScore.matchOutcomes; 

      daoStorage.setEvent(eventCard);
      KaratePool pool = daoStorage.getKaratePool(daoStorage.nextPool());
      daoStorage.incrementPool();

      address[] memory oracleServices = new address[](getRoleMemberCount(KC_ORACLE_SERVICE_ROLE));
      require(oracleServices.length > 0, "BADORACLLEN");
      for(uint256 idx=0; idx < getRoleMemberCount(KC_ORACLE_SERVICE_ROLE); idx++) {
          oracleServices[idx] = getRoleMember(KC_ORACLE_SERVICE_ROLE, idx);
      }

      KarateClaim claimAddress = kcFactory.createKarateClaimContract(ClaimConstructorArgs(address(this), address(token), address(pool), eventCard.snapshotId, oracleServices, eventCard.outcomes, flattenGetMatches(eventNum)));
      pool.createAllowance(address(claimAddress));
      daoStorage.setSnapshotIdToClaimContract(eventCard.snapshotId, claimAddress);
      eventOpened = false;
   }

   function upgradeDao(address new_contract_addr) external virtual requireRole(DEFAULT_ADMIN_ROLE) {
      IUpgradableDAOContract newDAO = IUpgradableDAOContract(new_contract_addr);
      daoStorage.transferOwnership(new_contract_addr);
      token.transferOwnership(new_contract_addr);
      token.transfer( new_contract_addr, token.balanceOf( address(this) ) );

      if(newDAO.finalizeUpgrade())
        return;

      revert UpgradeFailed(daoStorage.owner(), _msgSender());
   }

   function getMemberRoles(address member) public view returns (bytes32[] memory roles) {
    bytes32[] memory rolesArr = new bytes32[](AVAIL_ROLES.length);
    for(uint256 i=0; i < AVAIL_ROLES.length; i++) {
        if( hasRole(AVAIL_ROLES[i], member) ) {
            rolesArr[i] = AVAIL_ROLES[i];
        } else {
            rolesArr[i] = NO_ROLE_VALUE;
        }
    }
    return rolesArr;
   }

   function setEventViewLink(uint256 eventNum, string memory viewLink) external virtual requireRole(KC_DELEGATE_ROLE) {
       daoStorage.setEventMetadata(eventNum, abi.encode(viewLink));
   }

   function getEventViewLink(uint256 eventNum) public view returns (string memory viewLink) {
      return abi.decode(daoStorage.getEventMetadata(eventNum), (string));
   }

   function isEventClaimed(address claimant, uint256 eventNum) public view returns (bool isClaimed) {
       return daoStorage.claimedSnapshotIds(claimant, daoStorage.getEvent(eventNum).snapshotId);
   }

   function deleteEvent(uint256 eventCardNum) external virtual requireRole(DEFAULT_ADMIN_ROLE) returns (bool successful) {
       KarateDAOStorage.EventCard memory eventCard = daoStorage.getEvent(eventCardNum);
       eventCard.deleted = true;
       daoStorage.setEvent(eventCard);
       emit DeletedFightEvent(eventCardNum, eventCard);
       return true;
   }

   function setSnapshotIdToVoteBalances(uint256 snapshotId, uint256[] calldata voteBals) external requireRole(KC_ORACLE_SERVICE_ROLE) {
       
       uint256 matchCount = daoStorage.getMatches( daoStorage.snapshotIdToEventNum(snapshotId) ).length;

       require(voteBals.length == matchCount*2, "LENDNE"); 
       daoStorage.setSnapshotIdToVoteBalances(snapshotId, voteBals);
       KarateClaim(daoStorage.getSnapshotIdToClaimContract(snapshotId)).setSnapshotIdToVoteBalances(voteBals);
   }

   function setTotalClaimable(uint256 snapshotId, uint256[] memory amountClaimable) external requireRole(KC_ORACLE_SERVICE_ROLE) {
       KarateClaim(daoStorage.getSnapshotIdToClaimContract(snapshotId)).setTotalClaimable(amountClaimable);
   }

   function transfer(address recipient, uint256 amount) external requireRole(DEFAULT_ADMIN_ROLE) {
       token.transfer(recipient, amount); 
   }

   function mint(address recipient, uint256 amount) external requireRole(DEFAULT_ADMIN_ROLE) {
       token.mint(recipient, amount);
   }

   function claim(uint256[] calldata votesPerOutcome, uint64[] calldata outcomes, uint256[] calldata snapshotIds, Signatures.SigData[] calldata signatures) external {
        require(!hasRole(KC_ORACLE_SERVICE_ROLE, msg.sender), 'ONEC'); //Oracle service cannot claim its own rewards;
       
        for(uint256 snapIdx = 0; snapIdx < snapshotIds.length; snapIdx++) { 
            KarateClaim karateClaim = daoStorage.getSnapshotIdToClaimContract(snapshotIds[snapIdx]);
            uint256 totalOwedRewards = karateClaim.claim(msg.sender, votesPerOutcome, outcomes, snapshotIds, signatures);
            daoStorage.setClaimedSnapshotId(msg.sender, snapshotIds[snapIdx]);
        }
   }
}