// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol"; 
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./BlacklistableUpgradeable.sol";

/**
 * @title IDDRV1
 * @dev Token backed by idr reserves
 */
contract IDDRV1 is Initializable, OwnableUpgradeable, PausableUpgradeable, BlacklistableUpgradeable, EIP712Upgradeable, UUPSUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 internal totalSupply_;

    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    mapping(address => bool) internal minters;
    mapping(address => uint256) internal minterAllowed;
    mapping(address => CountersUpgradeable.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    event Mint(address indexed minter, address indexed to, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Burn(address indexed burner, uint256 amount);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );
    event MinterConfigured(address indexed minter, uint256 minterAllowedAmount);
    event MinterRemoved(address indexed oldMinter);
    event MasterMinterChanged(address indexed newMasterMinter);

    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Function to initialise contract
     * @param _name string Token name
     * @param _symbol string Token symbol
     * @param _decimals uint8 Token decimals
     * @param _blacklister address Address of the blacklister
    */
    function initialize(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _blacklister
    ) initializer public  {
        require(_blacklister != address(0), "blacklister can't be 0x0");

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        blacklister = _blacklister;

        __Ownable_init();
        __Pausable_init();
        __EIP712_init(name, "1");
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
    
    /**
     * @dev Throws if called by any account other than a minter
     */
    modifier onlyMinters() {
        require(minters[msg.sender] == true, "minters only");
        _;
    }

    /**
     * @dev Triggers pause state.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Returns to normal state.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Function to mint tokens
     * Validates that the contract is not paused
     * only minters can call this function
     * minter and the address that will received the minted tokens are not blacklisted
     * @param _to address The address that will receive the minted tokens.
     * @param _amount uint256 The amount of tokens to mint. Must be less than or equal to the minterAllowance of the caller.
     * @return True if the operation was successful.
    */
    function mint(address _to, uint256 _amount)
        public
        whenNotPaused
        onlyMinters
        notBlacklisted(msg.sender)
        notBlacklisted(_to)
        returns (bool)
    {
        require(_to != address(0), "can't mint to 0x0");
        require(_amount > 0, "amount to mint has to be > 0");

        uint256 mintingAllowedAmount = minterAllowance(msg.sender);
        require(_amount <= mintingAllowedAmount, "minter allowance too low");

        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        minterAllowed[msg.sender] = mintingAllowedAmount.sub(_amount);
        if (minterAllowance(msg.sender) == 0) {
            minters[msg.sender] = false;
            emit MinterRemoved(msg.sender);
        }
        emit Mint(msg.sender, _to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    /**
     * @dev Function to get minter allowance of an address
     * @param _minter address The address of check minter allowance of
     * @return The minter allowance of the address
    */
    function minterAllowance(address _minter) public view returns (uint256) {
        return minterAllowed[_minter];
    }

    /**
     * @dev Function to check if an address is a minter
     * @param _address The address to check
     * @return A boolean value to indicates if an address is a minter
    */
    function isMinter(address _address) public view returns (bool) {
        return minters[_address];
    }

    /**
     * @dev Function to get total supply of token
     * @return The total supply of the token
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
     * @dev Function to get token balance of an address
     * @param _address address The account
     * @return The token balance of an address
    */
    function balanceOf(address _address) public view returns (uint256) {
        return balances[_address];
    }

    /**
     * @dev Function to approves a spender to spend up to a certain amount of tokens
     * Validates that the contract is not paused
     * the owner and spender are not blacklisted
     * Avoid calling this function if possible (https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729)
     * @param _spender address The Address of the spender
     * @param _amount uint256 The amount of tokens that the spender is approved to spend
     * @return True if the operation was successful.
    */
    function approve(address _spender, uint256 _amount)
        public
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(_spender)
        returns (bool)
    {
         _approve(msg.sender,_spender, _amount);
         return true;
    }

    /**
     * @dev Alternative function to the approve function
     * Increases the allowance of the spender
     * Validates that the contract is not paused
     * the owner and spender are not blacklisted
     * @param _spender address The Address of the spender
     * @param _addedValue uint256 The amount of tokens to be added to a spender's allowance
     * @return True if the operation was successful.
    */
    function increaseAllowance(address _spender, uint256 _addedValue)
        public
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(_spender)
        returns (bool)
    {
        uint256 updatedAllowance = allowed[msg.sender][_spender].add(
            _addedValue
        );
         _approve(msg.sender,_spender, updatedAllowance);
         return true;
    }

    /**
     * @dev Alternative function to the approve function
     * Decreases the allowance of the spender
     * Validates that the contract is not paused
     * the owner and spender are not blacklisted
     * @param _spender address The Address of the spender
     * @param _subtractedValue uint256 The amount of tokens to be subtracted from a spender's allowance
     * @return True if the operation was successful.
    */
    function decreaseAllowance(address _spender, uint256 _subtractedValue)
        public
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(_spender)
        returns (bool)
    {
        uint256 updatedAllowance = allowed[msg.sender][_spender].sub(
            _subtractedValue
        );
        _approve(msg.sender,_spender, updatedAllowance);
        return true;
    }

    /**
     * @dev Internal function to set allowance
     * @param _owner     Token owner's address
     * @param _spender   Spender's address
     * @param _amount     Allowance amount
     */
    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) internal  {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");
        allowed[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    /**
     * @dev Function to get token allowance given to a spender by the owner
     * @param _owner address The address of the owner
     * @param _spender address The address of the spender
     * @return The number of tokens that a spender can spend on behalf of the owner
    */
    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Function to transfer tokens from one address to another.
     * Validates that the contract is not paused
     * the caller, sender and receiver of the tokens are not blacklisted
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _amount uint256 the amount of tokens to be transferred
     * @return True if the operation was successful.
    */
    function transferFrom(address _from, address _to, uint256 _amount)
        public
        whenNotPaused
        notBlacklisted(_to)
        notBlacklisted(msg.sender)
        notBlacklisted(_from)
        returns (bool)
    {
        require(_to != address(0), "can't transfer to 0x0");
        require(_amount <= balances[_from], "insufficient balance");
        require(
            _amount <= allowed[_from][msg.sender],
            "token allowance is too low"
        );

        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }

    /**
     * @dev Function to transfer token to a specified address
     * Validates that the contract is not paused
     * The sender and receiver are not blacklisted
     * @param _to The address to transfer to.
     * @param _amount The amount of tokens to be transferred.
     * @return True if the operation is successful
    */
    function transfer(address _to, uint256 _amount)
        public
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(_to)
        returns (bool)
    {
        require(_to != address(0), "can't transfer to 0x0");
        require(_amount <= balances[msg.sender], "insufficient balance");

        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    /**
    * @dev Function to increase minter allowance of a minter
    * Validates that only the master minter can call this function
    * @param _minter address The address of the minter
    * @param _increasedAmount uint256 The amount of to be added to a minter's allowance
    */
    function increaseMinterAllowance(address _minter, uint256 _increasedAmount)
        public
        onlyOwner
    {
        require(_minter != address(0), "minter can't be 0x0");
        uint256 updatedAllowance = minterAllowance(_minter).add(
            _increasedAmount
        );
        minterAllowed[_minter] = updatedAllowance;
        minters[_minter] = true;
        emit MinterConfigured(_minter, updatedAllowance);
    }

    /**
    * @dev Function to decrease minter allowance of a minter
    * Validates that only the master minter can call this function
    * @param _minter address The address of the minter
    * @param _decreasedAmount uint256 The amount of allowance to be subtracted from a minter's allowance
    */
    function decreaseMinterAllowance(address _minter, uint256 _decreasedAmount)
        public
        onlyOwner
    {
        require(_minter != address(0), "minter can't be 0x0");
        require(minters[_minter], "not a minter");

        uint256 updatedAllowance = minterAllowance(_minter).sub(
            _decreasedAmount
        );
        minterAllowed[_minter] = updatedAllowance;
        if (minterAllowance(_minter) > 0) {
            emit MinterConfigured(_minter, updatedAllowance);
        } else {
            minters[_minter] = false;
            emit MinterRemoved(_minter);

        }
    }

    /**
     * @dev Function to allow a minter to burn some of its own tokens
     * Validates that the contract is not paused
     * caller is a minter and is not blacklisted
     * amount is less than or equal to the minter's mint allowance balance
     * @param _amount uint256 the amount of tokens to be burned
    */
    function burn(uint256 _amount)
        public
        whenNotPaused
        onlyMinters
        notBlacklisted(msg.sender)
    {
        uint256 balance = balances[msg.sender];
        require(_amount > 0, "burn amount has to be > 0");
        require(balance >= _amount, "balance in minter is < amount to burn");

        totalSupply_ = totalSupply_.sub(_amount);
        balances[msg.sender] = balance.sub(_amount);
        emit Burn(msg.sender, _amount);
        emit Transfer(msg.sender, address(0), _amount);
    }

    /**
     * @dev Function to allow the blacklister to burn entire balance of tokens from a blacklisted address
     * Validates that contract is not paused
     * caller is the blacklister
     * address to burn tokens from is a blacklisted address
     * @param _from address the address to burn tokens from
    */
    function lawEnforcementWipingBurn(address _from)
        public
        whenNotPaused
        onlyBlacklister
    {
        require(
            isBlacklisted(_from),
            "Can't wipe balances of a non blacklisted address"
        );
        uint256 balance = balances[_from];
        totalSupply_ = totalSupply_.sub(balance);
        balances[_from] = 0;
        emit Burn(_from, balance);
        emit Transfer(_from, address(0), balance);
    }

    
    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public 
        whenNotPaused
        notBlacklisted(_owner)
        notBlacklisted(_spender)  {
        require(block.timestamp <= _deadline, "FiatTokenPermit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, _owner, _spender, _value, _useNonce(_owner), _deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSAUpgradeable.recover(hash, _v, _r, _s);
        require(signer == _owner, "FiatTokenPermit: invalid signature");

        _approve(_owner, _spender, _value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address _owner) public view returns (uint256) {
        return _nonces[_owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     */
    function _useNonce(address _owner) internal returns (uint256 current) {
        CountersUpgradeable.Counter storage nonce = _nonces[_owner];
        current = nonce.current();
        nonce.increment();
    }


     /**
     * @notice Rescue ERC20 tokens locked up in this contract.
     * @param _tokenContract ERC20 token contract address
     * @param _to        Recipient address
     * @param _amount    Amount to withdraw
     */
    function rescueERC20(
        IERC20Upgradeable _tokenContract,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        _tokenContract.safeTransfer(_to, _amount);
    }

    /**
     * @return Version string
     */
    function version() external pure virtual returns (string memory) {
        return "1";
    }    
    
}