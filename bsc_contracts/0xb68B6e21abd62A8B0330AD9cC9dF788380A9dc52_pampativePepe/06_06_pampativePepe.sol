// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

// PAMPATIVE PEPE TOKEN
                                                                                     
                                  /////*.                                                           
                         //////////////////////,           .//////////                             
                      //////////////////*.             ////////////////////                         
                   /////////.  ,/////////////////////,   .////////,                                
                 ///////, ///////////////////////*,,...       ,///////////////////,                
                //////////////////////*   ,*/////////////////////  .////,   ,*//////////////*       
              ///////////////////. .//////. .%@@@@@@@@@@@@@@@@&      *////.   .*#%&&&&&%/.    ,//*  
             /////////////////////,  *@@@@@@@@@@@@@@&,.,%@@@@@@@@,   ,@@@@@@@@@@@@@@*,,@@@@@@@@*   
             ///////////////* %@@@@@@@@@@@@@@@@@@@          /@@@@@@@  @@@@@@@@@@@@         @@@@@@@* 
            ////////////////  [email protected]@@@@@@@@@@@@@@@&            @@@@@@@@ ,@@@@@@@@@@           @@@@@@@ 
         ///////////////////////, /@@@@@@@@@@@@      @@@@   @@@@@@@@  @@@@@@@@@@     @@@%  @@@@@@@ 
       ////////////////////////,///  @@@@@@@@@@&           *@@@@@@@@  [email protected]@@@@@@@@@         @@@@@@@& 
     ///////////////////////////* ////  @@@@@@@@@%      #@@@@@@@@@&  //*  (@@@@@@@@@@@@@@@@@@@@@*  
    ////////////////////////////////, .///,  .#@@@@@@@@@@@@@@@@@@   /   ///////*.       ....        
   /////////////////////////////////////  ,//////*,.......,,*///../////. .////*.   ...,*****,      
   /////////////////////////////   ///////////*.    ,,*//**.   *///////////   /////////             
   //////////////////////////////////,      .**///**,.    ,//////////////////       ,*//////.       
  //////////////// /////////////////////////////////////////////////////////// */////////////,     
  //////////////* ////  .,.  ,//////////////////////////////////////////////////////////////////    
  ////////////////// ************,   ,////////////////////////////////////////////////////////, .*  
  ///////////////// ,*********************.   .*/////////////////////////////////////////*  ,*****  
  ////////////////// *****.      ,*******************,.   .**///////////////**,.    ,***********,   
  ///////////////////* *****..,,,,,,,.   ,**********************************************.           
  ////////////////////// ******, ,,,,,,,,,,,,,,..    ,********************,          *******        
   ///////////////////////* *******. .,,,,,    .,,,,,,,,,,,,,,,,,,,,,,,.  %%%%%%%%%%%%  *******     
    ////////////////////////, *********   %%%%%%(.   .,,,,,,,,,,,,,,,,,,,  %%%%%%%%%%%%* ,****     
       /////////////////////////* **********.  #%%%%%%%%    ,,,,,,,,,,,,,  .%%%%%%%%%%%%%  ****     
          //////////////////////////  ************.   ,#%%%%,            %%%%%%%%%%#   .*******     
              //////////////////////////.  *****************,.             ..***************.       
                  ///////////////////////////   .******************************.    ,.              
                      //////////////////////////////    .********.   ,/////////////////.            
                           ///////////////////////////////////////////////////////*                 
                                 ////////////////////////////////////////////                       
                                                                                                 

import '@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol';
import '@pancakeswap/pancake-swap-lib/contracts/GSN/Context.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';
import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';
import '@pancakeswap/pancake-swap-lib/contracts/utils/Address.sol';

/**
 * @dev Implementation of the {IBEP20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {BEP20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-BEP20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of BEP20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IBEP20-approve}.
 */
