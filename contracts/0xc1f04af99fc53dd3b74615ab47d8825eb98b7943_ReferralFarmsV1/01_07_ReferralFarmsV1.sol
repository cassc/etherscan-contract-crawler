// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.14;

//
//                                 (((((((((((()                                 
//                              (((((((((((((((((((                              
//                            ((((((           ((((((                            
//                           (((((               (((((                           
//                         (((((/                 ((((((                         
//                        (((((                     (((((                        
//                      ((((((                       ((((()                      
//                     (((((                           (((((                     
//                   ((((((                             (((((                    
//                  (((((                                                        
//                ((((((                        (((((((((((((((                  
//               (((((                       (((((((((((((((((((((               
//             ((((((                      ((((((             (((((.             
//            (((((                      ((((((.               ((((((            
//          ((((((                     ((((((((                  (((((           
//         (((((                      (((((((((                   ((((((         
//        (((((                     ((((((.(((((                    (((((        
//       (((((                     ((((((   (((((                    (((((       
//      (((((                    ((((((      ((((((                   (((((      
//      ((((.                  ((((((          (((((                  (((((      
//      (((((                .((((((            ((((((                (((((      
//       ((((()            (((((((                (((((             ((((((       
//        .(((((((      (((((((.                   ((((((((     ((((((((         
//           ((((((((((((((((                         ((((((((((((((((           
//                .((((.                                    (((()         
//                                  
//                               attrace.com
//

// import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../chainAddress/ChainAddress.sol";
import "../interfaces/IERC20.sol";
import "../confirmations/types.sol";
// import "../oracles/OracleEffectsV1.sol";
// import "../support/DevRescuableOnTestnets.sol";

