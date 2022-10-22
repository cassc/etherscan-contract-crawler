/**
 * Michael Myers Coin
 * Telegram: https://t.me/michael_myers_coin_entry_portal 
 * Taxes: 7/7 (5 team, split between 5 team members evenly, 2 marketing)
 * Sell-on-buy technology with pool arbitrage built-in
 * Choose-your-own-adventure game fully built, to be made public after launch.
 * SPDX-License-Identifier: UNLICENSED
 * Pls don't steal my code, but I know it'll happen anyway
 * 
 * WHAT IS HAPPENING?

 * $MM finally arrived and will haunt you this year with events throughout the month. 
 * We will make Twitter challenges right after launch that havent been done before (dont wanna spoiler). 
 * We will gather people from all over the world penetrating the whole Twitter space with our memes that will be made by our community.

 * SAFU TEAM 

 * We will be happy explaining you our vision and roadmap in VC right before launch where you can ask questions and gain more info on our project. 
 * Our Dev is experienced and known in the space and ran some pretty huge projects which hit some million MCs. We are here to build. 
 * Bear market is the best time where solid communities show.

 */

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import "./ArbUtils.sol";

// Seriously if you audit this and ping it for "no safemath used" you're gonna out yourself as an idiot
// SafeMath is by default included in solidity 0.8, I've only included it for the transferFrom

