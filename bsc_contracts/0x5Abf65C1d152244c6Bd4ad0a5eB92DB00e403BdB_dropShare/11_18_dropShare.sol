// Live deployment  v3

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "contracts/libraries/SafeMath8.sol";
import "contracts/interfaces/IOracle.sol";
import "contracts/libraries/Operator.sol";
import "contracts/interfaces/IUniswapV2Factory.sol";
import "contracts/interfaces/IUniswapV2Pair.sol";
import "contracts/interfaces/IUniswapV2Router02.sol";
import "contracts/drop.sol";

contract dropShare is ERC20Burnable, Operator {
    using SafeMath for uint256;

    uint256 public constant FARMING_POOL_REWARD_ALLOCATION = 30000 ether;
    uint256 public constant COMMUNITY_FUND_POOL_ALLOCATION = 4000 ether;
    uint256 public constant DEV_FUND_POOL_ALLOCATION = 4000 ether;
    uint256 public constant INITIAL = 100 ether;
    uint256 public constant VESTING_DURATION = 300 days;
    uint256 public constant MULTIPLIER = 100;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public communityFundRewardRate;
    uint256 public devFundRewardRate;

    address public communityFund;
    address public devFund;
    address public admin;

    // tax collection
    address public taxCollectorAddress;
    
    // immutables
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable BOND;
    DropLit public immutable DROP;
    address public immutable BUSD;
    address public immutable PairWBNB;
    address public immutable PairBUSD;
    address public immutable PairDROP;
    address public immutable genesisAddress;
    address public immutable boardroom;
    address public immutable treasury;
    address public immutable shareRewardPool;

    
    // whitelist from and too fee
	mapping(address => bool) public whitelist;


    uint256 public taxRate;
    uint256 public communityFundLastClaimed;
    uint256 public devFundLastClaimed;

    bool public rewardPoolDistributed = false;

        // modifiers
    modifier onlyTaxCollector() {
        require(taxCollectorAddress == _msgSender(), "caller is not the taxCollector");
        _;
    }

    modifier onlyWhitelist() {
         require(whitelist[msg.sender], "You are not whitelist");  
        _;
    }

        modifier onlyAdmin() {
         require(admin == msg.sender, "You are not the admin");  
        _;
    }

    constructor(address _BOND, address _DROP, address _BUSD, address _router, address _genesisAddress, address _treasury, address _boardroom, address _shareRewardPool, uint256 _startTime, address _communityFund, address _devFund) ERC20("Golden Drip Share", "GDS") {
        _mint(msg.sender, INITIAL); 
        BOND = _BOND;
        DROP = DropLit(_DROP);
        BUSD = _BUSD;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);
        uniswapV2Router = _uniswapV2Router;

        PairWBNB = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        PairBUSD = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), BUSD);

        PairDROP = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), address(DROP));

        DROP.setPairDshare(PairDROP);

        genesisAddress = _genesisAddress;
        treasury = _treasury;
        boardroom = _boardroom;
        shareRewardPool = _shareRewardPool;

        // distribute rewards
        rewardPoolDistributed = true;
        _mint(_shareRewardPool, FARMING_POOL_REWARD_ALLOCATION);

        admin = msg.sender;
        
        whitelist[boardroom] = true;
        whitelist[treasury] = true;
        whitelist[shareRewardPool] = true;
        whitelist[genesisAddress] = true;

        startTime = _startTime;
        endTime = startTime + VESTING_DURATION;

        communityFundLastClaimed = startTime;
        devFundLastClaimed = startTime;

        communityFundRewardRate = COMMUNITY_FUND_POOL_ALLOCATION.div(VESTING_DURATION);
        devFundRewardRate = DEV_FUND_POOL_ALLOCATION.div(VESTING_DURATION);

        require(_devFund != address(0), "Address cannot be 0");
        devFund = _devFund;

        require(_communityFund != address(0), "Address cannot be 0");
        communityFund = _communityFund;

        taxCollectorAddress = msg.sender; 
        
    }

    
    function isContract(address _addr) private view returns (bool){
        uint32 size;
        assembly {
        size := extcodesize(_addr)
        }
        return (size > 0);
    }

    // set whitelist
    function setWhiteList(address _WhiteList) public onlyAdmin {
        require(isContract(_WhiteList) == true, "only contracts can be whitelisted");
        require(address(uniswapV2Router) != _WhiteList, "set tax to 0 if you want to remove fee from trading");
        require(PairWBNB != _WhiteList, "set tax to 0 if you want to remove fee from trading");
        require(PairBUSD != _WhiteList, "set tax to 0 if you want to remove fee from trading");
        require(PairDROP != _WhiteList, "set tax to 0 if you want to remove fee from trading");

		whitelist[_WhiteList] = true;
    }

    function setAdmin(address _admin) public onlyAdmin {
        admin = _admin;
    }

    function setDevFund(address _devFund) external {
        require(msg.sender == devFund, "!dev");
        require(_devFund != address(0), "zero");
        devFund = _devFund;
    }


    function setCommunityFund(address _communityFund) external {
        require(msg.sender == communityFund, "!dev");
        require(_communityFund != address(0), "Address cannot be 0");
        communityFund = _communityFund;
    }

    function setTaxCollectorAddress(address _taxCollectorAddress) public onlyTaxCollector {
        require(_taxCollectorAddress != address(0), "taxCollectorAddress address cannot be 0 address");
        taxCollectorAddress = _taxCollectorAddress;
    }

    function setTaxRate(uint256 _taxRate) onlyTaxCollector public {
        require(_taxRate <= 5 ,"taxrate has to be between 0% and 5%" );
        taxRate = _taxRate;
    }

    function unclaimedTreasuryFund() public view returns (uint256 _pending) {
        uint256 _now = block.timestamp;
        if (_now > endTime) _now = endTime;
        if (communityFundLastClaimed >= _now) return 0;
        _pending = _now.sub(communityFundLastClaimed).mul(communityFundRewardRate);
    }

    function unclaimedDevFund() public view returns (uint256 _pending) {
        uint256 _now = block.timestamp;
        if (_now > endTime) _now = endTime;
        if (devFundLastClaimed >= _now) return 0;
        _pending = _now.sub(devFundLastClaimed).mul(devFundRewardRate);
    }

    /**
     * @dev Claim pending rewards to community and dev fund
     */
    function claimRewards() external {
        uint256 _pending = unclaimedTreasuryFund();
        if (_pending > 0 && communityFund != address(0)) {
            _mint(communityFund, _pending);
            communityFundLastClaimed = block.timestamp;
        }
        _pending = unclaimedDevFund();
        if (_pending > 0 && devFund != address(0)) {
            _mint(devFund, _pending);
            devFundLastClaimed = block.timestamp;
        }
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
         if (whitelist[sender] == true || whitelist[recipient] == true ) {
            super._transfer(sender, recipient, amount);
        }
        else {
        
        uint256 taxRateMultiplied = taxRate * MULTIPLIER;
        uint256 taxAmount = amount.mul(taxRateMultiplied).div(10000);
        uint256 amountAfterTax = amount.sub(taxAmount);

        _transfer(sender, taxCollectorAddress, taxAmount);
        _transfer(sender, recipient, amountAfterTax);
        
         }

        _approve(sender, _msgSender(), allowance(sender, _msgSender()).sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        if (whitelist[_msgSender()] == true || whitelist[recipient] == true ) {
            super._transfer(_msgSender(), recipient, amount);
        }
         else {

        uint256 taxRateMultiplied = taxRate * MULTIPLIER;

        uint256 taxAmount = amount.mul(taxRateMultiplied).div(10000);
        uint256 amountAfterTax = amount.sub(taxAmount);

        _transfer(_msgSender(), taxCollectorAddress, taxAmount);
        _transfer(_msgSender(), recipient, amountAfterTax);
        }

        return true;
    }

    function burn(uint256 amount) public override {
        super.burn(amount);
    }

}