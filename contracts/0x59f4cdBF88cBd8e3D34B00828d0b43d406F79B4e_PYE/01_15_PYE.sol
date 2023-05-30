// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Arrays.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IPYESwapFactory.sol";
import "./interfaces/IPYESwapRouter.sol";
import "./interfaces/IStakingContract.sol";


contract PYE is Context, ERC20, Ownable {

    // allows easy determination of actual msg.sender in meta-transactions
    using Address for address;
    // declare SafeMath useage so compiler recognizes SafeMath syntax
    using SafeMath for uint256;

//--------------------------------------BEGIN FEE INFO---------|

     // Fees
    struct Fees {
        uint256 reflectionFee;
        uint256 developmentFee;
        uint256 buybackFee;
        address developmentAddress;
    }

    // Transaction fee values
    struct FeeValues {
        uint256 transferAmount;
        uint256 reflection;
        uint256 development;
        uint256 buyBack;
    }

    // instantiating new Fees structs (see struct Fees above)
    Fees private _defaultFees;
    Fees public _buyFees;
    Fees private _previousFees;
    Fees private _emptyFees;
    Fees public _sellFees;
    Fees private _outsideBuyFees;
    Fees private _outsideSellFees;

//--------------------------------------BEGIN MAPPINGS---------|

    // user mappings for token balances and spending allowances. 
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    // user states governing fee exclusion, blacklist status, Reward exempt (meaning no reflection entitlement)
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isRewardExempt;
    mapping (address => bool) isBlacklisted;

    // Pair Details
    mapping (uint256 => address) private pairs;
    mapping (uint256 => address) private tokens;
    uint256 private pairsLength;
    mapping (address => bool) public _isPairAddress;
    // Outside Swap Pairs
    mapping (address => bool) private _includeSwapFee;
    // Staking Contracts
    mapping (address => bool) public isStakingContract;
    // Allowed Callers of Snapshot()
    mapping (address => bool) public isSnapshotter;

//--------------------------------------BEGIN TOKEN PARAMS---------|

    // token details.
    // tTotal is the total token supply (100 mil with 9 decimals)
    string constant _name = "PYE";
    string constant _symbol = "PYE";
    uint8 constant _decimals = 9;
    uint256 private constant _tTotal = 100000000 * (10 ** _decimals);

//--------------------------------------BEGIN TOKEN STAKED INFO---------|

    struct Staked {
        uint256 amount;
    }

    address[] holders;
    mapping (address => uint256) holderIndexes;
    mapping (address => Staked) public staked;

    uint256 public totalStaked;

//--------------------------------------BEGIN ROUTER, WETH, BURN ADDRESS INFO---------|

    IPYESwapRouter public pyeSwapRouter;
    address public pyeSwapPair;
    address public WETH;
    address public USDC;
    address public constant _burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 public _maxTxAmount = 5 * 10**8 * 10**9;


//--------------------------------------BEGIN BUYBACK VARIABLES---------|

    // auto set buyback to false. additional buyback params. blockPeriod acts as a time delay in the shouldAutoBuyback(). Last uint represents last block for buyback occurance.
    bool public autoBuybackEnabled = false;
    uint256 autoBuybackCap;
    uint256 autoBuybackAccumulator;
    uint256 public autoBuybackAmount;
    uint256 autoBuybackBlockPeriod;
    uint256 autoBuybackBlockLast;
    uint256 minimumBuyBackThreshold = _tTotal / 1000000; // 0.0001%

//--------------------------------------STAKING CONT. INSTANCES---------|

    IStakingContract public StakingContract;
    address public stakingContract;

    uint256 distributorGas = 500000;

//--------------------------------------BEGIN SWAP INFO---------|

    bool inSwap;

    // function modifiers handling swap status
    modifier swapping() { inSwap = true; _; inSwap = false; }
    modifier onlyExchange() {
        bool isPair = false;
        for(uint i = 0; i < pairsLength; i++) {
            if(pairs[i] == msg.sender) isPair = true;
        }
        require(
            msg.sender == address(pyeSwapRouter)
            || isPair
            , "PYE: NOT_ALLOWED"
        );
        _;
    }

//--------------------------------------BEGIN CONSTRUCTOR AND RECEIVE FUNCTION---------|    

    constructor() ERC20("PYE", "PYE") {
        _balances[_msgSender()] = _tTotal;

        pyeSwapRouter = IPYESwapRouter(0x3b505Af97031B75e2be39e7F8FA1Fa634857f29D);
        WETH = pyeSwapRouter.WETH();
        USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        pyeSwapPair = IPYESwapFactory(pyeSwapRouter.factory()).createPair(address(this), WETH, true, address(this));
       
        tokens[pairsLength] = WETH;
        pairs[pairsLength] = pyeSwapPair;
        pairsLength += 1;
        _isPairAddress[pyeSwapPair] = true;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[pyeSwapPair] = true;
        _isExcludedFromFee[stakingContract] = true;

        isTxLimitExempt[_msgSender()] = true;
        isTxLimitExempt[pyeSwapPair] = true;
        isTxLimitExempt[address(pyeSwapRouter)] = true;
        isTxLimitExempt[stakingContract] = true;

        isRewardExempt[_msgSender()] = true;
        isRewardExempt[pyeSwapPair] = true;
        isRewardExempt[address(this)] = true;
        isRewardExempt[_burnAddress] = true;
        isRewardExempt[stakingContract] = true;

        isSnapshotter[msg.sender] = true;

        _defaultFees = Fees(
            800,
            200,
            0,
            0x99b4e1F2B2a3a17CA890b992B892ABCCd44E0c9a
        );

        _buyFees = Fees(
            800,
            200,
            0,
            0x99b4e1F2B2a3a17CA890b992B892ABCCd44E0c9a
        );

        _sellFees = Fees(
            1800,
            200,
            0,
            0x99b4e1F2B2a3a17CA890b992B892ABCCd44E0c9a
        );

        _outsideBuyFees = Fees(
            800,
            200,
            0,
            0x99b4e1F2B2a3a17CA890b992B892ABCCd44E0c9a
        );

        _outsideSellFees = Fees(
            1800,
            200,
            0,
            0x99b4e1F2B2a3a17CA890b992B892ABCCd44E0c9a
        );
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    //to receive ETH from pyeRouter when swapping
    receive() external payable {}

//--------------------------------------BEGIN BLACKLIST FUNCTIONS---------|

    // enter an address to blacklist it. This blocks transfers TO that address. Balcklisted members can still sell.
    function blacklistAddress(address addressToBlacklist) public onlyOwner {
        require(!isBlacklisted[addressToBlacklist] , "Address is already blacklisted!");
        isBlacklisted[addressToBlacklist] = true;
    }

    // enter a currently blacklisted address to un-blacklist it.
    function removeFromBlacklist(address addressToRemove) public onlyOwner {
        require(isBlacklisted[addressToRemove] , "Address has not been blacklisted! Enter an address that is on the blacklist.");
        isBlacklisted[addressToRemove] = false;
    }

//--------------------------------------BEGIN TOKEN GETTER FUNCTIONS---------|

    // decimal return fxn is explicitly stated to override the std. ERC-20 decimals() fxn which is programmed to return uint 18, but
    // PYE has 9 decimals.
    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    // totalSupply return fxn is explicitly stated to override the std. ERC-20 totalSupply() fxn which is programmed to return a uint "totalSupply", but
    // PYE uses "_tTotal" variable to define total token supply, 
    function totalSupply() public pure override(ERC20) returns (uint256) {
        return _tTotal;
    }

    // balanceOf function displays the tokens in the specified account wallet.
    function balanceOf(address account) public view override(ERC20) returns (uint256) {
        return _balances[account];
    }

    // returns the owned amount of tokens, including tokens that are staked in main pool. Balance qualifies for tier privileges.
    function getOwnedBalance(address account) public view returns (uint256){
        return staked[account].amount.add(_balances[account]);
    }

    // returns the circulating token supply minus the balance in the burn address (0x00..dEAD) and the balance in address(0) (0x00...00)
    function getCirculatingSupply() public view returns (uint256) {
        return _tTotal.sub(balanceOf(_burnAddress)).sub(balanceOf(address(0)));
    }

//--------------------------------------BEGIN TOKEN PAIR FUNCTIONS---------|

    // returns the index of paired tokens
    function _getTokenIndex(address _token) internal view returns (uint256) {
        uint256 index = pairsLength + 1;
        for(uint256 i = 0; i < pairsLength; i++) {
            if(tokens[i] == _token) index = i;
        }

        return index;
    }

    // check if a pair of tokens are paired
    function _checkPairRegistered(address _pair) internal view returns (bool) {
        bool isPair = false;
        for(uint i = 0; i < pairsLength; i++) {
            if(pairs[i] == _pair) isPair = true;
        }

        return isPair;
    }

    function addPair(address _pair, address _token) public {
        address factory = pyeSwapRouter.factory();
        require(
            msg.sender == factory
            || msg.sender == address(pyeSwapRouter)
            || msg.sender == address(this)
        , "PYE: NOT_ALLOWED"
        );

        if(!_checkPairRegistered(_pair)) {
            _isExcludedFromFee[_pair] = true;
            _isPairAddress[_pair] = true;
            isTxLimitExempt[_pair] = true;
            isRewardExempt[_pair] = true;

            pairs[pairsLength] = _pair;
            tokens[pairsLength] = _token;

            pairsLength += 1;
        }
    }

    function addOutsideSwapPair(address account) public onlyOwner {
        _includeSwapFee[account] = true;
    }

    function removeOutsideSwapPair(address account) public onlyOwner {
        _includeSwapFee[account] = false;
    }

    // set an address as a staking contract
    function setIsStakingContract(address account, bool set) external onlyOwner {
        isStakingContract[account] = set;
    }

//--------------------------------------BEGIN RESCUE FUNCTIONS---------|

    // Rescue eth that is sent here by mistake
    function rescueETH(uint256 amount, address to) external onlyOwner {
        payable(to).transfer(amount);
      }

    // Rescue tokens that are sent here by mistake
    function rescueToken(IERC20 token, uint256 amount, address to) external onlyOwner {
        if( token.balanceOf(address(this)) < amount ) {
            amount = token.balanceOf(address(this));
        }
        token.transfer(to, amount);
    }

//--------------------------------------BEGIN APPROVAL & ALLOWANCE FUNCTIONS---------|

     // allowance fxn is identical to ERC-20 allowance fxn. As per tommy's request, function is still explicity declared.
    function allowance(address owner, address spender) public view override(ERC20) returns (uint256) {
        return _allowances[owner][spender];
    }
    
    // approve fxn overrides std. ERC-20 approve() fxn which declares address owner = _msgSender(), whereas PYE approve() fxn does not.
    function approve(address spender, uint256 amount) public override(ERC20) returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    // added override tag, see same explanation for approve() function above.
    function increaseAllowance(address spender, uint256 addedValue) public override virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    
    // added override tag, see same explanation for approve() function above.
    function decreaseAllowance(address spender, uint256 subtractedValue) public override virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    // added override tag for error message clarity (BEP vs ERC), changed visibility from private to internal to avoid compiler errors.
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal override {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

//--------------------------------------BEGIN FEE FUNCTIONS---------|

    // get sum of all fees
    function getTotalFee(address account) public view returns (uint256) {
        if(_isExcludedFromFee[account]) {
            return 0;
        } else {
            return _defaultFees.reflectionFee
                .add(_defaultFees.developmentFee)
                .add(_defaultFees.buybackFee);
        }
    }

    function getFee() public view returns (uint256) {
        return _defaultFees.reflectionFee
            .add(_defaultFees.developmentFee)
            .add(_defaultFees.buybackFee);
    }

    // takes fees
    function _takeFees(FeeValues memory values) private {
        _takeFee(values.development.add(values.reflection), _defaultFees.developmentAddress);
        _takeFee(values.buyBack, _burnAddress);
    }

    // collects fees
    function _takeFee(uint256 tAmount, address recipient) private {
        if(recipient == address(0)) return;
        if(tAmount == 0) return;

        _balances[recipient] = _balances[recipient].add(tAmount);
    }

    // calculates the fee
    function calculateFee(uint256 _amount, uint256 _fee) private pure returns (uint256) {
        if(_fee == 0) return 0;
        return _amount.mul(_fee).div(
            10**4
        );
    }

    // restores all fees
    function restoreAllFee() private {
        _defaultFees = _previousFees;
    }

    // removes all fees
    function removeAllFee() private {
        _previousFees = _defaultFees;
        _defaultFees = _emptyFees;
    }

    function setSellFee() private {
        _defaultFees = _sellFees;
    }

    function setOutsideBuyFee() private {
        _previousFees = _defaultFees;
        _defaultFees = _outsideBuyFees;
    }

    function setOutsideSellFee() private {
        _previousFees = _defaultFees;
        _defaultFees = _outsideSellFees;
    }

    // shows whether or not an account is excluded from fees
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    // returns whether or not an entered address is entitled to rewards 
    function isExcludedFromReward(address account) public view returns (bool) {
        return isRewardExempt[account];
    }
    
    // allows Owner to make an address exempt from fees
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    // allows Owner to make an address incur fees
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    // allows Owner to change max TX percent
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10**4
        );
    }

    // set an address to be tx limit exempt
    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    // safety check for set tx limit
    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    // returns the specified values
    function _getValues(uint256 tAmount) private view returns (FeeValues memory) {
        FeeValues memory values = FeeValues(
            0,
            calculateFee(tAmount, _defaultFees.reflectionFee),
            calculateFee(tAmount, _defaultFees.developmentFee),
            calculateFee(tAmount, _defaultFees.buybackFee)
        );

        values.transferAmount = tAmount.sub(values.reflection).sub(values.development).sub(values.buyBack);
        return values;
    }

    
    function handleFee(uint256 amount, address token) public onlyExchange {
        if(amount == 0) {
            restoreAllFee(); 
        } else {
            uint256 tokenIndex = _getTokenIndex(token);
            if(tokenIndex < pairsLength) {
                uint256 allowanceT = IERC20(token).allowance(msg.sender, address(this));
                if(allowanceT >= amount) {
                    IERC20(token).transferFrom(msg.sender, address(this), amount);

                    if(token == USDC) {
                        uint256 totalFee = getFee();
                        uint256 developmentFeeAmount = amount.mul(_defaultFees.developmentFee).div(totalFee);
                        uint256 reflectionFeeAmount = amount.mul(_defaultFees.reflectionFee).div(totalFee);
                        uint256 buybackFeeAmount = amount.mul(_defaultFees.buybackFee).div(totalFee);

                        IERC20(token).transfer(stakingContract, reflectionFeeAmount);
                        try StakingContract.depositUSDCToStakingContract(reflectionFeeAmount) {} catch {}

                        uint256 balanceBefore = IERC20(address(WETH)).balanceOf(address(this));
                        uint256 amountToSwap = developmentFeeAmount.add(buybackFeeAmount);
                        uint256 totalFee2 = _defaultFees.developmentFee.add(_defaultFees.buybackFee);
                        swapToWETH(amountToSwap, token);
                        uint256 fAmount = IERC20(address(WETH)).balanceOf(address(this)).sub(balanceBefore);
                        uint256 developmentFeeAmount2 = fAmount.mul(_defaultFees.developmentFee).div(totalFee2);

                        IERC20(WETH).transfer(_defaultFees.developmentAddress, developmentFeeAmount2);

                    } else if(token == WETH) {
                        // All fees to be declared here in order to be calculated and sent
                        uint256 totalFee = getFee();
                        uint256 developmentFeeAmount = amount.mul(_defaultFees.developmentFee).div(totalFee);
                        uint256 reflectionFeeAmount = amount.mul(_defaultFees.reflectionFee).div(totalFee);

                        uint256 balanceBefore = IERC20(address(USDC)).balanceOf(address(this));
                        swapToUSDC(reflectionFeeAmount, token);
                        uint256 reflectionUSDCFeeAmount = IERC20(address(USDC)).balanceOf(address(this)).sub(balanceBefore);
                        IERC20(token).transfer(_defaultFees.developmentAddress, developmentFeeAmount);

                        IERC20(USDC).transfer(stakingContract, reflectionUSDCFeeAmount);
                        try StakingContract.depositUSDCToStakingContract(reflectionUSDCFeeAmount) {} catch {}
                    
                    } else {
                        uint256 balanceBefore = IERC20(address(WETH)).balanceOf(address(this));
                        swapToWETH(amount, token);
                        uint256 fAmount = IERC20(address(WETH)).balanceOf(address(this)).sub(balanceBefore);
                        
                        // All fees to be declared here in order to be calculated and sent
                        uint256 totalFee = getFee();
                        uint256 developmentFeeAmount = fAmount.mul(_defaultFees.developmentFee).div(totalFee);
                        uint256 reflectionFeeAmount = fAmount.mul(_defaultFees.reflectionFee).div(totalFee);

                        uint256 balanceUSDCBefore = IERC20(address(USDC)).balanceOf(address(this));
                        swapToUSDC(reflectionFeeAmount, token);
                        uint256 reflectionUSDCFeeAmount = IERC20(address(USDC)).balanceOf(address(this)).sub(balanceUSDCBefore);

                        IERC20(WETH).transfer(_defaultFees.developmentAddress, developmentFeeAmount);

                        IERC20(USDC).transfer(stakingContract, reflectionUSDCFeeAmount);
                        try StakingContract.depositUSDCToStakingContract(reflectionUSDCFeeAmount) {} catch {}
                    }

                    restoreAllFee(); 
                }
            }
        }
    }

    function swapToUSDC(uint256 amount, address token) internal {
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = USDC;

        IERC20(token).approve(address(pyeSwapRouter), amount);
        pyeSwapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function swapToWETH(uint256 amount, address token) internal {
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = WETH;

        IERC20(token).approve(address(pyeSwapRouter), amount);
        pyeSwapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    // allows user to set an address as Reward exempt
    function setIsRewardExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this) && holder != pyeSwapPair);
        isRewardExempt[holder] = exempt;
        if(exempt){
            setStaked(holder, 0);
        }else{
            setStaked(holder, _balances[holder]);
        }
    }

    // set fee values on buys
    function setBuyFees(uint256 _reflectionFee, uint256 _developmentFee, uint256 _buybackFee) external onlyOwner {
        _defaultFees.reflectionFee = _reflectionFee;
        _defaultFees.developmentFee = _developmentFee;
        _defaultFees.buybackFee = _buybackFee;

        _buyFees.reflectionFee = _reflectionFee;
        _buyFees.developmentFee = _developmentFee;
        _buyFees.buybackFee = _buybackFee;

        _outsideBuyFees.reflectionFee = _reflectionFee;
        _outsideBuyFees.developmentFee = _developmentFee;
        _outsideBuyFees.buybackFee = _buybackFee;
    }

    // set fee values on sells
    function setSellFees(uint256 _reflectionFee, uint256 _developmentFee, uint256 _buybackFee) external onlyOwner {
        _sellFees.reflectionFee = _reflectionFee;
        _sellFees.developmentFee = _developmentFee;
        _sellFees.buybackFee = _buybackFee;

        _outsideSellFees.reflectionFee = _reflectionFee;
        _outsideSellFees.developmentFee = _developmentFee;  
        _outsideSellFees.buybackFee = _buybackFee;
    }

