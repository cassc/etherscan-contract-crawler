// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Enchantable.sol";

/**
 * @title RSR

 * An ERC20 insurance token for the Reserve Protocol ecosystem, using the copy-on-write
 * pattern to enable a ugprade from the old RSR token.

 * This token allows the configuration of a rich system of "siphons" to administer the
 * copy pattern of some holder addresses, before the token goes into its WORKING phase.
 */
contract RSR is Pausable, Ownable, Enchantable, ERC20Permit {
    using EnumerableSet for EnumerableSet.AddressSet;

    ERC20Pausable public immutable oldRSR;

    /// weight scale
    /// A uint64 value `w` is a _weight_, and it represents the fractional value `w / WEIGHT_ONE`.
    uint64 public constant WEIGHT_ONE = 1e18;

    /// fixedSupply inherited from oldRSR contract
    /// Note that due to lost dust crossing, it's possible sum(_balances) < fixedSupply
    uint256 private immutable fixedSupply;

    /** Operational Lifecycle
    The contract is initially deployed into SETUP. During the SETUP phase:
    - admins can configure siphons
    - no ERC20 operations can happen
    - the contract is always paused

    The contract can transition from SETUP to WORKING only after oldRSR is paused.
    During that transition, the owner is set to the zero address.

    In the WORKING phase:
    - siphons cannot be changed
    - ERC20 operations happen as usual
    - the pauser can pause and unpause the contract

    Once in WORKING, the contract cannot move back to SETUP.
    */
    enum Phase {
        SETUP,
        WORKING
    }
    Phase public phase;

    /// Pausing
    /// Note well that, because of the above about lifecycle phase, whenNotPaused implies isWorking.
    event PauserChanged(address indexed oldPauser, address newPauser);
    address public pauser;

    /** @dev
    Relative Immutability
    =====================

    We assume that, once OldRSR is paused, its paused status, balances, and allowances
    are immutable, and this contract's values for hasWeights, weights, and origins
    are immutable as well.

    Before OldRSR is paused, the booleans in balCrossed and allownceCrossed are all
    false (immutable). After OldRSR is paused, the entries in those maps can change to true.
    Once the entry value is true, it remains immutable.
    */

    /// weights: map(OldRSR addr -> RSR addr -> uint64 weight)
    /// weights[A][B] is the fraction of A's old balance that should be forwarded to B.
    mapping(address => mapping(address => uint64)) public weights;

    /// Invariant:
    /// For all OldRSR addresses A,
    /// if !hasWeights[A], then for all RSR Addresses B, weights[A][B] == 0
    /// if hasWeights[A], then sum_{all RSR addresses B} (weights[A][B]) == WEIGHT_ONE
    ///
    /// hasWeights: map(OldRSR addr -> bool)
    /// If !hasWeights[A], then A's OldRSR balances should be forwarded as by default.
    /// If hasWeights[A], then A's OldRSR balances should be forwarded as by weights[A][_]
    mapping(address => bool) public hasWeights;

    /// Invariant: For all A and B, if weights[A][B] > 0, then A is in origins[B]
    ///
    /// origins: map(RSR addr -> set(OldRSR addr))
    mapping(address => EnumerableSet.AddressSet) private origins;

    /// balCrossed[A]: true if and only if OldRSR address "A" has already crossed
    mapping(address => bool) public balCrossed;

    /// allowanceCrossed[A][B]: true if and only if oldRSR.allowances[A][B] has crossed
    mapping(address => mapping(address => bool)) public allowanceCrossed;

    /** @dev A few mathematical functions, so we can be really precise here:

    totalWeight(A, B) = (hasWeights[A] ? weights[A][B] : ((A == B) ? WEIGHT_ONE : 0))
    inheritedBalance(A) = sum_{all addrs B} ( oldRSR.balanceOf(A) * totalWeight(A,B) / WEIGHT_ONE )

    # Properties of balances:

    For all RSR addresses "A":
    - If OldRSR is not yet paused, balCrossed[A] is `false`.
    - Once balCrossed[A] is `true`, it stays `true` forever.
    - balanceOf(A) == this._balances[A] + (balCrossed[A] ? inheritedBalance(A) : 0)
    - The function `balanceOf` satisfies all the usual rules for ERC20 tokens.

    # Properties of allowances:

    For all addresses A and B,
    - If OldRSR is not yet paused, then allowanceCrossed[A][B] is false
    - Once allowanceCrossed[A][B] == true, it stays true forever
    - allowance(A,B) == allowanceCrossed[A][B] ? this._allowance[A][B] : oldRSR.allowance(A,B)
    - The function `allowance` satisfies all the usual rules for ERC20 tokens.
    */

    constructor(address oldRSR_) ERC20("Reserve Rights", "RSR") ERC20Permit("Reserve Rights") {
        oldRSR = ERC20Pausable(oldRSR_);
        // `totalSupply` for both OldRSR and RSR is fixed and equal
        fixedSupply = ERC20Pausable(oldRSR_).totalSupply();
        pauser = _msgSender();
        _pause();
        phase = Phase.SETUP;
    }

    // ========================= Modifiers =========================

    modifier ensureBalCrossed(address from) {
        if (!balCrossed[from]) {
            balCrossed[from] = true;
            _mint(from, _oldBal(from));
        }
        _;
    }

    modifier ensureAllowanceCrossed(address from, address to) {
        if (!allowanceCrossed[from][to]) {
            allowanceCrossed[from][to] = true;
            _approve(from, to, oldRSR.allowance(from, to));
        }
        _;
    }

    modifier onlyAdminOrPauser() {
        require(
            _msgSender() == pauser || _msgSender() == mage() || _msgSender() == owner(),
            "only pauser, mage, or owner"
        );
        _;
    }

    modifier inWorking() {
        require(phase == Phase.WORKING, "only during working phase");
        _;
    }
    modifier inSetup() {
        require(phase == Phase.SETUP, "only during setup phase");
        _;
    }

    // ========================= Governance =========================

    function moveToWorking() external onlyAdmin inSetup {
        require(oldRSR.paused(), "waiting for oldRSR to pause");
        phase = Phase.WORKING;
        _unpause();
        _transferOwnership(address(0));
    }

    /// Pause ERC20 + ERC2612 functions
    function pause() external onlyAdminOrPauser inWorking {
        _pause();
    }

    /// Unpause ERC20 + ERC2612 functions
    function unpause() external onlyAdminOrPauser inWorking {
        _unpause();
    }

    function changePauser(address newPauser) external onlyAdminOrPauser {
        require(newPauser != address(0), "use renouncePauser");
        emit PauserChanged(pauser, newPauser);
        pauser = newPauser;
    }

    function renouncePauser() external onlyAdminOrPauser {
        emit PauserChanged(pauser, address(0));
        pauser = address(0);
    }

    // ========================= Weight Management =========================

    /// Moves weight from old->prev to old->to
    /// @param from The address that has the balance on OldRSR
    /// @param oldTo The receiving address to siphon tokens away from
    /// @param newTo The receiving address to siphon tokens towards
    /// @param weight A uint between 0 and the current old->prev weight, max WEIGHT_ONE
    function siphon(
        address from,
        address oldTo,
        address newTo,
        uint64 weight
    ) external onlyAdmin inSetup {
        _siphon(from, oldTo, newTo, weight);
    }

    /// Partially crosses an account balance.
    /// Calling this function does not impact final balances after completing account crossing.
    function partiallyCross(address to, uint256 n) public inWorking {
        if (!balCrossed[to]) {
            while (origins[to].length() > 0 && n > 0) {
                address from = origins[to].at(origins[to].length() - 1);
                _mint(to, (oldRSR.balanceOf(from) * weights[from][to]) / WEIGHT_ONE);
                weights[from][to] = 0;
                origins[to].remove(from);
                n -= 1;
            }
        }
    }

    // ========================= ERC20 + ERC2612 ==============================

    function transfer(address recipient, uint256 amount)
        public
        override
        whenNotPaused
        ensureBalCrossed(_msgSender())
        returns (bool)
    {
        require(recipient != address(this), "no transfers to this token address");
        return super.transfer(recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
        public
        override
        whenNotPaused
        ensureBalCrossed(sender)
        ensureAllowanceCrossed(sender, _msgSender())
        returns (bool)
    {
        require(recipient != address(this), "no transfers to this token address");
        return super.transferFrom(sender, recipient, amount);
    }

    function approve(address spender, uint256 amount) public override whenNotPaused returns (bool) {
        _approve(_msgSender(), spender, amount);
        allowanceCrossed[_msgSender()][spender] = true;
        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override whenNotPaused {
        super.permit(owner, spender, value, deadline, v, r, s);
        allowanceCrossed[owner][spender] = true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        override
        whenNotPaused
        ensureAllowanceCrossed(_msgSender(), spender)
        returns (bool)
    {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subbedValue)
        public
        override
        whenNotPaused
        ensureAllowanceCrossed(_msgSender(), spender)
        returns (bool)
    {
        return super.decreaseAllowance(spender, subbedValue);
    }

    /// @return The fixed total supply of the token
    function totalSupply() public view override returns (uint256) {
        return fixedSupply;
    }

    /// @return The RSR balance of account
    /// @dev The balance we return from balanceOf is the sum of three sources of balances:
    ///     - newly received tokens
    ///     - already-crossed oldRSR balances
    ///     - not-yet-crossed oldRSR balances
    /// super.balanceOf(account) == (newly received tokens + already-crossed oldRSR balances)
    /// if not balCrossed[account], then _oldBal(account) == not-yet-crossed oldRSR balances
    function balanceOf(address account) public view override returns (uint256) {
        if (balCrossed[account]) {
            return super.balanceOf(account);
        }
        return _oldBal(account) + super.balanceOf(account);
    }

    /// The allowance is a combination of crossing allowance + newly granted allowances
    function allowance(address owner, address spender) public view override returns (uint256) {
        if (allowanceCrossed[owner][spender]) {
            return super.allowance(owner, spender);
        }
        return oldRSR.allowance(owner, spender);
    }

    // ========================= Internal =============================

    /// Moves weight from old->prev to old->to
    /// @param from The address that has the balance on OldRSR
    /// @param oldTo The receiving address to siphon tokens away from
    /// @param newTo The receiving address newTo siphon tokens towards
    /// @param weight A uint between 0 and the current from->oldTo weight, max WEIGHT_ONE (1e18)
    function _siphon(
        address from,
        address oldTo,
        address newTo,
        uint64 weight
    ) internal {
        /// Ensure that hasWeights[from] is true (base case)
        if (!hasWeights[from]) {
            origins[from].add(from);
            weights[from][from] = WEIGHT_ONE;
            hasWeights[from] = true;
        }

        require(weight <= weights[from][oldTo], "weight too big");
        require(from != address(0), "from cannot be zero address");
        // Redistribute weights
        weights[from][oldTo] -= weight;
        weights[from][newTo] += weight;
        origins[newTo].add(from);
    }

    /// @return sum The starting balance for an account after crossing from OldRSR
    function _oldBal(address account) internal view returns (uint256 sum) {
        if (!hasWeights[account]) {
            sum = oldRSR.balanceOf(account);
        }
        for (uint256 i = 0; i < origins[account].length(); i++) {
            // Note that there is an acceptable loss of precision equal to ~1e18 RSR quanta
            address from = origins[account].at(i);
            sum += (oldRSR.balanceOf(from) * weights[from][account]) / WEIGHT_ONE;
        }
    }
}