// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract IRewardDistributionRecipient is Ownable {
    address public rewardDistribution;

    function notifyRewardAmount(uint256 reward, uint256 _duration)
        external
        virtual;

    modifier onlyRewardDistribution() {
        require(
            _msgSender() == rewardDistribution,
            "Caller is not reward distribution"
        );
        _;
    }

    function setRewardDistribution(address _rewardDistribution)
        external
        onlyOwner
    {
        rewardDistribution = _rewardDistribution;
    }
}

contract FightNight_V1_USDT is IRewardDistributionRecipient, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant endTime = 1824422400;

    string public constant desc = "Fight Night Dubai 2022: Player1 vs Player2";
    IERC20 public USDT;
    address public croupier;
    bool public isPaused;
    bool public isCanceled;
    bool public isFinal;
    bool public isFeesClaimed;
    enum Fighter {
        Undecided,
        Player_2,
        Player_1
    }
    Fighter public winner;

    mapping(address => uint256) public Player_1USDTBet;
    mapping(address => uint256) public Player_2USDTBet;

    uint256 public Player_1USDTPot;
    uint256 public Player_2USDTPot;

    mapping(address => bool) private lock;

    event Player_1USDTBetevent(address indexed user, uint256 amount);
    event Player_2USDTBetevent(address indexed user, uint256 amount);
    event EarningsPaid(address indexed user, uint256 usdtEarnings);

    modifier checkStatus() {
        require(!isFinal, "fight is decided");
        require(!isCanceled, "fight is canceled, claim your bet");
        require(!isPaused, "betting not started");
        require(block.timestamp < endTime, "betting has ended");
        _;
    }

    constructor(address _croupier, address _usdt) {
        croupier = _croupier;

        USDT = IERC20(_usdt);
        rewardDistribution = msg.sender;
    }

    function USDTBet(Fighter fighter, uint256 amount)
        public
        checkStatus
        nonReentrant
    {
        require(amount != 0, "no token sent");
        if (fighter == Fighter.Player_1) {
            uint256 _before = USDT.balanceOf(address(this));
            USDT.safeTransferFrom(msg.sender, address(this), amount);
            uint256 _after = USDT.balanceOf(address(this));
            uint256 _amount = _after.sub(_before);
            Player_1USDTBet[msg.sender] += _amount;
            Player_1USDTPot += _amount;
            emit Player_1USDTBetevent(msg.sender, _amount);
        } else if (fighter == Fighter.Player_2) {
            uint256 _before = USDT.balanceOf(address(this));
            USDT.safeTransferFrom(msg.sender, address(this), amount);
            uint256 _after = USDT.balanceOf(address(this));
            uint256 _amount = _after.sub(_before);
            Player_2USDTBet[msg.sender] += _amount;
            Player_2USDTPot += _amount;
            emit Player_2USDTBetevent(msg.sender, _amount);
        } else {
            revert("LFG! Pick one already!");
        }
    }

    function pauseBetting() external onlyRewardDistribution {
        isPaused = true;
    }

    function unpauseBetting() external onlyRewardDistribution {
        isPaused = false;
    }

    function cancelFight() external onlyRewardDistribution {
        require(!isFinal, "fight is decided");
        isCanceled = true;
    }

    function finalizeFight(Fighter fighter) external onlyRewardDistribution {
        require(!isFinal, "fight is decided");
        require(!isCanceled, "fight is canceled");
        require(
            fighter == Fighter.Player_1 || fighter == Fighter.Player_2,
            "invalid fighter"
        );
        winner = fighter;
        isFinal = true;
    }

    function getFees()
        external
        onlyRewardDistribution
        returns (uint256 usdtFees)
    {
        require(!isFeesClaimed, "fees claimed");
        require(isFinal, "fight is not ended yet!");
        isFeesClaimed = true;

        if (winner == Fighter.Player_1) {
            usdtFees = Player_2USDTPot.mul(1e18).div(1e19);
            if (usdtFees != 0) {
                USDT.safeTransfer(msg.sender, usdtFees);
            }
        } else if (winner == Fighter.Player_2) {
            usdtFees = Player_1USDTPot.mul(1e18).div(1e19);
            if (usdtFees != 0) {
                USDT.safeTransfer(msg.sender, usdtFees);
            }
        }
    }

    function earned(address account)
        public
        view
        returns (uint256 usdtEarnings)
    {
        if (isFinal) {
            uint256 _Player_1USDTBet = Player_1USDTBet[account];
            uint256 _Player_2USDTBet = Player_2USDTBet[account];

            uint256 winnings;
            uint256 fee;

            if (winner == Fighter.Player_1 && _Player_1USDTBet != 0) {
                winnings = Player_2USDTPot.mul(_Player_1USDTBet).div(
                    Player_1USDTPot
                );
                fee = winnings.mul(1e18).div(1e19);
                winnings = winnings.sub(fee);
                usdtEarnings = _Player_1USDTBet.add(winnings);
            } else if (winner == Fighter.Player_2 && _Player_2USDTBet != 0) {
                winnings = Player_1USDTPot.mul(_Player_2USDTBet).div(
                    Player_2USDTPot
                );
                fee = winnings.mul(1e18).div(1e19);
                winnings = winnings.sub(fee);
                usdtEarnings = _Player_2USDTBet.add(winnings);
            }
        } else if (isCanceled) {
            usdtEarnings = Player_1USDTBet[account] + Player_2USDTBet[account];
        }
    }

    function getRewards() public nonReentrant {
        require(isFinal || isCanceled, "fight not decided");
        require(!lock[msg.sender], "you have already wotdraw your reward");

        uint256 usdtEarnings = earned(msg.sender);
        lock[msg.sender] = true;

        if (usdtEarnings != 0) {
            Player_1USDTBet[msg.sender] = 0;
            Player_2USDTBet[msg.sender] = 0;
            USDT.safeTransfer(msg.sender, usdtEarnings);

            // _safeTransfer(usdtEarnings);
        }
        emit EarningsPaid(msg.sender, usdtEarnings);
    }

    function _safeTransfer(uint256 _amount) internal {
        uint256 _balance = USDT.balanceOf(address(this));
        if (_amount > _balance) {
            _amount = _balance;
            // }
            USDT.safeTransfer(msg.sender, _amount);
        }
    }

    function setCroupier(address _addr) public onlyOwner {
        croupier = _addr;
    }

    function getPlayerinformationUsdt(address sender)
        public
        view
        returns (
            uint256 _Player_1USDTBet,
            uint256 _Player_2USDTBet,
            uint256 _Player_1USDTPot,
            uint256 _Player_2USDTPot
        )
    {
        _Player_1USDTBet = Player_1USDTBet[sender];
        _Player_2USDTBet = Player_2USDTBet[sender];
        _Player_1USDTPot = Player_1USDTPot;
        _Player_2USDTPot = Player_2USDTPot;
    }

    //! unused
    function notifyRewardAmount(uint256, uint256) external pure override {
        return;
    }
}