//--------------------------------------BEGIN SET ADDRESS FUNCTIONS---------|

    // manually set development address
    function setDevelopmentAddress(address _development) external onlyOwner {
        require(_development != address(0), "PYE: Address Zero is not allowed");
        _defaultFees.developmentAddress = _development;
        _buyFees.developmentAddress = _development;
        _sellFees.developmentAddress = _development;
        _outsideBuyFees.developmentAddress = _development;
        _outsideSellFees.developmentAddress = _development;
    }

    function setNewStakingContract(address _newStakingContract) external onlyOwner {
        stakingContract = (_newStakingContract);
        StakingContract = IStakingContract(_newStakingContract);

        isTxLimitExempt[_newStakingContract] = true;
        isRewardExempt[_newStakingContract] = true;
        _isExcludedFromFee[_newStakingContract] = true;
        isStakingContract[_newStakingContract] = true;
    }

//--------------------------------------BEGIN STAKED BALANCE FUNCTIONS---------|

    function setStaked(address holder, uint256 amount) internal  {
        if(amount > 0 && staked[holder].amount == 0){
            addHolder(holder);
        }else if(amount == 0 && staked[holder].amount > 0){
            removeHolder(holder);
        }

        totalStaked = totalStaked.sub(staked[holder].amount).add(amount);
        staked[holder].amount = amount;
    }

    function addHolder(address holder) internal {
        holderIndexes[holder] = holders.length;
        holders.push(holder);
    }

    function removeHolder(address holder) internal {
        holders[holderIndexes[holder]] = holders[holders.length-1];
        holderIndexes[holders[holders.length-1]] = holderIndexes[holder];
        holders.pop();
    }