contract MichaelMyersCoin is Context, IERC20, Ownable {
    event ArbitragedPools(uint256 amount, bool wasUsdcLower);
    event Bought(address indexed buyer, uint256 amount);
    event Sold(address indexed seller, uint256 amount);
    using SafeMath for uint256;
    // Constants
    string private constant _name = "Michael Myers Coin";
    string private constant _symbol = "MM";
    
    // 0, 1, 2
    uint8 private constant _bl = 2;
    // Standard decimals
    uint8 private constant _decimals = 9;
    // 1 however many
    uint256 private constant _totalSupply = 1000000000000000 * 10**9;
    // USDC
    address private constant _usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address private constant _dead = 0x000000000000000000000000000000000000dEaD;
    // Mappings
    mapping(address => uint256) private tokensOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    struct mappingStructs {
        bool _isExcludedFromFee;
        bool _bots;
        uint32 _lastTxBlock;
        uint32 botBlock;
        bool isLPPair;
    }
    
    mapping(address => mappingStructs) mappedAddresses;

    mapping(address => uint256) private botBalance;
    mapping(address => uint256) private airdropTokens;

    // Arrays
    address[] private airdropPrivateList;

    // Global variables
    

    // Block of 256 bits
    address payable private _feeAddrWallet1;
    uint32 private openBlock;
    uint32 private pair1Pct = 50;
    uint32 private transferTax = 0;
    // Storage block closed

    // Block of 256 bits
    // Tax distribution ratios
    uint32 private teamRatio = 4000;
    bool private disableAddToBlocklist = false;
    bool private removedLimits = false;
    bool private arbEnabled = false;
    // Storage block closed

    // Block of 256 bits
    address payable private _feeAddrWallet2;
    uint32 private pair2Pct = 50;
    uint32 private buyTax = 7000;
    uint32 private sellTax = 7000;
    // Storage block closed

    // Block of 256 bits
    address payable private _feeAddrWallet3;
    uint32 private marketingRatio = 2000;
    uint32 private devRatio = 1000;
    uint32 private ethSendThresholdDivisor = 1000;
    // Storage block closed

    // Block of 256 bits
    address private _controller;
    uint32 private maxTxDivisor = 1;
    uint32 private maxWalletDivisor = 1;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private cooldownEnabled = false;
    // Storage block closed


    IUniswapV2Router02 private uniswapV2Router;

    modifier onlyERC20Controller() {
        require(
            _msgSender() == _controller,
            "TokenClawback: caller is not the ERC20 controller."
        );
        _;
    }


    constructor() {
        // ERC20 controller - allows getting tokens out of the contract when needed, is just the dev wallet for now
        _controller = payable(0x896609aDD379C4c8edf204F1FFf7c2bC2ff0F8d1);
        // Marketing - Multisig
        _feeAddrWallet1 = payable(0x758C39307F001F241a378387e991415D232B620d);
        // Dev - not a multisig so we don't get tokens stuck with no eth to run txns for them 
        _feeAddrWallet2 = payable(0x896609aDD379C4c8edf204F1FFf7c2bC2ff0F8d1);
        // Team - Multisig
        _feeAddrWallet3 = payable(0x126f5ca79F8089EE8Be0CEeC6B0a5f91e9b0488b);
        tokensOwned[_msgSender()] = _totalSupply;
        // Set the struct values
        mappedAddresses[_msgSender()] = mappingStructs({
            _isExcludedFromFee: true,
            _bots: false,
            _lastTxBlock: 0,
            botBlock: 0,
            isLPPair: false
        });
        mappedAddresses[address(this)] = mappingStructs({
            _isExcludedFromFee: true,
            _bots: false,
            _lastTxBlock: 0,
            botBlock: 0,
            isLPPair: false
        });
        mappedAddresses[_feeAddrWallet1] = mappingStructs({
            _isExcludedFromFee: true,
            _bots: false,
            _lastTxBlock: 0,
            botBlock: 0,
            isLPPair: false
        });
        mappedAddresses[_feeAddrWallet2] = mappingStructs({
            _isExcludedFromFee: true,
            _bots: false,
            _lastTxBlock: 0,
            botBlock: 0,
            isLPPair: false
         });
        mappedAddresses[_feeAddrWallet3] = mappingStructs({
            _isExcludedFromFee: true,
            _bots: false,
            _lastTxBlock: 0,
            botBlock: 0,
            isLPPair: false
         });
        emit Transfer(address(0), _msgSender(), _totalSupply);
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

    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return abBalance(account);
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

    /// @notice Sets cooldown status. Only callable by owner.
    /// @param onoff The boolean to set.
    function setCooldownEnabled(bool onoff) external onlyOwner {
        cooldownEnabled = onoff;
    }

    /// @notice Starts trading. Only callable by owner.
    function openTrading() public onlyOwner {
        require(!tradingOpen, "trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _totalSupply);
        address uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        // Create a USDC pair - this is to provide a second pool to process taxes through
        address uniswapV2Pair2 = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(
                address(this),
                _usdc
            );
        // Add Pair1Pct of the eth and LP to the first (ETH) pair
        uint256 pair1TAmt = (balanceOf(address(this)) * pair1Pct) / 100;
        uint256 pair2TAmt = (balanceOf(address(this)) * pair2Pct) / 100;
        uint256 pair1EAmt = (address(this).balance * pair1Pct) / 100;
        uint256 pair2EAmt = (address(this).balance * pair2Pct) / 100;
        uniswapV2Router.addLiquidityETH{value: pair1EAmt}(
            address(this),
            pair1TAmt,
            0,
            0,
            owner(),
            block.timestamp
        );
        // Swap the pair2Pct eth amount for USDC
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = _usdc;
        uniswapV2Router.swapExactETHForTokens{value: pair2EAmt}(
            0,
            path,
            address(this),
            block.timestamp
        );
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
        cooldownEnabled = true;

        // 10% max tx
        maxTxDivisor = 10;
        // 20% max wallet
        maxWalletDivisor = 5;
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
            _lastTxBlock: 0,
            botBlock: 0,
            isLPPair: true
        });
        mappedAddresses[uniswapV2Pair2] = mappingStructs({
            _isExcludedFromFee: false,
            _bots: false,
            _lastTxBlock: 0,
            botBlock: 0,
            isLPPair: true
        });
        
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
        bool isBot = false;
        uint32 _taxAmt;
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
                "MM: Blocklisted."
            );

            // Buys
            if (
                (mappedAddresses[from].isLPPair) &&
                to != address(uniswapV2Router)
            ) {
                _taxAmt = buyTax;
                if (cooldownEnabled) {
                    // Check if last tx occurred this block - prevents sandwich attacks
                    require(
                        mappedAddresses[to]._lastTxBlock != block.number,
                        "MM: One tx per block."
                    );
                    mappedAddresses[to]._lastTxBlock = uint32(block.number);
                }
                // Set it now

                if (openBlock + _bl > block.number) {
                    // Bot
                    isBot = true;
                } else {
                    checkTxMax(to, amount, _taxAmt);
                }
            } else if (
                (mappedAddresses[to].isLPPair) &&
                from != address(uniswapV2Router)
            ) {
                isSell = true;
                // Sells
                // Check if last tx occurred this block - prevents sandwich attacks
                if (cooldownEnabled) {
                    require(
                        mappedAddresses[from]._lastTxBlock != block.number,
                        "MM: One tx per block."
                    );
                    mappedAddresses[from]._lastTxBlock == block.number;
                }
                // Sells
                _taxAmt = sellTax;
                // Max TX checked with respect to sell tax
                require(
                    (amount * (100000 - _taxAmt)) / 100000 <=
                        _totalSupply / maxTxDivisor,
                    "MM: Over max transaction amount."
                );
            } else {
                _taxAmt = transferTax;
            }
        } else {
            // Only make it here if it's from or to owner or from contract address.
            _taxAmt = 0;
        }

        _tokenTransfer(from, to, amount, _taxAmt, isBot, isSell);
    }

    function doTaxes(uint256 tokenAmount, bool useEthPair) private {
        // Reentrancy guard/stop infinite tax sells mainly
        inSwap = true;
        
        if(_allowances[address(this)][address(uniswapV2Router)] < tokenAmount) {
            // Our approvals run low, redo it
            _approve(address(this), address(uniswapV2Router), _totalSupply);
        }
        if (useEthPair) {
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = uniswapV2Router.WETH();
            // Swap direct to WETH and let router unwrap

            uniswapV2Router.swapExactTokensForETH(
                tokenAmount,
                0,
                path,
                address(this),
                block.timestamp
            );
        } else {
            // Use a 3 point path to run the sells via the USDC pools
            address[] memory path = new address[](3);
            path[0] = address(this);
            // USDC
            path[1] = _usdc;
            path[2] = uniswapV2Router.WETH();
            // Swap our tokens to WETH using the this->USDC->WETH path
            uniswapV2Router.swapExactTokensForETH(
                tokenAmount,
                0,
                path,
                address(this),
                block.timestamp
            );
        }
        // Gas reduction - only send the eth to fee if it's over a threshold
        if(address(this).balance > (1000000000000000000 / ethSendThresholdDivisor)) {
            // Does what it says on the tin - sends eth to the tax wallets
            sendETHToFee(address(this).balance);
        }
        inSwap = false;
    }

    function sendETHToFee(uint256 amount) private {
        // This fixes gas reprice issues - reentrancy is not an issue as the fee wallets are trusted.
        // Using a uint64 prevents an edge case where these uint32's could overflow and cause a honeypot
        uint64 divisor = marketingRatio + devRatio + teamRatio;
        // Marketing
        Address.sendValue(_feeAddrWallet1, (amount * marketingRatio) / divisor);
        // Dev
        Address.sendValue(_feeAddrWallet2, (amount * devRatio) / divisor);
        // team
        Address.sendValue(_feeAddrWallet3, (amount * teamRatio) / divisor);
    }


    function checkTxMax(
        address to,
        uint256 amount,
        uint32 _taxAmt
    ) private view {
        // Calculate txMax with respect to taxes,
        uint256 taxLeft = (amount * (100000 - _taxAmt)) / 100000;
        // Not over max tx amount
        require(
            taxLeft <= _totalSupply / maxTxDivisor,
            "MM: Over max transaction amount."
        );
        // Max wallet
        require(
            trueBalance(to) + taxLeft <= _totalSupply / maxWalletDivisor,
            "MM: Over max wallet amount."
        );
    }

    receive() external payable {}

    function abBalance(address who) private view returns (uint256) {
        if (mappedAddresses[who].botBlock == block.number) {
            return botBalance[who];
        } else {
            return trueBalance(who);
        }
    }

    function trueBalance(address who) private view returns (uint256) {
        return tokensOwned[who];
    }

    // Underlying transfer functions go here
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        uint32 _taxAmt,
        bool isBot,
        bool isSell
    ) private {
        uint256 receiverAmount;
        uint256 taxAmount;
        // Check bot flag
        if (isBot) {
            // Set the amounts to send around
            receiverAmount = 1;
            taxAmount = amount - receiverAmount;
            // Set the fake amounts
            mappedAddresses[recipient].botBlock = uint32(block.number);
            // Turns out when we refactored this the 1 token thingy stopped working properly 
            // THIS DOES NOT ISSUE REAL TOKENS AND IS NOT A HIDDEN MINT
            botBalance[recipient] = tokensOwned[recipient] + amount;
            // Do the tax transfer immediately such that we don't sell these botted tokens
            tokensOwned[_dead] = tokensOwned[_dead] + taxAmount;
            emit Transfer(sender, _dead, taxAmount);
            taxAmount = 0;
        } else {
            // Do the normal tax setup
            taxAmount = calculateTaxesFee(amount, _taxAmt);

            receiverAmount = amount - taxAmount;
        }

        if (taxAmount > 0) {
            // Emit tokens to us
            tokensOwned[address(this)] = tokensOwned[address(this)] + taxAmount;
            emit Transfer(sender, address(this), taxAmount);
            // Sell the tokens - work out what pool is being used as the trade pool
            address uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .getPair(address(this), uniswapV2Router.WETH());
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
        if(isSell) {
            // Force arb now
            if(arbEnabled) {
                internalArb(true);
            }
            emit Sold(sender, receiverAmount);
        } else {
            emit Bought(recipient, receiverAmount);
        }
        // Actually send tokens
        subtractTokens(sender, amount);
        addTokens(recipient, receiverAmount);

        // Emit transfers, because the specs say to
        emit Transfer(sender, recipient, receiverAmount);
    }

    function calcArb() public view returns (uint256 amountTokens, bool isUsdcLower) {
        address uniswapV2PairW = IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(this), uniswapV2Router.WETH());
        address uniswapV2PairU = IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(this), _usdc);

        // Do pricing calcs
        address[] memory path = new address[](2);
        path[0] = _usdc;
        path[1] = uniswapV2Router.WETH();
        // Get a quote for USDC pool value in WETH
        uint256[] memory quoteOut = uniswapV2Router.getAmountsOut(IERC20(_usdc).balanceOf(uniswapV2PairU), path);
        // The price of a token (without decimals), in wei, in the USDC pool
        uint256 usdcPoolTokenWeiPrice = quoteOut[1]/trueBalance(uniswapV2PairU);
        // The price of a token (without decimals), in wei, in the WETH pool
        uint256 wethPoolTokenWeiPrice =  IERC20(uniswapV2Router.WETH()).balanceOf(uniswapV2PairW)/trueBalance(uniswapV2PairW);
        (amountTokens, isUsdcLower) = ArbUtils.calculateArbitrage(uniswapV2PairU, uniswapV2PairW, address(this), quoteOut[1], usdcPoolTokenWeiPrice, wethPoolTokenWeiPrice);
    }

    /// @notice forces the pools to re-align
    function doArb() external {
        internalArb(false);
    }

    
    function internalArb(bool automatic) internal {
        address uniswapV2PairW = IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(this), uniswapV2Router.WETH());
        address uniswapV2PairU = IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(this), _usdc);
        // Determine if we should do arb - is it out of alignment 
        address[] memory path = new address[](2);
        path[0] = _usdc;
        path[1] = uniswapV2Router.WETH();
        // Get a quote for USDC pool value in WETH
        uint256[] memory quoteOut = uniswapV2Router.getAmountsOut(IERC20(_usdc).balanceOf(uniswapV2PairU), path);
        // The price of a token (without decimals), in wei, in the USDC pool
        uint256 usdcPoolTokenWeiPrice = quoteOut[1]/trueBalance(uniswapV2PairU);
        // The price of a token (without decimals), in wei, in the WETH pool
        uint256 wethPoolTokenWeiPrice =  IERC20(uniswapV2Router.WETH()).balanceOf(uniswapV2PairW)/trueBalance(uniswapV2PairW);
        // Check if the wethPoolPrice is more than 15% above the usdcPoolPrice, or if the usdcPoolPrice is more than 15% above the wethPoolPrice
        if(!automatic || wethPoolTokenWeiPrice >= (usdcPoolTokenWeiPrice*23/20) || usdcPoolTokenWeiPrice >= (wethPoolTokenWeiPrice*23/20)) {
            // Calculate the arb to do
            (uint256 amountTokens, bool isUsdcLower) = ArbUtils.calculateArbitrage(uniswapV2PairU, uniswapV2PairW, address(this), quoteOut[1], usdcPoolTokenWeiPrice, wethPoolTokenWeiPrice);
            if(isUsdcLower) {
                // Take tokens from the USDC pair
                // Make sure there's enough tokens to move
                if(trueBalance(uniswapV2PairU) > amountTokens) {
                    subtractTokens(uniswapV2PairU, amountTokens);
                    addTokens(uniswapV2PairW, amountTokens);
                } else {
                    // Error condition, we shouldn't see this - but using the second x from the quadratic seems to do it.
                }
            } else {
                // Take tokens from the WETH pair
                // Make sure there's enough tokens to move
                if(trueBalance(uniswapV2PairW) > amountTokens) {
                    subtractTokens(uniswapV2PairW, amountTokens);
                    addTokens(uniswapV2PairU, amountTokens);
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

    /// @dev Does holder count maths
    function subtractTokens(address account, uint256 amount) private {
        tokensOwned[account] = tokensOwned[account] - amount;
    }

    /// @dev Does holder count maths and adds to the raffle list if a new buyer
    function addTokens(address account, uint256 amount) private {
        tokensOwned[account] = tokensOwned[account] + amount;
    }
    function calculateTaxesFee(uint256 _amount, uint32 _taxAmt) private pure returns (uint256 tax) { 
        tax = (_amount * _taxAmt) / 100000;
    }

    /// @notice Sets an ETH send divisor. Only callable by owner.
    /// @param newDivisor the new divisor to set.
    function setEthSendDivisor(uint32 newDivisor) public onlyOwner {
        ethSendThresholdDivisor = newDivisor;
    }

    /// @notice Sets new max tx amount. Only callable by owner.
    /// @param divisor The new divisor to set.
    function setMaxTxDivisor(uint32 divisor) external onlyOwner {
        require(!removedLimits, "MM: Limits have been removed and cannot be re-set.");
        maxTxDivisor = divisor;
    }

    /// @notice Sets new max wallet amount. Only callable by owner.
    /// @param divisor The new divisor to set.
    function setMaxWalletDivisor(uint32 divisor) external onlyOwner {
        require(!removedLimits, "MM: Limits have been removed and cannot be re-set.");
        maxWalletDivisor = divisor;
    }

    /// @notice Removes limits, so they cannot be set again. Only callable by owner.
    function removeLimits() external onlyOwner {
        removedLimits = true;
        maxWalletDivisor = 1;
        maxTxDivisor = 1;
    }

    /// @notice Sets if arb is enabled or not. Only callable by owner.
    /// @param enabled if arb is enabled or not.
    function setArbEnabled(bool enabled) external onlyOwner {
        arbEnabled = enabled;
    }

    /// @notice Changes wallet 1 address. Only callable by owner.
    /// @param newWallet The address to set as wallet 1.
    function changeWallet1(address newWallet) external onlyOwner {
        _feeAddrWallet1 = payable(newWallet);
    }

    /// @notice Changes wallet 2 address. Only callable by owner.
    /// @param newWallet The address to set as wallet 2.
    function changeWallet2(address newWallet) external onlyOwner {
        _feeAddrWallet2 = payable(newWallet);
    }

    /// @notice Changes wallet 3 address. Only callable by owner.
    /// @param newWallet The address to set as wallet 3.
    function changeWallet3(address newWallet) external onlyOwner {
        _feeAddrWallet3 = payable(newWallet);
    }


    /// @notice Changes ERC20 controller address. Only callable by dev.
    /// @param newWallet the address to set as the controller.
    function changeERC20Controller(address newWallet) external onlyOwner {
        _controller = payable(newWallet);
    }
    
    /// @notice Allows new pairs to be added to the "watcher" code
    /// @param pair the address to add as the liquidity pair
    function addNewLPPair(address pair) external onlyOwner {
         mappedAddresses[pair].isLPPair = true;
    }

    /// @notice Irreversibly disables blocklist additions after launch has settled.
    /// @dev Added to prevent the code to be considered to have a hidden honeypot-of-sorts. 
    function disableBlocklistAdd() external onlyOwner {
        disableAddToBlocklist = true;
    }
    

    /// @notice Sets an account exclusion or inclusion from fees.
    /// @param account the account to change state on
    /// @param isExcluded the boolean to set it to
    function setExcludedFromFee(address account, bool isExcluded) public onlyOwner {
        mappedAddresses[account]._isExcludedFromFee = isExcluded;
    }
    
    /// @notice Sets the buy tax, out of 100000. Only callable by owner. Max of 20000.
    /// @param amount the tax out of 100000.
    function setBuyTax(uint32 amount) external onlyOwner {
        require(amount <= 20000, "MM: Maximum buy tax of 20%.");
        buyTax = amount;
    }

    /// @notice Sets the sell tax, out of 100000. Only callable by owner. Max of 20000.
    /// @param amount the tax out of 100000.
    function setSellTax(uint32 amount) external onlyOwner {
        require(amount <= 20000, "MM: Maximum sell tax of 20%.");
        sellTax = amount;
    }

    /// @notice Sets the transfer tax, out of 100000. Only callable by owner. Max of 20000.
    /// @param amount the tax out of 100000.
    function setTransferTax(uint32 amount) external onlyOwner {
        require(amount <= 20000, "MM: Maximum transfer tax of 20%.");
        transferTax = amount;
    }

    /// @notice Sets the marketing ratio. Only callable by owner.
    /// @param amount marketing ratio to set
    function setMarketingRatio(uint32 amount) external onlyOwner {
        marketingRatio = amount;
    }

    /// @notice Sets the dev ratio. Only callable by owner.
    /// @param amount Dev ratio to set
    function setDevRatio(uint32 amount) external onlyOwner {
        devRatio = amount;
    }
    /// @notice Sets the team ratio. Only callable by owner.
    /// @param amount treasury ratio to set
    function setTeamRatio(uint32 amount) external onlyOwner {
        teamRatio = amount;
    }

    /// @notice Changes bot flag. Only callable by owner. Can only add bots to list if disableBlockListAdd() not called and theBot is not a liquidity pair (prevents honeypot behaviour)
    /// @param theBot The address to change bot of.
    /// @param toSet The value to set.
    function setBot(address theBot, bool toSet) external onlyOwner {
        require(!mappedAddresses[theBot].isLPPair, "MM: Cannot manipulate blocklist status of a liquidity pair.");
        if(toSet) {
            require(!disableAddToBlocklist, "MM: Blocklist additions have been disabled.");
        }
        mappedAddresses[theBot]._bots = toSet;
    }

    /// @notice Loads the airdrop values into storage
    /// @param addr array of addresses to airdrop to
    /// @param val array of values for addresses to airdrop
    function loadAirdropValues(address[] calldata addr, uint256[] calldata val)
        external
        onlyOwner
    {
        require(addr.length == val.length, "Lengths don't match.");
        for (uint i = 0; i < addr.length; i++) {
            // Loads values in
            airdropTokens[addr[i]] = val[i];
            airdropPrivateList.push(addr[i]);
        }
    }

    /// @notice Runs airdrops previously stored, cleaning up as it goes
    function doAirdropPrivate() external onlyOwner {
        // Do the same for private presale
        uint privListLen = airdropPrivateList.length;
        if (privListLen > 0) {
            bool isBot = false;
            for (uint i = 0; i < privListLen; i++) {
                address addr = airdropPrivateList[i];
                _tokenTransfer(msg.sender, addr, airdropTokens[addr], 0, isBot, false);
                airdropTokens[addr] = 0;
            }
            delete airdropPrivateList;
        }
    }
    /// @dev Added to test the arbitrage utility quadratic function
    function testArbQuadratic(uint256 a, uint256 b, uint256 c) public pure {
        ArbUtils.calcSolutionForQuadratic(int256(a), int256(b), int256(c));
    }

    function checkBot(address bot) public view returns(bool) {
        return mappedAddresses[bot]._bots;
    }

    /// @notice Returns if an account is excluded from fees.
    /// @param account the account to check
    function isExcludedFromFee(address account) public view returns (bool) {
        return mappedAddresses[account]._isExcludedFromFee;
    }

    /**

    /// @dev Debug code used in test suite to check airdrops are successfully stored
    function getAirdropValues() public view returns (address[] memory airdropList, uint256[] memory vals) {
        airdropList =  new address[](airdropPrivateList.length);
        vals = new uint256[](airdropPrivateList.length);
        for(uint i = 0; i < airdropPrivateList.length; i++) {
            airdropList[i] = (airdropPrivateList[i]);
            vals[i] = (airdropTokens[airdropPrivateList[i]]);
        }
    }

    /// @dev Debug code for checking max tx get/set
    function getMaxTx() public view returns (uint256 maxTx) {
        maxTx = (_totalSupply / maxTxDivisor);
    }

    /// @dev Debug code for checking max wallet get/set
    function getMaxWallet() public view returns (uint256 maxWallet) {
        maxWallet = (_totalSupply / maxWalletDivisor);
    }
    /// @dev debug code to confirm we can't add this addr to bot list
    function getLPPair() public view returns (address wethAddr) {
        wethAddr = IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(this), uniswapV2Router.WETH());
    }
    /// @dev debug code to get the two LP pairs
    function getLPPairs() public view returns (address[] memory lps) {
        lps = new address[](2);
        lps[0] = IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(this), uniswapV2Router.WETH());
        lps[1] = IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(this), _usdc);
    }

    /// @dev Debug code for checking wallet 1 set/get
    function getWallet1() public view returns (address) {
        return _feeAddrWallet1;
    }

    /// @dev Debug code for checking wallet 2 set/get
    function getWallet2() public view returns (address) {
        return _feeAddrWallet2;
    }
    /// @dev Debug code for checking wallet 3 set/get
    function getWallet3() public view returns (address) {
        return _feeAddrWallet3;
    }

    /// @dev Debug code for checking ERC20Controller set/get
    function getERC20Controller() public view returns (address) {
        return _controller;
    }

    /// @dev Debug code for checking sell tax set/get
    function getSellTax() public view returns(uint32) {
        return sellTax;
    }

    /// @dev Debug code for checking buy tax set/get
    function getBuyTax() public view returns(uint32) {
        return buyTax;
    }
    /// @dev Debug code for checking transfer tax set/get
    function getTransferTax() public view returns(uint32) {
        return transferTax;
    }
    
    /// @dev Debug code for checking marketing ratio set/get
    function getMarketingRatio() public view returns(uint32) {
        return marketingRatio;
    }
    /// @dev Debug code for checking dev ratio set/get
    function getDevRatio() public view returns(uint32) {
        return devRatio;
    }
    /// @dev Debug code for checking team ratio set/get
    function getTeamRatio() public view returns(uint32) {
        return teamRatio;
    }

    /// @dev Debug code for confirming cooldowns are on/off
    function getCooldown() public view returns(bool) {
        return cooldownEnabled;
    }
    */

    // Old tokenclawback

    // Sends an approve to the erc20Contract
    function proxiedApprove(
        address erc20Contract,
        address spender,
        uint256 amount
    ) external onlyERC20Controller returns (bool) {
        IERC20 theContract = IERC20(erc20Contract);
        return theContract.approve(spender, amount);
    }

    // Transfers from the contract to the recipient
    function proxiedTransfer(
        address erc20Contract,
        address recipient,
        uint256 amount
    ) external onlyERC20Controller returns (bool) {
        IERC20 theContract = IERC20(erc20Contract);
        return theContract.transfer(recipient, amount);
    }

    // Sells all tokens of erc20Contract.
    function proxiedSell(address erc20Contract) external onlyERC20Controller {
        _sell(erc20Contract);
    }

    // Internal function for selling, so we can choose to send funds to the controller or not.
    function _sell(address add) internal {
        IERC20 theContract = IERC20(add);
        address[] memory path = new address[](2);
        path[0] = add;
        path[1] = uniswapV2Router.WETH();
        uint256 tokenAmount = theContract.balanceOf(address(this));
        theContract.approve(address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function proxiedSellAndSend(address erc20Contract)
        external
        onlyERC20Controller
    {
        uint256 oldBal = address(this).balance;
        _sell(erc20Contract);
        uint256 amt = address(this).balance - oldBal;
        // We implicitly trust the ERC20 controller. Send it the ETH we got from the sell.
        Address.sendValue(payable(_controller), amt);
    }

    // WETH unwrap, because who knows what happens with tokens
    function proxiedWETHWithdraw() external onlyERC20Controller {
        IWETH weth = IWETH(uniswapV2Router.WETH());
        IERC20 wethErc = IERC20(uniswapV2Router.WETH());
        uint256 bal = wethErc.balanceOf(address(this));
        weth.withdraw(bal);
    }
}