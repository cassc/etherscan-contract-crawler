/**
 * SuperStake: Hex
 * 
 * https://superstake.win
 */
//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@uniswap/v2-core/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import "@uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolImmutables.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./DPT/TokenDividendTracker.sol";
import "./SimpleStakingImpl.sol";
import "./IMultisend.sol";
import "./ArbUtils.sol";
// Seriously if you audit this and ping it for "no safemath used" you're gonna out yourself as an idiot
// SafeMath is by default included in solidity 0.8, I've only included it for the transferFrom

contract SuperStake is Context, IERC20, Ownable, IERC20Permit, IMultisend {
    /** START OF EIP2612/EIP712 VARS */
    
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /** END OF EIP2612/EIP712 VARS */
    
    event ArbitragedPools(uint256 amount, bool wasUsdcLower);
    event Bought(address indexed buyer, uint256 amount);
    event Sold(address indexed seller, uint256 amount);

    event Minted(uint256 amount);
    event Burned(uint256 amount);

    using SafeMath for uint256;
    // Constants
    string private constant _name = "SuperStake: Hex";
    string private constant _symbol = "SSH";
    string private constant _max = "SSH: MAX";
    string private constant _reinit = "SSH: REINIT";
    // Standard decimals
    uint8 private constant _decimals = 9;
    // 55.55m
    uint256 private constant initialSupply = 55550000 * 10**9;
    // The actual current supply
    uint256 public currentSupply;
    // USDC
    address private _usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address private constant _dead = 0x000000000000000000000000000000000000dEaD;

    address private _wnative;
    // Mappings
    mapping(address => uint256) private tokensOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    struct mappingStructs {
        bool _isExcludedFromFee;
        bool _bots;
        uint32 _lastTxBuy;
        uint32 _lastTxSell;
        uint32 botBlock;
        bool isLPPair;
        bool isInitialLP;
    }
    
    struct LaggedLPData {
        address lpAddr;
        uint112 reserve0;
        uint112 reserve1;
        uint256 laggedBurnAmt;
    }

    mapping(address => mappingStructs) private mappedAddresses;

    mapping(address => uint256) private airdropTokens;

    // Arrays
    address[] private airdropPrivateList;
    address[] private lpPairs;

    address[] private initialLPPairs;

    // Global variables

    uint256 private laggedBurnAmt;

    LaggedLPData private laggedLP;

    uint256 public currentChainId;

    // Block
    address public dividendTracker;
    // Default
    uint32 private gasForProcessing = 300000;
    uint32 private hexStakingRatio = 2500;
    bool private disableAddToBlocklist = false;
    bool private removedLimits = false;
    // 8 bits remaining

    // Block of 256 bits
    uint32 private openBlock;
    uint32 private pair1Pct = 50; 
    // Storage block closed

    // Block of 256 bits
    address public stakingImpl;
    // Tax distribution ratios
    uint32 private hexRewardRatio = 5000;
    // 64 bits remaining
    // Storage block closed

    // Block of 256 bits
    // This is Hex
    address private rewardToken = 0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39;
    uint32 private pair2Pct = 50;
    uint32 private buyInfl = 7500;
    uint32 private sellDefl = 9000;
    // Storage block closed

    // Block of 256 bits
    // 160 bits free

    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private arbEnabled = true;
    // 8 bits free
    // Storage block closed


    IUniswapV2Router02 private uniswapV2Router;



    constructor(address router) {
        uniswapV2Router = IUniswapV2Router02(router);
        // Set up EIP712
        bytes32 hashedName = keccak256(bytes(_name));
        bytes32 hashedVersion = keccak256(bytes("1"));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;



        tokensOwned[_msgSender()] = initialSupply;
        currentSupply = initialSupply;
        
        // Set up the dividends
        TokenDividendTracker tracker = new TokenDividendTracker(rewardToken, 1000000000);

        dividendTracker = address(tracker);
        // Create the SimpleStakingImpl
        
        // This addr is Hedron
        SimpleStakingImpl staker = new SimpleStakingImpl(rewardToken, 60, dividendTracker, address(0x3819f64f282bf135d62168C1e513280dAF905e06), router);
        stakingImpl = address(staker);
        tracker.setStakingImpl(stakingImpl);
        // Handle exclusion from dividends
        
        tracker.excludeFromDividends(dividendTracker);
        tracker.excludeFromDividends(address(this));
        tracker.excludeFromDividends(owner());
        tracker.excludeFromDividends(_dead);

        // Save chain ID
        currentChainId = block.chainid;

        // Create the staking contract


        // Set the struct values
        mappedAddresses[_msgSender()] = mappingStructs({
            _isExcludedFromFee: true,
            _bots: false,
            _lastTxBuy: 0,
            _lastTxSell: 0,
            botBlock: 0,
            isLPPair: false,
            isInitialLP: false
        });
        mappedAddresses[address(this)] = mappingStructs({
            _isExcludedFromFee: true,
            _bots: false,
            _lastTxBuy: 0,
            _lastTxSell: 0,
            botBlock: 0,
            isLPPair: false,
            isInitialLP: false
        });
        mappedAddresses[dividendTracker] = mappingStructs({
            _isExcludedFromFee: true,
            _bots: false,
            _lastTxBuy: 0,
            _lastTxSell: 0,
            botBlock: 0,
            isLPPair: false,
            isInitialLP: false
         });
        emit Transfer(address(0), _msgSender(), initialSupply);
        
    }


    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return currentSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokensOwned[account];
    }

    // These functions are to inflate/deflate supply on buys/sells as per the tokenomics
    function _increaseSupply(uint256 amt) internal {
        currentSupply += amt;
        tokensOwned[address(this)] += amt;
        emit Transfer(address(0), address(this), amt);
        emit Minted(amt);
    }
    
    function _decreaseSupply(uint256 amt, address lpToBurn) internal {
        currentSupply -= amt;
        tokensOwned[lpToBurn] -= amt;
        IUniswapV2Pair(lpToBurn).sync();
        emit Transfer(lpToBurn, address(0), amt);
        emit Burned(amt); 
    }



    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        
        _transfer(sender, recipient, amount);

        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }


    /// @notice Starts trading. Only callable by owner.                                                                                                                                          
    function openTrading(address nativeWrapped) public onlyOwner {
        require(!tradingOpen, "OPEN");
        _wnative = nativeWrapped;
        // Exclude the router from dividends
        TokenDividendTracker(dividendTracker).excludeFromDividends(address(uniswapV2Router));
        
        _approve(address(this), address(uniswapV2Router), type(uint256).max);
        address uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), _wnative);
        // Create a USDC pair - this is to provide a second pool to process taxes through
        address uniswapV2Pair2 = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(
                address(this),
                _usdc
            );
        // Exclude both pairs
        TokenDividendTracker(dividendTracker).excludeFromDividends(address(uniswapV2Pair));
        TokenDividendTracker(dividendTracker).excludeFromDividends(address(uniswapV2Pair2));
        // Add Pair1Pct of the eth and LP to the first (ETH) pair
        uint256 pair1TAmt = (balanceOf(address(this)) * pair1Pct) / 100;
        uint256 pair2TAmt = (balanceOf(address(this)) * pair2Pct) / 100;
        uint256 pair1EAmt = (address(this).balance);
        //uint256 pair2EAmt = (address(this).balance * pair2Pct) / 100;
        
        uniswapV2Router.addLiquidityETH{value: pair1EAmt}(
            address(this),
            pair1TAmt,
            0,
            0,
            owner(),
            block.timestamp
        );
        // Swap the pair2Pct eth amount for USDC
        /*address[] memory path = new address[](2);
        path[0] = _wnative;
        path[1] = _usdc;
        uniswapV2Router.swapExactETHForTokens{value: pair2EAmt}(
            0,
            path,
            address(this),
            block.timestamp
        );*/
        // Approve the USDC spend
        IERC20 usdc = IERC20(_usdc);
        // Actually get our balance
        uint256 pair2UAmt = usdc.balanceOf(address(this));
        usdc.approve(address(uniswapV2Router), pair2UAmt);
        // Create a token/usdc pool
        uniswapV2Router.addLiquidity(
            _usdc,
            address(this),
            pair2UAmt,
            pair2TAmt,
            0,
            0,
            owner(),
            block.timestamp
        );
        swapEnabled = true;
        tradingOpen = true;
        openBlock = uint32(block.number);
        IERC20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint256).max
        );
        IERC20(uniswapV2Pair2).approve(
            address(uniswapV2Router),
            type(uint256).max
        );
        // Add the pairs to the list 
        mappedAddresses[uniswapV2Pair] = mappingStructs({
            _isExcludedFromFee: false,
            _bots: false,
            _lastTxBuy: 0,
            _lastTxSell: 0,
            botBlock: 0,
            isLPPair: true,
            isInitialLP: true
        });
        mappedAddresses[uniswapV2Pair2] = mappingStructs({
            _isExcludedFromFee: false,
            _bots: false,
            _lastTxBuy: 0,
            _lastTxSell: 0,
            botBlock: 0,
            isLPPair: true,
            isInitialLP: true
        });
        // Add to LP pair list
        lpPairs.push(uniswapV2Pair);
        lpPairs.push(uniswapV2Pair2);

        // Add to initial LP pair list
        initialLPPairs.push(uniswapV2Pair);
        initialLPPairs.push(uniswapV2Pair2);
        
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint32 _flAmt;
        bool isSell = false;
        
        if (
            from != owner() &&
            to != owner() &&
            from != address(this) &&
            !mappedAddresses[to]._isExcludedFromFee &&
            !mappedAddresses[from]._isExcludedFromFee
        ) {
            require(
                !mappedAddresses[to]._bots && !mappedAddresses[from]._bots,
                "SSH: Blocklisted."
            );
            

            if (mappedAddresses[from].isLPPair) {
                // buy, or LP remove
                
                // Make a distinction between the two
                IUniswapV2Pair lpPair = IUniswapV2Pair(from);
                if(lpPair.token0() == address(this)) {
                    // Token1 is other pair
                    IERC20 otherTok = IERC20(lpPair.token1());
                    (, uint112 reserve1,) = lpPair.getReserves();
                    if(otherTok.balanceOf(from) > reserve1) {
                        // Means balance is going up of the other token - this must be a buy
                        _flAmt = buyInfl;
                        // Only allow one type of operation - buy, or sell, per tx
                        require(mappedAddresses[to]._lastTxSell != uint32(block.number), "SSH: SWCH");
                        mappedAddresses[to]._lastTxBuy = uint32(block.number);
                    } else {
                        // Either balance is going down of the other token, hasn't been sent yet (never true for a buy, but definitely the case if we're token0 on a LP removal) - if we get here, this is a LP removal
                        _flAmt = 0;
                    }
                } else {
                    // Token0 is the other token
                    IERC20 otherTok = IERC20(lpPair.token0());
                    (uint112 reserve0, ,) = lpPair.getReserves();
                    if(otherTok.balanceOf(from) > reserve0) {
                        // Balance going up on other token - must be a buy
                        _flAmt = buyInfl;
                        // Only allow one type of operation - buy, or sell, per tx
                        require(mappedAddresses[to]._lastTxSell != uint32(block.number), "SSH: SWCH");
                        mappedAddresses[to]._lastTxBuy = uint32(block.number);
                    } else {
                        // Either balance is going down of the other token or hasn't been sent yet (never true for a buy or if SSH is token1) - if we get here, this is a LP removal
                        _flAmt = 0;
                    }
                }
               
            } else if (mappedAddresses[to].isLPPair) {
                // Sell, or LP add
                
                // Checks if it's either forkController or chain ID matches
                isSell = true;
                _flAmt = sellDefl;
                // Only allow one type of operation - buy, or sell, per tx
                require(mappedAddresses[from]._lastTxBuy != uint32(block.number), "SSH: SWCH");
                mappedAddresses[from]._lastTxSell = uint32(block.number);
            } else {
                // No inflation/deflation on transfers
                _flAmt = 0;
                // Check if this is going to become a new LP
                uint8 lpType = isNewLP(to);
                require(lpType != 2, "SSH: No v3 LP.");
                if(lpType == 1) {
                    // V2 LP, so add the "to" address to the LP list for tracking
                    mappedAddresses[to].isLPPair = true;
                    lpPairs.push(to);
                    TokenDividendTracker(dividendTracker).excludeFromDividends(to);
                } else {
                    // All good
                }
            }

        } else {
            // Only make it here if it's from or to owner, contract address, or something excluded from inflation/deflation - so inflation amt is 0 and no fork restrictions
            _flAmt = 0;
        }

        _tokenTransfer(from, to, amount, _flAmt, isSell);
    }


    function doTaxes(uint256 tokenAmount, bool useEthPair) private {
        // Reentrancy guard/stop infinite tax sells mainly
        inSwap = true;
        if(_allowances[address(this)][address(uniswapV2Router)] < tokenAmount) {
            // Our approvals run low, redo it
            _approve(address(this), address(uniswapV2Router), type(uint256).max);
        }

        uint256 sellAmt = tokenAmount;
        
        if (useEthPair) {
            address[] memory path = new address[](3);
            path[0] = address(this);
            path[1] = _wnative;
            path[2] = rewardToken;
            // Swap direct to Hex

            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                sellAmt,
                0,
                path,
                address(this),
                block.timestamp
            );
        } else {
            // Use a 3 point path to run the sells via the USDC pools
            address[] memory path = new address[](4);
            path[0] = address(this);
            // USDC
            path[1] = _usdc;
            path[2] = _wnative;
            path[3] = rewardToken;
            // Swap our tokens to WETH using the this->USDC->WETH path
            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                sellAmt,
                0,
                path,
                address(this),
                block.timestamp
            );
        }
        // This fixes gas reprice issues - reentrancy is not an issue as the fee wallets are trusted.
        // Using a uint64 prevents an edge case where these uint32's could overflow and cause failure
        // burnRatio and lp rationot here as they don't make it to ETH
        uint64 divisor = hexRewardRatio + hexStakingRatio;
        
        IERC20 hexToken = IERC20(rewardToken);
        uint256 hexAmount = hexToken.balanceOf(address(this));
        // Send them, split as required
        hexToken.transfer(stakingImpl, (hexAmount * hexStakingRatio) / divisor);
        SimpleStakingImpl(stakingImpl).afterReceivedHex();
        hexToken.transfer(dividendTracker, (hexAmount * hexRewardRatio) / divisor);
        TokenDividendTracker(dividendTracker).afterReceivedHex((hexAmount * hexRewardRatio) / divisor);
        
        inSwap = false;
    }

    receive() external payable {}

    /// @notice Sets if arb is enabled or not. Only callable by owner.
    /// @param enabled if arb is enabled or not.
    function setArbEnabled(bool enabled) external onlyOwner {
        arbEnabled = enabled;
    }

    function doLaggedBurn(bool isSell, address sender) internal {
        if(laggedBurnAmt > 0) {
            // Need to determine if last "sell" was actually a LP add, and if so, discard
            {
                // Determine which token we are in the LP
                
                IUniswapV2Pair lpPair = IUniswapV2Pair(laggedLP.lpAddr);
                
                (uint112 reserve0, uint112 reserve1,) = lpPair.getReserves();
                
                
                if(laggedLP.reserve0 < reserve0 && laggedLP.reserve1 < reserve1) {
                    // Reserve0 went up and so did reserve1 - surely the only case this can occur on is a lp add, so wipe the burn
                    if(laggedBurnAmt <= laggedLP.laggedBurnAmt) {
                        laggedBurnAmt = 0;
                    } else {
                        laggedBurnAmt -= laggedLP.laggedBurnAmt;
                    }
                    delete(laggedLP);
                    return;

                }
                
                
            }
            
            // Determine the best pool to burn from
            if(isSell) {
                
                uint8 best = 0;
                uint256 lastBal;
                for(uint8 i = 0; i < lpPairs.length; i++) {
                    // Only add pools with a balance of our tokens for burn
                    if(lpPairs[i] != sender && tokensOwned[(lpPairs[i])] > 0) {
                        
                        if(lastBal == 0) {
                            lastBal = tokensOwned[(lpPairs[i])];
                            best = i;
                        } else {
                            if(lastBal < tokensOwned[lpPairs[i]]) {
                                best = i;
                                lastBal = tokensOwned[lpPairs[i]];
                            }
                        }
                    }
                }
                // Unset laggedLP if it's set
                
                delete(laggedLP);
                if(lastBal < laggedBurnAmt) {
                    
                    // Don't burn if there's too many tokens to burn scheduled - they'll get caught up later on.
                    return;
                } else {
                    
                    _decreaseSupply(laggedBurnAmt, lpPairs[best]);
                    // Unset the lagged burn amount - no gas cost to unset and then re-set vs just re-setting, and a gas refund if it's a buy
                    laggedBurnAmt = 0; 
                }
                              
            } else {
                
                uint8 best = 0;
                uint256 lastBal;
                for(uint8 i = 0; i < lpPairs.length; i++) {
                    if(lpPairs[i] != sender && tokensOwned[(lpPairs[i])] > 0) {
                        
                        if(lastBal == 0) {
                            best = i;
                            lastBal = tokensOwned[lpPairs[i]];
                            
                        } else {
                            if(lastBal < tokensOwned[lpPairs[i]]) {
                                best = i;
                                lastBal = tokensOwned[lpPairs[i]];
                            }
                        }
                    }
                }
                
                // Unset laggedLP if it's set
                delete(laggedLP);
                if(tokensOwned[lpPairs[best]] < laggedBurnAmt) {
                    
                    // Don't burn if there's too many tokens to burn scheduled - they'll get caught up later on.
                    return;
                    
                } else {
                    _decreaseSupply(laggedBurnAmt, lpPairs[best]);
                    // Unset the lagged burn amount - no gas cost to unset and then re-set vs just re-setting, and a gas refund if it's a buy
                    laggedBurnAmt = 0;
                }
            }
        }
    }

    // Underlying transfer functions go here
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        uint32 _flAmt,
        bool isSell
    ) private {
        
        doLaggedBurn(isSell, sender);
        

        // Do the normal tax setup
        uint256 taxAmount = calculateTaxesFee(amount, _flAmt);

        if(isSell) {
            TokenDividendTracker(dividendTracker).process(gasForProcessing);
            if (taxAmount > 0) {
                // Add tokens to burn queue
                
                laggedBurnAmt += taxAmount;
                
                // Save old data to be monitored on next tx
                {
                    IUniswapV2Pair lpPair = IUniswapV2Pair(recipient);
                    (uint112 reserve0, uint112 reserve1, ) = lpPair.getReserves();
                    laggedLP = LaggedLPData(recipient, reserve0, reserve1, amount);
                }
                if(arbEnabled) {
                    internalArb(true);
                }
            }
            emit Sold(sender, amount);
        } else {
            if (taxAmount > 0) {
                // Emit tokens to us
                _increaseSupply(taxAmount);
                // Sell the tokens - work out what pool is being used as the trade pool
                address uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
                    .getPair(address(this), _wnative);
                // Work out where tokens are going to
                bool useWETH;
                if(sender == uniswapV2Pair) {
                    useWETH = false;
                } else if (recipient == uniswapV2Pair) {
                    useWETH = false;
                } else {
                    useWETH = true;
                }
                doTaxes(taxAmount, useWETH);
            }
            emit Bought(recipient, amount);
        }
        // Actually send tokens
        tokensOwned[sender] = tokensOwned[sender] - amount;
        tokensOwned[recipient] = tokensOwned[recipient] + amount;
        // Do the dividendtracking
        try TokenDividendTracker(dividendTracker).setBalance(payable(sender), tokensOwned[sender]) {} catch {}
        try TokenDividendTracker(dividendTracker).setBalance(payable(recipient), tokensOwned[recipient]) {} catch {}
        // Emit transfers, because the specs say to
        emit Transfer(sender, recipient, amount);
    }


    function internalArb(bool automatic) internal {
        address uniswapV2PairW = IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(this), _wnative);
        address uniswapV2PairU = IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(this), _usdc);
        // Determine if we should do arb - is it out of alignment 
        address[] memory path = new address[](2);
        path[0] = _usdc;
        path[1] = _wnative;
        // Get a quote for USDC pool value in WETH
        uint256[] memory quoteOut = uniswapV2Router.getAmountsOut(IERC20(_usdc).balanceOf(uniswapV2PairU), path);
        // The price of a token (without decimals), in wei, in the USDC pool
        uint256 usdcPoolTokenWeiPrice = quoteOut[1]/tokensOwned[uniswapV2PairU];
        // The price of a token (without decimals), in wei, in the WETH pool
        uint256 wethPoolTokenWeiPrice =  IERC20(_wnative).balanceOf(uniswapV2PairW)/tokensOwned[uniswapV2PairW];
        // Check if the wethPoolPrice is more than 15% above the usdcPoolPrice, or if the usdcPoolPrice is more than 15% above the wethPoolPrice
        if(!automatic || wethPoolTokenWeiPrice >= (usdcPoolTokenWeiPrice*23/20) || usdcPoolTokenWeiPrice >= (wethPoolTokenWeiPrice*23/20)) {
            // Calculate the arb to do
            (uint256 amountTokens, bool isUsdcLower) = ArbUtils.calculateArbitrage(_wnative, uniswapV2PairU, uniswapV2PairW, address(this), quoteOut[1], usdcPoolTokenWeiPrice, wethPoolTokenWeiPrice);
            if(isUsdcLower) {
                // Take tokens from the USDC pair
                // Make sure there's enough tokens to move
                if(tokensOwned[uniswapV2PairU] > amountTokens) {
                    tokensOwned[uniswapV2PairU] = tokensOwned[uniswapV2PairU] - amountTokens;
                    tokensOwned[uniswapV2PairW] = tokensOwned[uniswapV2PairW] + amountTokens;
                } else {
                    // Error condition, we shouldn't see this - but using the second x from the quadratic seems to do it.
                }
            } else {
                // Take tokens from the WETH pair
                // Make sure there's enough tokens to move
                if(tokensOwned[uniswapV2PairW] > amountTokens) {
                    tokensOwned[uniswapV2PairW] = tokensOwned[uniswapV2PairW] - amountTokens;
                    tokensOwned[uniswapV2PairU] = tokensOwned[uniswapV2PairU] + amountTokens;
                } else {
                    // Error condition, we shouldn't see this - but using the second x from the quadratic seems to do it.
                }
            }
            // Sync the pairs
            IUniswapV2Pair(uniswapV2PairU).sync();
            IUniswapV2Pair(uniswapV2PairW).sync();
            emit ArbitragedPools(amountTokens, isUsdcLower);
        }

    }




    function updateGasForProcessing(uint32 newValue) external onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "200,000 < GFP < 500,000");
        require(newValue != gasForProcessing, "Same");
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        TokenDividendTracker(dividendTracker).updateClaimWait(claimWait);
    }


    function excludeFromDividends(address account) external onlyOwner{
        TokenDividendTracker(dividendTracker).excludeFromDividends(account);
    }



    function processDividendTracker(uint256 gas) external {
        TokenDividendTracker(dividendTracker).process(gas);
    }

    function claim() external {
        TokenDividendTracker(dividendTracker).processAccount(payable(msg.sender), false);
    }


    function calculateTaxesFee(uint256 _amount, uint32 _flAmt) private pure returns (uint256 tax) { 
        tax = (_amount * _flAmt) / 100000;
    }

    
    /// @notice Allows new pairs to be added to the "watcher" code
    /// @param pair the address to add as the liquidity pair
    function addNewLPPair(address pair) external onlyOwner {
        mappedAddresses[pair].isLPPair = true;
        lpPairs.push(pair);
    }

    /// @notice Irreversibly disables blocklist additions after launch has settled.
    /// @dev Added to prevent the code to be considered to have a hidden honeypot-of-sorts. 
    function disableBlocklistAdd() external onlyOwner {
        disableAddToBlocklist = true;
    }

    function isNewLP(address acc) internal view returns (uint8) {
        /**
         * The process of a LP being created is as follows:
         * The router calls a low-level _addLiquidity function
         * This function checks if a LP pair exists and if not, creates one
         * After that, it checks the ratio and if none, sets to desired, otherwise gets optimal
         * The rest doesn't matter
         * So our transfer is called after the creation of the contract, meaning we can identify it is a contract
         * 
         */
        if(Address.isContract(acc)) {
            /**
             * The next step of identifying if this is a LP is to attempt to probe the liquidity pair for its type
             * We may not want a v3 liquidity being created, for example, and could revert the transfer
             */
            IUniswapV2Pair testPair = IUniswapV2Pair(acc);
            try testPair.getReserves() {
                return 1;
            } catch {
                // Not v2 liq
                // v3 has "fee()" request
                IUniswapV3PoolImmutables test3Pair = IUniswapV3PoolImmutables(acc);
                try test3Pair.fee() {
                    return 2;
                } catch {
                    // Unknown contract type, not v2 or v3
                    return 0;
                }
            }

        } else {
            return 0;
        }

    }
    

    /// @notice Sets an account exclusion or inclusion from fees.
    /// @param account the account to change state on
    /// @param isExcluded the boolean to set it to
    function setExcludedFromFee(address account, bool isExcluded) external onlyOwner {
        mappedAddresses[account]._isExcludedFromFee = isExcluded;
    }
    
    /// @notice Sets the buy tax, out of 100000. Only callable by owner. Max of 20000.
    /// @param amount the tax out of 100000.
    function setBuyInfl(uint32 amount) external onlyOwner {
        require(amount <= 20000, "SSH: Max 20%.");
        buyInfl = amount;
    }

    /// @notice Sets the sell tax, out of 100000. Only callable by owner. Max of 20000.
    /// @param amount the tax out of 100000.
    function setSellDefl(uint32 amount) external onlyOwner {
        require(amount <= 20000, "SSH: Max 20%.");
        sellDefl = amount;
    }

    /// @notice Sets the staking ratio. Only callable by owner.
    /// @param amount staking ratio to set
    function setStakingRatio(uint32 amount) external onlyOwner {
        hexStakingRatio = amount;
    }
    /// @notice Sets the reward ratio. Only callable by owner.
    /// @param amount rward ratio to set
    function setRewardRatio(uint32 amount) external onlyOwner {
        hexRewardRatio = amount;
    }

    /// @notice Changes bot flag. Only callable by owner. Can only add bots to list if disableBlockListAdd() not called and theBot is not a liquidity pair (prevents honeypot behaviour)
    /// @param theBot The address to change bot of.
    /// @param toSet The value to set.
    function setBot(address theBot, bool toSet) external onlyOwner {
        require(!mappedAddresses[theBot].isLPPair, "SSH: FORBIDDEN");
        if(toSet) {
            require(!disableAddToBlocklist, "SSH: DISABLED");
        }
        mappedAddresses[theBot]._bots = toSet;
    }

    /// @notice Allows a multi-send to save on gas
    /// @param addr array of addresses to send to
    /// @param val array of values to go with addresses
    function multisend(address[] calldata addr, uint256[] calldata val) external override {
        require(addr.length == val.length, "SSH: MISMATCH");
        for(uint i = 0; i < addr.length; i++) {
            // There's gas savings to be had to do this - we bypass top-level checks
            _tokenTransfer(_msgSender(), addr[i], val[i], 0, false);
        }
    }
    /// @notice Allows a multi-send to save on gas on behalf of someone - need approvals
    /// @param sender sender to use - must be approved to spend
    /// @param addrRecipients array of addresses to send to
    /// @param vals array of values to go with addresses
    function multisendFrom(address sender, address[] calldata addrRecipients, uint256[] calldata vals) external override {
        require(addrRecipients.length == vals.length, "SSH: MISMATCH");
        for(uint i = 0; i < addrRecipients.length; i++) {
            // More gas savings as we bypass top-level checks - we have to do approval subs tho
            _tokenTransfer(sender, addrRecipients[i], vals[i], 0, false);
            _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(vals[i],"ERC20: transfer amount exceeds allowance"));
        }
    }
    
    function checkBot(address bot) external view returns(bool) {
        return mappedAddresses[bot]._bots;
    }

    /// @notice Returns if an account is excluded from fees.
    /// @param account the account to check
    function isExcludedFromFee(address account) external view returns (bool) {
        return mappedAddresses[account]._isExcludedFromFee;
    }
    
    /// @dev debug code to get the LP pairs
    function getLPPairs() external view returns (address[] memory lps) {
        lps = lpPairs;
    }
    
    
    /** START OF EIP2612/EIP712 FUNCTIONS */
    // These need to be here so it can access _approve, lol

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /**
     * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     * @custom:oz-renamed-from _PERMIT_TYPEHASH
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");
        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
    /** END OF EIP2612/EIP712 FUNCTIONS */
}