//--------------------------------------BEGIN BUYBACK FUNCTIONS---------|

    // runs check to see if autobuyback should trigger
    function shouldAutoBuyback(uint256 amount) internal view returns (bool) {
        return msg.sender != pyeSwapPair
        && !inSwap
        && autoBuybackEnabled
        && autoBuybackBlockLast + autoBuybackBlockPeriod <= block.number // After N blocks from last buyback
        && IERC20(address(WETH)).balanceOf(address(this)) >= autoBuybackAmount
        && amount >= minimumBuyBackThreshold;
    }


    // triggers auto buyback
    function triggerAutoBuyback() internal {
        buyTokens(autoBuybackAmount, _burnAddress);
        autoBuybackBlockLast = block.number;
        autoBuybackAccumulator = autoBuybackAccumulator.add(autoBuybackAmount);
        if(autoBuybackAccumulator > autoBuybackCap){ autoBuybackEnabled = false; }
    }

    // logic to purchase PYE tokens
    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(this);

        IERC20(WETH).approve(address(pyeSwapRouter), amount);
        pyeSwapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            to,
            block.timestamp
        );
    }

    function triggerManualBuyback(uint256 _amount) public onlyOwner {
        uint256 contractBalance = IERC20(WETH).balanceOf(address(this));
        require(_amount <= contractBalance , "Amount exceeds contract balance");
        buyTokens(_amount, _burnAddress);
    }

    // manually adjust the buyback settings to suit your needs
    function setAutoBuybackSettings(bool _enabled, uint256 _cap, uint256 _amount, uint256 _period) external onlyOwner {
        autoBuybackEnabled = _enabled;
        autoBuybackCap = _cap;
        autoBuybackAccumulator = 0;
        autoBuybackAmount = _amount;
        autoBuybackBlockPeriod = _period;
        autoBuybackBlockLast = block.number;
    }

    // manually adjust minimumBuyBackThreshold Denominator. Threshold will be tTotal divided by Denominator. default 1000000 or .0001%
    function setBuyBackThreshold(uint256 thresholdDenominator) external onlyOwner {
        minimumBuyBackThreshold = _tTotal / thresholdDenominator;
    }

