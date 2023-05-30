// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// This contract is derived from xSushi from Sushiswap https://github.com/sushiswap/sushiswap/blob/master/contracts/SushiBar.sol
// We added cooldown period

// This contract handles swapping to and from sMuse, NFT20's staking token.
contract StakedMuse is ERC20("stakedMUSE", "sMuse") {
    using SafeMath for uint256;

    IERC20 public muse = IERC20(0xB6Ca7399B4F9CA56FC27cBfF44F4d2e4Eef1fc81);
    mapping(address => uint256) public timeLock;
    uint256 public unlockPeriod = 10 days;

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    // Enter the bar. Pay some Muse. Earn some shares.
    // Locks Muse and mints sMuse
    function enter(uint256 _amount) public {
        timeLock[msg.sender] = 0; //reset timelock in case they stake twice.
        // Gets the amount of Muse locked in the contract
        uint256 totalMuse = muse.balanceOf(address(this));
        // Gets the amount of sMuse in existence
        uint256 totalShares = totalSupply();
        // If no sMuse exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalMuse == 0) {
            _mint(msg.sender, _amount);
        }
        // Calculate and mint the amount of sMuse the Muse is worth. The ratio will change overtime, as sMuse is burned/minted and Muse deposited + gained from fees / withdrawn.
        else {
            uint256 what = _amount.mul(totalShares).div(totalMuse);
            _mint(msg.sender, what);
        }
        // Lock the Muse in the contract
        muse.transferFrom(msg.sender, address(this), _amount);
    }

    function changeUnlockPeriod(uint256 _period) external {
        require(msg.sender == owner, "forbidden");
        unlockPeriod = _period;
    }

    function startUnstake() public {
        timeLock[msg.sender] = block.timestamp + unlockPeriod;
    }

    // Leave the bar. Claim back your Muse.
    // Unlocks the staked + gained Muse and burns sMuse
    function unstake(uint256 _share) public {
        uint256 lockedUntil = timeLock[msg.sender];
        timeLock[msg.sender] = 0;
        require(
            lockedUntil != 0 &&
                block.timestamp >= lockedUntil &&
                block.timestamp <= lockedUntil + 2 days,
            "!still locked"
        );

        uint256 totalShares = totalSupply();
        // Calculates the amount of Muse the sMuse is worth
        uint256 what = _share.mul(muse.balanceOf(address(this))).div(
            totalShares
        );
        _burn(msg.sender, _share);
        muse.transfer(msg.sender, what);
    }

    function userInfo(address _user)
        public
        view
        returns (
            uint256 balance,
            uint256 museValue,
            uint256 timelock,
            bool isClaimable,
            uint256 globalShares,
            uint256 globalBalance
        )
    {
        balance = balanceOf(_user);
        museValue = balance.mul(muse.balanceOf(address(this))).div(
            totalSupply()
        );
        timelock = timeLock[_user];
        isClaimable = (timelock != 0 &&
            block.timestamp >= timelock &&
            block.timestamp <= timelock + 2 days);
        globalShares = totalSupply();
        globalBalance = muse.balanceOf(address(this));
    }
}