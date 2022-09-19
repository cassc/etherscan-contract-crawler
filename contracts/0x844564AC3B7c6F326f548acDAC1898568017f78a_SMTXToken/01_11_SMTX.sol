// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
pragma solidity ^0.8.0;

contract SMTXToken is
    Initializable,
    ContextUpgradeable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    using SafeMath for uint256;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    uint256 private _initialSupply;
    mapping(address => bool) public blacklisted;

    function initialize() public initializer {
        __ERC20_init("SUMOTEX", "SMTX");
        __Ownable_init();
        __Pausable_init();
        _totalSupply = 1000000000 * 10**uint256(decimals());
    }

    /**
     * @dev total number of tokens in existence
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function initialSupply() public view returns (uint256) {
        return _initialSupply;
    }

    /**
     * @dev transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint256 _value)
        public
        override
        whenNotPaused
        returns (bool)
    {
        require(_to != address(0));
        require(blacklisted[msg.sender] != true);
        address owner = _msgSender();
        _transfer(owner, _to, _value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param amount uint256 the amount of tokens to be transferred
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override whenNotPaused returns (bool) {
        address spender = _msgSender();
        require(to != address(0));
        require(blacklisted[msg.sender] != true);
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

   /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    
    function mint(address to, uint256 amount) public whenNotPaused onlyOwner {
        require(_initialSupply + amount <= _totalSupply);
        _mint(to, amount);
        _initialSupply += amount;
    }

    function addblackListUser(address _blacklistUser)
        public
        whenNotPaused
        onlyOwner
    {
        blacklisted[_blacklistUser] = true;
    }

    function removeblackListUser(address _blacklistUser)
        public
        whenNotPaused
        onlyOwner
    {
        blacklisted[_blacklistUser] = false;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}