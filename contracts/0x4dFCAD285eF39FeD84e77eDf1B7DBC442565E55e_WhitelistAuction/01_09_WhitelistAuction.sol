// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract WhitelistAuction is ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20Metadata;

    // ============================ Time Variables ====================================

    uint public constant FIRST_AUCTION_DURATION = 2 days;
    uint public constant SECOND_AUCTION_DURATION = 1 days;

    uint public constant VEST_DURATION = 26 weeks;

    uint public constant vestStartTime = 1679155200;

    //
    uint public firstAuctionStartTime;
    uint public firstAuctionEndTime;
    // value be set after the ending of the 1st auction
    uint public secondAuctionEndTime;

    // ============================ Token Meta ====================================
    address immutable public stargateTreasury;
    uint8 immutable public astgDecimals;

    IERC20Metadata immutable public stableCoin;
    IERC20Metadata immutable public stargateToken;

    // ============================ Amount (USD/STG) ====================================
    uint public constant USD_AUCTION_CAP = 5_000_000;
    uint public constant STARGATE_FOR_AUCTION = 20_000_000;

    //whitelisting
    mapping(address => bool) public astgWhitelist;
    mapping(address => bool) public bondingWhitelist;

    //auction amounts
    uint public capStgAuctionAmount;
    uint immutable public astgWhitelistMaxAlloc;
    uint immutable public bondingWhitelistMaxAlloc;
    bool public ownerWithdrawn;

    // value be set after the ending of the 1st auction
    bool public secondAuctionInit;
    uint public secondAuctionAdditionalAllocCap;

    // book keeping
    uint public remainingUsdQuota;
    mapping(address => uint) public redeemedShares;
    //tallying for second auction
    uint public countOfMaxAuction;

    // ============================ Events ====================================
    event FirstAuctioned(address _sender, uint _astgAmount);
    event SecondAuctioned(address _sender, uint _astgAmount);
    event FinalWithdrawal(address _to, uint _remainingUSD, uint _remainingSTG);
    event Redeemed(address _sender, uint _astgAmount, uint _stgAmount);

    // ============================ Constructor ====================================

    constructor(
        address payable _stargateTreasury,
        IERC20Metadata _stargate,
        IERC20Metadata _stableCoin,
        uint _auctionStartTime,
        uint _astgWhitelistMaxAlloc,
        uint _bondingWhitelistMaxAlloc
    )
        ERC20("aaSTG","aaSTG")
    {
        stargateTreasury = _stargateTreasury;

        // tokens
        stargateToken = _stargate;
        stableCoin = _stableCoin;
        astgDecimals = _stableCoin.decimals();
        remainingUsdQuota = USD_AUCTION_CAP * (10 ** _stableCoin.decimals());

        // time variables
        firstAuctionStartTime = _auctionStartTime;
        firstAuctionEndTime = firstAuctionStartTime + FIRST_AUCTION_DURATION;
        // the 2nd auction starts when the 1st ends
        secondAuctionEndTime = firstAuctionEndTime + SECOND_AUCTION_DURATION;

        // set the cap for both roles
        astgWhitelistMaxAlloc = _astgWhitelistMaxAlloc;
        bondingWhitelistMaxAlloc = _bondingWhitelistMaxAlloc;
    }

    // ============================ onlyOwner =======================================

    function addAuctionAddresses(address[] calldata addresses) external onlyOwner {
        uint length = addresses.length;
        uint i;
        while(i < length){
            astgWhitelist[addresses[i]] = true;
            i++;
        }
    }

    function addBondAddresses(address[] calldata addresses) external onlyOwner {
        uint length = addresses.length;
        uint i;
        while(i < length){
            bondingWhitelist[addresses[i]] = true;
            i++;
        }
    }

    function withdrawRemainingStargate(address _to) external onlyOwner {
        require(block.timestamp > secondAuctionEndTime, "Stargate: second auction not finished");
        require(!ownerWithdrawn, "Stargate: owner has withdrawn");

        uint startingCap = STARGATE_FOR_AUCTION * (10 ** stargateToken.decimals());

        uint usdAuctionCap = USD_AUCTION_CAP * (10 ** astgDecimals);
        uint remainingSTG = startingCap * remainingUsdQuota / usdAuctionCap;

        // adjust the capStgAuctionAmount value, the redeem would overflow otherwise
        capStgAuctionAmount = startingCap - remainingSTG;

        stargateToken.safeTransfer(_to, remainingSTG);

        ownerWithdrawn = true;

        emit FinalWithdrawal(_to, remainingUsdQuota, remainingSTG);
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

    function enterFirstAuction(uint _requestAmount) external nonReentrant {
        require(_requestAmount > 0, "Stargate: request amount must > 0");
        require(block.timestamp >= firstAuctionStartTime && block.timestamp < firstAuctionEndTime, "Stargate: not in the first auction period");
        require(remainingUsdQuota > 0, "Stargate: auction reaches its cap");

        uint maxExecAmount = this.getFirstAuctionCapAmount(msg.sender);

        uint balance = this.balanceOf(msg.sender);
        require(balance < maxExecAmount, "Stargate: already at max");

        // cap the request amount if too much
        if (balance + _requestAmount >= maxExecAmount) {
            _requestAmount = maxExecAmount - balance;
            // reaches max. increment the counter
            countOfMaxAuction++;
        }

        // execute it
        uint execAmount = _executeAuction(_requestAmount);
        emit FirstAuctioned(msg.sender, execAmount);
    }

    function enterSecondAuction(uint _requestAmount) external nonReentrant {
        // assert the auction is at the 2nd stage
        require(block.timestamp >= firstAuctionEndTime && block.timestamp < secondAuctionEndTime, "Stargate: not in the second auction period");
        require(remainingUsdQuota > 0, "Stargate: auction reaches its cap");

        if (!secondAuctionInit) {
            secondAuctionAdditionalAllocCap = remainingUsdQuota / countOfMaxAuction;
            secondAuctionInit = true;
        }

        uint firstAuctionMaxExecAmount = this.getFirstAuctionCapAmount(msg.sender);
        uint balance = this.balanceOf(msg.sender);
        require(balance >= firstAuctionMaxExecAmount, "Stargate: not eligible for the second auction");

        // compute the execAmount
        uint maxExecAmount = firstAuctionMaxExecAmount + secondAuctionAdditionalAllocCap;
        if (balance + _requestAmount >= maxExecAmount) {
            _requestAmount = maxExecAmount - balance;
        }

        uint execAmount = _executeAuction(_requestAmount);
        emit SecondAuctioned(msg.sender, execAmount);
    }

    function secondAuctionAllocCap() external view returns(uint) {
        if(!secondAuctionInit){
            return remainingUsdQuota / countOfMaxAuction;
        }else{
            return secondAuctionAdditionalAllocCap;
        }
    }

    // whitelist amount > bonding amount.
    function getFirstAuctionCapAmount(address user) public view returns(uint) {
        if (astgWhitelist[user]) return astgWhitelistMaxAlloc;
        if (bondingWhitelist[user]) return bondingWhitelistMaxAlloc;
        revert("Stargate: not a whitelisted address");
    }

    // compute the final amount and execute the transaction
    function _executeAuction(uint _execAmount) internal returns(uint finalExecAmount){
        // exec amount capped at the remaining. even tho it should never hit it.
        if(_execAmount > remainingUsdQuota) {
            finalExecAmount = remainingUsdQuota;
        } else {
            finalExecAmount = _execAmount;
        }

        // execute the txn
        remainingUsdQuota -= finalExecAmount;
        stableCoin.safeTransferFrom(msg.sender, stargateTreasury, finalExecAmount);
        _mint(msg.sender, finalExecAmount);
    }

    function redeem() external nonReentrant {
        require(block.timestamp >= vestStartTime, "Stargate: vesting not started");
        require(capStgAuctionAmount != 0, "Stargate: stargate for vesting not set");

        uint vestSinceStart = block.timestamp - vestStartTime;
        if(vestSinceStart > VEST_DURATION){
            vestSinceStart = VEST_DURATION;
        }

        uint totalRedeemableShares = balanceOf(msg.sender) * vestSinceStart / VEST_DURATION;
        uint redeemed = redeemedShares[msg.sender];
        require(totalRedeemableShares > redeemed, "Stargate: nothing to redeem");

        uint newSharesToRedeem = totalRedeemableShares - redeemed;
        redeemedShares[msg.sender] = redeemed + newSharesToRedeem;

        uint stargateAmount = capStgAuctionAmount * newSharesToRedeem / totalSupply();
        stargateToken.safeTransfer(msg.sender, stargateAmount);

        emit Redeemed(msg.sender, newSharesToRedeem, stargateAmount);
    }

    function redeemable(address _redeemer) external view returns(uint){
        require(block.timestamp >= vestStartTime, "Stargate: vesting not started");
        require(capStgAuctionAmount != 0, "Stargate: stargate for vesting not set");

        uint vestSinceStart = block.timestamp - vestStartTime;
        if(vestSinceStart > VEST_DURATION){
            vestSinceStart = VEST_DURATION;
        }

        uint totalRedeemableShares = balanceOf(_redeemer) * vestSinceStart / VEST_DURATION;
        uint redeemed = redeemedShares[_redeemer];
        require(totalRedeemableShares > redeemed, "Stargate: nothing to redeem");

        uint newSharesToRedeem = totalRedeemableShares - redeemed;

        return capStgAuctionAmount * newSharesToRedeem / totalSupply();
    }
}