// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/IRewardTracker.sol";
import "../core/interfaces/IElpManager.sol";
import "../core/interfaces/IVaultPriceFeedV2.sol";
import "../core/interfaces/IVault.sol";
import "../tokens/interfaces/IMintable.sol";
import "../tokens/interfaces/IWETH.sol";
import "../tokens/interfaces/IELP.sol";
import "../utils/EnumerableValues.sol";
import "../DID/interfaces/IESBT.sol";


contract RewardRouter is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;

    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableValues for EnumerableSet.AddressSet;

    uint256 public cooldownDuration = 1 hours;
    mapping (address => uint256) public latestOperationTime;

    uint256 public constant PRICE_TO_EUSD = 10 ** 12; //ATTENTION: must be same as vault.
    uint256 public base_fee_point;  //using LVT_PRECISION
    uint256 public constant LVT_PRECISION = 10000;
    uint256 public constant LVT_MINFEE = 50;
    uint256 public constant PRICE_PRECISION = 10 ** 30; //ATTENTION: must be same as vault.
    uint256 public constant SWAP_THRESHOLD = 100 * (10 ** 30); //ATTENTION: must be same as vault.


    bool public isInitialized;
    // address public weth;
    address public rewardToken;
    address public eusd;
    address public weth;
    address public esbt;

    // address[] public allWhitelistedToken;
    // mapping (address => bool) public whitelistedToken;
    EnumerableSet.AddressSet internal allToken;
    mapping (address => bool) public swapToken;
    mapping (address => bool) public isStable;
    mapping (address => bool) public swapStatus;
    mapping (address => EnumerableSet.AddressSet) internal ELPnContainsToken;
    mapping (address => address) ELPnStableTokens;

    address public pricefeed;
    uint256 public totalELPnWeights;
    // address[] public allWhitelistedELPn;
    // uint256 public whitelistedELPnCount;
    // mapping (address => bool) public whitelistedELPn;
    EnumerableSet.AddressSet allWhitelistedELPn;
    address[] public whitelistedELPn;
    // mapping (address => bool) public whitelistedSELPn;
    // mapping (address => address) public correspondingSELPn;
    // mapping (address => address) public SELPn_correspondingELPn;
    mapping (address => uint256) public rewardELPnWeights;
    mapping (address => address) public stakedELPnTracker;
    mapping (address => address) public stakedELPnVault;
    mapping (address => uint256) public tokenDecimals;


    event StakeElp(address account, uint256 amount);
    event UnstakeElp(address account, uint256 amount);

    //===
    event UserStakeElp(address account, uint256 amount);
    event UserUnstakeElp(address account, uint256 amount);

    event Claim(address receiver, uint256 amount);

    event BuyEUSD(
        address account,
        address token,
        uint256 amount,
        uint256 fee
    );

    event SellEUSD(
        address account,
        address token,
        uint256 amount,
        uint256 fee
    );
    event ClaimESBTEUSD(address _account, uint256 claimAmount);


    receive() external payable {
        require(msg.sender == weth, "Router: invalid sender");
    }
    
    function initialize(
        address _rewardToken,
        address _eusd,
        address _weth,
        address _pricefeed,
        uint256 _base_fee_point
    ) external onlyOwner {
        require(!isInitialized, "RewardTracker: already initialized");
        isInitialized = true;
        eusd = _eusd;
        weth = _weth;
        rewardToken = _rewardToken;
        pricefeed = _pricefeed;
        base_fee_point = _base_fee_point;
        tokenDecimals[eusd] = 18;//(eusd).decimals()
    }
    
    function setRewardToken(address _rewardToken)external onlyOwner {
        rewardToken = _rewardToken;
    }

    function setPriceFeed(address _pricefeed)  external onlyOwner {
        pricefeed = _pricefeed;
    }

    function setESBT(address _esbt)  external onlyOwner {
        esbt = _esbt;
    }

    function setPriceFeed(address _token, bool _status)  external onlyOwner {
        swapToken[_token] = _status;
    }

    function setBaseFeePoint(uint256 _base_fee_point) external onlyOwner {
        base_fee_point = _base_fee_point;
    }
    
    function setCooldownDuration(uint256 _setCooldownDuration)  external onlyOwner {
        cooldownDuration = _setCooldownDuration;
    }

    function setTokenConfig(
        address _token,
        uint256 _token_decimal,
        address _elp_n,
        bool _isStable
    ) external onlyOwner {
        if (!allToken.contains(_token)){
            allToken.add(_token);
        }
        tokenDecimals[_token] = _token_decimal;

        if (!ELPnContainsToken[_elp_n].contains(_token))
            ELPnContainsToken[_elp_n].add(_token);
        if (_isStable){
            ELPnStableTokens[_elp_n] = _token;
            isStable[_token] = true;
        }
    }

    function delToken(
        address _token,
        address _elp_n
    ) external onlyOwner {
        if (allToken.contains(_token)){
            allToken.remove(_token);
        } 
        if (ELPnContainsToken[_elp_n].contains(_token))
            ELPnContainsToken[_elp_n].remove(_token);
    }

    function setSwapToken(address _token, bool _status) external onlyOwner{
        swapStatus[_token] = _status;
    }

    function setELPn(
        address _elp_n,
        uint256 _elp_n_weight,
        address _stakedELPnVault,
        uint256 _elp_n_decimal,
        address _stakedElpTracker
    ) external onlyOwner {
        if (!allWhitelistedELPn.contains(_elp_n)) {
            // whitelistedELPnCount = whitelistedELPnCount.add(1);
            allWhitelistedELPn.add(_elp_n);
        }
        //ATTENTION! set this contract as selp-n minter before initialize.
        //ATTENTION! set elpn reawardTracker as ede minter before initialize.
        uint256 _totalELPnWeights = totalELPnWeights;
        _totalELPnWeights = _totalELPnWeights.sub(rewardELPnWeights[_elp_n]);      
        totalELPnWeights = totalELPnWeights.add(_elp_n_weight);
        rewardELPnWeights[_elp_n] = _elp_n_weight;
        tokenDecimals[_elp_n] = _elp_n_decimal;
        stakedELPnTracker[_elp_n] = _stakedElpTracker;
        stakedELPnVault[_elp_n] = _stakedELPnVault;   
        whitelistedELPn = allWhitelistedELPn.valuesAt(0, allWhitelistedELPn.length());
    }

    function clearELPn(address _elp_n) external onlyOwner {
        require(allWhitelistedELPn.contains(_elp_n), "not included");
        totalELPnWeights = totalELPnWeights.sub(rewardELPnWeights[_elp_n]);
        allWhitelistedELPn.remove(_elp_n);
        // address _cor_selp = stakedELPnTracker[_token];

        // delete correspondingSELPn[_token];
        // delete SELPn_correspondingELPn[_cor_selp];
        // delete whitelistedELPn[_token];
        // delete whitelistedSELPn[_cor_selp];
        // delete tokenDecimals[_token];
        // delete tokenDecimals[_cor_selp];
        delete rewardELPnWeights[_elp_n];
        delete stakedELPnTracker[_elp_n];
        // whitelistedELPnCount = whitelistedELPnCount.sub(1);
        whitelistedELPn = allWhitelistedELPn.valuesAt(0, allWhitelistedELPn.length());
    }


    // to help users who accidentally send their tokens to this contract
    function withdrawToken(address _token, address _account, uint256 _amount) external onlyOwner {
        IERC20(_token).safeTransfer(_account, _amount);
    }

    //===============================================================================================================

    function stakedELPnAmount() external view returns (address[] memory, uint256[] memory, uint256[] memory) {
        uint256 poolLength = whitelistedELPn.length;
        uint256[] memory _stakedAmount = new uint256[](poolLength);
        address[] memory _stakedELPn = new address[](poolLength);
        uint256[] memory _poolRewardRate = new uint256[](poolLength);

        for (uint80 i = 0; i < poolLength; i++) {
            _stakedELPn[i] = whitelistedELPn[i];
            _stakedAmount[i] = IRewardTracker(stakedELPnTracker[whitelistedELPn[i]]).poolStakedAmount();
            _poolRewardRate[i] = IRewardTracker(stakedELPnTracker[whitelistedELPn[i]]).poolTokenRewardPerInterval();
        }
        return (_stakedELPn, _stakedAmount, _poolRewardRate);
    }


    function stakeELPn(address _elp_n, uint256 _elpAmount) external nonReentrant returns (uint256) {
        require(_elpAmount > 0, "RewardRouter: invalid _amount");
        require(allWhitelistedELPn.contains(_elp_n), "RewardTracker: invalid stake ELP Token"); 
        address account = msg.sender;

        latestOperationTime[account] = block.timestamp;

        IRewardTracker(stakedELPnTracker[_elp_n]).stakeForAccount(account, account, _elp_n, _elpAmount);
        

        emit UserStakeElp(account, _elpAmount);

        return _elpAmount;
    }

    function unstakeELPn(address _elp_n, uint256 _tokenInAmount) external nonReentrant returns (uint256) {
        address account = msg.sender;
        require(block.timestamp.sub(latestOperationTime[account]) > cooldownDuration, "Cooldown Time Required.");
        latestOperationTime[account] = block.timestamp;

        require(_tokenInAmount > 0, "RewardRouter: invalid _elpAmount");
        require(allWhitelistedELPn.contains(_elp_n), "RewardTracker: invalid stake Token"); 
        // address _orig_ELPn = SELPn_correspondingELPn[_tokenIn];
        // require(whitelistedELPn[_orig_ELPn], "RewardTracker: invalid ELPn"); 
        
        // IMintable(_tokenIn).burn(account, _tokenInAmount);
        IRewardTracker(stakedELPnTracker[_elp_n]).unstakeForAccount(account, _elp_n, _tokenInAmount, account);

        emit UserUnstakeElp(account, _tokenInAmount);

        return _tokenInAmount;
    }
    //----------------------------------------------------------------------------------------------------------------


    function claimEDEForAccount(address _account) external nonReentrant returns (uint256) {
        address account =_account == address(0) ? msg.sender : _account;
        return _claimEDE(account);
    }
    function claimEDE() external nonReentrant returns (uint256) {
        address account = msg.sender;
        return _claimEDE(account);
    }

    function claimEUSDForAccount(address _account) public nonReentrant returns (uint256) {
        address account =_account == address(0) ? msg.sender : _account;
        return _claimEUSD(account);
    }
    function claimEUSD() public nonReentrant returns (uint256) {
        address account = msg.sender;
        return _claimEUSD(account);
    }

    function claimEE(address[] memory _ELPlist) public nonReentrant returns (uint256, uint256) {
        address account = msg.sender;
        return _claimEEforAccount(account, _ELPlist);
    }

    function _claimEEforAccount(address _account, address[] memory _ELPlist)  internal returns (uint256, uint256) {
        require(block.timestamp.sub(latestOperationTime[_account]) > cooldownDuration, "Cooldown Time Required.");
        for (uint80 i = 0; i < _ELPlist.length; i++) {
            require(allWhitelistedELPn.contains(_ELPlist[i]), "invalid elp");
        }

        // uint256 this_reward  = IRewardTracker(stakedELPnTracker[_tokenIn]).claimForAccount(account, account);
        uint256 eusdClaimReward = 0;
        for (uint80 i = 0; i < _ELPlist.length; i++) {
            uint256 this_reward  = IRewardTracker(stakedELPnTracker[_ELPlist[i]]).claimForAccount(_account, _account);
            eusdClaimReward = eusdClaimReward.add(this_reward);
        }
        require(IERC20(rewardToken).balanceOf(address(this)) > eusdClaimReward, "insufficient EDE");
        IERC20(rewardToken).safeTransfer(_account, eusdClaimReward);
        address account =_account == address(0) ? msg.sender : _account;        
        uint256 edeClaimReward = 0;
        for (uint80 i = 0; i < _ELPlist.length; i++) {
            uint256 this_reward  = IELP(_ELPlist[i]).claimForAccount(account);
            edeClaimReward = edeClaimReward.add(this_reward);
        }
        return (edeClaimReward, eusdClaimReward);
    }


    function claimableEUSDForAccount(address _account) external view returns (uint256) {
        address account =_account == address(0) ? msg.sender : _account;
        uint256 totalClaimReward = 0;
        for (uint80 i = 0; i < whitelistedELPn.length; i++) {
            uint256 this_reward  = IELP(whitelistedELPn[i]).claimable(account);
            totalClaimReward = totalClaimReward.add(this_reward);
        }
        return totalClaimReward;        
    }
    function claimableEUSD() external view returns (uint256) {
        address account = msg.sender;
        uint256 totalClaimReward = 0;
        
        for (uint80 i = 0; i < whitelistedELPn.length; i++) {
            uint256 this_reward  = IELP(whitelistedELPn[i]).claimable(account);
            totalClaimReward = totalClaimReward.add(this_reward);
        }
        return totalClaimReward;        
    }
    

    function claimableEUSDListForAccount(address _account) external view returns (address[] memory, uint256[] memory) {
        
        uint256 poolLength = whitelistedELPn.length;
        address account =_account == address(0) ? msg.sender : _account;
        address[] memory _stakedELPn = new address[](poolLength);
        uint256[] memory _rewardList = new uint256[](poolLength);
        for (uint80 i = 0; i < whitelistedELPn.length; i++) {
            _rewardList[i] = IELP(whitelistedELPn[i]).claimable(account);
            _stakedELPn[i] = whitelistedELPn[i];
        }
        return (_stakedELPn, _rewardList);
    }
    function claimableEUSDList() external view returns (address[] memory, uint256[] memory) {
        
        uint256 poolLength = whitelistedELPn.length;
        address account = msg.sender;
        address[] memory _stakedELPn = new address[](poolLength);
        uint256[] memory _rewardList = new uint256[](poolLength);
        for (uint80 i = 0; i < whitelistedELPn.length; i++) {
            _rewardList[i] = IELP(whitelistedELPn[i]).claimable(account);
            _stakedELPn[i] = whitelistedELPn[i];
        }
        return (_stakedELPn, _rewardList);
    }

    function claimAllForAccount(address _account) external nonReentrant returns ( uint256[] memory) {
        address account =_account == address(0) ? msg.sender : _account;
        uint256[] memory reward = new uint256[](2);
        reward[0] = _claimEDE(account);
        reward[1] = _claimEUSD(account);
        return reward;
    }
    function claimAll() external nonReentrant returns ( uint256[] memory) {
        address account = msg.sender ;
        uint256[] memory reward = new uint256[](2);
        reward[0] = _claimEDE(account);
        reward[1] = _claimEUSD(account);
        return reward;
    }

    function _claimEUSD(address _account) private returns (uint256) {
        address account =_account == address(0) ? msg.sender : _account;
        require(block.timestamp.sub(latestOperationTime[account]) > cooldownDuration, "Cooldown Time Required.");
        
        
        uint256 totalClaimReward = 0;
        for (uint80 i = 0; i < whitelistedELPn.length; i++) {
            uint256 this_reward  = IELP(whitelistedELPn[i]).claimForAccount(account);
            totalClaimReward = totalClaimReward.add(this_reward);
        }
        return totalClaimReward;
    }


    function _claimEDE(address _account) private returns (uint256) {
        require(block.timestamp.sub(latestOperationTime[_account]) > cooldownDuration, "Cooldown Time Required.");
        // uint256 this_reward  = IRewardTracker(stakedELPnTracker[_tokenIn]).claimForAccount(account, account);
        
        uint256 totalClaimReward = 0;
        for (uint80 i = 0; i < whitelistedELPn.length; i++) {
            uint256 this_reward  = IRewardTracker(stakedELPnTracker[whitelistedELPn[i]]).claimForAccount(_account, _account);
            totalClaimReward = totalClaimReward.add(this_reward);
        }

        require(IERC20(rewardToken).balanceOf(address(this)) > totalClaimReward, "insufficient EDE");
        IERC20(rewardToken).safeTransfer(_account, totalClaimReward);

        // IMintable(rewardToken).mint(_account, totalClaimReward);
        return totalClaimReward;
    }


    function claimableEDEListForAccount(address _account) external view returns (address[] memory, uint256[] memory) {
        
        uint256 poolLength = whitelistedELPn.length;
        address[] memory _stakedELPn = new address[](poolLength);
        uint256[] memory _rewardList = new uint256[](poolLength);
        address account =_account == address(0) ? msg.sender : _account;
        for (uint80 i = 0; i < whitelistedELPn.length; i++) {
            _rewardList[i] = IRewardTracker(stakedELPnTracker[whitelistedELPn[i]]).claimable(account);
            _stakedELPn[i] = whitelistedELPn[i];
        }
        return (_stakedELPn, _rewardList);
    }
    function claimableEDEList() external view returns (address[] memory, uint256[] memory) {
        
        address account = msg.sender ;
        uint256 poolLength = whitelistedELPn.length;
        address[] memory _stakedELPn = new address[](poolLength);
        uint256[] memory _rewardList = new uint256[](poolLength);
        for (uint80 i = 0; i < whitelistedELPn.length; i++) {
            _rewardList[i] = IRewardTracker(stakedELPnTracker[whitelistedELPn[i]]).claimable(account);
            _stakedELPn[i] = whitelistedELPn[i];
        }
        return (_stakedELPn, _rewardList);
    }

    function claimableEDEForAccount(address _account) external view returns (uint256) {
        uint256 _rewardList = 0;
        address account =_account == address(0) ? msg.sender : _account;
        for (uint80 i = 0; i < whitelistedELPn.length; i++) {
            _rewardList = _rewardList.add(IRewardTracker(stakedELPnTracker[whitelistedELPn[i]]).claimable(account));
        }
        return _rewardList;
    }
    function claimableEDE() external view returns (uint256) {
        uint256 _rewardList = 0;
        address account = msg.sender;
        for (uint80 i = 0; i < whitelistedELPn.length; i++) {
            _rewardList = _rewardList.add(IRewardTracker(stakedELPnTracker[whitelistedELPn[i]]).claimable(account));
        }
        return _rewardList;
    }

    function withdrawToEDEPool() external {
        for (uint80 i = 0; i < whitelistedELPn.length; i++) {
            IELP(whitelistedELPn[i]).withdrawToEDEPool();
        }       
    }


    function claimableESBTEUSD(address _account) external view returns (uint256, uint256)  {
        if (esbt == address(0)) return (0, 0);
        (uint256 accumReb, uint256 accumDis) = IESBT(esbt).userClaimable(_account);
        accumReb = accumReb.div(PRICE_TO_EUSD);
        accumDis = accumDis.div(PRICE_TO_EUSD);
        return  (accumDis,accumReb);
    }

    function claimESBTEUSD( ) public nonReentrant returns (uint256) {
        address _account = msg.sender;  
        if (esbt == address(0)) return (0);
        (uint256 accumReb, uint256 accumDis) = IESBT(esbt).userClaimable(_account);
        accumReb = accumReb.div(PRICE_TO_EUSD);
        accumDis = accumDis.div(PRICE_TO_EUSD);
        uint256 claimAmount = accumDis.add(accumReb);
        IESBT(esbt).updateClaimVal(_account);

        if (claimAmount > 0)
            IMintable(eusd).mint(_account, claimAmount);
        emit ClaimESBTEUSD(_account, claimAmount);
        return claimAmount;
    }


    //------ EUSD Part 
    function _USDbyFee() internal view returns (uint256){
        uint256 feeUSD = 0;
        for (uint80 i = 0; i < whitelistedELPn.length; i++) {
            feeUSD = feeUSD.add( IELP(whitelistedELPn[i]).USDbyFee() );
        }
        return feeUSD;   
    }

    function _collateralAmount(address token) internal view returns (uint256) {
        uint256 colAmount = 0;
        for (uint80 i = 0; i < whitelistedELPn.length; i++) {
            colAmount = colAmount.add(IELP(whitelistedELPn[i]).TokenFeeReserved(token) );
        }    

        colAmount = colAmount.add(IERC20(token).balanceOf(address(this)));
        return colAmount;
    }

    function EUSDCirculation() public view returns (uint256) {
        uint256 _EUSDSupply = _USDbyFee().div(PRICE_TO_EUSD);
        return  _EUSDSupply.sub(IERC20(eusd).balanceOf(address(this)));
    }

    function feeAUM() public view returns (uint256) {
        uint256 aum = 0;

        address[] memory allWhitelistedToken = allToken.valuesAt(0, allToken.length());
        for (uint80 i = 0; i < allWhitelistedToken.length; i++) {
            uint256 price = IVaultPriceFeedV2(pricefeed).getOrigPrice(allWhitelistedToken[i]);
            uint256 poolAmount = _collateralAmount(allWhitelistedToken[i]);
            uint256 _decimalsTk = tokenDecimals[allWhitelistedToken[i]];
            aum = aum.add(poolAmount.mul(price).div(10 ** _decimalsTk));
        }
        return aum;
    }

    function lvt() public view returns (uint256) {
        uint256 _aumToEUSD = feeAUM().div(PRICE_TO_EUSD);
        uint256 _EUSDSupply = EUSDCirculation();
        return _aumToEUSD.mul(LVT_PRECISION).div(_EUSDSupply);
    }

    function _buyEUSDFee(uint256 _aumToEUSD, uint256 _EUSDSupply) internal view returns (uint256) {        
        uint256 fee_count = _aumToEUSD > _EUSDSupply ? base_fee_point : 0;
        return fee_count;
    }

    function _sellEUSDFee(uint256 _aumToEUSD, uint256 _EUSDSupply) internal view returns (uint256) {        
        uint256 fee_count = _aumToEUSD > _EUSDSupply ? base_fee_point : base_fee_point.add(_EUSDSupply.sub(_aumToEUSD).mul(LVT_PRECISION).div(_EUSDSupply) );
        return fee_count;
    }

    function buyEUSD( address _token, uint256 _amount) external nonReentrant returns (uint256)  {
        address _account = msg.sender;
        require(allToken.contains(_token), "Invalid Token");
        require(_amount > 0, "invalid amount");
        IERC20(_token).transferFrom(_account, address(this), _amount);
        uint256 buyAmount = _buyEUSD(_account, _token, _amount);
        return buyAmount;
    }

    function buyEUSDNative( ) external nonReentrant payable returns (uint256)  {
        address _account = msg.sender;
        uint256 _amount = msg.value;
        address _token = weth;
        require(allToken.contains(_token), "Invalid Token");
        require(_amount > 0, "invalid amount");

        IWETH(weth).deposit{value: msg.value}();
        uint256 buyAmount = _buyEUSD(_account, _token, _amount);

        return buyAmount;
    }



    function _buyEUSD(address _account, address _token, uint256 _amount) internal returns (uint256)  {
        uint256 _aumToEUSD = feeAUM().div(PRICE_TO_EUSD);
        uint256 _EUSDSupply = EUSDCirculation();
        
        // uint256 fee_count = _aumToEUSD > _EUSDSupply ? 0 : _EUSDSupply.sub(_aumToEUSD).mul(LVT_PRECISION).div(_EUSDSupply);
        uint256 fee_count = _buyEUSDFee(_aumToEUSD, _EUSDSupply);
        uint256 price = IVaultPriceFeedV2(pricefeed).getOrigPrice(_token);
        uint256 buyEusdAmount = _amount.mul(price).div(10 ** tokenDecimals[_token]).mul(10 ** tokenDecimals[eusd]).div(PRICE_PRECISION);
        uint256 fee_cut = buyEusdAmount.mul(fee_count).div(LVT_PRECISION);
        buyEusdAmount = buyEusdAmount.sub(fee_cut);
        
        require(buyEusdAmount < IERC20(eusd).balanceOf(address(this)), "insufficient EUSD");
        IERC20(eusd).safeTransfer(_account, buyEusdAmount);
        // IMintable(eusd).mint(_account, buyEusdAmount);
        // boughtEUSDAmount = boughtEUSDAmount.add(buyEusdAmount);
        
        emit BuyEUSD(_account, _token, buyEusdAmount, fee_count); 
        return buyEusdAmount;
    }

    function claimGeneratedFee(address _token) public returns (uint256) {
        uint256 claimedTokenAmount = 0;
        for (uint80 i = 0; i < whitelistedELPn.length; i++) {
            claimedTokenAmount = claimedTokenAmount.add(IVault(stakedELPnVault[whitelistedELPn[i]]).claimFeeToken(_token) );
        }
        return claimedTokenAmount;
    }

    function swapCollateral() public {
        for (uint256 i = 0; i < whitelistedELPn.length; i++) {
            if (whitelistedELPn[i] == address(0)) continue;
            if (ELPnStableTokens[whitelistedELPn[i]] == address(0)) continue;
            address[] memory _wToken = ELPnContainsToken[whitelistedELPn[i]].valuesAt(0,ELPnContainsToken[whitelistedELPn[i]].length());
 
            for (uint80 k = 0; k < _wToken.length; k++) {
                // if (isStable[_wToken[k]]) continue;
                if (!swapStatus[_wToken[k]]) continue;

                if (IVault(stakedELPnVault[whitelistedELPn[i]]).tokenToUsdMin(_wToken[k], IERC20(_wToken[k]).balanceOf(address(this)))
                    < SWAP_THRESHOLD)
                    break;
                IVault(stakedELPnVault[whitelistedELPn[i]]).swap(_wToken[k], ELPnStableTokens[whitelistedELPn[i]], address(this));
            }
        }
    }

    function sellEUSD(address _token, uint256 _EUSDamount) public nonReentrant returns (uint256)  {
        require(allToken.contains(_token), "Invalid Token");
        require(_EUSDamount > 0, "invalid amount");
        address _account = msg.sender;
        uint256 sellTokenAmount = _sellEUSD(_account, _token, _EUSDamount);

        IERC20(_token).transfer(_account, sellTokenAmount);

        return sellTokenAmount;
    }

    function sellEUSDNative(uint256 _EUSDamount) public nonReentrant returns (uint256)  {
        address _token = weth;
        require(allToken.contains(_token), "Invalid Token");
        require(_EUSDamount > 0, "invalid amount");
        address _account = msg.sender;
        uint256 sellTokenAmount = _sellEUSD(_account, _token, _EUSDamount);

        IWETH(weth).withdraw(sellTokenAmount);
        payable(_account).sendValue(sellTokenAmount);

        return sellTokenAmount;
    }

    function _sellEUSD(address _account, address _token, uint256 _EUSDamount) internal returns (uint256)  {
        uint256 _aumToEUSD = feeAUM().div(PRICE_TO_EUSD);
        uint256 _EUSDSupply = EUSDCirculation();
        
        uint256 fee_count = _sellEUSDFee(_aumToEUSD, _EUSDSupply);
        uint256 price = IVaultPriceFeedV2(pricefeed).getOrigPrice(_token);
        uint256 sellTokenAmount = _EUSDamount.mul(PRICE_PRECISION).div(10 ** tokenDecimals[eusd]).mul(10 ** tokenDecimals[_token]).div(price);
        uint256 fee_cut = sellTokenAmount.mul(fee_count).div(LVT_PRECISION);
        sellTokenAmount = sellTokenAmount.sub(fee_cut);
        claimGeneratedFee(_token);
        require(IERC20(_token).balanceOf(address(this)) > sellTokenAmount, "insufficient sell token");
       
        IERC20(eusd).transferFrom(_account, address(this), _EUSDamount);
       
        uint256 burnEUSDAmount = _EUSDamount.mul(fee_count).div(LVT_PRECISION);
        if (burnEUSDAmount > 0){
            IMintable(eusd).burn(address(this), burnEUSDAmount);     
        }


        // soldEUSDAmount = soldEUSDAmount.add(_EUSDamount);

        return sellTokenAmount;
    }



    function getEUSDPoolInfo() external view returns (uint256[] memory) {
        uint256[] memory _poolInfo = new uint256[](6);
        _poolInfo[0] = feeAUM();
        _poolInfo[1] = EUSDCirculation().add(IERC20(eusd).balanceOf(address(this)));
        _poolInfo[2] = EUSDCirculation();
        _poolInfo[3] = base_fee_point;
        _poolInfo[4] = _buyEUSDFee(_poolInfo[0].div(PRICE_TO_EUSD), _poolInfo[2]);
        _poolInfo[5] = _sellEUSDFee(_poolInfo[0].div(PRICE_TO_EUSD), _poolInfo[2]);
        return _poolInfo;
    }

    function getEUSDCollateralDetail() external view returns (address[] memory, uint256[] memory, uint256[] memory) {
        address[] memory allWhitelistedToken = allToken.valuesAt(0, allToken.length());
        uint256 _length = allWhitelistedToken.length;
        address[] memory _collateralToken = new address[](_length);
        uint256[] memory _collageralAmount = new uint256[](_length);
        uint256[] memory _collageralUSD  = new uint256[](_length);

        for (uint256 i = 0; i < allWhitelistedToken.length; i++) {
            uint256 price = IVaultPriceFeedV2(pricefeed).getOrigPrice(allWhitelistedToken[i]);
            _collateralToken[i] = allWhitelistedToken[i];
            _collageralAmount[i] =  _collateralAmount(allWhitelistedToken[i]);
            uint256 _decimalsTk = tokenDecimals[allWhitelistedToken[i]];
            _collageralUSD[i] = _collageralAmount[i].mul(price).div(10 ** _decimalsTk);
        }

        return (_collateralToken, _collageralAmount, _collageralUSD);
    }



}