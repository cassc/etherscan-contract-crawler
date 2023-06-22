pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

import "@openzeppelin/contracts/access/Ownable.sol";

import "./RebasingERC20.sol";
import "./Rational.sol";

/**
 * @title Captures our exposure to a particular asset
 *
 * @dev Any given exposure is split among many holders, as the exposure changes
 * holders get rebased accordingly.
 */
contract Exposure is Ownable, RebasingERC20 {
    /// @dev The token which this particular strategy is
    /// accounted for in unused other than for information purposes
    IERC20 public revalToken;

    /// @dev total value of all share holders in this strategy
    uint256 public reval;

    /// @dev which actors can increase their stake in a given position
    /// in the temple core, only vaults should hold shares in a position
    mapping(address => bool) public canMint;

    /// @dev if set, automatically liquidates position and transfers temple
    /// minted as a result to the appropriate vault
    ILiquidator public liquidator;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory _name, string memory _symbol, IERC20 _revalToken) ERC20(_name, _symbol) {
        revalToken = _revalToken;
    }

    /**
     * @dev increase reval associated with a strategy
     */
    function increaseReval(uint256 amount) external onlyOwner {
        uint256 oldVal = reval;
        reval += amount;

        emit IncreaseReval(oldVal, reval);
    }

    /**
     * @dev decrease reval associated with a strategy
     */
    function decreaseReval(uint256 amount) external onlyOwner {
        uint256 oldVal = reval;
        reval -= amount;

        emit DecreaseReval(oldVal, reval);
    }

    /**
     * @dev set actor which automatically liquidates any claimed position into temple
     */
    function setLiqidator(ILiquidator _liquidator) external onlyOwner {
        liquidator = _liquidator;

        emit SetLiquidator(address(liquidator));
    }

    /**
     * @dev set/unset an accounts ability to mint exposure tokens
     */
    function setMinterState(address account, bool state) external onlyOwner {
        canMint[account] = state;
        emit SetMinterState(account, state);
    }

    /**
     * @notice Generate new strategy shares
     *
     * @dev Only callable by minters. Increases a minters share of
     * a strategy
     */
    function mint(address account, uint256 amount) external onlyMinter {
        _mint(account, amount);
        reval += amount;

        // no need for event, handled via _mint
    }

    /**
     * @dev redeem the callers share of this exposure back to temple
     */
    function redeem() external {
        redeemAmount(balanceOf(msg.sender), msg.sender);
    }

    /**
     * @dev redeem the callers share of this exposure back to temple
     */
    function redeemAmount(uint256 amount, address to) public {
        _burn(msg.sender, amount);
        reval -= amount;

        if (address(liquidator) != address(0)) {
            liquidator.toTemple(amount, to);
        }

        emit Redeem(address(revalToken), msg.sender, to, amount);
    }

    function amountPerShare() public view override returns (uint256 p, uint256 q) {
        p = reval;
        q = totalShares;

        // NOTE(butlerji): Assuming this is fairly cheap in gas, as it gets called
        // often
        if (p == 0) {
            p = 1;
        }

        if (q == 0) {
            q = p;
        }
    }

    /**
     * Throws if called by an actor that cannot mint
     */
    modifier onlyMinter() {
        require(canMint[msg.sender], "Exposure: caller is not a vault");
        _;
    }

    event IncreaseReval(uint256 oldVal, uint256 newVal);
    event DecreaseReval(uint256 oldVal, uint256 newVal);
    event SetLiquidator(address liquidator);
    event SetMinterState(address account, bool state);
    event Redeem(address revalToken, address caller, address to, uint256 amount);
}

interface ILiquidator {
    function toTemple(uint256 amount, address toAccount) external;
}