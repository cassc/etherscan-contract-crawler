// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./interfaces/IRAX.sol";

contract RAXToken is IRAX, ERC20BurnableUpgradeable, ERC20CappedUpgradeable, AccessControlUpgradeable {

    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @dev Origin chain is BSC mainnet.
     */
    uint256 public constant ORIGIN_CHAINID = 56;

    /**
     * @dev Max possible supply.
     */
    uint256 public constant MAX_SUPPLY = 2500000000 ether;

    /**
     * @dev Bridge role id.
     */
    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");

    /**
     * @dev Crowdsale role id.
     */
    bytes32 public constant CROWDSALE_ROLE = keccak256("CROWDSALE_ROLE");

    /**
     * @dev DAO pool address.
     */
    address public DAOPool;

    /**
     * @dev Router address.
     */
    address public router;

    mapping(address => address) public referrers;

    modifier onlyOriginChain {
        require(block.chainid == ORIGIN_CHAINID, "RAX: not origin chain");
        _;
    }

    modifier onlyNonOriginChain {
        require(block.chainid != ORIGIN_CHAINID, "RAX: origin chain");
        _;
    }

    /**
     * @dev External initializer function, cause token is upgradable (see openzeppelin\proxy).
     */
    function initialize() public initializer
    {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        __ERC20_init("RAX Token", "RAX");
        __ERC20Capped_init(MAX_SUPPLY);
        if (block.chainid == ORIGIN_CHAINID)
            _mint(address(this), MAX_SUPPLY);
    }

    /**
     * @dev Set bridge `bridge_` address.
     */
    function setBridge(address bridge_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(bridge_ != address(0), "RAX: zero address given");
        _grantRole(BRIDGE_ROLE, bridge_);
    }

    /**
     * @dev Set router `router_` address. 0.2% fee are not applicable for router's tx.
     *
     * Pancake router in BSC. Any other popular one in other chains.
     */
    function setRouter(address router_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        router = router_;
    }

    /**
     * @dev Set `DAOPool_` address. DAO pool will get 0.1% fee from any user's transaction if he doesn't have referrer.
     */
    function setDAOPool(address DAOPool_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        DAOPool = DAOPool_;
    }

    /**
     * @dev Add crowdsale contract address `sale_` to the token.
     *
     * Can be added only in origin chain.
     */
    function addSale(address sale_) external onlyRole(DEFAULT_ADMIN_ROLE) onlyOriginChain {
        require(sale_ != address(0), "RAX: zero address given");
        _grantRole(CROWDSALE_ROLE, sale_);
    }

    /**
     * @dev Remove crowdsale contract address `sale_` from the token. 
     *
     * Can be removed only in origin chain.
     */
    function removeSale(address sale_) external onlyRole(DEFAULT_ADMIN_ROLE) onlyOriginChain {
        require(sale_ != address(0), "RAX: zero address given");
        _revokeRole(CROWDSALE_ROLE, sale_);
    }

    /** @dev Creates `amount` tokens and assigns them to `to`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Can be used in non-origin chain and only by bridge account.
     */
    function mint(address to, uint256 amount, address referrer) external onlyRole(BRIDGE_ROLE) onlyNonOriginChain {
        if (referrers[to] != address(0)) {
            referrers[to] = referrer;
        }
        _mint(to, amount);
    }

    /**
     * @dev Set `referrer` for caller's account.
     */
    function setReferrer(address referrer) external {
        _setReferrer(_msgSender(), referrer);
    }

    /**
     * @dev Set `referrer` for `referee`.
     *
     * Can be used only in origin chain (eg BSC) by crowd sale account.
     */
    function setReferrer(address referee, address referrer) external onlyRole(CROWDSALE_ROLE) onlyOriginChain {
        _setReferrer(referee, referrer);
    }

    /**
     * @dev Withdraws `amount` of given `erc20` tokens from the contracts's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function withdraw(address erc20, address to, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        IERC20Upgradeable erc20Impl = IERC20Upgradeable(erc20);
        erc20Impl.safeTransfer(to, amount);
        return true;
    }

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`. 
     *
     * Commission will be deducted from given sum if caller is not owner, bridge, router or registered crowdsale:
     * - 0.1% moves to the referrer or DAO pool (if set)
     * - 0.1% will be burned
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits few {Transfer} event.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address sender = _msgSender();
        _transfer(sender, to, amount);
        return true;
    }

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance. Please see transfer comments.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        _spendAllowance(from, _msgSender(), amount);
        _transfer(from, to, amount);
        return true;
    }

    function _setReferrer(address referee, address referrer) internal virtual {
        require(referrer != referee, "RAX: referrer can't be referred himself");
        require(referee != address(0), "RAX: zero address given");
        require(referrer != address(0), "RAX: zero address given");
        require(referrers[referee] == address(0), "RAX: referrer already set");
        referrers[referee] = referrer;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual override {
        (uint256 amountOut, uint256 referrerOut, uint256 DAOPoolOut, uint256 burnOut) = _calcFees(from, to, amount);
        super._transfer(from, to, amountOut);
        if (referrerOut > 0)
            super._transfer(from, referrers[from], referrerOut);
        if (DAOPoolOut > 0)
            super._transfer(from, DAOPool, DAOPoolOut);
        if (burnOut > 0)
            _burn(from, burnOut);
    }

    function _calcFees(address from, address to, uint256 amount) internal view returns (uint256 amountOut, uint256 referrerOut, uint256 DAOPoolOut, uint256 burnOut) {
        if (hasRole(DEFAULT_ADMIN_ROLE, from) || hasRole(BRIDGE_ROLE, from) || hasRole(CROWDSALE_ROLE, from) || from == address(this)) {
            return (amount, 0, 0, 0);
        }

        amountOut = amount;
        referrerOut = 0;
        DAOPoolOut = 0;
        burnOut = 0;

        // calc fee only if sender / receiver is not pancake router
        if (from != router && to != router) {
            if (referrers[from] != address(0)) {
                referrerOut = (amountOut * 10) / 10000; // 0.1%
            } else if (DAOPool != address(0)) {
                DAOPoolOut = (amountOut * 10) / 10000; // 0.1%
            }

            burnOut = (amountOut * 10) / 10000; // 0.1%

            amountOut -= referrerOut + DAOPoolOut + burnOut;
        }

        require(amountOut > 0, "RAX: Invalid amount");

        return (amountOut, referrerOut, DAOPoolOut, burnOut);
    }

    function _mint(address account, uint256 amount) internal virtual override(ERC20Upgradeable, ERC20CappedUpgradeable) {
        ERC20CappedUpgradeable._mint(account, amount);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}