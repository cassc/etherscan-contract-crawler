// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FairLaunch is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMath for uint;

    address public rewardWallet;
    IERC20 public sellToken;

    string  name;        //Sale name
    uint256 price;      //per 1 ETH value

    uint256 totalPresale = 0; //260_000_000 * 10**18;     // ETH raised
    uint256 totalRaised;     // ETH raised

    uint256 minVal;     //Buy min
    uint256 maxVal;     //Buy max
    uint256 openingTime;
    uint256 closingTime;

    mapping(address => bool) private _whitelist; //

    //User
    struct UserBuy {
        uint256 locked; //lock buy pool
        uint256 at; //lock buy pool
        uint256 claimed; //has claim
        uint lastClaim; //lock buy pool
        uint256 raised; //r
        uint256 refRaised; //total ref raised
        uint luckyNumber; //total token wined
        bool isWhitelist; //token withdraw
    }
    mapping(address => UserBuy) private _buyed;   //user -> UserBuyed
    address[] private _lookup;

    //Referral:
    struct RefInfo {
        mapping(address => uint256) raised;
        address[] lookup;
        uint256 totalRaised; //total ETH
    }

    struct PriceLog {
        uint256 price; 
        uint256 time; 
    }
    PriceLog[] public Prices;
    
    mapping(address => RefInfo) private _refLogs;                   //user -> referral of user
    address[] private _refLogsLookup; //addr has refinfor
    //Reward sale:
    mapping(address => uint256) private _refRewards;                  //amout of ref reward
    address[] private _refLookup;

    mapping(address => uint256) private _giveawayRewards;                 //amout of giveaway reward  
    address[] private _giveawayLookup;

    uint256 public releaseReferalTime = 0;
    uint256 public releaseLuckyTime = 0;

    //Setup Vesting:
    struct VestingInfo {
        uint index;
        uint256 openingTime;
        uint256 percent;
    }
    mapping(uint => VestingInfo) private _vesting; //index - VestingInfo
    uint public vestingLength;

    //percent
    uint256 public apr = 0;
    uint256 private denominator = 10000;


    //Events:
    event TokensPurchased(
        address indexed beneficiary,
        uint256 value,
        uint256 totalRaised, 
        uint256 totalSale,
        uint totalContributer
    );
    event ClaimToken(address indexed beneficiary, uint256 amount);
    event Withdrawtoken(address indexed to, uint256 amount);
    event SetDone(address indexed from, bool result, uint256 value);

    modifier isLaunching() {
        require(block.timestamp >= openingTime && block.timestamp <= closingTime, "not in time");
        _;
    }

    function setToken(address addr) external onlyOwner {
        require(addr != address(0), "Zero address");
        sellToken = IERC20(addr);
    }

    function exportData(uint _index) public view returns (UserBuy memory data) {
        return _buyed[_lookup[_index]];
    }

    function exportPrice(uint _index) public view returns (PriceLog memory data) {
        return Prices[_index];
    }

    function exportCount() public view returns (uint count) {
        return _lookup.length;
    }

    function setRewardWallet(address _rewardWallet) external onlyOwner{
        require(_rewardWallet != address(0), "Zero address");
        rewardWallet = _rewardWallet;
    }

    //
    function importUser(address[] calldata addrs, uint256[] calldata amounts) external onlyOwner{
        for(uint i=0; i< addrs.length; i++){
            if (_buyed[addrs[i]].locked == 0) {
                _lookup.push(addrs[i]);
            }
            _buyed[addrs[i]].locked = _buyed[addrs[i]].locked.add(amounts[i]);
            _buyed[addrs[i]].claimed = 0;
            _buyed[addrs[i]].lastClaim = 0;
        }
    }

    function importRefReward(address[] calldata addrs, uint256[] calldata amounts) external onlyOwner{
        for(uint i=0; i< addrs.length; i++){
            _refRewards[addrs[i]] = _refRewards[addrs[i]].add(amounts[i]);
        }
    }

    function importLuckyReward(address[] calldata addrs, uint256[] calldata amounts) external onlyOwner{
        for(uint i=0; i< addrs.length; i++){
            _giveawayRewards[addrs[i]] = _giveawayRewards[addrs[i]].add(amounts[i]);
        }
    }

    function setReferalTime(uint256 _time) external onlyOwner {
        releaseReferalTime = _time;
    } 
    function setGiveawayTime(uint256 _time) external onlyOwner {
        releaseLuckyTime = _time;
    } 

    function setPool(string memory _name, uint256 _minUserCap, uint256 _maxUserCap, uint256 _openingTime, uint256 _closingTime) external onlyOwner {
        require(_closingTime > _openingTime, "opening is not before closing");
        name = _name;
        totalRaised = address(this).balance;
        minVal = _minUserCap;
        maxVal = _maxUserCap;
        openingTime = _openingTime;
        closingTime = _closingTime;
    }

    function getPool() public view returns (string memory, uint256, uint256, bool, uint256, uint256, uint256, uint256) {
        return (name, _lookup.length, totalRaised, false, minVal, maxVal, openingTime, closingTime);
    }

    function isWhitelist(address addr) public view returns (bool) {
        return _whitelist[addr];
    }

    function setWhitelist(address addr, bool val) external onlyOwner {
        require(addr != address(0), "addr is 0");
        _whitelist[addr] = val;
    }

    function addWhitelist(address addr) external {
        _whitelist[addr] = true;
    }

    receive() external payable{
        if(msg.value > 0){
            buyToken(address(0), block.timestamp % 1000);
        }
    }   
     
    function withdrawToken(address _to, uint256 _amount) external onlyOwner {
        require(_to != address(0), "Destination is 0");
        sellToken.transfer(_to, _amount);
        emit SetDone(_to, true, _amount);(_to, _amount);
    }

    function withdrawReward(uint256 _amount) external onlyOwner {
        sellToken.transfer(msg.sender, _amount);
        emit SetDone(msg.sender, true, _amount);
    }

    function withdrawRewardTo(address _to, uint256 _amount) external onlyOwner {
        require(_to != address(0), "Destination is 0");
        sellToken.transferFrom(rewardWallet, msg.sender, _amount);
        emit SetDone(_to, true, _amount);
    }

    function withdrawETH() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    struct RefView {
        address addr;
        uint256 raised; //total ETH
    }
    function getRefUser(address addr) public view returns (RefView[] memory) {
        uint count = _refLogs[addr].lookup.length;
        RefView[] memory ret = new RefView[](count);
        for (uint256 i = 0; i < count; i++) {
            ret[i].addr = _refLogs[addr].lookup[i];
            ret[i].raised = _refLogs[addr].raised[_refLogs[addr].lookup[i]];
        }
        return ret;
    }

    function getTotalPresale() public view returns (uint256) {
        return totalPresale > 0 ? totalPresale :  sellToken.balanceOf(address(this));
    }

    function getReferralReward(address account) public view returns (uint256) {
        return _refRewards[account];
    }

    function getGiveawayReward(address account) public view returns (uint256) {
        return _giveawayRewards[account];
    }

    function giveawayRewards() public view returns (address[] memory) {
        return _giveawayLookup;
    }

    function referralRewards() public view returns (address[] memory) {
        return _refLookup;
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal virtual isLaunching {
        require(beneficiary != address(0), "beneficiary is the zero address");
        require(weiAmount > 0, "weiAmount is 0");
        require(weiAmount >= minVal, "cap minimal required");
    }

    function buyToken(address refaddr, uint ln) public payable {
        address beneficiary = _msgSender();
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);
        //POOL
        totalRaised = totalRaised.add(weiAmount);
        //lookup 
        if (_buyed[beneficiary].raised == 0) {
            _lookup.push(beneficiary);
        }
        //USER
        _buyed[beneficiary].at = block.timestamp;
        _buyed[beneficiary].luckyNumber = ln;
        _buyed[beneficiary].isWhitelist = _whitelist[beneficiary];
        _buyed[beneficiary].raised = _buyed[beneficiary].raised.add(weiAmount);
        //REF USER:
        if (refaddr != address(0)) {
            //add lookup
            if (_refLogs[refaddr].totalRaised == 0) {
                _refLogsLookup.push(refaddr);
            }
            //total ref:
            _buyed[refaddr].refRaised = _buyed[refaddr].refRaised.add(weiAmount);
            //log ref
            if (_refLogs[refaddr].raised[beneficiary] == 0) {
                _refLogs[refaddr].lookup.push(beneficiary); 
            }
            _refLogs[refaddr].raised[beneficiary] = _refLogs[refaddr].raised[beneficiary].add(weiAmount); 
            _refLogs[refaddr].totalRaised = _refLogs[refaddr].totalRaised.add(weiAmount);
            //earn ref
        }
        fairLaunchCalculate();
        emit TokensPurchased(beneficiary, weiAmount, totalRaised, totalPresale > 0 ? totalPresale :  sellToken.balanceOf(address(this)), _lookup.length);
    }

    function getBuyInfo(address account) public view returns (uint256 raised, UserBuy memory user) {
        return (totalRaised, _buyed[account]);
    }

    //amount per pool can claim locked token (msg, until, amount, reward)
    function checkClaim(address holder) public view returns(string memory mss, uint time, uint256 amount, uint256 reward){
        if(_buyed[holder].locked == 0) {
            return ("Locked is zero", 0, 0, 0);
        }
        ( ,uint256 _reward) = rewardAmount(holder);
        //before release time
        if(block.timestamp < _vesting[0].openingTime){
            return ("Claim on ", _vesting[0].openingTime, _buyed[holder].locked.mul(_vesting[0].percent).div(denominator), _reward);
        }
        // release all
        if (block.timestamp >= _vesting[vestingLength - 1].openingTime){
            return ("Released", 0,  _buyed[holder].locked.sub( _buyed[holder].claimed), _reward);
        }
        //in
        uint _time = 0;
        uint256 percent = 0;
        uint256 toclaim = 0;
        for (uint256 i = 0; i < vestingLength; i++) {
            if(block.timestamp < _vesting[i].openingTime){
                _time = _vesting[i].openingTime;
                break;
            }
            percent = percent + _vesting[i].percent;
            toclaim = _buyed[holder].locked;
            toclaim = toclaim.mul(percent).div(denominator);
        }
        if (toclaim.sub(_buyed[holder].claimed) > 0) {
            return ("Claim amount ", 0, toclaim.sub(_buyed[holder].claimed), _reward);
        }
        return ("Claim on ", _time, 0, _reward);
    }

    //duration - amount
    function rewardAmount(address holder) public view returns(uint, uint256){
        uint256 amount = _buyed[holder].locked.sub(_buyed[holder].claimed);
        if(amount == 0){
            return (0, 0);
        }
        uint timeElapsed;
        if(_buyed[holder].lastClaim != 0){
            timeElapsed = block.timestamp - _buyed[holder].lastClaim;
        }else{
            timeElapsed = block.timestamp - _vesting[0].openingTime;
        }
        uint256 reward = amount.mul(timeElapsed).div(365 days).mul(apr).div(denominator);
        return (timeElapsed, reward);
    }

    function claim() external{
        ( , ,uint256 _amount, uint256 reward) = checkClaim(msg.sender);
        require(_amount > 0, "Nothing to claim");
        //require(sellToken.balanceOf(address(this)) >= _amount, "Pre-Sale not enough token");
        if(_amount > 0){
            if(reward > 0){
                require(sellToken.balanceOf(rewardWallet) >= _amount, "rewardWallet not enough token");
                sellToken.transferFrom(rewardWallet, msg.sender, reward);
            }
        }
        _buyed[msg.sender].lastClaim = block.timestamp;
        _buyed[msg.sender].claimed = _buyed[msg.sender].claimed.add(_amount);
        sellToken.transfer(msg.sender, _amount);
        emit ClaimToken(msg.sender, _amount);
    }

    function setAPR(uint _apr) external onlyOwner{
        apr = _apr;
    }

    function setTotalPresale(uint256 _wei) external onlyOwner{
        totalPresale = _wei;
    }

    function fairLaunchCalculate() internal {
        uint256 totaltoken = totalPresale > 0 ? totalPresale : sellToken.balanceOf(address(this));
        price = totaltoken.mul(10**18).div(totalRaised); //wei
        for (uint i = 0; i < _lookup.length; i++) {
            _buyed[_lookup[i]].locked = _buyed[_lookup[i]].raised.mul(price).div(10**18);
        }
        Prices.push(PriceLog(price, block.timestamp));
    }

    function getReleaseTime() public view returns(uint256) {
        return _vesting[0].openingTime;
    }

    //
    function setVesting(uint _index, uint256 _time, uint256 _vestpercent) external onlyOwner{
        if (_vesting[_index].percent == 0) {
            vestingLength++;
        }
        _vesting[_index].index = _index;
        _vesting[_index].openingTime = _time;
        _vesting[_index].percent = _vestpercent;
    }

    function getVesting(uint _index) public view returns(VestingInfo memory) {
        return _vesting[_index];
    }

    function setVestingLength(uint _length) external onlyOwner{
        vestingLength = _length;
    }

    function governanceRecoverUnsupported(IERC20 _token, uint256 _amount, address _to) external onlyOwner {
        _token.transfer(_to, _amount);
    }
}