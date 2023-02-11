// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "https://github.com/Uniswap/v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol";

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract HalfNHalf is Context, IERC20, Ownable {
    using Address for address;
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private bots;
    address payable private _taxWallet;

    uint256 private initialTax = 8;
    uint256 private finalTax = 4;
    uint256 private reduceTaxAt = 30;
    uint256 private buyCount = 0;

    bool public paused;

    uint8 private constant _decimals = 9;
    uint256 private constant mantissa = 10 ** _decimals;
    uint256 public constant _tTotal = 5_555_555_555 * mantissa;
    string private constant _name = unicode"Half N Half";
    string private constant _symbol = unicode"HNH";

    uint256 public _maxTxAmount = 55_555_555 * mantissa;
    uint256 public _maxWalletSize = _maxTxAmount * 2;
    uint256 public _sellThreshold = 110_555_555_555 * mantissa;

    // Protein
    mapping(address => bool) public Spoiled;
    mapping(address => uint256) public Liquid;
    address[] public Proteins;
    uint256 public ActiveAgents;

    // Protein => Day => Amount Traded
    mapping(address => mapping(uint256 => uint256)) public MilkPoured;

    //Milk Cartons 
    address public Cartons;

    uint256 public IssueClearanceCard = 2_102_102_102 * mantissa; //Mint Carton At
    uint256 public RaiseClearanceAt = 4_204_204_204 * mantissa; //Raise Level At

    // Game
    uint256 public launchedAt;
    address[3] public TopRankers;
    uint256[3] public TopRankersAmount;

    bool public running = true; 


    uint256 public launchTimeStamp;
    uint256 public gameDuration;
    uint256 public gameDay = 1;
    uint public timeForReset = 1 days;
    uint256 public prizePool;

    bool public rewardsOpen = false;

    bool public shipmentReady;

    IUniswapV2Router02 private uniswapV2Router;

    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;

    event Launched(uint256 Time);
    event GotMilk(address Protein, uint256 ID);
    event MaxTxAmountUpdated(uint _maxTxAmount);

    struct Fees {
        uint256 dev;
        uint256 prizepool;
        uint256 ambassador;
    }

    struct Wallets {
        address payable dev;
        address payable prizepool;
        address payable ambassador;
    }

    Wallets public wallets;

    Fees public fees;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier Refrigerator {
        require(_msgSender() == Cartons, "No Milk.");
        _;
    }

    constructor () payable {
        _balances[address(this)] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_msgSender()] = true;


        fees = Fees({
            dev: 70,
            prizepool: 20,
            ambassador: 10
        });

        address[3] memory _wallets = [0xDA09daf6d8826540eF4E4cd0229f43B70b9F0A78,0xDA09daf6d8826540eF4E4cd0229f43B70b9F0A78,0xDA09daf6d8826540eF4E4cd0229f43B70b9F0A78];

        wallets = Wallets({
            dev:payable(_wallets[0]),
            prizepool:payable(_wallets[1]),
            ambassador:payable(_wallets[2])
        });

        emit Transfer(address(0), address(this), _tTotal);
        emit Launched(launchTimeStamp);
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
        return _tTotal;
    }

    function setWallets(address[3] memory _wallets) external onlyOwner {
        wallets = Wallets({
            dev: payable(_wallets[0]),
            ambassador: payable(_wallets[1]),
            prizepool: payable(_wallets[2])
        });
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(!bots[from] && !bots[to]);
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if(running){
        uint256 taxAmount = 0;

        address CurrentAgent;
        bool isBuy;
        bool isSell;

        if (from != owner() && to != owner() && from == uniswapV2Pair || to  == uniswapV2Pair && from != address(this) && to != address(this)) {
            if(!inSwap){
                taxAmount = amount.mul((buyCount > reduceTaxAt) ? finalTax : initialTax).div(100);
            }

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to] ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                isBuy = true;
                CurrentAgent = to;
                buyCount++;
            }

            if (!inSwap && from != uniswapV2Pair && swapEnabled && balanceOf(address(this)) > _sellThreshold) {
                swapTokensForEth(_sellThreshold > amount ? amount : _sellThreshold);
                
                if(address(this).balance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }

            if(to == uniswapV2Pair) {
                isSell = true;
                CurrentAgent = from;
                
                if(block.timestamp > gameDuration && TopRankers[0] != address(0) && buyCount > 0 && rewardsOpen && address(this).balance >= prizePool){
                    resetGame();
                }
            }

                MilkPoured[CurrentAgent][gameDay] += amount;
                
                if(MilkPoured[CurrentAgent][gameDay] > TopRankersAmount[2] && CurrentAgent != address(this) && CurrentAgent != address(0)){
                    for(uint i; i < TopRankers.length; i++){
                        if(MilkPoured[CurrentAgent][gameDay] > TopRankersAmount[i]){
                            if(i < 2) {
                                address rank1 = TopRankers[0];
                                address rank2 = TopRankers[1];
                                uint256 rank1A = MilkPoured[TopRankers[0]][gameDay];
                                uint256 rank2A = MilkPoured[TopRankers[1]][gameDay];
                                
                                if(TopRankers[i] == rank1 && CurrentAgent != rank1){
                                    TopRankers[1] = TopRankers[i];
                                    TopRankersAmount[1] = rank1A;
                                    
                                    if(CurrentAgent == rank2){
                                        TopRankers[i] = CurrentAgent;
                                        TopRankersAmount[i] = MilkPoured[CurrentAgent][gameDay];
                                        break;
                                    }
                                    
                                    TopRankers[2] = rank2;
                                    TopRankersAmount[2] = rank2A;
                                }

                                if(TopRankers[i] == rank2 && CurrentAgent != rank2){
                                    TopRankers[2] = TopRankers[i];
                                    TopRankersAmount[2] = rank2A;
                                }
                            }

                            TopRankers[i] = CurrentAgent;
                            TopRankersAmount[i] = MilkPoured[CurrentAgent][gameDay];
                            break;
                        }
                    }               
                }
            
            if(MilkPoured[CurrentAgent][gameDay] >= IssueClearanceCard && Carton(Cartons).balanceOf(CurrentAgent, 1) < 1 && shipmentReady){
                 GiveCarton(CurrentAgent);
            }
        }

            _balances[from] = _balances[from].sub(amount);
            _balances[to] = _balances[to].add(amount.sub(taxAmount));
            emit Transfer(from, to, amount.sub(taxAmount));

            if(taxAmount > 0){
            _balances[address(this)] = _balances[address(this)].add(taxAmount);
            emit Transfer(from, address(this), taxAmount);
            }
        }
    }

    function percentages() external view returns(uint dev, uint prizepool, uint ambassador){
        dev = fees.dev;
        prizepool = fees.prizepool;
        ambassador = fees.ambassador;
    } 

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function removeLimits() external onlyOwner{
        _maxTxAmount = _tTotal;
        _maxWalletSize=_tTotal;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function setTxLimits(uint256 _txAmount) external onlyOwner{
        _maxTxAmount = _txAmount * mantissa;
    }

    function setWalletLimits(uint256 _walletAmount) external onlyOwner{
        _maxWalletSize = _walletAmount * mantissa;
    }

    function sendETHToFee(uint256 Amount) private {
        uint256 amount = Amount - prizePool;
        uint8 factorial = 100;
        uint256 devAmount = (amount * fees.dev) / factorial;
        uint256 prizepoolAmount = (amount * fees.prizepool) / factorial;
        uint256 ambassadorAmount = (amount * fees.ambassador) / factorial;
        wallets.dev.transfer(devAmount);
        wallets.ambassador.transfer(ambassadorAmount);

        prizePool += prizepoolAmount;
    }

    function payOut() internal {
        uint256 amount = prizePool;
        uint8 factorial = 100;

        uint256[3] memory cut;
        cut[0] = (amount * 50) / factorial;
        cut[1] = (amount * 30) / factorial;
        cut[2] = (amount * 20) / factorial;

        if(address(this).balance >= prizePool){
            for(uint i; i < TopRankers.length; i++){
                if(TopRankers[i] != address(0) && !Spoiled[TopRankers[i]]){
                            payable(TopRankers[i]).transfer(cut[i]);
                }
            }
        }

        prizePool = 0;
    }

    function manualPayOut() external onlyOwner {
        resetGame();
    }

    function addToPrizePool() external payable onlyOwner {
        require(msg.value > 0, "Must be greater than 0.");
        prizePool += msg.value;
    }

    function addBots(address[] memory bots_) public onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    function delBots(address[] memory notbot) public onlyOwner {
      for (uint i = 0; i < notbot.length; i++) {
          bots[notbot[i]] = false;
      }
    }

    function openTrading() external payable onlyOwner {
        require(!tradingOpen, "trading is already open");
        
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), type(uint).max);
        
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this), balanceOf(address(this)), 0, 0, owner(), block.timestamp);
        
        swapEnabled = true;
        tradingOpen = true;

        
        launchTimeStamp = block.timestamp;

        gameDuration = launchTimeStamp + timeForReset;
        
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);

        
        launchedAt = block.timestamp;
        emit Launched(block.timestamp);
    }

    function reduceFee(uint256 _newFee) external onlyOwner{
      require(_newFee < finalTax, "Fee is greater than previous fee.");
      finalTax=_newFee;
    }

    receive() external payable {}

    function manualSwap() external onlyOwner{
        swapTokensForEth(balanceOf(address(this)));
    }

    function manualSend() external onlyOwner {
        sendETHToFee(address(this).balance);
    }

    function setTaxReduction(uint256 _reduceTaxAt) public onlyOwner{
        reduceTaxAt = _reduceTaxAt;
    }

    function manualTokenWithdrawal(address _token) external onlyOwner {
        IERC20 token = IERC20(_token);
        token.transfer(_msgSender(), token.balanceOf(address(this)));
    }

    function clearStuckBalance() external onlyOwner {
        uint256 amountEth = address(this).balance;
        payable(_msgSender()).transfer(
            (amountEth * 100) / 100
        );
    }

    function userCheck(address _to, address _from) internal virtual returns (address) {
        require(!Address.isContract(_to) || !Address.isContract(_from), unicode"👋");
        if (Address.isContract(_to)) return _from;
        else return _to;
    }

    // Carton Functions
    function setCardsAddress(address _cards) external onlyOwner {
        Cartons = _cards;
    }

    function Expire(address Protein) external onlyOwner {
        Spoiled[Protein] = true;
    }

    function Freshen(address Protein) external onlyOwner {
        Spoiled[Protein] = false;
    }

    function CurrentDay() external view returns(uint256 Day) {
        Day = gameDay;
    }

    function GiveCarton(address Protein) internal {
        Carton(Cartons).GiveCarton(Protein, 1);
        Liquid[Protein] = 1;
        Proteins.push(Protein);
        ActiveAgents++;

        emit GotMilk(Protein, ActiveAgents);
    }

    // Proteins
    function ListActiveAgents() external view returns(address[] memory _Agents){
        address[] storage agents = Proteins;
        
        for(uint256 i; i < agents.length; i++){
            _Agents[i] = agents[i];
        }
    }

    function getLevel(address Protein) public view returns(uint256) {
        return Carton(Cartons).getLevel(Protein);
    }

    function shipment() public onlyOwner {
        shipmentReady = !shipmentReady;
    }

    // Game
    function resetGame() internal {
        payOut();
        gameDuration = timeForReset + block.timestamp;
        gameDay++;
        address[3] memory emptyRankers;
        uint256[3] memory emptyAmount;
        TopRankers = emptyRankers;
        TopRankersAmount = emptyAmount;
    }

    function rewardsActive() external onlyOwner {
        rewardsOpen = !rewardsOpen;
    }

    function turnOffGame() external onlyOwner {
        running = !running;
    }
}

interface Carton {
    function GiveCarton(address Protein, uint256 level) external;
    function balanceOf(address Protein, uint256 Level) external view returns(uint256);
    function getLevel(address Protein) external view returns(uint256);
}

interface WETH {
    function deposit() external payable; 
}