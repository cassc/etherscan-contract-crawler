// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./ERC20/ERC20Upgradeable.sol";
import "./ERC20/Ownable.sol";
import "./ERC20/ERC20PausableUpgradeable.sol";

abstract contract ERC20_FCG_Token {
    // Allows token minting
    function distributeTokens(address to, uint256 value) external virtual returns (bool success);

    // Pauses token use
    function pause() external virtual;

    // Unpauses token use
    function unpause() external virtual;

    // Burn tokens use
    function burn(address from, uint256 value) external virtual;

    // Returns the amount of tokens in existence.
    function totalSupply() external virtual view returns (uint256);
}

/**
 * @dev Pausable specifies if trade is opened or not.
 * @dev Ownable is keeping track of owner of the
 */
contract ManagementContract is OwnableUpgradeable, PausableUpgradeable {
    // Amount of max Mintable tokens
    uint256 private _maxMintable;

    // Amount of total minted tokens
    uint256 private _totalMinted;

    // Token as a main point of trading in the contract.
    ERC20_FCG_Token public FCG_Token;

    // Flag for initialization checks
    bool private _initializationCompleted;

    mapping(address => bool) whitelistedAddresses;

    event TokensDistribution(address to, uint256 tokensAmount);
    event ContractStateUpdated(bool isPaused);
    event BurnTokens(address from, uint256 amount);

    function initialize () public initializer {
        __Ownable_init();
        __Pausable_init();
        _initializationCompleted = false;
        addAddressToWhiteList(owner());
        closeTrade();
    }

    /**
     * @dev Owner can distribute tokens directly to receiver.
     */
    function distributeTokensForAddress(address receiver, uint amount) public isWhitelisted(msg.sender) whenNotPaused initializationCompleted returns (bool success) {
        return _distributeTokensForAddress(receiver, amount);
    }

    /**
     * @dev Distributing tokens for receiver.
     */
    function _distributeTokensForAddress(address receiver, uint tokensAmount) private returns (bool success) {
        require(receiver != address(0), 'FCG_Management_Contract: Receiver address must not be empty.');
        require(tokensAmount > 0, 'FCG_Management_Contract: Tokens amount should be defined.');

        // Calculating total amount of minted tokens
        uint256 total = _totalMinted + tokensAmount;

        // Restrict amount of mintable tokens
        require(total <= _maxMintable, 'FCG_Management_Contract: Amount of tokens to be minted exceeds the max tokens allowed amount.');

        // Minting tokens for the sender who passed Ether
        FCG_Token.distributeTokens(receiver, tokensAmount);

        _totalMinted += tokensAmount;

        // Emitting event about the tokens release for receiver.
        TokensDistribution(receiver, tokensAmount);

        return true;
    }

    /**
     * @dev Setup:
     *  - Token to be used
     */
    function setup(address tokenAddress) public onlyOwner pendingInitialization {
        // Loading the Token to work with
        FCG_Token = ERC20_FCG_Token(tokenAddress);
        _maxMintable = FCG_Token.totalSupply();

        // Setting initialization is complete
        _initializationCompleted = true;
    }


    /**
     * @dev Changes ERC20 Token status to paused.
     */
    function pauseToken() public onlyOwner {
        FCG_Token.pause();
    }

    /**
     * @dev Changes ERC20 Token status to unpaused.
     */
    function unpauseToken() public onlyOwner {
        FCG_Token.unpause();
    }

    /**
     * @dev Burn ERC20 Tokens status from account.
     */
    function burnTokens(address from, uint256 tokensAmount) public onlyOwner {
        require(from != address(0), 'FCG_Management_Contract: Receiver address must not be empty.');
        require(tokensAmount > 0, 'FCG_Management_Contract: Tokens amount should be defined.');
        
        FCG_Token.burn(from, tokensAmount);

        _totalMinted -= tokensAmount;

        BurnTokens(from, tokensAmount);
    }

    /**
     * @dev Closes the trade if opened. Can be controlled only by the owner.
     */
    function closeTrade() public onlyOwner whenNotPaused {
        _pause();

        ContractStateUpdated(true);
    }

    /**
     * @dev Opens the trade if closed. Can be controlled only by the owner.
     */
    function openTrade() public onlyOwner whenPaused {
        _unpause();

        ContractStateUpdated(false);
    }

    /**
     * @dev Add address to whitelist.
     */
    function addAddressToWhiteList(address _addressToWhitelist) public onlyOwner {
        whitelistedAddresses[_addressToWhitelist] = true;
    }

    /**
     * @dev remove address from whitelist.
     */
    function removeAddressFromWhiteList(address _addressInWhitelist) public onlyOwner {
        delete whitelistedAddresses[_addressInWhitelist];
    }


    /**
     * @dev Allows publicly to load amount of total minted tokens.
     */
    function getTotalMinted() public view returns (uint256 totalMinted) {
        return _totalMinted;
    }

    /**
     * @dev Check initialization state.
     */
    function getinitializationState() public view returns (bool initCompleted) {
        return _initializationCompleted;
    }

    function transferOwnership(address newOwner) public override  onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        delete whitelistedAddresses[owner()];
        addAddressToWhiteList(newOwner);
        _transferOwnership(newOwner);
    }
    
    /**
     * @dev Checks whether initialization is not completed.
     */
    modifier pendingInitialization() {
        require(!_initializationCompleted, 'FCG_Management_Contract: Initialization is already completed.');
        _;
    }

    /**
     * @dev Checks whether initialization is completed.
     */
    modifier initializationCompleted() {
        require(_initializationCompleted, 'FCG_Management_Contract: Initialization is not completed.');
        _;
    }


    /**
     * @dev Modifier to whitelisted users
     */
    modifier isWhitelisted(address _address) {
        require(whitelistedAddresses[_address], "Address need to be whitelisted");
        _;
    }

}