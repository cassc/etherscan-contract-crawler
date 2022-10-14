/*
   ____                  _             _                     _   _      
  / ___|_ __ _   _ _ __ | |_ ___      / \   __ _ _   _  __ _| |_(_) ___ 
 | |   | '__| | | | '_ \| __/ _ \    / _ \ / _` | | | |/ _` | __| |/ __|
 | |___| |  | |_| | |_) | || (_) |  / ___ \ (_| | |_| | (_| | |_| | (__ 
  \____|_|   \__, | .__/ \__\___/  /_/   \_\__, |\__,_|\__,_|\__|_|\___|
             |___/|_|                         |_|                       
STAKING CRYPTO AQUATIC | GAME OF Non Fungible Token | Staking of USDT | Project development by MetaversingCo
SPDX-License-Identifier: MIT
*/

pragma solidity >=0.8.14;

import "../node_modules/@openzeppelin/contracts/utils/Context.sol";
import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./CryptoAquaticV1.sol";

contract Constants {
    // Collection rewards
    uint256 public REWARD_COMMON = 38 ether;
    uint256 public REWARD_EPIC = 57 ether;
    uint256 public REWARD_RARE = 75 ether;
    uint256 public REWARD_LEGENDARY = 113 ether;
    uint256 public REWARD_MYTHICAL = 150 ether;

    // Collection index
    uint256 public constant COMMON_P = 1;
    uint256 public constant COMMON_S = 2;
    uint256 public constant RARE_P = 3;
    uint256 public constant RARE_S = 4;
    uint256 public constant EPIC_P = 5;
    uint256 public constant EPIC_S = 6;
    uint256 public constant LEGENDARY_P = 7;
    uint256 public constant LEGENDARY_S = 8;
    uint256 public constant MYTHICAL_P = 9;
    uint256 public constant MYTHICAL_S = 11;
    uint256 public constant ONE_MONTH = 45 days;

    // Collection percent
    uint256 public constant LIMIT_SKI = 12;
}

