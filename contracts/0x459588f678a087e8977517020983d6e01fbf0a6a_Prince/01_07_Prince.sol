// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
//import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Whitelistable.sol";

/**
 * @title Prince Token
 * @dev ERC20 Token for PRINCE
 */
contract Prince is Ownable, ERC20, Whitelistable {
    //using SafeMath for uint256;

    uint256 private constant TOTAL_SUPPLY_MAX = 950000000000;
    address private _manager;
    bool private _paused;
    uint8 private immutable _decimals;
    string private _documentURI;

    event ManagerChanged(address indexed newManager);
    event DocumentURIChanged(string indexed newDocumentURI);
    event Pause();
    event Unpause();

    error Paused();
    error NotPaused();
    error InvalidAmount();

    /**
     * @dev Throws if called by any account other than a manager
     */
    modifier onlyManager() {
        if(msg.sender != _manager){
            revert Unauthorized();
        }
        _;
    }

    /**
     * @dev Throws if PRINCE transfer: paused
     */
    modifier whenNotPaused() {
        if(_paused){
            revert Paused();
        }
        _;
    }

    constructor(string memory name, string memory symbol, address manager, address owner, uint8 tokenDecimals) 
        ERC20(name, symbol)
        Whitelistable(manager) 
    {
        if(manager == address(0)){
            revert ZeroAddress();
        }
        _manager = manager;
        _decimals = tokenDecimals;
        _paused = true;
        _transferOwnership(owner);
        
    }

    /**
     * @notice Transfer tokens by manager
     * @param from Payer's address
     * @param to Payee's address
     * @param amount transfer amount
     * @return True if successful
     */
    function transferByManager(address from, address to, uint256 amount) 
        external 
        virtual 
        onlyManager  
        inWhitelist(from)
        inWhitelist(to) 
        returns (bool) 
    {
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Function to mint tokens 
     * @param to The address that will receive the minted tokens.
     * @param amount The amount of tokens to mint. Must be less than or equal to the total supply.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address to, uint256 amount) 
        external 
        onlyManager 
        returns (bool)
    {
        if(amount + totalSupply() > TOTAL_SUPPLY_MAX){
            revert InvalidAmount();
        }
        _mint(to, amount);
        _addWhitelist(to);
        return true;
    }

    /**
     * @dev allows a minter to burn some of account tokens
     * @param account address of the account whose token to be burned
     * @param amount uint256 the amount of tokens to be burned
     * @return A boolean that indicates if the operation was successful.
     */
    function burn(address account, uint256 amount) external onlyManager returns (bool) {
        _burn(account, amount);
        return true;
    }

    /**
     * @dev getManager address
     */
    function getManager() external view returns (address) {
        return _manager;
    }

    /**
     * @dev updateManager address by owner
     * @param newManager address
     */
    function updateManager(address newManager) external onlyOwner {
        if(newManager == address(0)){
            revert ZeroAddress();
        }
        _manager = newManager;
        emit ManagerChanged(_manager);
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() external view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev called by the manager to pause, triggers stopped state
     */
    function pause() external onlyManager {
        _paused = true;
        emit Pause();
    }

    /**
     * @dev called by the manager to unpause, returns to normal state
     */
    function unpause() external onlyManager {
        _paused = false;
        emit Unpause();
    }

    /**
     * 
     * @param documentURI_ Uniform Resource Identifier (URI) of Document  
     */
    function setDocumentURI(string calldata documentURI_) external onlyManager {
        _documentURI = documentURI_;
        emit DocumentURIChanged(_documentURI);
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function documentURI() external view returns(string memory){
        return _documentURI;
    }

    /**
     * @notice Transfer tokens from the caller
     * @param to    Payee's address
     * @param amount Transfer amount
     * @return True if successful
     */
    function transfer(address to, uint256 amount) 
        public 
        virtual 
        override 
        whenNotPaused() 
        inWhitelist(msg.sender)
        inWhitelist(to) 
        returns (bool) 
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @notice Transfer tokens by spending allowance
     * @param from  Payer's address
     * @param to    Payee's address
     * @param amount Transfer amount
     * @return True if successful
     */
    function transferFrom(address from, address to, uint256 amount) 
        public 
        virtual 
        override 
        whenNotPaused()
        inWhitelist(from)
        inWhitelist(to) 
        returns (bool) 
    {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
    */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    } 
}