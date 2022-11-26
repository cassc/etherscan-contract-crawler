// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./Authorizable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract RibbonVIPToken is Context, Authorizable, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    uint256 private _totalSupply;

    string private _name = "Ribbon VIP";
    string private _symbol = "RVIP";

    function mint(address to, uint256 amount) public onlyAuthorized {
        _mint(to, amount);
        emit Transfer(address(0), to, amount);
    }

    function burn(address from, uint256 amount) public onlyAuthorized {
        _burn(from, amount);
        emit Transfer(from, address(0), amount);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(
        address to,
        uint256 amount
    ) public virtual override onlyAuthorized returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @notice Dummy variable that always returns 5 to save on gas since allowance not used
     */
    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return 5;
    }

    /**
     * @notice Kept to adhere to ERC20, but unused since only owner can transfer tokens anyway
     */
    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        return true;
    }

    /**
     * @notice For the owner to transfer back tokens from unqualified addresses
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override onlyAuthorized returns (bool) {
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @notice Provided for convinience so individual burning not needed. Ensure balanceOf all provided addresses > 1.
     * @param addressesToBurn is the array of addresses whose token should be burnt
     *
     */
    function groupBurn(
        address[] calldata addressesToBurn
    ) external onlyAuthorized {
        uint256 addressesToBurnLen = addressesToBurn.length;
        for (uint256 i = 0; i < addressesToBurnLen; i++) {
            _burn(addressesToBurn[i], 1);
        }
    }

    /**
     * @notice Provided for convinience so indivdual minting not needed
     * @param addressesToMint is the array of addresses for whom a token should be minted
     *
     */
    function groupMint(
        address[] calldata addressesToMint
    ) external onlyAuthorized {
        uint256 addressesToMintLen = addressesToMint.length;
        for (uint256 i = 0; i < addressesToMintLen; i++) {
            _mint(addressesToMint[i], 1);
        }
    }

    /**
     * @notice Will update the holders of RVIP by minting for and burning tokens current holders' tokens as needed
     * @param addressesToRemove is the array of addresses whose token should be removed by internal burning
     * @param addressesToAdd is the array of addresses that should be given the token through internal minting
     *
     */
    function updateTokenHolders(
        address[] calldata addressesToAdd,
        address[] calldata addressesToRemove
    ) external onlyAuthorized {
        uint256 addressesToAddLen = addressesToAdd.length;
        uint256 addressesToRemoveLen = addressesToRemove.length;
        for (uint256 i = 0; i < addressesToAddLen; i++) {
            _mint(addressesToAdd[i], 1);
        }
        for (uint256 i = 0; i < addressesToRemoveLen; i++) {
            _burn(addressesToRemove[i], 1);
        }
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }
    }
}