// Attrace Referral Farms V1
//
// A farm can be thought of as a "farm deposit". A single owner can have multiple deposits for different reward tokens and different farms.
// Token farms aggregated are a virtual/logical concept: UI's can render and groups these together as "Farms per token" and can group further "Aggregated farming value per token" and so on.
//
// This contract manages these deposits by sponsor (sponsor=msg.sender).
contract ReferralFarmsV1 is Ownable {

  // Pointer to oracles confirmations contract
  ConfirmationsResolver confirmationsAddr;

  // The farm reward token deposits remaining
  // farmHash => deposit remaining
  // Where farmHash = hash(encode(chainId,sponsor,rewardTokenDefn,referredTokenDefn))
  mapping(bytes32 => uint256) private farmDeposits;

  // Mapping which tracks which effects have been executed at the account token level (and thus are burned).
  // account => token => offset
  mapping(address => mapping(address => uint256)) private accountTokenConfirmationOffsets;

  // Mapping which tracks which effects have been executed at the farm level (and thus are burned).
  // Tracks sponsor withdraw offsets.
  // farmHash => offset
  mapping(bytes32 => uint256) private farmConfirmationOffsets;

  // Max-reward value per farm/confirmation, used by claim flows to act as a fail-safe to ensure the rewards don't overflow in the unlikely event of a bug/attack.
  mapping(bytes32 => uint256) private farmConfirmationRewardMax;

  // Tracks the remaining rewards that can be transferred per confirmation
  // farmHash -> confirmation number -> { initialized, valueRemaining }
  mapping(bytes32 => mapping(uint256 => FarmConfirmationRewardRemaining)) private farmConfirmationRewardRemaining;

  // Emitted whenever a farm is increased (which guarantees creation). Occurs multiple times per farm.
  event FarmExists(address indexed sponsor, bytes24 indexed rewardTokenDefn, bytes24 indexed referredTokenDefn, bytes32 farmHash);

  // Emitted whenever a farm is increased
  event FarmDepositIncreased(bytes32 indexed farmHash, uint128 delta);

  // Emitted when a sponsor _requests_ to withdraw their funds.
  // UI's can use the value here to indicate the change to the farm.
  // Promoters can be notified to stop promoting this farm.
  event FarmDepositDecreaseRequested(bytes32 indexed farmHash, uint128 value, uint128 confirmation);

  // Emitted whenever a farm deposit decrease is claimed
  event FarmDepositDecreaseClaimed(bytes32 indexed farmHash, uint128 delta);

  // Dynamic field to control farm behavior. 
  event FarmMetastate(bytes32 indexed farmHash, bytes32 indexed key, bytes value);

  // Emitted when rewards have been harvested by an account
  event RewardsHarvested(address indexed caller, bytes24 indexed rewardTokenDefn, bytes32 indexed farmHash, uint128 value, bytes32 leafHash);

  bytes32 constant CONFIRMATION_REWARD = "confirmationReward";

  function configure(address confirmationsAddr_) external onlyOwner {
    confirmationsAddr = ConfirmationsResolver(confirmationsAddr_);
  }

  function getFarmDepositRemaining(bytes32 farmHash) external view returns (uint256) {
    return farmDeposits[farmHash];
  }

  // Returns the confirmation offset per account per reward token
  function getAccountTokenConfirmationOffset(address account, address token) external view returns (uint256) {
    return accountTokenConfirmationOffsets[account][token];
  }

  // Getter to step through the history of farm confirmation rewards over time
  function getFarmConfirmationRewardMax(bytes32 farmHash) external view returns (uint256) {
    return farmConfirmationRewardMax[farmHash];
  }

  // Increase referral farm using ERC20 reward token (also creates any non-existing farm)
  function increaseReferralFarm(bytes24 rewardTokenDefn, bytes24 referredTokenDefn, uint128 rewardDeposit, KeyVal[] calldata metastate) external {
    require(
      rewardDeposit > 0 && rewardTokenDefn != ChainAddressExt.getNativeTokenChainAddress(), 
      "400: invalid"
    );

    // First transfer the reward token deposit to this
    IERC20(ChainAddressExt.toAddress(rewardTokenDefn)).transferFrom(msg.sender, address(this), uint256(rewardDeposit));

    // Increase the farm (this doubles as security)
    bytes32 farmHash = toFarmHash(msg.sender, rewardTokenDefn, referredTokenDefn);
    farmDeposits[farmHash] += rewardDeposit;
    
    // Inform listeners about this new farm and allow discovering the farmHash (since we don't store it)
    emit FarmExists(msg.sender, rewardTokenDefn, referredTokenDefn, farmHash);

    // Emit creation and increase of deposit
    emit FarmDepositIncreased(farmHash, rewardDeposit);

    // Handle metastate
    handleMetastateChange(farmHash, metastate);
  }

  // Configure additional metastate for a farm
  function configureMetastate(bytes24 rewardTokenDefn, bytes24 referredTokenDefn, KeyVal[] calldata metastate) external {
    // FarmHash calculation doubles as security
    bytes32 farmHash = toFarmHash(msg.sender, rewardTokenDefn, referredTokenDefn);
    handleMetastateChange(farmHash, metastate);
  }

  function handleMetastateChange(bytes32 farmHash, KeyVal[] calldata metastate) private {
    for(uint256 i = 0; i < metastate.length; i++) {
      // Manage the confirmation reward rate changes
      if(metastate[i].key == CONFIRMATION_REWARD) {
        processConfirmationRewardChangeRequest(farmHash, metastate[i].value);
      }

      emit FarmMetastate(farmHash, metastate[i].key, metastate[i].value);
    }

    // Checks if the confirmationReward has at least one value or throws error that it's required
    require(farmConfirmationRewardMax[farmHash] > 0, "400: confirmationReward");
  }

  // It should be impossible to change history.
  function processConfirmationRewardChangeRequest(bytes32 farmHash, bytes calldata value) private {
    (uint128 reward, ) = abi.decode(value, (uint128, uint128));
    if(reward > farmConfirmationRewardMax[farmHash]) {
      farmConfirmationRewardMax[farmHash] = reward;
    }
  }

  // -- HARVEST REWARDS

  // Validates against double spend
  function validateEntitlementsSetOffsetOrRevert(address rewardToken, TokenEntitlement[] calldata entitlements) private {
    require(entitlements.length > 0, "400: entitlements");
    uint128 min = entitlements[0].confirmation;
    uint128 max;
    
    // Search min/max from list
    for(uint256 i = 0; i < entitlements.length; i++) {
      if(entitlements[i].confirmation < min) {
        min = entitlements[i].confirmation;
      }
      if(entitlements[i].confirmation > max) {
        max = entitlements[i].confirmation;
      }
    }
    
    // Validate against double spend
    require(accountTokenConfirmationOffsets[msg.sender][rewardToken] < min, "401: double spend");

    // Store the new offset to protect against double spend
    accountTokenConfirmationOffsets[msg.sender][rewardToken] = max;
  }

  // Check the requested amount against the limits and update confirmation remaining value to protect against re-entrancy
  function adjustFarmConfirmationRewardRemainingOrRevert(bytes32 farmHash, uint128 confirmation, uint128 value) private {
    // Find reward remaining or initialize the first time it's used
    uint128 rewardRemaining;
    if(farmConfirmationRewardRemaining[farmHash][confirmation].initialized == false) {
      // First initializes the farmConfirmationRewardRemaining...valueRemaining
      rewardRemaining = uint128(farmConfirmationRewardMax[farmHash]); 
    } else {
      rewardRemaining = farmConfirmationRewardRemaining[farmHash][confirmation].valueRemaining;
    }

    // Adjust reward
    rewardRemaining -= value; // Underflow will throw here on insufficient confirmation balance.
    farmConfirmationRewardRemaining[farmHash][confirmation] = FarmConfirmationRewardRemaining(true, rewardRemaining);

    // Ensure sufficient deposit is left for this farm
    farmDeposits[farmHash] -= value; // Underflow will throw here on insufficient balance.
  }

  // Collect rewards entitled by the oracles.
  // Function has been tested to support 2000 requests, each carrying 20 proofs.
  function harvestRewardsNoGapcheck(HarvestTokenRequest[] calldata reqs, bytes32[][][] calldata proofs) external {
    require(reqs.length > 0 && proofs.length == reqs.length, "400: request");

    // Execute requests by reward token
    for(uint256 i = 0; i < reqs.length; i++) {
      HarvestTokenRequest calldata req = reqs[i];
      require(uint32(block.chainid) == ChainAddressExt.toChainId(req.rewardTokenDefn), "400: chain");
      address rewardTokenAddr = ChainAddressExt.toAddress(req.rewardTokenDefn);

      // Validate nonces and protects against re-entrancy.
      validateEntitlementsSetOffsetOrRevert(rewardTokenAddr, reqs[i].entitlements);

      // Check entitlements and sum reward value
      uint128 rewardValueSum = 0;
      for(uint256 j = 0; j < req.entitlements.length; j++) {
        TokenEntitlement calldata entitlement = req.entitlements[j];

        // Check if its a valid call
        bytes32 leafHash = makeLeafHash(req.rewardTokenDefn, entitlement);
        bytes32 computedHash = MerkleProof.processProof(proofs[i][j], leafHash);
        // bytes32 computedHash = OracleEffectsV1.computeRoot(leafHash, proofs[i][j]);
        (uint128 confirmation, ) = confirmationsAddr.getConfirmation(computedHash);
        require(confirmation > 0, "401: not finalized proof");  

        adjustFarmConfirmationRewardRemainingOrRevert(entitlement.farmHash, entitlement.confirmation, entitlement.value);

        emit RewardsHarvested(msg.sender, req.rewardTokenDefn, entitlement.farmHash, entitlement.value, leafHash);

        rewardValueSum += entitlement.value;
      }

      // Transfer the value using ERC20 implementation
      if(rewardValueSum > 0) {
        IERC20(rewardTokenAddr).transfer(msg.sender, rewardValueSum);
      }
    }
  }

  // -- Sponsor withdrawals

  // Called by a sponsor to request extracting (unused) funds.
  // This will be picked up by the oracle, who will reduce the deposit in it's state and provide a valid claim for extracting the value.
  function requestDecreaseReferralFarm(bytes24 rewardTokenDefn, bytes24 referredTokenDefn, uint128 value) external {
    // Farm hash doubles as security
    bytes32 farmHash = toFarmHash(msg.sender, rewardTokenDefn, referredTokenDefn);
    require(farmDeposits[farmHash] > 0, "400: deposit");

    // For good ux, replace value here with max if it overflows the deposit
    if(value > farmDeposits[farmHash]) {
      value = uint128(farmDeposits[farmHash]);
    }
    
    // Emit event for oracle trie calculation
    (uint128 headConfirmation, ) = confirmationsAddr.getConfirmation(confirmationsAddr.getHead());
    emit FarmDepositDecreaseRequested(farmHash, value, headConfirmation);
  }

  // Can be called by the sponsor after the confirmation has included the decrease request.
  // Sponsor then collects a proof which allows to extract the value.
  function claimReferralFarmDecrease(bytes24 rewardTokenDefn, bytes24 referredTokenDefn, uint128 confirmation, uint128 value, bytes32[] calldata proof) external {
    // Farm hash doubles as security
    bytes32 farmHash = toFarmHash(msg.sender, rewardTokenDefn, referredTokenDefn);

    // Check if this request is already burned (protect against double-spend and re-entrancy)
    require(confirmation > farmConfirmationOffsets[farmHash], "400: invalid or burned");

    // Burn the request
    farmConfirmationOffsets[farmHash] = confirmation;

    // Calculate leaf hash
    bytes32 leafHash = makeDecreaseLeafHash(farmHash, confirmation, value);
    
    // Check that the proof is valid (the oracle keeps a state of decrease requests, requests are bound to their request confirmation)
    // bytes32 computedHash = OracleEffectsV1.computeRoot(leafHash, proof);
    bytes32 computedHash = MerkleProof.processProof(proof, leafHash);
    (uint128 searchConfirmation, ) = confirmationsAddr.getConfirmation(computedHash);
    require(searchConfirmation > 0, "401: not finalized proof");

    // Failsafe against any bugs
    if(farmDeposits[farmHash] < value) {
      value = uint128(farmDeposits[farmHash]);
    }

    // Avoid re-entrancy on value before transfer
    farmDeposits[farmHash] -= value;

    // Transfer the value
    address rewardTokenAddr = ChainAddressExt.toAddress(rewardTokenDefn);
    IERC20(rewardTokenAddr).transfer(msg.sender, value);

    // Emit event of decrease in farm value
    emit FarmDepositDecreaseClaimed(farmHash, value);
  }

  function makeLeafHash(bytes24 rewardTokenDefn, TokenEntitlement calldata entitlement) private view returns (bytes32) {
    return keccak256(abi.encode(
      ChainAddressExt.toChainAddress(block.chainid, address(confirmationsAddr)), 
      ChainAddressExt.toChainAddress(block.chainid, address(this)),
      msg.sender, 
      rewardTokenDefn,
      entitlement
    ));
  }

  function makeDecreaseLeafHash(bytes32 farmHash, uint128 confirmation, uint128 value) private view returns (bytes32) {
    return keccak256(abi.encode(
      ChainAddressExt.toChainAddress(block.chainid, address(confirmationsAddr)), 
      ChainAddressExt.toChainAddress(block.chainid, address(this)),
      farmHash,
      confirmation,
      value
    ));
  }

  // -- don't accept raw ether
  receive() external payable {
    revert('unsupported');
  }

  // -- reject any other function
  fallback() external payable {
    revert('unsupported');
  }
}

struct KeyVal {
  bytes32 key;
  bytes value;
}

struct FarmConfirmationRewardRemaining {
  bool initialized;
  uint128 valueRemaining;
}

// Entitlements for a reward token
struct HarvestTokenRequest {
  // The reward token
  bytes24 rewardTokenDefn;

  // Entitlements for this token which can be verified against the confirmation hashes
  TokenEntitlement[] entitlements;
}

// An entitlement to token value, which can be harvested, if confirmed by the oracles
struct TokenEntitlement {
  // The farm deposit
  bytes32 farmHash;

  // Reward token value which can be harvested
  uint128 value;

  // The confirmation number during which this entitlement was generated
  uint128 confirmation;
}

// Farm Hash - represents a single sponsor owned farm.
function toFarmHash(address sponsor, bytes24 rewardTokenDefn, bytes24 referredTokenDefn) view returns (bytes32 farmHash) {
  return keccak256(abi.encode(block.chainid, sponsor, rewardTokenDefn, referredTokenDefn));
}