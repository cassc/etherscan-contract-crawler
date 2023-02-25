/**
 *Submitted for verification at BscScan.com on 2023-02-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

// File: contracts/Tokens/extensions/ERC20_ML_AnyswapV6.sol

//This is an extension for AnyswapV6ERC20
//https://github.com/anyswap/chaindata/blob/main/AnyswapV6ERC20.sol
abstract contract ERC20_ML_AnyswapV6
{
    //========================
    // ATTRIBUTES
    //========================    

    address public immutable underlying = address(0); //Inderlying token. always 0 but required for AnySwap
    address public anyswapMinter; //Minter from Anyswap

    //========================
    // CONFIG FUNCTIONS
    //========================  

    function _setMinter(address _minter) internal
    {
        require(_minter != address(0), "AnyswapV6ERC20: address(0)");
        anyswapMinter = _minter;
    }

    //========================
    // ANYSWAP FUNCTIONS
    //========================  

    function mint(address to, uint256 amount) external virtual returns (bool);
    function burn(address from, uint256 amount) external virtual returns (bool);

    //========================
    // SECURITY FUNCTIONS
    //========================  

    function checkAnyswapMinter(address _address) internal view returns (bool)
    {
        return (_address == anyswapMinter);
    }

    function requireAnyswapMinter() internal view
    {
        require(checkAnyswapMinter(msg.sender), "Minting not allowed");
    }
}

// File: @openzeppelin/contracts/utils/Context.sol

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/Customers/One Immortl/OneImmortl_ERC20_IMRTL optimizedBridge.sol

//made by MoonLabs
//[email protected]
contract OneImmortl_ERC20_IMRTL is
    Ownable,
    ERC20_ML_AnyswapV6
{
    //========================
    // STRUCTS
    //========================

    struct TaxTimeline
    {
        uint256 beforeTimestamp;
        uint256 tier;
    }

    struct TaxInfo
    {
        uint32 buy;
        uint32 sell;
        uint32 p2p;
    }

    //========================
    // CONSTANTS
    //========================

    string public constant name = "Immortl";
    string public constant symbol = "IMRTL";
    uint8 public constant decimals = 18;

    uint32 public constant PERCENT_FACTOR = 10000; //100 = 1%

    //========================
    // ATTRIBUTES
    //========================

    //base
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    uint256 public totalSupply;

    //enable trading
    bool public tradingEnabled; //transfer enabled
    mapping(address => bool) public excludedFromDisabledTransfer; //exclude address from disabled transfer

    //taxes
    mapping(address => bool) public excludedFromTax; //exclude address from taxes
    mapping(address => bool) public isLPToken; //check if LP token (to identify buy/sell)
    mapping(uint256 => TaxInfo) public taxes; //tax tiers
    address public taxWallet; //wallet to recieve taxes
    TaxInfo public maxTax = TaxInfo({
        buy: 500, //5%
        p2p: 500, //5%
        sell: 1000 //10%
    }); //max tax

    //tax timeline
    TaxTimeline[] public taxTimeline;

    //========================
    // EVENTS
    //========================

    //base
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    //enable trading
    event SetExcludedFromDisabledTransfer(address indexed wallet, bool excluded);

    //taxes
    event SetTax(
        uint256 indexed tier,
        int8 indexed taxType,
        uint256 tax
    );
    event SetExcludedFromTax(address indexed wallet, bool exclude);
    event SetLPToken(address  indexed token, bool isLP);

    //========================
    // CREATE
    //========================

    constructor()
    {        
        //init
        taxWallet = msg.sender;     

        //exclude
        setExcludedFromDisabledTransfer(msg.sender, true);
        setExcludedFromTax(msg.sender, true);
        setExcludedFromTax(address(this), true);    

        //tiers
        uint32 buyTax = 0;
        uint32 p2pTax = 0;
        _setTaxTier(
            0, 
            TaxInfo({
                buy: buyTax,
                p2p: p2pTax,
                sell: 500
            })
        );
        _setTaxTier(
            1, 
            TaxInfo({
                buy: buyTax,
                p2p: p2pTax,
                sell: 1000
            })
        );
        _setTaxTier(
            2, 
            TaxInfo({
                buy: buyTax,
                p2p: p2pTax,
                sell: 1000
            })
        );
        _setTaxTier(
            3, 
            TaxInfo({
                buy: buyTax,
                p2p: p2pTax,
                sell: 1000
            })
        );    

        //tax timeline
        taxTimeline.push(TaxTimeline({ beforeTimestamp: 1678748400, tier: 3})); //14.03.2023
        taxTimeline.push(TaxTimeline({ beforeTimestamp: 1681423200, tier: 2})); //14.04.2023
        taxTimeline.push(TaxTimeline({ beforeTimestamp: 1684015200, tier: 1})); //14.05.2023               
    }

    //========================
    // ADMIN FUNCTIONS
    //========================

    function setMinter(address _minter) external onlyOwner
    {
        _setMinter(_minter);
    }

    function enableTrading() external onlyOwner
    {
        tradingEnabled = true;
    }

    function setExcludedFromDisabledTransfer(address _wallet, bool _excluded) public onlyOwner
    {
        //set
        excludedFromDisabledTransfer[_wallet] = _excluded;
        emit SetExcludedFromDisabledTransfer(_wallet, _excluded);
    }

    function setTaxWallet(address _wallet) external onlyOwner
    {
        //set
        require(_wallet != address(0), "Invalid address");
        taxWallet = _wallet;
    }    

    function _setTax(uint256 _tier, int8 _type, uint32 _tax, bool _checkMax) internal onlyOwner
    {
        //check
        require(_type >= -1 && _type <= 1, "Invalid Type");
        require(_tax <= PERCENT_FACTOR, "Invalid Tax");
        if (_checkMax)
        {            
            require(_tax <= getMaxTaxPercent(_type), "Tax to high");            
        }

        //set
        if (_type == 1)
        {
            taxes[_tier].buy = _tax;
        }
        else if (_type == -1)
        {
            taxes[_tier].sell = _tax;
        }
        taxes[_tier].p2p = _tax;

        //event
        emit SetTax(
            _tier,
            _type,
            _tax
        );
    }

    function setTax(uint256 _tier, int8 _type, uint32 _tax) external
    {
        _setTax(_tier, _type, _tax, true);
    }

    function _setTaxTier(uint256 _tier, TaxInfo memory _tax) internal
    {
        _setTax(_tier, 1, _tax.buy, false);
        _setTax(_tier, -1, _tax.sell, false);
        _setTax(_tier, 0, _tax.p2p, false);
    }

    function setTaxTier(uint256 _tier, TaxInfo memory _tax) external
    {
        _setTax(_tier, 1, _tax.buy, true);
        _setTax(_tier, -1, _tax.sell, true);
        _setTax(_tier, 0, _tax.p2p, true);
    }    

    function setExcludedFromTax(address _wallet, bool _excluded) public onlyOwner
    {
        //set
        excludedFromTax[_wallet] = _excluded;
        emit SetExcludedFromTax(_wallet, _excluded);
    }

    function setLPToken(address _token, bool _isLP) public onlyOwner
    {
        //set
        isLPToken[_token] = _isLP;
        emit SetLPToken(_token, _isLP);
    }

    //========================
    // INFO FUNCTIONS
    //========================

    function balanceOf(address _account) external view returns (uint256)
    {
        return balances[_account];
    }

    function allowance(address _owner, address _spender) external view returns (uint256)
    {
        return allowances[_owner][_spender];
    }

    //========================
    // TOKEN ALLOWANCE FUNCTIONS
    //========================

    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) internal
    {
        //check
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");

        //adjust
        allowances[_owner][_spender] = _amount;

        //event
        emit Approval(
            _owner,
            _spender,
            _amount
        );
    }

    function approve(address _spender, uint256 _amount) public returns (bool)
    {
        _approve(
            msg.sender, 
            _spender, 
            _amount
        );
        return true;
    }    
    
    function increaseAllowance(address _spender, uint256 _amount) public returns (bool)
    {
        _approve(
            msg.sender,
            _spender,
            allowances[msg.sender][_spender] + _amount
        );
        return true;
    }
    
    function decreaseAllowance(address _spender, uint256 _amount) public returns (bool)
    {
        //check
        uint256 currentAllowance = allowances[msg.sender][_spender];
        require(currentAllowance >= _amount, "ERC20: decreased allowance below zero");

        //addjust
        unchecked
        {
            _approve(
                msg.sender,
                _spender,
                currentAllowance - _amount
            );
        }

        return true;
    }

    //========================
    // TOKEN TRANSFER FUNCTIONS
    //========================

    function transfer(address _from, uint256 _to) public returns (bool)
    {
        _transfer(msg.sender, _from, _to);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public returns (bool)
    {
        //check
        uint256 currentAllowance = allowances[_from][msg.sender];
        require(currentAllowance >= _amount, "ERC20: transfer amount exceeds allowance");

        //transfer
        _transfer(_from, _to, _amount);

        //adjust allowance
        unchecked
        {
            _approve(_from, msg.sender, currentAllowance - _amount);
        }

        return true;
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal
    {
        //take tax
        uint256 amount = takeTax(
            _from,
            _to,
            _amount
        );

        //transfer
        _transferBase(
            _from,
            _to,
            amount
        );
    }

    function _transferBase(
        address _from,
        address _to,
        uint256 _amount
    ) internal
    {
        //check
        require(tradingEnabled
                || excludedFromDisabledTransfer[_from]
                || checkAnyswapMinter(_from)
                || checkAnyswapMinter(_to),
            "Transfer disabled"
        );
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(balances[_from] >= _amount, "ERC20: transfer amount exceeds balance");

        //transfer        
        unchecked
        {
            balances[_from] -= _amount;
        }
        balances[_to] += _amount;

        //event
        emit Transfer(
            _from,
            _to,
            _amount
        );
    }

    //========================
    // TOKEN MINT/BURN FUNCTIONS
    //========================

    function mint(address _account, uint256 _amount) external override returns (bool)
    {
        requireAnyswapMinter();
        _mint(_account, _amount);        
        return true;
    }

    function burn(address _account, uint256 _amount) external override returns (bool)
    {
        requireAnyswapMinter();
        _burn(_account, _amount);        
        return true;
    }
    
    function _mint(address _account, uint256 _amount) internal
    {
        //check
        require(_account != address(0), "ERC20: mint to the zero address");

        //mint
        totalSupply += _amount;
        balances[_account] += _amount;

        //event
        emit Transfer(
            address(0),
            _account,
            _amount
        );
    }

    function _burn(address _from, uint256 _amount) internal
    {
        //check
        require(_from != address(0), "ERC20: burn from the zero address");
        require(balances[_from] >= _amount, "ERC20: burn amount exceeds balance");
        
        unchecked
        {
            balances[_from] -= _amount;
        }
        totalSupply -= _amount;

        //events
        emit Transfer(
            _from,
            address(0),
            _amount
        );
    }

    function burn(uint256 _amount) external
    {
        _burn(msg.sender, _amount);        
    }

    //========================
    // TAX FUNCTIONS
    //========================  

    function takeTax(address _from, address _to, uint256 _amount) internal returns (uint256)
    {
        //get tax
        uint32 tax = getTaxPercent(_from, _to);
        uint256 taxAmount = (_amount * uint256(tax)) / uint256(PERCENT_FACTOR);
        uint256 amount = _amount - taxAmount;

        //send tax to tax wallet
        if (taxAmount > 0)
        {
            _transferBase(
                _from,
                taxWallet,
                taxAmount
            );
        }

        return amount;
    }

    function getTaxType(address _from, address _to) internal view returns (int8)
    {
        if (isLPToken[_from])
        {
            return 1; //buy
        }
        else if (isLPToken[_to])
        {
            return -1; //sell
        }

        return 0; //p2p
    }

    function getTaxTier() internal view returns (uint256)
    {
        //get timeline
        for (uint256 n = 0; n < taxTimeline.length; n++)
        {
            if (block.timestamp <= taxTimeline[n].beforeTimestamp)
            {
                return taxTimeline[n].tier;
            }
        }

        return 0;
    }

    function getTaxPercent(address _from, address _to) public view returns (uint32)
    {
        //check tax wallet / excluded
        if (taxWallet == address(0)
            || excludedFromTax[_from]
            || excludedFromTax[_to])
        {
            return 0;
        }

    	//make decision based on type        
        int8 taxType = getTaxType(_from, _to);
        TaxInfo memory taxTier = taxes[getTaxTier()];
        if (taxType == 1)
        {
            return taxTier.buy;
        }
        else if (taxType == -1)
        {
            return taxTier.sell;
        }
        return taxTier.p2p;
    }

    function getMaxTaxPercent(int8 _type) internal view returns (uint32)
    {
    	//make decision based on type
        if (_type == 1)
        {
            return maxTax.buy;
        }
        else if (_type == -1)
        {
            return maxTax.sell;
        }
        return maxTax.p2p;
    }
}