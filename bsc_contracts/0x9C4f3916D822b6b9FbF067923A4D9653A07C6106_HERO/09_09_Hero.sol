//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

// import "hardhat/console.sol";


interface IPool {
	function swapTokenTo(address to) external payable returns(uint);
}

contract HERO is OwnableUpgradeable, PausableUpgradeable {
	uint tradeNo;
	uint _mintId;
	uint public MINT_VALUE;

	event onPublicMint(uint tradeNo);
	event onUpgrade(uint upgradeNo);
	

	error OverMaxOneDayBuy();
	error NotEnoughBNB();
	error OnlyOneOrTen();

	struct MintInfo {
		address player;
		uint num;
	}
	mapping (uint => MintInfo) mints;

	struct UpgradeInfo {
		uint heroId;
		uint fee;
		address player;
	}
	mapping (uint => UpgradeInfo) upgrades;
	uint _upgradeId;
	IERC20 token;
	address public feeReceiver;
	uint public OneDayMaxBuy;
	uint public CurDayBuy;
	uint256 public resetTime;
  uint256 public RESET_TIME_PERIOD;

	//inviter
	mapping (address=>address) public inviters;
	uint public inviteFee;
	mapping (address=>uint) public inviterCounts;
	mapping (address=>uint) public inviterFees;

	IPool pool;
	address public constant blackHole = 0x0000000000000000000000000000000000000001;

	function initialize(address _pool) public initializer {
		__Ownable_init();
		__Pausable_init();

		MINT_VALUE = 0.1 ether;

		pool = IPool(_pool);
  }

	function timeSync() public {
    if (block.timestamp - resetTime >= RESET_TIME_PERIOD) {
      resetTime =
        resetTime +
        ((block.timestamp - resetTime) / RESET_TIME_PERIOD) *
        RESET_TIME_PERIOD;
			CurDayBuy = 0; 
    }
  }

	function publicMint(uint num, address inviter) public payable whenNotPaused {
		if(num!=1 && num != 10) revert OnlyOneOrTen();
		if(msg.value < MINT_VALUE *num ) revert NotEnoughBNB();
		// console.log("num is ", num);

		timeSync();

		//bind inviter
		if(inviter!=address(0) && inviter != msg.sender){
			if(inviters[msg.sender] == address(0)){
				inviters[msg.sender] = inviter;

				inviterCounts[inviter] += 1;
			}
		}

		CurDayBuy += num;
		if(CurDayBuy>OneDayMaxBuy)revert OverMaxOneDayBuy();

		_mintId += 1;

    uint itemId = uint(keccak256(abi.encodePacked(_mintId, msg.sender, address(this))));
		mints[itemId] = (MintInfo({
			player: msg.sender,
			num: num
		}));

		
		//invite fee
		uint amount = msg.value;
		// console.log("amount is ", amount);
		if(inviters[msg.sender]!=address(0)){
			uint fee = msg.value * inviteFee / 100;
			// console.log("fee is ", fee);
			amount -= fee * 2;
			if(fee>0){
				// payable(inviters[msg.sender]).transfer(fee);
				if(address(pool)!=address(0)) {
					inviterFees[inviters[msg.sender]] += pool.swapTokenTo{value: fee}(inviters[msg.sender]);
					inviterFees[msg.sender] += pool.swapTokenTo{value: fee}(msg.sender);
				}
			}
		}

		if(feeReceiver!=address(0)){
			payable(feeReceiver).transfer(amount);
		}

		emit onPublicMint(itemId);
	}

	function getMintInfo(uint mintId) public view returns(MintInfo memory){
		return mints[mintId];
	}

	function getUpgradeInfo(uint upgradeId) public view returns (UpgradeInfo memory){
		return upgrades[upgradeId];
	}

	/**
	 * upgrade
	 */
	function upgrade(uint heroId, uint fee) public whenNotPaused {
		// [2500,6250 ,12000 ,20000 ,33250] 
		require(token.transferFrom(msg.sender, blackHole, fee), "token transfer error");

		_upgradeId += 1;

    uint itemId = uint(keccak256(abi.encodePacked(_upgradeId, msg.sender, address(this), "upgrade")));
		upgrades[itemId] = (UpgradeInfo({
			heroId: heroId,
			fee: fee,
			player: msg.sender
		}));

		emit onUpgrade(itemId);
	}

	function getTodayBuyInfo() public view returns(uint,uint) {
		//如果还没有人mint，信息没同步则发初始值 
		if (block.timestamp - resetTime > RESET_TIME_PERIOD) {
      return (OneDayMaxBuy, 0);
    }
		return (OneDayMaxBuy, CurDayBuy);
	}

	function setMintValue(uint mintValue) external onlyOwner {
		MINT_VALUE = mintValue;
	}

	function setToken(IERC20 _token) external onlyOwner {	
		token = _token;
	}

	function setFeeReceiver(address _feeReceiver) external onlyOwner {
		feeReceiver = _feeReceiver;
	}

	function setOnedayMaxBuy(uint _value) external onlyOwner {
		OneDayMaxBuy = _value;
	}

	function setResetTime(uint256 _resetTime)
    public
    onlyOwner
  {
    resetTime = _resetTime;
  }

  function setResetTimePeriod(uint256 _resetTimePeriod)
    public
    onlyOwner
  {
    require(_resetTimePeriod > 0);
    RESET_TIME_PERIOD = _resetTimePeriod;
  }

	function setInviteFee(uint _fee) external onlyOwner {
		require(_fee>=0 && _fee<=100);
		inviteFee = _fee;		
	}

	function setPool(address _pool) external onlyOwner {
		pool = IPool(_pool);
	}

	function cleanInviter(address to) external onlyOwner {
		inviterCounts[to] = 0;
		inviterFees[to] = 0;
	}
	
}