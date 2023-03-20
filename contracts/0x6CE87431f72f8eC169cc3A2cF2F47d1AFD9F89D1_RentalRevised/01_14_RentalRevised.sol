pragma solidity ^0.8.5;

import "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./IRLand.sol";

contract RentalRevised is Initializable, ReentrancyGuardUpgradeable {

    using Strings for uint256;
    struct Deposite {
        uint256[] _landId;
        uint256 _lordId;
        uint256[] _landCatorgy;
        uint256 _lordCatory;
    }

    struct corrdinate {
        uint256[] land1;
        uint256[] land2;
        uint256[] land3;
    }

    struct lordsInfo{
        address lordOwner;
        uint96 weightage;
        uint256[] landIds;
    }

    struct landlord {
        uint256 landId;
        uint256[] lordIds;
    }


    IERC721AUpgradeable public lordNFT;
    IRLand public landNFT;
    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 private rewardsDuration;
    uint256 private  lastUpdateTime;
    uint256 private rewardPerTokenStored;
    bytes32 private rootLand;
    bytes32 private rootLord;
    address public owner;

    uint256[] private landWeight;

    mapping(address => uint256) private userRewardPerTokenPaid;
    mapping(address => uint256) private rewards;

    uint256 private totalWeightage;
    mapping(address => uint256) private userWeightage;
    mapping(uint256 =>lordsInfo) private lordOwnerIDs;

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        address _owner,
        address _landContract,
        address _lordContract,
        bytes32 _rootLand,
        bytes32 _rootLord,
        uint256[] calldata _landWeight
    ) external initializer {
        owner = _owner;
        rootLand = _rootLand;
        rootLord = _rootLord;
        lordNFT = IERC721AUpgradeable(_lordContract);
        landNFT = IRLand(_landContract);
        landWeight=_landWeight;

    }

    /* ========== VIEW FUNCTION ========== */

    function totalSupply() external view returns (uint256) {
        return totalWeightage;
    }

    function userPoolPercentage(address account) external view returns (uint256) {
        return userWeightage[account]*1000000/totalWeightage;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function rewardPerUnitWeight() public view returns (uint256) {
        if (totalWeightage == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored+((
                (lastTimeRewardApplicable()-lastUpdateTime)*rewardRate*1e18)/totalWeightage
            );
    }

    function earned(address account) public view returns (uint256) {
        return userWeightage[account]*(rewardPerUnitWeight()-(userRewardPerTokenPaid[account]))/(1e18)+(rewards[account]);
    }

   /* ==========  
   
        This should only be used as a view function to read data from front end
        Not to be called inside any function
        High gas fees

    ========== */

  

    function landlords(address _lordOwner) external view returns(landlord[] memory ) {
        uint256 totalSupplyLords=IERC721AUpgradeable(lordNFT).totalSupply();
        
        uint256 total;
        uint256 count;
        for(uint256 i;i<totalSupplyLords;) {
            if(lordOwnerIDs[i].lordOwner==_lordOwner)
                total++;
                unchecked {
                    i++;
                }
        }
        landlord[] memory lordIds=new landlord[](total);
        for(uint256 i;i<totalSupplyLords;) {
            if(lordOwnerIDs[i].lordOwner==_lordOwner){
                lordIds[count++]=landlord(i,lordOwnerIDs[i].landIds);
            }
                unchecked {
                    i++;
                }
        }
        return lordIds;


    }

    function viewLandWeight() external view returns(uint256[] memory) {
        return landWeight;
    }


    function getRewardForDuration() external view returns (uint256) {
        return rewardRate*(rewardsDuration);
    }

    /* ========== SUPPORT FUNCTIONS ========== */

    function lordProof(
        uint256 _lordId,
        uint256 _lordCatory,
        bytes32[] memory _merkleProoflord
    ) 
    internal 
    view 
     {
        bytes32 leafToCheck = keccak256(
            abi.encodePacked(_lordId.toString(), ",", _lordCatory.toString())
        );
        require(
            MerkleProofUpgradeable.verify(
                _merkleProoflord,
                rootLord,
                leafToCheck
            ),
            "Incorrect lord proof"
        );

        
        
    }

    function merkelProof(
        uint256 x,
        uint256 y,
        uint256 _landCatorgy,
        bytes32[] memory _merkleProofland
    ) 
    internal 
    view 
    {
        bytes32 leafToCheck = keccak256(
            abi.encodePacked(
                x.toString(),
                ",",
                y.toString(),
                ",",
                _landCatorgy.toString()
            )
        );
        require(
            MerkleProofUpgradeable.verify(
                _merkleProofland,
                rootLand,
                leafToCheck
            ),
            "Incorrect land proof"
        );
    }

    function setRootLand(bytes32 _rootLand) external nonReentrant onlyOwner {
        rootLand = _rootLand;
    }

    function setRootLord(bytes32 _rootLord) external nonReentrant onlyOwner {
        rootLord = _rootLord;
    }

    function setLandWeight(uint256[] calldata _landWeight) external nonReentrant onlyOwner {
        landWeight = _landWeight;
    }

    function min(
        uint256 a,
        uint256 b
        ) 
        internal 
        pure 
        returns (uint256) 
        {
        return a>=b?b:a;
    }

    function landProof(
        corrdinate memory cordinate,
        uint256[] memory _landId,
        uint256[] memory _landCatorgy,
        uint256 _lordCategory,
        bytes32[] memory _merkleProofland1,
        bytes32[] memory _merkleProofland2,
        bytes32[] memory _merkleProofland3
    ) 
    internal 
    view 
    {
        if (min(_landId.length,_lordCategory) == 1) {
            require(
                IRLand(landNFT).getTokenId(
                    cordinate.land1[0],
                    cordinate.land1[1]
                ) == _landId[0],
                "Incorrect LandID"
            );
            merkelProof(
                cordinate.land1[0],
                cordinate.land1[1],
                _landCatorgy[0],
                _merkleProofland1
            );
        

        } else if (min(_landId.length,_lordCategory) == 2) {
             require(
                IRLand(landNFT).getTokenId(
                    cordinate.land1[0],
                    cordinate.land1[1]
                ) == _landId[0],
                "Incorrect LandID"
            );
            require(
                IRLand(landNFT).getTokenId(
                    cordinate.land2[0],
                    cordinate.land2[1]
                ) == _landId[1],
                "Incorrect LandID"
            );

            merkelProof(
                cordinate.land1[0],
                cordinate.land1[1],
                _landCatorgy[0],
                _merkleProofland1
            );
            merkelProof(
                cordinate.land2[0],
                cordinate.land2[1],
                _landCatorgy[1],
                _merkleProofland2
            );

        } else if (min(_landId.length,_lordCategory) == 3) {
             require(
                IRLand(landNFT).getTokenId(
                    cordinate.land1[0],
                    cordinate.land1[1]
                ) == _landId[0],
                "Incorrect LandID"
            );
            require(
                IRLand(landNFT).getTokenId(
                    cordinate.land2[0],
                    cordinate.land2[1]
                ) == _landId[1],
                "Incorrect LandID"
            );
            require(
                IRLand(landNFT).getTokenId(
                    cordinate.land3[0],
                    cordinate.land3[1]
                ) == _landId[2],
                "Incorrect LandID"
            );

            merkelProof(
                cordinate.land1[0],
                cordinate.land1[1],
                _landCatorgy[0],
                _merkleProofland1
            );
            merkelProof(
                cordinate.land2[0],
                cordinate.land2[1],
                _landCatorgy[1],
                _merkleProofland2
            );
            merkelProof(
                cordinate.land3[0],
                cordinate.land3[1],
                _landCatorgy[2],
                _merkleProofland3
            );
        }
    }

    /* ========== USER LEVEL FUNCTIONS ========== */
    
    function stake(Deposite memory deposite,
        corrdinate memory cordinate,
        bytes32[] memory _merkleProofland1,
        bytes32[] memory _merkleProofland2,
        bytes32[] memory _merkleProofland3,
        bytes32[] memory _merkleProoflord
        ) 
        external 
        nonReentrant 
        updateReward(msg.sender)
        {
            landProof(
            cordinate,
            deposite._landId,
            deposite._landCatorgy,
            deposite._lordCatory,
            _merkleProofland1,
            _merkleProofland2,
            _merkleProofland3
             );
            lordProof(deposite._lordId, deposite._lordCatory, _merkleProoflord);
            IERC721AUpgradeable(lordNFT).transferFrom(msg.sender, address(this) , deposite._lordId);
            uint256 totalWeight;
            uint256 minAmount=min(deposite._landId.length,deposite._lordCatory);
            for(uint256 i;i<minAmount;){
                IRLand(landNFT).transferFrom(msg.sender, address(this) , deposite._landId[i]); 
                totalWeight+=landWeight[deposite._landCatorgy[i]-1];
                unchecked {
                            i++;
                        }
            }
            totalWeightage+=totalWeight;
            userWeightage[msg.sender]+= totalWeight;
            lordOwnerIDs[deposite._lordId]=lordsInfo(msg.sender,uint96(totalWeight),deposite._landId);
        emit Staked(msg.sender, deposite._lordId);
    }

    function withdraw(
        uint256 _lordID) 
        external  
        nonReentrant 
        updateReward(msg.sender) 
        {
            lordsInfo storage currentLord=lordOwnerIDs[_lordID];
            require(currentLord.lordOwner==msg.sender,"Not The Owner");
            uint256 reward = rewards[msg.sender];
            totalWeightage-=currentLord.weightage;
            userWeightage[msg.sender]-= currentLord.weightage;
            IERC721AUpgradeable(lordNFT).transferFrom(address(this) , msg.sender, _lordID);
            for(uint256 i;i<currentLord.landIds.length;){
            IRLand(landNFT).transferFrom(address(this) , msg.sender, currentLord.landIds[i]);
            unchecked {
                        i++;
                    } 
            }
            delete lordOwnerIDs[_lordID];
            if (reward > 0) {
                rewards[msg.sender] = 0;
            (bool success, ) = payable(msg.sender).call{value: reward}("");
                require(success, "refund failed");
                emit RewardPaid(msg.sender, reward);
            }

        emit Withdrawn(msg.sender, _lordID);
    }

    function getReward() external nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            (bool success, ) = payable(msg.sender).call{value: reward}("");
            require(success, "refund failed");
            emit RewardPaid(msg.sender, reward);
        }
    }

  
    /* ========== RESTRICTED FUNCTIONS ========== */


    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
        emit UpdateOwner(msg.sender, owner);
    }

    function getBackUnclaimedReward(
        uint256 reward
        ) 
        external 
        onlyOwner 
        {

        (bool success, ) = payable(msg.sender).call{value: reward}("");
        require(success, "refund failed");

    }

    function stopRewardEmission() 
        external 
        onlyOwner 
        updateReward(address(0)) 
        {
        require (block.timestamp < periodFinish,"Pool Expired");
            uint256 remaining = periodFinish-block.timestamp;
            uint256 leftover = remaining*rewardRate;
            rewardRate = 0;
            lastUpdateTime = block.timestamp;
            periodFinish = block.timestamp;        
            rewardsDuration = 0;
            (bool success, ) = payable(msg.sender).call{value: leftover}("");
            require(success, "refund failed");
        emit RewardRemoved(leftover,remaining);
    }


    function notifyRewardAmount(
        uint256 reward,
        uint256 _rewardsDuration
        ) 
        external 
        payable 
        onlyOwner 
        updateReward(address(0)) 
        {
            require(msg.value==reward,"Send exact ETH!!!");
            if (block.timestamp >= periodFinish) {
                rewardRate = reward/_rewardsDuration;
            } else {
                uint256 remaining = periodFinish-block.timestamp;
                uint256 leftover = remaining*rewardRate;
                rewardRate = (reward+leftover)/_rewardsDuration;
            }

            lastUpdateTime = block.timestamp;
            periodFinish = block.timestamp+_rewardsDuration;        
            rewardsDuration = _rewardsDuration;
        emit RewardAdded(reward,_rewardsDuration);
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }




    /* ========== MODIFIERS ========== */

    modifier onlyOwner() {
        require(owner == msg.sender, "not owner");
        _;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerUnitWeight();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }



    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward, uint256 duration);
    event RewardRemoved(uint256 reward, uint256 duration);
    event Staked(address indexed user, uint256 lordId);
    event Withdrawn(address indexed user, uint256 lordId);
    event RewardPaid(address indexed user, uint256 reward);    
    event UpdateOwner(address indexed oldOwner, address newOwner);
}