// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IAirDropDistributor {
   function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
   function setShare(address shareholder, uint256 amount) external;
   function depositUSDT(uint256 amount) external;
   function process(uint256 gas) external;
}

contract AirDrop is IAirDropDistributor {
    using SafeMath for uint256;
	using SafeERC20 for IERC20;
	
    address _token;
	
    struct Share {
	  uint256 amount;
	  uint256 totalExcluded;
	  uint256 totalRealised;
    }
	
    IERC20 USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
	
    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;
    mapping (address => Share) public shares;
	
	event DistributionCriteriaUpdate(uint256 minPeriod, uint256 minDistribution);
	event NewFundDeposit(uint256 amount);

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public constant dividendsPerShareAccuracyFactor = 10 ** 36;
	
    uint256 public minPeriod = 7 days;
    uint256 public minDistribution = 1 * (10 ** 6);
	
    uint256 currentIndex;
	
    modifier onlyToken() {
        require(msg.sender == _token, "!Token"); _;
    }
	
    constructor () {
        _token = msg.sender;
    }
	
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
		emit DistributionCriteriaUpdate(minPeriod, minDistribution);
    }
	
    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }
		
        if(amount > 0 && shares[shareholder].amount == 0)
		{
            addShareholder(shareholder);
        }
		else if(amount == 0 && shares[shareholder].amount > 0)
		{
            removeShareholder(shareholder);
        }
		
        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function depositUSDT(uint256 amount) external override onlyToken {
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
		emit NewFundDeposit(amount);
    }

    function process(uint256 gas) external override onlyToken {
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
        return shareholderClaims[shareholder] + minPeriod < block.timestamp && getUnpaidEarnings(shareholder) > minDistribution;
    }
	
    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }
		
        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            USDT.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }
	
    function claimAirDrop() external {
		if(shouldDistribute(msg.sender)) 
		{
		   distributeDividend(msg.sender);
		}
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
}