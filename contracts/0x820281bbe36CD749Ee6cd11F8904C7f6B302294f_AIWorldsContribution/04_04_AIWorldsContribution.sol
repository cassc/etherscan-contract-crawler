pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

contract AIWorldsContribution is Ownable {
    struct Contribution {
        address addr;
        uint256 amount;
    }
    IERC20 public token;
    uint256 public constant MIN_CONTRIBUTION = 0.1 ether;
    uint256 public constant MAX_CONTRIBUTION = 5 ether;
    uint256 public supply;
    uint256 public capacity;
    uint256 public contributorCapacity;
    bool public contributionOpen;
    uint256 public totalContributed;
    uint256 public numContributors;
    mapping(uint256 => Contribution) public contribution;
    mapping(address => uint256) public contributor;

    constructor(
        uint256 capacity_,
        uint256 contributorCapacity_
    ) {
        capacity = capacity_;
        contributorCapacity = contributorCapacity_;
    }

    /**
     * @notice Contribute to AIWorlds (Min 0.1 ETH, Max 5 ETH)
     */
    function contribute() public payable {
        require(contributionOpen, "Contributions Not Open");
        uint256 currentContribution = contribution[contributor[msg.sender]]
            .amount;
        require(msg.value >= MIN_CONTRIBUTION, "Under Minimum Contribution");
        require(
            msg.value + currentContribution <= MAX_CONTRIBUTION,
            "Over Maximum Contribution"
        );
        totalContributed += msg.value;
        require(totalContributed <= capacity, "Capacity Reached");
        uint256 contributionIndex;
        if (contributor[msg.sender] != 0) {
            contributionIndex = contributor[msg.sender];
        } else {
            contributionIndex = numContributors + 1;
            require(
                contributionIndex <= contributorCapacity,
                "Contributor Capacity Reached"
            );
            numContributors++;
        }
        contributor[msg.sender] = contributionIndex;
        contribution[contributionIndex].addr = msg.sender;
        contribution[contributionIndex].amount += msg.value;
    }

    function airdrop() external onlyOwner {
        _airdrop(1, numContributors);
    }

    function airdropex(uint256 from, uint256 to) external onlyOwner {
        _airdrop(from, to);
    }

    function _airdrop(uint256 from, uint256 to) private {
        require(address(token) != address(0), "Unset Token");
        require(supply != 0, "Unset Supply");
        uint256 pricePerToken = (totalContributed * 10e18) / supply;
        for (uint256 i = from; i <= to; i++) {
            uint256 contributionAmount = contribution[i].amount * 10e18;
            uint256 numberOfTokensToMint = contributionAmount / pricePerToken;
            token.transfer(contribution[i].addr, numberOfTokensToMint);
        }
    }

    function open() external onlyOwner {
        contributionOpen = !contributionOpen;
    }

    function refund() external onlyOwner {
        _refund(1, numContributors);
    }

    function refundex(uint256 from, uint256 to) external onlyOwner {
        _refund(from, to);
    }

    function _refund(uint256 from, uint256 to) private {
        for (uint256 i = from; i <= to; i++) {
            address payable refundAddress = payable(contribution[i].addr);
            refundAddress.transfer(contribution[i].amount);
        }
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "Withdraw failed");
    }

    function withdrawERC20() external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        if (balance > 0) {
            token.transfer(owner(), balance);
        }
    }

    function setToken(IERC20 token_) external onlyOwner {
        token = token_;
    }

    function setSupply(uint256 supply_) external onlyOwner {
        supply = supply_;
    }

    function reduceCapacity(uint256 capacity_) external onlyOwner {
        require(capacity_ <= capacity, "Reduce Only");
        capacity = capacity_;
    }

    function reduceContributorCapacity(
        uint256 contributorCapacity_
    ) external onlyOwner {
        require(contributorCapacity_ <= contributorCapacity, "Reduce Only");
        contributorCapacity = contributorCapacity_;
    }
}