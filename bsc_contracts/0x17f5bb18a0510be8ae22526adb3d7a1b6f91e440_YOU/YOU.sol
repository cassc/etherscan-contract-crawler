/**
 *Submitted for verification at BscScan.com on 2023-05-14
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
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
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
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

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: contracts/1_Storage.sol

pragma solidity ^0.8.0;



contract YOU is ERC20, Ownable {
    address private _pancakeSwapAddress;
    uint256 private _startTime;

    mapping(address => bool) private _whitelist;
    mapping(address => uint256) private _earlySellerBalances;

    address[] public recipients = [
        0x333bfB11CE4400B79385c34899D1960C21e6ABDb, 0x27c00426Fbafe42883985C73Ba1cEbc520a01Db6, 0x6eeDeD2aA814C8483372A6F719f60993154fc254, 0x99595167cbC7a5e95487BA65E99e4Aae4595f59E, 0xcc9C757C99493eFEa8B7548d457796F746d40311, 0xfd50aF37b85Fd98f6264A534D4D274949ED9045a, 0x0dA7062C36c0BB0846B4064Bc3E69B1aB224Ec2a, 0xF44307E163e5f7AEb26e0640ef45239fAA146f1D, 0x1265Bb5f06C633C0c7eAa711B89Ef6AdC59dbda5, 0xb723aB292820f8d259787a34173bE55E2529c1e1, 0xc17E4DE002b68660b3747d5bc30C1E825ff0630D, 0x3f89D03398441A3820fd1B65E2Ba1D3d58b82B07, 0x5e5B33cdF9344177EF710E337cDf76053174e1E8, 0x9caBFb3b7c8f9e6732583E8000B116fdBEf5c2DA, 0x418F7d8EbFbF36539EDc54D279f20002ec37754A, 0x22E6Aa82a39AD6c4C3CC7d9a0CFAd0e41614dd9b, 0xd1a374c27A9FfC8b3D91c30D475998eE9845790E, 0x7e5875D976549d9539B7C6588EA972635DA3A199, 0xEF65404a466b5B4FBeE99d59774223799B924F09, 0x140aeD810A2C1F9Cd0f1Ec59E21BA2639B551dE3, 0x82266eb9bd9652dB48A25275AdB977A986dca55F, 0x3bbcaf2297221901D995C80708540469065746e9, 0x43B0c64A30Cd61Bc12E7b3CEcA7353B114Ff5FF3, 0x987eb205FEC76177c136d5148f3b13219Da9C1F0, 0x36294fE49513Da300A3b2e89ED7d9a27083b6394, 0x69Efa85259ACfda981390B190f8C4c6bBDdc38f5, 0xe66B3BEE8d08E8315C9c7524EB368559504D1194, 0x579DEb676E7d66a0F524c9E4e5924683145C0B01, 0xE2E7bCc01EAA42EeB6B8E3B0c53fF869b42096aa, 0x8941B4f0bf0Ced7cC1c602882394378bf6a57E83, 0x8224b71068c84559222cf21a484370faea659408, 0x64A85dd20d7644521ee75976b472D62c9A8FE795, 0x620E2f660465BD9D952816941911EEF117b845E4, 0xB96f46A79243D02E0AfedCFf80d84EF73D5Cc7b3, 0xcd219154347025e7eA1b0a91c571b97BC2eDAA89, 0xA7bacade01B0EEa95D141cf445Fe172FC9F33F4b, 0xdcA2365F155fD1dDe5C14DC10Dd745B8Cb866492, 0xF6981D6C844cB41A5ca4557B57271079511ee035, 0xAA8916E7DcAAf1FB75bd1c1279584DB364F65FB2, 0x1194CE3Afe7DCA51242e2530e3D2258Bc9857079, 0x0A2F9B7599fDD68Ca7709ed3ED75929527F9FCc4, 0x5bC511d4192D1b965AbA889A64Ec5F940C12e11B, 0xa0ac974C7251D217A172c0391AB06491783a9B74, 0x0a3c8Ae917879E64c05df59Ff65b85282F345849, 0x23c1d7ad729FDe37B369d3125B3075f5465A8eE5, 0xe80e46314e0CD7214f82b76D2c77C5Cc25E62e21, 0x2505d1d33eC918F0f09efA0e9FE6C9185Ec695e2, 0xD668A5d02296E146567e39d05fc0AD371c9B998d, 0xADACfDF29CbF855E8726C8Ce9D1cA6E8DfD34cF9, 0x712231df57Bc4cfd474Dc761A2Ee6fe33F64b955, 0xc70137DC77D9b2fc30F4373e635b2CFa6d54ABd1, 0x262b8800f25D628947dE98BB2F9839aE580Fc8d4, 0xF3D6B91505b1f7613433345E598fa299CFD8984A, 0x9553CFBB01e9783D7BBd1a767AC17b1B51b7bae0, 0xfD9486d7A07d1279bcaE9c6C06B1a531F1219D72, 0x42962f2cDef53870dBa9Bd9586F8B3d484a8d98d, 0x2D5D2F4Fd3BEE2324BBd32414395C39522a17ec5, 0x874DbDE80Cb28E9c4B6B31Ab0EE2092DfA5E1276, 0x841AF74C54057d8505a9c126362409A68590edB3, 0xbA6f09875Da66BC8274Fd28172Fe8bABb70941e9, 0xeAB4DFb4f48483798aB5267D658b86829FD0C816, 0x8B84DAd1Ac9dd6841eccf65C4d7035eAfcBCd8A5, 0x5C0c317c617f93Ef13Bf75E59BAA3D31C86B3Bd9, 0x588465660A8f5294d25C6e878f155ea40a52eAFc, 0x5573AFA80B2BB429ed9A97f7a75d8076Ac68D2bb, 0xECED8612c54e4Fdd500A8CAB1a3c3C28F4543e1F, 0xF0DeC3465598c5016e4C52Bfff611BBd612dBe85, 0xBeBf79F3C65D98B7EA29C7d9AC468C6A27c9B085, 0xFE73c5485bA3C2432632F7bb6933EF749100ec03, 0xF1a7cf174370B1CC4fA0C0b6b24E8fe6a8DB73B6, 0xD3317b7312268457Fabf59257cD2CeA17CfDb28E, 0x94d5450196D9a1D6dA590BD0598bCA2812f50BC0, 0xb61d5E6dC6b404Ea96123AE980D569060e34E7Ce, 0xf75fA19Ee2aAEAE5DeA80DEAf12CE31C9a76F569, 0xae82BfB88F2a10c24D3d4CAb01cA3599c739bC96, 0x635A889780b7f684e84f235Cd5615aC71ae71E5B, 0xd2Aac14625e7f2eFD9a3147623ffC9c02596a146, 0x742510B72E99aaF45b1d4A216267dF6f64A0D424, 0x2199d5AD619f75153dA56C6f2159898B0C3ce6BC, 0xE11dd006AC225446eEBD63aF429f6A7d636F697a, 0x8D259aB975C7A001F7E55ffD72f7C754EE9892ad, 0x556f31B015B29F9123DD7a27F77DEF6Ba9373ba0, 0x2F8c4687D3e5fa1522e77e3376E810ec44CC23a2, 0xF403a2D39c28eC6a6BEC4004bd4E0fE5060d1C38, 0x3C92412910aC8Cc5cd130A672308e0BB30D78d03, 0x9AFbe1069B066bDB3007a3ee31Ae0F1A7A7BEBB2, 0xA428Db839EF23f1a9E0439202B413805573f5d7A, 0x4641Eb5CC392E095C0392BaADe145f11485b3BC4, 0x0bd4C6506f9e9c8c4A014463da884a66e7d62d24, 0x7DAC87606fDc0B3Ef470A39575449f5B19554098, 0x843805972fE4b5DfC29fa657922dB554bA90f41e, 0xe9d48ceA0Fb9ab3739136f6062E66275a16e4beb, 0x9b5d82caeBc3d250647662a044a112564c5692Ee, 0x305322BF1490AD84bF03FD87Aaa2e335964F1230, 0x3cE7276f27461BEf152E9EDF62dfb6f6C183A2b3, 0x7b2bB8eFD2d974564e2FE777b4a869a2F35D265D, 0xBed86557a536A43a145a4e2f1F7eDf01F267DA88, 0x4427CB2B1E3C2123e83B44E152C8CD03Ca16D00f, 0x1623695E4256e805711db7dc5F0B34Ade8d8E167, 0xB21362BD7Ab52f1fA8829189126bEC5E5DE3d9Bb
    ];

    constructor() ERC20("111", "111") {
    _startTime = block.timestamp;
    _whitelist[msg.sender] = true;
    _mint(msg.sender, 10_000_000_000 * 10**decimals());

       for (uint256 i = 0; i < recipients.length; i++) {
            uint256 randomAmount = random(100_000, 500_000);
            transfer(recipients[i], randomAmount * 10**decimals());
        }
}

  function random(uint256 lower, uint256 upper) internal view returns (uint256) {
        uint256 randomness = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        return randomness % (upper - lower) + lower;
    }

    function addToWhitelist(address account) public onlyOwner {
        _whitelist[account] = true;
    }

    function removeFromWhitelist(address account) public onlyOwner {
        _whitelist[account] = false;
    }

    function setPancakeSwapAddress(address pancakeSwapAddress) public onlyOwner {
        _pancakeSwapAddress = pancakeSwapAddress;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if (msg.sender == _pancakeSwapAddress || _whitelist[msg.sender]) {
         
            return super.transfer(recipient, amount);
        } else if (block.timestamp < _startTime + 30 days) {
          
            require(amount <= 1_000_000 * 10**decimals(), "Sales are limited to 1M tokens in the first month");
            _earlySellerBalances[msg.sender] += amount;
            require(_earlySellerBalances[msg.sender] <= 10_000_000 * 10**decimals(), "Cannot sell more than 10M tokens in total before one month");
        }

        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        if (sender == _pancakeSwapAddress || _whitelist[sender]) {
           
            return super.transferFrom(sender, recipient, amount);
        } else if (block.timestamp < _startTime + 30 days) {
           
            require(amount <= 1_000_000 * 10**decimals(), "Sales are limited to 1M tokens in the first month");
            _earlySellerBalances[sender] += amount;
            require(_earlySellerBalances[sender] <= 10_000_000 * 10**decimals(), "Cannot sell more than 10M tokens in total before one month");
        }

        return super.transferFrom(sender, recipient, amount);
    }
}