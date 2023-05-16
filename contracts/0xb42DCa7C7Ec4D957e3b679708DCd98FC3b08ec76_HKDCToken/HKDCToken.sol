/**
 *Submitted for verification at Etherscan.io on 2023-05-16
*/

// File: contracts/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

}

// File: contracts/Pausable.sol

pragma solidity ^0.6.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: contracts/Ownable.sol

pragma solidity ^0.6.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/BlackList.sol
pragma solidity ^0.6.2;


contract BlackList is Ownable{

    mapping (address => bool) public blackList;

    event AddedBlackList(address _user);

    event RemovedBlackList(address _user);

    constructor() internal{}
    
    function addBlackList(address _user) external onlyOwner {
        blackList[_user] = true;
        emit AddedBlackList(_user);
    }

    function removeBlackList(address _user) external onlyOwner {
        blackList[_user] = false;
        emit RemovedBlackList(_user);
    }

    function isBlackListUser(address _user) public view returns (bool){
        return blackList[_user];
    }

    modifier isNotBlackUser(address _user) {
        require(!isBlackListUser(_user), "BlackList: this address is in blacklist");
        _;
    }

}

// File: contracts/Votable.sol
pragma solidity ^0.6.2;


contract Votable is Ownable{

    // voter->bool
    mapping(address => bool) public voters;

    // voters count
    uint16 public votersCount = 0;

    // pid->proposal
    mapping(uint16 => Proposal) public proposals;

    // next pid, start with 10000
    uint16 public nextPid = 10000;

    constructor() internal{
        // init owner as a voter
        voters[owner()] = true;
        votersCount++;
        emit AddVoter(owner());
    }

    // struct of proposal
    struct Proposal {
        uint16 pid;
        uint16 count;
        bool done;
        bytes payload;
        // voter->bool
        mapping(address => bool) votes;
    }

    // events
    event OpenProposal(uint16 pid);

    event CloseProposal(uint16 pid);

    event DoneProposal(uint16 pid);

    event VoteProposal(uint16 pid, address voter);

    event AddVoter(address voter);

    event RemoveVoter(address voter);

    // modifiers
    modifier proposalExistAndNotDone(uint16 _pid){
        require(proposals[_pid].pid == _pid, "Votable: proposal not exists");
        require(!proposals[_pid].done, "Votable: proposal is done");
        _;
    }

    modifier onlyVoters(){
        require(voters[_msgSender()], "Votable: only voter can call");
        _;
    }

    modifier onlySelf(){
        require(_msgSender() == address(this), "Votable: only self can call");
        _;
    }

    // for inheriting
    function _openProposal(bytes memory payload) internal{
        uint16 pid = nextPid++;
        proposals[pid] = Proposal(pid,0,false,payload);
        emit OpenProposal(pid);
    }

    // vote
    function voteProposal(uint16 _pid) public onlyVoters proposalExistAndNotDone(_pid){
        Proposal storage proposal = proposals[_pid];
        require(!proposal.votes[_msgSender()], "Votable: duplicate voting is not allowed");

        proposal.votes[_msgSender()] = true;
        proposal.count++;
        emit VoteProposal(_pid, _msgSender());

        // judge
        _judge(proposal);
    }

    function _judge(Proposal storage _proposal) private{
        if(_proposal.count > votersCount/2){
            (bool success, ) = address(this).call(_proposal.payload);
            require(success, "Votable: call payload failed");
            _proposal.done = true;
            emit DoneProposal(_proposal.pid);
        }
    }

    // hasVoted
    function hasVoted(uint16 _pid) public view returns(bool){
        Proposal storage proposal = proposals[_pid];
        require(proposal.pid == _pid, "Votable: proposal not exists");
        return proposal.votes[_msgSender()];
    }

    // translate proposal
    // function translateProposal(uint16 _pid) external view returns(bytes32, address, uint256){
    //     Proposal memory proposal = proposals[_pid];
    //     require(proposal.pid == _pid, "Votable: proposal not exists");
    //     return abi.decode(abi.encodePacked(bytes28(0), proposal.payload),(bytes32,address,uint256));
    // }

    // onlySelf: match to proposals
    function addVoter(address _voter) external onlySelf{
        require(!voters[_voter], "Votable: this address is already a voter");
        voters[_voter] = true;
        votersCount++;
        emit AddVoter(_voter);
    }

    function removeVoter(address _voter) external onlySelf{
        require(voters[_voter], "Votable: this address is not a voter");
        require(_voter != owner(), "Votable: owner can not be removed");
        voters[_voter] = false;
        votersCount--;
        emit RemoveVoter(_voter);
    }

    // onlyOwner
    // open proposals
    function openAddVoterProposal(address _voter) external onlyOwner{
        _openProposal(abi.encodeWithSignature("addVoter(address)",_voter));
    }

    function openRemoveVoterProposal(address _voter) external onlyOwner{
        _openProposal(abi.encodeWithSignature("removeVoter(address)",_voter));
    }

    // close proposal
    function closeProposal(uint16 _pid) external proposalExistAndNotDone(_pid) onlyOwner{
        proposals[_pid].done = true;
        emit CloseProposal(_pid);
    }

}

