// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IGrade24.sol";
import "./IHorseNFT.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract Grade24 is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, AccessControlUpgradeable, IGrade24 {
	
	enum roundStatus{ PENDING, PROCESSING, ENDED }
	
	bytes public constant SIGN_PREFIX = "\x19Ethereum Signed Message:\n32";
	bytes32 public constant AUTH_ROLE = keccak256("AUTH_ROLE");
    using SafeERC20Upgradeable for IERC20Upgradeable;
	
	IERC20Upgradeable public mbtc; //reward token
	
	struct Member {
        uint256 round;
		uint256 tzedakahRound;
		address parent;		
		address[] children;
		uint256[] myClaims; //round => grade

		/*P1 = ticket*/
		int256 ownP1;      
		int256 directP1; 
		int256 groupP1; 
		int256 levelTwoP1;
		
		/*P2 = breed*/
		int256 ownP2;      
		int256 directP2; 
		int256 groupP2;  //not in use
		int256 levelTwoP2;
    }
	
	mapping(address => Member) public members;
	
	struct Round{
		bool active;
		
		int256 totalP1;
		int256 totalP2;
		int256 totalP3;
		
		//important
		uint256[24] normalNumPerGrade;
		uint256[24] tzedakahNumPerGrade;
		uint256[24] normalDists;
		uint256[24] tzedakahDists;
		
		roundStatus status;
	}
	
	mapping(uint256 => Round) public rounds;
	uint256 public lastRound;
	address public horseSalesContract;
	address public root;
	uint256 public withdrawalFee;
	uint256 public totalFees; //company collected fee
	uint256 public maxDirects;
	
	modifier onlyValidCaller {
		require(msg.sender == horseSalesContract || msg.sender == address(this));
		_;
	}
	
	modifier onlyIfGranted( uint8 v, bytes32 r, bytes32 s, bytes32 hashMsg ) {
		address recoveredSigner = ecrecover(keccak256(abi.encodePacked(SIGN_PREFIX, hashMsg)), v, r, s);
		require(hasRole(AUTH_ROLE, recoveredSigner), "unauthorized");
		_;
	}
	
    function initialize(IERC20Upgradeable _mbtc, address _root, address authorizer, uint256 _withdrawalFee ) public initializer {
	
        __Ownable_init();
		__ReentrancyGuard_init();
		__AccessControl_init();
		
		root = _root;
		mbtc = _mbtc;
		
		_setupRole(AUTH_ROLE, authorizer);
		
		lastRound = 1;
		
		Member storage member = members[root];
		member.parent = address(0);
		member.round = lastRound;
		
		emit registered(root, member.parent);
		
		rounds[lastRound].active = true;
		
		withdrawalFee = _withdrawalFee;
		
		maxDirects = 10;
		
    }
	
	function getMemberArrayFields(address who) public view returns(address[] memory children, uint256[] memory myClaims) {
		Member storage member = members[who];
		return (member.children, member.myClaims);
	}
	
	function getRoundArrayFields(uint256 which) public view returns(uint256[24] memory normalNumPerGrade, uint256[24] memory tzedakahNumPerGrade, uint256[24] memory normalDists, uint256[24] memory tzedakahDists) {
		Round storage round = rounds[which];
		return (round.normalNumPerGrade, round.tzedakahNumPerGrade, round.normalDists , round.tzedakahDists);
	}
	
	function becomeTzedakah(address[] calldata _members, uint8 action) public onlyOwner {
		require(action >= 1 && action <= 2, "invalid action");
				
		for(uint256 i; i < _members.length; i++){
			address target = _members[i];
			Member storage member = members[target];
			require(member.round > 0,"not registered");
			require(member.tzedakahRound == 0, "already tredakahed");
			
            if (action == 1) {//add
				member.tzedakahRound = lastRound;
			} else { //remove
				member.tzedakahRound = 0;
			}
        }
	}
	
	function emergencyCollectToken(address token, uint amount) public onlyOwner {
        IERC20Upgradeable(token).transfer(owner(), amount);
    }
	
	function setMaxDirects(uint256 _maxDirects) public onlyOwner {
        maxDirects = _maxDirects;
    }
	
	function setWithdrawalFee(uint256 _withdrawalFee) public onlyOwner {
        withdrawalFee = _withdrawalFee;
    }
	
	function setHorseSalesContract(address _horseSalesContract) public onlyOwner {
        horseSalesContract = _horseSalesContract;
    }
	
	function registerExt(address from, address myParent) external onlyValidCaller {
		address referrer = (myParent == address(0) ? root : myParent);
		_register(from, referrer);
	}
	
	function registerByOwner(address from, address myParent) public onlyOwner{
		_register(from, myParent);
	}
	
	function register(address myParent) public {
		_register(msg.sender,myParent);
	}
	
	function isRegistered(address from) external view returns (bool) {
		Member storage member = members[from];
		return member.round > 0;
	}
	
	function _register(address from, address myParent) private{
	
		Member storage member = members[from];
		Member storage parent  = members[myParent];
		
		require(parent.round > 0, "parent not exists");
		if (myParent != root) {
			require(parent.children.length + 1 <= maxDirects, "too many referees");
		}
		require(member.round == 0, "member exists");
		
		member.parent = myParent;
		member.round = lastRound;
		
		parent.children.push(from);
		
		emit registered(from, myParent);
		
	}
	
	function _sumP(Member storage member) private view returns(int256) {
		return member.ownP1 + member.directP1 + member.groupP1 + member.levelTwoP1 + member.ownP2 + member.directP2 + member.groupP2 + member.levelTwoP2;
	}
	
	 function calcWithdrawalFee(uint256 amount) private view returns (uint256) {
        return (amount * withdrawalFee) / (10**2);
    }
	
	function updateTicketP(address from, int256 qty) external onlyValidCaller {
		Member storage fromMember = members[from];
		int256 totalP1;
		
		if (fromMember.round > 0 && from != root) {
			fromMember.ownP1 += qty;
			totalP1 += qty;
			
			emit updateP(from, from, lastRound, _sumP(fromMember), uint8(1));
			
			Member storage fromMemberParent = members[fromMember.parent];
			
			if (fromMemberParent.round > 0 && fromMember.parent != root) {
				fromMemberParent.directP1 += qty;
				totalP1 += qty;
				
				totalP1 -= fromMemberParent.groupP1;
				fromMemberParent.groupP1 = (fromMemberParent.directP1 >= int256(1) ? fromMemberParent.directP1 - int256(1) : int256(0));
				totalP1 += fromMemberParent.groupP1;
				
				emit updateP(from, fromMember.parent, lastRound, _sumP(fromMemberParent), uint8(1));
				
				Member storage fromMemberGrandParent = members[fromMemberParent.parent];
				
				if (fromMemberGrandParent.round> 0 && fromMemberParent.parent != root) {
				
					int256 highestP1 = 0;
					int256 addlevelTwoP1 = 0;
					int256 deductlevelTwoP1 = 0;
					
					totalP1 -= fromMemberGrandParent.levelTwoP1;
					
					//recalculate for grandparent's levelTwoP1
					uint256 i;
					uint256 qualified;
					
					for(i=0; i< fromMemberGrandParent.children.length;i++) {
					
						Member storage thisChild = members[ fromMemberGrandParent.children[i] ];
						
						if (thisChild.round > 0) {
							if (thisChild.directP1 > 0) {
								qualified++;
								if (thisChild.directP1 > highestP1) {
									deductlevelTwoP1 = thisChild.directP1;
									highestP1 = thisChild.directP1;
								} 
							}
							
							addlevelTwoP1 += thisChild.directP1;
						}
					}
					
					if (qualified == 1) {
						fromMemberGrandParent.levelTwoP1 = addlevelTwoP1;
					} else {
						fromMemberGrandParent.levelTwoP1 = addlevelTwoP1 - deductlevelTwoP1;
					}
					
					totalP1 += fromMemberGrandParent.levelTwoP1;
					
					emit updateP(from, fromMemberParent.parent, lastRound, _sumP(fromMemberGrandParent), uint8(1));
				}
			}
			
			rounds[lastRound].totalP1 += totalP1;
		}
	}
	
	function updateBreedP(address from, int256 qty) external onlyValidCaller {
		Member storage fromMember = members[from];
		int256 totalP2;
		
		if (fromMember.round > 0 && from != root) {
			fromMember.ownP2 += qty;
			totalP2 += qty;
			
			emit updateP(from, from, lastRound, _sumP(fromMember), uint8(2));
			
			Member storage fromMemberParent = members[fromMember.parent];
			
			if (fromMemberParent.round > 0 && fromMember.parent != root) {
				fromMemberParent.directP2 += qty;
				totalP2 += qty;
				
				emit updateP(from, fromMember.parent, lastRound, _sumP(fromMemberParent), uint8(2));
				
				Member storage fromMemberGrandParent = members[fromMemberParent.parent];
				
				if (fromMemberGrandParent.round > 0 && fromMemberParent.parent != root) {
				
					int256 highestP2 = 0;
					int256 addlevelTwoP2 = 0;
					int256 deductlevelTwoP2 = 0;
					
					totalP2 -= fromMemberGrandParent.levelTwoP2;
					
					//recalculate for grandparent's levelTwoP2
					uint256 i;
					uint256 qualified;
					for(i=0; i< fromMemberGrandParent.children.length;i++) {
					
						Member storage thisChild = members[ fromMemberGrandParent.children[i] ];
						
						if (thisChild.round > 0) {
							if (thisChild.directP2 > 0) {
								qualified++;
								if (thisChild.directP2 > highestP2) {
									deductlevelTwoP2 = thisChild.directP2;
									highestP2 = thisChild.directP2;
								} 
							}
							addlevelTwoP2 += thisChild.directP2;
						}
					}
					
					if (qualified == 1) {
						fromMemberGrandParent.levelTwoP2 = addlevelTwoP2;
					} else {
						fromMemberGrandParent.levelTwoP2 = addlevelTwoP2 - deductlevelTwoP2;
					}
					
					totalP2 += fromMemberGrandParent.levelTwoP2;
					
					emit updateP(from, fromMemberParent.parent, lastRound, _sumP(fromMemberGrandParent), uint8(2));
				}
			}
			
			rounds[lastRound].totalP2 += totalP2;
		} 
	}
	
	function processRound() public onlyOwner {
	
		require(rounds[lastRound].status==roundStatus.PENDING, "round not pending");
		
		if (lastRound > 1) {
			Round storage lastTwoRound = rounds[lastRound - 1];
			require(lastTwoRound.status ==roundStatus.ENDED, "last 2 round not ended");
		}

		int256 lastTotalP1 = rounds[lastRound].totalP1;
		int256 lastTotalP2 = rounds[lastRound].totalP2;
		
		rounds[lastRound].status = roundStatus.PROCESSING;
		
		uint256 newRound = lastRound + 1;
		
		rounds[newRound].active = true;
		rounds[newRound].totalP1 = lastTotalP1;
		rounds[newRound].totalP2 = lastTotalP2;
		
		lastRound = newRound;
	}
	
	function endRound(int256 _totalP3, uint256[24] memory _normalNumPerGrade, uint256[24] memory _tzedakahNumPerGrade, uint256[24] memory _normalDists, uint256[24] memory _tzedakahDists) public onlyOwner {
	
		uint256 lastTwoRound = lastRound - 1;
		
		require(rounds[lastTwoRound].status==roundStatus.PROCESSING, "round not processing");
		
		//check _normalNumPerGrade
		if (lastTwoRound > 1) {
			Round storage lastThreeRound = rounds[lastTwoRound - 1];
			
			for(uint256 i=0; i < _normalNumPerGrade.length; i++) {
				require(_normalNumPerGrade[i] >= lastThreeRound.normalNumPerGrade[i], "invalid normal num per grade");
				require(_tzedakahNumPerGrade[i] >= lastThreeRound.tzedakahNumPerGrade[i], "invalid tzedakah num per grade");
			}
		}
		
		rounds[lastTwoRound].normalNumPerGrade = _normalNumPerGrade;
		rounds[lastTwoRound].tzedakahNumPerGrade = _tzedakahNumPerGrade;
		rounds[lastTwoRound].normalDists = _normalDists;
		rounds[lastTwoRound].tzedakahDists = _tzedakahDists;
		rounds[lastTwoRound].totalP3 = _totalP3;
		rounds[lastTwoRound].status = roundStatus.ENDED;
	}
	
	function getMaxClaimRound() public view returns (uint256) {
		uint256 maxClaimRound;
		for(uint256 claimRound = lastRound - 1; claimRound > 0; claimRound--) {
			Round storage thisRound = rounds[claimRound];
			
			if (thisRound.status == roundStatus.ENDED) {
				maxClaimRound = claimRound;
				break;
			}
		}
		
		return maxClaimRound;
	}
	
	function pendingRewards(uint256[] memory myRounds, uint256[] memory myGrades) public view returns(uint256) {
		Member storage member = members[msg.sender];
		require(member.round > 0, "member not exists");
		
		uint256 maxClaimRound = getMaxClaimRound();
		require(maxClaimRound > 0, "no round to claim");
		
		uint256 lastClaimRound = member.myClaims.length;		
		require(lastClaimRound < maxClaimRound, "nothing to claim");
		
		//check myRounds
		require(myRounds.length == maxClaimRound-lastClaimRound, "invalid myRounds");
		
		//check myGrades
		require(myGrades.length == myRounds.length, "invalid myGrades");
		
		uint256 myLastGrade = lastClaimRound > 0 ? member.myClaims[ lastClaimRound - 1 ]: 0;
		
		for(uint256 i=0;i<myGrades.length;i++) {
			require(myGrades[i] >= myLastGrade, "invalid myGrades 2");
			myLastGrade = myGrades[i];
		}

		uint256 normalRewards;
		uint256 tzedakahRewards;
		uint256 k;
		for(uint256 toClaimRound=lastClaimRound+1; toClaimRound<= maxClaimRound; toClaimRound++) {
			
			uint256 myGrade = myGrades[k];
			uint256 myRound = myRounds[k];
			
			require(myRound == toClaimRound, "invalid myRounds 2");
			
			Round storage thisRound = rounds[toClaimRound];
			
			uint256 normalReward;
			uint256 tzedakahReward;
			for(uint256 j=myGrade; j>0; j--) {
				uint256 arrayIdx = j - 1;
				normalReward += thisRound.normalDists[arrayIdx] / thisRound.normalNumPerGrade[arrayIdx];
				if ( member.tzedakahRound > 0 && myRound >= member.tzedakahRound) {
					tzedakahReward += thisRound.tzedakahDists[arrayIdx] / thisRound.tzedakahNumPerGrade[arrayIdx];
				}
			}
			
			normalRewards += normalReward;
			tzedakahRewards += tzedakahReward;
			
			k++;
		}
		
		uint256 totalRewards = normalRewards + tzedakahRewards;
		uint256 fee = calcWithdrawalFee(totalRewards);
		totalRewards -= fee;
		
		return totalRewards;
	}
	
	function claim( uint256[] memory myRounds, uint256[] memory myGrades, uint256 timestamp, uint8 v, bytes32 r, bytes32 s) public nonReentrant onlyIfGranted(v, r, s, keccak256(abi.encodePacked(this, msg.sender, timestamp))){
		require(timestamp >= block.timestamp, "expired");
		
		Member storage member = members[msg.sender];
		require(member.round > 0, "member not exists");
		
		uint256 maxClaimRound = getMaxClaimRound();
		require(maxClaimRound > 0, "no round to claim");
		
		uint256 lastClaimRound = member.myClaims.length;		
		require(lastClaimRound < maxClaimRound, "nothing to claim");
		
		//check myRounds
		require(myRounds.length == maxClaimRound-lastClaimRound, "invalid myRounds");
		
		//check myGrades
		require(myGrades.length == myRounds.length, "invalid myGrades");
		
		uint256 myLastGrade = lastClaimRound > 0 ? member.myClaims[ lastClaimRound - 1 ]: 0;
		
		for(uint256 i=0;i<myGrades.length;i++) {
			require(myGrades[i] >= myLastGrade, "invalid myGrades 2");
			myLastGrade = myGrades[i];
		}

		uint256 normalRewards;
		uint256 tzedakahRewards;
		uint256 k;
		for(uint256 toClaimRound=lastClaimRound+1; toClaimRound<= maxClaimRound; toClaimRound++) {
			
			uint256 myGrade = myGrades[k];
			uint256 myRound = myRounds[k];
			
			require(myRound == toClaimRound, "invalid myRounds 2");
			
			Round storage thisRound = rounds[toClaimRound];
			
			uint256 normalReward;
			uint256 tzedakahReward;
			for(uint256 j=myGrade; j>0; j--) {
				uint256 arrayIdx = j - 1;
				normalReward += thisRound.normalDists[arrayIdx] / thisRound.normalNumPerGrade[arrayIdx];
				if (member.tzedakahRound > 0 && myRound >= member.tzedakahRound) {
					tzedakahReward += thisRound.tzedakahDists[arrayIdx] / thisRound.tzedakahNumPerGrade[arrayIdx];
				}
			}
			
			normalRewards += normalReward;
			tzedakahRewards += tzedakahReward;
			
			emit rewarded(msg.sender, myRound, myGrade, normalReward, tzedakahReward);
			member.myClaims.push(myGrade);
			
			k++;
		}
		
		uint256 totalRewards = normalRewards + tzedakahRewards;
		uint256 fee = calcWithdrawalFee(totalRewards);
		totalRewards -= fee;
		
		totalFees += fee;
		if (totalRewards > 0) {
			mbtc.safeTransfer(msg.sender, totalRewards);
		}
	}
	
	function version() public pure returns (string memory) {
		return "1.0";
	}
	
	receive() external payable{
		revert();
	}
	
	fallback() external payable{
		revert();
	}
}