// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract HyperRace {
	using SafeMath for uint256;
	address public ownerWallet;
	address public marketingWallet;
	address public devAddress;
	address[3] public partners;
	uint256 private constant REFERRAL_LENGTH = 1;
	uint256[REFERRAL_LENGTH] public REFERRAL_PERCENTS = [500];
	uint256 public constant PERCENTS_DIVIDER = 1000;

	uint256 public currUserID;
	uint256 public currUserCount = partners.length;

	mapping(uint256 => uint256) public poolusersCount;
	//mapping(uint => uint) public truePoolusersCount;
	mapping(uint256 => uint256) public poolActiveUserId;
	mapping(uint256 => uint256) public poolPaymentCount;
	mapping(uint256 => uint256) public poolPaymentIndex;
	mapping(uint256 => mapping(uint256 => address)) public pooluserList;
	mapping(uint256 => mapping(address => PoolUserStruct)) public poolusers;
	uint256 public totalSumPoolPrices;
	uint256 public constant minPool = 1;
	uint256 public constant maxPool = 9;
	uint256 public constant MAX_PAYMENT_BY_POOL = 3;

	struct UserStruct {
		bool isExist;
		uint256 id;
		uint256 referrerID;
		uint256[REFERRAL_LENGTH] referredUsers;
		uint256 totalProfit;
	}

	struct PoolUserStruct {
		bool isExist;
		uint256 paymentReceived;
		uint256 totalPayment;
		uint256[] tickets;
	}

	struct PoolUserHistoryStruct {
		address user;
		uint256 paymentReceived;
		uint256 totalPayment;
	}

	mapping(uint256 => mapping(address => PoolUserHistoryStruct)) public poolHistory;
	mapping(address => UserStruct) public users;
	mapping(uint256 => address) public userList;

	uint256 public constant REGESTRATION_FESS = 0.05 ether;

	mapping(uint256 => uint256) public poolPrices;

	event RegLevelEvent(
		address indexed _user,
		address indexed _referrer,
		uint256 _time
	);
	event GetMoneyForLevelEvent(
		address indexed _user,
		address indexed _referral,
		uint256 _level,
		uint256 _time
	);

	event RegPoolEntry(address indexed _user, uint256 _level, uint256 _time);

	event GetPoolPayment(
		address indexed _user,
		address indexed _receiver,
		uint256 _level,
		uint256 _time
	);
	event RefBonus(
		address indexed referrer,
		address indexed referral,
		uint256 indexed level,
		uint256 amount
	);

	event PaymentSent(
		address indexed _from,
		address indexed _to,
		uint256 _amount,
		uint256 _pool
	);
	event FeeSent(address from, uint256 amount);

	event Paused(address account);
	event Unpaused(address account);

	uint256 public initDate;

	mapping(address => bool) internal wL;

	constructor(address _dev, address _mark) {
		ownerWallet = 0xAE49aB6c4C131C3c871b1f57832c3f51608B99A6;
		devAddress = _dev;
		marketingWallet = _mark;

		poolPrices[1] = 0.05 ether;
		poolPrices[2] = 0.1 ether;
		poolPrices[3] = 0.2 ether;
		poolPrices[4] = 0.4 ether;
		poolPrices[5] = 0.8 ether;
		poolPrices[6] = 1.6 ether;
		poolPrices[7] = 3.2 ether;
		poolPrices[8] = 6.4 ether;
		poolPrices[9] = 12.8 ether;

		uint256 _tatalsum = 0;
		for (uint256 i = 1; i <= maxPool; i++) {
			_tatalsum += poolPrices[i];
		}
		totalSumPoolPrices = _tatalsum;

		partners[0] = ownerWallet;
		partners[1] = _mark;
		partners[2] = _dev;

		address[50] memory inversors = [
	0xc498c0f50dAab76DCF9d0E7706D8c792F011e366,
	0x52Be31B721e03bAAE1ec543B5701091BAb00678c,
	0xBb81239b7D5cA6f453174eDfebdd4BD78Af97dD6,
	0x5575BB80F6b525216bC7cee449F7C526cF30c152,
	0xBF9A0E5F7Eab077876aac3b985B82D3e89e93D13,
	0x9330535CD0cb8e899d7103aC0EDDB240CAC21D8f,
	0x32A15D74488589573eC6dAE25fF4Fb865266f55f,
	0x1B1bf81408117A8e9c35e627eb6EEa180A856f21,
	0x8e55ed2E77b807a9713fD20105B173d545918453,
	0x0A5187a651A699A8DfD80A14457ECb4AA2728C7D,
	0xB3C7830c37d2A0a2b014A64c6d579BEfE3586E4A,
	0x565500260e26FD051Ab2FDf3B69d3255F2f5d94E,
	0x5D63783327d5B2e27f833A93719495Eec63A2e24,
	0xbc7227e28e0fE5A419B24d7b481AA8C111483Ce6,
	0xBb81239b7D5cA6f453174eDfebdd4BD78Af97dD6,
	0x40800438030b5677Ef9CDD8B7383aa55ba890aCb,
	0x4b44646eeEe13AEe0FA08458673c8e2Ee734d908,
	0xdf56921481d1349d2e826ECCa13CB88C7c882b68,
	0x1DCa2E99Da609A37a451d9AdF35Dfd661BE0aCDb,
	0x319EF8ED14A0C542707eE48eed54311eA27Dec17,
	0x88EccB078006466e2e5e5DB16d3358B76156DfDe,
	0xBCBF2339919143bBd9d98853C5838bDD3a05e1ef,
	0x40800438030b5677Ef9CDD8B7383aa55ba890aCb,
	0xbc7227e28e0fE5A419B24d7b481AA8C111483Ce6,
	0xBF9A0E5F7Eab077876aac3b985B82D3e89e93D13,
	0x0e20B8B7359CF61F953f640c212AE55c12768449,
	0x9330535CD0cb8e899d7103aC0EDDB240CAC21D8f,
	0x2c692F7FA629eF794D79b8715FCecF0bb549886C,
	0x0Eb9d3E753D24251C6E1ddE7e96A9753Bf472Af6,
	0xd33B0b6FdB041A5c5A5AeB3c53735a375bC1c847,
	0x47FF19D5A35126c207E8CF81bEEDf9Db0cB823F9,
	0xcFbD4B692F4A0a0659EB3081D5b2B8326EFfd7A5,
	0x11aBd95dbBeE2A30AF0498F35008Fc50412F9A66,
	0x26e08e012CD6fEf8B67b37413B9290C6B1c51544,
	0x254C45b3D426a03884dA3CEeb5547e55D3465671,
	0x42f287347b65a687332A8fbAf6B9Cb2bc65201A5,
	0x641DB6594c2191DC6449C671B14CD90872114c52,
	0x02aA815C98d849F84ff543e7DAa6eF591e5a30b9,
	0x4A167de7806e3C2B77aF57cEB8BD3B457ebCe6f9,
	0x4429fD6b2E181DB973D9ec832bFc0a2Ca441e38D,
	0xb6C01Ca261bD30ED0242078c3bd08Da93E1917f0,
	0xB66c19eF4506cb5AA1e00eF93e04e4085497d078,
	0xAB80a64A2d3D66E4C83512A0f58D639472115E96,
	0x177BeC525b4D9E4B7f61A318A5470A48912d6b09,
	0x4341Bdf54e6A992bc59696B0228d4988116777d8,
	0xb7EDE228220Ef60B4E0D346f5000D712E7F26b61,
	0x6B70aeE21326de60E8082d8d5FbeDff30a119FE6,
	0x847FD5A43A6D711814cd4bea5595BE7131D27198,
	0x8C7bEB533A72ae137bfEb02b24824280E5C47Ac1,
	0x430d914F9fb3e27a4f1eD899d50d10De3002D269
		];

		initPools(inversors);

		emit Paused(msg.sender);
	}

	function getBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getMaxDeposits() public pure returns (uint256) {
		return MAX_PAYMENT_BY_POOL;
	}

	modifier onlyUsers() {
		require(users[msg.sender].isExist, "User no Exists");
		_;
	}

	function regUser(uint256 _referrerID) external payable checkReg {
		uint256 _amount = msg.value;
		require(!users[msg.sender].isExist, "User Exists");
		require(
			_referrerID > 0 && _referrerID <= currUserID,
			"Incorrect referral ID"
		);
		require(_amount == REGESTRATION_FESS, "Incorrect Value");

		UserStruct storage userStruct = users[msg.sender];
		currUserID++;
		currUserCount++;
		userStruct.isExist = true;
		userStruct.id = currUserID;
		userStruct.referrerID = _referrerID;
		userList[currUserID] = msg.sender;
		referralUpdate(msg.sender);
		payReferral(msg.sender, _amount);
		emit RegLevelEvent(msg.sender, userList[_referrerID], block.timestamp);
	}

	function referralUpdate(address _user) internal {
		address upline = userList[users[_user].referrerID];
		for (uint256 i; i < REFERRAL_PERCENTS.length; i++) {
			UserStruct storage user_ = users[upline];
			if (upline != address(0)) {
				user_.referredUsers[i] += 1;
				upline = userList[user_.referrerID];
			} else break;
		}
	}

	function payReferral(address _user, uint256 investAmt) internal {
		address upline = userList[getReferrerID(_user)];
		uint256 payed;
		for (uint256 i; i < REFERRAL_PERCENTS.length; i++) {
			if (upline != address(0)) {
				uint256 amount = (investAmt.mul(REFERRAL_PERCENTS[i])).div(
					PERCENTS_DIVIDER
				);
				payed += amount;
				payHandler(upline, amount);
				emit RefBonus(upline, msg.sender, i, amount);
				upline = userList[getReferrerID(upline)];
			} else break;
		}
		payFees(investAmt.sub(payed));
		emit FeeSent(msg.sender, investAmt.sub(payed));
	}

	function buyPool(uint256 _pool) external payable onlyUsers {
		uint256 investAmt = msg.value;
		PoolUserStruct storage pooluser_ = poolusers[_pool][msg.sender];
		require(!pooluser_.isExist, "Already in AutoPool");
		require(investAmt == poolPrices[_pool], "Incorrect Value");
		require(_pool >= minPool && _pool <= maxPool, "Incorrect Pool");
		if (_pool > minPool) {
			require(
				canBuyPool(_pool, msg.sender),
				"ready in pool or is in previous pool"
			);
		}
		/*if(!pooluser_.isExist) {
			pooluser_.isExist = true;
			truePoolusersCount[_pool]++;
		}*/
		buyHandler(_pool, msg.sender, true);
	}

	function buyHandler(
		uint256 _pool,
		address sender,
		bool _withPay
	) internal {
		poolusersCount[_pool]++;
		PoolUserStruct storage pooluser_ = poolusers[_pool][sender];
		pooluser_.tickets.push(poolusersCount[_pool]);

		pooluserList[_pool][poolusersCount[_pool]] = sender;
		pooluser_.isExist = true;
		emit RegPoolEntry(sender, _pool, block.timestamp);
		if (_withPay) {
			payPool(sender, _pool);
		}
	}

	function initPayPool(address _addrs, uint256 _pool) internal {
		PoolUserStruct storage _pooluser = poolusers[_pool][_addrs];
		_pooluser.paymentReceived += 1;
		_pooluser.totalPayment += 1;
		poolPaymentCount[_pool]++;
		users[_addrs].totalProfit += poolPrices[_pool];
	}

	function canBuyPool(uint256 _pool, address _user)
		internal
		view
		returns (bool)
	{
		if (poolusers[_pool][_user].isExist) {
			return false;
		}
		if (_pool == minPool) {
			return true;
		} else {
			return poolusers[_pool - 1][_user].isExist;
		}
	}

	/*function payPool(address _sender, uint _pool) internal {
		address _poolCurrentUser = pooluserList[_pool][poolActiveUserId[_pool]];
		PoolUserStruct storage pooluser_ = poolusers[_pool][_poolCurrentUser];
		initPayPool(_poolCurrentUser, _pool);

		// event
		emit GetPoolPayment(_sender, _poolCurrentUser, _pool, block.timestamp);

		uint paymentReceived = pooluser_.paymentReceived;
		uint _reserves = poolReserves[_pool];

		if(paymentReceived >= getMaxDeposits(_pool)) {
			poolActiveUserId[_pool]++;
			delete pooluser_.paymentReceived;
		}

		if(paymentReceived == REINVEST_THRESOLD) {
			delete poolReserves[_pool];
			if(canBuyPool(_poolCurrentUser, _pool)) {
				buyHandler(_pool+1, _poolCurrentUser);
			} else {
				PoolUserHistoryHandler(_poolCurrentUser,_reserves, _pool);
				payHandler(_poolCurrentUser, _reserves);
				emit PaymentSent(_sender, _poolCurrentUser, _reserves, _pool);
			}

		} else if(paymentReceived >= getMaxDeposits(_pool)) {
			delete poolReserves[_pool];
			PoolUserHistoryHandler(_poolCurrentUser,_reserves, _pool);

			payHandler(_poolCurrentUser, _reserves);
			emit PaymentSent(_sender, _poolCurrentUser, _reserves, _pool);
		}
	}*/

	function payPool(address _sender, uint256 _pool) internal {
		address _poolCurrentUser = pooluserList[_pool][poolActiveUserId[_pool]];
		PoolUserStruct storage pooluser_ = poolusers[_pool][_poolCurrentUser];
		initPayPool(_poolCurrentUser, _pool);
		uint256 _price = poolPrices[_pool];

		// event
		emit GetPoolPayment(_sender, _poolCurrentUser, _pool, block.timestamp);

		uint256 paymentReceived = pooluser_.paymentReceived;

		if (paymentReceived >= getMaxDeposits()) {
			emit PaymentSent(_sender, _poolCurrentUser, _price, _pool);
			poolActiveUserId[_pool]++;
			delete pooluser_.paymentReceived;
			//payFees(_price);
			emit FeeSent(_sender, _price);
			uint256 nextPool;
			if (_pool == maxPool) {
				pooluser_.isExist = false;
				uint256 toUser = _price * 3;
				for (uint256 i = minPool; i <= maxPool; i++) {
					nextPool = i;
					if (canBuyPool(nextPool, _poolCurrentUser)) {
						toUser -= poolPrices[nextPool];
						buyHandler(nextPool, _poolCurrentUser, true);
					}
				}
				payHandler(_poolCurrentUser, toUser);
			} else {
				nextPool = _pool + 1;
				if (canBuyPool(nextPool, _poolCurrentUser)) {
					pooluser_.isExist = false;
					payHandler(
						_poolCurrentUser,
						(_price * 3) - poolPrices[nextPool]
					);
					buyHandler(nextPool, _poolCurrentUser, true);
				} else {
					pooluser_.isExist = false;
					payHandler(_poolCurrentUser, _price * 3);
				}
			}
		}
	}

	function PoolUserHistoryHandler(
		address _poolCurrentUser,
		uint256 _reserves,
		uint256 _pool
	) internal {
		PoolUserHistoryStruct storage _pooluserHistory = poolHistory[_pool][
			_poolCurrentUser
		];
		_pooluserHistory.paymentReceived += 1;
		_pooluserHistory.user = _poolCurrentUser;
		_pooluserHistory.totalPayment += _reserves;
		poolPaymentIndex[_pool]++;
	}

	function initPools(address[50] memory _inversors) internal {
		for (uint256 j; j < partners.length; j++) {
			address partner = partners[j];
			UserStruct storage userStruct = users[partner];
			currUserID++;

			userStruct.isExist = true;
			userStruct.id = currUserID;

			userList[currUserID] = partner;
			for (uint256 i = minPool; i <= maxPool; i++) {
				poolusers[i][partner].isExist = true;
				poolusersCount[i]++;
				PoolUserStruct memory pooluserStruct = PoolUserStruct({
					isExist: true,
					paymentReceived: 0,
					totalPayment: 0,
					tickets: new uint256[](0)
				});

				poolActiveUserId[i] = 1;
				poolusers[i][partner] = pooluserStruct;
				poolusers[i][partner].tickets.push(poolusersCount[i]);
				pooluserList[i][poolusersCount[i]] = partner;
			}
		}

		for (uint256 j; j < _inversors.length; j++) {
			address partner = _inversors[j];
			UserStruct storage userStruct = users[partner];
			currUserID++;

			userStruct.isExist = true;
			userStruct.id = currUserID;

			userList[currUserID] = partner;
			for (uint256 i = minPool; i <= minPool; i++) {
				poolusers[i][partner].isExist = true;
				poolusersCount[i]++;
				PoolUserStruct memory pooluserStruct = PoolUserStruct({
					isExist: true,
					paymentReceived: 0,
					totalPayment: 0,
					tickets: new uint256[](0)
				});

				poolusers[i][partner] = pooluserStruct;
				poolusers[i][partner].tickets.push(poolusersCount[i]);
				pooluserList[i][poolusersCount[i]] = partner;
			}
		}
		currUserCount += _inversors.length;
	}

	function payHandler(address _to, uint256 _amount) private {
		if (_to == address(0)) {
			payFees(_amount);
		} else {
			if (getBalance() < _amount) {
				payable(_to).transfer(getBalance());
			} else {
				payable(_to).transfer(_amount);
			}
		}
	}

	function payFees(uint256 _amount) private {
		uint256 _toOwners = _amount.div(3);
		payHandler(marketingWallet, _toOwners);
		payHandler(ownerWallet, _toOwners);
		payHandler(devAddress, _amount.sub(_toOwners * 2));
	}

	function getReferrerID(address _user) public view returns (uint256) {
		return users[_user].referrerID;
	}

	function getUserData(address _user)
		external
		view
		returns (
			bool isExist_,
			uint256 id_,
			uint256 referrerID_,
			uint256[REFERRAL_LENGTH] memory referredUsers_,
			uint256 totalProfit_
		)
	{
		UserStruct memory user_ = users[_user];

		isExist_ = user_.isExist;
		id_ = user_.id;
		referrerID_ = user_.referrerID;
		referredUsers_ = user_.referredUsers;
		totalProfit_ = user_.totalProfit;
	}

	function getAllPoolusersinfo(address _user)
		external
		view
		returns (PoolUserStruct[] memory)
	{
		PoolUserStruct[] memory poolInfo = new PoolUserStruct[](maxPool);

		for (uint256 i; i < maxPool; i++) {
			poolInfo[i] = poolusers[i + 1][_user];
		}
		return poolInfo;
	}

	function getAllPooluser(uint256 _user)
		external
		view
		returns (address[] memory)
	{
		uint256 length = poolusersCount[_user];
		address[] memory poolInfo = new address[](length);

		for (uint256 i; i < length; i++) {
			poolInfo[i] = pooluserList[_user][i + 1];
		}
		return poolInfo;
	}

	function CountPooluser() external view returns (uint256[] memory) {
		uint256 length = maxPool;
		uint256[] memory poolInfo = new uint256[](length);

		for (uint256 i; i < length; i++) {
			poolInfo[i] = poolusersCount[i + 1];
		}
		return poolInfo;
	}

	struct PoolShow {
		address user;
		uint256 id;
		uint256 totalPayment;
		uint256 paymentReceived;
	}

	function getAllPoolUserAndProfit(uint256 id)
		external
		view
		returns (PoolShow[] memory)
	{
		uint256 length = poolusersCount[id];
		return getAllPoolUserAndProfitRange(id, 0, length);
	}

	function getAllPoolUserAndProfitRange(
		uint256 id,
		uint256 start,
		uint256 length
	) public view returns (PoolShow[] memory) {
		PoolShow[] memory poolShow = new PoolShow[](length);

		for (uint256 i = start; i < length; i++) {
			address _poolCurrentUser = pooluserList[id][i + 1];
			PoolUserHistoryStruct memory _pooluserHistory = poolHistory[id][
				_poolCurrentUser
			];
			poolShow[i].user = _poolCurrentUser;
			poolShow[i].id = users[_poolCurrentUser].id;
			poolShow[i].totalPayment = _pooluserHistory.totalPayment;
			poolShow[i].paymentReceived = _pooluserHistory.paymentReceived;
		}
		return poolShow;
	}

	function getActiveUserData(uint256 _pool)
		external
		view
		returns (
			address _user,
			uint256 _id,
			uint256 _paymentReceived,
			uint256 _poolPaymentCount,
			uint256 _index
		)
	{
		address _poolCurrentUser = pooluserList[_pool][poolActiveUserId[_pool]];
		PoolUserStruct storage pooluser_ = poolusers[_pool][_poolCurrentUser];
		_user = _poolCurrentUser;
		_id = poolActiveUserId[_pool];
		_paymentReceived = pooluser_.paymentReceived;
		_poolPaymentCount = poolPaymentCount[_pool];
		_index = poolPaymentIndex[_pool];
	}

	modifier onlyOwner() {
		require(devAddress == msg.sender, "Ownable: caller is not the owner");
		_;
	}

	function canReg(address _user) public view returns (bool) {
		if (isPaused()) {
			if (wL[_user]) {
				return true;
			} else {
				return false;
			}
		}
		return true;
	}

	modifier checkReg() {
		require(canReg(msg.sender), "User is not registered");
		_;
	}

	modifier whenNotPaused() {
		require(initDate > 0, "Pausable: paused");
		_;
	}

	modifier whenPaused() {
		require(initDate == 0, "Pausable: not paused");
		_;
	}

	function unpause() external whenPaused onlyOwner {
		initDate = block.timestamp;
		emit Unpaused(msg.sender);
	}

	function isPaused() public view returns (bool) {
		return (initDate == 0);
	}

	function getDAte() public view returns (uint256) {
		return block.timestamp;
	}

	function sw(address[] calldata _users, bool _status) external onlyOwner {
		for (uint256 i; i < _users.length; i++) {
			wL[_users[i]] = _status;
		}
	}
}