// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "hardhat/console.sol";

interface ITribeManager {
     function safeStakeKong(
        address staker,
        uint256 akcId,
        bool isOmega
    ) external;
    function safeUnstakeKong(
        address staker,
        uint256 akcId, 
        bool isOmega
    ) external;
}

interface IOmega is IERC721 {
    function totalSupply() external view returns (uint256);
}

contract AKCRarityStakingUpgradeable is OwnableUpgradeable {
    /**
     * @dev Addresses
     */
    IERC721 public akc;
    IOmega public omega;
    ITribeManager public manager;

    /**
     * @dev Staking Logic
     */

    /// @dev maps Kong ID to staker
    mapping(uint256 => address) public kongToStaker;

    /// @dev maps Omega Kong ID to staker
    mapping(uint256 => address) public omegaToStaker;
     
    /// @dev Save staking data in a single uint256
    /// - first 32 bits are the timestamp
    /// - second 16 bits are staked kongs amount
    /// - second 104 bits are the earnings amount
    /// - third 104 bits are the pending bonus
    mapping(address => uint256) public userToStakeData;
    mapping(address => uint256) public userToTotalEarned;

    bytes32 public rarityMerkleRoot;

    /**
     * @dev Modifiers
     */
    modifier onlyManager() {
        require(msg.sender == address(manager) || msg.sender == owner(), "Sender not authorized");
        _;
    }

    constructor(
        address _akc,
        address _omega,
        address _manager
    ) {
    }

     function initialize(
        address _akc,
        address _omega,
        address _manager
    ) public initializer {
        __Ownable_init();

        akc = IERC721(_akc);
        omega = IOmega(_omega);
        manager = ITribeManager(_manager);
    }


    /** === Stake Logic === */

    /**
     * @dev Get pending from last stake / claim
     * to block.timestamp
     */
    function _getPendingReward(address staker)
        internal
        view
        returns (uint256) {
            uint256 stakeData = userToStakeData[staker];
            uint256 currentEarnings = _getEarningsFromStakeData(stakeData);
            uint256 lastTimeStamp = _getStakeTimeStampFromStakeData(stakeData);
 
            uint256 pendingReward = (block.timestamp - lastTimeStamp) * currentEarnings / 86400;
            return pendingReward;
        }

    /**
     * @dev Returns pending bonus
     * and resets stake data with current time
     * and zero bonus.
     */
    function liquidateBonus(address staker)
        external
        onlyManager
        returns (uint256) {
            uint256 stakeData = userToStakeData[staker];
            if (stakeData == 0) {
                return 0;
            }
            
            uint256 currentEarnings = _getEarningsFromStakeData(stakeData);
            uint256 currentAmount = _getAmountFromStakeData(stakeData);
            uint256 accumulatedBonus = _getAccumulatedEarningsFromStakeData(stakeData);
            uint256 pendingReward = _getPendingReward(staker);
            
            userToStakeData[staker] = _getUpdatedStakeData(block.timestamp, currentAmount, currentEarnings, 0);
            userToTotalEarned[staker] += accumulatedBonus + pendingReward;
            
            return accumulatedBonus + pendingReward;
        }

    /**
     * @dev Stakes a new kong
     * gets pending bonus based on previous amount
     * and adds it to accumulated bonus
     */
    function stake(
        address staker, 
        uint256 kongId, 
        uint256 additionalEarnings, 
        bool isOmega, 
        bytes32[] memory proof
    ) internal {
            if (isOmega)  {
                require(omegaToStaker[kongId] == address(0), "Omega Kong already staked");
                require(omega.ownerOf(kongId) == address(this), "Omega Kong not in custody");
                omegaToStaker[kongId] = staker;
            } else {
                require(kongToStaker[kongId] == address(0), "Kong already staked");
                require(akc.ownerOf(kongId) == address(this), "Kong not in custody");
                kongToStaker[kongId] = staker;
            }

            bytes32 leaf = keccak256(abi.encodePacked(kongId, isOmega ? true : false, additionalEarnings));
            require(MerkleProof.verify(proof, rarityMerkleRoot, leaf), "Rarity merkle proof invalid");

            uint256 stakeData = userToStakeData[staker];
            uint256 currentAmount = _getAmountFromStakeData(stakeData);
            uint256 currentEarnings = _getEarningsFromStakeData(stakeData); 
            uint256 accumulatedBonus = _getAccumulatedEarningsFromStakeData(stakeData);
            uint256 pendingBonus =  stakeData == 0 ? 0 : _getPendingReward(staker);    

            userToStakeData[staker] = _getUpdatedStakeData(block.timestamp, currentAmount + 1, currentEarnings + additionalEarnings, accumulatedBonus + pendingBonus);
        }

     /**
      * @dev Unstakes a kong
      * gets pending bonus based on previous amount
      * and adds it to accumulated bonus
      */
    function unstake(
        address staker, 
        uint256 kongId,
        uint256 additionalEarnings,        
        bool isOmega, 
        bytes32[] memory proof
    ) internal {
            if (isOmega) {
                address stakerOfOmegaKong = omegaToStaker[kongId];
                require(stakerOfOmegaKong == staker, "Omega Kong not owned by staker");                
                //require(omega.ownerOf(kongId) == address(this), "Omega Kong not transfered to rarity");
                delete omegaToStaker[kongId];
            } else {
                address stakerOfAlphaKong = kongToStaker[kongId];
                require(stakerOfAlphaKong == staker, "Kong not owned by staker");                
                //require(akc.ownerOf(kongId) == address(this), "Kong not transfered to rarity");
                delete kongToStaker[kongId];
            }
           
            bytes32 leaf = keccak256(abi.encodePacked(kongId, isOmega ? true : false, additionalEarnings));
            require(MerkleProof.verify(proof, rarityMerkleRoot, leaf), "Rarity merkle proof invalid");

            uint256 stakeData = userToStakeData[staker];
            uint256 currentAmount = _getAmountFromStakeData(stakeData);
            uint256 currentEarnings = _getEarningsFromStakeData(stakeData);            
            uint256 accumulatedBonus = _getAccumulatedEarningsFromStakeData(stakeData);
            uint256 pendingBonus = _getPendingReward(staker);

            userToStakeData[staker] = _getUpdatedStakeData(block.timestamp, currentAmount - 1, currentEarnings - additionalEarnings, accumulatedBonus + pendingBonus);
        }

    function safeStakeKongs(
        uint256[] memory akcIds, 
        uint256[] memory additionalEarnings, 
        bool[] memory areOmega, 
        bytes32[][] memory proofs
    ) external {
        require(akcIds.length > 0, "No ids provided");
        require(akcIds.length == additionalEarnings.length, "Array length mismatch");
        require(akcIds.length == areOmega.length, "Array length mismatch");
        require(akcIds.length == proofs.length, "Array length mismatch");

        for (uint i = 0; i < akcIds.length; i++) {
            uint256 akcId = akcIds[i];
            uint256 additionalEarning = additionalEarnings[i];
            bool isOmega = areOmega[i];
            bytes32[] memory proof = proofs[i];

            if (isOmega) {
                require(omega.getApproved(akcId) == address(manager) || omega.isApprovedForAll(msg.sender, address(manager)), "MANAGER NOT APPROVED");
            } else {            
                require(akc.getApproved(akcId) == address(manager) || akc.isApprovedForAll(msg.sender, address(manager)), "MANAGER NOT APPROVED");
            }

            manager.safeStakeKong(msg.sender, akcId, isOmega);
            stake(msg.sender, akcId, additionalEarning, isOmega, proof);
        }
    }

    function safeUnstakeKongs(
        address staker,
        uint256[] memory akcIds, 
        uint256[] memory additionalEarnings, 
        bool[] memory areOmega, 
        bytes32[][] memory proofs
    ) external onlyManager {
        require(akcIds.length > 0, "No ids provided");
        require(akcIds.length == additionalEarnings.length, "Array length mismatch");
        require(akcIds.length == areOmega.length, "Array length mismatch");
        require(akcIds.length == proofs.length, "Array length mismatch");

        for (uint i = 0; i < akcIds.length; i++) {
            uint256 akcId = akcIds[i];
            uint256 additionalEarning = additionalEarnings[i];
            bool isOmega = areOmega[i];
            bytes32[] memory proof = proofs[i];

            if (isOmega) {                    
                require(omega.isApprovedForAll(address(this), address(manager)), "MANAGER NOT APPROVED FOR CORE");
            } else {                   
                require(akc.isApprovedForAll(address(this), address(manager)), "MANAGER NOT APPROVED FOR CORE");
            }

            manager.safeUnstakeKong(staker, akcId, isOmega);
            unstake(staker, akcId, additionalEarning, isOmega, proof);
        }
    }

    /** === Getters === */


    // get stake data internal
    function _getStakeTimeStampFromStakeData(uint256 stakeData)
        internal
        pure
        returns (uint256) {
            return uint256(uint32(stakeData));
        }

    function _getAmountFromStakeData(uint256 stakeData)
        internal
        pure
        returns (uint256) {
            return uint256(uint16(stakeData >> 32));
        }
    
    function _getEarningsFromStakeData(uint256 stakeData)
        internal
        pure
        returns (uint256) {
            return  uint256(uint104(stakeData >> 48));
        }
    
    function _getAccumulatedEarningsFromStakeData(uint256 stakeData)
        internal
        pure
        returns (uint256) {
            return  uint256(uint104(stakeData >> 152));
        }

    function _getUpdatedStakeData(uint256 newTimeStamp, uint256 newAmount, uint256 newEarnings, uint256 newBonus)
        internal
        pure
        returns (uint256) {
            uint256 stakeData = newTimeStamp;
            stakeData |= newAmount << 32;
            stakeData |= newEarnings << 48;
            stakeData |= newBonus << 152;
            return stakeData;
        }

    /** === View === */

    function getStakeTimeStampFromStakeData(uint256 stakeData)
        external
        pure
        returns (uint256) {
            return _getStakeTimeStampFromStakeData(stakeData);
        }    
    
    function getStakeEarningsFromStakeData(uint256 stakeData)
        external
        pure
        returns (uint256) {
            return _getEarningsFromStakeData(stakeData);
        }
    
    function getStakePendingBonusFromStakeData(uint256 stakeData)
        external
        pure
        returns (uint256) {
            return  _getAccumulatedEarningsFromStakeData(stakeData);
        }

    function getAmountFromStakeData(uint256 stakeData)
        external
        pure
        returns (uint256) {
            return _getAmountFromStakeData(stakeData);
        }

    function getPendingReward(address staker)
        external
        view   
        returns(uint256) {
            return _getPendingReward(staker);
        }

    function getTotalLiquidatableReward(address staker)
        external
        view
        returns (uint256) {
            uint256 stakeData = userToStakeData[staker];
            return _getPendingReward(staker) + _getAccumulatedEarningsFromStakeData(stakeData);
        }

    function getStakedAlphaKongsOfUser(address staker)
        external
        view
        returns (uint256[] memory) {
            uint256 stakeData = userToStakeData[staker];
            uint256 amountStaked = _getAmountFromStakeData(stakeData);

            uint256[] memory kongs = new uint256[](amountStaked);
            uint256 counter;

            for (uint i = 1; i <= 8888; i++) {
                address kongStaker = kongToStaker[i];                

                if (kongStaker == staker) {
                    kongs[counter] = i;
                    counter++;
                }        
            }
            return kongs;
        }

    function getStakedOmegaKongsOfUser(address staker)
        external
        view
        returns (uint256[] memory) {
            uint256 stakeData = userToStakeData[staker];
            uint256 amountStaked = _getAmountFromStakeData(stakeData);

            uint256[] memory omegas = new uint256[](amountStaked);
            uint256 counter;

            for (uint i = 1; i <= omega.totalSupply(); i++) {
                address omegaStaker = omegaToStaker[i];                

                if (omegaStaker == staker) {
                    omegas[counter] = i;
                    counter++;
                }        
            }
            return omegas;
        }

    function getAllOmegasOfUser(address user)
        external
        view
        returns (uint256[] memory) {
            uint256 balance = omega.balanceOf(user);

            uint256[] memory omegas = new uint256[](balance);
            uint256 counter;

            for (uint i = 1; i <= omega.totalSupply(); i++) {
                address owner = omega.ownerOf(i);                

                if (owner == user) {
                    omegas[counter] = i;
                    counter++;
                }        
            }
            return omegas;
        }


   /** === Owner === */


   function setAkcTribeManager(address newManager)
        external
        onlyOwner {
            manager = ITribeManager(newManager);
        }

    function setRarityMerkleRoot(bytes32 root)
        external 
        onlyOwner {
            rarityMerkleRoot = root;
        }

    function akcNFTApproveForAll(address approved, bool isApproved)
        external
        onlyOwner {
            akc.setApprovalForAll(approved, isApproved);
        }
    
    function omegaNFTApproveForAll(address approved, bool isApproved)
        external
        onlyOwner {
            omega.setApprovalForAll(approved, isApproved);
        }
    
    function withdrawEth(uint256 percentage, address _to)
        external
        onlyOwner {
        payable(_to).transfer((address(this).balance * percentage) / 100);
    }

    function withdrawStuckKong(uint256 kongId, address _to) external onlyOwner {
        require(akc.ownerOf(kongId) == address(this), "CORE DOES NOT OWN KONG");
        akc.transferFrom(address(this), _to, kongId);
    }

    function withdrawStuckOmega(uint256 kongId, address _to) external onlyOwner {
        require(omega.ownerOf(kongId) == address(this), "CORE DOES NOT OWN KONG");
        omega.transferFrom(address(this), _to, kongId);
    }
}