pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/Context.sol";


contract ERC20PresetMinterRebaser is
Context,
AccessControlEnumerable,
ERC20Burnable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant REBASER_ROLE = keccak256("REBASER_ROLE");

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(REBASER_ROLE, _msgSender());
    }
}


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./utils/IPancakeRouter02.sol";
import "./utils/IPancakeFactory.sol";
import "./utils/IPancakePair.sol";

contract Token is ERC20PresetMinterRebaser, Ownable {

    receive() external payable {}

    using SafeMath for uint256;
    /**
     * @notice Internal decimals used to handle scaling factor
     */
    uint256 public constant internalDecimals = 10 ** 24;

    /**
     * @notice Used for percentage maths
     */
    uint256 public constant BASE = 10 ** 18;

    /**
     * @notice Scaling factor that adjusts everyone's balances
     */
    uint256 public scalingFactor;

    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowedFragments;

    uint256 public initSupply;

    mapping(address => uint256) public nonces;
    uint256 private INIT_SUPPLY = 88888 * 10 ** 18;
    uint256 private _totalSupply;


    bool inSwap;

    modifier validRecipient(address to) {
        require(to != address(0x0));
        _;
    }

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    event Rebase(uint256 indexed epoch, uint256 prevScalingFactor, uint256 newScalingFactor);
    event Burn(address indexed burner, uint256 value);

    address public marketingAddress;

    uint256 public marketingRate;
    uint256 public liquidityRate;
    uint256 public lpRate;
    uint256 public startBlock;

    mapping(address => bool) public isMarketPair;
    mapping(address => bool) public isExcludedFromFee;

    address public usdt;
    address public router;
    address public pairAddress;

    bool public swapEnabled;

    constructor(address _marketing) ERC20PresetMinterRebaser("XiaoLong", "XiaoLong")  {

        router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        usdt = 0x55d398326f99059fF775485246999027B3197955;

        marketingAddress = _marketing;

        marketingRate = 100;
        liquidityRate = 100;
        lpRate = 200;

        pairAddress = IPancakeFactory(IPancakeRouter01(router).factory())
        .createPair(address(this), usdt);

        isExcludedFromFee[_marketing] = true;
        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;

        isMarketPair[address(pairAddress)] = true;

        scalingFactor = BASE;
        initSupply = _fragmentToToken(INIT_SUPPLY);
        _totalSupply = INIT_SUPPLY;
        _balances[owner()] = initSupply;
        emit Transfer(address(0), msg.sender, INIT_SUPPLY);
    }

    function startTrade() public onlyOwner {
        startBlock = block.number;
    }

    function setRates(uint256 _marketingRate, uint256 _liquidityRate, uint256 _lpRate) public onlyOwner {
        marketingRate = _marketingRate;
        liquidityRate = _liquidityRate;
        lpRate = _lpRate;
    }


    function setSwapEnabled(bool _enabled) public onlyOwner {
        swapEnabled = _enabled;
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
        return uint256(int256(- 1)) / initSupply;
    }

    /**
     * @notice Burns tokens from msg.sender, decreases totalSupply, initSupply, and a users balance.
     */

    function burn(uint256 amount) public override {
        _burn(amount);
    }

    function _burn(uint256 amount) internal {
        // decrease totalSupply
        _totalSupply = _totalSupply.sub(amount);

        // get underlying value
        uint256 tokenValue = _fragmentToToken(amount);

        // decrease initSupply
        initSupply = initSupply.sub(tokenValue);

        // decrease balance
        _balances[msg.sender] = _balances[msg.sender].sub(tokenValue);
        emit Burn(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);
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
    validRecipient(to)
    returns (bool)
    {
        // get amount in underlying
        uint256 tokenValue = _fragmentToToken(value);
        _transfer(msg.sender, to, tokenValue);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * @param from The address you want to send tokens from.
     * @param to The address you want to transfer to.
     * @param value The amount of tokens to be transferred.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override validRecipient(to) returns (bool) {
        // decrease allowance
        if (!hasRole(MINTER_ROLE, _msgSender())) {//the chef do not need allowance
            _allowedFragments[from][msg.sender] = _allowedFragments[from][
            msg.sender
            ].sub(value);
        }
        uint256 tokenValue = _fragmentToToken(value);
        _transfer(from, to, tokenValue);
        return true;
    }


    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        if (inSwap) {
            _basicTransfer(sender, recipient, amount);
        } else {
            if (amount == 0) {
                _balances[recipient] = _balances[recipient].add(amount);
                return;
            }
            _balances[sender] = _balances[sender].sub(
                amount,
                "Insufficient Balance"
            );

            if (startBlock == 0 && (isMarketPair[recipient] || isMarketPair[sender])) {
                require(isExcludedFromFee[sender] ||
                    isExcludedFromFee[recipient], "not trade and liquidity");
            }


            if (
                swapEnabled &&
                isMarketPair[recipient] &&
                balanceOf(address(this)) >= _tokenToFragment(amount).div(2)
            ) {
                swapTokensForUSDT(_tokenToFragment(amount).div(2), marketingAddress);
            }

            uint256 finalAmount = (isExcludedFromFee[sender] ||
            isExcludedFromFee[recipient])
            ? amount
            : takeFee(sender, recipient, amount);

            _balances[recipient] = _balances[recipient].add(finalAmount);

            emit Transfer(sender, recipient, _tokenToFragment(finalAmount));
        }
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, _tokenToFragment(amount));
        return true;
    }


    function takeFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        uint256 feeAmount = 0;
        uint256 _amount = amount;

        if (isMarketPair[sender] && startBlock + 60 >= block.number) {
            feeAmount = _amount.mul(99).div(100);
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
            return _amount.sub(feeAmount);
        }

        if (isMarketPair[sender] || isMarketPair[recipient]) {

            uint256 marketingAmount = _amount.mul(marketingRate).div(10000);
            uint256 liquidityAmount = _amount.mul(liquidityRate).div(10000);
            uint256 lpAmount = _amount.mul(lpRate).div(10000);

            if (marketingAmount > 0) {
                _balances[address(this)] = _balances[address(this)].add(
                    marketingAmount
                );
                emit Transfer(sender, address(this), _tokenToFragment(marketingAmount));
            }
            if (liquidityAmount > 0) {
                _balances[address(this)] = _balances[address(this)].add(
                    liquidityAmount
                );
                emit Transfer(sender, address(this), _tokenToFragment(liquidityAmount));
            }

            if (lpAmount > 0) {
                _balances[address(this)] = _balances[address(this)].add(
                    lpAmount
                );
                emit Transfer(sender, address(this), _tokenToFragment(lpAmount));
            }

            feeAmount = feeAmount.add(marketingAmount).add(liquidityAmount).add(lpAmount);

        }
        return _amount.sub(feeAmount);
    }


    function swapTokensForUSDT(uint256 tokenAmount, address to)
    private
    lockTheSwap
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = usdt;

        _allowedFragments[address(this)][address(router)] = tokenAmount;

        IPancakeRouter02(router)
        .swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            to,
            block.timestamp
        );
    }

    /**
     * @param who The address to query.
     * @return The balance of the specified address.
     */
    function balanceOf(address who) public view override returns (uint256) {
        return _tokenToFragment(_balances[who]);
    }

    /** @notice Currently returns the internal storage amount
     * @param who The address to query.
     * @return The underlying balance of the specified address.
     */
    function balanceOfUnderlying(address who) public view returns (uint256) {
        return _balances[who];
    }

    /**
     * @dev Function to check the amount of tokens that an owner has allowed to a spender.
     * @param owner_ The address which owns the funds.
     * @param spender The address which will spend the funds.
     * @return The number of tokens still available for the spender.
     */
    function allowance(address owner_, address spender)
    public
    view
    override
    returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of
     * msg.sender. This method is included for ERC20 compatibility.
     * increaseAllowance and decreaseAllowance should be used instead.
     * Changing an allowance with this method brings the risk that someone may transfer both
     * the old and the new allowance - if they are both greater than zero - if a transfer
     * transaction is mined before the later approve() call is mined.
     *
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value)
    public
    override
    returns (bool)
    {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner has allowed to a spender.
     * This method should be used instead of approve() to avoid the double approval vulnerability
     * described above.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
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

    /**
     * @dev Decrease the amount of tokens that an owner has allowed to a spender.
     *
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
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


    function rebase(
        uint256 epoch,
        uint256 indexDelta,
        bool positive
    ) public returns (uint256) {
        require(hasRole(REBASER_ROLE, _msgSender()), "Must have rebaser role");

        // no change
        if (indexDelta == 0) {
            emit Rebase(epoch, scalingFactor, scalingFactor);
            return _totalSupply;
        }

        // for events
        uint256 prevScalingFactor = scalingFactor;

        if (!positive) {
            // negative rebase, decrease scaling factor
            scalingFactor = scalingFactor
            .mul(BASE.sub(indexDelta))
            .div(BASE);
        } else {
            // positive rebase, increase scaling factor
            uint256 newScalingFactor = scalingFactor
            .mul(BASE.add(indexDelta))
            .div(BASE);
            if (newScalingFactor < _maxScalingFactor()) {
                scalingFactor = newScalingFactor;
            } else {
                scalingFactor = _maxScalingFactor();
            }
        }

        // update total supply, correctly
        _totalSupply = _tokenToFragment(initSupply);
        IPancakePair(pairAddress).sync();
        emit Rebase(epoch, prevScalingFactor, scalingFactor);

        return _totalSupply;
    }

    function tokenToFragment(uint256 _token) public view returns (uint256) {
        return _tokenToFragment(_token);
    }

    function fragmentToToken(uint256 value) public view returns (uint256) {
        return _fragmentToToken(value);
    }

    function _tokenToFragment(uint256 _token) internal view returns (uint256) {
        return _token.mul(scalingFactor).div(internalDecimals);
    }

    function _fragmentToToken(uint256 value) internal view returns (uint256) {
        return value.mul(internalDecimals).div(scalingFactor);
    }


    // Rescue tokens
    function rescueTokens(
        address token,
        address to,
        uint256 amount
    ) public onlyOwner returns (bool) {
        SafeERC20.safeTransfer(IERC20(token), to, amount);
        return true;
    }

}