//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**

             \     /
             \\   //
              )\-/(
              /e e\
             ( =Y= )
             /`-!-'\
        ____/ /___\ \
   \   /    ```    ```~~"--.,_
`-._\ /                       `~~"--.,_
----->|                                `~~"--.,_
_.-'/ \                                         ~~"--.,_
   /   \_________________________,,,,....----""""~~~~````


     88     888    d8P         d8888 8888888b.  8888888b.   .d88888b. 88888888888 
 .d88888b.  888   d8P         d88888 888   Y88b 888   Y88b d88P" "Y88b    888     
d88P 88"88b 888  d8P         d88P888 888    888 888    888 888     888    888     
Y88b.88     888d88K         d88P 888 888   d88P 888   d88P 888     888    888     
 "Y88888b.  8888888b       d88P  888 8888888P"  8888888P"  888     888    888     
     88"88b 888  Y88b     d88P   888 888 T88b   888 T88b   888     888    888     
Y88b 88.88P 888   Y88b   d8888888888 888  T88b  888  T88b  Y88b. .d88P    888     
 "Y88888P"  888    Y88b d88P     888 888   T88b 888   T88b  "Y88888P"     888 ETH Edition
     88                                                                           
                                                                                  
    https://twitter.com/Karrot_gg                                                                    
 */

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/IConfig.sol";
import "./interfaces/IKarrotChef.sol";
import "./interfaces/IDexInterfacer.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IStolenPool.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


/**
 * Karrots: Rabbits seem to love these tokens can't stop trying to steal them from our users...
 */

contract Karrots is Context, AccessControlEnumerable, ERC20Burnable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant REBASER_ROLE = keccak256("REBASER_ROLE");

    uint256 public constant PERCENTAGE_DENOMINATOR = 10000;
    uint256 public constant KARROTS_DECIMALS = 1e18;
    uint256 public constant KARROTS_INTERNAL_DECIMALS = 1e24;

    /**
     * @notice 3,324,324,324,357 is total supply
     * LP (40%) = 1,329,729,729,743
     * Presale (35%) = 1_163_513_513_525
     * Airdrop (20%) = 664,864,864,871
     * Team (5%) = 166,216,216,218 (Will be minted via constructor args)
     */
    uint256 public constant KARROTS_LP_SUPPLY =  1_329_729_729_743 * KARROTS_DECIMALS;
    uint256 public constant KARROTS_PRESALE_SUPPLY =  1_163_513_513_525 * KARROTS_DECIMALS;
    uint256 public constant KARROTS_AIRDROP_SUPPLY =  664_864_864_871 * KARROTS_DECIMALS;

    IConfig public config;

    address public outputAddress;

    bool private isInitialized;
    bool public tradingIsOpen;
    bool private inSwap;

    uint16 public sellTaxRate = 3000; //will decrease to 1buy/2sell in 5% increments every 10ish seconds
    uint16 public buyTaxRate = 3000;
    uint16 public maxScaleFactorDecreasePercentagePerDebase = 1200; //1200/10000 = 12%
    uint64 public karrotsScalingFactor;
    uint160 public _totalFragmentSupply;

    uint256 public divertTaxToStolenPoolRate = 100; //1% of buy/sell tax goes to stolen pool
    uint256 public taxSwapAmountThreshold = 500000000 * KARROTS_DECIMALS; //0.5B tokens accumulated in-contract before swap to ETH to treasury
    uint256 public maxScaleFactorAdjust = 10; //just if needed to control max scale factor. adding as margin of error.

    address[] public swapPath = new address[](2); 

    mapping(address => uint256) internal _karrotsBalances;
    mapping(address => mapping(address => uint256)) internal _allowedFragments;
    mapping(address => uint256) public nonces;
    mapping(address => bool) public isDexAddress;
    
    event Rebase(uint256 epoch, uint256 prevKarrotsScalingFactor, uint256 newKarrotsScalingFactor);
    event Mint(address to, uint256 amount);
    event Burn(address from, uint256 amount);

    error ForwardFailed();
    error CallerIsNotConfig();
    error TradingIsNotOpen();
    error MaxScalingFactorTooLow();
    error InvalidRecipient();
    error MustHaveMinterRole();
    error MustHaveRebaserRole();
    error NotEnoughBalance();
    error OutputAddressNotSet();
    error CallerIsNotStolenPool();
    error ZeroAddressNotAllowed();

    constructor(
        address _configManagerAddress, 
        address[] memory teamMemberAddresses, 
        uint256[] memory teamMemberTokenAmounts,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(REBASER_ROLE, _msgSender());
        
        config = IConfig(_configManagerAddress);
        karrotsScalingFactor = uint64(KARROTS_DECIMALS);
        swapPath[0] = address(this); 
        swapPath[1] = IUniswapV2Router02(config.uniswapRouterAddress()).WETH();
        outputAddress = config.treasuryAddress();

        _mint(config.dexInterfacerAddress(), KARROTS_LP_SUPPLY);
        _mint(config.presaleDistributorAddress(), KARROTS_PRESALE_SUPPLY);
        _mint(config.airdropDistributorAddress(), KARROTS_AIRDROP_SUPPLY);
        
        for(uint256 i = 0; i < teamMemberAddresses.length; i++) {
            _mint(teamMemberAddresses[i], teamMemberTokenAmounts[i]);
        }
    }

    receive() external payable {}

    modifier validRecipient(address to) {
        if(to == address(0x0) || to == address(this)) {
            revert InvalidRecipient();
        }
        _;
    }

    modifier onlyConfig() {
        if (msg.sender != address(config) && msg.sender != owner()) {
            revert CallerIsNotConfig();
        }
        _;
    }

    //=========================================================================
    // ERC20 OVERRIDES
    //=========================================================================

    /**
     * @return The total number of fragments.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalFragmentSupply;
    }

    /**
     * @notice Computes the current max scaling factor
     */

    function maxScalingFactor() public view returns (uint256) {
        // scaling factor can only go up to 2**256-1 = _fragmentToKarrots(_totalFragmentSupply) * karrotsScalingFactor
        // this is used to check if karrotsScalingFactor will be too high to compute balances when rebasing.
        return Math.mulDiv(type(uint256).max / _fragmentToKarrots(_totalFragmentSupply),1, maxScaleFactorAdjust);
    }

    /**
     * @notice Mints new tokens, increasing totalSupply, and a users balance.
     */
    function mint(address to, uint256 amount) external returns (bool) {

        if(!hasRole(MINTER_ROLE, _msgSender())){
            revert MustHaveMinterRole();
        }

        _mint(to, amount);
        return true;
    }

    function _mint(address to, uint256 amount) internal override {
        // increase totalSupply
        _totalFragmentSupply += uint160(amount);

        // get underlying value
        uint256 karrotsAmount = _fragmentToKarrots(amount);

        // make sure the mint didnt push maxScalingFactor too low
        if(karrotsScalingFactor > maxScalingFactor()) {
            revert MaxScalingFactorTooLow();
        }

        // add balance
        _karrotsBalances[to] = _karrotsBalances[to].add(karrotsAmount);

        emit Mint(to, amount);
        emit Transfer(address(0), to, amount);
    }

    /**
     * @notice Burns tokens from msg.sender, decreases totalSupply, and a users balance.
     */

    function burn(uint256 amount) public override {
        _burn(amount);
    }

    function _burn(uint256 amount) internal {
        // decrease totalSupply
        _totalFragmentSupply -= uint160(amount);

        // get underlying value
        uint256 karrotsAmount = _fragmentToKarrots(amount);

        // decrease balance
        _karrotsBalances[msg.sender] = _karrotsBalances[msg.sender].sub(karrotsAmount);
        emit Burn(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);
    }

    /* - ERC20 functionality - */

    /**
     * @dev Transfer tokens to a specified address.
     * @param to The address to transfer to.
     * @param amount The amount to be transferred.
     * @return True on success, false otherwise.
     */

    function transfer(address to, uint256 amount) public override validRecipient(to) returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * @param from The address you want to send tokens from.
     * @param to The address you want to transfer to.
     * @param amount The amount of tokens to be transferred.
     */

    function transferFrom(address from, address to, uint256 amount) public override validRecipient(to) returns (bool) {        
        _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender].sub(amount);
        _transfer(from, to, amount);
        return true;
    }


    /**
     * @dev transfer tokens from one address to another
     * @param from address to send tokens from
     * @param to address to transfer tokens to
     * @param amount amount of tokens to transfer
     * @notice tax value should be in terms of 1e24 like the balances.
     * @notice event value should be in terms of 1e18 for events.
     */

    function _transfer(address from, address to, uint256 amount) internal override {
        if(from == address(0) || to == address(0)){
            revert ZeroAddressNotAllowed();
        }

        // get value in karrots
        uint256 karrotsValue = _fragmentToKarrots(amount);
        uint256 thisTaxValue = 0;
        
        // no internal swaps call this, only user-called swaps
        if( !inSwap && (isDexAddress[to] || isDexAddress[from]) ){
            // [!] should use karrotsValue instead of value - same 10^24 that adjusts the balances below
            thisTaxValue = computeTax(to, from, karrotsValue);

            // add tax value to contract, for swap to ETH and send to treasury
            _karrotsBalances[address(this)] = _karrotsBalances[address(this)].add(thisTaxValue);            
        
            if(thisTaxValue > 0){
                emit Transfer(from, address(this), _karrotsToFragment(thisTaxValue));
            }

            // if we're not already within an ETH swap, over the threshold, and user is selling
            // swap the tax value to eth and send to treasury (input is 10^18)            
            if( (balanceOf(address(this)) > taxSwapAmountThreshold) && isDexAddress[to]){
                _swapContractKarrotsToEth();
            }
        }

        // sub from from, add to to, minus the taxed value
        _karrotsBalances[from] = _karrotsBalances[from].sub(karrotsValue);
        _karrotsBalances[to] = _karrotsBalances[to].add(karrotsValue.sub(thisTaxValue));   

        //show event in terms of 10^18
        emit Transfer(from, to, amount.sub(_karrotsToFragment(thisTaxValue)));

    }

    /**
     * @dev swaps contract's karrots balance for eth as part of tax collection
     * @notice inSwap prevents recursive transferFrom calls
     * @notice also diverts divertTaxToStolenPoolRate of tax to the stolen pool
     */
    
    function _swapContractKarrotsToEth() private nonReentrant {

        inSwap = true;

        // balanceOf returns 10^18 units
        uint256 _contractKarrotAmount = balanceOf(address(this));

        // 10^18 * N/10000
        uint256 _divertedAmount = Math.mulDiv(_contractKarrotAmount, divertTaxToStolenPoolRate, PERCENTAGE_DENOMINATOR);
        
        // 10^18 - 10^18
        uint256 _swapToEthAmount = _contractKarrotAmount - _divertedAmount;

        // Ensure the Uniswap router has enough allowance (the amount to swap)
        if ( allowance(address(this),config.uniswapRouterAddress()) < _swapToEthAmount) {
            _allowedFragments[address(this)][config.uniswapRouterAddress()] = _swapToEthAmount;
        }

        // divert _divertedAmount to stolen pool (burn, then virtual deposit)
        this.burn(_divertedAmount);
        IStolenPool(config.karrotStolenPoolAddress()).virtualDeposit(_divertedAmount);

        // Swap _swapEthAmount to ETH
        IUniswapV2Router02(config.uniswapRouterAddress()).swapExactTokensForETHSupportingFeeOnTransferTokens(
            _swapToEthAmount,
            0,
            swapPath,
            outputAddress,
            block.timestamp
        );

        inSwap = false;
    }

    function balanceOf(address who) public view override returns (uint256) {
        return _karrotsToFragment(_karrotsBalances[who]);
    }

    /** 
     * @notice Currently returns the internal storage amount
     * @param who The address to query.
     * @return The underlying balance of the specified address.
     */
    function balanceOfUnderlying(address who) public view returns (uint256) {
        return _karrotsBalances[who];
    }


    function allowance(address owner_, address spender) public view override returns (uint256) {
        return _allowedFragments[owner_][spender];
    }

    function approve(address spender, uint256 value) public override returns (bool) {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public override returns (bool) {
        _allowedFragments[msg.sender][spender] = _allowedFragments[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public override returns (bool) {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    /**
     * @dev rebases the token
     * @param epoch the epochtime of the rebase
     * @param indexDelta the delta of the rebase
     * @param positive whether or not the rebase is positive
     * @notice returns the new scale factor based on the supplied indexDelta
     * @notice if debase (most of the time, unless manually altered), new scaling factor < old scaling factor. 
     *         the degree to how much less it is is regulated by _minScalingFactorForThisDebase
     */

    function rebase(uint256 epoch, uint256 indexDelta, bool positive) public nonReentrant returns (uint256) {
        if(!hasRole(REBASER_ROLE, _msgSender())) {
            revert MustHaveRebaserRole();
        }
        // no change
        if (indexDelta == 0) {
            emit Rebase(epoch, karrotsScalingFactor, karrotsScalingFactor);
            return _totalFragmentSupply;
        }

        // for events
        uint256 prevKarrotsScalingFactor = karrotsScalingFactor;

        if (!positive) {
            karrotsScalingFactor = uint64(Math.mulDiv(uint256(karrotsScalingFactor), KARROTS_DECIMALS, KARROTS_DECIMALS.add(indexDelta)));
            karrotsScalingFactor = uint64(Math.max(karrotsScalingFactor, _minScalingFactorForThisDebase(prevKarrotsScalingFactor)));
        } else {
            uint256 newScalingFactor = uint64(Math.mulDiv(uint256(karrotsScalingFactor), KARROTS_DECIMALS.add(indexDelta), KARROTS_DECIMALS));
            karrotsScalingFactor = uint64(Math.min(uint256(newScalingFactor), maxScalingFactor()));
        }

        emit Rebase(epoch, prevKarrotsScalingFactor, karrotsScalingFactor);
        return _totalFragmentSupply;
    }

    function swapContractKarrotsToEth() public onlyOwner {
        _swapContractKarrotsToEth();
    }

    //=========================================================================
    // GETTERS
    //=========================================================================

    /**
     * @dev called within _transfer to determine the tax amount. does not apply tax during pool creation
     *  @param _to the address to transfer to
     *  @param _from the address to transfer from
     *  @param _value the amount to transfer (in units of 10^24!)
     */
    function computeTax(address _to, address _from, uint256 _value) public view returns (uint256) {
        if (isDexAddress[_to] && _from != config.dexInterfacerAddress()) {
            return _value.mul(sellTaxRate).div(PERCENTAGE_DENOMINATOR);
        } else if (isDexAddress[_from]) {
            return _value.mul(buyTaxRate).div(PERCENTAGE_DENOMINATOR);
        } else {
            return 0;
        }            
    }

    function karrotsToFragment(uint256 karrots) public view returns (uint256) {
        return _karrotsToFragment(karrots);
    }

    function fragmentToKarrots(uint256 fragment) public view returns (uint256) {
        return _fragmentToKarrots(fragment);
    }

    // 10^24 --> 10^18
    function _karrotsToFragment(uint256 karrots) internal view returns (uint256) {
        return karrots.mul(karrotsScalingFactor).div(KARROTS_INTERNAL_DECIMALS);
    }

    //10^18 --> 10^24
    function _fragmentToKarrots(uint256 value) internal view returns (uint256) {
        return value.mul(KARROTS_INTERNAL_DECIMALS).div(karrotsScalingFactor);
    }

    function getTotalSupply() external view returns (uint256) {
        return _totalFragmentSupply;
    }

    function _minScalingFactorForThisDebase(uint256 _previousScalingFactor) internal view returns (uint256) {
        return Math.mulDiv(_previousScalingFactor, PERCENTAGE_DENOMINATOR - maxScaleFactorDecreasePercentagePerDebase, PERCENTAGE_DENOMINATOR);
    }

    //=========================================================================
    // SETTERS
    //=========================================================================

    function setConfigManagerAddress(address _configManager) external onlyOwner {
        config = IConfig(_configManager);
    }

    function setSellTaxRate(uint16 _sellTaxRate) external onlyConfig {
        sellTaxRate = _sellTaxRate;
    }

    function setBuyTaxRate(uint16 _buyTaxRate) external onlyConfig {
        buyTaxRate = _buyTaxRate;
    }

    function addDexAddress(address _addr) external onlyConfig {
        isDexAddress[_addr] = true;
    }

    function removeDexAddress(address _addr) external onlyConfig {
        isDexAddress[_addr] = false;
    }

    function setMaxScaleFactorDecreasePercentagePerDebase(uint256 _maxScaleFactorDecreasePercentagePerDebase) external onlyConfig {
        maxScaleFactorDecreasePercentagePerDebase = uint16(_maxScaleFactorDecreasePercentagePerDebase);
    }

    function setTaxSwapAmountThreshold(uint256 _taxSwapAmountThreshold) external onlyConfig {
        taxSwapAmountThreshold = _taxSwapAmountThreshold;
    }

    function setOutputAddress(address _outputAddress) external onlyOwner {
        outputAddress = _outputAddress;
    }

    function setDivertTaxToStolenPoolRate(uint256 _divertTaxToStolenPoolRate) external onlyConfig {
        divertTaxToStolenPoolRate = _divertTaxToStolenPoolRate;
    }

    function setMaxScaleFactorAdjust(uint256 _adjustFactor) external onlyOwner {
        maxScaleFactorAdjust = _adjustFactor;
    }

    //=========================================================================
    // WITHDRAWALS
    //=========================================================================

    function withdrawERC20FromContract(address _to, address _token) external onlyOwner {
        if(_to == address(0) || _to == address(this)){
            revert InvalidRecipient();
        }

        bool os = IERC20(_token).transfer(_to, IERC20(_token).balanceOf(address(this)));
        if (!os) {
            revert ForwardFailed();
        }
    }

    function withdrawEthFromContract(address _to) external onlyOwner {
        if(_to == address(0) || _to == address(this)){
            revert InvalidRecipient();
        }

        (bool os, ) = payable(_to).call{value: address(this).balance}("");
        if (!os) {
            revert ForwardFailed();
        }
    }
}