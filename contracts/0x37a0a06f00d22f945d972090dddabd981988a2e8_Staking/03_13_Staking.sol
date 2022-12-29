// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 _______  _______  _______  _        _        _______  _          _______           _        _        _______
(  ____ \(  ____ )(  ___  )( (    /|| \    /\(  ____ \( (    /|  (  ____ )|\     /|( (    /|| \    /\(  ____ \
| (    \/| (    )|| (   ) ||  \  ( ||  \  / /| (    \/|  \  ( |  | (    )|| )   ( ||  \  ( ||  \  / /| (    \/
| (__    | (____)|| (___) ||   \ | ||  (_/ / | (__    |   \ | |  | (____)|| |   | ||   \ | ||  (_/ / | (_____
|  __)   |     __)|  ___  || (\ \) ||   _ (  |  __)   | (\ \) |  |  _____)| |   | || (\ \) ||   _ (  (_____  )
| (      | (\ (   | (   ) || | \   ||  ( \ \ | (      | | \   |  | (      | |   | || | \   ||  ( \ \       ) |
| )      | ) \ \__| )   ( || )  \  ||  /  \ \| (____/\| )  \  |  | )      | (___) || )  \  ||  /  \ \/\____) |
|/       |/   \__/|/     \||/    )_)|_/    \/(_______/|/    )_)  |/       (_______)|/    )_)|_/    \/\_______)

*/

import "solmate/tokens/ERC721.sol";
import "solmate/utils/LibString.sol";
import "./utils/SafeCast.sol";
import "./utils/Refundable.sol";
import "./utils/Admin.sol";

import "./interfaces/IERC721.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/IGovernance.sol";
import "./interfaces/IExecutor.sol";

/// @title FrankenDAO Staking
/// @author Zach Obront & Zakk Fleischmann
/// @notice Users stake FrankenPunks & FrankenMonsters and get ERC721s in return
/// @notice These ERC721s are used for voting power for FrankenDAO governance
contract Staking is IStaking, ERC721, Admin, Refundable {
  using LibString for uint256;

  /// @notice The original ERC721 FrankenPunks contract
  IERC721 frankenpunks;
  
  /// @notice The original ERC721 FrankenMonsters contract
  IERC721 frankenmonsters;

  /// @notice The DAO governance contract (where voting occurs)
  IGovernance governance;

  /// @notice Base votes for holding a Frankenpunk token
  uint constant public BASE_VOTES = 20;

  /// @return maxStakeBonusTime The maxmimum time you will earn bonus votes for staking for
  /// @return maxStakeBonusAmount The amount of bonus votes you'll get if you stake for the max time
  StakingSettings public stakingSettings;

  /// @notice Multipliers (expressed as percentage) for calculating community voting power from user stats
  /// @return votes The multiplier for extra voting power earned per DAO vote cast
  /// @return proposalsCreated The multiplier for extra voting power earned per proposal created
  /// @return proposalsPassed The multiplier for extra voting power earned per proposal passed
  CommunityPowerMultipliers public communityPowerMultipliers;

  /// @notice Constant to calculate voting power based on multipliers above
  uint constant PERCENT = 100;

  /// @notice Are refunds turned on for staking?
  bool public stakingRefund;

  /// @notice The last timestamp at which a user used their staking refund
  mapping(address => uint256) public lastStakingRefund;

  /// @notice Are refunds turned on for delegating?
  bool public delegatingRefund;

  /// @notice The last timestamp at which a user used their delegating refund
  mapping(address => uint256) public lastDelegatingRefund;

  /// @notice How often can a user use their refund?
  uint256 public refundCooldown;

  /// @notice Is staking currently paused or open?
  bool public paused;

  /// @notice The staked time bonus for each staked token (tokenId => bonus votes)
  /// @dev This needs to be tracked because users will select how much time to lock for, so bonus is variable
  mapping(uint => uint) stakedTimeBonus; 
  
  /// @notice The allowed unlock time for each staked token (tokenId => timestamp)
  /// @dev This remains at 0 if tokens are staked without locking
  mapping(uint => uint) public unlockTime;

  /// @notice Addresses that each user delegates votes to
  /// @dev This should only be accessed via getDelegate() function, which overrides address(0) with self
  mapping(address => address) private _delegates;

  /// @notice The total voting power earned by each user's staked tokens
  /// @dev In other words, this is the amount of voting power that would move if they redelegated
  /// @dev They don't necessarily have this many votes, because they may have delegated them
  mapping(address => uint) public votesFromOwnedTokens;

  /// @notice The total voting power each user has, after adjusting for delegation
  /// @dev This represents the actual token voting power of each user
  mapping(address => uint) public tokenVotingPower;

  /// @notice The total token voting power of the system
  uint totalTokenVotingPower;

  /// @notice Base token URI for the ERC721s representing the staked position
  string public baseTokenURI;

  /// @notice Contract URI for marketplace metadata
  string public contractURI;

  /// @notice The total supply of staked frankenpunks
  uint128 public stakedFrankenPunks;

  /// @notice The total supply of staked frankenmonsters
  uint128 public stakedFrankenMonsters;

  /// @notice Bitmaps representing whether each FrankenPunk has a sufficient "evil score" for a bonus.
  /// @dev 40 words * 256 bits = 10,240 bits, which is sufficient to hold values for 10k FrankenPunks
  uint[40] EVIL_BITMAPS = [
    883425322698150530263834307704826599123904599330160270537777278655401984, // 0
    14488147225470816109160058996749687396265978336526515174837584423109802852352, // 1
    38566513062215815139428642218823858442255833421860837338906624, // 2
    105312291668557186697918027683670432324476705909712387428719788032, // 3
    14474011154664524427946373126085988481660077311200856629730921422678596263936, // 4
    3618502788692465607655909614339766499850336868450542774889103259212619972609, // 5
    441711772776714745308416192199486840791445460561420424832198410539892736, // 6
    6901746759773641161995257390185172072446268286034776944761674561224712, // 7
    883423532414903565819785182543377466397133986207912949084155019599544320, // 8
    14474011155086185177904289442148664541270784730116237084843513087002589265920, // 9
    107839786668798718607898896909541540930351713584408019687362806153216, // 10
    904625700641838402593673198335004289144275540958779302917589231213362556944, // 11
    220859253090631447287862539909960206022391538433640386622889848771706880, // 12
    1393839110204029063653915313866451565150208, // 13
    784637716923340670665773318162647287385528792673206407169, // 14
    107839786668602559178668060353525740564723109496935832847049186869248, // 15
    51422802054004612152481822571560984362335820545231474237898784, // 16
    6582018229284824169333500576582381960460086447259084614308728832, // 17
    365732221255902219560809532335122355265736818688, // 18
    445162639419413381705829464770174011933371831432841644599383048677490688, // 19
    6935446280124502090171244984389489167294584349705235353545399909482504, // 20
    452312848583266388373372050675839373643513806386188657447441353755011973120, // 21
    51422023594160337932957247212003666383914706547133656225284128, // 22
    2923003274661805998666646494941077336069228208128, // 23
    215679573337205118357336126271343355406346657833909405071980653182976, // 24
    26959946667150639794667015087041235820865508444839585222888876146720, // 25
    3731581108651760187459529718884681603688140590625042088037390915407571845120, // 26
    33372889303170710042455474178259135664197736114694375141005066752, // 27
    28948022309329151699928351061631107912622119818910282538292189430411643863044, // 28
    55214023430470347690952963241066788995217469738067023806554216123598848, // 29
    55213971185700649632772712790212230970723509677757939395778641765335297, // 30
    50216813883139118038214077107913983031541181002059654103040, // 31
    45671926166601100787582220677640905906662146176, // 32
    431359146674410260659915067596052074490887103277477952745659311325184, // 33
    6741683593362397442763285474207733540211166501858783908538903166976, // 34
    421249166674235107246797774824181756792478284093098635821743865856, // 35
    53919893334350319447007114026840783409769671338355940037889148190720, // 36
    401740641047276407850947922339698016834483256774579142524928, // 37
    220855883097304318299647574273628650268020954052697685772267193358090240, // 38
    0 // 39
  ];

  /////////////////////////////////
  /////////// MODIFIERS ///////////
  /////////////////////////////////

  /// @dev To avoid needing to checkpoint voting power, tokens are locked while users have active votes cast or proposals open
  /// @dev If a user creates a proposal or casts a vote, this modifier prevents them from unstaking or delegating
  /// @dev Once the proposal is completed, it is removed from getActiveProposals and their tokens are unlocked
  modifier lockedWhileVotesCast() {
    uint[] memory activeProposals = governance.getActiveProposals();
    for (uint i = 0; i < activeProposals.length; i++) {
      if (governance.getReceipt(activeProposals[i], getDelegate(msg.sender)).hasVoted) revert TokenLocked();
      (, address proposer,) = governance.getProposalData(activeProposals[i]);
      if (proposer == getDelegate(msg.sender)) revert TokenLocked();
    }
    _;
  }

  /////////////////////////////////
  ////////// CONSTRUCTOR //////////
  /////////////////////////////////

  /// @param _frankenpunks The address of the original ERC721 FrankenPunks contract
  /// @param _frankenmonsters The address of the original ERC721 FrankenMonsters contract
  /// @param _governance The address of the DAO governance contract
  /// @param _executor The address of the DAO executor contract
  /// @param _founders The address of the founder multisig for restricted functions
  /// @param _council The address of the council multisig for restricted functions
  /// @param _baseTokenURI Token URI for the Staking NFT contract
  /// @param _contractURI URI for the contract metadata
  constructor(
    address _frankenpunks, 
    address _frankenmonsters,
    address _governance, 
    address _executor, 
    address _founders,
    address _council,
    string memory _baseTokenURI,
    string memory _contractURI
  ) ERC721("Staked FrankenPunks", "sFP") {
    frankenpunks = IERC721(_frankenpunks);
    frankenmonsters = IERC721(_frankenmonsters);
    governance = IGovernance( _governance );

    executor = IExecutor(_executor);
    founders = _founders;
    council = _council;

    // Staking bonus increases linearly from 0 to 20 votes over 4 weeks
    stakingSettings = StakingSettings({
      maxStakeBonusTime: uint128(4 weeks), 
      maxStakeBonusAmount: uint128(20)
    });

    // Users get a bonus 1 vote per vote, 2 votes per proposal created, and 2 votes per proposal passed
    communityPowerMultipliers = CommunityPowerMultipliers({
      votes: uint64(100), 
      proposalsCreated: uint64(200),
      proposalsPassed: uint64(200)
    });

    // Refunds are initially turned on with 1 day cooldown.
    delegatingRefund = true;
    stakingRefund = true;
    refundCooldown = 1 days;

    // Set the base token URI.
    baseTokenURI = _baseTokenURI;

    // Set the contract URI.
    contractURI = _contractURI;
  }

  /////////////////////////////////
  // OVERRIDE & REVERT TRANSFERS //
  /////////////////////////////////  

  /// @notice Transferring of staked tokens is prohibited, so all transfers will revert
  /// @dev This will also block safeTransferFrom, because of solmate's implementation
  function transferFrom(address, address, uint256) public pure override(ERC721) {
    revert StakedTokensCannotBeTransferred();
  }

  /////////////////////////////////
  /////// TOKEN URI FUNCTIONS /////
  /////////////////////////////////

  /// @notice Token URI to find metadata for each tokenId
  /// @dev The metadata will be a variation on the metadata of the underlying token
  function tokenURI(uint256 _tokenId) public view virtual override(ERC721) returns (string memory) {
    if (ownerOf(_tokenId) == address(0)) revert NonExistentToken();

    string memory baseURI = baseTokenURI;
    return bytes(baseURI).length > 0
      ? string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"))
      : "";
  }

  /////////////////////////////////
  /////// DELEGATION LOGIC ////////
  /////////////////////////////////

  /// @notice Return the address that a given address delegates to
  /// @param _delegator The address to check 
  /// @return The address that the delegator has delegated to
  /// @dev If the delegator has not delegated, this function will return their own address
  function getDelegate(address _delegator) public view returns (address) {
    address current = _delegates[_delegator];
    return current == address(0) ? _delegator : current;
  }

  /// @notice Delegate votes to another address
  /// @param _delegatee The address you wish to delegate to
  /// @dev Refunds gas if delegatingRefund is true and hasn't been used by this user in the past 24 hours
  function delegate(address _delegatee) public {
    if (_delegatee == address(0)) _delegatee = msg.sender;
    
    // Refunds gas if delegatingRefund is true and hasn't been used by this user in the past 24 hours
    if (delegatingRefund && lastDelegatingRefund[msg.sender] + refundCooldown <= block.timestamp) {
      uint256 startGas = gasleft();
      _delegate(msg.sender, _delegatee);
      lastDelegatingRefund[msg.sender] = block.timestamp;
      _refundGas(startGas);
    } else {
      _delegate(msg.sender, _delegatee);
    }
  }

  /// @notice Delegates votes from the sender to the delegatee
  /// @param _delegator The address of the user who called the function and owns the votes being delegated
  /// @param _delegatee The address of the user who will receive the votes
  function _delegate(address _delegator, address _delegatee) internal lockedWhileVotesCast {
    address currentDelegate = getDelegate(_delegator);
    // If currentDelegate == _delegatee, then this function will not do anything
    if (currentDelegate == _delegatee) revert InvalidDelegation();

    // Set the _delegates mapping to the correct address, subbing in address(0) if they are delegating to themselves
    _delegates[_delegator] = _delegatee == _delegator ? address(0) : _delegatee;
    uint amount = votesFromOwnedTokens[_delegator];

    // If the delegator has no votes, then this function will not do anything
    // This is explicitly blocked to ensure that users without votes cannot abuse the refund mechanism
    if (amount == 0) revert InvalidDelegation();
    
    // Move the votes from the currentDelegate to the new delegatee
    // Neither of these addresses can be address(0) because: 
    // - currentDelegate calls getDelegate(), which replaces address(0) with the delegator's address
    // - delegatee is changed to msg.sender in the external functions if address(0) is passed
    tokenVotingPower[currentDelegate] -= amount;
    tokenVotingPower[_delegatee] += amount; 

    // If this moved the current delegate down to zero voting power, then remove their community VP from the totals
    if (tokenVotingPower[currentDelegate] == 0) {
        _updateTotalCommunityVotingPower(currentDelegate, false);
    }

    // If the new delegate previously had zero voting power, then add their community VP to the totals
    if (tokenVotingPower[_delegatee] == amount) {
      _updateTotalCommunityVotingPower(_delegatee, true);
    }

    emit DelegateChanged(_delegator, currentDelegate, _delegatee);
  }

  /// @notice Updates the total community voting power totals
  /// @param _delegator The address of the user who called the function and owns the votes being delegated
  /// @param _increase Should we be increasing or decreasing the totals?
  /// @dev This function is called by _delegate, _stake, and _unstake
  function _updateTotalCommunityVotingPower(address _delegator, bool _increase) internal {
    (uint64 votes, uint64 proposalsCreated, uint64 proposalsPassed) = governance.userCommunityScoreData(_delegator);
    (uint64 totalVotes, uint64 totalProposalsCreated, uint64 totalProposalsPassed) = governance.totalCommunityScoreData();

    if (_increase) {
      governance.updateTotalCommunityScoreData(totalVotes + votes, totalProposalsCreated + proposalsCreated, totalProposalsPassed + proposalsPassed);
    } else {
      governance.updateTotalCommunityScoreData(totalVotes - votes, totalProposalsCreated - proposalsCreated, totalProposalsPassed - proposalsPassed);
    }
  }

  /////////////////////////////////
  /// STAKE & UNSTAKE FUNCTIONS ///
  /////////////////////////////////

  /// @notice Stake your tokens to get voting power
  /// @param _tokenIds An array of the id of the token you wish to stake
  /// @param _unlockTime The timestamp of the time your tokens will be unlocked
  /// @dev unlockTime can be set to 0 to stake without locking (and earn no extra staked time bonus)
  function stake(uint[] calldata _tokenIds, uint _unlockTime) public {
    // Refunds gas if stakingRefund is true and hasn't been used by this user in the past 24 hours
    if (stakingRefund && lastStakingRefund[msg.sender] + refundCooldown <= block.timestamp) {
      uint256 startGas = gasleft();
      _stake(_tokenIds, _unlockTime);
      lastStakingRefund[msg.sender] = block.timestamp;
      _refundGas(startGas);
    } else {
      _stake(_tokenIds, _unlockTime);
    }
  }

  /// @notice Internal function to stake tokens and get voting power
  /// @param _tokenIds An array of the id of the tokens being staked
  /// @param _unlockTime The timestamp of when the tokens will be unlocked
  function _stake(uint[] calldata _tokenIds, uint _unlockTime) internal {
    if (paused) revert Paused();
    if (_unlockTime > 0 && _unlockTime < block.timestamp) revert InvalidParameter();

    uint maxStakeTime = stakingSettings.maxStakeBonusTime;
    if (_unlockTime > 0 && _unlockTime - block.timestamp > maxStakeTime) {
      _unlockTime = block.timestamp + maxStakeTime;
    }

    uint numTokens = _tokenIds.length;
    // This is required to ensure the gas refunds are not abused
    if (numTokens == 0) revert InvalidParameter();
    
    uint newVotingPower;
    for (uint i = 0; i < numTokens; i++) {
        newVotingPower += _stakeToken(_tokenIds[i], _unlockTime);
    }

    votesFromOwnedTokens[msg.sender] += newVotingPower;
    tokenVotingPower[getDelegate(msg.sender)] += newVotingPower;
    totalTokenVotingPower += newVotingPower;

    // If the delegate (including self) had no tokenVotingPower before, they just unlocked their community voting power
    if (tokenVotingPower[getDelegate(msg.sender)] == newVotingPower) {
      // The delegate's community voting power is reactivated, so we add it to the total community voting power
      _updateTotalCommunityVotingPower(getDelegate(msg.sender), true);
    }
  }

  /// @notice Internal function to stake a single token and get voting power
  /// @param _tokenId The id of the token being staked
  /// @param _unlockTime The timestamp of when the token will be unlocked
  function _stakeToken(uint _tokenId, uint _unlockTime) internal returns (uint) {
    if (_unlockTime > 0) {
      unlockTime[_tokenId] = _unlockTime;
      uint fullStakedTimeBonus = ((_unlockTime - block.timestamp) * stakingSettings.maxStakeBonusAmount) / stakingSettings.maxStakeBonusTime;
      stakedTimeBonus[_tokenId] = _tokenId < 10000 ? fullStakedTimeBonus : fullStakedTimeBonus / 2;
    }

    // Transfer the underlying token from the owner to this contract
    IERC721 collection;
    if (_tokenId < 10000) {
      collection = frankenpunks;
      stakedFrankenPunks++;
    } else {
      collection = frankenmonsters;
      stakedFrankenMonsters++;
    }

    address owner = collection.ownerOf(_tokenId);
    if (msg.sender != owner) revert NotAuthorized();
    collection.transferFrom(owner, address(this), _tokenId);

    // Mint the staker a new ERC721 token representing their staked token
    _mint(msg.sender, _tokenId);

    // Return the voting power for this token based on staked time bonus and evil score
    return getTokenVotingPower(_tokenId);
  }

  /// @notice Unstake your tokens and surrender voting power
  /// @param _tokenIds An array of the ids of the tokens you wish to unstake
  /// @param _to The address to send the underlying NFT to
  function unstake(uint[] calldata _tokenIds, address _to) public {
    _unstake(_tokenIds, _to);
  }

  /// @notice Internal function to unstake tokens and surrender voting power
  /// @param _tokenIds An array of the ids of the tokens being unstaked
  /// @param _to The address to send the underlying NFT to
  function _unstake(uint[] calldata _tokenIds, address _to) internal lockedWhileVotesCast {
    uint numTokens = _tokenIds.length;
    if (numTokens == 0) revert InvalidParameter();
    
    uint lostVotingPower;
    for (uint i = 0; i < numTokens; i++) {
        lostVotingPower += _unstakeToken(_tokenIds[i], _to);
    }

    votesFromOwnedTokens[msg.sender] -= lostVotingPower;
    // Since the delegate currently has the voting power, it must be removed from their balance
    // If the user doesn't delegate, delegates(msg.sender) will return self
    tokenVotingPower[getDelegate(msg.sender)] -= lostVotingPower;
    totalTokenVotingPower -= lostVotingPower;

    // If this unstaking reduced the user or their delegate's tokenVotingPower to 0, then someone just lost their community voting power
    // First, check if the user is their own delegate
    if (msg.sender == getDelegate(msg.sender)) {
      // Did their tokenVotingPower just become 0?
      if (tokenVotingPower[msg.sender] == 0) {
        // If so, reduce the total voting power to capture this decrease in the user's community voting power
        _updateTotalCommunityVotingPower(msg.sender, false);
      }
    // If they aren't their own delegate...
    } else {
      // If their delegate's tokenVotingPower reaches 0, that means they were the final unstake and the delegate loses community voting power
      if (tokenVotingPower[getDelegate(msg.sender)] == 0) {
        // The delegate's community voting power is forfeited, so we adjust total community power balances down
        _updateTotalCommunityVotingPower(getDelegate(msg.sender), false);
      }
    }
  }

  /// @notice Internal function to unstake a single token and surrender voting power
  /// @param _tokenId The id of the token being unstaked
  /// @param _to The address to send the underlying NFT to
  function _unstakeToken(uint _tokenId, address _to) internal returns(uint) {
    address owner = ownerOf(_tokenId);
    if (msg.sender != owner) revert NotAuthorized();
    if (unlockTime[_tokenId] > block.timestamp) revert TokenLocked();
    
    // Transfer the underlying token from the owner to this contract
    IERC721 collection;
    if (_tokenId < 10000) {
      collection = frankenpunks;
      --stakedFrankenPunks;
    } else {
      collection = frankenmonsters;
      --stakedFrankenMonsters;
    }
    collection.safeTransferFrom(address(this), _to, _tokenId);

    // Voting power needs to be calculated before staked time bonus is zero'd out, as it uses this value
    uint lostVotingPower = getTokenVotingPower(_tokenId);
    _burn(_tokenId);

    if (unlockTime[_tokenId] > 0) {
      delete unlockTime[_tokenId];
      delete stakedTimeBonus[_tokenId];
    }

    return lostVotingPower;
  }

    //////////////////////////////////////////////
    ///// VOTING POWER CALCULATION FUNCTIONS /////
    //////////////////////////////////////////////
    
    /// @notice Get the total voting power (token + community) for an account
    /// @param _account The address of the account to get voting power for
    /// @return The total voting power for the account
    /// @dev This is used by governance to calculate the voting power of an account
    function getVotes(address _account) public view returns (uint) {
        return tokenVotingPower[_account] + getCommunityVotingPower(_account);
    }
    
    /// @notice Get the voting power for a specific token when staking or unstaking
    /// @param _tokenId The id of the token to get voting power for
    /// @return The voting power for the token
    /// @dev Voting power is calculated as baseVotes + staking bonus (0 to max staking bonus) + evil bonus (0 or 10)
    function getTokenVotingPower(uint _tokenId) public override view returns (uint) {
      if (ownerOf(_tokenId) == address(0)) revert NonExistentToken();

      // If tokenId < 10000, it's a FrankenPunk, so BASE_VOTES, otherwise, divide by 2 for monsters
      uint baseVotes = _tokenId < 10_000 ? BASE_VOTES : BASE_VOTES / 2;
      
      // evilBonus will return 0 for all FrankenMonsters, as they are not eligible for the evil bonus
      return baseVotes + stakedTimeBonus[_tokenId] + evilBonus(_tokenId);
    }

    /// @notice Get the community voting power for a given user
    /// @param _voter The address of the account to get community voting power for
    /// @return The community voting power the user currently has
    function getCommunityVotingPower(address _voter) public override view returns (uint) {
      uint64 votes;
      uint64 proposalsCreated;
      uint64 proposalsPassed;
      
      // We allow this function to be called with the max uint value to get the total community voting power
      if (_voter == address(type(uint160).max)) {
        (votes, proposalsCreated, proposalsPassed) = governance.totalCommunityScoreData();
      } else {
        // This is only the case if they are delegated or unstaked, both of which should zero out the result
        if (tokenVotingPower[_voter] == 0) return 0;

        (votes, proposalsCreated, proposalsPassed) = governance.userCommunityScoreData(_voter);
      }

      CommunityPowerMultipliers memory cpMultipliers = communityPowerMultipliers;

      return (
          (votes * cpMultipliers.votes) + 
          (proposalsCreated * cpMultipliers.proposalsCreated) + 
          (proposalsPassed * cpMultipliers.proposalsPassed)
        ) / PERCENT;
    }

    /// @notice Get the total voting power of the entire system
    /// @return The total votes in the system
    /// @dev This is used to calculate the quorum and proposal thresholds
    function getTotalVotingPower() public view returns (uint) {
      return totalTokenVotingPower + getCommunityVotingPower(address(type(uint160).max));
    }

    function getStakedTokenSupplies() public view returns (uint128, uint128) {
      return (stakedFrankenPunks, stakedFrankenMonsters);
    }

    /// @notice Get the evil bonus for a given token
    /// @param _tokenId The id of the token to get the evil bonus for
    /// @return The evil bonus for the token
    /// @dev The evil bonus is 10 if the token is sufficiently evil, 0 otherwise
    function evilBonus(uint _tokenId) public view returns (uint) {
      if (_tokenId >= 10000) return 0; 
      return (EVIL_BITMAPS[_tokenId >> 8] >> (255 - (_tokenId & 255)) & 1) * 10;
    }

  /////////////////////////////////
  //////// OWNER OPERATIONS ///////
  /////////////////////////////////

  /// @notice Set the max staking time needed to get the max bonus
  /// @param _newMaxStakeBonusTime The new max staking time
  /// @dev This function can only be called by the executor based on a governance proposal
  function changeStakeTime(uint128 _newMaxStakeBonusTime) external onlyExecutor {
    if (_newMaxStakeBonusTime == 0) revert InvalidParameter();
    emit StakeTimeChanged(stakingSettings.maxStakeBonusTime = _newMaxStakeBonusTime);
  }

  /// @notice Set the max staking bonus earned if a token is staked for the max time
  /// @param _newMaxStakeBonusAmount The new max staking bonus
  /// @dev This function can only be called by the executor based on a governance proposal
  function changeStakeAmount(uint128 _newMaxStakeBonusAmount) external onlyExecutor {
    emit StakeAmountChanged(stakingSettings.maxStakeBonusAmount = _newMaxStakeBonusAmount);
  }

  /// @notice Set the community power multiplier for votes
  /// @param _votesMultiplier The multiplier applied to community voting power based on past votes
  /// @dev This function can only be called by the executor based on a governance proposal
  function setVotesMultiplier(uint64 _votesMultiplier) external onlyExecutor {
    emit VotesMultiplierChanged(communityPowerMultipliers.votes = _votesMultiplier);
  }

  /// @notice Set the community power multiplier for proposals created
  /// @param _proposalsCreatedMultiplier The multiplier applied to community voting power based on proposals created
  /// @dev This function can only be called by the executor based on a governance proposal
  function setProposalsCreatedMultiplier(uint64 _proposalsCreatedMultiplier) external onlyExecutor {
    emit ProposalsCreatedMultiplierChanged(communityPowerMultipliers.proposalsCreated = _proposalsCreatedMultiplier);
  }

  /// @notice Set the community power multiplier for proposals passed
  /// @param _proposalsPassedMultiplier The multiplier applied to community voting power based on proposals passed
  /// @dev This function can only be called by the executor based on a governance proposal
  function setProposalsPassedMultiplier(uint64 _proposalsPassedMultiplier) external onlyExecutor {
    emit ProposalPassedMultiplierChanged(communityPowerMultipliers.proposalsPassed =  _proposalsPassedMultiplier);
  }

  /// @notice Turn on or off gas refunds for staking and delegating
  /// @param _stakingRefund Should refunds for staking be on (true) or off (false)?
  /// @param _delegatingRefund Should refunds for delegating be on (true) or off (false)?
  /// @param _newCooldown The amount of time a user must wait between refunds of the same type
  function setRefunds(bool _stakingRefund, bool _delegatingRefund, uint _newCooldown) external onlyExecutor {
    emit RefundSettingsChanged(
      stakingRefund = _stakingRefund, 
      delegatingRefund = _delegatingRefund,
      refundCooldown = _newCooldown
    );
  }

  /// @notice Pause or unpause staking
  /// @param _paused Whether staking should be paused or not
  /// @dev This will be used to open and close staking windows to incentivize participation
  function setPause(bool _paused) external onlyPauserOrAdmins {
    emit StakingPause(paused = _paused);
  }

  /// @notice Set hte base URI for the metadata for the staked token
  /// @param _baseURI The new base URI
  function setBaseURI(string calldata _baseURI) external onlyAdmins {
    emit BaseURIChanged(baseTokenURI = _baseURI);
  }

  /// @notice Set the contract URI for marketplace metadata
  /// @param _newContractURI The new contract URI
  function setContractURI(string calldata _newContractURI) external onlyAdmins {
    emit ContractURIChanged(contractURI = _newContractURI);
  }

  /// @notice Check to confirm that this is a FrankenPunks staking contract
  /// @dev Used by governance when upgrading staking to ensure the correct contract
  /// @dev Used instead of an interface because interface may change
  function isFrankenPunksStakingContract() external pure returns (bool) {
    return true;
  }

  /// @notice Contract can receive ETH (will be used to pay for gas refunds)
  receive() external payable {}

  /// @notice Contract can receive ETH (will be used to pay for gas refunds)
  fallback() external payable {}
}