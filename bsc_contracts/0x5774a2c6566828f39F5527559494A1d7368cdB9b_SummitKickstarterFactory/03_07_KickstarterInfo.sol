import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

enum ApprovalStatus {
  PENDING,
  APPROVED,
  REJECTED
}

struct Kickstarter {
  IERC20 paymentToken;
  string title;
  string creator;
  string imageUrl;
  string projectDescription;
  string rewardDescription;
  uint256 minContribution;
  uint256 projectGoals;
  uint256 rewardDistributionTimestamp;
  uint256 startTimestamp;
  uint256 endTimestamp;
}