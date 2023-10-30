// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/IRestakedETH.sol";
import "./helpers/Utils.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract RestakedETH is IRestakedETH, Initializable, PausableUpgradeable, AccessControlUpgradeable, UUPSUpgradeable {

    using SafeMath for uint256;

    event RebasePerformed(uint256 indexed epoch, uint256 totalSupply);

    modifier validRecipient(address to) {
        require(to != address(0x0), "Recipient cannot be zero address");
        require(to != address(this), "Recipient cannot be self");
        _;
    }

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant REBASER_ROLE = keccak256("REBASER_ROLE");

    uint256 private constant MAX_UINT256 = type(uint256).max;

    /* LEGACY STORAGE */
    uint256 private constant MAX_SUPPLY = type(uint128).max; // (2^128) - 1
    /* END LEGACY STORAGE */

    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    uint256 private _totalGons;
    uint256 private _gonsPerFragment;
    mapping(address => uint256) private _gonBalances;

    // This is denominated in Fragments, because the gons-fragments conversion might change before
    // it's fully paid.
    mapping(address => mapping(address => uint256)) private _allowedFragments;

    // EIP-2612: permit – 712-signed approvals
    // https://eips.ethereum.org/EIPS/eip-2612
    string public constant EIP712_REVISION = "1";
    bytes32 public constant EIP712_DOMAIN =
    keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );
    bytes32 public constant PERMIT_TYPEHASH =
    keccak256(
        "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    );

    // EIP-2612: keeps track of number of permits per address
    mapping(address => uint256) private _nonces;

    // address of staked ETH
    address public stakedTokenAddress;

    mapping(uint256 => bool) public rebaseByDate;

    uint256 private constant MAXIMUM_SUPPLY = 10**27;
    uint256 private constant INITIAL_GONS_PER_FRAGMENT = 10**50;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _governanceAddress, address _stakedTokenAddress, string memory _stakedTokenSymbol) initializer public {
        require(_governanceAddress != address(0), "AstridProtocol: Governance cannot be zero address");
        require(Utils.contractExists(_stakedTokenAddress), "AstridProtocol: Contract does not exist");

        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _name = string.concat("Astrid Restaked ", _stakedTokenSymbol);
        _symbol = string.concat("r", _stakedTokenSymbol);

        _grantRole(DEFAULT_ADMIN_ROLE, _governanceAddress);
        _grantRole(PAUSER_ROLE, _governanceAddress);
        _grantRole(UPGRADER_ROLE, _governanceAddress);

        stakedTokenAddress = _stakedTokenAddress;

        _totalSupply = 0;
        _totalGons = 0;
        _gonsPerFragment = INITIAL_GONS_PER_FRAGMENT;
    }

    function mint(address to, uint256 amount) external override onlyRole(MINTER_ROLE) whenNotPaused validRecipient(to) {
        require(amount > 0, "Amount must be greater than 0");
        require(_totalSupply + amount <= MAXIMUM_SUPPLY, "Maximum supply exceeded");

        uint256 gonValue = amount.mul(_gonsPerFragment);

        _totalSupply = _totalSupply.add(amount);
        _totalGons = _totalGons.add(gonValue);

        _gonBalances[to] = _gonBalances[to].add(gonValue);
        emit Transfer(address(0), to, amount);
    }

    function burn(address from, uint256 amount) external override onlyRole(MINTER_ROLE) whenNotPaused validRecipient(from) {
        require(amount > 0, "Amount must be greater than 0");

        uint256 gonValue = amount.mul(_gonsPerFragment);
        require(_gonBalances[from] >= gonValue, "Insufficient balance");

        _gonBalances[from] = _gonBalances[from].sub(gonValue);
        emit Transfer(from, address(0), amount);

        _totalSupply = _totalSupply.sub(amount);
        _totalGons = _totalGons.sub(gonValue);
    }

    /**
     * @dev Pauses the contract: transfers & rebase operations are no longer possible.
     */
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev UnPauses the contract: transfers & rebase operations are now possible.
     */
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev Method used for upgrading the proxy implementation contract.
     */
    function _authorizeUpgrade(address newImplementation) internal onlyRole(UPGRADER_ROLE) override {
    }

    /**
     * @dev Notifies reETH contract about a new rebase cycle.
     * @return The total number of fragments after the supply adjustment.
     */
    function rebase(uint256 epoch, bool isRebasePositive, uint256 supplyDelta) external whenNotPaused onlyRole(REBASER_ROLE) returns (uint256) {
        if (epoch < 1692403200) {
            return _totalSupply;
        }

        if (rebaseByDate[epoch]) {
            return _totalSupply;
        }

        rebaseByDate[epoch] = true;

        if (supplyDelta == 0) {
            emit RebasePerformed(epoch, _totalSupply);
            return _totalSupply;
        }

        if (isRebasePositive) {
            _totalSupply = _totalSupply.add(supplyDelta);
        } else {
            _totalSupply = _totalSupply.sub(supplyDelta);
        }

        if (_totalSupply > MAXIMUM_SUPPLY) {
            _totalSupply = MAXIMUM_SUPPLY;
        }

        if (_totalGons == 0) {
            _gonsPerFragment = INITIAL_GONS_PER_FRAGMENT;
        } else {
            _gonsPerFragment = _totalGons.div(_totalSupply);
        }

        // From this point forward, _gonsPerFragment is taken as the source of truth.
        // We recalculate a new _totalSupply to be in agreement with the _gonsPerFragment
        // conversion rate.
        // This means our applied supplyDelta can deviate from the requested supplyDelta,
        // but this deviation is guaranteed to be < (_totalSupply^2)/(TOTAL_GONS - _totalSupply).
        //
        // In the case of _totalSupply <= MAX_UINT128 (our current supply cap), this
        // deviation is guaranteed to be < 1, so we can omit this step. If the supply cap is
        // ever increased, it must be re-included.
        // _totalSupply = TOTAL_GONS.div(_gonsPerFragment)

        emit RebasePerformed(epoch, _totalSupply);

        return _totalSupply;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @return The total number of fragments.
     */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /**
    * @param who The address to query.
     * @return The balance of the specified address.
     */
    function balanceOf(address who) external view override returns (uint256) {
        if (_gonsPerFragment == 0) {
            return 0;
        }
        return _gonBalances[who].div(_gonsPerFragment);
    }

    /**
     * @return the total number of gons.
     */
    function scaledTotalSupply() external view returns (uint256) {
        return _totalGons;
    }

    /**
     * @param who The address to query.
     * @return The gon balance of the specified address.
     */
    function scaledBalanceOf(address who) external view returns (uint256) {
        return _gonBalances[who];
    }

    function scaledBalanceToBalance(uint256 scaledBalance) external view returns (uint256) {
        if (_gonsPerFragment == 0) {
            return 0;
        }
        return scaledBalance.div(_gonsPerFragment);
    }

    /**
     * @return The number of successful permits by the specified address.
     */
    function nonces(address who) public view returns (uint256) {
        return _nonces[who];
    }

    /**
     * @return The computed DOMAIN_SEPARATOR to be used off-chain services
     *         which implement EIP-712.
     *         https://eips.ethereum.org/EIPS/eip-2612
     */
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return
            keccak256(
            abi.encode(
                EIP712_DOMAIN,
                keccak256(bytes(name())),
                keccak256(bytes(EIP712_REVISION)),
                chainId,
                address(this)
            )
        );
    }

    /**
     * @dev Transfer tokens to a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     * @return True on success, false otherwise.
     */
    function transfer(address to, uint256 value) external override whenNotPaused validRecipient(to) returns (bool) {
        uint256 gonValue = value.mul(_gonsPerFragment);
        require(_gonBalances[msg.sender] >= gonValue, "Insufficient balance");

        _gonBalances[msg.sender] = _gonBalances[msg.sender].sub(gonValue);
        _gonBalances[to] = _gonBalances[to].add(gonValue);

        emit Transfer(msg.sender, to, value);

        return true;
    }

    /**
     * @dev Transfer all of the sender's wallet balance to a specified address.
     * @param to The address to transfer to.
     * @return True on success, false otherwise.
     */
    function transferAll(address to) external whenNotPaused validRecipient(to) returns (bool) {
        uint256 gonValue = _gonBalances[msg.sender];
        uint256 value = gonValue.div(_gonsPerFragment);

        delete _gonBalances[msg.sender];
        _gonBalances[to] = _gonBalances[to].add(gonValue);

        emit Transfer(msg.sender, to, value);

        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner has allowed to a spender.
     * @param owner_ The address which owns the funds.
     * @param spender The address which will spend the funds.
     * @return The number of tokens still available for the spender.
     */
    function allowance(address owner_, address spender) external view override returns (uint256) {
        return _allowedFragments[owner_][spender];
    }

    /**
     * @dev Transfer tokens from one address to another.
     * @param from The address you want to send tokens from.
     * @param to The address you want to transfer to.
     * @param value The amount of tokens to be transferred.
     */
    function transferFrom(address from, address to, uint256 value) external override whenNotPaused validRecipient(to) returns (bool) {
        require(value <= _allowedFragments[from][msg.sender], "Insufficient allowance");
        _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender].sub(value);

        uint256 gonValue = value.mul(_gonsPerFragment);
        require(_gonBalances[from] >= gonValue, "Insufficient balance");

        _gonBalances[from] = _gonBalances[from].sub(gonValue);
        _gonBalances[to] = _gonBalances[to].add(gonValue);

        emit Transfer(from, to, value);

        return true;
    }

    /**
     * @dev Transfer all balance tokens from one address to another.
     * @param from The address you want to send tokens from.
     * @param to The address you want to transfer to.
     */
    function transferAllFrom(address from, address to) external whenNotPaused validRecipient(to) returns (bool) {
        uint256 gonValue = _gonBalances[from];
        uint256 value = gonValue.div(_gonsPerFragment);

        require(value <= _allowedFragments[from][msg.sender], "Insufficient allowance");
        _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender].sub(value);

        delete _gonBalances[from];
        _gonBalances[to] = _gonBalances[to].add(gonValue);

        emit Transfer(from, to, value);

        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of
     * msg.sender. This method is included for ERC20 compatibility.
     * increaseAllowance and decreaseAllowance should be used instead.
     * Changing an allowance with this method brings the risk that someone may transfer both
     * the old and the new allowance - if they are both greater than zero - if a transfer
     * transaction is mined before the later approve() call is mined.
     *
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) external override returns (bool) {
        _allowedFragments[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner has allowed to a spender.
     * This method should be used instead of approve() to avoid the double approval vulnerability
     * described above.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _allowedFragments[msg.sender][spender] = _allowedFragments[msg.sender][spender].add(
            addedValue
        );

        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);

        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner has allowed to a spender.
     *
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        _allowedFragments[msg.sender][spender] = (subtractedValue >= oldValue)
            ? 0
            : oldValue.sub(subtractedValue);

        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);

        return true;
    }

    /**
     * @dev Allows for approvals to be made via secp256k1 signatures.
     * @param owner The owner of the funds
     * @param spender The spender
     * @param value The amount
     * @param deadline The deadline timestamp, type(uint256).max for max deadline
     * @param v Signature param
     * @param s Signature param
     * @param r Signature param
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
        require(block.timestamp <= deadline, "Exceeded deadline");

        uint256 ownerNonce = _nonces[owner];
        bytes32 permitDataDigest = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, ownerNonce, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), permitDataDigest));

        require(owner == ecrecover(digest, v, r, s), "Invalid signature");

        _nonces[owner] = ownerNonce.add(1);

        _allowedFragments[owner][spender] = value;

        emit Approval(owner, spender, value);
    }

}