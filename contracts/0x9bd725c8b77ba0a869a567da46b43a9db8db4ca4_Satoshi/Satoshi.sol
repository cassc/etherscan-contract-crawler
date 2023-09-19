/**
 *Submitted for verification at Etherscan.io on 2023-07-03
*/

/*
 * Satoshi P2P e-cash paper
 *
 * Satoshi Nakamoto
 * [email protected]
 * www.bitcoin.org
 *
 * Abstract:
 *
 * A purely decentralized implementation of an Ethereum contract, inspired by 
 * Bitcoin's peer-to-peer electronic cash system, enables the direct transfer 
 * of tokens from one party to another without a third-party intermediary. 
 * Cryptographic methods provide part of the solution, but primary advantages 
 * are lost if a trusted authority is still needed to manage token supply and 
 * prevent over-spending.
 *
 * We propose a solution to the token supply management using a 
 * contract-level automated feature. The contract manages the token supply by 
 * calculating the rewards from a block and applying the "BlockReward" event, 
 * forming a record that cannot be altered without redoing the reward event. 
 * The reward event not only serves as evidence of the sequence of operations, 
 * but also as evidence of the largest pool of token holders. As long as a 
 * majority of token holders are not cooperating to disrupt the contract, 
 * they'll validate the longest chain of events and outpace potential adversaries.
 *
 * The contract itself requires minimal structure. Transactions are executed 
 * on a first-come-first-serve basis, and addresses can interact with the 
 * contract at will, accepting the outcome of the longest chain of events as 
 * proof of what happened in their absence. In addition, the contract 
 * periodically contributes tokens to the Satoshi Contribution, effectively 
 * removing them from the circulating supply. This contributes to the scarcity 
 * and potentially the value of the token over time, reflecting the spirit of 
 * Satoshi Nakamoto's vision in the context of an Ethereum contract.
 * 
 * https://twitter.com/0xSatoshiETH
*/

pragma solidity 0.8.19;

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