//--------------------------------------BEGIN ROUTER FUNCTIONS---------|

    function updateRouterAndPair(address _router, address _pair) public onlyOwner {
        _isExcludedFromFee[address(pyeSwapRouter)] = false;
        _isExcludedFromFee[pyeSwapPair] = false;
        pyeSwapRouter = IPYESwapRouter(_router);
        pyeSwapPair = _pair;
        WETH = pyeSwapRouter.WETH();

        _isExcludedFromFee[address(pyeSwapRouter)] = true;
        _isExcludedFromFee[pyeSwapPair] = true;

        isRewardExempt[pyeSwapPair] = true;

        _isPairAddress[pyeSwapPair] = true;
        

        isTxLimitExempt[pyeSwapPair] = true;
        isTxLimitExempt[address(pyeSwapRouter)] = true;

        pairs[0] = pyeSwapPair;
        tokens[0] = WETH;
    }

//--------------------------------------BEGIN TRANSFER FUNCTIONS---------|

    // transfer fxn is explicitly stated to override the std. ERC-20 transfer fxn which uses "to" param, but
    // PYE uses "recipient" param.
    function transfer(address recipient, uint256 amount) public override(ERC20) returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    // transferFrom explicitly stated and overrides ERC-20 std becasue of variable name differences.
    function transferFrom(address sender, address recipient, uint256 amount) public override(ERC20) returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

   function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!isBlacklisted[to]);
        _beforeTokenTransfer(from, to, amount);
        
        checkTxLimit(from, amount);

        if (shouldAutoBuyback(amount)) {
            triggerAutoBuyback();
        } 

        //indicates if fee should be deducted from transfer
        uint8 takeFee = 0;
        if(_isPairAddress[to] && from != address(pyeSwapRouter) && !isExcludedFromFee(from)) {
            takeFee = 1;
        } else if(_includeSwapFee[from]) {
            takeFee = 2;
        } else if(_includeSwapFee[to]) {
            takeFee = 3;
        }

        //transfer amount, it will take tax
        _tokenTransfer(from, to, amount, takeFee);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, uint8 takeFee) private {
        if(takeFee == 0 || takeFee == 1) {
            removeAllFee();

            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
            _balances[recipient] = _balances[recipient].add(amount);

            if(isStakingContract[recipient]) { 
                uint256 newAmountAdd = staked[sender].amount.add(amount);
                setStaked(sender, newAmountAdd);
            }

            if(isStakingContract[sender]) {
                uint256 newAmountSub = staked[recipient].amount.sub(amount);
                setStaked(recipient, newAmountSub);
            }

            emit Transfer(sender, recipient, amount);

            if(takeFee == 0) {
                restoreAllFee();
            } else if(takeFee == 1) {
                setSellFee();
            }
        } else {
            if(takeFee == 2) {
                setOutsideBuyFee();
            } else if(takeFee == 3) {
                setOutsideSellFee();
            }

            FeeValues memory _values = _getValues(amount);
            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
            _balances[recipient] = _balances[recipient].add(_values.transferAmount);
            _takeFees(_values);

            restoreAllFee();

            emit Transfer(sender, recipient, _values.transferAmount);
            emit Transfer(sender, _defaultFees.developmentAddress, _values.development.add(_values.reflection));
            emit Transfer(sender, _burnAddress, _values.buyBack);  
        }
    }


    //--------------------BEGIN MODIFIED SNAPSHOT FUNCITONALITY---------------

    // @dev a modified implementation of ERC20 Snapshot to keep track of staked balances + balanceOf. 
    // ERC20 Snapshot import/inheritance is avoided in this contract to avoid issues with interface conflicts and to directly control private 
    // functionality
    // copied from source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/ERC20Snapshot.sol

    using Arrays for uint256[];
    using Counters for Counters.Counter;
    Counters.Counter private _currentSnapshotId;

    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping(address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalSupplySnapshots;

    // @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
    event Snapshot(uint256 id);

    // owner grant and revoke Snapshotter role to account.
    function setIsSnapshotter(address account, bool flag) external onlyOwner {
        isSnapshotter[account] = flag;
    }

    // generate a snapshot, calls internal _snapshot().
    function snapshot() public {
        require(isSnapshotter[msg.sender], "Caller is not allowed to snapshot");
        _snapshot();
    }

    function _snapshot() internal returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _getCurrentSnapshotId();
        emit Snapshot(currentId);
        return currentId;
    }

    function _getCurrentSnapshotId() internal view returns (uint256) {
        return _currentSnapshotId.current();
    }

    function getCurrentSnapshotId() public view returns (uint256) {
        return _getCurrentSnapshotId();
    }

    // balOf + staked
    function balanceOfAt(address account, uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : (balanceOf(account) + staked[account].amount);
    }

    function totalSupplyAt(uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);

        return snapshotted ? value : totalSupply();
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots) private view returns (bool, uint256) {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        require(snapshotId <= _getCurrentSnapshotId(), "ERC20Snapshot: nonexistent id");

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) {
            // mint
            _updateAccountSnapshot(to);
            _updateTotalSupplySnapshot();
        } else if (to == address(0)) {
            // burn
            _updateAccountSnapshot(from);
            _updateTotalSupplySnapshot();
        } else if (isStakingContract[to]) { 
            // user is staking
            _updateAccountSnapshot(from);
        } else if (isStakingContract[from]) {
            // user is unstaking
            _updateAccountSnapshot(to);
        } else {
            // transfer
            _updateAccountSnapshot(from);
            _updateAccountSnapshot(to);
        }
    }

    // tracks staked and owned
    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], (balanceOf(account) + staked[account].amount));
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply());
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _getCurrentSnapshotId();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }
}