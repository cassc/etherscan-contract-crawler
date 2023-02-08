// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/IDEXRouter.sol";
import "./interfaces/IDEXFactory.sol";
import "./interfaces/InterfaceLP.sol";

contract Accumulator is Initializable, OwnableUpgradeable, IERC20MetadataUpgradeable {

    string private _name;
    string private _symbol;
    uint8  private _decimals;

    uint256 public  MAX_UINT256;
    uint256 public  MAX_SUPPLY;
    uint256 public  INITIAL_FRAGMENTS_SUPPLY;
    uint256 public  TOTAL_GONS;
    
    uint256 private _totalSupply;
    uint256 private _gonsPerFragment;
    mapping(address => uint256) private _gonBalances;
    mapping(address => mapping(address => uint256)) private _allowedFragments;

    IDEXRouter public router;
    address public pairBUSD;
    address public pairBNB;
    address public busdToken;
    mapping(address => bool) public blackList;
    address[] public _markerPairs;
    mapping(address => bool) public automatedMarketMakerPairs;

    
    bool public autoRebase;
    uint256 public rebaseInitTime;
    uint256 public lastRebasedTime;
    uint256 public rebaseRateDenominator;
    mapping(uint256 => uint256) public rebaseStageRate;


    address public psmTreasury;
    address public ptTreasury;
    address public gwTreasury;
    address DEAD;
    address ZERO;
    
    bool inSwap;
    bool public swapEnabled;
    uint256 public swapBackLimit;
    
    mapping(address => bool) private _isFeeExempt;
    mapping(uint256 => mapping(uint256 => uint256)) public tradeFee;
    mapping(uint256 => mapping(uint256 => uint256)) public psmFee;
    mapping(uint256 => mapping(uint256 => uint256)) public ptFee;
    mapping(uint256 => mapping(uint256 => uint256)) public lpFee;

    uint256 public psmDump;
    uint256 public ptDump;
    uint256 public lpDump;

    uint256 public feeDenominator;
    
    modifier swapping() {
        require (inSwap == false, "ReentrancyGuard: reentrant call");
        inSwap = true;
        _;
        inSwap = false;
    }
    
    function initialize() public initializer {

        __Ownable_init();

        _name = "Accumulator";
        _symbol = "ACCU";
        _decimals = 18;

        psmTreasury = 0x661B941969e8e358E29461b60f451c9416336989;
        ptTreasury  = 0x53D2351da23FC86a1aB64128Acc18dA6963EacbB;
        gwTreasury  = 0x05E327095FaB8C03838CBf718edd4Cf3AD6173f5;
        busdToken   = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

        router = IDEXRouter(0x39255DA12f96Bb587c7ea7F22Eead8087b0a59ae);
        // pairBUSD = IDEXFactory(router.factory()).createPair(
        //     address(this),
        //     busdToken
        // );

        // pairBNB = IDEXFactory(router.factory()).createPair(
        //     address(this),
        //     router.WETH()
        // );

        MAX_UINT256 = type(uint256).max;
        MAX_SUPPLY = type(uint128).max;
        INITIAL_FRAGMENTS_SUPPLY = 21 * 10**5 * 10**18;
        TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonsPerFragment = TOTAL_GONS / _totalSupply;
        _gonBalances[msg.sender] = 20 * 10**5 * 10**18 * _gonsPerFragment;
        _gonBalances[gwTreasury] = 10**5 * 10**18 * _gonsPerFragment;

        _allowedFragments[address(this)][address(this)] = type(uint256).max;
        _allowedFragments[address(this)][address(router)] = type(uint256).max;
        // _allowedFragments[address(this)][pairBUSD] = type(uint256).max;
        // _allowedFragments[address(this)][pairBNB] = type(uint256).max;

        IERC20Upgradeable(busdToken).approve(address(this), type(uint256).max);
        IERC20Upgradeable(busdToken).approve(address(router), type(uint256).max);
        // IERC20Upgradeable(busdToken).approve(address(pairBUSD), type(uint256).max);
        // IERC20Upgradeable(busdToken).approve(address(pairBNB), type(uint256).max);

        _isFeeExempt[msg.sender] = true;
        _isFeeExempt[address(this)] = true;
        _isFeeExempt[psmTreasury] = true;
        _isFeeExempt[ptTreasury] = true;
        _isFeeExempt[gwTreasury] = true;

        rebaseInitTime = block.timestamp;
        lastRebasedTime = block.timestamp;
        DEAD = 0x000000000000000000000000000000000000dEaD;
        ZERO = 0x0000000000000000000000000000000000000000;

        autoRebase = false;
        swapEnabled = false;
        feeDenominator = 100;
        rebaseRateDenominator = 10 ** 30;

        emit Transfer(address(0x0), msg.sender, 20 * 10**5 * 10**18);
    }

    receive() external payable {}

    function name() external view override returns(string memory) {
        return _name;
    }

    function symbol() external view override returns(string memory) {
        return _symbol;
    }

    function decimals() external view override returns(uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _gonBalances[account] / _gonsPerFragment;
    }

    function transfer(address to, uint256 amount) external override returns(bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowedFragments[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool) {

        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private returns (bool) {

        require(!blackList[sender] && !blackList[recipient], "blackList");

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (shouldSwapBack()) {
            swapBack();
        }

        if (shouldRebase()) {
            _rebase();

            if (
                !automatedMarketMakerPairs[sender] &&
                !automatedMarketMakerPairs[recipient]
            ) {
                manualSync();
            }
        }

        uint256 gonAmount = amount * _gonsPerFragment;

        _gonBalances[sender] = _gonBalances[sender] - gonAmount;

        uint256 gonAmountReceived = shouldTakeFee(sender, recipient)
            ? takeFee(sender, recipient, gonAmount)
            : gonAmount;
        _gonBalances[recipient] = _gonBalances[recipient] + gonAmountReceived;

        emit Transfer(
            sender,
            recipient,
            gonAmountReceived / _gonsPerFragment
        );

        return true;
    }

    function mint(address account, uint256 amount) external onlyOwner{
        _mint(account, amount);
    }

    function _mint(address account, uint256 amount) private {

        _totalSupply += amount * 10**18;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _gonBalances[account] += amount * 10**18 * _gonsPerFragment;
        }
        emit Transfer(address(0), account, amount);
    }

    function _basicTransfer(
        address from,
        address to,
        uint256 amount
    ) private returns (bool) {
        uint256 gonAmount = amount * _gonsPerFragment;
        _gonBalances[from] = _gonBalances[from] - gonAmount;
        _gonBalances[to] = _gonBalances[to] + gonAmount;

        emit Transfer(from, to, amount);

        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowedFragments[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) private {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _rebase() private {

        uint256 cTimeStamp = block.timestamp;
        uint256 cTimes;
        uint256 pTimes;
        uint256 scId = _getPresentStage(cTimeStamp);
        uint256 spId = _getPresentStage(lastRebasedTime);

        if(scId == spId) {
            cTimes = (cTimeStamp - lastRebasedTime) / 30 minutes;
        } else {
            cTimes = (cTimeStamp - rebaseInitTime - (scId + 1) * 1 weeks) / 30 minutes;
            pTimes = (rebaseInitTime + (scId + 1) * 1 weeks - lastRebasedTime) / 30 minutes;
        }

        for(uint256 i = 0; i < pTimes; i ++) {
            _totalSupply += _totalSupply * rebaseStageRate[spId] / rebaseRateDenominator;
        }

        for(uint256 i = 0; i < cTimes; i ++) {
            _totalSupply += _totalSupply * rebaseStageRate[scId] / rebaseRateDenominator;
        }

        if(_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _gonsPerFragment = TOTAL_GONS / _totalSupply;
        lastRebasedTime += (cTimes + pTimes) * 30 minutes;
        emit LogRebase(cTimeStamp, _totalSupply);
    }

    function _getPresentStage(uint256 currentT) public view returns(uint256) {
        for(uint256 i = 0; i < 5; i++) {
            if(currentT <= rebaseInitTime + 2 weeks * (i + 1)) return i;
        }
    }

    function manualRebase() external {
        
        require(!inSwap, "Try again");
        require(block.timestamp >= lastRebasedTime + 30 minutes, "Not in time");
        
        _rebase();
        manualSync();
    }

    function shouldRebase() internal view returns (bool) {
        return 
            autoRebase &&
            !inSwap &&
            block.timestamp >= lastRebasedTime + 30 minutes;
    }

    function shouldTakeFee(address from, address to)
        internal
        view
        returns (bool)
    {
        return !_isFeeExempt[from] && !_isFeeExempt[to] && 
               (automatedMarketMakerPairs[from] || automatedMarketMakerPairs[to]);
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            !automatedMarketMakerPairs[msg.sender] &&
            !inSwap &&
            swapEnabled &&
            _gonBalances[address(this)] >= swapBackLimit * _gonsPerFragment;
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 gonAmount
    ) internal returns (uint256) {

        uint256 sId = _getPresentStage(block.timestamp);
        uint256 tId = 0;
        uint256 feeAmount;

        if(automatedMarketMakerPairs[recipient]) tId = 1;
        feeAmount = gonAmount * tradeFee[sId][tId] / feeDenominator;

        if(tId == 0) {
            lpDump += feeAmount * lpFee[sId][tId] / feeDenominator;
            ptDump += feeAmount * ptFee[sId][tId] / feeDenominator;
        } else {
            psmDump += feeAmount * psmFee[sId][tId] / feeDenominator;
            ptDump  += feeAmount * ptFee[sId][tId] / feeDenominator;
        }

        _gonBalances[address(this)] = _gonBalances[address(this)] + feeAmount;

        emit Transfer(sender, address(this), feeAmount / _gonsPerFragment);
        return gonAmount - feeAmount;
    }

    function swapBack() internal swapping {

        uint256 ctAmount = _gonBalances[address(this)] / _gonsPerFragment;

        require(ctAmount >= swapBackLimit, "Below threshold");

        if(psmDump > 0) {
            _swapTokensForBusd(psmDump / _gonsPerFragment, psmTreasury);
            psmDump = 0;
        }

        if(ptDump > 0) {
            _swapTokensForBusd(ptDump / _gonsPerFragment, ptTreasury);
            ptDump = 0;
        }

        if(lpDump > 0) {
            _swapAndLiquify(lpDump / _gonsPerFragment);
            lpDump = 0;
        }

        emit SwapBack(
            ctAmount,
            psmDump,
            ptDump,
            lpDump
        );
    }

    function _swapTokensForBusd(uint256 tokenAmount, address receiver) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = router.WETH();
        path[2] = busdToken;

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            receiver,
            block.timestamp
        );
    }

    function _swapAndLiquify(uint256 _amount) private {
        
        _mint(address(this), _amount);
        uint256 initValue = IERC20Upgradeable(busdToken).balanceOf(address(this));

        _swapTokensForBusd(_amount, address(this));

        uint256 _amountBUSD = IERC20Upgradeable(busdToken).balanceOf(address(this)) - initValue;

        _addLiquidityBUSD(_amount, _amountBUSD);

        emit SwapAndLiquifyBusd(_amount, _amountBUSD);
    }

    function _addLiquidityBUSD(uint256 tokenAmount, uint256 busdAmount)
        private
    {
        router.addLiquidity(
            address(this),
            busdToken,
            tokenAmount,
            busdAmount,
            0,
            0,
            ptTreasury,
            block.timestamp
        );
    }

    function manualSync() public {
        for(uint256 i = 0; i < _markerPairs.length; i ++) {
            InterfaceLP(_markerPairs[i]).sync();
        }
    }

    function setBlackList(address account, bool value) external onlyOwner {
        blackList[account] = value;
    }

    function setAutomatedMarketMakerPair(address _pair, bool _value) external onlyOwner
    {
        require(
            automatedMarketMakerPairs[_pair] != _value,
            "Already set"
        );

        automatedMarketMakerPairs[_pair] = _value;

        if (_value) {
            _markerPairs.push(_pair);
        } else {
            require(_markerPairs.length > 1, "Required 1 pair");
            for (uint256 i = 0; i < _markerPairs.length; i++) {
                if (_markerPairs[i] == _pair) {
                    _markerPairs[i] = _markerPairs[_markerPairs.length - 1];
                    _markerPairs.pop();
                    break;
                }
            }
        }
    }


    function setFeeExempt(address _addr, bool _value) external onlyOwner {
        _isFeeExempt[_addr] = _value;
    }

    function setAutoRebase(bool _enabled) external onlyOwner {
        autoRebase = _enabled;
    }

    function setSwapBackSettings(address _pairBUSD, address _pairBNB, bool _enabled, uint256 _amount) external onlyOwner {
        pairBUSD = _pairBUSD;
        pairBNB = _pairBNB;
        swapEnabled = _enabled;
        swapBackLimit = _amount;
    }

    function setFeeReceivers(address _psm, address _pt, address _gw) external onlyOwner {
        psmTreasury = _psm;
        ptTreasury = _pt;
        gwTreasury = _gw;
    }

    function checkFeeExempt(address _addr) external view returns (bool) {
        return _isFeeExempt[_addr];
    }

    function setRebaseRate(uint256 _stage, uint256 _value) external onlyOwner {
        rebaseStageRate[_stage] = _value;
    }

    function setTradeFee(uint256 _stage, uint256 _trade, uint256 _value) external onlyOwner {
        tradeFee[_stage][_trade] = _value;
    }

    function setPSMFee(uint256 _stage, uint256 _trade, uint256 _value) external onlyOwner {
        psmFee[_stage][_trade] = _value;
    }

    function setPtFee(uint256 _stage, uint256 _trade, uint256 _value) external onlyOwner {
        ptFee[_stage][_trade] = _value;
    }

    function setLpFee(uint256 _stage, uint256 _trade, uint256 _value) external onlyOwner {
        lpFee[_stage][_trade] = _value;
    }

    event SwapBack(
        uint256 contractTokenBalance,
        uint256 psmDumpAmount,
        uint256 ptDumpAmount,
        uint256 lpDumpAmount
    );
    event SwapAndLiquifyBusd(
        uint256 tokensSwapped,
        uint256 busdReceived
    );

    event LogRebase(uint256 indexed epoch, uint256 totalSupply);
    event ManualRebase(int256 supplyDelta);
}