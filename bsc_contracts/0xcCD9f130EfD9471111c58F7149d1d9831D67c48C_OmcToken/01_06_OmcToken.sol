//SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract OmcToken is ERC20 {

    using SafeMath for uint256;

    address private _owner;
    address private pair;
    address constant feeA = 0x0F9dF9b3Ab08DF8dBB469d847B6bc3761d65d0CA;
    address constant feeB = 0x5edFc93f5E133F4283Cc82caCc2088dF32E66379;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor(string memory _name,string memory _symbol)  ERC20(_name,_symbol)   {
        _mint(_msgSender(),94860255123*10**12);
        _mint(address(0x0),5139744877*10**12);
        _owner = _msgSender();
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

        /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function setPair(address _pair) public virtual onlyOwner {
        pair = _pair;
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address from = _msgSender();
        _takeFee(from, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _takeFee(from, to, amount);
        return true;
    }

    
    function _takeFee(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        if(pair != address(0) && from == pair || to == pair){
            uint256 fee = amount.div(100);
            _transfer(from, feeA, fee);
            amount = amount.sub(fee);
            _transfer(from, feeB, fee);
            amount = amount.sub(fee);
            uint256 burnAmount = fee.mul(3);
            _burn(from,burnAmount);
            amount = amount.sub(burnAmount);
        }
        _transfer(from, to, amount);
    }
}