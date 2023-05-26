//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./Signatures.sol";

interface IERC20Snapshot is IERC20 {
    function balanceOfAt(address account, uint256 snapshotId) external view returns (uint256);
}
interface IKarateDAOStorage {

    struct EventCard { 
        uint256 idx_pos;
        bool exists;
        uint256 eventStart;
        string info_ipfs;
        string results_ipfs;
        string snapshotProposalIPFS;
        bool deleted;
        uint64 outcomes;
    }

    function oracleService() external view returns (address oracleServiceAddr);

    function getSnapshotIdToEvent(uint256 snapshotId) external view returns (EventCard memory eventCard);
    function claimedSnapshotIds(address claimant, uint256 snapshotId) external view returns (bool exists);
}

struct ClaimConstructorArgs {
    address _karateDaoStorageAddr; 
    address _karateToken;
    address _pool;
    uint256 _snapshotId;
    address[] _oracleServices; 
    uint64 _eventOutcome;
    address[] _matches;
}

contract KarateClaimFactory is Ownable {
    function createKarateClaimContract(ClaimConstructorArgs memory claimConstructorArgs) external returns (KarateClaim karateClaim) {
        return new KarateClaim(claimConstructorArgs);
    }
}

contract KarateClaim is Ownable {

   struct ClaimData {
       uint256 lastOutcomeVote;
       uint256 totalOwedRewards;
       uint256 totalVoteAtSnapshot;
   }


   using Signatures for Signatures.SigData;

   IERC20Snapshot public token;
   address public accessContract;
   uint256 public snapshotId;
   address public pool;
   uint256 public prizePoolAmount;
   uint256 public amountClaimable;
   address[] public oracleServices;
   uint64 public eventOutcome;
   uint256 totalTokenAlloc;
   uint256[] public voteBalances;
   address[] public fighterMatches;

   bool public totalClaimableCalled;

   uint256 RESOLUTION_FACTOR_100 = 10**16;
   uint256 fighterBonusPercent = 10;
   uint256 winnerSplit = 90;
   mapping(address => bool) public addressHasClaimed;


   constructor(ClaimConstructorArgs memory claimConstructorArgs) {
       token = IERC20Snapshot(claimConstructorArgs._karateToken);
       accessContract = claimConstructorArgs._karateDaoStorageAddr;
       pool = claimConstructorArgs._pool;

       snapshotId = claimConstructorArgs._snapshotId;
       oracleServices = claimConstructorArgs._oracleServices;
       eventOutcome = claimConstructorArgs._eventOutcome;
       prizePoolAmount = token.balanceOf(claimConstructorArgs._pool);
       fighterMatches = claimConstructorArgs._matches;
   }

   function isOracleService(address candidate) internal view returns (bool testResult) {
        for(uint256 j =0; j < oracleServices.length; j++) {
            if( candidate == oracleServices[j] ){
                return true;
            }
        }
        return false;
   }

   function findLoserIndex(uint256 winnerIdx) internal pure returns (uint256 loserIdx) {
       if(winnerIdx % 2 == 0) {
           loserIdx = winnerIdx + 1;
       } else {
           loserIdx = winnerIdx - 1;
       }
   }

   function setTotalClaimable(uint256[] memory totalVotesFromThisChain) external {
       require(msg.sender == accessContract, 'NotLogicContract');
       require(!totalClaimableCalled, 'CALLED');
       require(voteBalances.length != 0, 'VOTEUNSET');
       require(fighterMatches.length == totalVotesFromThisChain.length, 'LENDNM');

       uint256 totalClaimable;

	   for(uint8 outcomeBit = 0; outcomeBit < 64; outcomeBit++) {
	       uint64 bitResult = (eventOutcome >> outcomeBit) & uint64(1);

	       if(bitResult != uint64(1)) {
	       	continue;
	       }

           totalClaimable += calculatePlayerRewards(outcomeBit, totalVotesFromThisChain[outcomeBit]); 
       }
       amountClaimable = totalClaimable;
       require(token.balanceOf(pool) >= totalClaimable, 'AMTBIG');
       token.transferFrom(pool, accessContract, prizePoolAmount - totalClaimable);
       totalClaimableCalled = true;
   }

   function setSnapshotIdToVoteBalances(uint256[] memory _voteBalances) external {
       require(voteBalances.length == 0, 'Set already');
       require(msg.sender == accessContract, 'NotLogicContract');

       voteBalances = _voteBalances;
       

       uint256 tempTotal;
       for(uint256 i = 0; i < _voteBalances.length; i++) {
           tempTotal += _voteBalances[i];
       }
       totalTokenAlloc = tempTotal;

	   for(uint8 outcomeBit = 0; outcomeBit < 64; outcomeBit++) {
	       uint64 bitResult = (eventOutcome >> outcomeBit) & uint64(1);

	       if(bitResult != uint64(1)) {
	       	continue;
	       }

           token.transferFrom(pool, fighterMatches[outcomeBit], calculateFighterRewards(outcomeBit) * winnerSplit / 100);

           token.transferFrom(pool, fighterMatches[findLoserIndex(outcomeBit)], calculateFighterRewards(outcomeBit) * (100 - winnerSplit) / 100);
       }
   }

   struct FighterRewards {
       uint256 fighterEarnings;
       uint256 fightPrizePool;
   }


   function calculateRewards(uint256 winningFighterIdx) internal view returns (FighterRewards memory fighterRewards) {
        
        uint256 fightHypeCoefficient = RESOLUTION_FACTOR_100 * 100 * (voteBalances[winningFighterIdx] + voteBalances[findLoserIndex(winningFighterIdx)]) / totalTokenAlloc;
        fighterRewards.fightPrizePool = prizePoolAmount * fightHypeCoefficient / 100 / RESOLUTION_FACTOR_100;
        fighterRewards.fighterEarnings = RESOLUTION_FACTOR_100 * fighterBonusPercent * fighterRewards.fightPrizePool / 100 / RESOLUTION_FACTOR_100;
        return fighterRewards;
   }

   function calculateFighterRewards(uint256 winningFighterIdx) internal view returns (uint256 sum) {
        return calculateRewards(winningFighterIdx).fighterEarnings;
   }

   function calculatePlayerRewards(uint256 winningFighterIdx, uint256 fightVote) internal view returns (uint256 sum) {
        FighterRewards memory fighterRewards = calculateRewards(winningFighterIdx);
        uint256 playerProportionToPool = RESOLUTION_FACTOR_100 * 100 * fightVote / voteBalances[winningFighterIdx];
        uint256 playerEarnings = (fighterRewards.fightPrizePool - fighterRewards.fighterEarnings) * playerProportionToPool / 100 / RESOLUTION_FACTOR_100;
        return playerEarnings;
   }

   function estimateEarnings(uint64 outcome, uint256[] memory votesPerOutcome) public view returns (uint256 earnings) {
       require(voteBalances.length != 0, 'TOTALVOTESSET');
       uint256 totalClaimable;
       uint256 votesIdx;

	   for(uint8 outcomeBit = 0; outcomeBit < 64; outcomeBit++) {
	       uint64 bitResult = (outcome >> outcomeBit) & uint64(1);

	       if(bitResult != uint64(1)) {
	       	continue;
	       }

           uint64 matchResult = (eventOutcome >> outcomeBit) & uint64(1);

           if((matchResult & bitResult) == uint64(0)) {
               votesIdx++;
               continue;
           }

           totalClaimable += calculatePlayerRewards(outcomeBit, votesPerOutcome[votesIdx]); 
           votesIdx++;
       }

       return totalClaimable;
   }


   function claim(address claimant, uint256[] memory votesPerOutcome, uint64[] memory outcomes, uint256[] memory snapshotIds, Signatures.SigData[] memory signatures) external returns (uint256 totalRewards){
        require(voteBalances.length != 0, 'TOTALVOTESSET');
        require(addressHasClaimed[claimant] == false, 'CCA'); // claimant claimed already
        require(!isOracleService(claimant), 'ONEC'); //Oracle service cannot claim its own rewards;
		require(outcomes.length == snapshotIds.length, 'OSDNE');//More votes outcomes than snapshot ids or vice versa
        ClaimData memory claimData = ClaimData(0,0,0);
        bool[2] memory signConditions;
        bytes32 hash = keccak256(abi.encode(claimant, votesPerOutcome, outcomes, snapshotIds));
        for(uint256 i=0; i < signatures.length; i++) {
            address signer = signatures[i].verifyMessage(hash);

            if(signer == claimant) {
                signConditions[0] = true;
                continue;
            }

            if( isOracleService(signer) ) {
                signConditions[1] = true;
                continue;
            }
        }

        require(signConditions[0] && signConditions[1], 'SMDNE');//You need a signed message from the claimant and oracle

        for(uint i = 0; i < snapshotIds.length; i++) {

			for(uint8 outcomeBit = 0; outcomeBit < 64; outcomeBit++) {
				uint64 bitResult = (outcomes[i] >> outcomeBit) & uint64(1);

				if(bitResult != uint64(1)) {
					continue;
				}

                if(snapshotIds[i] != snapshotId) {
                    claimData.lastOutcomeVote += 1;
                    continue;
                }

                claimData.totalVoteAtSnapshot += votesPerOutcome[claimData.lastOutcomeVote];

				uint64 matchResult = (eventOutcome >> outcomeBit) & uint64(1);

				if((matchResult & bitResult) == uint64(0)) {
		 		    claimData.lastOutcomeVote += 1;
					continue;
				}
				
		        claimData.totalOwedRewards += calculatePlayerRewards(outcomeBit, votesPerOutcome[claimData.lastOutcomeVote]);
		 		claimData.lastOutcomeVote += 1;
			}
		   require(claimData.totalVoteAtSnapshot <= token.balanceOfAt(claimant, snapshotIds[i]), "TVBE"); //Total vote balance exceeds balance at snapshot
           claimData.totalVoteAtSnapshot = 0;
		}
        token.transferFrom(pool, claimant, claimData.totalOwedRewards);
        addressHasClaimed[claimant] = true;
        return claimData.totalOwedRewards;
   }
}