pragma solidity ^0.8.7;

import "@openzeppelin/access/Ownable.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";

contract ReguPresale is Ownable {
    IERC20 public immutable token;

    uint256 public constant MIN_CONTRIBUTION = .05 ether;
    uint256 public constant MAX_CONTRIBUTION = 2 ether;
    uint256 public constant PRESALE_SUPPLY = 233_100_000_000e18;

    struct Contribution {
        address addr;
        uint256 amount;
    }
    mapping(uint256 => Contribution) public contribution;
    mapping(address => uint256) public contributor;
    uint256 public totalContributed;
    uint256 public totalContributors;
    bool public presaleOpen;
    uint256 public presaleCap = 50 ether;

    constructor(IERC20 token_) {
        token = token_;
    }

    /**
     * @dev Users can send ETH to the contract directly if they want
     */
    receive() external payable {
        _receiveForPresale();
    }

    /**
     * @notice Contribute ETH to presale (Min 0.05 ETH / Max 2 ETH)
     */
    function purchase() public payable {
        _receiveForPresale();
    }

    function _receiveForPresale() private {
        require(presaleOpen, "Sale not open");
        uint256 currentContribution = contribution[contributor[msg.sender]]
            .amount;
        require(msg.value >= MIN_CONTRIBUTION, "Under min contribution");
        require(
            msg.value + currentContribution <= MAX_CONTRIBUTION,
            "Over max contribution"
        );
        uint256 contributionIndex;
        require(totalContributed <= presaleCap, "Contribution over hard cap");
        if (contributor[msg.sender] != 0) {
            contributionIndex = contributor[msg.sender];
        } else {
            contributionIndex = totalContributors + 1;
            totalContributors++;
        }
        contributor[msg.sender] = contributionIndex;
        contribution[contributionIndex].addr = msg.sender;
        contribution[contributionIndex].amount += msg.value;
        totalContributed += msg.value;
    }

    function airdrop() external onlyOwner {
        uint256 pricePerToken = (totalContributed * 10e18) / PRESALE_SUPPLY;
        for (uint256 i = 1; i <= totalContributors; i++) {
            uint256 contributionAmount = contribution[i].amount * 10e18;
            uint256 numberOfTokensToMint = contributionAmount / pricePerToken;
            token.transfer(contribution[i].addr, numberOfTokensToMint);
        }
    }

    function openPresale() external onlyOwner {
        presaleOpen = !presaleOpen;
    }

    function setPresaleCap(uint256 cap) external onlyOwner {
        require(cap <= presaleCap, "Reduce ONLY");
        presaleCap = cap;
    }

    function refund() external onlyOwner {
        for (uint256 i = 1; i <= totalContributors; i++) {
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

    function withdrawERC20(uint256 amount) external onlyOwner {
        token.transfer(owner(), amount);
    }
}