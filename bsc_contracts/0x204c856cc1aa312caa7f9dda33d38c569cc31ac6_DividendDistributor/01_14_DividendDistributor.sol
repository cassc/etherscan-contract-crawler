//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./Interface/IDividendDistributor.sol";
import "./PancakeswapInterface/IERC20.sol";

contract DividendDistributor is UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {

    using SafeMath for uint256;

    address ownerToken;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    // LAUNCH CHECK
    IERC20 BUSD;

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor;

    // LAUNCH CHECK
    // The threshold that the BNB in the distributor has to reach before it will swap for BUSD
    uint256 public dividendBNBThreshold;

    uint256 public minPeriod;
    uint256 public minDistribution;

    uint256 currentIndex;

    modifier onlyToken() {
        require(msg.sender == ownerToken); _;
    }

    function initialize(
        address _token,
        address _BUSD
    ) public initializer {
        ownerToken = _token;
        BUSD = IERC20(_BUSD);
        __Ownable_init();
        __ReentrancyGuard_init();

        dividendsPerShareAccuracyFactor = 10 ** 36;
        dividendBNBThreshold = 1 * (10 ** 18);
        minPeriod = 1 hours;
        minDistribution = 1 * (10 ** 18);
    }

    function _authorizeUpgrade(address newImplementaion) internal override onlyOwner {}

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setdividendBNBThreshold(uint256 _bnbamount) external onlyToken {
        dividendBNBThreshold = _bnbamount;
    }

    function setShare(address shareholder, uint256 amount) external onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }

        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function depositBUSD(uint256 busdAmount) external onlyToken {
        totalDividends = totalDividends.add(busdAmount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(busdAmount).div(totalShares));
    }

    function depositBUSDByOwner(uint256 busdAmount) external onlyOwner {
        totalDividends = totalDividends.add(busdAmount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(busdAmount).div(totalShares));
    }

    function process(uint256 gas) external onlyToken {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }
    
    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            BUSD.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }
    
    function claimDividend() external nonReentrant {
        distributeDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    function setSteakD(address _steakD) public onlyOwner {
        require(ownerToken != _steakD, "same value already!");
        ownerToken = _steakD;
    }

    receive() external payable {}
}