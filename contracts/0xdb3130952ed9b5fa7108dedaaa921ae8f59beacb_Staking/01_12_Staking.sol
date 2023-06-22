// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/IFeesCollector.sol";
import "./interfaces/IWETH.sol";

contract Staking is IStaking, IFeesCollector, Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant PRECISION_DECIMALS = 1e18;

    uint256 public totalStaked;

    IERC20[] private claimableTokens;
    IERC20[] private otherTokens;

	mapping(IERC20 => bool) private claimableTokensSupported;
    mapping(IERC20 => bool) private otherTokensSupported;

	mapping(IERC20 => uint256) public totalProfits;

    mapping(address => mapping(IERC20 => uint256)) private lastProfits;
    mapping(address => mapping(IERC20 => uint256)) private savedProfits;

    mapping(address => uint256) public stakes;
    mapping(address => uint256) public stakeTimestamps;

    IERC20 private immutable cviToken;
    IWETH private immutable wethToken;
    address public immutable fallbackRecipient;

    IUniswapV2Router02 private immutable uniswapRouter;

    uint256 public stakeLockupTime = 1 hours;

	uint256 public creationTimestamp;

    constructor(IERC20 _cviToken, IUniswapV2Router02 _uniswapRouter) public {
    	cviToken = _cviToken;
    	uniswapRouter = _uniswapRouter;
    	wethToken = IWETH(_uniswapRouter.WETH());
    	fallbackRecipient = msg.sender;
		creationTimestamp = block.timestamp;
    }

    receive() external payable override {

    }

    function sendProfit(uint256 _amount, IERC20 _token) external override {
        bool isClaimableToken = claimableTokensSupported[_token];
        bool isOtherToken = otherTokensSupported[_token];
    	require(isClaimableToken || isOtherToken, "Token not supported");

    	if (totalStaked > 0) {
            if (isClaimableToken) {
    		  addProfit(_amount, _token);
            }
    		_token.safeTransferFrom(msg.sender, address(this), _amount);
    	} else {
    		_token.safeTransferFrom(msg.sender, fallbackRecipient, _amount);
    	}
    }

    function stake(uint256 _amount) external override {
    	require(_amount > 0, "Amount must be positive");

    	if (stakes[msg.sender] > 0) {
    		saveProfit(claimableTokens, msg.sender, stakes[msg.sender]);
    	}

    	stakes[msg.sender] = stakes[msg.sender].add(_amount);
    	stakeTimestamps[msg.sender] = block.timestamp;
    	totalStaked = totalStaked.add(_amount);

    	for (uint256 tokenIndex = 0; tokenIndex < claimableTokens.length; tokenIndex = tokenIndex.add(1)) {
    		IERC20 token = claimableTokens[tokenIndex];
	    	lastProfits[msg.sender][token] = totalProfits[token];	    	
	    }

	    cviToken.safeTransferFrom(msg.sender, address(this), _amount);
    }

    function unstake(uint256 _amount) external override {
    	require(_amount > 0, "Amount must be positive");
    	require(_amount <= stakes[msg.sender], "Not enough staked");
    	require(stakeTimestamps[msg.sender].add(stakeLockupTime) <= block.timestamp, "Funds locked");

    	totalStaked = totalStaked.sub(_amount);
    	stakes[msg.sender] = stakes[msg.sender].sub(_amount);
    	saveProfit(claimableTokens, msg.sender, _amount);
    	cviToken.safeTransfer(msg.sender, _amount);
    }

    function claimProfit(IERC20 token) external override returns (uint256 profit) {
    	_saveProfit(token, msg.sender, stakes[msg.sender]);
    	
    	profit = _claimProfit(token);
    	require(profit > 0, "No profit for token");
    }

    function claimAllProfits() external override returns (uint256[] memory) {
        uint256[] memory profits = new uint256[](claimableTokens.length); 
    	saveProfit(claimableTokens, msg.sender, stakes[msg.sender]);

    	uint256 totalProfit = 0;
    	for (uint256 tokenIndex = 0; tokenIndex < claimableTokens.length; tokenIndex++) {
            uint256 currProfit = _claimProfit(claimableTokens[tokenIndex]);
    		profits[tokenIndex] = currProfit;
            totalProfit = totalProfit.add(currProfit);
    	}

    	require(totalProfit > 0, "No profit");

        return profits;
    }

    function addClaimableToken(IERC20 _newClaimableToken) external override onlyOwner {
        _addToken(claimableTokens, claimableTokensSupported, _newClaimableToken);
    }

    function removeClaimableToken(IERC20 _removedClaimableToken) external override onlyOwner {
        _removeToken(claimableTokens, claimableTokensSupported, _removedClaimableToken);
    }

    function addToken(IERC20 _newToken) external override onlyOwner {
        _addToken(otherTokens, otherTokensSupported, _newToken);
        _newToken.safeApprove(address(uniswapRouter), uint256(-1));
    }

    function removeToken(IERC20 _removedToken) external override onlyOwner {
        _removeToken(otherTokens, otherTokensSupported, _removedToken);
        _removedToken.safeApprove(address(uniswapRouter), 0);
    }

    function convertFunds() external override {
        bool didConvert = false;
    	for (uint256 tokenIndex = 0; tokenIndex < otherTokens.length; tokenIndex++) {
    		IERC20 token = otherTokens[tokenIndex];
            uint256 balance = token.balanceOf(address(this));

            if (balance > 0) {
                didConvert = true;

        		address[] memory path = new address[](2);
            	path[0] = address(token);
            	path[1] = address(wethToken);

        		uint256[] memory amounts = 
        			uniswapRouter.swapExactTokensForTokens(token.balanceOf(address(this)), 
        				0, path, address(this), block.timestamp);
                addProfit(amounts[1], IERC20(address(wethToken)));
            }
    	}

        require(didConvert, "No funds to convert");
    }

    function setStakingLockupTime(uint256 _newLockupTime) external override onlyOwner {
        stakeLockupTime = _newLockupTime;
    }

    function profitOf(address _account, IERC20 _token) external view override returns (uint256) {
        return savedProfits[_account][_token].add(unsavedProfit(_account, stakes[_account], _token));
    }

    function getClaimableTokens() external view override returns (IERC20[] memory) {
        return claimableTokens;
    }

    function getOtherTokens() external view override returns (IERC20[] memory) {
        return otherTokens;
    }

    function _claimProfit(IERC20 _token) private returns (uint256 profit) {
    	require(claimableTokensSupported[_token], "Token not supported");
		profit = savedProfits[msg.sender][_token];

		if (profit > 0) {
			savedProfits[msg.sender][_token] = 0;
			lastProfits[msg.sender][_token] = totalProfits[_token];

			if (address(_token) == address(wethToken)) {
				wethToken.withdraw(profit);
                msg.sender.transfer(profit);
			} else {
				_token.safeTransfer(msg.sender, profit);
			}
		}
    }

    function _addToken(IERC20[] storage _tokens, mapping(IERC20 => bool) storage _supportedTokens, IERC20 _newToken) private {
    	require(!_supportedTokens[_newToken], "Token already added");
    	_supportedTokens[_newToken] = true;
    	_tokens.push(_newToken);
    }

    function _removeToken(IERC20[] storage _tokens, mapping(IERC20 => bool) storage _supportedTokens, IERC20 _removedTokenAddress) private {
    	require(_supportedTokens[_removedTokenAddress], "Token not supported");

    	bool isFound = false;
    	for (uint256 tokenIndex = 0; tokenIndex < _tokens.length; tokenIndex = tokenIndex.add(1)) {
    		if (_tokens[tokenIndex] == _removedTokenAddress) {
    			isFound = true;
    			_tokens[tokenIndex] = _tokens[_tokens.length.sub(1)];
    			_tokens.pop();
    			break;
    		}
    	}
    	require(isFound, "Token not found");

    	_supportedTokens[_removedTokenAddress] = false;
    }

    function addProfit(uint256 _amount, IERC20 _token) private {
    	totalProfits[_token] = totalProfits[_token].add(_amount.mul(PRECISION_DECIMALS).div(totalStaked));
    }

    function saveProfit(IERC20[] storage _claimableTokens, address _account, uint256 _amount) private {
    	for (uint256 tokenIndex = 0; tokenIndex < _claimableTokens.length; tokenIndex = tokenIndex.add(1)) {
    		IERC20 token = _claimableTokens[tokenIndex];
    		_saveProfit(token, _account, _amount);
    	}
    }

    function _saveProfit(IERC20 _token, address _account, uint256 _amount) private {
    	savedProfits[_account][_token] = 
    			savedProfits[_account][_token].add(unsavedProfit(_account, _amount, _token));
    }

    function unsavedProfit(address _account, uint256 _amount, IERC20 _token) private view returns (uint256) {
    	return totalProfits[_token].sub(lastProfits[_account][_token]).mul(_amount).div(PRECISION_DECIMALS);
    }
}