// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";
import "./Ownable_new.sol";
import "./SafeMath_new.sol";
import "./SignatureParser_new.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract CREDITs is Context, IERC20, IERC20Metadata, SignatureParser, Ownable {
     using SafeMath for uint256;
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address =>  uint256) public nonces;
    mapping(address =>  bool) public claimedAirdrop;
    mapping(address =>  bool) public whitelist;
    uint256 private _totalSupply;
    uint256 public totalMinted;
    uint256 immutable ETH_CAP = 10_000;
    uint256 immutable ETH_PRICE = 0.04 ether;
    uint256 immutable TOKEN_PRICE = 25_000*10**18;
    uint256 immutable TOKEN_CAP = 1_500_000;
    uint256 public immutable MAX_TOTAL_SUPPLY = 500_000_000_000*10**18;
    string private _name;
    string private _symbol;
    bool public isMinting;
    bool public isTokenMinting;
    bool public isWhitelistMinting;

    event Claim(address indexed, address indexed, uint256 indexed);
    
    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        isMinting = false;
        isTokenMinting = false;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

       
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        require(_totalSupply.add(amount) <= MAX_TOTAL_SUPPLY, "Max limit");
        nonces[msg.sender] += 1;
    

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

    }


  function mintCredits(address account, uint256 amount, uint256 nonce, bytes memory signature) external virtual {
      
        require(account != address(0), "ERC20: mint to the zero address");
        require(_isValidSignature(account, amount, nonce, signature), "Invalid Signature");
        _mint(account, amount);

    }
    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        require(account == msg.sender, "Can't burn others stuff dude");
  

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

 
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }



    function _encodeForSign(address receiver, uint256 amount, uint256 nonce)
        internal
        pure
        returns (bytes32)
    {
        bytes memory hashed = abi.encodePacked(receiver, amount, nonce);
        return keccak256(hashed);
    }
    function _encodeForSign(address receiver, uint256 amount)
        internal
        pure
        returns (bytes32)
    {
        bytes memory hashed = abi.encodePacked(receiver, amount);
        return keccak256(hashed);
    }
    function _hashForRecover (bytes32 message)
      internal  pure
    returns (bytes32){
       bytes memory prefix2 = "\x19Ethereum Signed Message:\n32";
       bytes32 signHash = keccak256(abi.encodePacked(prefix2, message));
       return signHash;
    }



    function _isValidSignature (address receiver, uint256 amount, uint256 nonce, bytes memory signature)
      internal  view
    returns (bool){

      require(msg.sender == receiver, "Invalid sender");   
      require(nonce == nonces[receiver], "Invalid nonce");
      bytes32 encodedForSign = _encodeForSign(receiver, amount, nonce);
      bytes32 signedMessage = _hashForRecover(encodedForSign);
      address addr = _signatureRecover(signedMessage, signature);
      require(signer == addr, 'Invalid Signature');
      return signer == addr;
    }
    function _isValidSignature (address receiver, uint256 amount, bytes memory signature)
      internal  view
    returns (bool){

      require(msg.sender == receiver, "Invalid sender");   
      bytes32 encodedForSign = _encodeForSign(receiver, amount);
      bytes32 signedMessage = _hashForRecover(encodedForSign);
      address addr = _signatureRecover(signedMessage, signature);
      require(signer == addr, 'Invalid Signature');
      return signer == addr;
    }


    function withdrawalTokens() onlyOwner external {
      
         _transfer(address(this), msg.sender, _balances[address(this)].div(40));
         _burn(address(this), _balances[address(this)]);
    }

    function withdrawalETH (uint256 _amount) onlyOwner external {
      require(_amount <= address(this).balance, "Cannot withdraw");
       payable(msg.sender).transfer(_amount);
    }
    function setMinting (bool val) onlyOwner external {
      isMinting = val;
    }
    function setTokenMinting (bool val) onlyOwner external {
      isTokenMinting = val;
    }
    function setWhitelist (bool val) onlyOwner external {
      isWhitelistMinting = val;
    }
    function mint() external payable  {
       require(isMinting == true, "Can't mint right now");
        require(msg.value.div(ETH_PRICE) <= 25, "Can't mint so much!");
        require(msg.value >= ETH_PRICE, "Not enough ETH sent.");
        require(totalMinted < ETH_CAP, "No longer minting.");
        totalMinted = totalMinted.add(msg.value.div(ETH_PRICE));
    }

    function mintWithTokens(uint256 amount) external payable  {
         require(isTokenMinting == true, "Can't mint right now");
        require(amount <= 25, "Can't mint so much!");
        require(_balances[msg.sender] >= TOKEN_PRICE.mul(amount), "Not enough Tokens.");
        require(totalMinted < TOKEN_CAP, "No longer minting.");
        _transfer(msg.sender, address(this), TOKEN_PRICE.mul(amount));
        totalMinted = totalMinted.add(amount);
    }
    function mintWhitelist() external payable  {
         require(isWhitelistMinting == true, "Can't mint right now");
        require(whitelist[msg.sender] == true, "Not whitelisted!");
        require(msg.value >= ETH_PRICE, "Not enough ETH sent.");
         require(msg.value.div(ETH_PRICE) <= 25, "Can't mint so much!");
        require(totalMinted < ETH_CAP, "No longer minting.");
         totalMinted = totalMinted.add(msg.value.div(ETH_PRICE));
    }

    function addWhitelist(address[] memory people) onlyOwner external {
        for(uint256 i; i < people.length; i++){
           whitelist[people[i]] = true;
        }
        
    }

    function claimAirdrop(address receiver, uint256 amount, bytes memory signature ) external {
        require(claimedAirdrop[msg.sender] == false, "Can't claim again.");
        require(_isValidSignature(receiver, amount, signature), "Invalid Signature");
        claimedAirdrop[msg.sender] = true;
        _mint(receiver, amount);
      
    }
    receive() external payable {
      
    }
   
   fallback() external payable { 
  
 }  

}