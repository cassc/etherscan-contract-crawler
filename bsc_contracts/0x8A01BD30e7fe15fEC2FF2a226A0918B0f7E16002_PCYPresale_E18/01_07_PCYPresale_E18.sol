// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

// ######  ######  #######  #####  #     # ####### #     # 
// #     # #     # #     # #     #  #   #  #     # ##    # 
// #     # #     # #     # #         # #   #     # # #   # 
// ######  ######  #     # #          #    #     # #  #  # 
// #       #   #   #     # #          #    #     # #   # # 
// #       #    #  #     # #     #    #    #     # #    ## 
// #       #     # #######  #####     #    ####### #     # 

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./libs/IProcyonFarmingReferral.sol";
import "./libs/IBEP20.sol";
import "./libs/SafeBEP20.sol";

contract PCYPresale_E18 is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    mapping(address => uint256) public PCYUnclaimed; // The number of unclaimed PCY tokens the user has
    mapping(address => bool) public isFirstClaimed;

    event ReferralCommissionPaid(address indexed user, address indexed referrer, uint256 commissionAmount);

    // PCY referral contract address.
    IProcyonFarmingReferral public procyonFarmingReferral;
    // Referral commission rate in basis points.
    uint16 public referralCommissionRate = 500;

    // Hardcap
    uint256 public constant HARDCAP = 700000*(1e18);

    // PCY token
    IBEP20 public PCY;
    // Buy token
    IBEP20 public commitToken;

    // Enable sale
    bool public enableSale;
    // Enable 1st release presale token phase
    bool public enable1stRelease; // firstClaimPercent %
    // Enable 2nd release presale token phase
    bool public enable2ndRelease; // Remaining token

    // Starting timestamp
    uint256 public startTime; // timestamp
    // Total PCY sold
    uint256 public totalSold = 0;
    // Total PCY sold
    uint256 public firstClaimPercent = 50;
    // Total PCY Unclaimed
    uint256 public totalUnclaimed = 0;
    // PCY Price = commitTokenPerPCY / 100
    uint256 private constant commitTokenPerPCY = 30; // 0.3 commitToken

    address payable owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "You're not the owner");
        _;
    }

    event Bought(address user, uint256 tokens);
    event FirstClaimed(address user, uint256 tokens);
    event SecondClaimed(address user, uint256 tokens);

    constructor(
        address _PCY,
        uint256 _startTime,
        address _commitTokenAddress
    ) public {
        PCY = IBEP20(_PCY);
        commitToken = IBEP20(_commitTokenAddress);
        enableSale = true;
        enable1stRelease = false;
        enable2ndRelease = false;
        owner = msg.sender;
        startTime = _startTime;
    }

    function currentTime() external view returns (uint256) {
        return block.timestamp;
    }

    function setEnableSale(bool _enableSale) external onlyOwner {
        enableSale = _enableSale;
    }

    function setEnable1stRelease(bool _enable1stRelease) external onlyOwner {
        require(!enableSale, "Error: Must disable sale before enable claim");
        enable1stRelease = _enable1stRelease;
    }

    function setEnable2ndRelease(bool _enable2ndRelease) external onlyOwner {
        require(enable1stRelease, "Error: Must enable 1st release");
        enable2ndRelease = _enable2ndRelease;
    }

    function buy(uint256 _amount, address _buyer, address _referrer) public nonReentrant {
        require(enableSale, "enableSale: Presale has not started");
        require(
            block.timestamp >= startTime,
            "startTime: Presale has not started"
        );

        address buyer = _buyer;
        uint256 tokens = _amount.div(commitTokenPerPCY).mul(100);

        require(
            totalSold + tokens <= HARDCAP,
            "Presale hardcap reached"
        );

        commitToken.safeTransferFrom(buyer, address(this), _amount);

        PCYUnclaimed[buyer] = PCYUnclaimed[buyer].add(tokens);
        totalSold = totalSold.add(tokens);
        totalUnclaimed = totalSold;

        if (_amount > 0 && address(procyonFarmingReferral) != address(0) && _referrer != address(0) && _referrer != msg.sender) {
            procyonFarmingReferral.recordReferral(msg.sender, _referrer);
        }

        emit Bought(buyer, tokens);
    }

    function claim() external {
        
        require(
            PCYUnclaimed[msg.sender] > 0,
            "User should have unclaimed PCY tokens"
        );

        require(
            PCY.balanceOf(address(this)) >= PCYUnclaimed[msg.sender],
            "There are not enough PCY tokens to transfer."
        );

        require(enable1stRelease, "1st claim is not allowed yet");

        if(enable2ndRelease) {
            require(enable2ndRelease, "2nd claim is not allowed yet");

            uint256 pcyToClaim = PCYUnclaimed[msg.sender];
            PCYUnclaimed[msg.sender] = PCYUnclaimed[msg.sender].sub(pcyToClaim);
            totalUnclaimed = totalUnclaimed.sub(pcyToClaim);

            PCY.safeTransfer(msg.sender, pcyToClaim);
            payReferralCommission(msg.sender, pcyToClaim);

            emit SecondClaimed(msg.sender, pcyToClaim);
        }
        else {
            require(!isFirstClaimed[msg.sender], "Already 1st Claimed");
            uint256 pcyToClaim = PCYUnclaimed[msg.sender].mul(firstClaimPercent).div(100);
            PCYUnclaimed[msg.sender] = PCYUnclaimed[msg.sender].sub(pcyToClaim);
            totalUnclaimed = totalUnclaimed.sub(pcyToClaim);

            PCY.safeTransfer(msg.sender, pcyToClaim);
            payReferralCommission(msg.sender, pcyToClaim);

            isFirstClaimed[msg.sender] = true;

            emit FirstClaimed(msg.sender, pcyToClaim);
        }
    }


    function withdrawFunds() external onlyOwner {
        commitToken.safeTransfer(msg.sender, commitToken.balanceOf(address(this)));
    }

    function withdrawUnsoldPCY() external onlyOwner {
        uint256 amount = PCY.balanceOf(address(this)) - totalSold;
        PCY.safeTransfer(msg.sender, amount);
    }

    function emergencyWithdraw() external onlyOwner {
        PCY.safeTransfer(msg.sender, PCY.balanceOf(address(this)));
    }

    function updateStartTime(uint256 _startTime) external onlyOwner {
        startTime = _startTime;
    }

    // Owner can recover tokens that are sent here by mistake
    function recoverBEP20Token(IBEP20 _token, uint256 _amount, address _to) external onlyOwner {
        require(address(_token) != address(PCY), "Cannot be PCY token");
        require(address(_token) != address(commitToken), "Cannot be commit token");
        _token.safeTransfer(_to, _amount);
    }

    // Update the pcy referral contract address by the owner
    function setProcyonFarmingReferral(IProcyonFarmingReferral _procyonFarmingReferral) public onlyOwner {
        procyonFarmingReferral = _procyonFarmingReferral;
    }

    // Pay referral commission to the referrer who referred this user.
    function payReferralCommission(address _user, uint256 _pending) internal {
        if (address(procyonFarmingReferral) != address(0) && referralCommissionRate > 0) {
            address referrer = procyonFarmingReferral.getReferrer(_user);
            uint256 commissionAmount = _pending.mul(referralCommissionRate).div(1e4);

            if (referrer != address(0) && commissionAmount > 0) {
                PCY.safeTransfer(referrer, commissionAmount);
                procyonFarmingReferral.recordReferralCommission(referrer, commissionAmount);
                emit ReferralCommissionPaid(_user, referrer, commissionAmount);
            }
        }
    }
}