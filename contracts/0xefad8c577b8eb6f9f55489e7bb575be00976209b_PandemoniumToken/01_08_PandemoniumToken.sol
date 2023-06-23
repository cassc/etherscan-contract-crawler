// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
    PANDEMONIUM
    $CHAOS

    Website: https://pandemonium.wtf
    Twitter: https://twitter.com/Chaotic_DeFi
    Telegram: https://t.me/chaoticdefi
 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Pair.sol";

contract PandemoniumToken is IERC20, Ownable {
    using SafeMath for uint;

    uint private constant internalDecimals = 10**24;
    uint private constant BASE = 10**18;
    uint public scalingFactor;
    uint public initSupply;

    IUniswapV2Router02 public immutable uniswapV2Router;
    IUniswapV2Pair public immutable uniswapV2Pair;
    address public immutable WETH;
    
    uint private constant REBASE_PERIOD = 1 hours; // 1 hour between rebases
    uint public maxRebasePercentage = 50;

    address public vault;
    uint public currentEpoch;
    uint public lastEpochTimestamp;
    
    uint private constant INIT_SUPPLY = 1_000_000 * 10**18;
    uint public constant maxWallet = INIT_SUPPLY / 100;

    uint private _totalSupply;
    mapping (address => uint) internal _supplyBalances;
    mapping (address => mapping(address => uint)) internal _allowedFragments;

    // Anti-bot and anti-whale mappings and variables
    mapping(address => uint) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch
    mapping(address => bool) private _isExcluded;
    bool public limitsEnabled = true;

    string private _name = "Pandemonium";
    string private _symbol = "CHAOS";
    uint8 private _decimals = uint8(18);

    /**
     * @notice Event emitted when tokens are rebased
     */
    event Rebase(
        uint epoch,
        uint prefix,
        uint percentage,
        uint prevScalingFactor,
        uint newScalingFactor
    );

    event Mint(address to, uint amount);
    event Burn(address from, uint amount);

    modifier validRecipient(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }

    modifier onlyVault() {
        require(msg.sender == vault);
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

        lastEpochTimestamp = 1687467600;

        scalingFactor = BASE;
        initSupply = _fragmentsToSupply(INIT_SUPPLY);
        _totalSupply = INIT_SUPPLY;
        _supplyBalances[owner()] = initSupply;
        
        emit Transfer(address(0x0), msg.sender, INIT_SUPPLY);
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
    function balanceOf(address who) public view returns (uint) {
        return _supplyToFragments(_supplyBalances[who]);
    }

    function mint(address to, uint amount) external onlyVault returns (bool) {
        _mint(to, amount);
        return true;
    }

    function _mint(address to, uint amount) internal {
        _totalSupply = _totalSupply.add(amount);
        uint supplyValue = _fragmentsToSupply(amount);

        initSupply = initSupply.add(supplyValue);

        require(
            scalingFactor <= _maxScalingFactor(),
            "max scaling factor too low"
        );

        _supplyBalances[to] = _supplyBalances[to].add(supplyValue);

        emit Mint(to, amount);
        emit Transfer(address(0), to, amount);
    }

    function burn(uint amount) external onlyVault returns (bool) {
        _burn(amount);
        return true;
    }

    function _burn(uint amount) internal {
        _totalSupply = _totalSupply.sub(amount);
        uint supplyValue = _fragmentsToSupply(amount);

        initSupply = initSupply.sub(supplyValue);
        _supplyBalances[msg.sender] = _supplyBalances[msg.sender].sub(supplyValue);

        emit Burn(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);
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
                to != address(uniswapV2Pair) &&
                !(_isExcluded[msg.sender] || _isExcluded[to])
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

        uint supplyValue = _fragmentsToSupply(value);
        _supplyBalances[msg.sender] = _supplyBalances[msg.sender].sub(supplyValue);
        _supplyBalances[to] = _supplyBalances[to].add(supplyValue);

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
                to != address(uniswapV2Pair) &&
                !(_isExcluded[from] || _isExcluded[to])
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

        _allowedFragments[from][msg.sender] = _allowedFragments[from][
            msg.sender
        ].sub(value);

        uint supplyValue = _fragmentsToSupply(value);
        _supplyBalances[from] = _supplyBalances[from].sub(supplyValue);
        _supplyBalances[to] = _supplyBalances[to].add(supplyValue);

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
    function decreaseAllowance(address spender, uint subtractedValue)
        external
        returns (bool)
    {
        uint oldValue = _allowedFragments[msg.sender][spender];
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

        uint nonce = random();
        uint prefix = nonce % 2;
        uint percentage = nonce % maxRebasePercentage;
        if (percentage == 0) percentage = maxRebasePercentage;

        currentEpoch++;
        lastEpochTimestamp = block.timestamp;
        uint prevScalingFactor = scalingFactor;

        if (prefix == 1) {
            // positive rebase
            uint newScalingFactor = scalingFactor
                .mul(BASE.add(BASE.mul(percentage).div(100)))
                .div(BASE);

            if (newScalingFactor < _maxScalingFactor()) {
                scalingFactor = newScalingFactor;
            } else {
                scalingFactor = _maxScalingFactor();
            }
        } else {
            // negative rebase
            scalingFactor = scalingFactor
                .mul(BASE.sub(BASE.mul(percentage).div(100)))
                .div(BASE);
        }

        _totalSupply = _supplyToFragments(initSupply);
        uniswapV2Pair.sync();

        emit Rebase(
            currentEpoch, 
            prefix,
            percentage,
            prevScalingFactor, 
            scalingFactor
        );
        return _totalSupply;
    }

    function canRebase() external view returns (bool) {
        return lastEpochTimestamp.add(REBASE_PERIOD) < block.timestamp;
    }

    function toggleLimits() external onlyOwner returns (bool) {
        limitsEnabled = !limitsEnabled;
        return true;
    }

    // for token airdrop
    function excludeAddress(address _address) external onlyOwner {
        _isExcluded[_address] = true;
    }

    function setVault(address _vault) external onlyOwner {
        vault = _vault;
    }

    function setMaxRebase(uint percentage) external onlyOwner {
        require (percentage <= 50,
            "Max rebase percentage must be lte than 50");

        maxRebasePercentage = percentage;
    }

    function random() internal view returns (uint) {
        return uint(
            keccak256(
                abi.encodePacked(
                    block.timestamp, 
                    block.difficulty,
                    currentEpoch, 
                    scalingFactor
                )
            )
        );
    }

    /** VIEWS */

    function maxScalingFactor() external view returns (uint) {
        return _maxScalingFactor();
    }

    function _maxScalingFactor() internal view returns (uint) {
        return uint(int256(-1)) / initSupply;
    }

    function _fragmentsToSupply(uint amount) internal view returns (uint) {
        return amount.mul(internalDecimals).div(scalingFactor);
    }

    function _supplyToFragments(uint amount) internal view returns (uint) {
        return amount.mul(scalingFactor).div(internalDecimals);
    }
}