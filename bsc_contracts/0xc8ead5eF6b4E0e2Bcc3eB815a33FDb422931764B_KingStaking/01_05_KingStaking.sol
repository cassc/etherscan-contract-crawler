// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract KingStaking {
    using SafeERC20 for IERC20;

    address immutable public owner;
    IERC20 immutable public kingToken;

    uint256[3] public periods = [7 days, 14 days, 21 days];
    uint16[3] public rates = [2065, 4690, 8085];
    uint256 public rewardsPool;
    uint256 public MAX_STAKES = 100;

    uint256 constant public DENOMINATOR = 10000;

     struct Stake {
        uint8 class;
        uint256 initialAmount;
        uint256 finalAmount;
        uint256 timestamp;
        bool unstaked;
    }

    Stake[] public stakes;
    mapping(address => uint256[]) public stakesOf;
    mapping(uint256 => address) public ownerOf;

    event Staked(address indexed sender, uint8 indexed class, uint256 amount, uint256 finalAmount);
    event Prolonged(address indexed sender, uint8 indexed class, uint256 newAmount, uint256 newFinalAmount);
    event Unstaked(address indexed sender, uint8 indexed class, uint256 amount);
    event IncreaseRewardsPool(address indexed adder, uint256 added, uint256 newSize);

    modifier restricted {
        require(msg.sender == owner, "This function is restricted to owner");
        _;
    }

    modifier ready(uint256 _index) {
        require(msg.sender == ownerOf[_index], 'Not owner');
        Stake storage _s = stakes[_index];
        require(!_s.unstaked, 'Already unstaked'); // not unstaked yet
        require(block.timestamp >= _s.timestamp + periods[_s.class], 'Not finished'); // staking period finished
        _;
    }

    constructor(address _kingToken) {
        owner = msg.sender;
        kingToken = IERC20(_kingToken);
    }

    function stakesInfo(uint256 _from, uint256 _to) external view returns (Stake[] memory s) {
        s = new Stake[](_to - _from);
        for (uint256 i = _from; i < _to; i++) s[i - _from] = stakes[i];
    }

    function stakesInfoAll() external view returns (Stake[] memory s) {
        s = new Stake[](stakes.length);
        for (uint256 i = 0; i < stakes.length; i++) s[i] = stakes[i];
    }

    function stakesLength() external view returns (uint256) {
        return stakes.length;
    }

    function myStakes(address _me) external view returns (Stake[] memory s, uint256[] memory indexes) {
        s = new Stake[](stakesOf[_me].length);
        indexes = new uint256[](stakesOf[_me].length);
        for (uint256 i = 0; i < stakesOf[_me].length; i++) {
            indexes[i] = stakesOf[_me][i];
            s[i] = stakes[indexes[i]];
        }
    }

    function myActiveStakesCount(address _me) public view returns (uint256 l) {
        uint256[] storage _s = stakesOf[_me];
        for (uint256 i = 0; i < _s.length; i++) if (!stakes[_s[i]].unstaked) l++;
    }

    function stake(uint8 _class, uint _amount) external {
        require(_class < 3, "Wrong class"); // data valid
        require(myActiveStakesCount(msg.sender) < MAX_STAKES, "MAX_STAKES overflow"); // has space for new active stake
        uint256 _finalAmount = _amount + (_amount * rates[_class]) / DENOMINATOR;
        require(rewardsPool >= _finalAmount - _amount, "Rewards pool is empty for now");
        rewardsPool -= _finalAmount - _amount;
        kingToken.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _index = stakes.length;
        stakesOf[msg.sender].push(_index);
        stakes.push(Stake({
            class: _class,
            initialAmount: _amount,
            finalAmount: _finalAmount,
            timestamp: block.timestamp,
            unstaked: false
        }));
        ownerOf[_index] = msg.sender;
        emit Staked(msg.sender, _class, _amount, _finalAmount);
    }

    function compound(uint256 _index) external ready(_index) {
        Stake storage _s = stakes[_index];
        uint256 _amount = _s.initialAmount + (_s.initialAmount * rates[_s.class]) / DENOMINATOR;
        uint256 _finalAmount = _amount + (_amount * rates[_s.class]) / DENOMINATOR;
        require(rewardsPool >= _finalAmount - _amount, "Rewards pool is empty for now");
        rewardsPool -= _finalAmount - _amount;
        _s.initialAmount = _amount;
        _s.finalAmount = _finalAmount;
        _s.timestamp = block.timestamp;
        emit Prolonged(msg.sender, _s.class, _amount, _finalAmount);
    }

    function unstake(uint256 _index) external ready(_index) {
        Stake storage _s = stakes[_index];
        uint256 _reward = (_s.initialAmount * rates[_s.class]) / DENOMINATOR;
        kingToken.safeTransfer(msg.sender, _reward + _s.initialAmount);
        _s.unstaked = true;
        emit Unstaked(msg.sender, _s.class, _s.finalAmount);
    }

    function increaseRewardsPool(uint256 _amount) external {
      kingToken.safeTransferFrom(msg.sender, address(this), _amount);
      rewardsPool += _amount;
      emit IncreaseRewardsPool(msg.sender, _amount, rewardsPool);
    }

    function updateMax(uint256 _max) external restricted {
        MAX_STAKES = _max;
    }
}