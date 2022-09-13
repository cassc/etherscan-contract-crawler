// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./interfaces/IFTFarm.sol";

contract Game is Ownable,Pausable,ReentrancyGuard{

    using SafeMath for uint256;
    
    using Math for uint256;
    
    using SafeERC20 for IERC20;

    using Counters for Counters.Counter;

    uint256 constant QUOTA = 10;//名额

    Counters.Counter private _configIds;

    struct Config{
        uint256 burn;
        uint256 deposit;
        address burnToken;
    }

    mapping(uint256=>Config) private _configs;//配置

    mapping(address=>uint256)private _signupBurnAmounts;//报名销毁数量

    mapping(uint256=>address[]) private _signupAddresses;//报名地址

    mapping(uint256=>mapping(address=>bool)) private _isSignups;//报名

    IERC20 immutable public ald;//销毁token

    IERC20 immutable public usdt;//抵押token

    IERC20 immutable public ft;//飞毯

    IFTFarm immutable public ftFarm;//飞毯农场

    IUniswapV2Router02 immutable public uniswapV2Router;//uniswap路由

    address immutable public burnAddress = 0x000000000000000000000000000000000000dEaD;//黑洞地址

    uint256[QUOTA-1] public rewardRates = [5,5,5,5,5,5,5,10,15];//奖励率

    uint256 public farmMul = 3;//农场倍数

    address public teamRewardWallet;//团队奖励分配地址

    uint256 immutable public teamRewardRate = 20;//团队奖励率

    uint256 immutable public swapRate = 20;//交换率

    uint256 public maxBurnFtAmount = 9000 * 1e18;//最大销毁飞毯数量

    uint256 private _ftBurnAmount;//ft销毁数量

    constructor(IERC20 ft_,IERC20 ald_,IFTFarm ftFarm_,IERC20 usdt_,IUniswapV2Router02 uniswapV2Router_){
        ald = ald_;
        usdt = usdt_;
        ft = ft_;
        ftFarm = ftFarm_;
        uniswapV2Router = uniswapV2Router_;
        teamRewardWallet = msg.sender;
    }

    function getSignupBurnAmount(address _token) external view returns(uint256){
        return _signupBurnAmounts[_token];
    }

    function getIsSignup(uint256 _id,address _account) public view returns(bool){
        return _isSignups[_id][_account];
    }

    function getSignupAddresses(uint256 _id) external view returns(address[] memory){
        return _signupAddresses[_id];
    }

    function getFtBurnAmount()external view returns(uint256){
        return _ftBurnAmount;
    }

    function signup(uint256 _id) external whenNotPaused nonReentrant {
        address user = msg.sender;
        require(_id<_configIds.current(),"Config not found");
        require(!getIsSignup(_id,user),"Already signup");
        require(_signupAddresses[_id].length<QUOTA,"The quota is full");
        //报名
        _isSignups[_id][user] = true;
        uint256 deposit = _configs[_id].deposit;
        uint256 burn = _configs[_id].burn;
        _burn(user,_configs[_id].burnToken,burn);
        usdt.safeTransferFrom(user, address(this), deposit);
        _signupAddresses[_id].push(user);
        emit Signup(_id,user);
        //开奖
        if(_signupAddresses[_id].length == QUOTA){
            _lottery(_id, deposit);
        }
    }

    function _burn(address _user,address _token,uint256 _amount) private{
        IERC20(_token).safeTransferFrom(_user, burnAddress, _amount);
        _signupBurnAmounts[address(_token)] += _amount;
    }

    function _lottery(uint256 _phase,uint256 _amount) private {
        address winAddress = _signupAddresses[_phase][_random(QUOTA-1)];
        address[QUOTA-1] memory loseAddresses;
        uint256[QUOTA-1] memory rewards;
        uint256[QUOTA-1] memory randomRewardRates = _getRandomRewardRates();
        uint256 loseIndex = 0;
        uint256 swapAmount = _amount.mul(swapRate).div(100);
        usdt.safeTransfer(teamRewardWallet, _amount.mul(teamRewardRate).div(100));
        for(uint256 i=0;i<QUOTA;i++){
            address account = _signupAddresses[_phase][i];
            if(account != winAddress){
                uint256 reward = _amount.mul(randomRewardRates[loseIndex]).div(100);
                loseAddresses[loseIndex] = account;
                rewards[loseIndex] = reward;
                usdt.safeTransfer(account, _amount.add(reward));
                loseIndex++;
            }else{
                ftFarm.stake(winAddress, _amount.mul(farmMul));
            }
        }
        emit Lottery(_phase,winAddress,loseAddresses,rewards,_swapAndBurn(swapAmount));
    }

    function _getRandomRewardRates() private view returns(uint256[QUOTA-1] memory result){
        result = rewardRates;
        for(uint256 i=0;i<result.length;i++){
            result = _swapOrder(result,i);
        }
    }

    function _swapOrder(uint256[QUOTA-1] memory _result,uint256 _sIndex) private view returns(uint256[QUOTA-1] memory result){
        uint256 random = _random(_result.length-1);
        uint256 tmp = _result[_sIndex];
        result = _result;
        result[_sIndex] = result[random];
        result[random] = tmp;
    }

    function _swapAndBurn(uint256 _amount) private returns(uint256 result){
        address[] memory path = new address[](2);
        path[0] = address(usdt);
        path[1] = address(ft);
        usdt.approve( address(uniswapV2Router), _amount);
        uint256 beforeFt = ft.balanceOf(address(this));
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp
        );
        result = ft.balanceOf(address(this)).sub(beforeFt);
        _ftBurnAmount += result;
        ft.safeTransfer(burnAddress, result);
        require(ft.balanceOf(burnAddress)<=maxBurnFtAmount,'GT max burn FT');
    }

    function _random(uint256 _number) private view returns(uint) {
        return uint256(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  msg.sender))) % _number;
    }

    function setTeamRewardWallet(address _wallet) external onlyOwner{
        teamRewardWallet = _wallet;
    }

    function setFarmMul(uint256 _mul) external onlyOwner{
        farmMul = _mul;
    }

    function setMaxBurnFtAmount(uint256 _amount) external onlyOwner{
        maxBurnFtAmount = _amount;
    }

    function createConfig(uint256 _deposit,address _burnToken,uint256 _burnAmount) external onlyOwner{
        Config memory config = Config(_burnAmount,_deposit,_burnToken);
        uint256 id = _configIds.current();
        _configIds.increment();
        _configs[id] = config;
        emit CreateConfig(id,_burnToken, _burnAmount, _deposit);
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

    event Lottery(uint256 id,address winAddress,address[QUOTA-1] loseAddresses,uint256[QUOTA-1] rewards,uint256 burnAmount);
    event Signup(uint256 id,address user);
    event CreateConfig(uint256 id,address burnToken,uint256 burn,uint256 deposit);
}