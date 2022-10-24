// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import "./TimeLock.sol";

/**
 * Receipt token sent to stakers in CLR instance
 * Used to redeem underlying LP tokens
 */
contract StakedCLRToken is ERC20Upgradeable, TimeLock {
    address public clrPool;
    bool public transferable;

    //--------------------------------------------------------------------------
    // Constructor / Initializer
    //--------------------------------------------------------------------------

    // Initialize the implementation
    constructor() initializer {}

    function initialize(
        string memory _name,
        string memory _symbol,
        address _clrPool,
        bool _transferable
    ) external initializer {
        require(_clrPool != address(0), "CLR Pool cannot be 0x0 address");
        clrPool = _clrPool;
        transferable = _transferable;
        __ERC20_init(_name, _symbol);
    }

    /// @dev Helps to perform actions meant to be executed by the CLR Pool itself
    modifier onlyCLRPool() {
        require(
            msg.sender == clrPool,
            "Only CLR Pool instance may perform this action"
        );
        _;
    }

    /// @notice Mints SCLR tokens in exchange for LP's provided tokens to CLR instance
    /// @param _recipient (address) LP's address to send the SCLR tokens to
    /// @param _amount (uint256) SCLR tokens amount to be minted
    /// @return  (bool) indicates a successful operation
    function mint(address _recipient, uint256 _amount)
        external
        onlyCLRPool
        notLocked(_recipient)
        returns (bool)
    {
        lock(_recipient);
        _mint(_recipient, _amount);
        return true;
    }

    /// @notice Burns SCLR tokens as indicated
    /// @param _sender (address) LP's address account to burn SCLR tokens from
    /// @param _amount (uint256) SCLR token amount to be burned
    /// @return  (bool) indicates a successful operation
    function burnFrom(address _sender, uint256 _amount)
        external
        onlyCLRPool
        notLocked(_sender)
        returns (bool)
    {
        lock(_sender);
        _burn(_sender, _amount);
        return true;
    }

    /**
     * Overriden ERC-20 transfer function
     * Receipt tokens are non-transferable
     */
    function transfer(address recipient, uint256 amount)
        public
        override
        isTransferable
        notLocked(msg.sender)
        returns (bool)
    {
        lock(msg.sender);
        return super.transfer(recipient, amount);
    }

    /**
     * Overriden ERC-20 transferFrom function
     * Receipt tokens are non-transferable
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override isTransferable notLocked(sender) returns (bool) {
        lock(sender);
        return super.transferFrom(sender, recipient, amount);
    }

    modifier isTransferable() {
        require(transferable, "Staked Tokens are non-transferable");
        _;
    }
}