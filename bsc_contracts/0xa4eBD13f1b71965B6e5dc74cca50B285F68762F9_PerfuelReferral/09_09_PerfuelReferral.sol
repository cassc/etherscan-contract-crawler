// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PerfuelReferral is Ownable, ReentrancyGuard{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 public tokenPerEth = 200000;
    uint256 public totalTokensForSale = 200000000;
    uint256 public referralPercentage = 20;
    uint256 public constant TOTAL_PERCENTAGE = 100;
    address public tokenContract;

    uint256 public totalTokenSold;
    uint256 public totalAmount;
    uint256 public totalReferralGenerated = 0;
    uint256 public REFERRAL_MAX = 100000;

    struct ReferralData {
        address _referrer;
        uint256 _referralCode;
        uint256 totalReward;
        uint256 unClaimedReward;
        uint256 claimedReward;
    }

    mapping(address=>uint256) public addressToReferral;
    mapping(uint256=>address) public referralToAddress;
    mapping(address=>ReferralData) public referralData;
    mapping(address=>uint256) public userBought;

    event ReferralCreated(address _address,uint256 _referralCounter);

    constructor(address _tokenContract){
        require(_tokenContract!=address(0),"Invalid token contract address");
        tokenContract = _tokenContract;
    }

    function setTokenContract(address _tokenContract) external onlyOwner{
        require(_tokenContract!=address(0),"Invalid token contract address");
        tokenContract = _tokenContract;
    }

    function createReferal() public {
        totalReferralGenerated = totalReferralGenerated.add(1);
        uint256 currentReferral = createReferralCode(REFERRAL_MAX.add(totalReferralGenerated));

        addressToReferral[msg.sender] = currentReferral;
        referralToAddress[currentReferral] = msg.sender;

        referralData[msg.sender] = ReferralData({
            _referrer:msg.sender,
            _referralCode:currentReferral,
            totalReward:0,
            unClaimedReward:0,
            claimedReward:0
        });

        emit ReferralCreated(msg.sender,currentReferral);
    }

    function buyToken(address _sender,uint256 _value,uint256 _referralCode) external{
        require(_value>0,"Invalid amount sent");
        uint256 amount = (_value * tokenPerEth)/(1 ether);

        address _referral = referralToAddress[_referralCode];

        totalTokenSold = totalTokenSold.add(amount);
        totalAmount = totalAmount.add(_value);

        if(_referral!=address(0)  && _referral!=_sender){
            uint256 referralAmount = (_value*referralPercentage)/TOTAL_PERCENTAGE;
            referralData[_referral].totalReward = referralData[_referral].totalReward.add(referralAmount);
            referralData[_referral].unClaimedReward = referralData[_referral].unClaimedReward.add(referralAmount);
        }

        userBought[_sender] = userBought[_sender].add(amount);
    }

    function claimReward(uint256 _amount) external{
        require(addressToReferral[msg.sender]!=0,"Create your referral first");
        require(referralData[msg.sender].unClaimedReward>=_amount,"Insufficient reward balance");

        referralData[msg.sender].unClaimedReward = referralData[msg.sender].unClaimedReward.sub(_amount);
        referralData[msg.sender].claimedReward = referralData[msg.sender].claimedReward.add(_amount);
        payable(msg.sender).transfer(_amount);
    }

    function getBalance() public view returns(uint256){
        return address(this).balance;
    }

    function addLiquidity() public payable onlyOwner{}

    function withdrawAmount(uint256 _amount) public onlyOwner{
        require(_amount<=getBalance(),"Invalid amount");
        payable(msg.sender).transfer(_amount);
    }
    
    function withdrawPRF(uint256 _amount) public onlyOwner{
        require(_amount<=IERC20(tokenContract).balanceOf(address(this)),"Insufficient token");

        IERC20(tokenContract).safeTransfer(msg.sender,_amount);   
        
    }

    function createReferralCode(uint256 max) internal view returns (uint256){
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        msg.sender
                    )
                )
            ) % max;
    }
}