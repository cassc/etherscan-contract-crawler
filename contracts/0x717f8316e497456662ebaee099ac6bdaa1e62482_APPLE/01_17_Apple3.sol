// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Arrays.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IPYESwapFactory.sol";
import "./interfaces/IPYESwapRouter.sol";


contract APPLE is AccessControl, ERC20 {
    using SafeMath for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant FEE_SETTER_ROLE = keccak256("FEE_SETTER_ROLE");

    // staked struct	
    struct Staked {	
        uint256 amount;	
    }	
    address[] holders;	
    mapping (address => uint256) holderIndexes;	
    uint256 public totalStaked;

    // Fees
    // Add and remove fee types and destinations here as needed
    struct Fees {
        uint256 developmentFee;
        uint256 buybackFee;
        address developmentAddress;
    }

    // Transaction fee values
    // Add and remove fee value types here as needed
    struct FeeValues {
        uint256 transferAmount;
        uint256 development;
        uint256 buyback;
    }

    // Token details
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => Staked) public staked;

    // denylist and staking contract mappings	
    mapping (address => bool) isDenylisted; 	
    mapping (address => bool) isStakingContract; 
    
    // Allowed Callers of Snapshot()
    mapping (address => bool) public isSnapshotter;

    // Set total supply here
    uint256 private _tTotal;

    // Tracker for total burned amount
    uint256 private _bTotal;

    // auto set buyback to false. additional buyback params. blockPeriod acts as a time delay in the shouldAutoBuyback(). Last uint represents last block for buyback occurance.
    struct Settings {
        bool autoBuybackEnabled;
        uint256 autoBuybackCap;
        uint256 autoBuybackAccumulator;
        uint256 autoBuybackAmount;
        uint256 autoBuybackBlockPeriod;
        uint256 autoBuybackBlockLast;
        uint256 minimumBuyBackThreshold;
    }

    // Users states
    mapping (address => bool) private _isExcludedFromFee;

    // Outside Swap Pairs
    mapping (address => bool) private _includeSwapFee;


    // Pair Details
    mapping (uint256 => address) private pairs;
    mapping (uint256 => address) private tokens;
    uint256 private pairsLength;
    mapping (address => bool) public _isPairAddress;


    // Set the name, symbol, and decimals here
    string constant _name = "ApplePYE";
    string constant _symbol = "APPLEPYE";
    uint8 constant _decimals = 18;

    Fees private _defaultFees;
    Fees private _previousFees;
    Fees private _emptyFees;
    Fees public _buyFees;
    Fees public _sellFees;
    Fees private _outsideBuyFees;
    Fees private _outsideSellFees;

    Settings public _buyback;

    IPYESwapRouter public pyeSwapRouter;
    address public pyeSwapPair;
    address public WETH;
    address public constant _burnAddress = 0x000000000000000000000000000000000000dEaD;

    bool public swapEnabled = true;
    bool inSwap;

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


    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    // Edit the constructor in order to declare default fees on deployment
    constructor (address _router, address _development, uint256 _developmentFeeBuy, uint256 _buybackFeeBuy, uint256 _developmentFeeSell, uint256 _buybackFeeSell) ERC20("","") {
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(BURNER_ROLE, msg.sender);
        _setupRole(FEE_SETTER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        pyeSwapRouter = IPYESwapRouter(_router);
        WETH = pyeSwapRouter.WETH();
        pyeSwapPair = IPYESwapFactory(pyeSwapRouter.factory())
        .createPair(address(this), WETH, true, address(this));

        tokens[pairsLength] = WETH;
        pairs[pairsLength] = pyeSwapPair;
        pairsLength += 1;
        _isPairAddress[pyeSwapPair] = true;

        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[pyeSwapPair] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_burnAddress] = true;

        isSnapshotter[msg.sender] = true;

        // This should match the struct Fee
        _defaultFees = Fees(
            _developmentFeeBuy,
            _buybackFeeBuy,
            _development
        );

        _buyFees = Fees(
            _developmentFeeBuy,
            _buybackFeeBuy,
            _development
        );

        _sellFees = Fees(
            _developmentFeeSell,
            _buybackFeeSell,
            _development
        );

        _outsideBuyFees = Fees(
            _developmentFeeBuy.add(_buybackFeeBuy),
            0,
            _development
        );

        _outsideSellFees = Fees(
            _developmentFeeSell.add(_buybackFeeSell),
            0,
            _development
        );
    }

    function name() public pure override returns (string memory) {
        return _name;
    }

    function symbol() public pure override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function totalBurned() public view returns (uint256) {
        return _balances[_burnAddress].add(_bTotal);
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

    function increaseAllowance(address spender, uint256 addedValue) public virtual override returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual override returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function excludeFromFee(address account) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "APPLE: NOT_ALLOWED");
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "APPLE: NOT_ALLOWED");
        _isExcludedFromFee[account] = false;
    }

    function addOutsideSwapPair(address account) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "APPLE: NOT_ALLOWED");
        _includeSwapFee[account] = true;
    }

    function removeOutsideSwapPair(address account) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "APPLE: NOT_ALLOWED");
        _includeSwapFee[account] = false;
    }

    // Functions to update fees and addresses 

    function setBuyFees(uint256 _developmentFee, uint256 _buybackFee) external {
        require(hasRole(FEE_SETTER_ROLE, msg.sender), "APPLE: NOT_ALLOWED");
        require(_developmentFee.add(_buybackFee) <= 2500, "Fees exceed max limit");
        _defaultFees.developmentFee = _developmentFee;
        _defaultFees.buybackFee = _buybackFee;

        _buyFees.developmentFee = _developmentFee;
        _buyFees.buybackFee = _buybackFee;

        _outsideBuyFees.developmentFee = _developmentFee.add(_buybackFee);
    }

    function setSellFees(uint256 _developmentFee, uint256 _buybackFee) external {
        require(hasRole(FEE_SETTER_ROLE, msg.sender), "APPLE: NOT_ALLOWED");
        require(_developmentFee.add(_buybackFee) <= 2500, "Fees exceed max limit");
        _sellFees.developmentFee = _developmentFee;
        _sellFees.buybackFee = _buybackFee;

        _outsideSellFees.developmentFee = _developmentFee.add(_buybackFee);
    }

    function setdevelopmentAddress(address _development) external {
        require(hasRole(FEE_SETTER_ROLE, msg.sender), "APPLE: NOT_ALLOWED");
        require(_development != address(0), "PYE: Address Zero is not allowed");
        _defaultFees.developmentAddress = _development;
        _buyFees.developmentAddress = _development;
        _sellFees.developmentAddress = _development;
        _outsideBuyFees.developmentAddress = _development;
        _outsideSellFees.developmentAddress = _development;
    }

    function updateRouterAndPair(address _router, address _pair) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "APPLE: NOT_ALLOWED");
        _isExcludedFromFee[pyeSwapPair] = false;
        pyeSwapRouter = IPYESwapRouter(_router);
        pyeSwapPair = _pair;
        WETH = pyeSwapRouter.WETH();

        _isPairAddress[pyeSwapPair] = true;
        _isExcludedFromFee[pyeSwapPair] = true;

        pairs[0] = pyeSwapPair;
        tokens[0] = WETH;
    }

    //to receive ETH from pyeRouter when swapping
    receive() external payable {}

    function _getValues(uint256 tAmount) private view returns (FeeValues memory) {
        FeeValues memory values = FeeValues(
            0,
            calculateFee(tAmount, _defaultFees.developmentFee),
            calculateFee(tAmount, _defaultFees.buybackFee)
        );

        values.transferAmount = tAmount.sub(values.development).sub(values.buyback);
        return values;
    }

    function calculateFee(uint256 _amount, uint256 _fee) private pure returns (uint256) {
        if(_fee == 0) return 0;
        return _amount.mul(_fee).div(
            10**4
        );
    }

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

    function restoreAllFee() private {
        _defaultFees = _previousFees;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

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

    // function getBalance(address keeper) public view returns (uint256){
    //     return _balances[keeper];
    // }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!isDenylisted[to]);
        _beforeTokenTransfer(from, to, amount);

        if(shouldAutoBuyback(amount)){ triggerAutoBuyback(); }

        if(isStakingContract[to]) { 	
            uint256 newAmountAdd = staked[from].amount.add(amount);	
            setStaked(from, newAmountAdd);	
        }	
        if(isStakingContract[from]) {	
            uint256 newAmountSub = staked[to].amount.sub(amount);	
            setStaked(to, newAmountSub);	
        }

        //indicates if fee should be deducted from transfer of tokens
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

    function getCirculatingSupply() public view returns (uint256) {
        return _tTotal.sub(balanceOf(_burnAddress)).sub(balanceOf(address(0)));
    }

    function getTotalFee(address account) public view returns (uint256) {
        if(_isExcludedFromFee[account]) {
            return 0;
        } else {
        return _defaultFees.developmentFee
            .add(_defaultFees.buybackFee);
        }
    }

    function getFee() public view returns (uint256) {
        return _defaultFees.developmentFee
            .add(_defaultFees.buybackFee);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, uint8 takeFee) private {
        if(takeFee == 0 || takeFee == 1) {
            removeAllFee();

            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
            _balances[recipient] = _balances[recipient].add(amount);

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
            emit Transfer(sender, _defaultFees.developmentAddress, _values.development);

        }
    }

    function _takeFees(FeeValues memory values) private {
        _takeFee(values.development, _defaultFees.developmentAddress);
    }

    function _takeFee(uint256 tAmount, address recipient) private {
        if(recipient == address(0)) return;
        if(tAmount == 0) return;

        _balances[recipient] = _balances[recipient].add(tAmount);
    }

    // This function transfers the fees to the correct addresses. 
    function handleFee(uint256 amount, address token) public onlyExchange {
        if(amount == 0) {
            restoreAllFee(); 
        } else {
            uint256 tokenIndex = _getTokenIndex(token);
            if(tokenIndex < pairsLength) {
                uint256 allowanceT = IERC20(token).allowance(msg.sender, address(this));
                if(allowanceT >= amount) {
                    IERC20(token).transferFrom(msg.sender, address(this), amount);

                    if(token != WETH) {
                        uint256 balanceBefore = IERC20(address(WETH)).balanceOf(address(this));
                        swapToWETH(amount, token);
                        uint256 fAmount = IERC20(address(WETH)).balanceOf(address(this)).sub(balanceBefore);
                        
                        // All fees to be declared here in order to be calculated and sent
                        uint256 totalFee = getFee();
                        uint256 developmentFeeAmount = fAmount.mul(_defaultFees.developmentFee).div(totalFee);

                        IERC20(WETH).transfer(_defaultFees.developmentAddress, developmentFeeAmount);
                    } else {
                        // All fees to be declared here in order to be calculated and sent
                        uint256 totalFee = getFee();
                        uint256 developmentFeeAmount = amount.mul(_defaultFees.developmentFee).div(totalFee);

                        IERC20(token).transfer(_defaultFees.developmentAddress, developmentFeeAmount);
                    }

                    restoreAllFee();
                }
            }
        }
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

    // runs check to see if autobuyback should trigger
    function shouldAutoBuyback(uint256 amount) internal view returns (bool) {
        return msg.sender != pyeSwapPair
        && !inSwap
        && _buyback.autoBuybackEnabled
        && _buyback.autoBuybackBlockLast + _buyback.autoBuybackBlockPeriod <= block.number // After N blocks from last buyback
        && IERC20(address(WETH)).balanceOf(address(this)) >= _buyback.autoBuybackAmount
        && amount >= _buyback.minimumBuyBackThreshold;
    }

    // triggers auto buyback
    function triggerAutoBuyback() internal {
        buyTokens(_buyback.autoBuybackAmount, _burnAddress);
        _buyback.autoBuybackBlockLast = block.number;
        _buyback.autoBuybackAccumulator = _buyback.autoBuybackAccumulator.add(_buyback.autoBuybackAmount);
        if(_buyback.autoBuybackAccumulator > _buyback.autoBuybackCap){ _buyback.autoBuybackEnabled = false; }
    }

    // logic to purchase tokens
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

    // manually adjust the buyback settings to suit your needs
    function setAutoBuybackSettings(bool _enabled, uint256 _cap, uint256 _amount, uint256 _period, uint256 _minimumThreshold) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "APPLE: NOT_ALLOWED");
        _buyback.autoBuybackEnabled = _enabled;
        _buyback.autoBuybackCap = _cap;
        _buyback.autoBuybackAccumulator = 0;
        _buyback.autoBuybackAmount = _amount;
        _buyback.autoBuybackBlockPeriod = _period;
        _buyback.autoBuybackBlockLast = block.number;
        _buyback.minimumBuyBackThreshold = _minimumThreshold;
    }

    function _getTokenIndex(address _token) internal view returns (uint256) {
        uint256 index = pairsLength + 1;
        for(uint256 i = 0; i < pairsLength; i++) {
            if(tokens[i] == _token) index = i;
        }

        return index;
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

            pairs[pairsLength] = _pair;
            tokens[pairsLength] = _token;

            pairsLength += 1;
        }
    }

    function _checkPairRegistered(address _pair) internal view returns (bool) {
        bool isPair = false;
        for(uint i = 0; i < pairsLength; i++) {
            if(pairs[i] == _pair) isPair = true;
        }

        return isPair;
    }

    // Rescue eth that is sent here by mistake
    function rescueETH(uint256 amount, address to) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "APPLE: NOT_ALLOWED");
        payable(to).transfer(amount);
      }

    // Rescue tokens that are sent here by mistake
    function rescueToken(IERC20 token, uint256 amount, address to) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "APPLE: NOT_ALLOWED");
        if( token.balanceOf(address(this)) < amount ) {
            amount = token.balanceOf(address(this));
        }
        token.transfer(to, amount);
    }

    /**	
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.	
     *	
     * Does not update the allowance amount in case of infinite allowance.	
     * Revert if not enough allowance is available.	
     *	
     * Might emit an {Approval} event.	
     */	
    function _spendAllowance(	
        address owner,	
        address spender,	
        uint256 amount	
    ) internal override virtual {	
        uint256 currentAllowance = allowance(owner, spender);	
        if (currentAllowance != type(uint256).max) {	
            require(currentAllowance >= amount, "ERC20: insufficient allowance");	
            unchecked {	
                _approve(owner, spender, currentAllowance - amount);	
            }	
        }	
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) override internal {
        require(account != address(0), 'ERC20: mint to the zero address');

        _tTotal = _tTotal.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) override internal {	
        require(account != address(0), 'ERC20: burn from the zero address');	
        _balances[account] = _balances[account].sub(amount, 'ERC20: burn amount exceeds balance');	
        _tTotal = _tTotal.sub(amount);
        _bTotal = _bTotal.add(amount);	
        emit Transfer(account, address(0), amount);	
    }

    
    function burnFrom(address _from, uint256 _amount) public {	
        require(hasRole(BURNER_ROLE, msg.sender), "APPLE: NOT_ALLOWED");	
        _spendAllowance(_from, msg.sender, _amount);
        _beforeTokenTransfer(_from, address(0), _amount);		
        _burn(_from, _amount);	
        
    }	


    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public {
        require(hasRole(MINTER_ROLE, msg.sender), "APPLE: NOT_ALLOWED");
        _beforeTokenTransfer(address(0), _to, _amount);
        _mint(_to, _amount);
        
    }

    function burn(uint256 _amount) public {
        require(hasRole(BURNER_ROLE, msg.sender), "APPLE: NOT_ALLOWED");
        _beforeTokenTransfer(msg.sender, address(0), _amount);
        _burn(msg.sender, _amount);

    }

    //-------------------- BEGIN STAKED FXNS ------------------------------	
    function getOwnedBalance(address account) public view returns (uint256){	
        return staked[account].amount.add(_balances[account]);	
    }	
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
    // set an address as a staking contract	
    function setIsStakingContract(address account, bool set) external {	
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "APPLE: NOT_ALLOWED");	
        isStakingContract[account] = set;	
    }	
    //--------------------------------------BEGIN DENYLIST FUNCTIONS---------|	
    // enter an address to denylist it. This blocks transfers TO that address. Balcklisted members can still sell.	
    function denylistAddress(address addressToDenylist) external {	
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "APPLE: NOT_ALLOWED");	
        require(!isDenylisted[addressToDenylist] , "Address is already denylisted!");	
        isDenylisted[addressToDenylist] = true;	
    }	
    // enter a currently denylisted address to un-denylist it.	
    function removeFromDenylist(address addressToRemove) external {	
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "APPLE: NOT_ALLOWED");	
        require(isDenylisted[addressToRemove] , "Address has not been denylisted! Enter an address that is on the denylist.");	
        isDenylisted[addressToRemove] = false;	
    }

    // -------------------------------------BEGIN MODIFIED SNAPSHOT FUNCTIONS--------------------|

    //@ dev a direct, modified implementation of ERC20 snapshot designed to track totalOwnedBalance (the sum of balanceOf(acct) and staked.amount of that acct), as opposed
    // to just balanceOf(acct). totalSupply is tracked normally via _tTotal in the totalSupply() function.

    using Arrays for uint256[];
    using Counters for Counters.Counter;
    Counters.Counter private _currentSnapshotId;

    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping(address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalSupplySnapshots;
    event Snapshot(uint256 id);

    // owner grant and revoke Snapshotter role to account.
    function setIsSnapshotter(address account, bool flag) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "APPLE: NOT_ALLOWED");
        isSnapshotter[account] = flag;
    }

    // generate a snapshot, calls internal _snapshot().
    function snapshot() public {
        require(isSnapshotter[msg.sender], "Caller is not allowed to snapshot");
        _snapshot();
    }

    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _getCurrentSnapshotId();
        emit Snapshot(currentId);
        return currentId;
    }

    function _getCurrentSnapshotId() internal view virtual returns (uint256) {
        return _currentSnapshotId.current();
    }

    function getCurrentSnapshotID() public view returns (uint256) {
        return _getCurrentSnapshotId();
    }

    // modified to also read users staked balance. 
    function balanceOfAt(address account, uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : (getOwnedBalance(account));
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

}