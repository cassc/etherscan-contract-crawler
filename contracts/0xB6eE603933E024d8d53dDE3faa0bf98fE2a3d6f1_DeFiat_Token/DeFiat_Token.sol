/**
 *Submitted for verification at Etherscan.io on 2020-08-28
*/

// SPDX-License-Identifier: DeFiat 2020

/*
* Copyright (c) 2020 DeFiat.net
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/


/*
* DISCLAIMER:
* DeFiat (the “Token”) is a utility token experiment using the ERC20 standard on 
* the Ethereum Blockchain (The “Blockchain"). The DeFiat website and White Paper (the “WP”) 
* are for illustration only and do not make the Team liable for any of their content. 
* The DeFiat website may evolve over time, including but not limited to, a change of URL, 
* change of content, adding or removing functionalities. 
* THERE IS NO GUARANTEE THAT THE UTILITY OF THE TOKENS OR THE PROJECT DESCRIBED IN THE 
* AVAILABLE INFORMATION (AS DEFINED BELOW) WILL BE DELIVERED. REGARDLESS OF THE ACQUISITION 
* METHOD, BY ACQUIRING THE TOKEN YOU ARE AGREEING TO HAVE NO RECOURSE, CLAIM, ACTION, 
* JUDGEMENT OR REMEDY AGAINST THE TEAM IF THE UTILITY OF THE TOKENS OR IF THE PROJECT 
* DESCRIBED IN THE AVAILABLE INFORMATION IS NOT DELIVERED OR REALISED.
*/


/*
* Below are the 3 DeFiat ecosystem contracts:
* Defiat_Points, the loyalty token: 0x8c9d8f5cc3427f460e20f63b36992f74aa19e27d
* Defiat_Gov, the governance contract: 0x3aa3303877a0d1c360a9fe2693ae9f31087a1381
* Defiat_Token, the actual contract managing the DeFiat DFT token.
* Any questions regarding the code, please reach out to the team.
*/

//Libraries,  Interfaces and ERC20 baseline contract. SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
        
    //max and min from Zeppelin math.   

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}          //Zeppelin's SafeMath
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
} //don't use
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract _ERC20 is Context, IERC20 { 
    using SafeMath for uint256;
    //using Address for address;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function _constructor(string memory name, string memory symbol) internal {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

//Public Functions
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
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }


//Internal Functions
    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }  //overriden in Defiat_Token

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
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
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
} 


