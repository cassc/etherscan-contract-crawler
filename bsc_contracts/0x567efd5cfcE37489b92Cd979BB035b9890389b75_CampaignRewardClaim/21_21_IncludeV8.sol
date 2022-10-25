// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./IncludeV8.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

contract CampaignRewardClaim is Configurable {
    //using Address for address;
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    struct RoundInfo{
        bytes32 root;
        uint begin;
        uint end;
        uint claimedVol;
    }
   

    address public rewardToken;
    address public mine;
    mapping (uint => RoundInfo) public roundInfos; //round =>roots
	mapping (uint => mapping (address => bool)) public claimed; //round =>user=>claimed
	

	
    uint private _entered;
    modifier nonReentrant {
        require(_entered == 0, "reentrant");
        _entered = 1;
        _;
        _entered = 0;
    }


    function __CampaignRewardClaim_init(address governor_,address rewardToken_,address mine_) public initializer {
        __Governable_init_unchained(governor_);
        __CampaignRewardClaim_init_unchained(rewardToken_,mine_);
    }

    function __CampaignRewardClaim_init_unchained(address rewardToken_,address mine_) internal governance onlyInitializing{
        rewardToken = rewardToken_;
        mine = mine_;
    }

 
    function setMerkleRoot(uint round,bytes32 root_) external governance {
	    roundInfos[round].root = root_;
    }

    function setBeginEnd(uint round,uint begin_,uint end_) external governance {
	    roundInfos[round].begin = begin_;
        roundInfos[round].end = end_;
    }

    function setRoundInfo(uint round,bytes32 root_,uint begin_,uint end_) external governance {
        roundInfos[round].root = root_;
	    roundInfos[round].begin = begin_;
        roundInfos[round].end = end_;
    }


	function claim(uint round,uint vol,bytes32[] calldata _merkleProof) public nonReentrant {
        require(block.timestamp>=roundInfos[round].begin,"not begin");
        require(block.timestamp<=roundInfos[round].end,"end");
        require(!claimed[round][msg.sender],"claimed!");
        claimed[round][msg.sender] = true;
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender,vol));
        require(MerkleProofUpgradeable.verify(_merkleProof, roundInfos[round].root, leaf),"Invalid Proof." );
		IERC20(rewardToken).safeTransferFrom(mine,msg.sender,vol);
        roundInfos[round].claimedVol += vol;
		emit Claim(round,msg.sender,vol);
	
	}
	event Claim(uint indexed round,address indexed user,uint vol);
	
	function claims(uint[] calldata rounds,uint[] calldata vols,bytes32[][] calldata _merkleProofs) public {
        require(rounds.length == vols.length && _merkleProofs.length == vols.length,"length diff");
		for (uint i=0;i<rounds.length;i++){
		    claim(rounds[i],vols[i],_merkleProofs[i]);
		}
	}

    /*function proof(bytes32[][] calldata _merkleProofs) public pure returns(uint,bytes32[] memory,bytes32[] memory ){
         return (_merkleProofs.length,_merkleProofs[0],_merkleProofs[1]);
    }*/

}