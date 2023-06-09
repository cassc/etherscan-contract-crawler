// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
    (THE) SINGULARITY
    $ZERO

    Website: https://thiswillgotozero.com
    Twitter: https://twitter.com/TWGT_ZERO
    Telegram: https://t.me/thiswillgotozero
 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Pair.sol";

contract SingularityToken is IERC20, Ownable {
    using SafeMath for uint;

    uint private constant DECIMALS = 9;
    uint private constant MAX_uint = ~uint(0);

    IUniswapV2Router02 public immutable uniswapV2Router;
    IUniswapV2Pair public immutable uniswapV2Pair;
    address public immutable WETH;
    
    uint private constant REBASE_PERIOD = 6 hours;
    uint private constant INITIAL_FRAGMENTS_SUPPLY = 1_000_000_000_000 * 10**DECIMALS;

    // TOTAL_GONS is a multiple of INITIAL_FRAGMENTS_SUPPLY so that _gonsPerFragment is an integer.
    // Use the highest value that fits in a uint for max granularity.
    uint private constant TOTAL_GONS = MAX_uint - (MAX_uint % INITIAL_FRAGMENTS_SUPPLY);

    // MAX_SUPPLY = maximum integer < (sqrt(4*TOTAL_GONS + 1) - 1) / 2
    uint private constant MAX_SUPPLY = ~uint128(0);  // (2^128) - 1

    uint public constant maxWallet = INITIAL_FRAGMENTS_SUPPLY / 100;
    uint public currentEpoch = 1;
    uint public lastEpochTimestamp;
    uint private _totalSupply;
    uint private _gonsPerFragment;
    mapping(address => uint) private _gonBalances;

    // This is denominated in Fragments, because the gons-fragments conversion might change before
    // it's fully paid.
    mapping (address => mapping (address => uint)) private _allowedFragments;

    // Anti-bot and anti-whale mappings and variables
    mapping(address => uint) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch
    bool public limitsEnabled = true;

    string private _name = "Singularity";
    string private _symbol = "ZERO";
    uint8 private _decimals = uint8(DECIMALS);

    event LogRebase(uint indexed epoch, uint totalSupply);

    modifier validRecipient(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }

    constructor()
    {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

        address pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), WETH);
            
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Pair(pair);

        lastEpochTimestamp = 1686081600;

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonBalances[msg.sender] = TOTAL_GONS;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        
        emit Transfer(address(0x0), msg.sender, _totalSupply);
    }

        /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @return The total number of fragments.
     */
    function totalSupply()
        external
        view
        returns (uint)
    {
        return _totalSupply;
    }

    /**
     * @param who The address to query.
     * @return The balance of the specified address.
     */
    function balanceOf(address who)
        public
        view
        returns (uint)
    {
        return _gonBalances[who].div(_gonsPerFragment);
    }

    /**
     * @dev Transfer tokens to a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     * @return True on success, false otherwise.
     */
    function transfer(address to, uint value)
        external
        validRecipient(to)
        returns (bool)
    {
        if (limitsEnabled) {
            if (
                to != owner() &&
                to != address(0x0) && 
                to != address(0xdead) &&
                to != address(uniswapV2Router) &&
                to != address(uniswapV2Pair)
            ) {
                require(
                    _holderLastTransferTimestamp[msg.sender] <
                        block.number,
                    "transfer:: Transfer Delay enabled. Only one purchase per block allowed."
                );
                _holderLastTransferTimestamp[msg.sender] = block.number;

                require(
                    value + balanceOf(to) <= maxWallet,
                    "transfer:: Max wallet exceeded"
                );
            }
        }

        uint gonValue = value.mul(_gonsPerFragment);
        _gonBalances[msg.sender] = _gonBalances[msg.sender].sub(gonValue);
        _gonBalances[to] = _gonBalances[to].add(gonValue);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * @param from The address you want to send tokens from.
     * @param to The address you want to transfer to.
     * @param value The amount of tokens to be transferred.
     */
    function transferFrom(address from, address to, uint value)
        external
        validRecipient(to)
        returns (bool)
    {
        if (limitsEnabled) {
            if (
                to != owner() &&
                to != address(0x0) && 
                to != address(0xdead) &&
                to != address(uniswapV2Router) &&
                to != address(uniswapV2Pair)
            ) {
                require(
                    _holderLastTransferTimestamp[from] <
                        block.number,
                    "transfer:: Transfer Delay enabled. Only one purchase per block allowed."
                );
                _holderLastTransferTimestamp[from] = block.number;

                require(
                    value + balanceOf(to) <= maxWallet,
                    "transfer:: Max wallet exceeded"
                );
            }
        }

        _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender].sub(value);

        uint gonValue = value.mul(_gonsPerFragment);
        _gonBalances[from] = _gonBalances[from].sub(gonValue);
        _gonBalances[to] = _gonBalances[to].add(gonValue);
        emit Transfer(from, to, value);

        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner has allowed to a spender.
     * @param owner_ The address which owns the funds.
     * @param spender The address which will spend the funds.
     * @return The number of tokens still available for the spender.
     */
    function allowance(address owner_, address spender)
        external
        view
        returns (uint)
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
    function approve(address spender, uint value)
        external
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
    function increaseAllowance(address spender, uint addedValue)
        external
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] =
            _allowedFragments[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner has allowed to a spender.
     *
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint subtractedValue)
        external
        returns (bool)
    {
        uint oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Notifies Fragments contract about a new rebase cycle.
     * @return The total number of fragments after the supply adjustment.
     */
    function rebase()
        external
        returns (uint)
    {
        require(lastEpochTimestamp.add(REBASE_PERIOD) < block.timestamp,
            "rebase:: Too soon to trigger next rebase!");

        currentEpoch++;
        lastEpochTimestamp = block.timestamp;
        _totalSupply = _totalSupply.sub(_totalSupply / 2);
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        uniswapV2Pair.sync();

        emit LogRebase(currentEpoch, _totalSupply);
        return _totalSupply;
    }

    // disable Transfer delay - cannot be reenabled
    function disableLimits() external onlyOwner returns (bool) {
        limitsEnabled = false;
        return true;
    }
}