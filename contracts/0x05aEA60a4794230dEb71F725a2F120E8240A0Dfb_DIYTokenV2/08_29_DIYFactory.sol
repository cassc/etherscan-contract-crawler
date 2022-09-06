// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "./libraries/AuthorizableU.sol";
import "./DIYToken.sol";

contract DIYFactory is AuthorizableU {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    ////////////////////////////////////////////////////////////////////////
    // State variables
    ////////////////////////////////////////////////////////////////////////
    struct TokenAllocation {
        string name;                    // LP, Presale, Team, Marketing, Reserve
        uint256 allocationAmount;       // 2.5%, 22.5%, 25%, 30%, 20%
        uint256 allocatedAmount;        // Total Allocated Amount
        uint256 lockingDuration;        // Locking Duration
        uint256 vestingDuration;        // Vesting Duration
    }

    struct PresaleFund {
        string name;                    // ETH, USDT, USDC...
        bool isToken;                   // ETH: false, USDT: true, USDC: true
        address tokenAddr;              // ETH: 0x0, USDT: 0x123....
        uint256 priceRate;              // 9,381,355 TOKEN
        uint256 basisPoint;             // 1 ETH
    }

    struct PurchasedUser {
        uint8   allocationIndex;        // Index of TokenAllocation
        uint256 depositedAmount;        // How many Fund amount the user has deposited.
        uint256 purchasedAmount;        // How many Tokens the user has purchased.
        uint256 withdrawnAmount;        // Withdrawn amount
    }

    struct PresaleContext {
        bool isSelling;                 // Selling Flag
        uint256 startTime;              // Selling start time
        uint256 duration;               // Selling duration

        uint8 allocationIndex;          // Allocation Index
        uint16 treasuryIndex;           // Treasury Index

        uint256 maxPurchaseAmount;      // Max purchase amount per user
        uint256 depositedAmount;        // Total deposit amount
        uint256 purchasedAmount;        // Total purchased amount
    }

    IERC20Upgradeable public token;
    // common decimals
    uint8 public commonDecimals;

    // token allocations
    TokenAllocation[] public tokenAllocations;

    // presale funds
    PresaleFund[] public presaleFunds;

    // treasury addresses
    address[] public treasuryAddrs;

    // presale context
    PresaleContext public presaleContext;

    // purchasedUsers address => PurchasedUser
    mapping(address => PurchasedUser) public purchasedUserMap;
    address[] public purchasedUsers;

    ////////////////////////////////////////////////////////////////////////
    // Events & Modifiers
    ////////////////////////////////////////////////////////////////////////
    modifier whenSale() {
        require(isSalePeriod(), "This is not sale period.");
        _;
    }

    ////////////////////////////////////////////////////////////////////////
    // Initialization functions
    ////////////////////////////////////////////////////////////////////////

    function initialize(
        IERC20Upgradeable _token,
        TokenAllocation[] memory _tokenAllocations,
        PresaleFund[] memory _presaleFunds,
        address[] memory _treasuryAddrs,
        PresaleContext  memory _presaleContext
    ) public virtual initializer {
        __Authorizable_init();
        addAuthorized(_msgSender());

        commonDecimals = 18;

        updateToken(_token);
        updateTokenAllocations(_tokenAllocations);
        updatePresaleFunds(_presaleFunds);
        updateTreasuryAddrs(_treasuryAddrs);
        updatePresaleContext(_presaleContext);
        updatePresaleFlagAndTime(true, block.timestamp, 7 days);
    }

    ////////////////////////////////////////////////////////////////////////
    // External functions
    ////////////////////////////////////////////////////////////////////////

    // Token
    function updateToken(IERC20Upgradeable _token) public onlyAuthorized {
        token = _token;
    }

    // Token Allocation
    function updateTokenAllocations(TokenAllocation[] memory _tokenAllocations) public onlyAuthorized {
        delete tokenAllocations;
        for (uint i=0; i<_tokenAllocations.length; i++) {
            tokenAllocations.push(_tokenAllocations[i]);
        }
    }

    function updateTokenAllocationById(uint8 index, string memory name, uint256 allocationAmount, uint256 allocatedAmount, uint256 lockingDuration, uint256 vestingDuration) public onlyAuthorized {
        if (index == 255) {
            tokenAllocations.push(TokenAllocation(name, allocationAmount, allocatedAmount, lockingDuration, vestingDuration));
        } else {
            tokenAllocations[index] = TokenAllocation(name, allocationAmount, allocatedAmount, lockingDuration, vestingDuration);
        }
    }

    // Presale Funds
    function updatePresaleFunds(PresaleFund[] memory _presaleFunds) public onlyAuthorized {
        delete presaleFunds;
        for (uint i=0; i<_presaleFunds.length; i++) {
            presaleFunds.push(_presaleFunds[i]);
        }
    }

    function updatePresaleFundsById(uint8 index, string memory name, bool isToken, address tokenAddr, uint256 priceRate, uint256 basisPoint) public onlyAuthorized {
        if (index == 255) {
            presaleFunds.push(PresaleFund(name, isToken, tokenAddr, priceRate, basisPoint));
        } else {
            presaleFunds[index] = PresaleFund(name, isToken, tokenAddr, priceRate, basisPoint);
        }
    }

    // Treasury addresses
    function updateTreasuryAddrs(address[] memory _treasuryAddrs) public onlyAuthorized {
        delete treasuryAddrs;
        for (uint i=0; i<_treasuryAddrs.length; i++) {
            treasuryAddrs.push(_treasuryAddrs[i]);
        }
    }

    function updateTreasuryAddrById(uint8 index, address treasuryAddr) public onlyAuthorized {
        if (index == 255) {
            treasuryAddrs.push(treasuryAddr);
        } else {
            treasuryAddrs[index] = treasuryAddr;
        }
    }

    function updatePresaleTreasuryIndex(uint8 treasuryIndex) public onlyAuthorized {
        presaleContext.treasuryIndex = treasuryIndex;
    }

    // Presale Context
    function updatePresaleContext(PresaleContext memory _presaleContext) public onlyAuthorized {
        presaleContext = _presaleContext;
    }

    function updatePresaleFlagAndTime(bool isSelling, uint256 startTime, uint256 duration) public onlyAuthorized {
        presaleContext.isSelling = isSelling;
        presaleContext.startTime = startTime == 0 ? block.timestamp : startTime;
        presaleContext.duration = duration == 0 ? presaleContext.duration : duration;
    }

    function purchasedUserCount() public view returns (uint256) {
        return purchasedUsers.length;
    }

    //Presale///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function isSalePeriod() public view returns (bool) {
        return presaleContext.isSelling && block.timestamp >= presaleContext.startTime && block.timestamp <= presaleContext.startTime.add(presaleContext.duration);
    }

    function calcTotalSellingTokenAmount() public view returns(uint256) {
        TokenAllocation memory tokenAllocation = tokenAllocations[presaleContext.allocationIndex];
        return tokenAllocation.allocationAmount;
    }
    function calcTotalBuyableTokenAmount() public view returns(uint256) {
        TokenAllocation memory tokenAllocation = tokenAllocations[presaleContext.allocationIndex];
        uint256 buyableTokenAmount = tokenAllocation.allocationAmount - tokenAllocation.allocatedAmount;
        return buyableTokenAmount;
    }

    function calcUserBuyableTokenAmount() public view returns(uint256) {
        PurchasedUser memory purchasedUser = purchasedUserMap[_msgSender()];
        uint256 totalBuyableTokenAmount = calcTotalBuyableTokenAmount();
        uint256 buyableTokenAmount = Math.min(presaleContext.maxPurchaseAmount - purchasedUser.purchasedAmount, totalBuyableTokenAmount);
        return buyableTokenAmount;
    }

    function calcTokenAmountByFund(uint256 fundAmount, uint8 fundIndex) public view returns(uint256) {
        PresaleFund memory presaleFund = presaleFunds[fundIndex];
        uint256 tokenAmount = fundAmount.mul(presaleFund.priceRate).div(presaleFund.basisPoint);
        return tokenAmount;
    }

    function calcFundAmountByToken(uint256 tokenAmount, uint8 fundIndex) public view returns(uint256) {
        PresaleFund memory presaleFund = presaleFunds[fundIndex];
        uint256 fundAmount = tokenAmount.div(presaleFund.priceRate).mul(presaleFund.basisPoint);
        return fundAmount;
    }

    function setPurchasedToken(bool isSetOrAdd, address wallet, uint8 allocationIndex, uint256 depositedAmount, uint256 purchasedAmount) public onlyAuthorized {
        _setPurchasedToken(isSetOrAdd, wallet, allocationIndex, depositedAmount, purchasedAmount);
    }

    function buyToken(uint256 tokenAmount, uint8 fundIndex) external payable {
        uint256 fundAmount = msg.value;
        uint256 totalAmountBuyable = calcUserBuyableTokenAmount();
        uint256 tokenAmountByFund = calcTokenAmountByFund(fundAmount, fundIndex);
        uint256 tokenAmountToBuy = Math.min(totalAmountBuyable, Math.min(tokenAmount, tokenAmountByFund));
        uint256 fundAmountToBuy = calcFundAmountByToken(tokenAmountToBuy, fundIndex);

        require(tokenAmountToBuy > 0, "[email protected] token amount");
        require(fundAmountToBuy > 0, "[email protected] fund amount");

        _setPurchasedToken(false, _msgSender(), presaleContext.allocationIndex, fundAmountToBuy, tokenAmountToBuy);

        if (fundIndex == 0) {
            refundIfOver(fundAmountToBuy);
        }
    }

    // Claim
    function calcClaimableTokenAmount(address wallet) public view returns(uint256) {
        PurchasedUser memory purchasedUser = purchasedUserMap[wallet];
        if (purchasedUser.purchasedAmount == 0) {
            return 0;
        }

        TokenAllocation memory tokenAllocation = tokenAllocations[purchasedUser.allocationIndex];
        uint256 vestingStartTime = presaleContext.startTime.add(presaleContext.duration).add(tokenAllocation.lockingDuration);

        uint256 claimableAmount = 0;
        if (block.timestamp <= vestingStartTime) {
            claimableAmount = 0;
        } else if (block.timestamp >= vestingStartTime.add(tokenAllocation.vestingDuration)) {
            claimableAmount = purchasedUser.purchasedAmount - purchasedUser.withdrawnAmount;
        } else {
            claimableAmount = purchasedUser.purchasedAmount.mul(block.timestamp.sub(vestingStartTime)).div(tokenAllocation.vestingDuration) - purchasedUser.withdrawnAmount;
        }
        return claimableAmount;
    }

    // Deploy to DEX

    function claimToken(uint256 tokenAmount) external {
        _claimToken(_msgSender(), tokenAmount);
    }

    // Admin
    // Allocate by admin
    function adminAllocateToken(address wallet, uint8 allocationIndex, uint256 tokenAmount) public onlyAuthorized {
        _setPurchasedToken(true, wallet, allocationIndex, 0, tokenAmount);
    }

    function adminClaimToken(address wallet, uint256 tokenAmount) public onlyAuthorized {
        _claimToken(wallet, tokenAmount);
    }

    function adminWithdrawToken(address wallet, uint256 tokenAmount) public onlyAuthorized {
        require(token.balanceOf(address(this)) >= tokenAmount, "[email protected] token amount");
        token.safeTransfer(wallet, tokenAmount);
    }

    function adminWithdrawFund(address wallet, uint256 fundAmount) public onlyAuthorized {
        require(address(this).balance >= fundAmount, "[email protected] fund amount.");
        payable(wallet).transfer(fundAmount);
    }


    ////////////////////////////////////////////////////////////////////////
    // Internal functions
    ////////////////////////////////////////////////////////////////////////
    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function _setPurchasedToken(bool isSetOrAdd, address wallet, uint8 allocationIndex, uint256 depositedAmount, uint256 purchasedAmount) private {
        PurchasedUser storage purchasedUser = purchasedUserMap[wallet];
        TokenAllocation storage tokenAllocation = tokenAllocations[purchasedUser.allocationIndex];

        if (purchasedUser.purchasedAmount == 0) {
            purchasedUsers.push(wallet);
            purchasedUser.withdrawnAmount = 0;
        }

        purchasedUser.allocationIndex = allocationIndex;
        if (isSetOrAdd) {
            tokenAllocation.allocatedAmount = tokenAllocation.allocatedAmount.sub(Math.min(tokenAllocation.allocatedAmount, purchasedUser.purchasedAmount));
            presaleContext.depositedAmount = presaleContext.depositedAmount.sub(Math.min(presaleContext.depositedAmount, purchasedUser.depositedAmount));
            presaleContext.purchasedAmount = presaleContext.purchasedAmount.sub(Math.min(presaleContext.purchasedAmount, purchasedUser.purchasedAmount));
            purchasedUser.depositedAmount = 0;
            purchasedUser.purchasedAmount = 0;
        }

        tokenAllocation.allocatedAmount = tokenAllocation.allocatedAmount.add(depositedAmount);
        presaleContext.depositedAmount = presaleContext.depositedAmount.add(depositedAmount);
        presaleContext.purchasedAmount = presaleContext.purchasedAmount.add(depositedAmount);

        purchasedUser.depositedAmount = purchasedUser.depositedAmount.add(depositedAmount);
        purchasedUser.purchasedAmount = purchasedUser.purchasedAmount.add(purchasedAmount);
    }

    function _claimToken(address wallet, uint256 tokenAmount) private {
        uint256 claimableTokenAmount = calcClaimableTokenAmount(wallet);
        require(claimableTokenAmount > 0, "[email protected] token amount");
        uint256 tokenAmountToClaim = Math.min(claimableTokenAmount, tokenAmount);

        PurchasedUser storage purchasedUser = purchasedUserMap[wallet];

        purchasedUser.withdrawnAmount = purchasedUser.withdrawnAmount.add(tokenAmountToClaim);
        token.safeTransfer(wallet, tokenAmountToClaim);
    }
}