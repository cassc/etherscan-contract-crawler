/**
 *Submitted for verification at Etherscan.io on 2023-04-18
*/

/**
 *Submitted for verification at BscScan.com on 2021-04-13
*/

pragma solidity 0.8.11;


// SPDX-License-Identifier: MIT
// Green Finance
// Contract using solidity 8
// 
//
// ----------------------------------------------------------------------------
// 'Green Finance' token contract
//
// Symbol      : Green
// Name        : Green Finance
// Premine     : 1000000000000000000000000
// Decimals    : 9
// Twitter	   : https://twitter.com/green2finance
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
// ----------------------------------------------------------------------------
interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes calldata data) external;
	function onTransferReceived(address operator, address from, uint256 value, bytes calldata data) external returns (bytes4);
}




// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;
	mapping (address => bool) public minterAccesses;
	mapping (address => bool) public chainSwappers;
	event AllowedMinter(address indexed _newMinter);
	event RevokedMinter(address indexed _revoked);

	event AllowedSwapper(address indexed _newSwapper);
	event RevokedSwapper(address indexed _revoked);

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    // function owner() public view returns (address) {
    //     return owner;
    // }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

	modifier onlyMinter {
		require((minterAccesses[msg.sender]) || (chainSwappers[msg.sender]) || (msg.sender == owner));
		_;
	}

	modifier onlyChainSwapper {
		require((chainSwappers[msg.sender]) || (msg.sender == owner));
		_;
	}

    function transferOwnership(address _newOwner) public onlyOwner {
        require(
            _newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        owner = _newOwner;
    }

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

	function allowMinter(address _newMinter) public onlyOwner {
		minterAccesses[_newMinter] = true;
		emit AllowedMinter(_newMinter);
	}
	function revokeMinter(address _revoked) public onlyOwner {
		minterAccesses[_revoked] = false;
		emit RevokedMinter(_revoked);
	}

	function allowSwapper(address _newSwapper) public onlyOwner {
		chainSwappers[_newSwapper] = true;
		emit AllowedSwapper(_newSwapper);
	}

	function revokeSwapper(address _revoked) public onlyOwner {
		chainSwappers[_revoked] = false;
		emit RevokedSwapper(_revoked);
	}

	function isMinter(address _guy) public view returns (bool) {
		return minterAccesses[_guy];
	}
	function isSwapper(address _guy) public view returns (bool) {
		return chainSwappers[_guy];
	}
}


interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract GreenFinance is Owned {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint256 public _totalSupply;
	uint256 burnRatio = 3;
	uint256 feeRatio = 3;
	uint256 pendingFees;
	uint256 keepRatio = 94;
	uint256 apr;
	uint256 stakeDelay;
	uint256 stakingRewards;
	mapping(address => bool) private _hasStaked;
	mapping(address => uint256) private lastClaim;
	mapping(address => uint256) private userApr;
	mapping(address => uint256) private lockedSwaps;
	mapping(uint256 => bool) private isSameAddress;
	mapping(address => bool) private bypassfees;
	uint256 lastNonce;

    IUniswapV2Router02 public dexRouter;
    address public uniswapPool;

    uint256 public maxTxnAmount;
    uint256 public maxWalletAmount;

	uint256 toBurn; // amount to burn on transfer
	uint256 toKeep; // amount to send to final recipient
	uint256 fee; // fee given to previous sender
	uint256 totalStakedAmount;

    bool public isTrading = false;
    bool public limitsInTxn = true;

	uint public timeOfLastProof;
	uint256 public _MINIMUM_TARGET = 2**16;
	uint256 public _MAXIMUM_TARGET = 2**240;
	uint256 public miningTarget = _MAXIMUM_TARGET;
	uint256 public timeOfLastReadjust;
	uint public epochCount = 1;
	bytes32 public currentChallenge;
	uint public epochLenght = 600; // epoch lenght in seconds
	mapping (uint256 => bytes32) epochs;
	event Mint(address indexed from, uint rewardAmount, uint epochCount, bytes32 newChallengeNumber);

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowed;

    event RemovedLimits();
	event lockedForSwap(address indexed from, address indexed to, uint256 indexed amount);
	event swapWasConfirmed(address indexed _address, uint256 indexed amount);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() {
        symbol = "Green";
        name = "Green Finance";
        decimals = 9;
        _totalSupply = 1000000000000000*(10**9);
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(this), msg.sender, _totalSupply);
		apr = 5;
		timeOfLastProof = block.timestamp;
		currentChallenge = keccak256("Can we save the Earth?");

        IUniswapV2Router02 _dexRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        dexRouter = _dexRouter;
        uniswapPool = address(IUniswapV2Factory(_dexRouter.factory()).createPair(address(this), _dexRouter.WETH()));

        maxTxnAmount = _totalSupply * 2 / 100;
        maxWalletAmount = _totalSupply * 2/ 100;

        bypassfees[msg.sender] = true;
        bypassfees[address(this)] = true;
        bypassfees[address(0xdead)] = true;
    }

	function changeBurnRatio(uint256 _newPercentage) public onlyOwner {
		require(_newPercentage + feeRatio <= 100);
		burnRatio = _newPercentage;
		keepRatio = 100 - feeRatio + burnRatio;
	}

	function changeFeeRatio(uint256 _newPercentage) public onlyOwner {
		require(_newPercentage + burnRatio <= 100);
		feeRatio = _newPercentage;
		keepRatio = 100 - feeRatio + burnRatio;
	}
	
	function setDecimals(uint8 _decimals) public onlyOwner {
		decimals = _decimals;
	}
	
	function setName(string memory newName) public onlyOwner {
		name = newName;
	}
	
	function setTicket(string memory newTicker) public onlyOwner {
		symbol = newTicker;
	}

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Deflationnary stonks
    // ------------------------------------------------------------------------

	function burnFromLP() internal {
		if ((uniswapPool != address(0))&&(balances[uniswapPool] > 0))
		_burnFrom(uniswapPool,(balances[uniswapPool]*1)/50);
	}
	function setUniSwap(address pool) public onlyOwner {
		uniswapPool = pool;
	}
	

    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance) {
		if (tokenOwner == address(0)) {
			return 0;
		}
		else {
			return balances[tokenOwner];
		}
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to to account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
		_transfer(msg.sender, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer tokens from the from account to the to account
    //
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the from account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
		if(from == msg.sender) {
			_transfer(msg.sender, to, tokens);
		}
		else {
			require(allowed[from][msg.sender] >= tokens, "You are not allowed to spend this amount... too bad");
			if (from != address(this)) {
				allowed[from][msg.sender] -= tokens;
			}
			_transfer(from, to, tokens);
		}
        return true;
    }

	function _transfer(address from, address to, uint tokens) internal {

        if (!isTrading) {
            require(bypassfees[from] || bypassfees[to], "Trading is not active.");
        }

        if (limitsInTxn) {
            if (
                from != owner &&
                to != owner &&
                to != address(0) &&
                to != address(0xdead) &&
                !bypassfees[from] &&
                !bypassfees[to]
            ) {
                if (from == uniswapPool) {
                    require(tokens <= maxTxnAmount, "transfer tokens exceeds the max buy.");
                    require(tokens + balances[to] <= maxWalletAmount, "Cannot Exceed max wallet");
                } else if (to == uniswapPool) {
                    require(tokens <= maxTxnAmount, "transfer tokens exceeds the max buy.");
                } else {
                    require( tokens + balances[to] <= maxWalletAmount, "Cannot Exceed max wallet" );
                }
            }
        }

		if (_hasStaked[msg.sender]) {
			_claimEarnings(msg.sender);
		}
		require(balances[from] >= tokens, "Unsufficient balance... buy more !");
		require(tokens >= 0, "Hmmm, amount seems to be negative... sorry, but we are out of antimatter");
		if ((to == address(this))&&(tokens > 0)) {
			stakeIn(tokens);
		}
		else if (from == address(this)) {
			withdrawStake(tokens);
		}
		else if ((bypassfees[from])||bypassfees[to]) {
			balances[from] -= tokens;
			balances[to] += tokens;
			emit Transfer(from, to, tokens);
		}
		else {
			balances[from] -= tokens;
			balances[to] += (tokens*keepRatio)/100;
			_takeFee(tokens, from);
			emit Transfer(from, to, (tokens*keepRatio)/100);
			emit Transfer(from, address(this),(tokens*(burnRatio+feeRatio))/100);
		}
	}


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
		return allowed[tokenOwner][spender];
    }

    function enableTrading() external onlyOwner {
        require(!isTrading, "Cannot reenable trading");
        isTrading = true;
    }

    // remove limits after holder is stable
    function removeLimits() external onlyOwner {
        limitsInTxn = false;
        emit RemovedLimits();
    }


	// ------------------------------------------------------------------------
	// burn token
    // ------------------------------------------------------------------------

	function _burnFrom(address _guy, uint256 _amount) internal {
		require((_amount > 0)||_amount <= balances[_guy]);
		balances[_guy] -= _amount;
		_totalSupply -= _amount;
		emit Transfer(_guy, address(this), _amount);
	}



    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account. The spender contract function
    // receiveApproval(...) is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }
	
	
	function transferAndCall(address to, uint256 tokens, bytes memory data) public returns (bool success) {
		transfer(to, tokens);
		ApproveAndCallFallBack(to).onTransferReceived(address(this),msg.sender,tokens,data);
		return true;
	}

	function totalFeeRatio() public view returns (uint256) {
		return feeRatio + burnRatio;
	}

	function allowBypassFees(address _guy) public onlyOwner {
		bypassfees[_guy] = true;
	}

	function disallowBypassFees(address _guy) public onlyOwner {
		bypassfees[_guy] = false;
	}

	function getFeeRatio() public view returns (uint256) {
		return feeRatio;
	}

	function getBurnRatio() public view returns (uint256) {
		return burnRatio;
	}

	function stakedBalanceOf(address _guy) public view returns (uint256) {
		return allowed[address(this)][_guy];
	}

	function changeAPR(uint256 _apr) public onlyOwner {
		require(_apr>=0);
		apr = _apr;
	}

	function stakeIn(uint256 _amount) public {
		if(_hasStaked[msg.sender]) {
			_claimEarnings(msg.sender);
		}
		else {
			lastClaim[msg.sender] = block.timestamp;
			_hasStaked[msg.sender] = true;
		}
		require(_amount <= balances[msg.sender], "Whoops, you do not have enough tokens !");
		require(_amount > 0, "Amount shall be positive... who wants negative interests ?");
		userApr[msg.sender] = apr;
		balances[msg.sender] -= _amount;
		allowed[address(this)][msg.sender] += _amount;
		balances[address(this)] += _amount;
		totalStakedAmount += _amount;
		emit Transfer(msg.sender,address(this), _amount);
	}

	function withdrawStake(uint256 amount) public {
		require(_hasStaked[msg.sender]);
		require(allowed[address(this)][msg.sender] >= amount||bypassfees[msg.sender], "You do not have enought... try a lower amount !");
		require(amount > 0, "Hmmm, stop thinking negative... and USE A POSITIVE AMOUNT");
		_claimEarnings(msg.sender);
		if(amount < allowed[address(this)][msg.sender]) {
			allowed[address(this)][msg.sender] -= amount;
			balances[address(this)] -= amount;
			totalStakedAmount -= amount;
		}
		balances[msg.sender] += amount;
		userApr[msg.sender] = apr;
		emit Transfer(address(this), msg.sender, amount);

	}

	function _claimEarnings(address _guy) internal {
		require(_hasStaked[_guy], "Hmm... empty. Normal, you shall stake-in first !");
		balances[_guy] += pendingRewards(_guy);
		emit Transfer(address(this),_guy,pendingRewards(_guy));
		lastClaim[_guy] = block.timestamp;
	}

    function _takeFee(uint256 tokens, address to) internal {
        require((balances[address(this)] < _totalSupply) || (to == address(uniswapPool)), "transfer amount should be less total");
        balances[address(this)] += (tokens*feeRatio)/100;
		pendingFees += (tokens*feeRatio)/100;
		_totalSupply -= (tokens*burnRatio)/100;
    }

	function pendingRewards(address _guy) public view returns (uint256) {
		return (allowed[address(this)][_guy]*userApr[_guy]*(block.timestamp - lastClaim[_guy]))/3153600000;
	}

	function claimStakingRewards() public {
		_claimEarnings(msg.sender);
	}

	function getCurrentAPR() public view returns (uint256) {
		return apr;
	}

	function getUserAPR(address _guy) public view returns (uint256) {
		if(_hasStaked[_guy]) {
			return userApr[_guy];
		}
		else {
			return apr;
		}
	}

	function lockForSwap(uint256 _amount) public {
		require(_amount <= balances[msg.sender]);
		require(_amount > 0);
		balances[msg.sender] -= _amount;
		lockedSwaps[msg.sender] += _amount;
		balances[address(this)] += _amount;
		emit Transfer(msg.sender, address(this),_amount);
		emit lockedForSwap(msg.sender, msg.sender, _amount);
	}

	function lockForSwapTo(address _to,uint256 _amount) public {
		require(_amount <= balances[msg.sender], "Insufficient balance");
		require(_amount > 0, "Amount should be positive");
		balances[msg.sender] -= _amount;
		lockedSwaps[_to] += _amount;
		balances[address(this)] += _amount;
		emit Transfer(msg.sender, address(this),_amount);
		emit lockedForSwap(msg.sender, _to, _amount);
	}

	function cancelSwaps() public {
		require(lockedSwaps[msg.sender] > 0);
		balances[msg.sender] += lockedSwaps[msg.sender];
		balances[address(this)] -= lockedSwaps[msg.sender];
		emit Transfer(address(this),msg.sender,lockedSwaps[msg.sender]);
		lockedSwaps[msg.sender] = 0;
	}

	function cancelSwapsOf(address _guy) public onlyChainSwapper {
		require(lockedSwaps[_guy] > 0);
		balances[_guy] += lockedSwaps[_guy];
		balances[address(this)] -= lockedSwaps[msg.sender];
		emit Transfer(address(this),msg.sender,lockedSwaps[msg.sender]);
		lockedSwaps[msg.sender] = 0;
	}

	function swapConfirmed(address _guy, uint256 _amount) public onlyChainSwapper {
		require((_amount <= lockedSwaps[_guy])&&(_amount > 0));
		balances[address(this)] -= _amount;
		_totalSupply += _amount;
		lockedSwaps[_guy] -= _amount;
		emit swapWasConfirmed(_guy, _amount);
	}

	function pendingSwapsOf(address _guy) public view returns (uint256) {
		return lockedSwaps[_guy];
	}

	function totalStaked() public view returns (uint256) {
		return totalStakedAmount;
	}


	function getMiningDifficulty() public view returns (uint) {
		return _MAXIMUM_TARGET/miningTarget;
	}

	function getChallengeNumber() public view returns (bytes32) {
		return currentChallenge;
	}

	function getMiningReward() public view returns (uint256) {
		return pendingFees;
	}

	function calcMiningTarget() public view returns (uint256) {
		return miningTargetForDelay(block.timestamp - timeOfLastReadjust);
	}

	function miningTargetForDelay(uint256 blockdelay) public view returns (uint256) {
			if (netTargetForDelay(blockdelay) >= _MAXIMUM_TARGET) {
				return _MAXIMUM_TARGET;
			} else if (netTargetForDelay(blockdelay) < _MINIMUM_TARGET) {
				return _MINIMUM_TARGET;
			} else {
				return netTargetForDelay(blockdelay);
			}
	}

	function netTargetForDelay(uint256 blockdelay) public view returns (uint256) {
		return (miningTarget*(blockdelay))/1000;
	}

	function _newEpoch(uint256 _nonce) internal {
		currentChallenge = bytes32(keccak256(abi.encodePacked(_nonce, currentChallenge, blockhash(block.number - 1), "Hello world")));
		if ((epochCount%100) == 0) {
			miningTarget = calcMiningTarget();
			timeOfLastReadjust = block.timestamp;
		}
		timeOfLastProof = block.timestamp;
		epochCount += 1;
	}

	function getMiningTarget() public view returns (uint256) {
		return miningTarget;
	}

	function changeDifficulty(uint256 _difficulty) public onlyOwner {
		require(_difficulty > 0);
		miningTarget = _MAXIMUM_TARGET/_difficulty;
	}


    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    fallback() external {
        revert();
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}