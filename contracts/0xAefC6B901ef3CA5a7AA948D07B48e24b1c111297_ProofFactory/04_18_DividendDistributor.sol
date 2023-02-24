// SPDX-License-Identifier: None
pragma solidity = 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./libraries/TokenUtils.sol";
import "./interfaces/IDividendDistributor.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "hardhat/console.sol";

contract DividendDistributor is IDividendDistributor {
    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
    
    IUniswapV2Router02 router;
    IERC20 public RewardToken;

    address[] shareholders;
    mapping(address => uint256) public shareholderIndexes;
    mapping(address => uint256) public shareholderClaims;
    mapping(address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10**36;

    uint256 public minPeriod = 30 minutes;
    uint256 public minDistribution = 1 * (10**18);

    uint256 currentIndex;
    bool initialized;

    modifier onlyToken() {
        require(msg.sender == _token);
        _;
    }

    constructor(
        address _router,
        address _reflectionToken,
        address token
    ) {
        router = IUniswapV2Router02(_router);
        RewardToken = IERC20(_reflectionToken);
        _token = token;
        uint8 rewardTokenDecimals = TokenUtils.expectDecimals(token);
        uint256 fixedPoint = 10**rewardTokenDecimals;
        minDistribution = 1 * fixedPoint;
    }

    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function getShareHolders() external view returns (address[] memory) {
        return shareholders;
    }

    function setMinPeriod(uint256 _minPeriod) external onlyToken override {
        minPeriod = _minPeriod;
    }

    function setMinDistribution(uint256 _minDistribution) external onlyToken override {
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint256 amount)
        external
        override
        onlyToken
    {
        if (shares[shareholder].amount > 0) {
            distributeDividend(shareholder);
        }

        if (amount > 0 && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && shares[shareholder].amount > 0) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares - shares[shareholder].amount + amount;
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(
            shares[shareholder].amount
        );
    }

    function deposit() external payable override onlyToken {
        uint256 balanceBefore = RewardToken.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(RewardToken);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: msg.value
        }(0, path, address(this), block.timestamp);

        uint256 amount = RewardToken.balanceOf(address(this)) - balanceBefore;
        totalDividends = totalDividends + amount;
        dividendsPerShare = dividendsPerShare + dividendsPerShareAccuracyFactor * amount / totalShares;
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if (shareholderCount == 0) {
            return;
        }

        uint256 iterations = 0;
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }

            if (shouldDistribute(shareholders[currentIndex])) {
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed + gasLeft - gasleft();
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function shouldDistribute(address shareholder)
        internal
        view
        returns (bool)
    {
        return
            shareholderClaims[shareholder] + minPeriod <= block.timestamp &&
            getUnpaidEarnings(shareholder) >= minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if (shares[shareholder].amount == 0) {
            return;
        }

        uint256 amount = getUnpaidEarnings(shareholder);
        if (amount > 0) {
            totalDistributed = totalDistributed + amount;
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised + amount;
            shares[shareholder].totalExcluded = getCumulativeDividends(
                shares[shareholder].amount
            );
            RewardToken.transfer(shareholder, amount);
        }
    }

    function claimDividend() external {
        require(shouldDistribute(msg.sender), "Too soon. Need to wait!");
        distributeDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder)
        public
        view
        returns (uint256)
    {
        if (shares[shareholder].amount == 0) {
            return 0;
        }

        uint256 shareholderTotalDividends = getCumulativeDividends(
            shares[shareholder].amount
        );
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;
        if (shareholderTotalDividends <= shareholderTotalExcluded) {
            return 0;
        }

        return shareholderTotalDividends - shareholderTotalExcluded;
    }

    function getCumulativeDividends(uint256 share)
        internal
        view
        returns (uint256)
    {
        return
            share * dividendsPerShare / dividendsPerShareAccuracyFactor;
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[
            shareholders.length - 1
        ];
        shareholderIndexes[
            shareholders[shareholders.length - 1]
        ] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}