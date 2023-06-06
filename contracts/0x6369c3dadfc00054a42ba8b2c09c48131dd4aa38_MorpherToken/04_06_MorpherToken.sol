pragma solidity 0.5.16;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./MorpherState.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
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
contract MorpherToken is IERC20, Ownable {

    MorpherState state;
    using SafeMath for uint256;

    string public constant name     = "Morpher";
    string public constant symbol   = "MPH";
    uint8  public constant decimals = 18;
    
    modifier onlyState {
        require(msg.sender == address(state), "ERC20: caller must be MorpherState contract.");
        _;
    }

    modifier canTransfer {
        require(state.mainChain() == true || state.getCanTransfer(msg.sender), "ERC20: token transfers disabled on sidechain.");
        _;
    }
    
    event LinkState(address _address);

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(address _stateAddress, address _coldStorageOwnerAddress) public {
        setMorpherState(_stateAddress);
        transferOwnership(_coldStorageOwnerAddress);
    }

    // ------------------------------------------------------------------------
    // Links Token Contract with State
    // ------------------------------------------------------------------------
    function setMorpherState(address _stateAddress) public onlyOwner {
        state = MorpherState(_stateAddress);
        emit LinkState(_stateAddress);
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return state.totalSupply();
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address _account) public view returns (uint256) {
        return state.balanceOf(_account);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     * 
     * Emits a {Transfer} event via emitTransfer called by MorpherState
     */
    function transfer(address _recipient, uint256 _amount) public returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

   /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return state.getAllowance(_owner, _spender);
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address _spender, uint256 _amount) public returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `_sender` and `_recipient` cannot be the zero address.
     * - `_sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `_sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address _sender, address _recipient, uint256 amount) public returns (bool) {
        _transfer(_sender, _recipient, amount);
        _approve(_sender, msg.sender, state.getAllowance(_sender, msg.sender).sub(amount, "ERC20: transfer amount exceeds allowance"));
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
     * - `_spender` cannot be the zero address.
     */
    function increaseAllowance(address _spender, uint256 _addedValue) public returns (bool) {
        _approve(msg.sender, _spender, state.getAllowance(msg.sender, _spender).add(_addedValue));
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
    function decreaseAllowance(address _spender, uint256 _subtractedValue) public returns (bool) {
        _approve(msg.sender, _spender,  state.getAllowance(msg.sender, _spender).sub(_subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Caller destroys `_amount` tokens permanently
     *
     * Emits a {Transfer} event to zero address called by MorpherState via emitTransfer.
     *
     * Requirements:
     *
     * - Caller must have token balance of at least `_amount`
     * 
     */
     function burn(uint256 _amount) public returns (bool) {
        state.burn(msg.sender, _amount);
        return true;
    }

    /**
     * @dev Emits a {Transfer} event
     *
     * MorpherState emits a {Transfer} event.
     *
     * Requirements:
     *
     * - Caller must be MorpherState
     * 
     */
     function emitTransfer(address _from, address _to, uint256 _amount) public onlyState {
        emit Transfer(_from, _to, _amount);
    }

     /**
     * @dev Moves tokens `_amount` from `sender` to `_recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event via emitTransfer called by MorpherState
     *
     * Requirements:
     *
     * - `_sender` cannot be the zero address.
     * - `_recipient` cannot be the zero address.
     * - `_sender` must have a balance of at least `_amount`.
     */
    function _transfer(address _sender, address _recipient, uint256 _amount) canTransfer internal {
        require(_sender != address(0), "ERC20: transfer from the zero address");
        require(_recipient != address(0), "ERC20: transfer to the zero address");
        require(state.balanceOf(_sender) >= _amount, "ERC20: transfer amount exceeds balance");
        state.transfer(_sender, _recipient, _amount);
    }

    /**
     * @dev Sets `_amount` as the allowance of `spender` over the `owner`s tokens.
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
    function _approve(address _owner, address _spender, uint256 _amount) internal {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");
        state.setAllowance(_owner, _spender, _amount);
        emit Approval(_owner, _spender, _amount);
    }

    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    function () external payable {
        revert("ERC20: You can't deposit Ether here");
    }
}