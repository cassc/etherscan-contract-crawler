// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

//sample convex reward contracts interface
interface ICvxFxsStakingWrapper{
    //get balance of an address
    function balanceOf(address _account) external view returns(uint256);
    //withdraw to a convex tokenized deposit
    function withdraw(uint256 _amount) external;
    //claim rewards
    function getReward(address claimant) external;
    //claim rewards and forward to address
    function getReward(address claimant, address forwardTo) external;
    //stake convex frax
    function stakeFor(address _to, uint256 _amount) external;
    //get number of reward tokens
    function rewardTokenLength() external view returns(uint);
    //get reward address, reward group, reward integral and reward remaining
    function rewardTokens(uint index) external view returns(address);
}

/**
@title Convex FraxShare Escrow
@notice Collateral is stored in unique escrow contracts for every user and every market.
@dev Caution: This is a proxy implementation. Follow proxy pattern best practices
*/
contract ConvexFraxShareEscrow {
    using SafeERC20 for IERC20;
    address public market;
    IERC20 public token;
    uint public stakedBalance;
    ICvxFxsStakingWrapper public constant rewardPool = ICvxFxsStakingWrapper(0x49b4d1dF40442f0C31b1BbAEA3EDE7c38e37E31a);
    address public beneficiary;
    mapping(address => bool) public allowlist;

    modifier onlyBeneficiary {
        require(msg.sender == beneficiary, "ONLY BENEFICIARY");
        _; 
    }

    modifier onlyBeneficiaryOrAllowlist {
        require(msg.sender == beneficiary || allowlist[msg.sender], "ONLY BENEFICIARY OR ALLOWED");
        _; 
    }

    event AllowClaim(address indexed allowedAddress, bool allowed);

    /**
    @notice Initialize escrow with a token
    @dev Must be called right after proxy is created.
    @param _token The IERC20 token representing the governance token
    @param _beneficiary The beneficiary who cvxFXS is staked on behalf
    */
    function initialize(IERC20 _token, address _beneficiary) public {
        require(market == address(0), "ALREADY INITIALIZED");
        market = msg.sender;
        token = _token;
        token.approve(address(rewardPool), type(uint).max);
        beneficiary = _beneficiary;
    }

    /**
    @notice Withdraws the wrapped token from the reward pool and transfers the associated ERC20 token to a recipient.
    @param recipient The address to receive payment from the escrow
    @param amount The amount of ERC20 token to be transferred.
    */
    function pay(address recipient, uint amount) public {
        require(msg.sender == market, "ONLY MARKET");
        stakedBalance -= amount;
        rewardPool.withdraw(amount);
        token.transfer(recipient, amount);
    }

    /**
    @notice Get the token balance of the escrow
    @return Uint representing the staked balance of the escrow
    */
    function balance() public view returns (uint) {
        return stakedBalance;
    }

    /**
    @notice Function called by market on deposit. Stakes deposited collateral into convex reward pool
    @dev This function should remain callable by anyone to handle direct inbound transfers.
    */
    function onDeposit() public {
        //Stake cvxFxs
        uint tokenBal = token.balanceOf(address(this));
        stakedBalance += tokenBal;
        rewardPool.stakeFor(address(this), tokenBal);
    }

    /**
    @notice Claims reward tokens to the specified address. Only callable by beneficiary and allowlisted addresses
    @param to Address to send claimed rewards to
    */
    function claimTo(address to) public onlyBeneficiaryOrAllowlist{
        //Claim rewards
        rewardPool.getReward(address(this), to);

        //Send contract balance of rewards
        uint rewardTokenLength = rewardPool.rewardTokenLength();
        for(uint rewardIndex; rewardIndex < rewardTokenLength; ++rewardIndex){
            address rewardToken = rewardPool.rewardTokens(rewardIndex);
            uint rewardBal = IERC20(rewardToken).balanceOf(address(this));
            if(rewardBal > 0){
                //Use safe transfer in case bad reward token is added
                IERC20(rewardToken).safeTransfer(to, rewardBal);
            }
        }
    }
    
    /**
    @notice Claims reward tokens to the message sender. Only callable by beneficiary and allowlisted addresses
    */
    function claim() external {
        claimTo(msg.sender);
    }

    /**
    @notice Allow address to claim on behalf of the beneficiary to any address
    @param allowee Address that are allowed to claim on behalf of the beneficiary
    @dev Can be used to build contracts for auto-compounding cvxFxs, auto-buying DBR or auto-repaying loans
    */
    function allowClaimOnBehalf(address allowee) external onlyBeneficiary {
        allowlist[allowee] = true;
        emit AllowClaim(allowee, true);
    }

    /**
    @notice Disallow address to claim on behalf of the beneficiary to any address
    @param allowee Address that are disallowed to claim on behalf of the beneficiary
    */
    function disallowClaimOnBehalf(address allowee) external onlyBeneficiary {
        allowlist[allowee] = false;   
        emit AllowClaim(allowee, false);
    }
}