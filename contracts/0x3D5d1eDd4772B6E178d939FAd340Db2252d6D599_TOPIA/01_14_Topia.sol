// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IPYESwapFactory.sol";
import "./interfaces/IPYESwapRouter.sol";


contract TOPIA is AccessControl, ERC20 {
    using SafeMath for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant FEE_SETTER_ROLE = keccak256("FEE_SETTER_ROLE");

    // Fees
    // Add and remove fee types and destinations here as needed
    struct Fees {
        uint256 buybackFee;
    }

    // Transaction fee values
    // Add and remove fee value types here as needed
    struct FeeValues {
        uint256 transferAmount;
        uint256 buyback;
    }

    // Token details
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
   
    // denylist for WALLETS	
    mapping (address => bool) public isDenylisted;
    mapping (address => bool) public isAddressAllowlistedOut;
    mapping (address => bool) public allowedTransfer;
    bool public transferRestricted;

    // contract whitelist
    mapping (address => bool) allowedContracts; 	
     
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

    // Daily Transfer Limit
    bool public transferLimitEnabled = true;
    uint256 public transferLimit = 100 ether;
    struct DailyTransfer {
        uint256 startTime;
        uint256 endTime;
        uint256 periodTransfers;
    }
    mapping (address => DailyTransfer) public DailyTransfers;

    // Outside Swap Pairs
    mapping (address => bool) private _includeSwapFee;


    // Pair Details
    mapping (uint256 => address) private pairs;
    mapping (uint256 => address) private tokens;
    uint256 private pairsLength;
    mapping (address => bool) public _isPairAddress;


    // Set the name, symbol, and decimals here
    string constant _name = "TEST";
    string constant _symbol = "TEST";
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

    // @dev: disallows contracts from entering
    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    // Edit the constructor in order to declare default fees on deployment
    constructor (address _router, uint256 _buybackFeeBuy, uint256 _buybackFeeSell) ERC20("","") {
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
        allowedTransfer[_msgSender()] = true;
        allowedTransfer[address(this)] = true;
        allowedTransfer[_burnAddress] = true;   
        isAddressAllowlistedOut[msg.sender] = true; 
        isAddressAllowlistedOut[address(this)] = true;   

        // This should match the struct Fee
        _defaultFees = Fees(
            
            _buybackFeeBuy
        );

        _buyFees = Fees(
            
            _buybackFeeBuy
        );

        _sellFees = Fees(
            _buybackFeeSell
        );

        _outsideBuyFees = Fees(
            _buybackFeeBuy
            
        );

        _outsideSellFees = Fees(
            _buybackFeeSell
        );

        transferRestricted = true;
    }

    // @dev: returns the size of the code of an address. If >0, address is a contract. 
    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
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
        require(msg.sender == tx.origin || allowedContracts[msg.sender], "Proxy contract not allowed");
        if(transferRestricted) { 
            require(allowedTransfer[msg.sender] || allowedTransfer[recipient], "Transfer not allowed"); 
        }
        if (_isContract(msg.sender)) {
            require(allowedContracts[msg.sender], "This contract is not approved to interact with TOPIA");
        }
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
        require(msg.sender == tx.origin || allowedContracts[msg.sender], "Proxy contract not allowed");
        if(transferRestricted) { 
            require(allowedTransfer[sender] || allowedTransfer[recipient], "Transfer not allowed"); 
        }
        if (_isContract(msg.sender)) {
            require(allowedContracts[msg.sender], "This contract is not approved to interact with TOPIA");
        }
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual override returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual override returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function excludeFromFee(address account) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "TOPIA: NOT_ALLOWED");
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "TOPIA: NOT_ALLOWED");
        _isExcludedFromFee[account] = false;
    }

    function addOutsideSwapPair(address account) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "TOPIA: NOT_ALLOWED");
        _includeSwapFee[account] = true;
    }

    function removeOutsideSwapPair(address account) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "TOPIA: NOT_ALLOWED");
        _includeSwapFee[account] = false;
    }

    // Functions to update fees and addresses 

    function setBuyFees(uint256 _developmentFee, uint256 _buybackFee) external {
        require(hasRole(FEE_SETTER_ROLE, msg.sender), "TOPIA: NOT_ALLOWED");
        require(_developmentFee.add(_buybackFee) <= 2500, "Fees exceed max limit");
       
        _defaultFees.buybackFee = _buybackFee;
        _buyFees.buybackFee = _buybackFee;
    }

    function setSellFees(uint256 _developmentFee, uint256 _buybackFee) external {
        require(hasRole(FEE_SETTER_ROLE, msg.sender), "TOPIA: NOT_ALLOWED");
        require(_developmentFee.add(_buybackFee) <= 2500, "Fees exceed max limit");
        
        _sellFees.buybackFee = _buybackFee;
    }

    function updateRouterAndPair(address _router, address _pair) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "TOPIA: NOT_ALLOWED");
        _isExcludedFromFee[pyeSwapPair] = false;
        pyeSwapRouter = IPYESwapRouter(_router);
        pyeSwapPair = _pair;
        WETH = pyeSwapRouter.WETH();

        _isPairAddress[pyeSwapPair] = true;
        _isExcludedFromFee[pyeSwapPair] = true;
        allowedContracts[pyeSwapPair] = true;
        allowedContracts[_router] = true;
        allowedTransfer[pyeSwapPair] = true;
        allowedTransfer[_router] = true;
        isAddressAllowlistedOut[pyeSwapPair] = true;
        isAddressAllowlistedOut[_router] = true;

        pairs[0] = pyeSwapPair;
        tokens[0] = WETH;
    }

    function enablePYESwap() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "TOPIA: NOT_ALLOWED");
        allowedContracts[pyeSwapPair] = true;
        allowedContracts[address(pyeSwapRouter)] = true;
        allowedTransfer[pyeSwapPair] = true;
        allowedTransfer[address(pyeSwapRouter)] = true;
        isAddressAllowlistedOut[pyeSwapPair] = true;
        isAddressAllowlistedOut[address(pyeSwapRouter)] = true;

    }

    function setTransferLimit(uint256 _amount) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "TOPIA: NOT_ALLOWED");
        transferLimit = _amount;
    }

    function setTransferRestricted(bool _restricted) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "TOPIA: NOT_ALLOWED");
        transferRestricted = _restricted;
    }

    function addGameContract(address _gameAddress) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "TOPIA: NOT_ALLOWED");
        grantRole(MINTER_ROLE, _gameAddress);
        grantRole(BURNER_ROLE, _gameAddress);
        allowedContracts[_gameAddress] = true;
        allowedTransfer[_gameAddress] = true;
    }

    //to receive BNB from pyeRouter when swapping
    receive() external payable {}

    function _getValues(uint256 tAmount) private view returns (FeeValues memory) {
        FeeValues memory values = FeeValues(
            tAmount,
            calculateFee(tAmount, _defaultFees.buybackFee)
        );

        values.transferAmount = tAmount.sub(values.buyback);
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
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!isDenylisted[to]);
       
        if(shouldAutoBuyback(amount)){ triggerAutoBuyback(); }

        //indicates if fee should be deducted from transfer of tokens
        uint8 takeFee = 0;
        if(_isPairAddress[to] && from != address(pyeSwapRouter) && !isExcludedFromFee(from)) {
            require(dailyAllowed(from, amount));
            takeFee = 1;
        } else if(_includeSwapFee[from]) {
            takeFee = 2;
        } else if(_includeSwapFee[to]) {
            require(dailyAllowed(from, amount));
            takeFee = 3;
        }

        //transfer amount, it will take tax
        _tokenTransfer(from, to, amount, takeFee);
    }

    function dailyAllowed(address from, uint256 amount) internal returns (bool) {
        if(!transferLimitEnabled || isAddressAllowlistedOut[from]) {
            return true;
        } else if(DailyTransfers[from].endTime < block.timestamp && amount <= transferLimit) {
            DailyTransfers[from].startTime = block.timestamp;
            DailyTransfers[from].endTime = block.timestamp + 1 days;
            DailyTransfers[from].periodTransfers = amount;
            return true;
        } else if(DailyTransfers[from].periodTransfers.add(amount) <= transferLimit) {
            DailyTransfers[from].periodTransfers = DailyTransfers[from].periodTransfers.add(amount);
            return true;
        } else {
            return false;
        }
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _tTotal.sub(balanceOf(_burnAddress)).sub(balanceOf(address(0)));
    }

    function getTotalFee(address account) public view returns (uint256) {
        if(_isExcludedFromFee[account]) {
            return 0;
        } else {
        return _defaultFees.buybackFee;
        }
    }

    function getFee() public view returns (uint256) {
        return _defaultFees.buybackFee;
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

            emit Transfer(sender, recipient, _values.transferAmount);
            emit Transfer(sender, _burnAddress, _values.buyback);

            restoreAllFee();
        }
    }

    function _takeFees(FeeValues memory values) private {
        _takeFee(values.buyback, _burnAddress);
    }

    function _takeFee(uint256 tAmount, address recipient) private {
        if(recipient == address(0)) return;
        if(tAmount == 0) return;

        _balances[address(this)] = _balances[address(this)].add(tAmount);
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
                        swapToWETH(amount, token);
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
        pyeSwapRouter.swapExactTokensForTokens(
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
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "TOPIA: NOT_ALLOWED");
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
            allowedContracts[_pair] = true;
            allowedTransfer[_pair] = true;

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

    // Rescue bnb that is sent here by mistake
    function rescueBNB(uint256 amount, address to) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "TOPIA: NOT_ALLOWED");
        payable(to).transfer(amount);
      }

    // Rescue tokens that are sent here by mistake
    function rescueToken(IERC20 token, uint256 amount, address to) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "TOPIA: NOT_ALLOWED");
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
        require(account != address(0), 'BEP20: mint to the zero address');

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
        require(account != address(0), 'BEP20: burn from the zero address');	
        _balances[account] = _balances[account].sub(amount, 'BEP20: burn amount exceeds balance');	
        _tTotal = _tTotal.sub(amount);
        _bTotal = _bTotal.add(amount);	
        emit Transfer(account, address(0), amount);	
    }

    
    function burnFrom(address _from, uint256 _amount) public {	
        require(hasRole(BURNER_ROLE, msg.sender), "TOPIA: NOT_ALLOWED");	
        _spendAllowance(_from, msg.sender, _amount);
        _burn(_from, _amount);	
        
    }	


    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public {
        require(hasRole(MINTER_ROLE, msg.sender), "TOPIA: NOT_ALLOWED");
        _mint(_to, _amount);
        
    }

    function burn(uint256 _amount) public {
        require(hasRole(BURNER_ROLE, msg.sender), "TOPIA: NOT_ALLOWED");
        _burn(msg.sender, _amount);

    }

	
    //--------------------------------------BEGIN DENYLIST FUNCTIONS---------|	

    // enter an address to denylist it. This blocks transfers TO that address. Denylisted members can still sell.	
    function denylistAddress(address addressToBlacklist) external {	
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "TOPIA: NOT_ALLOWED");	
        require(!isDenylisted[addressToBlacklist] , "Address is already denylisted!");	
        isDenylisted[addressToBlacklist] = true;	
    }

    // enter a currently denylisted address to un-denylist it.	
    function removeFromDenylist(address addressToRemove) external {	
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "TOPIA: NOT_ALLOWED");	
        require(isDenylisted[addressToRemove] , "Address has not been denylisted! Enter an address that is on the denylist.");	
        isDenylisted[addressToRemove] = false;	
    }

    /// Functions to allowlist selected wallets
    function setAllowlistWalletOut(address wallet, bool flag) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "TOPIA: NOT_ALLOWED");
        isAddressAllowlistedOut[wallet] = flag;
    }

    function setAllowedContract(address _contract, bool flag) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "TOPIA: NOT_ALLOWED");
        require(_isContract(_contract), "The address you entered is returning a extcodesize of 0 - please ensure this is a contract and not a wallet!");
        allowedContracts[_contract] = flag;
    }

}