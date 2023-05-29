// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract ChilliSwapToken is Ownable , IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private whiteList;

    uint256 private _totalSupply;

    string private _name ;
    string private _symbol ;
    uint8 private _decimals;

    uint256 public constant multiplier = (10**18);

    uint256 public lastDevRelease;
    uint256 public lastTeamRelease;

    address team;
    address dev;

    uint256 public releaseStartDate;

    uint256 totalDevMinted;
    uint256 totalTeamMinted;

    constructor (  
        address _development,
        address _team,
        address _ido,
        address _farming,
        address _airdrops,
        address _bounties,
        address _treasary,
        address _privateSale
        ) {
        _decimals = 18;
        _name = "ChilliSwap Token";
        _symbol = "CHLI";
        _mint(_ido, 30_000_000 * multiplier);
        _mint(_farming, 75_000_000 * multiplier);
        _mint(_privateSale,45_000_000 * multiplier);
        _mint(_airdrops, 7_500_000 * multiplier);
        _mint(_bounties, 7_500_000 * multiplier);
        _mint(_treasary, 60_000_000 * multiplier);

        team = _team;
        dev = _development;

        releaseStartDate = 1635602850;
    }

    function devRelease() public {
        if (lastDevRelease == 0) {
            require(
                releaseStartDate <= block.timestamp,
                "token: release not started"
            );
            _mint(dev, 5_625_000 * multiplier);
            lastDevRelease = releaseStartDate;
            totalDevMinted += 5_625_000;
        } else {
            require(
                totalDevMinted <= 75_000_001 * multiplier,
                "token: let the quarter over"
            );
            require(
                block.timestamp >= lastDevRelease + 7776000,
                "token: let the quarter over"
            );
            _mint(dev, 5_625_000 * multiplier);
            lastDevRelease = lastDevRelease + 7776000;
            totalDevMinted += 5_625_000;
        }
    }

    function teamRelease() public {
        if (lastTeamRelease == 0) {
            require(
                releaseStartDate <= block.timestamp,
                "token: release not started"
            );
            _mint(dev, 3_750_000 * multiplier);
            lastTeamRelease = releaseStartDate;
            totalTeamMinted += 3_750_000;
        } else {
            require(
                totalTeamMinted <= 30_000_001 * multiplier,
                "token: let the quarter over"
            );
            require(
                block.timestamp >= lastTeamRelease + 7776000,
                "token: let the quarter over"
            );
            _mint(team, 3_750_000 * multiplier);
            lastTeamRelease = lastTeamRelease + 7776000;
            totalTeamMinted += 3_750_000;
        }
    }

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
     * Ether and Wei.
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
    function transfer(address recipient, uint256 amount) public virtual override isUserwhiteListed() returns (bool) {
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
    function approve(address spender, uint256 amount) public virtual override isUserwhiteListed() returns (bool) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override isUserwhiteListed() returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual isUserwhiteListed() returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual isUserwhiteListed() returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function burn(uint256 _amount) external{
       _burn(msg.sender,_amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function checkIsUserWhiteListed(address _user) public view returns(bool){
        return !whiteList[_user];
    }

    function whiteListAddress(address _user ,bool _varaible) external onlyOwner{
         whiteList[_user] = !_varaible;
    }

    modifier isUserwhiteListed(){
        require(!whiteList[msg.sender],"you are not whitelisted");
        _;
    }
}