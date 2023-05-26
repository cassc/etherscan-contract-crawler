// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./interfaces/IERC20Metadata.sol";

contract Auction is ERC20 {
    using SafeERC20 for IERC20Metadata;

    uint public constant AUCTION_CAP = 25_000_000;
    uint public constant STARGATE_FOR_AUCTION = 100_000_000;
    uint public constant STARGATE_FOR_LP = 50_000_000;

    uint public constant AUCTION_DURATION = 2 days;
    uint public constant LOCK_DURATION = 52 weeks;
    uint public constant VEST_DURATION = 26 weeks;

    address immutable public stargateTreasury;
    uint8 immutable public astgDecimals;

    IERC20Metadata immutable public stableCoin;
    IERC20Metadata immutable public stargate;

    //auction constants
    uint public auctionStartTime;
    uint public auctionEndTime;
    uint immutable public auctionCap;
    uint public auctionedAmount;

    //vesting constants
    uint immutable public vestStartTime;
    mapping(address => uint) public redeemedShares;

    uint immutable public stgAuctionAmount;

    event Auctioned(address _sender, uint _astgAmount);
    event Redeemed(address _sender, uint _astgAmount, uint _stgAmount);

    // ============================ Constructor ====================================

    constructor(
        address payable _stargateTreasury,
        IERC20Metadata _stargate,
        IERC20Metadata _stableCoin,
        uint _auctionStartTime
    )
        ERC20("aSTG","aSTG")
    {
        stargateTreasury = _stargateTreasury;

        stargate = _stargate;
        stableCoin = _stableCoin;
        astgDecimals = _stableCoin.decimals();

        auctionCap = AUCTION_CAP * (10 ** _stableCoin.decimals());
        stgAuctionAmount = STARGATE_FOR_AUCTION * (10 ** _stargate.decimals());

        auctionStartTime = _auctionStartTime;
        auctionEndTime = auctionStartTime + AUCTION_DURATION;
        vestStartTime = auctionEndTime + LOCK_DURATION;
    }

    // ============================ Override =======================================

    // this is non-transferable
    function _beforeTokenTransfer(address _from, address, uint) internal virtual override {
        require(_from == address(0), "non-transferable");
    }

    function decimals() public view virtual override returns(uint8) {
        return astgDecimals;
    }

    // ============================ External =======================================

    function enter(uint _amount) external {
        require(block.timestamp >= auctionStartTime, "auction not started");
        require(block.timestamp < auctionEndTime && auctionedAmount < auctionCap, "auction finished");
        require(_amount > 0, "amount too small");

        uint amount = _amount;
        uint quota = auctionCap - auctionedAmount;
        if(amount > quota) {
            amount = quota;
        }

        stableCoin.safeTransferFrom(msg.sender, stargateTreasury, amount);
        auctionedAmount += amount;
        _mint(msg.sender, amount);

        emit Auctioned(msg.sender, amount);
    }

    function redeem() external {
        require(block.timestamp >= vestStartTime, "vesting not started");

        uint vestSinceStart = block.timestamp - vestStartTime;
        if(vestSinceStart > VEST_DURATION){
            vestSinceStart = VEST_DURATION;
        }

        uint totalRedeemableShares = balanceOf(msg.sender) * vestSinceStart / VEST_DURATION;
        uint redeemed = redeemedShares[msg.sender];
        require(totalRedeemableShares > redeemed, "nothing to redeem");

        uint newSharesToRedeem = totalRedeemableShares - redeemed;
        redeemedShares[msg.sender] = redeemed + newSharesToRedeem;

        uint stargateAmount = stgAuctionAmount * newSharesToRedeem / totalSupply();
        stargate.safeTransfer(msg.sender, stargateAmount);

        emit Redeemed(msg.sender, newSharesToRedeem, stargateAmount);
    }
}