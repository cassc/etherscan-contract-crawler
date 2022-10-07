//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./BEP20.sol";
import "./Auth.sol";


contract $CC is BEP20,Auth {

        using SafeMath for uint256;

        string private _name= "Celebrity Coin";
        string private _symbol = "$CC";
        uint8 private _decimals = 18;
        uint256 private _totalSupply = 3 * 10**7* 10 ** _decimals;
        bool public tradingOpen = false;
        //max wallet holding of 3% 
        uint256 public _maxWalletToken = ( _totalSupply * 3 ) / 100;
        uint256 public _maxTransferUnit = 5000;
        //uint256 public _maxTxAmount = _totalSupply * 1 / 100;
        
        // Slowdown & timer functionality
        bool public _buySlowdownEnabled = true;
        uint8 public _slowdownTimerInterval = 60;
        mapping (address => uint) private slowdownTimer;

        mapping (address => bool) isTxLimitExempt;
        mapping (address => bool) isTimelockExempt;
        
        mapping(address => uint256) private _balances;
        mapping(address => mapping(address => uint256)) private _allowances;
        mapping(address => bool) private _whitelisted;
        mapping(address => bool) public excludedFromTax;
        mapping(address => uint256) public deposites;
        mapping(address => uint256) public userClaims;
        mapping(address => bool) public blacklisted;
        uint256 public totalClaims;
        string private _hash;


        uint256 public taxFee = 10;
      
 
        constructor() Auth(msg.sender) ERC20("CelebrityCoin", "$CC") {
            uint256 initialSupply = _totalSupply;
            excludedFromTax[msg.sender] = true;
            isTimelockExempt[msg.sender] = true;
            isTxLimitExempt[msg.sender] = true;
            // minting total supply 1 Billion
            _mint(msg.sender, initialSupply);
        }

         
        
        function decimals() public view virtual override returns (uint8) {
            return 18;
        }

        
        function getOwner() public view virtual returns (address){

            return owner;

        }

         
        function totalSupply() public view virtual override returns (uint256) {
            return _totalSupply;
        }

        
        function balanceOf(address account) public view virtual override returns (uint256) {
            return _balances[account];
        }

        function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
            _transfer(_msgSender(), recipient, amount);
            return true;
        }

        
        function allowance(address owner, address spender) public view virtual override returns (uint256) {
            return _allowances[owner][spender];
        }

        
        function approve(address spender, uint256 amount) public virtual override returns (bool) {
            _approve(_msgSender(), spender, amount);
            return true;
        }


         //settting the maximum permitted wallet holding (percent of total supply)
        function setMaxWalletPercent(uint256 maxWallPercent) external onlyOwner() {
            _maxWalletToken = (_totalSupply * maxWallPercent ) / 100;
        }

        //enable or disable the buy slow down
        function setBuySlowDownEnabled(bool enabled) external onlyOwner() {
            _buySlowdownEnabled = enabled;
        }

        //settting the time interval between trades
        function setSlowDownInterval(uint8 timeInterval) external onlyOwner() {
            _slowdownTimerInterval = timeInterval;
        }

        //function to blacklist bots
        function setBlackList(address holder) external authorized {
          blacklisted[holder] = true;
        }
        
        //function to whitelist
        function setWhiteList(address holder) external authorized {
          _whitelisted[holder] = true;
        }

        //settting the maximum permitted wallet holding (percent of total supply)
        function setTransferUnit(uint256 maxTransferUnit) external onlyOwner() {
            _maxTransferUnit = maxTransferUnit;
        }

        //exempt address from transfer limit
        function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
        }

        //exempt address from time lock limit
        function setIsTimelockExempt(address holder, bool exempt) external authorized {
            isTimelockExempt[holder] = exempt;
        }

        function validateTransactionLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTransferUnit || isTxLimitExempt[sender], "Transaction Limit Exceeded");
        }

         
        function transferFrom(address sender,address recipient,uint256 amount) public virtual override returns (bool) {
            _transfer(sender, recipient, amount);

            uint256 currentAllowance = _allowances[sender][_msgSender()];
            require(currentAllowance >= amount, "$CC: transfer amount exceeds allowance");
            unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
            }

            return true;
        }


         
        function _transfer(address sender,address recipient,uint256 amount) internal virtual override{
            require(sender != address(0), "$CC: transfer from the zero address");
            require(recipient != address(0), "$CC: transfer to the zero address");
            
            //check if recipient is blacklisted
            if(!_whitelisted[recipient]){
            require(!blacklisted[recipient], "Recipient is black listed");
            }

            //check if sender is blacklisted
            if(!_whitelisted[sender]){
            require(!blacklisted[sender], "Sender is black listed");
            }


            if(!authorizations[sender] && !authorizations[recipient]){
            require(tradingOpen,"Trading not open yet");
            }

            // max transfer unit
            if (!authorizations[sender] && recipient != address(this)){
            require((amount) <= _maxTransferUnit,"You can not send that much $CC");
            
            }

            // max wallet code - Prevent whales from transfering more that _maxWalletToken
            if (!authorizations[sender] && recipient != address(this)){
            uint256 heldTokens = balanceOf(recipient);
            require((heldTokens + amount) <= _maxWalletToken,"Total Holding is currently limited, you can not buy that much.");
            
            }
        

            // slowdown timer, so a bot doesnt do quick trades! 1 min gap between 2 trades.
            if (_buySlowdownEnabled && !isTimelockExempt[recipient]) {
                require(slowdownTimer[recipient] < block.timestamp,"Please wait for 1 min between two buys");
                slowdownTimer[recipient] = block.timestamp + _slowdownTimerInterval;
            }

             // Checks max transaction limit
             validateTransactionLimit(sender, amount);

            _beforeTokenTransfer(sender, recipient, amount);

            if(!excludedFromTax[sender] && !excludedFromTax[recipient]){
                
                uint256 _taxFee = amount.mul(taxFee).div(10**2);
                amount = amount.sub(_taxFee);
                _burn(sender, _taxFee);
            }

            uint256 senderBalance = _balances[sender];
            require(senderBalance >= amount, "$CC: transfer amount exceeds balance");
            unchecked {
            _balances[sender] = senderBalance - amount;
            }
            _balances[recipient] += amount;

            emit Transfer(sender, recipient, amount);

            _afterTokenTransfer(sender, recipient, amount);
        }

         
        function _mint(address account, uint256 amount) internal virtual override {
            require(account != address(0), "$CC: mint to the zero address");

            _beforeTokenTransfer(address(0), account, amount);

            _totalSupply += amount;
            _balances[account] += amount;
            emit Transfer(address(0), account, amount);

            _afterTokenTransfer(address(0), account, amount);
        }

        
        function _burn(address account, uint256 amount) internal virtual override{
            require(account != address(0), "$CC: burn from the zero address");

            _beforeTokenTransfer(account, address(0), amount);

            uint256 accountBalance = _balances[account];
            require(accountBalance >= amount, "$CC: burn amount exceeds balance");
            unchecked {
            _balances[account] = accountBalance - amount;
            }
            _totalSupply -= amount;

            emit Transfer(account, address(0), amount);

            _afterTokenTransfer(account, address(0), amount);
        }

         
        function _approve(address owner,address spender,uint256 amount) internal virtual override{
            require(owner != address(0), "$CC: approve from the zero address");
            require(spender != address(0), "$CC: approve to the zero address");

            _allowances[owner][spender] = amount;
            emit Approval(owner, spender, amount);
        }

         
       

        


}