//DeFiat Points - 2020 AUG 27
pragma solidity ^0.6.0;
contract DeFiat_Points is _ERC20{
    
    //global variables
    address public deFiat_Token;                        //1 DeFiat token address 
    mapping(address => bool) public deFiat_Gov;         //multiple governing addresses
    
    uint256 public txThreshold; //min tansfer to generate points
    mapping (uint => uint256) public _discountTranches;
    mapping (address => uint256) private _discounts; //current discount (base100)


//== modifiers ==
    modifier onlyGovernors {
        require(deFiat_Gov[msg.sender] == true, "Only governing contract");
        _;
    }
    modifier onlyToken {
        require(msg.sender == deFiat_Token, "Only token");
        _;
    }
    
    constructor() public { //token and governing contract
        deFiat_Gov[msg.sender] = true; //msg.sender is the 1st governor
        _constructor("DeFiat Points", "DFTP"); //calls the ERC20 "_constructor" to update token name
        txThreshold = 1e18*100;//
        setAll10DiscountTranches(
             1e18*10,  1e18*50,  1e18*100,  1e18*500,  1e18*1000, 
             1e18*1e10,  1e18*1e10+1,  1e18*1e10+2, 1e18*1e10+3); //60% and abovse closed at launch.
        _discounts[msg.sender]=100;
        //no minting. _totalSupply = 0
    }

//== VIEW ==
    function viewDiscountOf(address _address) public view returns (uint256) {
        return _discounts[_address];
    }
    function viewEligibilityOf(address _address) public view returns (uint256 tranche) {
        uint256 _tranche = 0;
        for(uint256 i=0; i<=9; i++){
           if(balanceOf(_address) >= _discountTranches[i]) { 
             _tranche = i;}
           else{break;}
        }
        return _tranche;
    }
    function discountPointsNeeded(uint _tranche) public view returns (uint256 pointsNeeded) {
        return( _discountTranches[_tranche]); //check the nb of points needed to access discount tranche
    }

//== SET ==
    function updateMyDiscountOf() public returns (bool) {
        uint256 _tranche = viewEligibilityOf(msg.sender);
        _discounts[msg.sender] =  SafeMath.mul(10, _tranche); //update of discount base100
        return true;
    }  //users execute this function to upgrade a status level to the max tranche

//== SET onlyGovernor ==
    function setDeFiatToken(address _token) external onlyGovernors returns(address){
        return deFiat_Token = _token;
    }
    function setGovernor(address _address, bool _rights) external onlyGovernors {
        require(msg.sender != _address); //prevents self stripping of rights
        deFiat_Gov[_address] = _rights;
    }
    
    function setTxTreshold(uint _amount) external onlyGovernors {
      txThreshold = _amount;  //base 1e18
    } //minimum amount of tokens to generate points per transaction
    function overrideDiscount(address _address, uint256 _newDiscount) external onlyGovernors {
      require(_newDiscount <= 100); //100 = 100% discount
      _discounts[_address]  = _newDiscount;
    }
    function overrideLoyaltyPoints(address _address, uint256 _newPoints) external onlyGovernors {
        _burn(_address, balanceOf(_address)); //burn all points
        _mint(_address, _newPoints); //mint new points
    }
    
    function setDiscountTranches(uint _tranche, uint256 _pointsNeeded) external onlyGovernors {
        require(_tranche <10, "max tranche is 9"); //tranche 9 = 90% discount
        _discountTranches[_tranche] = _pointsNeeded;
    }
    
    function setAll10DiscountTranches(
            uint256 _pointsNeeded1, uint256 _pointsNeeded2, uint256 _pointsNeeded3, uint256 _pointsNeeded4, 
            uint256 _pointsNeeded5, uint256 _pointsNeeded6, uint256 _pointsNeeded7, uint256 _pointsNeeded8, 
            uint256 _pointsNeeded9) public onlyGovernors {
        _discountTranches[0] = 0;
        _discountTranches[1] = _pointsNeeded1; //10%
        _discountTranches[2] = _pointsNeeded2; //20%
        _discountTranches[3] = _pointsNeeded3; //30%
        _discountTranches[4] = _pointsNeeded4; //40%
        _discountTranches[5] = _pointsNeeded5; //50%
        _discountTranches[6] = _pointsNeeded6; //60%
        _discountTranches[7] = _pointsNeeded7; //70%
        _discountTranches[8] = _pointsNeeded8; //80%
        _discountTranches[9] = _pointsNeeded9; //90%
    }
    
//== MINT points: onlyToken ==  
    function addPoints(address _address, uint256 _txSize, uint256 _points) external onlyToken {
       if(_txSize >= txThreshold){ _mint(_address, _points);}
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal override virtual {
        _ERC20._transfer(sender, recipient, amount);
        //force update discount
        uint256 _tranche = viewEligibilityOf(msg.sender);
        _discounts[msg.sender] =  SafeMath.mul(10, _tranche);
        
    }  //overriden to update discount at every points Transfer. Avoids passing tokens to get discounts.
    
    function burn(uint256 _amount) public returns(bool) {
        _ERC20._burn(msg.sender,_amount);
    }
} 


//DeFiat Governance v0.1 - 2020 AUG 27
pragma solidity ^0.6.0;
contract DeFiat_Gov{
//Governance contract for DeFiat Token.
    address public mastermind;
    mapping (address => uint256) private actorLevel; //governance = multi-tier level
    
    mapping (address => uint256) private override _balances; 
     mapping (address => uint256) private override _allowances; 
     
    uint256 private burnRate; // %rate of burn at each transaction
    uint256 private feeRate;  // %rate of fee taken at each transaction
    address private feeDestination; //target address for fees (to support staking contracts)

    event stdEvent(address _txOrigin, uint256 _number, bytes32 _signature, string _desc);

//== CONSTRUCTOR
constructor() public {
    mastermind = msg.sender;
    actorLevel[mastermind] = 3;
    feeDestination = mastermind;
    emit stdEvent(msg.sender, 3, sha256(abi.encodePacked(mastermind)), "constructor");
}

//== MODIFIERS ==
    modifier onlyMastermind {
    require(msg.sender == mastermind, " only Mastermind");
    _;
    }
    modifier onlyGovernor {
    require(actorLevel[msg.sender] >= 2,"only Governors");
    _;
    }
    modifier onlyPartner {
    require(actorLevel[msg.sender] >= 1,"only Partners");
    _;
    }  //future use
    
//== VIEW ==    
    function viewActorLevelOf(address _address) public view returns (uint256) {
        return actorLevel[_address]; //address lvl (3, 2, 1 or 0)
    }  
    function viewBurnRate() public view returns (uint256)  {
        return burnRate;
    }
    function viewFeeRate() public view returns (uint256)  {
        return feeRate;
    }
    function viewFeeDestination() public view returns (address)  {
        return feeDestination;
    }
    
//== SET INTERNAL VARIABLES==

    function setActorLevel(address _address, uint256 _newLevel) public {
      require(_newLevel < actorLevel[msg.sender], "Can only give rights below you");
      actorLevel[_address] = _newLevel; //updates level -> adds or removes rights
      emit stdEvent(_address, _newLevel, sha256(abi.encodePacked(msg.sender, _newLevel)), "Level changed");
    }
    
    //MasterMind specific 
    function removeAllRights(address _address) public onlyMastermind {
      require(_address != mastermind);
      actorLevel[_address] = 0; //removes all rights
      emit stdEvent(address(_address), 0, sha256(abi.encodePacked(_address)), "Rights Revoked");
    }
    function killContract() public onlyMastermind {
        selfdestruct(msg.sender); //destroys the contract if replacement needed
    } //only Mastermind can kill contract
    function setMastermind(address _mastermind) public onlyMastermind {
      mastermind = _mastermind;     //Only one mastermind
      actorLevel[_mastermind] = 3; 
      actorLevel[msg.sender] = 2;  //new level for previous mastermind
      emit stdEvent(tx.origin, 0, sha256(abi.encodePacked(_mastermind, mastermind)), "MasterMind Changed");
    }     //only Mastermind can transfer his own rights
     
    //Governors specific
    function changeBurnRate(uint _burnRate) public onlyGovernor {
      require(_burnRate <=200, "20% limit"); //cannot burn more than 20%/tx
      burnRate = _burnRate; 
      emit stdEvent(address(msg.sender), _burnRate, sha256(abi.encodePacked(msg.sender, _burnRate)), "BurnRate Changed");
    }     //only governors can change burnRate/tx
    function changeFeeRate(uint _feeRate) public onlyGovernor {
      require(_feeRate <=200, "20% limit"); //cannot take more than 20% fees/tx
      feeRate = _feeRate;
      emit stdEvent(address(msg.sender), _feeRate, sha256(abi.encodePacked(msg.sender, _feeRate)), "FeeRate Changed");
    }    //only governors can change feeRate/tx
    function setFeeDestination(address _nextDest) public onlyGovernor {
         feeDestination = _nextDest;
    }

}


//DeFiat Token - 2020 AUG 27
pragma solidity ^0.6.0;
contract DeFiat_Token is _ERC20 {  //overrides the _transfer function and adds burn capabilities

    using SafeMath for uint;

//== Variables ==
    address private mastermind;     // token creator.
    address public DeFiat_gov;      // contract governing the Token
    address public DeFiat_points;   // ERC20 loyalty TOKEN

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    struct Transaction {
        address sender;
        address recipient;
        uint256 burnRate;
        uint256 feeRate;
        address feeDestination;
        uint256 senderDiscount;
        uint256 recipientDiscount;
        uint256 actualDiscount;
    }
    Transaction private transaction;
        
//== Modifiers ==
    modifier onlyMastermind {
    require(msg.sender == mastermind, "only Mastermind");
    _;
    }
    modifier onlyGovernor {
    require(msg.sender == mastermind || msg.sender == DeFiat_gov, "only Governance contract");
    _;
    } //only Governance managing contract
    modifier onlyPoints {
    require(msg.sender == mastermind || msg.sender == DeFiat_points, " only Points contract");
    _;
    }   //only Points managing contract


    
//== Events ==
    event stdEvent(address _address, uint256 _number, bytes32 _signature, string _desc);
 
//== Token generation ==
    constructor (address _gov, address _points) public {  //token requires that governance and points are up and running
        mastermind = msg.sender;
        _constructor("DeFiat","DFT"); //calls the ERC20 _constructor
        _mint(mastermind, 1e18 * 500000); //mint 300,000 tokens
        
        DeFiat_gov = _gov;      // contract governing the Token
        DeFiat_points = _points;   // ERC20 loyalty TOKEN
    }
    
//== mastermind ==
    function widthdrawAnyToken(address _recipient, address _ERC20address, uint256 _amount) public onlyGovernor returns (bool) {
        IERC20(_ERC20address).transfer(_recipient, _amount); //use of the _ERC20 traditional transfer
        return true;
    } //get tokens sent by error to contract
    function setGovernorContract(address _gov) external onlyGovernor {
        DeFiat_gov = _gov;
    }    // -> governance transfer
    function setPointsContract(address _pts) external onlyGovernor {
        DeFiat_points = _pts;
    }      // -> new points management contract
    function setMastermind(address _mastermind) external onlyMastermind {
        mastermind = _mastermind; //use the 0x0 address to resign
    } // transfered to go contract OCT 2020

//== View variables from external contracts ==
    function _viewFeeRate() public view returns(uint256){
       return DeFiat_Gov(DeFiat_gov).viewFeeRate();
    }
    function _viewBurnRate() public view returns(uint256){
        return DeFiat_Gov(DeFiat_gov).viewBurnRate();
    }
    function _viewFeeDestination() public view returns(address){
        return DeFiat_Gov(DeFiat_gov).viewFeeDestination();
    }
    function _viewDiscountOf(address _address) public view returns(uint256){
        return DeFiat_Points(DeFiat_points).viewDiscountOf(_address);
    }
    function _viewPointsOf(address _address) public view returns(uint256){
        return DeFiat_Points(DeFiat_points).balanceOf(_address);
    }
  
//== override _transfer function in the ERC20Simple contract ==    
    function updateTxStruct(address sender, address recipient) internal returns(bool){
        transaction.sender = sender;
        transaction.recipient = recipient;
        transaction.burnRate = _viewBurnRate();
        transaction.feeRate = _viewFeeRate();
        transaction.feeDestination = _viewFeeDestination();
        transaction.senderDiscount = _viewDiscountOf(sender);
        transaction.recipientDiscount = _viewDiscountOf(recipient);
        transaction.actualDiscount = SafeMath.max(transaction.senderDiscount, transaction.recipientDiscount);
        
         if( transaction.actualDiscount > 100){transaction.actualDiscount = 100;} //manages "forever pools"
    
        return true;
    } //struct used to prevent "stack too deep" error
    
    function addPoints(address sender, uint256 _threshold) public {
    DeFiat_Points(DeFiat_points).addPoints(sender, _threshold, 1e18); //Update user's loyalty points +1 = +1e18
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal override { //overrides the inherited ERC20 _transfer
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        
    //load transaction Struct (gets info from external contracts)
        updateTxStruct(sender, recipient);
        
    //get discounts and apply them. You get the MAX discounts of the sender x recipient. discount is base100
        uint256 dAmount = 
        SafeMath.div(
            SafeMath.mul(amount, 
                                SafeMath.sub(100, transaction.actualDiscount))
        ,100);     //amount discounted to calculate fees

    //Calculates burn and fees on discounted amount (burn and fees are 0.0X% ie base 10000 -> "10" = 0.1%)
        uint _toBurn = SafeMath.div(SafeMath.mul(dAmount,transaction.burnRate),10000); 
        uint _toFee = SafeMath.div(SafeMath.mul(dAmount,transaction.feeRate),10000); 
        uint _amount = SafeMath.sub(amount, SafeMath.add(_toBurn,_toFee)); //calculates the remaning amount to be sent
   
    //transfers -> forcing _ERC20 inheritance level
        if(_toFee > 0) {
        _ERC20._transfer(sender, transaction.feeDestination, _toFee); //native _transfer + emit
        } //transfer fee
        
        if(_toBurn > 0) {_ERC20._burn(sender,_toBurn);} //native _burn tokens from sender
        
        //transfer remaining amount. + emit
        _ERC20._transfer(sender, recipient, _amount); //native _transfer + emit

        //mint loyalty points and update lastTX
        if(sender != recipient){addPoints(sender, amount);} //uses the full amount to determine point minting
    }
    
    function burn(uint256 _amount) public returns(bool) {
        _ERC20._burn(msg.sender,_amount);
    }

}

// End of code. Thanks for reading. If you had the patience and skills to read it all, send us a msg on out social media platrofms. (DeFiat 2020)