// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IReferral.sol";
import "./interfaces/IIVO.sol";

contract IVOV4 is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _configIds;

    struct Config {
        uint256 id;
        uint256 usdtAmount;
        uint256 wzDaoAmount;
        uint256 stock;
        uint256 quoto;
        bool isNode;
        uint256 minHoldDefiWz;
    }

    struct IvoData {
        uint256 balance; //余额
        uint256 amount; //总金额
        uint256 createtime; //创建时间
        uint256 configId; //配置id
        uint256 lastReceivetime; //最后领取时间
    }

    uint256 constant IVO_RELEASE_DAYS = 30; //释放天数
    uint256 constant IVO_FIRST_RELEASE_INTERVAl = 7 days; //首次释放间隔
    uint256 constant IVO_RECEIVE_INTERVAl = 1 days; //释放间隔

    IReferral public immutable referral; //推荐关系
    IERC20 public immutable usdt; //usdt
    IERC20 public immutable defiWz; //DEFIWZ
    IERC20 public immutable wzDao; //WZDAO
    IIVO public immutable oldIvo; //原来的预售

    uint256[2] public referralRewardRates = [5, 3]; //推荐奖励率
    uint256 public ivoUsdtAmount; //预售usdt金额
    uint256 public ivoQuantity; //预售数量

    address public platformAddress; //平台地址
    address public platformAddress1; //平台地址1
    uint256 public p1Rate = 20; //平台地址1奖励率

    mapping(address => uint256) private _referralRewards; //推荐奖励
    mapping(address => IvoData) private _ivoDatas; //预售数据
    mapping(uint256 => Config) private _configs; //预售配置

    event Ivo(address user, bool isNode, uint256 usdtAmount);
    event ReferralReward(address from, address indexed to, uint256 amount);
    event ReceiveReward(address user, uint256 amount);
    event ReceiveIvo(address user, uint256 amount);

    constructor(
        IERC20 usdt_,
        IERC20 defiWz_,
        IERC20 wzDao_,
        address platformAddress_,
        address platformAddress1_,
        IReferral referral_,
        IIVO oldIvo_
    ) {
        oldIvo = oldIvo_;
        usdt = usdt_;
        platformAddress = platformAddress_;
        platformAddress1 = platformAddress1_;
        referral = referral_;
        defiWz = defiWz_;
        wzDao = wzDao_;
        _initConfig();
    }

    function getReferralReward(address _address) public view returns (uint256) {
        return _referralRewards[_address];
    }

    function canIvo(address _address, uint256 _configId)
        public
        view
        returns (bool)
    {
        return
            !isIvo(_address) &&
            _isQuotaSufficient(_configId) &&
            usdt.balanceOf(_address) >= getIvoFee(_configId) &&
            (!_configs[_configId].isNode || !referral.isBindReferral(_address));
    }

    function canReceiveReward(address _address) public view returns (bool) {
        return getReferralReward(_address) > 0;
    }

    function canReceiveIvo(address _address) public view returns (bool) {
        return
            isIvo(_address) &&
            block.timestamp >
            _ivoDatas[_address].createtime.add(IVO_FIRST_RELEASE_INTERVAl) &&
            block.timestamp >
            getIvoLastReceivetime(_address).add(IVO_RECEIVE_INTERVAl) &&
            getIvoBalance(_address) > 0 &&
            wzDao.balanceOf(address(this)) >=
            _getIvoReceiveAmount(_ivoDatas[_address]) &&
            _isMinHoldDefiWz(_address, _ivoDatas[_address].configId);
    }

    function getIvoReceiveAmount(address _address)
        external
        view
        returns (uint256)
    {
        return
            canReceiveIvo(_address)
                ? _getIvoReceiveAmount(_ivoDatas[_address])
                : 0;
    }

    function getIvoLastReceivetime(address _address)
        public
        view
        returns (uint256)
    {
        return _ivoDatas[_address].lastReceivetime;
    }

    function getConfig(uint256 _configId) public view returns(Config memory){
        return _configs[_configId];
    }

    function getIvoBalance(address _address) public view returns (uint256) {
        return _ivoDatas[_address].balance;
    }

    function getIvoAmount(address _address) external view returns (uint256) {
        return _ivoDatas[_address].amount;
    }

    function getIvoFee(uint256 _configId) public view returns (uint256) {
        return _configs[_configId].usdtAmount;
    }

    function isIvo(address _address) public view returns (bool) {
        return _ivoDatas[_address].createtime > 0 || oldIvo.isIvo(_address);
    }

    function ivo(uint256 _configId, address _referral)
        external
        nonReentrant
        existsConfig(_configId)
    {
        address user = msg.sender;
        require(canIvo(user, _configId), "Can't IVO");
        require(referral.isBindReferral(_referral), "Referral not exists");
        Config storage config = _configs[_configId];
        _referral = config.isNode ? referral.getRootAddress() : _referral;
        if (_shouldBindReferral(user, _referral))
            _bindReferral(user, _referral);
        usdt.safeTransferFrom(user, address(this), config.usdtAmount);
        _ivo(config, user);
        usdt.safeTransfer(
            platformAddress,
            _referralReward(user, config.usdtAmount)
        );
    }

    function receiveReward() external {
        address user = msg.sender;
        require(canReceiveReward(user), "Can't receive reward");
        uint256 reward = getReferralReward(user);
        _referralRewards[user] = 0;
        usdt.safeTransfer(user, reward);
        emit ReceiveReward(user, reward);
    }

    function receiveIvo() external {
        address user = msg.sender;
        require(canReceiveIvo(user), "Can't receive IVO");
        IvoData storage ivoData = _ivoDatas[user];
        uint256 amount = _getIvoReceiveAmount(ivoData);
        ivoData.balance = ivoData.balance.sub(amount);
        ivoData.lastReceivetime = block.timestamp;
        wzDao.safeTransfer(user, amount);
        emit ReceiveIvo(user, amount);
    }

    function _ivo(Config storage _config, address _user) private {
        _config.stock -= 1;
        IvoData memory ivoData = IvoData(0, 0, block.timestamp, _config.id, 0);
        ivoData.amount = ivoData.balance = _config.wzDaoAmount;
        _ivoDatas[_user] = ivoData;
        ivoQuantity += 1;
        ivoUsdtAmount = ivoUsdtAmount.add(_config.usdtAmount);
        emit Ivo(_user, _config.isNode, _config.usdtAmount);
    }

    function _referralReward(address _user, uint256 _amount)
        private
        returns (uint256 afterAmount)
    {
        afterAmount = _amount;
        address[] memory referrals = referral.getReferrals(
            _user,
            referralRewardRates.length
        );
        for (uint256 i = 0; i < referrals.length; i++) {
            address to = referrals[i];
            if (to == address(0)) continue;
            uint256 reward = _amount.mul(referralRewardRates[i]).div(100);
            _referralRewards[to] = _referralRewards[to].add(reward);
            afterAmount = afterAmount.sub(reward);
            emit ReferralReward(_user, to, reward);
        }
        uint256 PFee = _amount.mul(p1Rate).div(100);
        if (PFee > 0) usdt.safeTransfer(platformAddress1, PFee);
        afterAmount = afterAmount.sub(PFee);
    }

    function _bindReferral(address _user, address _referral) private {
        referral.bindReferral(_referral, _user);
    }

    function _getIvoReceiveAmount(IvoData memory _ivoData)
        private
        pure
        returns (uint256 amount)
    {
        amount = _ivoData.amount.div(IVO_RELEASE_DAYS);
        uint256 supAmount = _ivoData.balance.sub(amount);
        amount = amount > supAmount ? amount.add(supAmount) : amount;
    }

    function _isMinHoldDefiWz(address _address, uint256 _configId)
        private
        view
        returns (bool)
    {
        return defiWz.balanceOf(_address) >= _configs[_configId].minHoldDefiWz;
    }

    function _isQuotaSufficient(uint256 _configId) private view returns (bool) {
        return _configs[_configId].stock > 0;
    }

    function _shouldBindReferral(address _user, address _referral)
        private
        view
        returns (bool)
    {
        return
            !referral.isBindReferral(_user) &&
            referral.isBindReferral(_referral);
    }

    function _initConfig() private {
        Config memory config1 = Config(
            _configIds.current(),
            1000 * 1e18,
            1000 * 1e18,
            30,
            30,
            true,
            1 * 1e18
        );
        _configs[_configIds.current()] = config1;
        _configIds.increment();

        Config memory config2 = Config(
            _configIds.current(),
            100 * 1e18,
            100 * 1e18,
            20000,
            20000,
            false,
            (1 * 1e18) / 10
        );
        _configs[_configIds.current()] = config2;
        _configIds.increment();

        Config memory config3 = Config(
            _configIds.current(),
            300 * 1e18,
            300 * 1e18,
            10000,
            10000,
            false,
            (2 * 1e18) / 10
        );
        _configs[_configIds.current()] = config3;
        _configIds.increment();

        Config memory config4 = Config(
            _configIds.current(),
            500 * 1e18,
            500 * 1e18,
            10000,
            10000,
            false,
            (3 * 1e18) / 10
        );
        _configs[_configIds.current()] = config4;
        _configIds.increment();
    }

    function setPlatformAddress(address _address) external onlyOwner {
        platformAddress = _address;
    }

    function setPlatformAddress1(address _address) external onlyOwner {
        platformAddress1 = _address;
    }

    function setP1Rate(uint256 _rate) external onlyOwner {
        p1Rate = _rate;
    }

    function setReferralRewardRates(uint256[2] calldata _rates)
        external
        onlyOwner
    {
        referralRewardRates = _rates;
    }

    function withdraw(address _token, address payable _to) external onlyOwner {
        if (_token == address(0x0)) {
            payable(_to).transfer(address(this).balance);
        } else {
            IERC20(_token).transfer(
                _to,
                IERC20(_token).balanceOf(address(this))
            );
        }
    }

    modifier existsConfig(uint256 _configId) {
        require(_configId < _configIds.current(), "Config not exists");
        _;
    }
}