// File: contracts/IERC20.sol

pragma solidity ^0.6.0;

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

// File: contracts/SafeMath.sol

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
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
}

// File: contracts/ERC20.sol
pragma solidity ^0.6.2;




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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

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
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
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
    function totalSupply() public virtual view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public virtual view override returns (uint256) {
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

// File: contracts/ERC20WithFeeAndRouter.sol
pragma solidity ^0.6.2;



contract ERC20WithFeeAndRouter is ERC20, Ownable {

  uint256 public basisPointsRate = 0;
  uint256 public maximumFee = 0;
  uint256 public routerFee = 18000000;
  string public prefix = "\x19Ethereum Signed Message:\n32";
  address public receivingFeeAddress;
  mapping (address => bool) private _routers;

  constructor (string memory name, string memory symbol) public ERC20(name, symbol) {}

  function addRouter(address _router) public onlyOwner {
      _routers[_router] = true;
  }

  function removeRouter(address _router) public onlyOwner {
      _routers[_router] = false;
  }

  function updateReceivingFeeAddress(address _receivingFeeAddress) public onlyOwner{
    receivingFeeAddress = _receivingFeeAddress;
  }

  function isRouter(address _router) public view returns (bool) {
      return _routers[_router];
  }

  function _isByRouter() internal view returns (bool) {
      return _routers[msg.sender];
  }

  function _calcFee(uint256 _value) internal view returns (uint256) {
    uint256 fee = (_value.mul(basisPointsRate)).div(10000);
    if (fee > maximumFee) {
        fee = maximumFee;
    }
    return fee;
  }

  function transfer(address _to, uint256 _value) public override virtual returns (bool) {
    uint256 fee = _calcFee(_value);
    uint256 sendAmount = _value.sub(fee);
    super.transfer(_to, sendAmount);
    if (fee > 0) {
      super.transfer(receivingFeeAddress, fee);
    }
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public override virtual returns (bool) {
    require(_to != address(0), "ERC20WithFee: transfer to the zero address");
    require(_value <= balanceOf(_from), "ERC20WithFee: transfer amount exceeds balance");
    require(_value <= allowance(_from, msg.sender), "ERC20WithFee: allowance amount exceeds allowed");
    uint256 fee = _calcFee(_value);
    uint256 sendAmount = _value.sub(fee);
    _transfer(_from, _to, sendAmount);
    if (fee > 0) {
      _transfer(_from, receivingFeeAddress, fee);
    }
    _approve(_from, msg.sender, allowance(_from, msg.sender).sub(_value, "ERC20WithFee: transfer amount exceeds allowance"));
    return true;

  }

  function setFeeParams(uint256 newBasisPoints, uint256 newMaxFee) public onlyOwner {
    basisPointsRate = newBasisPoints;
    maximumFee = newMaxFee.mul(uint256(10)**decimals());
  }

  function setRouterFee(uint256 newRouterFee) public onlyOwner {
    routerFee = newRouterFee.mul(uint256(10)**decimals());
  }

  function transferByBatchEach(address _to, uint256 _value) public{
    uint256 fee = _calcFee(_value);
    uint256 sendAmount = _value.sub(fee);
    super.transfer(_to, sendAmount);
    if (fee > 0) {
      super.transfer(receivingFeeAddress, fee);
    }
  }

  function transferFromByBatchEach(address _from, address _to, uint256 _value) public{
    if(_to != address(0) && _value <= balanceOf(_from) && _value <= allowance(_from, msg.sender)){
      uint256 fee = _calcFee(_value);
      uint256 sendAmount = _value.sub(fee);
      _transfer(_from, _to, sendAmount);
      if (fee > 0) {
        _transfer(_from, receivingFeeAddress, fee);
      }
      _approve(_from, msg.sender, allowance(_from, msg.sender).sub(_value, "ERC20WithFee: transfer amount exceeds allowance"));
    }
  }

  // 验证并发送转账交易
  function transferFromByRouterEach(address _from,address _to,uint256 _value,bytes32 _r,bytes32 _s,uint8 _v) public onlyRouter{
    if(getVerifySignatureResult(_from,_to,_value, _r, _s, _v) == _from){
      _transferFromByRouter(_from,_to,_value);
    }
  }

  function _transferFromByRouter(address _from,address _to,uint256 _value) private{
    if(_to != address(0) && _value <= balanceOf(_from)){
      uint256 fee = _calcFee(_value);
      uint256 sendAmount = _value.sub(fee);
      sendAmount = sendAmount.sub(routerFee);
      _transfer(_from, _to, sendAmount);
      if (fee > 0) {
        _transfer(_from, receivingFeeAddress, fee);
      }
      if(routerFee > 0){
        _transfer(_from,tx.origin,routerFee);
      }
    }
  }

  // 查看交易签名对应的地址
  function getVerifySignatureResult(address _from,address _to,uint256 _value,bytes32 _r,bytes32 _s,uint8 _v) public view returns(address){
    return ecrecover(getSha3Result(_from,_to,_value), _v, _r, _s);
  }

  // 获取sha3加密结果
  function getSha3Result(address _from,address _to,uint256 _value) public view returns(bytes32){
    return keccak256(abi.encodePacked(prefix,keccak256(abi.encodePacked(_from,_to,_value,address(this)))));
  }

  modifier onlyRouter(){
    require(_routers[msg.sender], 'ERC20WithFeeAndRouter: caller is not the router');
    _;
  }
}

// File: contracts/UpgradedStandardToken.sol
pragma solidity ^0.6.2;


abstract contract UpgradedStandardToken is ERC20WithFeeAndRouter {
    uint256 public _totalSupply;
    function transferByLegacy(address from, address to, uint256 value) public virtual returns (bool);
    function transferFromByLegacy(address sender, address from, address spender, uint256 value) public virtual returns (bool);
    function approveByLegacy(address from, address spender, uint256 value) public virtual returns (bool);
    function increaseApprovalByLegacy(address from, address spender, uint256 addedValue) public virtual returns (bool);
    function decreaseApprovalByLegacy(address from, address spender, uint256 subtractedValue) public virtual returns (bool);
    function transferByBatchEachByLegacy(address _to, uint256 _value) public virtual;
    function transferFromByBatchEachByLegacy(address sender, address _from, address _to, uint256 _value) public virtual;
    function transferFromByRouterEachByLegacy(address sender, address _from,address _to,uint256 _value,bytes32 _r,bytes32 _s,uint8 _v) public virtual;
}

// File: contracts/HKDCToken.sol
pragma solidity ^0.6.2;






contract HKDCToken is ERC20WithFeeAndRouter, BlackList, Votable, Pausable {

    address public upgradedAddress;

    bool public deprecated;

    constructor(uint256 _initialSupply, uint8 _decimals) public ERC20WithFeeAndRouter("HKDC Token","HKDC") {
        _setupDecimals(_decimals);
        _mint(_msgSender(), _initialSupply);
    }

    event DestroyedBlackFunds(address indexed blackListedUser, uint256 balance);

    event Deprecate(address newAddress);

    // functions users can call
    // make compatible if deprecated
    function balanceOf(address account) public override view returns (uint256) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).balanceOf(account);
        } else {
            return super.balanceOf(account);
        }
    }

    function totalSupply() public override view returns (uint256) {
        if (deprecated) {
            return IERC20(upgradedAddress).totalSupply();
        } else {
            return super.totalSupply();
        }
    }

    function allowance(address owner, address spender) public override view returns (uint256 remaining) {
        if (deprecated) {
            return IERC20(upgradedAddress).allowance(owner, spender);
        } else {
            return super.allowance(owner, spender);
        }
    }

    // Allow checks of balance at time of deprecation
    function oldBalanceOf(address account) public view returns (uint256) {
        require(deprecated, "HKDCToken: contract NOT deprecated");
        return super.balanceOf(account);
    }

    // normal functions
    function transfer(address recipient, uint256 amount) public override isNotBlackUser(_msgSender()) returns (bool) {
        require(!isBlackListUser(recipient), "BlackList: recipient address is in blacklist");

        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).transferByLegacy(_msgSender(), recipient, amount);
        } else {
            return super.transfer(recipient, amount);
        }
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override isNotBlackUser(_msgSender()) returns (bool) {
        require(!isBlackListUser(sender), "BlackList: sender address is in blacklist");
        require(!isBlackListUser(recipient), "BlackList: recipient address is in blacklist");

        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).transferFromByLegacy(_msgSender(), sender, recipient, amount);
        } else {
            return super.transferFrom(sender, recipient, amount);
        }
    }

    function approve(address spender, uint256 amount) public override isNotBlackUser(_msgSender()) returns (bool) {
        require(!isBlackListUser(spender), "BlackList: spender address is in blacklist");

        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).approveByLegacy(_msgSender(), spender, amount);
        } else {
            return super.approve(spender, amount);
        }
    }

    function increaseAllowance(address spender, uint256 addedValue) public override isNotBlackUser(_msgSender()) returns (bool) {
        require(!isBlackListUser(spender), "BlackList: spender address is in blacklist");

        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).increaseApprovalByLegacy(_msgSender(), spender, addedValue);
        } else {
            return super.increaseAllowance(spender, addedValue);
        }
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public override isNotBlackUser(_msgSender()) returns (bool) {
        require(!isBlackListUser(spender), "BlackList: spender address is in blacklist");

        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).decreaseApprovalByLegacy(_msgSender(), spender, subtractedValue);
        } else {
            return super.decreaseAllowance(spender, subtractedValue);
        }
    }

    function burn(uint256 amount) public {
        require(!deprecated, "HKDCToken: contract was deprecated");
        super._burn(_msgSender(), amount);
    }

    // functions only owner can call
    // open proposals
    function openMintProposal(address _account, uint256 _amount) external onlyOwner{
        _openProposal(abi.encodeWithSignature("mint(address,uint256)", _account, _amount));
    }

    function openDestroyBlackFundsProposal(address _user) external onlyOwner{
        _openProposal(abi.encodeWithSignature("destroyBlackFunds(address)", _user));
    }

    // onlySelf: mint & burn
    function mint(address _account, uint256 _amount) public onlySelf {
        require(!deprecated, "HKDCToken: contract was deprecated");
        super._mint(_account, _amount);
    }

    function destroyBlackFunds(address _user) public onlySelf {
        require(!deprecated, "HKDCToken: contract was deprecated");
        require(isBlackListUser(_user), "HKDCToken: only fund in blacklist address can be destroy");
        uint256 dirtyFunds = balanceOf(_user);
        super._burn(_user, dirtyFunds);
        emit DestroyedBlackFunds(_user, dirtyFunds);
    }

    // pause
    function pause() public onlyOwner {
        require(!deprecated, "HKDCToken: contract was deprecated");
        super._pause();
    }

    function unpause() public onlyOwner {
        require(!deprecated, "HKDCToken: contract was deprecated");
        super._unpause();
    }

    // deprecate
    function deprecate(address _upgradedAddress) public onlyOwner {
        require(!deprecated, "HKDCToken: contract was deprecated");
        require(_upgradedAddress != address(0));
        deprecated = true;
        upgradedAddress = _upgradedAddress;
        emit Deprecate(_upgradedAddress);
    }

    // hook before _transfer()/_mint()/_burn()
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "Pausable: token transfer while paused");
    }

    function transferByBatch(address[] memory _recipients, uint256[] memory _amounts) public isNotBlackUser(_msgSender()) {
        if (deprecated) {
            for(uint256 i=0; i<_recipients.length; i++){
                if(!isBlackListUser(_recipients[i])){
                    return UpgradedStandardToken(upgradedAddress).transferByBatchEachByLegacy(_recipients[i], _amounts[i]);
                }
            }
        } else {
            for(uint256 i=0; i<_recipients.length; i++){
                if(!isBlackListUser(_recipients[i])){
                    return super.transferByBatchEach(_recipients[i], _amounts[i]);
                }
            }
        }
    }

    function transferFromByBatch(address[] memory _senders, address[] memory _recipients, uint256[] memory _amounts) public isNotBlackUser(_msgSender()){
        if (deprecated) {
            for(uint256 i=0; i<_senders.length; i++){
                if(!isBlackListUser(_senders[i]) && !isBlackListUser(_recipients[i])){
                    UpgradedStandardToken(upgradedAddress).transferFromByBatchEachByLegacy(_msgSender(), _senders[i], _recipients[i], _amounts[i]);
                }
            }
        } else {
            for(uint256 i=0; i<_senders.length; i++){
                if(!isBlackListUser(_senders[i]) && !isBlackListUser(_recipients[i])){
                    super.transferFromByBatchEach(_senders[i], _recipients[i], _amounts[i]);
                }
            }
        }
    }

    function transferFromByRouter(address[] memory _from,address[] memory _to,uint256[] memory _value,bytes32[] memory _r,bytes32[] memory _s,uint8[] memory _v) public onlyRouter{
        if (deprecated) {
            for(uint256 i=0; i<_from.length; i++){
                if(!isBlackListUser(_from[i]) && !isBlackListUser(_to[i])){
                    UpgradedStandardToken(upgradedAddress).transferFromByRouterEachByLegacy(_msgSender(), _from[i], _to[i], _value[i],_r[i],_s[i],_v[i]);
                }
            }
        } else {
            for(uint256 i=0; i<_from.length; i++){
                if(!isBlackListUser(_from[i]) && !isBlackListUser(_to[i])){
                    super.transferFromByRouterEach(_from[i], _to[i], _value[i],_r[i],_s[i],_v[i]);
                }
            }
        }
    }


}