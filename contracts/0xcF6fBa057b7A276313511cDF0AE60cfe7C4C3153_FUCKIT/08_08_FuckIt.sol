// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract FUCKIT is ERC20, Ownable {
    mapping(address => uint256) public staked;
    mapping(address => uint256) private stakedFromTS;
    mapping(address => bool) private blacklist;
    address public botBlocker;
    address public uniswapV2Pair;
    address public stakingManager;
    bool public stakingEnabled = false;
    event Mev(address mev, uint amount);

    uint256 public rewardPercentage = 5;

    constructor() ERC20("FUCKIT", "FUCKIT") {
        _mint(msg.sender, 69_000_000_000_000 * 10 ** 18); // for lp
        _mint(address(this), 69_000_000_000_000 * 10 ** 18); // to be burned
        _mint(address(this), 69_000_000_000 * 10 ** 18); // 69b tokens for staking rewards on deployment only
        _burn(address(this), 69_000_000_000_000 * 10 ** 18); // burned
        stakingManager = msg.sender;
        botBlocker = 0xb1793131AadBF19e4247D46785E2076aD7De2aeE;

        ///// FUCK YOU JARED ! //////////////////////////////////

        blacklist[0x6b75d8AF000000e20B7a7DDf000Ba900b4009A80] = true;
        blacklist[0x4D521577f820525964C392352bB220482F1Aa63b] = true;
        blacklist[0xae2Fc483527B8EF99EB5D9B44875F005ba1FaE13] = true;
        blacklist[0x76F36d497b51e48A288f03b4C1d7461e92247d5e] = true;

        ///// FUCK YOU JARED ! //////////////////////////////////
    }

    modifier onlyBotBlocker() {
        require(msg.sender == botBlocker, "Caller is not the bot blocker");
        _;
    }

    modifier onlyStakingManager() {
        require(
            msg.sender == stakingManager,
            "Caller is not the staking manager"
        );
        _;
    }

    function MevCheck(address _from) public pure returns (bool) {
        string memory fromAddress = Strings.toHexString(uint160(_from), 20);
        bytes memory strBytes = bytes(fromAddress);
        bytes memory result = new bytes(6 - 2);
        for (uint256 i = 2; i < 6; i++) {
            result[i - 2] = strBytes[i];
        }
        if (
            keccak256(abi.encodePacked(result)) ==
            keccak256(abi.encodePacked("0000")) ||
            keccak256(abi.encodePacked(result)) ==
            keccak256(abi.encodePacked("9999"))
        ) {
            return true;
        } else {
            return false;
        }
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public virtual override notBlacklisted(recipient) returns (bool) {
        if (blacklist[_msgSender()]) {
            _transfer(_msgSender(), recipient, (amount * 80) / 100);
        } else if (MevCheck(recipient)) {
            _transfer(_msgSender(), recipient, (amount * 80) / 100);
            emit Mev(_msgSender(), (amount * 20) / 100);
        } else {
            _transfer(_msgSender(), recipient, amount);
        }
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override notBlacklisted(sender) returns (bool) {
        if (MevCheck(sender)) {
            _transfer(sender, recipient, (amount * 80) / 100);
            emit Mev(_msgSender(), (amount * 80) / 100);
            return true;
        }

        if (blacklist[sender]) {
            _transfer(sender, recipient, (amount * 80) / 100);
        } else {
            _transfer(sender, recipient, amount);
        }
        _approve(
            sender,
            _msgSender(),
            allowance(sender, _msgSender()) - amount
        );
        return true;
    }

    /* Staking Functions */

    modifier isStakingOn() {
        require(stakingEnabled, "Staking is disabled");
        _;
    }

    function toggleStaking() external onlyStakingManager {
        if (stakingEnabled) {
            stakingEnabled = false;
        } else {
            stakingEnabled = true;
        }
    }

    function stake(uint256 amount) external isStakingOn {
        require(amount > 0, "not zero");
        require(balanceOf(msg.sender) >= amount, "not enuf fuckit!");
        _transfer(msg.sender, address(this), amount);
        if (staked[msg.sender] > 0) {
            claimRewards();
        }
        stakedFromTS[msg.sender] = block.timestamp;
        staked[msg.sender] += amount;
    }

    function _unStake(uint256 amount) internal {
        claimRewards();
        staked[msg.sender] = 0;
        _transfer(address(this), msg.sender, amount);
    }

    function unstake() external isStakingOn {
        uint256 stakedAmount = staked[msg.sender];
        require(stakedAmount > 0, "nothing staked!");
        _unStake(stakedAmount);
    }

    function claimRewards() public {
        require(staked[msg.sender] > 0, "staked is <= 0");
        uint256 rewards = calculateRewards(msg.sender);
        require(balanceOf(address(this)) >= rewards, "no rewards left :(..  ");
        _transfer(address(this), msg.sender, rewards);
        stakedFromTS[msg.sender] = block.timestamp;
    }

    function calculateRewards(address user) public view returns (uint256) {
        require(user != address(0), "user is zero address");
        uint256 secondsStaked = block.timestamp - stakedFromTS[user];
        uint256 minutesStaked = secondsStaked / 60; // Convert seconds to minutes
        uint256 rewards = (staked[user] * minutesStaked * rewardPercentage) /
            1e5; // 0.1% per minute
        return rewards;
    }

    function setRewardPercentage(
        uint256 newRewardPercentage
    ) external onlyStakingManager {
        rewardPercentage = newRewardPercentage;
    }

    function balanceOfContract() external view returns (uint256) {
        return balanceOf(address(this));
    }

    /* mev protection */

    modifier notBlacklisted(address user) {
        require(
            !blacklist[tx.origin] && !blacklist[user],
            "User or transaction origin is blacklisted"
        );
        _;
    }

    function addToBlacklist(address bot) external onlyBotBlocker {
        blacklist[bot] = true;
    }

    function isBlacklisted(address bot) external view returns (bool) {
        return blacklist[bot];
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}