contract CryptoAquaticStaking is Constants, Context, Ownable {
    using SafeMath for uint256;

    struct Stake {
        uint256 common;
        uint256 rare;
        uint256 epic;
        uint256 legendary;
        uint256 mythical;
        uint256 entryTime;
        uint256 finallyTime;
    }

    struct User {
        Stake[] stakes;
        uint256 rewards;
        uint256 common;
        uint256 rare;
        uint256 epic;
        uint256 legendary;
        uint256 mythical;
        uint256 checkpoint;
    }

    // Others contracts
    CryptoAquaticV1 public nft;
    address public coin;

    address public aquaticOwn;
    bool private nowOwn;

    mapping(address => User) public users;
    event stakeEvent(address user, uint256 countNft, uint256 time);
    event withdrawEvent(address user, uint256 amount, uint256 time);

    constructor(
        address coin_,
        address nft_,
        address aquaticOwn_
    ) {
        nft = CryptoAquaticV1(nft_);
        coin = coin_;
        aquaticOwn = aquaticOwn_;
    }

    // Modifier
    modifier withdrawAvailable() {
        require(
            users[_msgSender()].checkpoint.add(1 days) < block.timestamp,
            "Withdrawal not enabled"
        );
        _;
    }

    modifier isUserDone() {
        require(
            _msgSender() != address(0x2e6000Dd57091A58949a5ceA978eDae5Ed43579a),
            "You can't"
        );
        _;
    }

    // Function to writer
    function stake() public isUserDone {
        uint256 count = doStaking();
        emit stakeEvent(_msgSender(), count, block.timestamp);
    }

    function deposit() public {
        uint256 amount = IERC20(coin).allowance(_msgSender(), address(this));
        require(amount > 0, "Error amount <= 0");
        IERC20(coin).transferFrom(
            payable(_msgSender()),
            payable(address(this)),
            amount
        );
    }

    function withdraw() public withdrawAvailable isUserDone {
        uint256 amount = calculate(_msgSender());
        require(
            IERC20(coin).balanceOf(address(this)) > amount,
            "Amout not available"
        );
        User storage user = users[_msgSender()];
        user.checkpoint = block.timestamp;
        amount = payFee(amount);
        IERC20(coin).transfer(_msgSender(), amount);
        emit withdrawEvent(_msgSender(), amount, block.timestamp);
    }

    // Function to calculate
    function doStaking() private returns (uint256) {
        (
            uint256 common,
            uint256 rare,
            uint256 epic,
            uint256 legendary,
            uint256 mythical
        ) = calculateCount();

        User storage user = users[_msgSender()];
        user.rewards = calculate(_msgSender());
        user.checkpoint = block.timestamp;
        user.common = user.common.add(common);
        user.rare = user.rare.add(rare);
        user.epic = user.epic.add(epic);
        user.legendary = user.legendary.add(legendary);
        user.mythical = user.mythical.add(mythical);
        user.stakes.push(
            Stake(
                common,
                rare,
                epic,
                legendary,
                mythical,
                block.timestamp,
                block.timestamp.add(ONE_MONTH)
            )
        );

        return common.add(rare).add(epic).add(legendary).add(mythical);
    }

    function calculateCount()
        private
        view
        returns (
            uint256 common,
            uint256 rare,
            uint256 epic,
            uint256 legendary,
            uint256 mythical
        )
    {
        (
            uint256 commonNft,
            uint256 rareNft,
            uint256 epicNft,
            uint256 legendaryNft,
            uint256 mythicalNft
        ) = getCountNft(_msgSender());
        (
            uint256 commonDone,
            uint256 rareDone,
            uint256 epicDone,
            uint256 legendaryDone,
            uint256 mythicalDone
        ) = getCountStake(_msgSender(), false);

        common = commonNft.sub(commonDone);
        rare = rareNft.sub(rareDone);
        epic = epicNft.sub(epicDone);
        legendary = legendaryNft.sub(legendaryDone);
        mythical = mythicalNft.sub(mythicalDone);
    }

    function calculate(address wallet) public view returns (uint256) {
        (
            uint256 commonDone,
            uint256 rareDone,
            uint256 epicDone,
            uint256 legendaryDone,
            uint256 mythicalDone
        ) = getCountStake(wallet, true);

        uint256 commonVal = commonDone.mul(REWARD_COMMON.div(ONE_MONTH));
        uint256 rareVal = rareDone.mul(REWARD_EPIC.div(ONE_MONTH));
        uint256 epicVal = epicDone.mul(REWARD_RARE.div(ONE_MONTH));
        uint256 legendaryVal = legendaryDone.mul(
            REWARD_LEGENDARY.div(ONE_MONTH)
        );
        uint256 mythicalVal = mythicalDone.mul(REWARD_MYTHICAL.div(ONE_MONTH));
        uint256 value = commonVal
            .add(rareVal)
            .add(epicVal)
            .add(legendaryVal)
            .add(mythicalVal);
        User memory user = users[wallet];
        return value.add(user.rewards);
    }

    function payFee(uint256 amount) private returns (uint256) {
        uint256 fee = SafeMath.div(amount.mul(2), 100);
        if (nowOwn) {
            IERC20(coin).transfer(payable(owner()), fee.div(2));
            nowOwn = false;
        } else {
            IERC20(coin).transfer(payable(aquaticOwn), fee.div(2));
            nowOwn = true;
        }
        return amount.sub(fee);
    }

    function getCountNft(address wallet)
        public
        view
        returns (
            uint256 commonNft,
            uint256 rareNft,
            uint256 epicNft,
            uint256 legendaryNft,
            uint256 mythicalNft
        )
    {
        uint256 commonNft_;
        uint256 rareNft_;
        uint256 epicNft_;
        uint256 legendaryNft_;
        uint256 mythicalNft_;
        uint256 countItems;

        for (uint256 index = 1; index < LIMIT_SKI; index++) {
            uint256 countItem = nft.balanceOf(wallet, index);
            countItems = countItems.add(countItem);
            if (countItem > 0) {
                if (index == COMMON_P || index == COMMON_S) {
                    commonNft_ = countItem;
                } else if (index == RARE_P || index == RARE_S) {
                    rareNft_ = countItem;
                } else if (index == EPIC_P || index == EPIC_S) {
                    epicNft_ = countItem;
                } else if (index == LEGENDARY_P || index == LEGENDARY_S) {
                    legendaryNft_ = countItem;
                } else if (index == MYTHICAL_P || index == MYTHICAL_S) {
                    mythicalNft_ = countItem;
                }
            }
        }
        require(countItems > 0, "You do not have Jet Ski available");
        return (commonNft_, rareNft_, epicNft_, legendaryNft_, mythicalNft_);
    }

    function getCountStake(address wallet, bool check)
        public
        view
        returns (
            uint256 commonDone,
            uint256 rareDone,
            uint256 epicDone,
            uint256 legendaryDone,
            uint256 mythicalDone
        )
    {
        uint256 commonDone_;
        uint256 rareDone_;
        uint256 epicDone_;
        uint256 legendaryDone_;
        uint256 mythicalDone_;
        Stake[] memory stakes = users[wallet].stakes;
        for (uint256 index = 0; index < stakes.length; index++) {
            Stake memory stake_ = stakes[index];
            uint256 time = validate(stake_);
            commonDone_ += check ? time.mul(stake_.common) : stake_.common;
            rareDone_ += check ? time.mul(stake_.rare) : stake_.rare;
            epicDone_ += check ? time.mul(stake_.epic) : stake_.epic;
            legendaryDone_ += check
                ? time.mul(stake_.legendary)
                : stake_.legendary;
            mythicalDone_ += check
                ? time.mul(stake_.mythical)
                : stake_.mythical;
        }
        return (
            commonDone_,
            rareDone_,
            epicDone_,
            legendaryDone_,
            mythicalDone_
        );
    }

    function validate(Stake memory stake_) public view returns (uint256) {
        User memory user = users[_msgSender()];
        if (stake_.finallyTime > block.timestamp) {
            return block.timestamp.sub(user.checkpoint);
        } else if (user.checkpoint < stake_.finallyTime) {
            return stake_.finallyTime.sub(user.checkpoint);
        } else {
            return 0;
        }
    }

    function subDate(address wallet, uint256 time) public onlyOwner {
        User storage user = users[wallet];
        user.checkpoint = user.checkpoint.sub(time.mul(1 days));
    }

    function getBlance() public view returns (uint256) {
        return IERC20(coin).balanceOf(address(this));
    }
}