// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../bees/BeeNFT.sol";
import "../bees/HoneyPots.sol";

contract QueenTax is Ownable {
    event Withdraw(address indexed holder, uint256 amount);
    event WithdrawQueen(address indexed holder);

    using SafeERC20 for IERC20;

    uint256 numberOfPrincess = 660;
    uint256 numberOfRoyals = 220;

    uint256 public totalTax = 0;
    uint256 public taxPerPrincess = 0;
    uint256 public taxPerRoyal = 0;

    IERC20 public rewardToken;
    BeeNFT public beeNFT;
    bool public paused;

    uint256 public permaLockPeriod;
    bool public permaLock = false;

    uint256 totalClaimed = 0;
    mapping(uint256 => uint256) public princessClaimed;
    mapping(uint256 => uint256) public royalClaimed;

    constructor(
        address _rewardToken,
        address _beeNFT,
        uint256 _permalockPeriod
    ) {
        rewardToken = IERC20(_rewardToken);
        beeNFT = BeeNFT(_beeNFT);
        permaLockPeriod = _permalockPeriod * 1 days;

        paused = false;
    }

    function earnedRoyal(uint256 _beeID) public view returns (uint256) {
        uint256 _taxPerRoyal = (rewardToken.balanceOf(address(this)) + totalClaimed - totalTax) / 2 / numberOfRoyals;

        return _taxPerRoyal - royalClaimed[_beeID];
    }

    function earnedPrincess(uint256 _beeID) public view returns (uint256) {
        uint256 _taxPerPrincess = (rewardToken.balanceOf(address(this)) + totalClaimed - totalTax) / 2 / numberOfPrincess;

        return _taxPerPrincess - princessClaimed[_beeID];
    }

    function claim(uint256[] memory _queenIDs) public taxUpdate {
        require(!paused, "Contract is paused.");

        uint256 totalAmount = 0;

        for (uint256 i = 0; i < _queenIDs.length; i++) {
            require(
                msg.sender == beeNFT.ownerOf(_queenIDs[i]),
                "not owner of queen"
            ); // validate ownership
            if (beeNFT.QueenRegistry(_queenIDs[i]) == 1) {
                // is royal

                uint256 currentEarned = taxPerRoyal - royalClaimed[_queenIDs[i]];

                royalClaimed[_queenIDs[i]] += currentEarned;

                require(
                    royalClaimed[_queenIDs[i]] <= taxPerRoyal,
                    "Exceeded claming amount"
                ); //just double check to avoid giving more per bee

                totalAmount += currentEarned;
            } else if (beeNFT.QueenRegistry(_queenIDs[i]) == 2) {
                // princess
                uint256 currentEarned = taxPerPrincess - princessClaimed[_queenIDs[i]];
                princessClaimed[_queenIDs[i]] += currentEarned;
                require(
                    princessClaimed[_queenIDs[i]] <= taxPerPrincess,
                    "Exceeded claming amount"
                ); //just double check to avoid giving more per bee

                totalAmount += currentEarned;
            } else {
                revert("not queen");
            }
        }
        totalClaimed += totalAmount;
        rewardToken.safeTransfer(msg.sender, totalAmount); // transfer current earned to msg.sender

        emit WithdrawQueen(msg.sender);
    }

    function setTaxPerPrincess(uint256 _amount) internal {
        taxPerPrincess += _amount / numberOfPrincess;
    }

    function setTaxPerRoyal(uint256 _amount) internal {
        taxPerRoyal += _amount / numberOfRoyals;
    }

    modifier taxUpdate() {
        uint256 _amount = rewardToken.balanceOf(address(this)) +
            totalClaimed -
            totalTax;
        setTaxPerPrincess(_amount / 2);
        setTaxPerRoyal(_amount / 2);
        totalTax = rewardToken.balanceOf(address(this)) + totalClaimed;
        _;
    }

    function pauseContract(bool _paused) external onlyOwner {
        paused = _paused;
    }

    function setNumberOfPrincess(uint256 _number, uint256 _type)
        external
        onlyOwner
    {
        if (_type == 1) {
            numberOfRoyals = _number;
        }

        if (_type == 2) {
            numberOfPrincess = _number;
        }
    }

    function setPermaLock() external onlyOwner {
        require(block.timestamp < permaLockPeriod, "Time lock in place");
        permaLock = true;
    }

    function migrationFailsafe(address _escrow) external onlyOwner {
        require(block.timestamp < permaLockPeriod, "Time lock in place");
        require(!permaLock, "LOCKED");
        rewardToken.safeTransfer(_escrow, rewardToken.balanceOf(address(this)));
    }
}