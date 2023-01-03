// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import './libraries/Math.sol';
import './interfaces/IERC20.sol';
import './interfaces/IRouter01.sol';
import './interfaces/IMasterchef.sol';

import "hardhat/console.sol";

interface IPair {
    //pair.sol
    function claimStakingFees() external;

    //pair.sol
    function token0() external view returns(address);
    function token1() external view returns(address);
}

// The base pair of pools, either stable or volatile
contract StakingNFTFeeConverter  {

    uint256 public lastRewardtime;

    address public masterchef;
    address public wbnb;
    address public owner;
    address public router;
    address public pairFactory;

    address[] public tokens;
    address[] public pairs;

    mapping(address => bool) public isToken;
    mapping(address => uint256) internal tokenToPosition;
    mapping(address => IRouter01.route) public tokenToRoutes;
    mapping(address => bool) public isKeeper;

    event StakingReward(uint256 _timestamp, uint256 _wbnbAmount);
    event TransferOwnership(address oldOwner, address newOwner);
    event ClaimFee(address indexed _pair, uint256 timestamp);
    event ClaimFeeError(address indexed _pair, uint256 timestamp);
    event SwapError(address indexed _tokenIn, uint256 _balanceIn, uint256 timestamp);  
    
    modifier onlyOwner() {
        require(msg.sender == owner, 'not allowed');
        _;
    }

    modifier keeper() {
        require(isKeeper[msg.sender] == true || msg.sender == owner, 'not keeper');
        _;
    }


    constructor() {
        owner = msg.sender;
        lastRewardtime = 0;
        wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    }



    /* ---------------------- HANDLE FEES */
    /* ---------------------- ---------------------- */
    /* ---------------------- ---------------------- */

    function claimFees() external keeper {
        uint i = 0;
        uint _len = pairs.length;
        address[] memory __pairs = new address[](_len);
        __pairs = pairs;

        for(i; i <_len; i++){
            try IPair(__pairs[i]).claimStakingFees() {
                emit ClaimFee(__pairs[i], block.timestamp);
            }
            catch {
                emit ClaimFeeError(__pairs[i], block.timestamp);
            }
        }

    }

    ///@notice claim any pair. Used if ClaimFeeError() is emitted 
    function claimSingleFee(address _pair) external keeper {
        require(_pair != address(0));
        IPair(_pair).claimStakingFees();
    }

    ///@notice swap any token. Used if SwapError() is emitted 
    function swapManual(uint amountIn,uint amountOutMin, IRouter01.route[] calldata _routes,uint deadline) external keeper returns (uint[] memory amounts) {
        amounts = IRouter01(router).swapExactTokensForTokens(amountIn, amountOutMin, _routes, address(this), deadline);
    }


    ///@notice set Masterchef distriubtion given this.balance 
    function setDistribution() external keeper {
        uint _balance = IERC20(wbnb).balanceOf(address(this));
        _safeTransfer(wbnb, masterchef, _balance);
        IMasterchef(masterchef).setDistributionRate(_balance);
        lastRewardtime = block.timestamp;
        emit StakingReward(block.timestamp, _balance);
    }



    function swap() external keeper {

        uint256 _balance;
        address _token;
        uint256 i;

        IRouter01.route[] memory _routes = new IRouter01.route[](1);

        for(i=0; i < tokens.length; i++){
            _token = tokens[i];
            _balance = IERC20(_token).balanceOf(address(this));
            if(_balance > 0 && isToken[_token]) {
                _routes[0] = tokenToRoutes[_token];
            
                _safeApprove(_token, router, 0);
                _safeApprove(_token, router, _balance);
                try IRouter01(router).swapExactTokensForTokens(_balance, 1, _routes, address(this), block.timestamp){}
                catch{
                    emit SwapError(_token, _balance, block.timestamp);
                    console.log("SwapError: ", _token);
                    console.log("SwapError: ", _balance);
                }             
            } 
        }

        _balance = IERC20(wbnb).balanceOf(address(this));
        _safeTransfer(wbnb, masterchef, _balance);
        IMasterchef(masterchef).setDistributionRate(_balance);
        lastRewardtime = block.timestamp;
        
        emit StakingReward(block.timestamp, _balance);

    }


    /* ---------------------- TOKEN SETTINGS */
    /* ---------------------- ---------------------- */
    /* ---------------------- ---------------------- */

    function setPair(address[] memory __pairs) external onlyOwner{
        uint i = 0;
        for(i; i < __pairs.length; i++){
            require(__pairs[i] != address(0));
            setToken(__pairs[i]);
            pairs.push(__pairs[i]);
        }
    }

    function setToken(address pair) internal {
        require(pair != address(0));

        address _token0 = IPair(pair).token0();
        address _token1 = IPair(pair).token1();
        require(_token0 != address(0));
        require(_token1 != address(0));

        IRouter01.route memory _routes;

        if(_token0 != wbnb && isToken[_token0] == false){
            _routes.from = _token0;
            _routes.to = wbnb;
            _routes.stable = false;
            tokenToRoutes[_token0] = _routes;
            isToken[_token0] = true;
            tokenToPosition[_token0] = tokens.length;
            tokens.push(_token0);
        }

        if(_token1 != wbnb && isToken[_token1] == false){
            _routes.from = _token1;
            _routes.to = wbnb;
            _routes.stable = false;
            tokenToRoutes[_token1] = _routes;
            isToken[_token1] = true;
            tokenToPosition[_token1] = tokens.length;
            tokens.push(_token1);
        }

    }

    function removeToken(address token) external onlyOwner {
        require(token != address(0));
        require(isToken[token] == true);
      

        uint256 _tokenToPosition = tokenToPosition[token];
        delete tokenToRoutes[token];
        delete tokenToPosition[token];
        delete tokenToRoutes[token];

        isToken[token] = false;

        if(tokens.length -1 == _tokenToPosition){
            tokens.pop();
        } else {
            address _lastToken = tokens[tokens.length -1];
            tokens[_tokenToPosition] = _lastToken;
            tokenToPosition[_lastToken] = _tokenToPosition;
            tokens.pop();
        }

    }

    function addToken(address token, IRouter01.route memory routes) external onlyOwner {
        require(token != address(0));
        require(isToken[token] == false);
        isToken[token] = true;
        tokenToRoutes[token] = routes;
        tokenToPosition[token] = tokens.length;
        tokens.push(token);
    }



    function setRoutesFor(address token, IRouter01.route memory routes) external onlyOwner {
        require(token != address(0));
        require(isToken[token] == true);
        require(routes.from == token);
        tokenToRoutes[token] = routes;
    }


    ///@notice in case token get stuck.
    function withdrawERC20(address _token) external onlyOwner {
        require(_token != address(0));
        uint256 _balance = IERC20(_token).balanceOf(address(this));
        _safeTransfer(_token, msg.sender, _balance);
    }

    /* ---------------------- VIEW */
    /* ---------------------- ---------------------- */
    /* ---------------------- ---------------------- */

    function _tokens() external view returns(address[] memory){
        return tokens;
    }
    function _pairs() external view returns(address[] memory){
        return pairs;
    }


    
    /* ---------------------- OWNER SETTINGS */
    /* ---------------------- ---------------------- */
    /* ---------------------- ---------------------- */

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        address _oldOwner = owner;
        owner = newOwner;
        emit TransferOwnership(_oldOwner, newOwner);
    }
    
    function setKeeper(address _keeper) external onlyOwner {
        require(_keeper != address(0));
        require(isKeeper[_keeper] == false);
        isKeeper[_keeper] = true;
    }

    function removeKeeper(address _keeper) external onlyOwner {
        require(_keeper != address(0));
        require(isKeeper[_keeper] == true);
        isKeeper[_keeper] = false;
    }
    
    function setRouter(address _router) external onlyOwner {
        require(_router != address(0), 'addr 0');
        router = _router;
    }

    function setMasterchef(address _masterchef) external onlyOwner {
        require(_masterchef != address(0), 'addr 0');
        masterchef = _masterchef;
    }

    function setPairFactory(address _pairFactory) external onlyOwner {
        require(_pairFactory != address(0), 'addr 0');
        pairFactory = _pairFactory;
    }


    function _safeTransfer(address token,address to,uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeApprove(address token,address spender,uint256 value) internal {
        require(token.code.length > 0);
        require((value == 0) || (IERC20(token).allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, spender, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

}