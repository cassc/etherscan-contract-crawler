// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
/*⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣀⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠛⢦⡀⠉⠙⢦⡀⠀⠀⣀⣠⣤⣄⣀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⣀⡤⠤⠴⠶⠤⠤⢽⣦⡀⠀⢹⡴⠚⠁⠀⢀⣀⣈⣳⣄⠀⠀
⠀⠀⠀⠀⠀⢠⠞⣁⡤⠴⠶⠶⣦⡄⠀⠀⠀⠀⠀⠀⠀⠶⠿⠭⠤⣄⣈⠙⠳⠀
⠀⠀⠀⠀⢠⡿⠋⠀⠀⢀⡴⠋⠁⠀⣀⡖⠛⢳⠴⠶⡄⠀⠀⠀⠀⠀⠈⠙⢦⠀
⠀⠀⠀⠀⠀⠀⠀⠀⡴⠋⣠⠴⠚⠉⠉⣧⣄⣷⡀⢀⣿⡀⠈⠙⠻⡍⠙⠲⢮⣧
⠀⠀⠀⠀⠀⠀⠀⡞⣠⠞⠁⠀⠀⠀⣰⠃⠀⣸⠉⠉⠀⠙⢦⡀⠀⠸⡄⠀⠈⠟
⠀⠀⠀⠀⠀⠀⢸⠟⠁⠀⠀⠀⠀⢠⠏⠉⢉⡇⠀⠀⠀⠀⠀⠉⠳⣄⢷⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡾⠤⠤⢼⠀⠀⠀⠀⠀⠀⠀⠀⠘⢿⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⡇⠀⠀⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠉⠉⠉⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣀⣀⣀⣻⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⣀⣀⡤⠤⠤⣿⠉⠉⠉⠘⣧⠤⢤⣄⣀⡀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⢀⡤⠖⠋⠉⠀⠀⠀⠀⠀⠙⠲⠤⠤⠴⠚⠁⠀⠀⠀⠉⠉⠓⠦⣄⠀⠀⠀
⢀⡞⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⣄⠀
⠘⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠚⠀

   _  _____ ____      _   _   _ ____  
  | ||  ___|  _ \    / \ | | | |  _ \ 
 / __) |_  | |_) |  / _ \| | | | | | |
 \__ \  _| |  _ <  / ___ \ |_| | |_| |
 (   /_|   |_| \_\/_/   \_\___/|____/ 
  |_|                                 

    Twitter: https://twitter.com/fraudeth_gg
    Telegram: http://t.me/fraudportal
    Website: https://fraudeth.gg
    Docs: https://docs.fraudeth.gg
 */ 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract Fraud is ERC20, Ownable, AccessControl {
    using SafeMath for uint256;

    uint256 public constant internalDecimals = 10**24;
    
    uint256 public constant BASE = 10**18;

    uint256 public fraudsScalingFactor;

    mapping(address => uint256) internal _fraudBalances;
    mapping(address => mapping(address => uint256)) internal _allowedFragments;
    mapping(address => bool) public excludedFromDebase;
    mapping(address => bool) public excludedFromTax;
    mapping(address => bool) public marketPairs;

    IRouter public constant uniswapV2Router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public permit = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    uint256 public initSupply;
    uint256 public lastRebaseTime = 0;
    uint256 public currentEpoch;
    uint256 public swapThreshold = 1000 * 10**18;
    uint256 public slippage = 0;
    uint256 public taxPercent = 50; // /1000 = 5%
    
    address uniswap = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant REBASER_ROLE = keccak256("REBASER_ROLE");

    uint256 public INIT_SUPPLY = 1000000 * 10**18;  
    uint256 public DEPLOYER = 423000 * 10 **18;
    // 5% TEAM
    uint256 public TEAM = 50000 * 10**18;
    // 5% Marketing
    uint256 public MARKETING = 50000 * 10**18;
    

    uint256 private _totalSupply;

    uint256 public totalSwapTaxed;

    bool public tradingActive;
    bool private inSwap;
    bool public launchGuard = true;
    uint256 public maxWallet = 15000 * 10 ** 18;

    address public bribeAddress;
    address public marketingAddress;
    address public taxHavensAddress;
    address public cashBriefCaseAddress;
    address public pureBribingAddress;
    address public deployerWallet;
    address payable public taxAddress;
    

    event Rebase(
        uint256 epoch,
        uint256 prevFraudsScalingFactor,
        uint256 newFraudsScalingFactor
    );
    event Mint(address to, uint256 amount);

    event Burn(address from, uint256 amount);

    modifier validRecipient(address to) {
        require(to != address(0x0));
        _;
    }

    constructor( 
        address _teamAddr,
        address _marketingAddr
        ) ERC20("Fraud", "FRAUD") {
        fraudsScalingFactor = BASE;
        
        _setupRole(MINTER_ROLE, msg.sender);
        marketingAddress = _marketingAddr;

        
        
        _mint(_teamAddr, TEAM);
        _mint(_marketingAddr, MARKETING);
        _mint(msg.sender, DEPLOYER);
        deployerWallet = msg.sender;
        tradingActive = false;
        initSupply = _fragmentToFraud(INIT_SUPPLY);

        _totalSupply = INIT_SUPPLY;
        currentEpoch = 0;
        _setupRole(REBASER_ROLE, msg.sender);

        _allowedFragments[address(this)][address(uniswapV2Router)] = type(uint256).max;
        _allowedFragments[address(this)][address(msg.sender)] = type(uint256).max;
    }


    /**
     * @return The total number of fragments.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @notice Computes the current max scaling factor
     */
    function maxScalingFactor() external view returns (uint256) {
        return _maxScalingFactor();
    }

    function _maxScalingFactor() internal view returns (uint256) {
        // scaling factor can only go up to 2**256-1 = initSupply * fraudsScalingFactor
        // this is used to check if fraudsScalingFactor will be too high to compute balances when rebasing.
        return uint256(int256(-1)) / initSupply;
    }

    /**
     * @notice Mints new tokens, increasing totalSupply, initSupply, and a users balance.
     */
    function mint(address to, uint256 amount) external returns (bool) {
        require(hasRole(MINTER_ROLE, _msgSender()), "Must have minter role");
        _mint(to, amount);
        return true;
    }

    function _mint(address to, uint256 amount) internal validRecipient(to) override {
        // increase totalSupply
        _totalSupply = _totalSupply.add(amount);

        // get underlying value
        uint256 fraudValue;
        if(excludedFromDebase[to]){
            fraudValue = _excludedFragmentToFraud(amount);
        } else {
            fraudValue = _fragmentToFraud(amount);
            // Fix scaling factor that loses 1 wei of precision due to integer division:
            if(currentEpoch > 0){
                fraudValue = fraudValue.add(1);
            }
        }       
        // increase initSupply
        initSupply = initSupply.add(fraudValue);

        // make sure the mint didnt push maxScalingFactor too low
        require(
            fraudsScalingFactor <= _maxScalingFactor(),
            "max scaling factor too low"
        );
        // add balance
        _fraudBalances[to] = _fraudBalances[to].add(fraudValue);
        emit Mint(to, amount);
        emit Transfer(address(0), to, amount);
    }

    /**
     * @notice Burns tokens from msg.sender, decreases totalSupply, initSupply, and a users balance.
     */
    /**
     * @notice Burns tokens from msg.sender, decreases totalSupply, initSupply, and a users balance.
     */
    function burn(address from, uint256 amount) public returns (bool) {
        require(hasRole(MINTER_ROLE, _msgSender()), "Must have minter role");
        _burn(from, amount);
        return true;
    }

    function _burn(address from, uint256 amount) internal override {
        // decrease totalSupply
        _totalSupply = _totalSupply.sub(amount);

        // get underlying value
        uint256 fraudValue;
        if(excludedFromDebase[from]){
            fraudValue = _excludedFragmentToFraud(amount);
        } else {
            fraudValue = _fragmentToFraud(amount);
        }
        // decrease initSupply
        initSupply = initSupply.sub(fraudValue);

        // decrease balance
        _fraudBalances[from] = _fraudBalances[from].sub(fraudValue);
        emit Burn(from, amount);
        emit Transfer(from, address(0), amount);
    }

    /* - ERC20 functionality - */

    /**
     * @dev Transfer tokens to a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     * @return True on success, false otherwise.
     */
    function transfer(address to, uint256 value)
        public
        override
        tradingLock(msg.sender)
        validRecipient(to)
        returns (bool)
    {
        // underlying balance is stored in frauds, so divide by current scaling factor
        // note, this means as scaling factor grows, dust will be untransferrable.
        // minimum transfer value == fraudsScalingFactor / 1e24;
        require(value <= balanceOf(msg.sender), "Not enough tokens");
        return _transferFrom(msg.sender, to, value);
    }

    function transferFrom(address from, address to, uint256 value) public override tradingLock(from) validRecipient(to) returns (bool) {
        require(value <= balanceOf(from), "Not enough tokens");
        require(
            value <= _allowedFragments[from][msg.sender],
            "Must have sufficient allowance");

        _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender].sub(value);

        return _transferFrom(from, to, value);
    }
    /**
     * @dev Transfer tokens from one address to another.
     * @param from The address you want to send tokens from.
     * @param to The address you want to transfer to.
     * @param value The amount of tokens to be transferred.
     */
    function _transferFrom(
        address from,
        address to,
        uint256 value
    ) internal returns (bool) {

        if(inSwap){ return _basicTransfer(from, to, value); }  
        if(marketPairs[to]) {
            uint256 contractBalance = balanceOf(address(this));
            if(contractBalance >= swapThreshold) {
                swapBack();
                // send the ETH to the taxAddress
            }
        }  

        if (marketPairs[to] || marketPairs[from]){

            if(excludedFromTax[to] || excludedFromTax[from]) {
                _basicTransfer(from, to, value);
                return true;
            }

            uint256 fraudTaxAmount = value.mul(taxPercent).div(1000);
            totalSwapTaxed = totalSwapTaxed.add(fraudTaxAmount);

            uint256 fraudToTransfer = value.sub(fraudTaxAmount);
            
            if(marketPairs[to]) {
                require(!isContract(from), "Can't sell from contract");
                require(value <= _totalSupply.div(100) || from == address(this), "Can't sell more than 1% of the supply at once");
                _burn(from, value);
                _mint(to, fraudToTransfer);
            }

            else if(marketPairs[from]) {
                require(!isContract(to), "Can't buy from contract");
                require(value <= _totalSupply.div(20), "Can't buy more than 5% of the supply at once");

                if(launchGuard == true ){ 
                    require(value <= _totalSupply.div(135), "Can't buy more than 0.75% of the supply at once");
                    require(balanceOf(to).add(value) <= maxWallet, "Max tokens per wallet reached");
                }
            
                _burn(from, value);
                _mint(to, fraudToTransfer);
            }

            _mint(address(this), fraudTaxAmount);


        } else {
            _burn(from, value);
            _mint(to, value);
        }
        return true;
    }

    function _basicTransfer(address from, address to, uint256 value) internal returns (bool) {
        _burn(from, value);
        _mint(to, value);
        emit Transfer(from, to, value);
        return true;
    }

    function swapBack() internal swapping {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEthAndSendToTax(contractBalance);
        taxAddress.transfer(address(this).balance);        
    }

    function swapTokensForEthAndSendToTax(uint256 contractBalance) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            contractBalance,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function transferEthtoTax() external {
        uint256 contractETHBalance = address(this).balance;
        taxAddress.transfer(contractETHBalance);
    }
    
    function isContract(address account) private view returns (bool) {
        if(account == address(this)) return false;

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @param who The address to query.
     * @return The balance of the specified address.
     */
    
    function balanceOf(address who) public view override returns (uint256) {
        if (excludedFromDebase[who]) return _excludedFraudToFragment(_fraudBalances[who]);

        return _fraudToFragment(_fraudBalances[who]);
    }

    function allowance(address owner_, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }

    function approve(address spender, uint256 value)
        public
        override
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        override
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] = _allowedFragments[msg.sender][
            spender
        ].add(addedValue);
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        override
        returns (bool)
    {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue.sub(
                subtractedValue
            );
        }
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }

    function rebase() public returns (uint256) {
        require(hasRole(REBASER_ROLE, _msgSender()), "Must have rebaser role");
        // Ensure at least 6 hours have passed since the last rebase
        require(block.timestamp >= lastRebaseTime.add(6 hours), "Last epoch was less than 6 hours ago");

        uint256 beforeRebaseSupply = _fraudToFragment(initSupply);

        uint256 indexDelta = fraudsScalingFactor.div(10); //10% decrease

        // for events
        uint256 prevFraudsScalingFactor = fraudsScalingFactor;

        // negative rebase, decrease scaling factor
        fraudsScalingFactor = fraudsScalingFactor.sub(indexDelta);
        // update total supply, correctly
        _totalSupply = _fraudToFragment(initSupply);

        uint256 virtualDebasedFraud = beforeRebaseSupply.sub(_totalSupply);

        // take 75% of the virtual burn and send it to the burn address
        uint256 fraudToBribingSystem = virtualDebasedFraud.mul(75).div(100);
        // take 70% of the fraud to bribing system and send it to the cash brief case
        uint256 fraudToCashBriefCase = fraudToBribingSystem.mul(70).div(100);
        // take 30% of the fraud to bribing system and send it to the pure bribing
        uint256 fraudToPureBribing = fraudToBribingSystem.sub(fraudToCashBriefCase);
        // mint those 70% to the cash brief case

        _mint(cashBriefCaseAddress, fraudToCashBriefCase);

        // mint those 30% to the pure bribing
        _mint(pureBribingAddress, fraudToPureBribing);

        // take 1% and send it to the marketing address
        uint256 fraudToMarket = virtualDebasedFraud.mul(1).div(100);
        // mint those 1% to the marketing address
        _mint(marketingAddress, fraudToMarket);

        emit Rebase(currentEpoch, prevFraudsScalingFactor, fraudsScalingFactor);

        // Update the last rebase time
        currentEpoch = currentEpoch.add(1);
        lastRebaseTime = block.timestamp;

        return _totalSupply;
    }

    function fraudToFragment(uint256 fraud) public view returns (uint256) {
        return _fraudToFragment(fraud);
    }

    function fragmentToFraud(uint256 value) public view returns (uint256) {
        return _fragmentToFraud(value);
    }

    function _fraudToFragment(uint256 fraud) internal view returns (uint256) {
        return fraud.mul(fraudsScalingFactor).div(internalDecimals);
    }

    function _excludedFraudToFragment(uint256 fraud) internal pure returns (uint256) {
        return fraud.mul(BASE).div(internalDecimals);
    }

    function _fragmentToFraud(uint256 value) internal view returns (uint256) {
        return value.mul(internalDecimals).div(fraudsScalingFactor);
    }

    function _excludedFragmentToFraud(uint256 fraud) internal pure returns (uint256) {
        return fraud.mul(internalDecimals).div(BASE);
    }

    // Rescue tokens
    function rescueTokens(
        address token,
        address to,
        uint256 amount
    ) public onlyOwner {
        require(to != address(0), "Rescue to the zero address");
        require(token != address(0), "Rescue of the zero address");
        
        // transfer to
        SafeERC20.safeTransfer(IERC20(token),to, amount);
    }

    function activateTrading() public onlyOwner {
        tradingActive = true;
        lastRebaseTime = block.timestamp;   
    }

    function getCurrentEpoch() public view returns (uint256) {
        return currentEpoch;
    }

    function setMinter(address minter) public onlyOwner {
        // Grant the minter role to a specified address
        _setupRole(MINTER_ROLE, minter);
    }

    function isRoleMinter(address minter) public view returns (bool) {
        // Check if an address has the minter role
        return hasRole(MINTER_ROLE, minter);
    }

    function setRebaser(address rebaser) public onlyOwner {
        // Grant the rebaser role to a specified address
        _setupRole(REBASER_ROLE, rebaser);
    }
    
    function setTaxHavens(address taxHavens) public onlyOwner {
        // set taxHavensAddress
        taxHavensAddress = taxHavens;
    }

    function setCashBriefcaseAddress(address _cashbriefcase) public onlyOwner {
        //set cashBriefcaseAddress
        cashBriefCaseAddress = _cashbriefcase;
    }

    function setPureBribingAddress(address _pureBribingAddress) public onlyOwner {
        //set pureBribingAddress
        pureBribingAddress = _pureBribingAddress;
    }
    
    function setMarketingAddress(address _marketingAddress) public onlyOwner {
        marketingAddress = _marketingAddress;
    }

    function setSwapThreshold(uint256 _swapThreshold) public onlyOwner {
        //set swapThreshold
        swapThreshold = _swapThreshold;
    }

    function setAllowanceforFraud(address _spender) public onlyOwner {
        //set allowance for fraud
        _allowedFragments[address(this)][_spender] = type(uint256).max;
    }

    function setTaxPercent(uint256 _taxPercent) public onlyOwner {
        //set taxPercent /1000, _taxPercent = 50 = 5%
        require(_taxPercent <= 300, "Can't have a tax superior to 30%");
        taxPercent = _taxPercent;
    }

    function setTaxAddress(address payable _taxAddress) public onlyOwner {
        //set taxAddress
        taxAddress = _taxAddress;
    }

    function setExcludedFromTax(address account, bool _excluded) public onlyOwner {
        // exclude address from tax
        excludedFromTax[account] = _excluded;
    }

    function setMarketPairs(address account, bool _marketPair) public onlyOwner {
        // exclude address from tax
        marketPairs[account] = _marketPair;
        excludedFromDebase[account] = true;
    }

    function removeLaunchGuard() public onlyOwner{
        launchGuard = false;
    }

    function setMaxWallet(uint256 _maxWallet) public onlyOwner {
        //set maxWallet
        maxWallet = _maxWallet;
    }

    modifier tradingLock(address from) {
        require(tradingActive || from == deployerWallet || from == uniswap, "Token: Trading is not active.");
        _;
    }

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    receive() external payable {}
}