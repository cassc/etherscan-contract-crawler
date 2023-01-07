// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@andskur/contracts/contracts/extension/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./IMLC.sol";

contract MLC is ERC20Upgradeable, Ownable, IMLC {

    // number of maximum token emission. If 0 - emission is not limited
    uint256 private _maxEmission;

    // addresses that can call mintTo function along with owner
    mapping(address => bool) private _minters;

    function initialize(string memory _name, string memory _symbol) external initializer {
        _setupOwner(msg.sender);
        __ERC20_init(_name, _symbol);
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
        return 0;
    }

    /*
    * @dev Sets `_minter`
    *
    * Requirements:
    * - only owner of the contract
    *
    * @param newMinter minter address.
    */
    function setMinter(address newMinter) external onlyOwner {
        _minters[newMinter] = true;
    }

    /*
    * @dev revoke `_minter`
    *
    * Requirements:
    * - only owner of the contract
    *
    * @param oldMinter minter address.
    */
    function revokeMinter(address oldMinter) external onlyOwner {
        delete _minters[oldMinter];
    }

    /*
    * @dev Mints `_amount` of tokens `_to` given address
    *
    * Requirements:
    * - total supply increased by `_amount` of tokens should not be more than number of maximum token emission
    * - `_amount` should be more than 0
    * - only owner of the contract
    *
    * @param _to       The recipient of the tokens to mint.
    * @param _amount   Quantity of tokens to mint.
    */
    function mintTo(address _to, uint256 _amount) external override(IMLC) {
        require(_canMint(), "Not authorized");
        require(_amount > 0, "Token amount must be more then 0!");
        require(_isEmissionAllowed(_amount), "Emission limit reached!");

        _mint(_to, _amount);
    }

    /*
    * @dev Transfers `_amount` of tokens to current contract address which is similar to burning, but does not affect
    * ERC-20 `totalSupply` method. See {ERC20-totalSupply}.
    *
    * Requirements:
    * - `_amount` of tokens to burn should be less or equal to user token balance
    *
    * @param _amount Quantity of tokens to burn (transfer to current contract address).
    */
    function burn(uint256 _amount) external override(IMLC) {
        require(balanceOf(msg.sender) >= _amount, "Not enough balance!");
        transfer(address(this), _amount);
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
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
        _transfer(from, to, amount);
        return true;
    }

    /*
     * @dev set number of maximum token emission
     *
     * Requirements:
     * - `maxEmission` must be more then current total supply or 0
     *
     * @param `maxEmission`- number of maximum token emission. If 0 - emission is not limited
     */
    function setMaxEmission(uint256 newMaxEmission) external onlyOwner {
        require(newMaxEmission > totalSupply() || newMaxEmission == 0, "Max emission must be 0 or more then total supply!");
        _maxEmission = newMaxEmission;
    }

    /*
     * @dev returns number of maximum token emission allowed `_maxEmission`
     */
    function maxEmission() public view onlyOwner returns(uint256) {
        return _maxEmission;
    }

    /*
     * @dev checks if emission is possible
     *
     * @param `amount` - number of tokens to emit
     *
     * @return true if emission is possible and false if not
     */
    function _isEmissionAllowed(uint256 amount) internal view returns (bool) {
        if (_maxEmission == 0 || amount + totalSupply() <= _maxEmission) {
            return true;
        } else {
            return false;
        }
    }

    /// @dev Returns whether tokens can be minted in the given execution context.
    function _canMint() internal view returns (bool) {
        return msg.sender == owner() || _minters[msg.sender];
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view override returns (bool) {
        return msg.sender == owner();
    }
}