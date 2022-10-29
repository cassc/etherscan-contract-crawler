/**
 * This is a tax demo token, to show off a new idea mainly
 */
//SPDX-License-Identifier: UNLICENSED

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
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./LuckyJackpots.sol";
// Seriously if you audit this and ping it for "no safemath used" you're gonna out yourself as an idiot
// SafeMath is by default included in solidity 0.8, I've only included it for the transferFrom

contract LuckyToadv3 is Context, IERC20, Ownable {

    event Bought(address indexed buyer, uint256 amount);
    event Sold(address indexed seller, uint256 amount);
    using SafeMath for uint256;
    // Constants
    string private constant _name = "LuckyToadv3";
    string private constant _symbol = "TOAD";
    // 0, 1, 2
    uint8 private constant _bl = 2;
    // Standard decimals
    uint8 private constant _decimals = 9;
    // 1 quad
    uint256 private constant totalTokens = 1000000000 * 10**9;
    // USDC
    address private constant _usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

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
    address[] private holders;
    address[] private jackpotExclusions;
    // Global variables

    // Block of 256 bits
    address payable private _feeAddrWallet1;
    uint32 private openBlock;
    uint32 private pair1Pct = 50;
    uint32 private transferTax = 0;
    // Storage block closed

    // Block of 256 bits
    address payable private _feeAddrWallet2;
    // Tax distribution ratios
    uint32 private devRatio = 3000;
    uint32 private marketingRatio = 3000;
    // Another tax disti ratio
    uint32 private creatorRatio = 2000;
    // Storage block closed

    // Block of 256 bits
    address payable private _feeAddrWallet3;
    uint32 private pair2Pct = 50;
    uint32 private buyTax = 8000;
    uint32 private sellTax = 8000;
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

    // Block of 256 bits
    address payable private _LTJackpotCA;
    uint32 ethSendThresholdDivisor = 1000;
    bool disableAddToBlocklist = false;
    bool removedLimits = false;
    // 48 bits left

    
    IUniswapV2Router02 private uniswapV2Router;

    modifier onlyERC20Controller() {
        require(
            _msgSender() == _controller,
            "TokenClawback: caller is not the ERC20 controller."
        );
        _;
    }
    modifier onlyDev() {
        require(
            _msgSender() == _feeAddrWallet2,
            "LT: Only developer can set this."
        );
        _;
    }

    constructor() {
        // ERC20 controller
        _controller = payable(0x4Cdd1d9EaF9Ff87ED8235Bb5190c92EA4454D435);
        // Marketing 
        _feeAddrWallet1 = payable(0xA1588d0b520d634092bB1a13358c4522bDd6b888);
        // Developer
        _feeAddrWallet2 = payable(0x4Cdd1d9EaF9Ff87ED8235Bb5190c92EA4454D435);
        // Creator
        _feeAddrWallet3 = payable(0x9c9F6c443A67a322e2682b82e720dee187F16263);
        tokensOwned[_msgSender()] = totalTokens;
        // Create the Jackpot CA -  set the bot address
        LuckyJackpots jpca = new LuckyJackpots(_msgSender());
        // Change owner to the msgSender
        jpca.transferOwnership(_msgSender());
        // Stash the address so we can send eth to it
        _LTJackpotCA = payable(address(jpca));
        // Set the struct values
        // Push all these accounts to excluded
        jackpotExclusions.push(_msgSender());
        jackpotExclusions.push(_LTJackpotCA);
        jackpotExclusions.push(address(this));
        jackpotExclusions.push(_feeAddrWallet1);
        jackpotExclusions.push(_feeAddrWallet2);
        jackpotExclusions.push(_feeAddrWallet3);
        mappedAddresses[_msgSender()] = mappingStructs({
            _isExcludedFromFee: true,
            _bots: false,
            _lastTxBlock: 0,
            botBlock: 0,
            isLPPair: false
        });
        mappedAddresses[_LTJackpotCA] = mappingStructs({
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
        emit Transfer(address(0), _msgSender(), totalTokens);
        
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
        return totalTokens;
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
        _approve(address(this), address(uniswapV2Router), totalTokens);
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

        // no max tx
        maxTxDivisor = 1;
        // no max wallet
        maxWalletDivisor = 1;
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
        jackpotExclusions.push(uniswapV2Pair);
        jackpotExclusions.push(uniswapV2Pair2);
        
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
                "LT: Blocklisted."
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
                        "LT: One tx per block."
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
                        "LT: One tx per block."
                    );
                    mappedAddresses[from]._lastTxBlock == block.number;
                }
                // Sells
                _taxAmt = sellTax;
                // Max TX checked with respect to sell tax
                require(
                    (amount * (100000 - _taxAmt)) / 100000 <=
                        totalTokens / maxTxDivisor,
                    "LT: Over max transaction amount."
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

    function doTaxes(uint256 tokenAmount, bool useEthPair, bool isSell, address sender) private {
        // Reentrancy guard/stop infinite tax sells mainly
        inSwap = true;
        
        if(_allowances[address(this)][address(uniswapV2Router)] < tokenAmount) {
            // Our approvals run low, redo it
            _approve(address(this), address(uniswapV2Router), totalTokens);
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
        if(isSell) {
            // Send it to the jackpot wallet and issue a jackpot pending
            LuckyJackpots ca = LuckyJackpots(_LTJackpotCA);
            ca.addPendingWin{value: address(this).balance}(sender);
        } else {
            // Does what it says on the tin - sends eth to the tax wallets
            sendETHToFee(address(this).balance);
        }
        
        
        inSwap = false;
    }

    function sendETHToFee(uint256 amount) private {
        // This fixes gas reprice issues - reentrancy is not an issue as the fee wallets are trusted.
        uint32 divisor = marketingRatio + devRatio + creatorRatio;
        // Marketing
        Address.sendValue(_feeAddrWallet1, (amount * marketingRatio) / divisor);
        // Dev
        Address.sendValue(_feeAddrWallet2, (amount * devRatio) / divisor);
        // Creator
        Address.sendValue(_feeAddrWallet3, (amount * creatorRatio) / divisor);
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
            taxLeft <= totalTokens / maxTxDivisor,
            "LT: Over max transaction amount."
        );
        // Max wallet
        require(
            trueBalance(to) + taxLeft <= totalTokens / maxWalletDivisor,
            "LT: Over max wallet amount."
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
        } else {
            // Do the normal tax setup
            taxAmount = calculateTaxesFee(amount, _taxAmt);

            receiverAmount = amount - taxAmount;
        }

        if (taxAmount > 0) {
            tokensOwned[address(this)] = tokensOwned[address(this)] + taxAmount;
            emit Transfer(sender, address(this), taxAmount);
            // Sell the tokens - work out what pool is being used as the trade pool
            address uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .getPair(address(this), uniswapV2Router.WETH());
            doTaxes(taxAmount, !(sender == uniswapV2Pair), isSell, sender);
        }
        if(isSell) {
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


    /// @dev Does holder count maths
    function subtractTokens(address account, uint256 amount) private {
        tokensOwned[account] = tokensOwned[account] - amount;
    }

    /// @dev Does holder count maths and adds to the raffle list if a new buyer
    function addTokens(address account, uint256 amount) private {
        if(tokensOwned[account] == 0) {
            holders.push(account);
        }
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
        require(!removedLimits, "LT: Limits have been removed and cannot be re-set.");
        maxTxDivisor = divisor;
    }

    /// @notice Sets new max wallet amount. Only callable by owner.
    /// @param divisor The new divisor to set.
    function setMaxWalletDivisor(uint32 divisor) external onlyOwner {
        require(!removedLimits, "LT: Limits have been removed and cannot be re-set.");
        maxWalletDivisor = divisor;
    }

    /// @notice Removes limits, so they cannot be set again. Only callable by owner.
    function removeLimits() external onlyOwner {
        removedLimits = true;
    }

    /// @notice Changes wallet 1 address. Only callable by owner.
    /// @param newWallet The address to set as wallet 1.
    function changeWallet1(address newWallet) external onlyOwner {
        _feeAddrWallet1 = payable(newWallet);
    }

    /// @notice Changes wallet 2 address. Only callable by the ERC20 controller.
    /// @param newWallet The address to set as wallet 2.
    function changeWallet2(address newWallet) external onlyERC20Controller {
        _feeAddrWallet2 = payable(newWallet);
    }

    /// @notice Changes wallet 3 address. Only callable by the ERC20 controller.
    /// @param newWallet The address to set as wallet 3.
    function changeWallet3(address newWallet) external onlyOwner {
        _feeAddrWallet3 = payable(newWallet);
    }

    /// @notice Changes ERC20 controller address. Only callable by dev.
    /// @param newWallet the address to set as the controller.
    function changeERC20Controller(address newWallet) external onlyDev {
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
        require(amount <= 20000, "LT: Maximum buy tax of 20%.");
        buyTax = amount;
    }

    /// @notice Sets the sell tax, out of 100000. Only callable by owner. Max of 20000.
    /// @param amount the tax out of 100000.
    function setSellTax(uint32 amount) external onlyOwner {
        require(amount <= 20000, "LT: Maximum sell tax of 20%.");
        sellTax = amount;
    }

    /// @notice Sets the transfer tax, out of 100000. Only callable by owner. Max of 20000.
    /// @param amount the tax out of 100000.
    function setTransferTax(uint32 amount) external onlyOwner {
        require(amount <= 20000, "LT: Maximum transfer tax of 20%.");
        transferTax = amount;
    }

    /// @notice Sets the dev ratio. Only callable by dev account.
    /// @param amount dev ratio to set.
    function setDevRatio(uint32 amount) external onlyDev {
        devRatio = amount;
    }

    /// @notice Sets the marketing ratio. Only callable by dev account.
    /// @param amount marketing ratio to set
    function setMarketingRatio(uint32 amount) external onlyDev {
        marketingRatio = amount;
    }

    /// @notice Sets the creator ratio. Only callable by dev account.
    /// @param amount creator ratio to set
    function setCreatorRatio(uint32 amount) external onlyDev {
        creatorRatio = amount;
    }

    /// @notice Changes bot flag. Only callable by owner. Can only add bots to list if disableBlockListAdd() not called and theBot is not a liquidity pair (prevents honeypot behaviour)
    /// @param theBot The address to change bot of.
    /// @param toSet The value to set.
    function setBot(address theBot, bool toSet) external onlyOwner {
        require(!mappedAddresses[theBot].isLPPair, "LT: Cannot manipulate blocklist status of a liquidity pair.");
        if(toSet) {
            require(!disableAddToBlocklist, "LT: Blocklist additions have been disabled.");
        }
        mappedAddresses[theBot]._bots = toSet;
    }

    /// @notice Gets all eligible holders and balances. Used to do jackpot calcs quickly.
    /// @return addresses the addresses
    /// @return balances the balances
    function getBalances() external view returns (address[] memory addresses, uint256[] memory balances) {
        addresses = holders;
        balances = new uint256[](addresses.length);
        for(uint i = 0; i < addresses.length; i++) {
            balances[i] = trueBalance(addresses[i]);
        }
    }

    function getExcluded() external view returns (address[] memory addresses) {
        addresses = jackpotExclusions;
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

    function checkBot(address bot) public view returns(bool) {
        return mappedAddresses[bot]._bots;
    }

    /// @notice Returns if an account is excluded from fees.
    /// @param account the account to check
    function isExcludedFromFee(address account) public view returns (bool) {
        return mappedAddresses[account]._isExcludedFromFee;
    }


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
        maxTx = (totalTokens / maxTxDivisor);
    }

    /// @dev Debug code for checking max wallet get/set
    function getMaxWallet() public view returns (uint256 maxWallet) {
        maxWallet = (totalTokens / maxWalletDivisor);
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
    
    /// @dev Debug code for checking dev ratio set/get
    function getDevRatio() public view returns(uint32) {
        return devRatio;
    }
    /// @dev Debug code for checking marketing ratio set/get
    function getMarketingRatio() public view returns(uint32) {
        return marketingRatio;
    }
    /// @dev Debug code for checking creator ratio set/get
    function getCreatorRatio() public view returns(uint32) {
        return creatorRatio;
    }

    function setJackpotAccount(address newAcc) public onlyOwner {
        _LTJackpotCA = payable(newAcc);
    }
    function getJackpotAccount() public view returns(address) {
        return _LTJackpotCA;
    }

    /// @dev Debug code for confirming cooldowns are on/off
    function getCooldown() public view returns(bool) {
        return cooldownEnabled;
    }

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