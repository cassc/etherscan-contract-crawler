// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import '../libraries/TransferHelper.sol';
import '../libraries/TimelockLibrary.sol';
import '../interfaces/IVestingPlans.sol';
import '../interfaces/ILockupPlans.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';


/// @title ClaimCampaigns - The smart contract to distribute your tokens to the community via claims
/// @notice This tool allows token projects to safely, securely and efficiently distribute your tokens in large scale to your community, whereby they can claim them based on your criteria of wallet address and amount. 

contract ClaimCampaigns is ReentrancyGuard {
  /// @notice the address that collects any donations given to the team
  address private donationCollector;

  /// @dev an enum defining the different types of claims to be made
  /// @param Unlocked means that tokens claimed are liquid and not locked at all
  /// @param Locked means that the tokens claimed will be locked inside a TokenLockups plan
  /// @param Vesting means the tokens claimed will be locked insite a TokenVesting plan
  enum TokenLockup {
    Unlocked,
    Locked,
    Vesting
  }

  /// @notice the struct that defines the Locked and Vesting parameters for each vesting
  /// @dev this can be ignored for Unlocked claim campaigns
  /// @param tokenLocker is the address of the TokenLockup or TokenVesting plans contract that will lock the tokens
  /// @param rate is the rate which the tokens will unlock / vest at per period. So 10 would indicate 10 tokens unlocking per period.
  /// @param start is the start date when the unlock / vesting begins
  /// @param cliff is the single cliff date for unlocking and vesting plans, when all tokens prior to the cliff remained locked and unvested
  /// @param period is the amount of seconds in each discrete period. A streaming style would have this set to 1, but a period of 1 day would be 86400, tokens only unlock at each discrete period interval
  struct ClaimLockup {
    address tokenLocker;
    uint256 rate;
    uint256 start;
    uint256 cliff;
    uint256 period;
  }

  /// @notice Campaign is the struct that defines a claim campaign in general. The Campaign is related to a one time use, related to a merkle tree that pre defines all of the wallets and amounts those wallets can claim
  /// once the amount is 0, the campaign is ended. The campaign can also be terminated at any time.
  /// @param manager is the address of the campaign manager who is in charge of cancelling the campaign - AND if the campaign is setup for vesting, this address will be used as the vestingAdmin wallet for all of the vesting plans created
  /// the manager is typically the msg.sender wallet, but can be defined as something else in case.
  /// @param token is the address of the token to be claimed by the wallets, which is pulled into the contract during the campaign
  /// @param amount is the total amount of tokens left in the Campaign. this starts out as the entire amount in the campaign, and gets reduced each time a claim is made
  /// @param end is a unix time that can be used as a safety mechanism to put a hard end date for a campaign, this can also be far far in the future to effectively be forever claims
  /// @param tokenLockup is the enum (uint8) that describes how and if the tokens will be locked or vesting when they are claimed. If set to unlocked, claimants will just get the tokens, but if they are Locked / vesting, they will receive the NFT Tokenlockup plan or vesting plan
  /// @param root is the root of the merkle tree used for the claims. 
  struct Campaign {
    address manager;
    address token;
    uint256 amount;
    uint256 end;
    TokenLockup tokenLockup;
    bytes32 root;
  }

  /// @notice this is an optional Donation that users can gift to Hedgey and team for their services. The campaign creator can define a lockup schedule of the donation of tokens, or gift them unlocked.
  /// @dev if donating tokens unlocked, set the start date to 0.
  /// @param tokenLocker is the address of the token lockup plans contract if the tokens are going to be locked
  /// @param amount is the amount of the donation
  /// @param rate is the rate the tokens unlock
  /// @param start is the start date the tokens unlock
  /// @param cliff is the cliff date the first time tokens unlock
  /// @param period is the time between each unlock
  struct Donation {
    address tokenLocker;
    uint256 amount;
    uint256 rate;
    uint256 start;
    uint256 cliff;
    uint256 period;
  }

  /// @dev we use UUIDs or CIDs to map to a specific unique campaign. The UUID or CID is typically generated when the merkle tree is created, and then that id or cid is the identifier of the file in S3 or IPFS 
  mapping(bytes16 => Campaign) public campaigns;
  /// @dev the same UUID is maped to the ClaimLockup details for the specific campaign
  mapping(bytes16 => ClaimLockup) public claimLockups;
  /// @dev this maps the UUID that have already been used, so that a campaign cannot be duplicated
  mapping(bytes16 => bool) public usedIds;
  

  //maps campaign id to a wallet address, which is flipped to true when claimed
  mapping(bytes16 => mapping(address => bool)) public claimed;

  // events
  event CampaignStarted(bytes16 indexed id, Campaign campaign);
  event ClaimLockupCreated(bytes16 indexed id, ClaimLockup claimLockup);
  event CampaignCancelled(bytes16 indexed id);
  event TokensClaimed(bytes16 indexed id, address indexed claimer, uint256 amountClaimed, uint256 amountRemaining);

  constructor(address _donationCollector) {
    donationCollector = _donationCollector;
  }

  /// @notice function to change the address the donations are sent to
  /// @param newCollector the address that is going to be the new recipient of donations
  function changeDonationcollector(address newCollector) external {
    require(msg.sender == donationCollector);
    donationCollector = newCollector;
  }

  /// @notice primary function for creating an unlocked claims campaign. This function will pull the amount of tokens in the campaign struct, and map the campaign to the id. 
  /// @dev the merkle tree needs to be pre-generated, so that you can upload the root and the uuid for the function
  /// @param id is the uuid or CID of the file that stores the merkle tree
  /// @param campaign is the struct of the campaign info, including the total amount tokens to be distributed via claims, and the root of the merkle tree
  /// @param donation is the doantion struct that can be 0 or any amount of tokens the team wishes to donate
  function createUnlockedCampaign(
    bytes16 id,
    Campaign memory campaign,
    Donation memory donation
  ) external nonReentrant {
    require(!usedIds[id], 'in use');
    usedIds[id] = true;
    require(campaign.token != address(0), '0_address');
    require(campaign.manager != address(0), '0_manager');
    require(campaign.amount > 0, '0_amount');
    require(campaign.end > block.timestamp, 'end error');
    require(campaign.tokenLockup == TokenLockup.Unlocked, 'locked');
    TransferHelper.transferTokens(campaign.token, msg.sender, address(this), campaign.amount + donation.amount);
    if (donation.amount > 0) {
      if (donation.start > 0) {
        SafeERC20.safeIncreaseAllowance(IERC20(campaign.token), donation.tokenLocker, donation.amount);
        ILockupPlans(donation.tokenLocker).createPlan(
          donationCollector,
          campaign.token,
          donation.amount,
          donation.start,
          donation.cliff,
          donation.rate,
          donation.period
        );
      } else {
        TransferHelper.withdrawTokens(campaign.token, donationCollector, donation.amount);
      }
    }
    campaigns[id] = campaign;
    emit CampaignStarted(id, campaign);
  }


  /// @notice primary function for creating an locked or vesting claims campaign. This function will pull the amount of tokens in the campaign struct, and map the campaign and claimLockup to the id.
  /// additionally it will check that the lockup details are valid, and perform an allowance increase to the contract for when tokens are claimed they can be pulled. 
  /// @dev the merkle tree needs to be pre-generated, so that you can upload the root and the uuid for the function
  /// @param id is the uuid or CID of the file that stores the merkle tree
  /// @param campaign is the struct of the campaign info, including the total amount tokens to be distributed via claims, and the root of the merkle tree, plus the lockup type of either 1 (lockup) or 2 (vesting) 
  /// @param claimLockup is the struct that defines the characteristics of the lockup for each token claimed. 
  /// @param donation is the doantion struct that can be 0 or any amount of tokens the team wishes to donate
  function createLockedCampaign(
    bytes16 id,
    Campaign memory campaign,
    ClaimLockup memory claimLockup,
    Donation memory donation
  ) external nonReentrant {
    require(!usedIds[id], 'in use');
    usedIds[id] = true;
    require(campaign.token != address(0), '0_address');
    require(campaign.manager != address(0), '0_manager');
    require(campaign.amount > 0, '0_amount');
    require(campaign.end > block.timestamp, 'end error');
    require(campaign.tokenLockup != TokenLockup.Unlocked, '!locked');
    require(claimLockup.tokenLocker != address(0), 'invalide locker');
    TransferHelper.transferTokens(campaign.token, msg.sender, address(this), campaign.amount + donation.amount);
    if (donation.amount > 0) {
      if (donation.start > 0) {
        SafeERC20.safeIncreaseAllowance(IERC20(campaign.token), donation.tokenLocker, donation.amount);
        ILockupPlans(donation.tokenLocker).createPlan(
          donationCollector,
          campaign.token,
          donation.amount,
          donation.start,
          donation.cliff,
          donation.rate,
          donation.period
        );
      } else {
        TransferHelper.withdrawTokens(campaign.token, donationCollector, donation.amount);
      }
    }
    (, bool valid) = TimelockLibrary.validateEnd(
      claimLockup.start,
      claimLockup.cliff,
      campaign.amount,
      claimLockup.rate,
      claimLockup.period
    );
    require(valid);
    claimLockups[id] = claimLockup;
    SafeERC20.safeIncreaseAllowance(IERC20(campaign.token), claimLockup.tokenLocker, campaign.amount);
    campaigns[id] = campaign;
    emit ClaimLockupCreated(id, claimLockup);
    emit CampaignStarted(id, campaign);
  }


  /// @notice this is the primary function for the claimants to claim their tokens
  /// @dev the claimer will need to know the uuid of the campiagn, plus have access to the amount of tokens they are claiming and the merkle tree proof
  /// @dev if the claimer doesnt have this information the function will fail as it will not pass the verify validation
  /// the leaf of each merkle tree is the hash of the wallet address plus the amount of tokens claimable
  /// @dev once a user has claimed tokens, they cannot perform a second claim
  /// @dev the amount of tokens in the campaign is reduced by the amount of the claim
  /// @param campaignId is the id of the campaign stored in storage
  /// @param proof is the merkle tree proof that maps to their unique leaf in the merkle tree
  /// @param claimAmount is the amount of tokens they are eligible to claim
  /// this function will verify and validate the eligibilty of the claim, and then process the claim, by delivering unlocked or locked / vesting tokens depending on the setup of the claim campaign. 
  function claimTokens(bytes16 campaignId, bytes32[] memory proof, uint256 claimAmount) external nonReentrant {
    require(!claimed[campaignId][msg.sender], 'already claimed');
    Campaign memory campaign = campaigns[campaignId];
    require(campaign.end > block.timestamp, 'campaign ended');
    require(verify(campaign.root, proof, msg.sender, claimAmount), '!eligible');
    require(campaign.amount >= claimAmount, 'campaign unfunded');
    claimed[campaignId][msg.sender] = true;
    campaigns[campaignId].amount -= claimAmount;
    if (campaigns[campaignId].amount == 0) {
      delete campaigns[campaignId];
    }
    if (campaign.tokenLockup == TokenLockup.Unlocked) {
      TransferHelper.withdrawTokens(campaign.token, msg.sender, claimAmount);
    } else {
      ClaimLockup memory c = claimLockups[campaignId];
      if (campaign.tokenLockup == TokenLockup.Locked) {
        ILockupPlans(c.tokenLocker).createPlan(
          msg.sender,
          campaign.token,
          claimAmount,
          c.start,
          c.cliff,
          c.rate,
          c.period
        );
      } else {
        IVestingPlans(c.tokenLocker).createPlan(
          msg.sender,
          campaign.token,
          claimAmount,
          c.start,
          c.cliff,
          c.rate,
          c.period,
          campaign.manager,
          false
        );
      }
    }
    emit TokensClaimed(campaignId, msg.sender, claimAmount, campaigns[campaignId].amount);
  }


  /// @notice this function allows the campaign manager to cancel an ongoing campaign at anytime. Cancelling a campaign will return any unclaimed tokens, and then prevent anyone from claiming additional tokens
  /// @param campaignId is the id of the campaign to be cancelled
  function cancelCampaign(bytes16 campaignId) external nonReentrant {
    Campaign memory campaign = campaigns[campaignId];
    require(campaign.manager == msg.sender, '!manager');
    delete campaigns[campaignId];
    delete claimLockups[campaignId];
    TransferHelper.withdrawTokens(campaign.token, msg.sender, campaign.amount);
    emit CampaignCancelled(campaignId);
  }

  /// @dev the internal verify function from the open zepellin library. 
  /// this function inputs the root, proof, wallet address of the claimer, and amount of tokens, and then computes the validity of the leaf with the proof and root. 
  /// @param root is the root of the merkle tree
  /// @param proof is the proof for the specific leaf
  /// @param claimer is the address of the claimer used in making the leaf
  /// @param amount is the amount of tokens to be claimed, the other piece of data in the leaf
  function verify(bytes32 root, bytes32[] memory proof, address claimer, uint256 amount) public pure returns (bool) {
    bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(claimer, amount))));
    require(MerkleProof.verify(proof, root, leaf), 'Invalid proof');
    return true;
  }
}