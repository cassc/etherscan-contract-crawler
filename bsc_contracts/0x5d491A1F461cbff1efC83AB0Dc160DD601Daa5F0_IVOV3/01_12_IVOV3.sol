// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IReferral.sol";
import "./interfaces/IWZNFT.sol";
import "./access/AccessControl.sol";
import "./interfaces/IIVO.sol";

contract IVOV3 is AccessControl, ReentrancyGuard,IIVO {
    
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct IvoData {
        uint256 balance;
        uint256 amount;
    }

    uint256 constant IVO_RELEASE_DAYS = 30;
    uint256 constant IVO_RECEIVE_INTERVAl = 1 days;

    uint256 constant MEMBER_MIN_HOLD_DEFI_WZ = 1e18 / 10;
    uint256 constant SHAREHOLDER_MIN_HOLD_DEFI_WZ = 1e18;
    uint256 constant SHAREHOLDER_IVO_AMOUNT = 2000 * 1e18;
    uint256 constant MEMBER_IVO_AMOUNT = 200 * 1e18;
    uint256 constant RECEIVE_REWARD_CONDITION = 1;

    IReferral public immutable referral;
    IERC20 public immutable usdt;
    IERC20 public immutable defiWz;
    IIVO public immutable oldIvo;
    IERC20 public immutable wzSwap;
    IWzNFT public immutable wzNft;

    uint256[2] public referralRewardRates = [5, 3];
    uint256 public ivoUsdtAmount;
    uint256 public ivoQuantity;

    uint256 public immutable usdtPerWzSwap;
    uint256 public immutable memberQuota;
    uint256 public memberSurplusQuota;
    uint256 public immutable shareholderQuota;
    uint256 public shareholderSurplusQuota;

    address public platformAddress;
    address public platformAddress1;
    uint256 public endTime;
    uint256 public p1Rate = 20;

    mapping(address => bool) private _isMemberIvo;
    mapping(address => bool) private _isShareholderIvo;
    mapping(address => uint256) private _referralCounts;
    mapping(address => uint256) private _referralRewards;
    mapping(address => IvoData) private _ivoDatas;
    mapping(address => bool) private _isWzNftList;
    mapping(address => uint256) private _lastReceiveIvoTimes;
    mapping(address=>bool) private _isReceiveWzNfts;
    mapping(address=>bool) private _isImport;

    event Ivo(address user, bool isMember);
    event ReferralReward(address from, address indexed to, uint256 amount);
    event ReceiveReward(address user, uint256 amount);
    event BatchSetIsWzNftList(address[] addresses, bool v);
    event ReceiveIvo(address user, uint256 amount);
    event ReceiveWzNft(address user, uint256 _tokenId);

    constructor(
        uint256 memberQuota_,
        uint256 shareholderQuota_,
        uint256 usdtPerWzSwap_,
        uint256 endTime_,
        IERC20 usdt_,
        IERC20 defiWz_,
        address platformAddress_,
        address platformAddress1_,
        IReferral referral_,
        IIVO oldIvo_,
        IWzNFT wzNft_,
        IERC20 wzSwap_
    ) {
        wzSwap = wzSwap_;
        wzNft = wzNft_;
        oldIvo = oldIvo_;
        memberQuota = memberSurplusQuota = memberQuota_;
        shareholderQuota = shareholderSurplusQuota = shareholderQuota_;
        usdtPerWzSwap = usdtPerWzSwap_;
        endTime = endTime_;
        usdt = usdt_;
        platformAddress = platformAddress_;
        platformAddress1 = platformAddress1_;
        referral = referral_;
        defiWz = defiWz_;
    }

    function isIvo(address _account) external view returns (bool){
        return _isIvo(_account);
    }

    function getReferralCount(address _address) public view returns (uint256) {
        return _referralCounts[_address];
    }

    function getReferralReward(address _address) public view returns (uint256) {
        return _referralRewards[_address];
    }

    function getLastReceiveIvoTime(address _address)
        public
        view
        returns (uint256)
    {
        return _lastReceiveIvoTimes[_address];
    }

    function isWzNftList(address _address) public view returns (bool) {
        return _isWzNftList[_address];
    }

    function isReceiveWzNft(address _address) public view returns (bool) {
        return _isReceiveWzNfts[_address];
    }

    function isMemberIvo(address _address) public  view returns (bool) {
        return _isMemberIvo[_address];
    }

    function isShareholderIvo(address _address) public  view returns (bool) {
        return _isShareholderIvo[_address];
    }

    function canIvo(address _address, bool _isMember)
        public
        view
        returns (bool)
    {
        return
            !_isIvo(_address) &&
            !_isEnd() &&
            _isQuotaSufficient(_isMember) &&
            usdt.balanceOf(_address) >= getIvoFee(_isMember);
    }

    function canReceiveReward(address _address) public view returns (bool) {
        return  getReferralCount(_address) >= RECEIVE_REWARD_CONDITION &&
            getReferralReward(_address) > 0;
    }

    function canReceiveWzNft(address _address) public view returns (bool) {
        return
            isWzNftList(_address) && !isReceiveWzNft(_address) &&
            address(wzNft) != address(0) &&
            wzNft.getSurplusQuantity() > 0;
    }

    function canReceiveIvo(address _address) public view returns (bool) {
        return _isEnd() &&
            block.timestamp >
            getLastReceiveIvoTime(_address).add(IVO_RECEIVE_INTERVAl) &&
            getIvoBalance(_address) > 0 &&
            address(wzSwap) != address(0) &&
            wzSwap.balanceOf(address(this)) >=
            _getIvoReceiveAmount(_ivoDatas[_address])
            && _isMinHoldDefiWz(_address, isMemberIvo(_address));
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

    function getIvoBalance(address _address) public view returns (uint256) {
        return _ivoDatas[_address].balance;
    }

    function getIvoAmount(address _address) external view returns (uint256) {
        return _ivoDatas[_address].amount;
    }

    function getIvoFee(bool _isMember) public view returns (uint256) {
        return
            (_isMember ? MEMBER_IVO_AMOUNT : SHAREHOLDER_IVO_AMOUNT).div(
                usdtPerWzSwap
            );
    }

    function ivo(bool _isMember, address _referral) external nonReentrant {
        address user = msg.sender;
        require(canIvo(user, _isMember), "Can't IVO");
        require(referral.isBindReferral(_referral), "Referral not exists");
        if (_shouldBindReferral(user, _referral))
            _bindReferral(user, _referral);
        uint256 ivoFee = getIvoFee(_isMember);
        usdt.safeTransferFrom(user, address(this), ivoFee);
        _ivo(_isMember, user, ivoFee);
        usdt.safeTransfer(platformAddress, _referralReward(user, ivoFee));
    }

    function receiveReward() external {
        address user = msg.sender;
        require(canReceiveReward(user), "Can't receive reward");
        uint256 reward = getReferralReward(user);
        _referralRewards[user] = 0;
        usdt.safeTransfer(user, reward);
        emit ReceiveReward(user, reward);
    }

    function receiveWzNft() external {
        address user = msg.sender;
        require(canReceiveWzNft(user), "Can't receive WZ NFT");
        _isWzNftList[user] = false;
        _isReceiveWzNfts[user] = true;
        emit ReceiveWzNft(user, wzNft.mint(user));
    }

    function receiveIvo() external {
        address user = msg.sender;
        require(canReceiveIvo(user), "Can't receive IVO");
        IvoData storage ivoData = _ivoDatas[user];
        uint256 amount = _getIvoReceiveAmount(ivoData);
        ivoData.balance = ivoData.balance.sub(amount);
        _lastReceiveIvoTimes[user] = block.timestamp;
        wzSwap.safeTransfer(user, amount);
        emit ReceiveIvo(user, amount);
    }

    function _ivo(
        bool _isMember,
        address _user,
        uint256 _fee
    ) private {
        if (_isMember) {
            memberSurplusQuota -= 1;
            _isMemberIvo[_user] = true;
        } else {
            shareholderSurplusQuota -= 1;
            _isShareholderIvo[_user] = true;
        }
        IvoData memory ivoData = IvoData(0, 0);
        ivoData.amount = ivoData.balance = _fee.mul(usdtPerWzSwap);
        _ivoDatas[_user] = ivoData;
        ivoQuantity += 1;
        ivoUsdtAmount = ivoUsdtAmount.add(_fee);
        emit Ivo(_user, _isMember);
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
        if(PFee>0)usdt.safeTransfer(platformAddress1,PFee);
        afterAmount = afterAmount.sub(PFee);
    }

    function _bindReferral(address _user, address _referral) private {
        referral.bindReferral(_referral, _user);
        _referralCounts[_referral] += 1;
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

    function _isEnd() private view returns (bool) {
        return block.timestamp > endTime;
    }

    function _isMinHoldDefiWz(address _address, bool _isMember)
        private
        view
        returns (bool)
    {
        return
            defiWz.balanceOf(_address) >=
            (
                _isMember
                    ? MEMBER_MIN_HOLD_DEFI_WZ
                    : SHAREHOLDER_MIN_HOLD_DEFI_WZ
            );
    }

    function _isIvo(address _address) public view returns (bool) {
        return _isMemberIvo[_address] || _isShareholderIvo[_address];
    }

    function _isQuotaSufficient(bool _isMember) private view returns (bool) {
        return (_isMember ? memberSurplusQuota : shareholderSurplusQuota) > 0;
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

    function setEndTime(uint256 _time) external onlyOwner {
        endTime = _time;
    }

    function setPlatformAddress(address _address) external onlyOwner {
        platformAddress = _address;
    }

    function setPlatformAddress1(address _address) external onlyOwner {
        platformAddress1 = _address;
    }

    function setP1Rate(uint256 _rate) external onlyOwner{
        p1Rate = _rate;
    }

    function setReferralRewardRates(uint256[2] calldata _rates)external onlyOwner{
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

    function import1(address[] calldata _addresses,bool _isMember) external onlyOwner {
        for(uint256 i=0;i<_addresses.length;i++){
            address account = _addresses[i];
            require(!_isImport[account],"error");
            _isImport[account] = true;
            if(_isMember){
                memberSurplusQuota-=1;
                _isMemberIvo[account] = true;
            }else{
                shareholderSurplusQuota -= 1;
                _isShareholderIvo[account] = true;
            }
            _referralCounts[account] = oldIvo.getReferralCount(account);
            _referralRewards[account] = oldIvo.getReferralReward(account);
            IvoData memory ivoData = IvoData(0, 0);
            ivoData.amount = ivoData.balance = oldIvo.getIvoBalance(account);
            _ivoDatas[account] = ivoData;
            ivoUsdtAmount += ivoData.amount.div(usdtPerWzSwap);
            ivoQuantity += 1;
        }
    }

    function batchSetIsWzNftList(address[] calldata _addresses, bool _v)
        external
        onlyOperator
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            address account = _addresses[i];
            require(_isShareholderIvo[account],"Not shareholder");
            _isWzNftList[account] = _v;
        }
        emit BatchSetIsWzNftList(_addresses, _v);
    }
}