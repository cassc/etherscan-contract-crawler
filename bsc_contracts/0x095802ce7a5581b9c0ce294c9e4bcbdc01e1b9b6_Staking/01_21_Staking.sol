//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./APIConsumer.sol";

contract Staking is Ownable {
	IERC721 public nftCollection;

	string private rarityBaseURL =
		"http://stakeserver-production.up.railway.app/";
	APIConsumer public apiConsumer;
	//staking
	struct Staker {
		uint256[] stakedIds;
		uint256 timeOfLastUpdate;
		uint256 unclaimedRewards;
	}

	mapping(address => Staker) public stakers;
	mapping(uint256 => address) public stakerAddress;

	uint256 private rewardsPerHour = 5000000000;
	address[] public stakersArray;

	uint256 public startTime;
	uint256 public lockupDuration;

	uint256 public lockupPeriod;
	bool public isStakingEnabled;

	modifier stakingEnabled() {
		require(isStakingEnabled == true, "Staking not enabled");
		_;
	}

	modifier stakingLocked() {
		require(
			block.timestamp >= lockupPeriod,
			"No withdraw until lockup ends"
		);
		_;
	}

	event StakingStarted(uint256 startTime, uint256 lockupPeriod);
	event Staked(address owner, uint256 tokenId);
	event Unstaked(address owner, uint256 tokenId);
	event RewardClaimed(address owner, uint256 amount);

	/**
	 * @notice Executes once when a contract is created to initialize state variables
	 * @param _nftCollection - address of the NFT to stake
	 * Goerli Testnet details:
	 * Link Token: 0x326C977E6efc84E512bB9C30f76E30c160eD06FB
	 * Oracle: 0xCC79157eb46F5624204f47AB42b3906cAA40eaB7 (Chainlink DevRel)
	 * jobId: 53f9755920cd451a8fe46f5087468395
	 */
	constructor(
		IERC721 _nftCollection,
		address _chainlinkToken,
		address _chainlinkOracle
	) {
		nftCollection = _nftCollection;
		//chainlinkToken, chainlinkOracle, jobId
		apiConsumer = new APIConsumer(_chainlinkToken, _chainlinkOracle);
		lockupDuration = 7 days;
	}

	//////////////////////////////////////
	/////          Staking           /////
	//////////////////////////////////////

	function stake(uint256 _tokenId) public stakingEnabled {
		_stake(msg.sender, _tokenId);
	}

	function _stake(address _user, uint256 _tokenId) internal {
		require(
			nftCollection.ownerOf(_tokenId) == _user,
			"Can't stake tokens you don't own!"
		);
		if (apiConsumer.getRarity(_tokenId) == 0) {
			apiConsumer.requestMultipleParameters(_tokenId);
			apiConsumer.setCurrentId(_tokenId);
		}

		if (stakers[_user].stakedIds.length > 0) {
			uint256 rewards = calculateRewards(msg.sender);
			stakers[msg.sender].unclaimedRewards += rewards;
		} else {
			stakersArray.push(msg.sender);
		}

		nftCollection.transferFrom(_user, address(this), _tokenId);
		stakerAddress[_tokenId] = _user;

		stakers[_user].stakedIds.push(_tokenId);
		stakers[_user].timeOfLastUpdate = block.timestamp;

		emit Staked(_user, _tokenId);
	}

	function stakeBatch(uint256[] memory tokenIds) public stakingEnabled {
		for (uint256 i = 0; i < tokenIds.length; i++) {
			_stake(msg.sender, tokenIds[i]);
		}
	}

	function unstake(uint256 _tokenId) public stakingEnabled stakingLocked {
		require(
			stakers[msg.sender].stakedIds.length > 0,
			"You have no tokens staked"
		);
		_unstake(msg.sender, _tokenId);
	}

	function unstakeBatch(uint256[] memory _tokenIds)
		public
		stakingEnabled
		stakingLocked
	{
		for (uint256 i = 0; i < _tokenIds.length; i++) {
			_unstake(msg.sender, _tokenIds[i]);
		}
	}

	function _unstake(address _user, uint256 _tokenId) internal {
		require(
			stakerAddress[_tokenId] == _user,
			"User must be the owner of the staked nft"
		);
		uint256 rewards = calculateRewards(_user);
		stakers[_user].unclaimedRewards += rewards;

		stakerAddress[_tokenId] = address(0);
		uint256 amount = stakers[_user].stakedIds.length;
		for (uint256 i = 0; i < amount; i++) {
			if (stakers[_user].stakedIds[i] == _tokenId)
				stakers[_user].stakedIds[i] = stakers[_user].stakedIds[amount - 1];
		}
		stakers[_user].stakedIds.pop();

		if (stakers[_user].stakedIds.length == 0) {
			for (uint256 i; i < stakersArray.length; ++i) {
				if (stakersArray[i] == _user) {
					stakersArray[i] = stakersArray[stakersArray.length - 1];
					stakersArray.pop();
				}
			}
		}

		stakers[_user].timeOfLastUpdate = block.timestamp;

		nftCollection.transferFrom(address(this), _user, _tokenId);

		emit Unstaked(_user, _tokenId);
	}

	function claimRewards() external {
		uint256 rewards = calculateRewards(msg.sender) +
			stakers[msg.sender].unclaimedRewards;
		require(rewards > 0, "You have no rewards to claim");

		stakers[msg.sender].timeOfLastUpdate = block.timestamp;
		stakers[msg.sender].unclaimedRewards = 0;

		address payable user = payable(msg.sender);
		user.transfer(rewards);
	}

	/////////////////////
	// View of staking //
	/////////////////////

	function userStakeInfo(address _user)
		public
		view
		returns (uint256 _tokensStaked, uint256 _availableRewards)
	{
		return (stakers[_user].stakedIds.length, availableRewards(_user));
	}

	function availableRewards(address _user)
		internal
		view
		returns (uint256)
	{
		if (stakers[_user].stakedIds.length == 0) {
			return stakers[_user].unclaimedRewards;
		}
		uint256 _rewards = stakers[_user].unclaimedRewards +
			calculateRewards(_user);
		return _rewards;
	}

	function calculateRewards(address _staker)
		internal
		view
		returns (uint256 _rewards)
	{
		Staker memory staker = stakers[_staker];

		for (uint256 i = 0; i < staker.stakedIds.length; i++) {
			uint256 tokenId = staker.stakedIds[i];
			_rewards += (((block.timestamp - staker.timeOfLastUpdate) *
				rewardsPerHour *
				apiConsumer.getRarity(tokenId)) / 3600);
		}
	}

	function getBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getLinkBalance() external view returns (uint256 balanceLink) {
		balanceLink = apiConsumer.getLinkBalance();
	}

	function getRarityInfo(uint256 _tokenId)
		public
		view
		returns (uint256 rarity)
	{
		rarity = apiConsumer.getRarity(_tokenId);
	}

	/////////////////////
	// Admin function  //
	/////////////////////

	function startStaking() external onlyOwner {
		setStakingStatus(true);
		startTime = block.timestamp;
		lockupPeriod = startTime + lockupDuration;
		emit StakingStarted(startTime, lockupDuration);
	}

	function setStakingStatus(bool status) public onlyOwner {
		isStakingEnabled = status;
	}

	function setRewardsPerhour(uint256 rewardRate) external onlyOwner {
		rewardsPerHour = rewardRate;
	}

	function setLockup(uint256 lockupDays) public onlyOwner {
		lockupDuration = lockupDays;
		if (startTime > 0) {
			lockupPeriod = block.timestamp + lockupDays * 1 days;
		}
	}

	function setRarityBaseURL(string memory _url) external onlyOwner {
		rarityBaseURL = _url;
	}

	//oracle
	function setJobId(bytes32 _jobId) external onlyOwner {
		apiConsumer.setJobId(_jobId);
	}

	function setOracle(address _oracle) external onlyOwner {
		apiConsumer.setOracle(_oracle);
	}

	function deposit() public payable {}

	function withdrawMoney() public onlyOwner {
		address payable to = payable(msg.sender);
		to.transfer(getBalance());
	}

	function withdrawLink() public onlyOwner {
		apiConsumer.withdrawLink(msg.sender);
	}
}