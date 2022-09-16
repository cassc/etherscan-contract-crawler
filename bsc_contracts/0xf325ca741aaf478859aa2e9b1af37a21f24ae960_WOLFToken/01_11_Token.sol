/**
 * SPDX-License-Identifier: UNLICENSED
 * 
 */
pragma solidity ^0.8.7;
import "./Context.sol";
import "./IBEP20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Loyalty.sol";
import "./SafeLoyalty.sol";
import "./Genealogy.sol";
import "./SafeGenealogy.sol";
import "./SafeBEP20.sol";

contract WOLFToken is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using SafeLoyalty for Loyalty;
    using SafeGenealogy for Genealogy;
    using SafeBEP20 for IBEP20;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping(address => bool) private whitelistedAddresses;

    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _symbol;
    string private _name;
    address private pairAddress;
    address private genealogyAddress;
    address [] private taxAddress;
    uint256 [] private taxPercentageIndividual;
    uint256 private taxPercentage;

    constructor(address _receiver,uint256 _taxPer, address[] memory _taxAddress,uint256[] memory _taxPerIndividual,address _genealogyAddress)  {
        _name = "WOLF Token";
        _symbol = "WOLF";
        _decimals = 4;
        _totalSupply = 9000000*(uint256(10) ** _decimals);
        _balances[_receiver] = _totalSupply;
        taxPercentage=_taxPer;
        taxAddress=_taxAddress;
        taxPercentageIndividual=_taxPerIndividual;
        genealogyAddress=_genealogyAddress;
        emit Transfer(address(0), _receiver, _totalSupply);
    }

   /**
    * @dev Returns the bep token owner.
    */
   
    function  getOwner() override external view returns (address) {
        return owner();
    }

   /**
    * @dev Returns the token decimals.
    */
    function decimals() override external view returns (uint8) {
        return _decimals;
    }

  /**
   * @dev Returns the token symbol.
   */
    function symbol() override external view returns (string memory) {
        return _symbol;
    }

  /**
   * @dev Returns the token name.
   */
    function name() override external view returns (string memory) {
        return _name;
    }

  /**
   * @dev See {BEP20-totalSupply}.
   */
    function totalSupply() override external view returns (uint256) {
        return _totalSupply;
    }

  /**
   * @dev See {BEP20-balanceOf}.
   */
    function balanceOf(address account) override external view returns (uint256) {
        return _balances[account];
    }

  /**
   * @dev See {BEP20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
    function transfer(address recipient, uint256 amount) override external returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

  /**
   * @dev See {BEP20-allowance}.
   */
    function allowance(address owner, address spender) override external view returns (uint256) {
        return _allowances[owner][spender];
    }

  /**
   * @dev See {BEP20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
    function approve(address spender, uint256 amount) override external returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

  /**
   * @dev See {BEP20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {BEP20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for `sender`'s tokens of at least
   * `amount`.
   */
    function transferFrom(address sender, address recipient, uint256 amount) override external returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");

        if(isWhitelisted(sender)==true || isWhitelisted(recipient)==true){
             _balances[recipient] =_balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
            if(_balances[recipient] == 0){
                Genealogy _gen= Genealogy(genealogyAddress);
                _gen.safeSetSponsor(recipient, address(msg.sender));    
            }
        }
        else if ((sender == pairAddress || recipient == pairAddress) && taxPercentage>0){
            uint256 fee=amount.mul(taxPercentage).div(1000);
            _balances[recipient] =_balances[recipient].add(amount.sub(fee));
            for(uint256 i=0;i<taxPercentageIndividual.length;i++){
                uint256 ownFees=fee.mul(taxPercentageIndividual[i]).div(1000);
                _balances[taxAddress[i]]=_balances[taxAddress[i]].add(ownFees);
                emit Transfer(sender, taxAddress[i], ownFees);
                if(i==0){
                    Loyalty _loyalty= Loyalty(taxAddress[0]);
                    if(sender == pairAddress){//Buy
                        _loyalty.safeAddInChunk(recipient, ownFees); 
                    }
                    else if(recipient == pairAddress){//Sell
                        _loyalty.safeAddInChunk(sender, ownFees); 
                    }
                }
            }
            emit Transfer(sender, recipient, amount.sub(fee));
        } 
        else {
            if(_balances[recipient] == 0){
                Genealogy _gen= Genealogy(genealogyAddress);
                _gen.safeSetSponsor(recipient, address(msg.sender));    
            }
            _balances[recipient] =_balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
            
        }
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
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

   /**
    * Set Pair Address {DEX Swap Pair}
    */
    function setPairAddress(address _pairAddress) public onlyOwner{
        pairAddress = _pairAddress;
    }

    /**
     * Get Pair Address
     */
    function getPairAddress() public view returns(address){
        return pairAddress ;
    }

    /**
     * Set TAX Collection Address []
     */
    function setTaxAddress(address [] memory _taxAddress) public onlyOwner{
        taxAddress = _taxAddress;
    }

    /**
     * Get TAX Collection Address Must be in sequnce 
     */
    function getTaxAddress() public view returns(address[] memory){
        return taxAddress ;
    }

    /**
     * Set Tax Percentage 
     */
    function setTaxPercentage(uint256 _taxPercentage) public onlyOwner{
        taxPercentage = _taxPercentage;
    }

    /**
     * Get Tax Percentage
     */
    function getTaxPercentage() public view returns(uint256){
        return taxPercentage ;
    }

    /**
     * Set Tax Percentage Must be in sequence  Individual
     */
    function setTaxPercentageIndividual(uint256[] memory  _taxPercentageIndividual) public onlyOwner{
        taxPercentageIndividual = _taxPercentageIndividual;
    }

    /**
     * Get Tax Percentage Individual
     */
    function getTaxPercentageIndividual() public view returns(uint256[] memory){
        return taxPercentageIndividual ;
    }

    /**
     * Set Whitelist Address
     */
    function addWhitelist(address _address) public onlyOwner {
        whitelistedAddresses[_address] = true;
    }

    /**
     * remove Whitelist Address
     */
    function removeWhitelist(address _address) public onlyOwner {
        whitelistedAddresses[_address] = false;
    }

    /**
     * check is whitelisted
     */
    function isWhitelisted(address _address) public view returns(bool) {
        return whitelistedAddresses[_address];
    }

    /**
     * Set Genealogy Address
     */ 
    function setGenealogyAddress(address _genealogyAddress)public onlyOwner{
        genealogyAddress=_genealogyAddress;
    }

    /**
     * Get Genealogy address
     */ 
    function getGenealogyAddress()external view returns(address){
        return genealogyAddress;
    }

    /**
     * Admin Payout
     */ 
    function adminPayout(address contractAddress,address receiver,uint256 amount)public onlyOwner returns(uint256){
        IBEP20 _admin= IBEP20(contractAddress);
        _admin.safeTransfer(receiver, amount);
        return 0;
    }
}