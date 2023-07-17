/**
 *Submitted for verification at Etherscan.io on 2023-06-29
*/

// https://twitter.com/CHAOS_ERC

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface InterfaceLP {
    function sync() external;
    function mint(address to) external returns (uint liquidity);
}

abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint8 _tokenDecimals
    ) {
        _name = _tokenName;
        _symbol = _tokenSymbol;
        _decimals = _tokenDecimals;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);
}

contract Ownable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IWETH {
    function deposit() external payable;
}

contract Chaos is ERC20Detailed, Ownable {

    uint256 public rateNumerator = 1914882956;
    uint256 public rateDenominator = 100000000000;

    uint256 public riftFrequency = 3 hours;
    uint256 public nextRift;
    bool public autoRift = true;

    uint256 public maxTxnAmount;
    uint256 public maxWallet;

    uint256 public percentForSingularity = 50;
    bool public singularityEnabled = true;
    uint256 public singularityFrequency = 3 hours;
    uint256 public nextSingularity;

    uint256 private constant DECIMALS = 18;
    uint256 private constant INITIAL_TOKENS_SUPPLY = 8_888_888 * 10**DECIMALS;
    uint256 private constant TOTAL_PARTS = type(uint256).max - (type(uint256).max % INITIAL_TOKENS_SUPPLY);
    uint256 private constant MIN_SUPPLY = 8 * 10**DECIMALS;

    event Rift(uint256 indexed time, uint256 totalSupply);
    event RemovedLimits();
    event Singularity(uint256 indexed amount);

    IWETH public immutable weth;

    IDEXRouter public immutable router;
    address public immutable pair;
    
    bool public limitsInEffect = true;
    bool public lpAdded = false;
    
    uint256 private _totalSupply;
    uint256 private _partsPerToken;

    mapping(address => uint256) private _partBalances;
    mapping(address => mapping(address => uint256)) private _allowedTokens;

    modifier validRecipient(address to) {
        require(to != address(0x0));
        _;
    }

    constructor() ERC20Detailed(block.chainid==1 ? "Harbinger" : "HTEST", block.chainid==1 ? "CHAOS" : "HTEST", 18) {
        address dexAddress;
        if(block.chainid == 1){
            dexAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        } else if(block.chainid == 5){
            dexAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        } else if (block.chainid == 97){
            dexAddress = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
        } else {
            revert("Chain not configured");
        }

        router = IDEXRouter(dexAddress);

        _totalSupply = INITIAL_TOKENS_SUPPLY;
        _partBalances[address(this)] = TOTAL_PARTS;
        _partsPerToken = TOTAL_PARTS/(_totalSupply);

        maxTxnAmount = _totalSupply * 1 / 100;
        maxWallet = _totalSupply * 1 / 100;

        weth = IWETH(router.WETH());
        pair = IDEXFactory(router.factory()).createPair(address(this), router.WETH());

        emit Transfer(address(0x0), address(this), balanceOf(address(this)));
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function allowance(address owner_, address spender) external view override returns (uint256){
        return _allowedTokens[owner_][spender];
    }

    function balanceOf(address who) public view override returns (uint256) {
        return _partBalances[who]/(_partsPerToken);
    }

    function shouldRift() public view returns (bool) {
        return nextRift <= block.timestamp;
    }

    function shouldSingularity() public view returns (bool) {
        return nextSingularity <= block.timestamp;
    }

    function lpSync() internal {
        InterfaceLP _pair = InterfaceLP(pair);
        _pair.sync();
    }

    function transfer(address to, uint256 value) external override validRecipient(to) returns (bool){
        _transferFrom(msg.sender, to, value);
        return true;
    }

    function removeLimits() external onlyOwner {
        require(limitsInEffect, "Limits already removed");
        limitsInEffect = false;
        emit RemovedLimits();
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(limitsInEffect){
            if (sender == pair || recipient == pair){
                require(amount <= maxTxnAmount, "Max Tx Exceeded");
            }
            if (recipient != pair){
                require(balanceOf(recipient) + amount <= maxWallet, "Max Wallet Exceeded");
            }
        }

        if(recipient == pair){
            if(autoRift && shouldRift()){
                rift();
            }
            if (shouldSingularity()) {
                autoSingularity();
            }
        }

        uint256 partAmount = amount*(_partsPerToken);

        _partBalances[sender] = _partBalances[sender]-(partAmount);
        _partBalances[recipient] = _partBalances[recipient]+(partAmount);

        emit Transfer(sender, recipient, partAmount/(_partsPerToken));

        return true;
    }

    function transferFrom(address from, address to,  uint256 value) external override validRecipient(to) returns (bool) {
        if (_allowedTokens[from][msg.sender] != type(uint256).max) {
            require(_allowedTokens[from][msg.sender] >= value,"Insufficient Allowance");
            _allowedTokens[from][msg.sender] = _allowedTokens[from][msg.sender]-(value);
        }
        _transferFrom(from, to, value);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool){
        uint256 oldValue = _allowedTokens[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedTokens[msg.sender][spender] = 0;
        } else {
            _allowedTokens[msg.sender][spender] = oldValue-(
                subtractedValue
            );
        }
        emit Approval(
            msg.sender,
            spender,
            _allowedTokens[msg.sender][spender]
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool){
        _allowedTokens[msg.sender][spender] = _allowedTokens[msg.sender][
        spender
        ]+(addedValue);
        emit Approval(
            msg.sender,
            spender,
            _allowedTokens[msg.sender][spender]
        );
        return true;
    }

    function approve(address spender, uint256 value) public override returns (bool){
        _allowedTokens[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function getSupplyDeltaOnNextRift() external view returns (uint256){
        return (_totalSupply*rateNumerator)/rateDenominator;
    }

    function rift() private returns (uint256) {
        uint256 time = block.timestamp;

        uint256 supplyDelta = (_totalSupply*rateNumerator)/rateDenominator;
        
        nextRift += riftFrequency;

        if (supplyDelta == 0) {
            emit Rift(time, _totalSupply);
            return _totalSupply;
        }

        _totalSupply = _totalSupply-supplyDelta;

        if (_totalSupply < MIN_SUPPLY) {
            _totalSupply = MIN_SUPPLY;
            autoRift = false;
        }

        _partsPerToken = TOTAL_PARTS/(_totalSupply);

        lpSync();

        emit Rift(time, _totalSupply);
        return _totalSupply;
    }

    function manualRift() external {
        require(shouldRift(), "Not in time");
        rift();
    }

    function autoSingularity() internal {
        nextSingularity = block.timestamp + singularityFrequency;

        uint256 liquidityPairBalance = balanceOf(pair);

        uint256 amountToBurn = liquidityPairBalance * percentForSingularity / 10000;

        if (amountToBurn > 0) {
            uint256 partAmountToBurn = amountToBurn*(_partsPerToken);
            _partBalances[pair] -= partAmountToBurn;
            _partBalances[address(0xdead)] += partAmountToBurn;
            emit Transfer(pair, address(0xdead), amountToBurn);
        }

        InterfaceLP _pair = InterfaceLP(pair);
        _pair.sync();
        emit Singularity(amountToBurn);
    }

    function manualSingularity() external {
        require(shouldSingularity(), "Must wait for cooldown to finish");

        nextSingularity = block.timestamp + singularityFrequency;

        uint256 liquidityPairBalance = balanceOf(pair);

        uint256 amountToBurn = liquidityPairBalance * percentForSingularity / 10000;

        if (amountToBurn > 0) {
            uint256 partAmountToBurn = amountToBurn*(_partsPerToken);
            _partBalances[pair] -= partAmountToBurn;
            _partBalances[address(0xdead)] += partAmountToBurn;
            emit Transfer(pair, address(0xdead), amountToBurn);
        }

        InterfaceLP _pair = InterfaceLP(pair);
        _pair.sync();
        emit Singularity(amountToBurn);
    }

    function initiate(address _to) external payable {
        require(!lpAdded, "LP already added");
        
        require(address(this).balance > 0 && balanceOf(address(this)) > 0);

        weth.deposit{value: address(this).balance}();

        _partBalances[pair] += _partBalances[address(this)];
        _partBalances[address(this)] = 0;
        emit Transfer(address(this), pair, _partBalances[pair]/(_partsPerToken));

        IERC20(address(weth)).transfer(address(pair), IERC20(address(weth)).balanceOf(address(this)));
        
        InterfaceLP(pair).mint(_to);
        lpAdded = true;

        nextRift = block.timestamp + riftFrequency;
        nextSingularity = block.timestamp + singularityFrequency;
    }
}