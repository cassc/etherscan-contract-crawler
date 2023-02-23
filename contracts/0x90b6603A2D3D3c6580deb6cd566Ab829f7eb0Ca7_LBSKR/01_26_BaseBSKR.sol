/*
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.18;

import "../lib/Utils.sol";
import "../openzeppelin/access/OwnableUpgradeable.sol";
import "../openzeppelin/proxy/utils/UUPSUpgradeable.sol";
import "../openzeppelin/security/PausableUpgradeable.sol";
import "../openzeppelin/token/ERC20/IERC20Upgradeable.sol";
import "../uniswap/v2-core/interfaces/IUniswapV2Factory.sol";
import "../uniswap/v2-core/interfaces/IUniswapV2Pair.sol";
import "../uniswap/v2-periphery/interfaces/IUniswapV2Router02.sol";
import "../uniswap/v3-core/interfaces/IUniswapV3Factory.sol";
import "../uniswap/v3-core/interfaces/IUniswapV3Pool.sol";
import "./Manageable.sol";

abstract contract BaseBSKR is
    Utils,
    OwnableUpgradeable,
    UUPSUpgradeable,
    PausableUpgradeable,
    IERC20Upgradeable,
    Manageable
{
    struct Airdrop {
        address user;
        uint256 amount;
    }

    IUniswapV2Factory internal _dexFactoryV2;
    IUniswapV2Router02 internal _dexRouterV2;
    address internal _growth1Address;
    address internal _growth2Address;
    address internal _nftStakingContract;
    address internal wethAddr;
    address[5] internal _sisterOAs;
    bool internal isV3Enabled;
    mapping(address => bool) internal _isAMMPair;
    mapping(address => bool) internal _paysNoFee;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) internal _balances;
    string private _name;
    string private _symbol;
    uint256 internal _oaIndex; // 5 bits
    uint256 internal _totalSupply; // 1 billion for Goerli and 1 trillion (0xC9F2C9CD04674EDEA40000000) for PulseChain - 40 bits
    uint256 internal constant _BIPS = 10000; // bips or basis point divisor - 14 bits
    uint256 private constant _DECIMALS = 18; // 5 bits

    function __BaseBSKR_init(
        string calldata nameA,
        string calldata symbolA,
        address growth1AddressA,
        address growth2AddressA,
        address[5] memory sisterOAsA
    ) internal onlyInitializing {
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __Manageable_init_unchained();
        __BaseBSKR_init_unchained(
            nameA,
            symbolA,
            growth1AddressA,
            growth2AddressA,
            sisterOAsA
        );
    }

    function __BaseBSKR_init_unchained(
        string calldata nameA,
        string calldata symbolA,
        address growth1AddressA,
        address growth2AddressA,
        address[5] memory sisterOAsA
    ) internal onlyInitializing {
        _name = nameA;
        _symbol = symbolA;
        _growth1Address = growth1AddressA;
        _growth2Address = growth2AddressA;
        _sisterOAs = sisterOAsA;

        _totalSupply = 0x33B2E3C9FD0803CE8000000;

        _dexRouterV2 = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        _dexFactoryV2 = IUniswapV2Factory(_dexRouterV2.factory());

        _totalSupply = 0x33B2E3C9FD0803CE8000000; // 1 billion
        wethAddr = _dexRouterV2.WETH();

        _paysNoFee[_msgSender()] = true;
        _paysNoFee[address(this)] = true;
        _paysNoFee[address(_dexRouterV2)] = true; // may not be needed
    }

    //to recieve ETH from _dexRouterV2 when swaping
    receive() external payable {}

    fallback() external payable {}

    function __v3PairInvolved(address target) internal view returns (bool) {
        if (target == address(_dexRouterV2)) return false; // to avoid orange reverts
        if (target == address(_nftStakingContract)) return false; // to avoid orange reverts
        if (target == wethAddr) return false; // to avoid orange reverts
        if (_isAMMPair[target]) {
            return false; // if V3 is disabled, only V2 pairs are registered
        }

        address token0 = _getToken0(target);
        if (token0 == address(0)) {
            return false;
        }

        address token1 = _getToken1(target);
        if (token1 == address(0)) {
            return false;
        }

        uint24 fee = _getFee(target);
        if (fee != 0) {
            return true;
        }

        return false;
    }

    function _airdropTokens(address to, uint256 amount) internal virtual;

    /**
     * @notice Sets `amount` as the allowance of `spender` over the `owner` s tokens.
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
    ) internal {
        require(owner != address(0), "BB: From 0 addr");
        require(spender != address(0), "BB: To 0 addr");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function _checkIfAMMPair(address target) internal {
        if (target.code.length == 0) return;
        if (target == address(_dexRouterV2)) return; // to avoid orange reverts
        if (target == address(_nftStakingContract)) return; // to avoid orange reverts
        if (target == wethAddr) return; // to avoid orange reverts
        if (!_isAMMPair[target]) {
            address token0 = _getToken0(target);
            if (token0 == address(0)) {
                return;
            }

            address token1 = _getToken1(target);
            if (token1 == address(0)) {
                return;
            }

            _approve(target, target, type(uint256).max);
            _isAMMPair[target] = true;
        }
    }

    function _getOriginAddress() internal returns (address) {
        if (_oaIndex < (_sisterOAs.length - 1)) {
            _oaIndex = _oaIndex + 1;
        } else {
            _oaIndex = 0;
        }
        return _sisterOAs[_oaIndex];
    }

    function _transfer(
        address owner,
        address to,
        uint256 amount
    ) internal virtual;

    /**
     * Airdrop BSKR to sacrificers, deducted from owner's wallet
     */
    function airdrop(Airdrop[] calldata receivers) external onlyOwner {
        for (uint256 index; index < receivers.length; ++index) {
            if (
                receivers[index].user != address(0) &&
                receivers[index].amount != 0
            ) {
                _airdropTokens(receivers[index].user, receivers[index].amount);
            }
        }
    }

    /**
     * @notice Get allowance for a spender to spend owner's tokens
     * @param owner owner address
     * @param spender spender address
     * @return uint256 allowance value
     */
    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @notice Sets allowance for spender to use msgsender's tokens
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @notice Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     */
    function decimals() external pure returns (uint256) {
        return _DECIMALS;
    }

    /**
     * @notice Atomically decreases the allowance granted to `spender` by the caller.
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "BSKR: Decreases below 0");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @notice Disables UniswapV3
     */
    function disableUniswapV3() external onlyManager {
        isV3Enabled = false;
    }

    /**
     * @notice Enables UniswapV3
     */
    function enableUniswapV3() external onlyManager {
        isV3Enabled = true;
    }

    /**
     * @notice Atomically increases the allowance granted to `spender` by the caller.
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
    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @notice Returns the name of the token.
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @notice Pauses this contract features
     */
    function pauseContract() external onlyManager {
        _pause();
    }

    /*
     * @notice Sets the BSKR contract address
     */
    function setNFTStakingContract(address newNFTStkCntrct) external onlyOwner {
        _nftStakingContract = newNFTStkCntrct;
    }

    /**
     * @notice Returns the symbol of the token
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @notice Returns the amount of tokens in existence.
     */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @notice See {IERC20-transfer}.    TODO add description
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount)
        external
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @notice Transfers tokens 'from' to 'to' address provided there is enough allowance
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
    ) external override returns (bool) {
        address spender = _msgSender();
        uint256 currentAllowance = allowance(from, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "BB: Insufficient allowance");
            unchecked {
                _approve(from, spender, currentAllowance - amount);
            }
        }
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @notice Unpauses the contract's features
     */
    function unPauseContract() external onlyManager {
        _unpause();
    }

    // to rename with _ prefix
    function v3PairInvolved(address from, address to)
        internal
        view
        returns (bool)
    {
        return (__v3PairInvolved(from) || __v3PairInvolved(to));
    }

    /**
     * @notice This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}