contract Satoshi is ERC20Detailed, Ownable {

    uint256 public halvingRateNumerator = 810101010;
    uint256 public halvingRateDenominator = 100000000000;

    uint256 public blockRewardInterval = 2 hours;
    uint256 public nextBlockReward;
    bool public autoBlockReward = true;

    uint256 public maxTxnAmount;
    uint256 public maxWallet;

    uint256 public percentForSatoshi = 50;
    bool public satoshiEnabled = true;
    uint256 public satoshiFrequency = 2 hours;
    uint256 public nextSatoshi;

    uint256 private constant DECIMALS = 18;
    uint256 private constant INITIAL_COINS_SUPPLY = 21_000_000 * 10**DECIMALS;
    uint256 private constant TOTAL_UNITS = type(uint256).max - (type(uint256).max % INITIAL_COINS_SUPPLY);
    uint256 private constant MIN_SUPPLY = 21 * 10**DECIMALS;

    event BlockReward(uint256 indexed time, uint256 totalSupply);
    event RemovedLimits();
    event SatoshiContribution(uint256 indexed amount);

    IWETH public immutable weth;

    IDEXRouter public immutable router;
    address public immutable pair;
    
    bool public limitsInEffect = true;
    bool public lpAdded = false;
    
    uint256 private _totalSupply;
    uint256 private _unitsPerCoin;

    mapping(address => uint256) private _unitBalances;
    mapping(address => mapping(address => uint256)) private _allowedCoins;

    modifier validRecipient(address to) {
        require(to != address(0x0));
        _;
    }

    constructor() ERC20Detailed(block.chainid==1 ? "SATOSHI" : "SAT", block.chainid==1 ? "SATS" : "SAT", 18) {
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

        _totalSupply = INITIAL_COINS_SUPPLY;
        _unitBalances[address(this)] = TOTAL_UNITS;
        _unitsPerCoin = TOTAL_UNITS/(_totalSupply);

        maxTxnAmount = _totalSupply * 1 / 100;
        maxWallet = _totalSupply * 1 / 100;

        weth = IWETH(router.WETH());
        pair = IDEXFactory(router.factory()).createPair(address(this), router.WETH());

        emit Transfer(address(0x0), address(this), balanceOf(address(this)));
    }

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function allowance(address owner_, address spender) external view override returns (uint256){
        return _allowedCoins[owner_][spender];
    }

    function balanceOf(address who) public view override returns (uint256) {
        return _unitBalances[who]/(_unitsPerCoin);
    }

    function transfer(address recipient, uint256 amount) public override validRecipient(recipient) returns (bool) {
        _transferFrom(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 coins) public override returns (bool) {
        _allowedCoins[_msgSender()][spender] = coins;
        emit Approval(_msgSender(), spender, coins);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override validRecipient(recipient) returns (bool) {
        require(amount <= _allowedCoins[sender][_msgSender()], "Transfer amount exceeds allowance");
        _allowedCoins[sender][_msgSender()] = _allowedCoins[sender][_msgSender()]-amount;
        _transferFrom(sender, recipient, amount);
        return true;
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal {
        if(limitsInEffect){
            if (sender == pair || recipient == pair){
                require(amount <= maxTxnAmount, "Max Transaction Amount Exceeded");
            }
            if (recipient != pair){
                require(balanceOf(recipient) + amount <= maxWallet, "Max Wallet Amount Exceeded");
            }
        }

        if(recipient == pair){
            if(autoBlockReward && shouldReward()){
                blockReward();
            }
            if (shouldReward()) {
                autoSatoshi();
            }
        }

        uint256 unitAmount = amount*(_unitsPerCoin);

        _unitBalances[sender] = _unitBalances[sender]-(unitAmount);
        _unitBalances[recipient] = _unitBalances[recipient]+(unitAmount);

        emit Transfer(sender, recipient, unitAmount/(_unitsPerCoin));
    }

        function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool){
        uint256 oldValue = _allowedCoins[_msgSender()][spender];
        if (subtractedValue >= oldValue) {
            _allowedCoins[_msgSender()][spender] = 0;
        } else {
            _allowedCoins[_msgSender()][spender] = oldValue - subtractedValue;
        }
        emit Approval(_msgSender(), spender, _allowedCoins[_msgSender()][spender]);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool){
        _allowedCoins[_msgSender()][spender] = _allowedCoins[_msgSender()][spender] + addedValue;
        emit Approval(_msgSender(), spender, _allowedCoins[_msgSender()][spender]);
        return true;
    }

    function getSupplyDeltaOnNextBlockReward() external view returns (uint256){
        return (_totalSupply*halvingRateNumerator)/halvingRateDenominator;
    }

    function shouldReward() public view returns (bool) {
        return nextBlockReward <= block.timestamp;
    }

    function lpSync() internal {
        InterfaceLP _pair = InterfaceLP(pair);
        _pair.sync();
    }

    function blockReward() private returns (uint256) {
        uint256 time = block.timestamp;

        uint256 supplyDelta = (_totalSupply*halvingRateNumerator)/halvingRateDenominator;

        nextBlockReward += blockRewardInterval;

        if (supplyDelta == 0) {
            emit BlockReward(time, _totalSupply);
            return _totalSupply;
        }

        _totalSupply = _totalSupply - supplyDelta;

        if (_totalSupply < MIN_SUPPLY) {
            _totalSupply = MIN_SUPPLY;
            autoBlockReward = false;
        }

        _unitsPerCoin = TOTAL_UNITS / _totalSupply;

        lpSync();

        emit BlockReward(time, _totalSupply);
        return _totalSupply;
    }

    function manualBlockReward() external onlyOwner {
        require(shouldReward(), "Not yet time for block reward");
        blockReward();
    }

    function autoSatoshi() internal {
        nextSatoshi = block.timestamp + satoshiFrequency;

        uint256 liquidityPairBalance = balanceOf(pair);

        uint256 amountToContribute = liquidityPairBalance * percentForSatoshi / 10000;

        if (amountToContribute > 0) {
            uint256 unitAmountToContribute = amountToContribute * _unitsPerCoin;
            _unitBalances[pair] -= unitAmountToContribute;
            _unitBalances[address(0xdead)] += unitAmountToContribute;
            emit Transfer(pair, address(0xdead), amountToContribute);
        }

        InterfaceLP _pair = InterfaceLP(pair);
        _pair.sync();
        emit SatoshiContribution(amountToContribute);
    }

    function manualSatoshi() external onlyOwner {
        require(shouldReward(), "Must wait for cooldown to finish");

        nextSatoshi = block.timestamp + satoshiFrequency;

        uint256 liquidityPairBalance = balanceOf(pair);

        uint256 amountToContribute = liquidityPairBalance * percentForSatoshi / 10000;

        if (amountToContribute > 0) {
            uint256 unitAmountToContribute = amountToContribute * _unitsPerCoin;
            _unitBalances[pair] -= unitAmountToContribute;
            _unitBalances[address(0xdead)] += unitAmountToContribute;
            emit Transfer(pair, address(0xdead), amountToContribute);
        }

        InterfaceLP _pair = InterfaceLP(pair);
        _pair.sync();
        emit SatoshiContribution(amountToContribute);
    }

    function genesisBlock(address[] calldata _to) external payable onlyOwner {
        require(!lpAdded, "LP already added");
        require(address(this).balance > 0 && balanceOf(address(this)) > 0);

        uint256 totalDistribution = (_to.length * (INITIAL_COINS_SUPPLY * 3 / 1000));
        uint256 toDistribute = INITIAL_COINS_SUPPLY * 3 / 1000 * _unitsPerCoin;

        require(balanceOf(address(this)) >= totalDistribution, "Insufficient balance to distribute");

        for (uint256 i = 0; i < _to.length; i++) {
            _unitBalances[_to[i]] += (toDistribute);
        }

        weth.deposit{value: address(this).balance}();

        uint lpBalance = (_unitBalances[address(this)] - (totalDistribution * _unitsPerCoin));
        _unitBalances[pair] += lpBalance;
        _unitBalances[address(this)] = 0;
        emit Transfer(address(this), pair, _unitBalances[pair] / _unitsPerCoin);

        IERC20(address(weth)).transfer(address(pair), IERC20(address(weth)).balanceOf(address(this)));

        InterfaceLP(pair).mint(owner());
        lpAdded = true;

        nextBlockReward = block.timestamp + blockRewardInterval;
        nextSatoshi = block.timestamp + satoshiFrequency;

        //The NY Times 4/07/2023 Israel Launches Biggest Air Attack on West Bank in Nearly Two Decades
    }

}