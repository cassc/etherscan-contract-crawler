/**
 *Submitted for verification at Etherscan.io on 2019-11-25
*/

//
//                               __     __               __
//    _________ ___  ____ ______/ /_   / /__ _   _____  / /
//   / ___/ __ `__ \/ __ `/ ___/ __/  / / _ \ | / / _ \/ / 
//  (__  ) / / / / / /_/ / /  / /_   / /  __/ |/ /  __/ /  
// /____/_/ /_/ /_/\__,_/_/   \__/  /_/\___/|___/\___/_/   
//
//
// Telegram: @smartlvl
// hashtag: #smartlvl


pragma solidity ^0.5.11;

contract Smartlevel {
	address public creator;
	uint public currentUserID;

	mapping(uint => uint) public levelPrice;
	mapping(address => User) public users;
	mapping(uint => address) public userAddresses;

	uint MAX_LEVEL = 10;
	uint REFERRALS_LIMIT = 3;
	uint LEVEL_DURATION = 15 days;

	struct User {
		uint id;
		uint referrerID;
		address[] referrals;
		mapping (uint => uint) levelExpiresAt;
	}

	event RegisterUserEvent(address indexed user, address indexed referrer, uint time, uint id, uint expires);
	event BuyLevelEvent(address indexed user, uint indexed level, uint time, uint expires);
	event GetLevelProfitEvent(address indexed user, address indexed referral, uint indexed level, uint time);
	event LostLevelProfitEvent(address indexed user, address indexed referral, uint indexed level, uint time);

	modifier userNotRegistered() {
		require(users[msg.sender].id == 0, 'User is already registered');
		_;
	}

	modifier userRegistered() {
		require(users[msg.sender].id != 0, 'User does not exist');
		_;
	}

	modifier validReferrerID(uint _referrerID) {
		require(_referrerID > 0 && _referrerID <= currentUserID, 'Invalid referrer ID');
		_;
	}

	modifier validLevel(uint _level) {
		require(_level > 0 && _level <= MAX_LEVEL, 'Invalid level');
		_;
	}

	modifier validLevelAmount(uint _level) {
		require(msg.value == levelPrice[_level], 'Invalid level amount');
		_;
	}

	constructor() public {
		levelPrice[1] = 0.03 ether;
		levelPrice[2] = 0.09 ether;
		levelPrice[3] = 0.15 ether;
		levelPrice[4] = 0.3 ether;
		levelPrice[5] = 0.35 ether;
		levelPrice[6] = 0.6 ether;
		levelPrice[7] = 1 ether;
		levelPrice[8] = 2 ether;
		levelPrice[9] = 5 ether;
		levelPrice[10] = 10 ether;

		currentUserID++;

		creator = 0x91c59276d6f1360BEB35e7e5105FE6A0BD26df2c;

		users[creator] = createNewUser(0);
		userAddresses[currentUserID] = creator;

		for(uint i = 1; i <= MAX_LEVEL; i++) {
			users[creator].levelExpiresAt[i] = 113131641600;
		}
	}

	function() external payable {
		uint level;

		for(uint i = 1; i <= MAX_LEVEL; i++) {
			if(msg.value == levelPrice[i]) {
				level = i;
				break;
			}
		}

		require(level > 0, 'Invalid amount has sent');

		if(users[msg.sender].id != 0) {
			buyLevel(level);
			return;
		}

		if(level != 1) {
			revert('Buy first level for 0.03 ETH');
		}

		address referrer = bytesToAddress(msg.data);
		registerUser(users[referrer].id);
	}
	
	function registerUser(uint _referrerID) public payable userNotRegistered() validReferrerID(_referrerID) validLevelAmount(1) {
		if(users[userAddresses[_referrerID]].referrals.length >= REFERRALS_LIMIT) {
			_referrerID = users[findReferrer(userAddresses[_referrerID])].id;
		}

		currentUserID++;

		users[msg.sender] = createNewUser(_referrerID);
		userAddresses[currentUserID] = msg.sender;
		users[msg.sender].levelExpiresAt[1] = now + LEVEL_DURATION;

		users[userAddresses[_referrerID]].referrals.push(msg.sender);

		transferLevelPayment(1, msg.sender);
		emit RegisterUserEvent(msg.sender, userAddresses[_referrerID], now, currentUserID, users[msg.sender].levelExpiresAt[1]);
	}

	function buyLevel(uint _level) public payable userRegistered() validLevel(_level) validLevelAmount(_level) {
		for(uint l = _level - 1; l > 0; l--) {
			require(getUserLevelExpiresAt(msg.sender, l) >= now, 'Buy the previous level');
		}

		if(getUserLevelExpiresAt(msg.sender, _level) < now) {
			users[msg.sender].levelExpiresAt[_level] = now + LEVEL_DURATION;
		} else {
			users[msg.sender].levelExpiresAt[_level] += LEVEL_DURATION;
		}

		transferLevelPayment(_level, msg.sender);
		emit BuyLevelEvent(msg.sender, _level, now, users[msg.sender].levelExpiresAt[_level]);
	}

	function findReferrer(address _user) public view returns(address) {
		if(users[_user].referrals.length < REFERRALS_LIMIT) {
			return _user;
		}

		address[1200] memory referrals;
		referrals[0] = users[_user].referrals[0];
		referrals[1] = users[_user].referrals[1];
		referrals[2] = users[_user].referrals[2];

		address referrer;

		for(uint i = 0; i < 1200; i++) {
			if(users[referrals[i]].referrals.length < REFERRALS_LIMIT) {
				referrer = referrals[i];
				break;
			}

			if(i >= 400) {
				continue;
			}

			referrals[(i + 1) * 3] = users[referrals[i]].referrals[0];
			referrals[(i + 1) * 3 + 1] = users[referrals[i]].referrals[1];
			referrals[(i + 1) * 3 + 2] = users[referrals[i]].referrals[2];
		}

		require(referrer != address(0), 'Referrer was not found');

		return referrer;
	}

	function transferLevelPayment(uint _level, address _user) internal {
		uint height = _level % 2 == 0 ? 2 : 1;
		address referrer = getUserUpline(_user, height);

		if(referrer == address(0)) {
			referrer = creator;
		}

		if(getUserLevelExpiresAt(referrer, _level) < now) {
			emit LostLevelProfitEvent(referrer, msg.sender, _level, now);
			transferLevelPayment(_level, referrer);
			return;
		}

		if(addressToPayable(referrer).send(msg.value)) {
			emit GetLevelProfitEvent(referrer, msg.sender, _level, now);
		}
	}


	function getUserUpline(address _user, uint height) public view returns(address) {
		if(height <= 0 || _user == address(0)) {
			return _user;
		}

		return this.getUserUpline(userAddresses[users[_user].referrerID], height - 1);
	}

	function getUserReferrals(address _user) public view returns(address[] memory) {
		return users[_user].referrals;
	}

	function getUserLevelExpiresAt(address _user, uint _level) public view returns(uint) {
		return users[_user].levelExpiresAt[_level];
	}


	function createNewUser(uint _referrerID) private view returns(User memory) {
		return User({ id: currentUserID, referrerID: _referrerID, referrals: new address[](0) });
	}

	function bytesToAddress(bytes memory _addr) private pure returns(address addr) {
		assembly {
			addr := mload(add(_addr, 20))
		}
	}

	function addressToPayable(address _addr) private pure returns(address payable) {
		return address(uint160(_addr));
	}
}