contract BEP20 is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    address private _operator;

    mapping (address => uint256) private _balances;
  
    mapping (address => mapping(address => uint256)) private _allowances;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    // Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
   
    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);
    
    uint256 private _totalSupply = 21 * 10**9 * 10**18;
    uint256 private bnbLstAmount = 3150000000 * 10**18; 
    uint256 private cexLstAmount = 1050000000 * 10**18; 
    uint256 private mkAmount = 3150000000 * 10**18; 
    uint256 private aiDevAmount = 5250000000 * 10**18; 
    uint256 private dropLiqAmount = 3656625000 * 10**18;   
    uint256 private airdropAmount = 36750000 * 10**18; 
    uint256 private saleAmount = 7350000000 * 10**18;        
   
    address private liquiditylockAddress = 0xFE8bf0622378A3Ef6D591287cdb7363CB4d7D074;
    address private devAddress = 0x24F134E0a9D2C3481d5a6E9cCA91af56Da24dAb7;
    address private excLstAddress = 0x52d86727f66ca47cf992419Ae6452eF7a39b9CC1;
    address private bncLstAddress = 0x59E732C7c6a14FB21f938218da03deC10B7C0e29;
    address private mktAddress = 0xfeB722193A900Ab5c5bB65196fDd2313585A4132;

    // Pre sale Variables
    mapping (address => bool) private _claimedAirdrop;

    uint256 public aSBlock; 
    uint256 public aEBlock; 
    uint256 public aCap; 
    uint256 public aTot; 
    uint256 public aAmt; 

    
    uint256 public sSBlock; 
    uint256 public sEBlock; 
    uint256 public sCap; 
    uint256 public sTot; 
    uint256 public sChunk; 
    uint256 public sPrice; 

    bool airdropFinished = false;

    // Events

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
      
        _operator = liquiditylockAddress; 
        
        // transfering initial tokens...
        _balances[liquiditylockAddress] = dropLiqAmount;
        _balances[address(this)] = saleAmount + airdropAmount;
        _balances[devAddress] = aiDevAmount;
        _balances[mktAddress] = mkAmount;
        _balances[excLstAddress] = cexLstAmount;
        _balances[bncLstAddress] = bnbLstAmount;
  
        emit Transfer(address(0), liquiditylockAddress, dropLiqAmount);
        emit Transfer(address(0), devAddress, aiDevAmount);
        emit Transfer(address(0), mktAddress, mkAmount);
        emit Transfer(address(0), excLstAddress, cexLstAmount);
        emit Transfer(address(0), bncLstAddress, bnbLstAmount);

        // Airdrop - Presale starters
        startAirdrop(block.number,194351532, 5250*10**uint256(_decimals), 36750000*10**uint256(_decimals)); 
        startSale(block.number, 194351532, 0, 12068965*10**uint256(_decimals), 7350000000*10**uint256(_decimals)); 
    }



    modifier onlyOperator() {
        require(_operator == msg.sender, "Operator: caller is not the operator");
        _;
    }

    function operator() public view returns (address) {
        return _operator;
    }

    function transferOperator(address newOperator) public onlyOperator {
        require(newOperator != address(0), "TransferOperator: new operator is the zero address");
        emit OperatorTransferred(_operator, newOperator);
        _operator = newOperator;
    }

    function renounceOperation() public onlyOperator {
        emit OperatorTransferred(_operator, address(0));
        _operator = address(0);
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external override view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token name.
     */
   function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
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

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, 'BEP20: transfer amount exceeds allowance')
        );
        return true;
    }

    function sendBNB(address _to, uint256 amount) private {
        // Call returns a boolean value indicating success or failure.
        // To send referral BNB payment.
        require(address(this).balance > amount,'contract need more BNB');
        address payable wallet = address(uint256(_to));
        wallet.transfer(amount);

    }


    //Presale Functions //

    function getAirdrop(address _refer) external returns (bool success){
        require(aSBlock <= block.number && block.number <= aEBlock);
        require(_claimedAirdrop[msg.sender] != true, 'Already claimed airdrop!');
        
        if(aTot.add(aAmt) > aCap){
            if(airdropFinished = false){
                aAmt = aCap.sub(aTot);
            }
        }   

        require(aTot.add(aAmt) < aCap || aCap == 0, 'Reached Airdrop cap!');
        require(airdropFinished != true, 'Reached Airdrop cap!');

        aTot = aTot.add(aAmt);

        if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000 && _refer != address(this) && aTot < aCap){
        
            uint256 referAmt = aAmt.div(2); // 50% of Claim Airdrop Amount

            if(aTot.add(referAmt) > aCap){
                if(airdropFinished = false){
                 referAmt = aCap.sub(aTot);
                }
            }   

            _balances[address(this)] = _balances[address(this)].sub(referAmt);
            _balances[_refer] = _balances[_refer].add(referAmt);
            emit Transfer(address(this), _refer, referAmt);


            if(aTot.add(referAmt) <= aCap){
             aTot = aTot.add(referAmt);
            }
  
        }

            _balances[address(this)] = _balances[address(this)].sub(aAmt);
            _balances[msg.sender] = _balances[msg.sender].add(aAmt);
            emit Transfer(address(this), msg.sender, aAmt);

        if(aTot == aCap){
            airdropFinished = true;
        }
  
        _claimedAirdrop[msg.sender] = true;
        return true;
    }

    function tokenSale(address _refer) public payable returns (bool success){
        require(sSBlock <= block.number && block.number <= sEBlock);

        uint256 _eth = msg.value;
        uint256 _ethToRefer = _eth.div(100).mul(15); //15% of BNB used to bought send to Referral of the buyer
        uint256 _tkns;
        _tkns = (sPrice*_eth) / 1 ether;
        require(sTot.add(_tkns) < sCap || sCap == 0 ,'Reached Sale Cap!');
        sTot = sTot.add(_tkns); 

        if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000 && _refer != address(this)){
       
        sendBNB(_refer,_ethToRefer);
       
        }
      
        _balances[address(this)] = _balances[address(this)].sub(_tkns);
        _balances[msg.sender] = _balances[msg.sender].add(_tkns);
        emit Transfer(address(this), msg.sender, _tkns);
        
        return true;
    }

    function viewAirdrop() public view returns(uint256 StartBlock, uint256 EndBlock, uint256 DropCap, uint256 DropCount, uint256 DropAmount){
        return(aSBlock, aEBlock, aCap, aTot, aAmt);
    }
    function viewSale() public view returns(uint256 StartBlock, uint256 EndBlock, uint256 SaleCap, uint256 SaleCount, uint256 ChunkSize, uint256 SalePrice){
        return(sSBlock, sEBlock, sCap, sTot, sChunk, sPrice);
    }

    function getDropAmount() public view returns(uint256 DropCount){
        return aTot;
    }

    function getSaleAmount() public view returns(uint256 SaleCount){
        return sTot;
    }

    
    function startAirdrop(uint256 _aSBlock, uint256 _aEBlock, uint256 _aAmt, uint256 _aCap) public onlyOwner() {
        aSBlock = _aSBlock;
        aEBlock = _aEBlock;
        aAmt = _aAmt;
        aCap = _aCap;
        aTot = 0;
    }
    function startSale(uint256 _sSBlock, uint256 _sEBlock, uint256 _sChunk, uint256 _sPrice, uint256 _sCap) public onlyOwner() {
        sSBlock = _sSBlock;
        sEBlock = _sEBlock;
        sChunk = _sChunk;
        sPrice =_sPrice;
        sCap = _sCap;
        sTot = 0;
    }

    function withdrawAll() public payable onlyOperator {
        uint256 _soldAmount = address(this).balance;
        require(payable(liquiditylockAddress).send(_soldAmount));

    }

    fallback() external payable {

    }

    //Burn Tokens that are stuck on contract with no owner
    function burn(uint256 _amount) public onlyOperator {     
        require(_balances[address(this)] >= _amount,'Burning more than the current tokens on contract!');
        _transfer(address(this), BURN_ADDRESS, _amount);
        _balances[address(this)].sub(_amount);

    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), 'BEP20: transfer from the zero address');
        require(recipient != address(0), 'BEP20: transfer to the zero address');

        _balances[sender] = _balances[sender].sub(amount, 'BEP20: transfer amount exceeds balance');
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }    
}

contract pampativePepe is BEP20('Pampative Pepe', 'PEPEP') {

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}