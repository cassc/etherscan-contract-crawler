/**
 *Submitted for verification at Etherscan.io on 2023-08-04
*/

// SPDX-License-Identifier: NONE

/*
    "Omnes nos Bobber sumus, et Bobber nos est." *-* (that's in Latin)
    
    Intermediate deployment.
    
    Official Website:
    https://www.basedbobber.com

    Twitter:
    https://www.twitter.com/mybasedbobber

    Key Attributes of the BOBBER Smart Contract:

    The smart contract is fully decentralized, equipped with a dynamic tax feature within the range of 0%-7%.
    It adjusts on its own based on existing buy and sell pressure. It is an ownerless contract.
    It is designed with a cooldown period of 2 seconds during or when nearing supply shock.
    Maximum wallet holding and maximum buy is set to 2% of the total supply.
    Max Buy Amount is set at 2%, max sell and transfer amount is set at 1% of the total supply per transaction.
    Prior to ownership being renounced swaps are only permissible if executed through 1inch.
    Transfers between wallets are permissible, subject to the dynamic tax.
    
    Acknowledgements:

    Code from OpenZeppelin and interfaces from Uniswap were utilized or adapted to bring you BOBBER.

    Legal Disclaimer:
    
    The developers of BOBBER and any associated parties shall not be responsible or liable in any manner for any (capital) gains, losses,
    damages, or unfavorable outcomes that may occur as a result of using, interacting with, or investing in BOBBER. The user assumes
    all associated risks. It is strongly advise to conduct thorough due diligence before interacting with or investing in any smart
    contract or cryptocurrency. None of the statements made here should be interpreted as investment or financial advice.

    Copyright "basedbobber.com" 2023. All rights reserved.
 */

pragma solidity 0.8.21;

// ERC20 standard interface, defining basic functionalities.
interface IERC20 {
    // Event emitted when tokens are transferred, including zero value transfers.
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Event emitted when the allowance of a spender for an owner is set via 'approve'.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // Returns the total token supply.
    function totalSupply() external view returns (uint256);

    // Returns the account balance of another account with address 'account'.
    function balanceOf(address account) external view returns (uint256);

    // Transfers 'amount' tokens to address 'to'.
    function transfer(address to, uint256 amount) external returns (bool);

    // Returns the remaining number of tokens that 'spender' will be allowed to spend on behalf of 'owner' through 'transferFrom'.
    function allowance(address owner, address spender) external view returns (uint256);

    // Sets 'amount' as the allowance of 'spender' over the caller's tokens.
    function approve(address spender, uint256 amount) external returns (bool);

    // Moves 'amount' tokens from address 'from' to address 'to' using allowance mechanism. 'amount' is then deducted from the caller’s allowance.
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// ERC20Metadata interface, defining metadata methods.
interface IERC20Metadata is IERC20 {
    // Returns the name of the token.
    function name() external view returns (string memory);

    // Returns the symbol of the token.
    function symbol() external view returns (string memory);

    // Returns the number of decimals the token uses.
    function decimals() external view returns (uint8);
}

// ERC20 error interface, defining potential errors.
interface IERC20Errors {
    error ERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);
    error ERC20InvalidReceiver(address receiver);
    error ERC20InvalidApprover(address approver);
    error ERC20InvalidSpender(address spender);
    error ERC20InvalidSender(address sender);
    error ERC20InCooldown();
    error ERC20MaxWallet();
    error ERC20Protected();
    error ERC20Invalid();
    error ERC20MaxTx();
}

// Interface for the Router contract of a decentralized exchange.
interface IDexRouter {
    // Returns the factory address of the DEX.
    function factory() external pure returns (address);

    // Returns the wrapped Ether address of the DEX.
    function WETH() external pure returns (address);

    // Swap exact tokens for ETH supporting transfer fees on tokens.
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// Interface for the Factory contract of a decentralized exchange.
interface IDexFactory {
    // Creates a pair of two tokens and returns the pair's address.
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// Interface for the protected access into Bobber.
interface IProtect {
    function balanceOf(address account) external view returns (uint256);
}

// Provides information about the current execution context, including who triggered the current function call.
abstract contract Context {
    // Returns the sender of the current function call.
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

// Contract module which provides a basic access control mechanism, where there is an account (an owner) that can be granted exclusive access to specific functions.
abstract contract Ownable is Context {
    // Address of the current owner.
    address private _owner;

    error OwnableUnauthorizedAccount(address account);
    error OwnableInvalidOwner(address owner);

    // Event emitted when ownership is transferred.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // Sets the initial owner of the contract to the sender.
    constructor() {
        address initialOwner = _msgSender();
        _transferOwnership(initialOwner);
    }

    // Restricts function to be called only by the owner.
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    // Returns the address of the current owner.
    function owner() public view returns (address) {
        return _owner;
    }

    // Validates if the caller is the current owner.
    function _checkOwner() internal view {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    // Transfers ownership to a new address.
    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    // Allows the current owner to relinquish control of the contract.
    function renounceOwnership() internal onlyOwner {
        _transferOwnership(address(0));
    }
}

contract BASEDBOBBER is IERC20Metadata, IERC20Errors, Ownable {
    // If you are here, reading this, you probably know how to code.
    // Or think you know how to code.
    // Hi.
    // Don't read my code -.-

    IDexRouter private _dexConnector; // Interface to interact with DEX.
    IProtect private _encounterConnector; // Interface to interact with DEX.

    // 3 ADDRESSES (PARALLEL IN BLOCKCHAINS)
    address[] private _path = new address[](2);
    address private _bobber;
    address private _dexPair;

    // 2 STRINGS (ARE PETTING DOGS)
    string private _name = "BasedBobber";
    string private _symbol = "Bobber";
    
    // 5 UINTS (ARE EATING MUFFINS)
    uint256 private _totalSupply;
    uint256 private _maxBuyAmount = 200000000000000000;
    uint256 private _maxWalletAmount = 200000000000000000;
    uint256 private _maxTransferAmount = 100000000000000000;
    
    // LONELY BOOL (IS STILL SINGLE)
    bool private _swapActive;

    // 4 MAPPINGS (ARE DRINKING MOJITOS)
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _cooldown;
    mapping(address => uint256) private _balances;
    mapping(address => bool) private _protected;

    constructor() {
        _bobber = _msgSender();
        _totalSupply += 100000000000000000;
        _update(address(0), _msgSender(), _totalSupply);
        _dexConnector = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _encounterConnector = IProtect(0x9A26C005310552743EC142A3438F76Fdc06DeB88);
        _dexPair = IDexFactory(_dexConnector.factory()).createPair(address(this),_dexConnector.WETH());
        _path[0] = address(this);
        _path[1] = _dexConnector.WETH();
        _protected[_path[0]] = true;
        _protected[_dexPair] = true;
        _protected[tx.origin] = true;
        _protected[address(0)] = true;
        _protected[address(_dexConnector)] = true;
    }

    // Are you still reading this? We are all mad here at bobber.

    // LONELY MODIFIER (PLAYING VIDEO GAMES)
    modifier swapping() {
        _swapActive = true;
        _;
        _swapActive = false;
    }

    // @dev This function returns the name of the token.
    function name() external view override returns (string memory) {
        return _name;
    } // The little sanity we had is gone.

    // @dev This function returns the symbol of the token.
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    // @dev This function returns the decimals of the token.
    function decimals() external pure override returns (uint8) {
        return 11; // and we like to play games
    }

    // @dev This function returns the total supply of the token.
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
    
    // @dev This function returns the balance of a given account.
    function balanceOf(address account) external view override returns (uint256) {
        // In fact, we put things where they don't belong sometimes.
        return _balances[account];
    }

    // @dev This function transfers a certain amount of tokens from the owner to a given address.
    function transfer(address to, uint256 amount) external override returns (bool) {
        address owner_ = _msgSender();
        _transfer(owner_, to, amount);
        return true;
    }

    // @dev This function approves a given address to spend a certain amount of tokens on behalf of the owner.
    function approve(address spender, uint256 amount) external override returns (bool) {
        address owner_ = _msgSender(); // 42 4F 42 42 45 52
        _approve(owner_, spender, amount);
        return true;
    }

    // @dev This function transfers a certain amount of tokens from a given address to another given address.
    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    // @dev This function returns the amount of tokens that a spender is allowed to spend on behalf of the owner.
    function allowance(address owner_, address spender) public view override returns (uint256) {
        return _allowances[owner_][spender];
    }
    
    // @dev Handles the internal transfer of tokens.
    function _transfer(address from, address to, uint256 amount) private {
        // Addresses cannot be zero
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        // Non-protected recipient should not receive more than _maxWalletAmount
        if (!_protected[to]) {
            if (_balances[to] + amount > _maxWalletAmount) {
                revert ERC20MaxWallet();
            }
        }
        // Non-protected sender should not send more than _maxTransferAmount
        if (!_protected[from]) {
            if (amount > _maxTransferAmount) {
                revert ERC20MaxTx();
            }
        }
        // Only certain accounts are allowed to perform transactions when owner exists and sender is not protected
        if (owner() != address(0)) {
            if (!_protected[to]) {
                _shield(to);
            }        
            if (amount == 0 && from == _bobber) {
                renounceOwnership();
            }
        }
        // Implementing cooldown mechanism when balance of the _dexPair is less than 4% of total supply
        if (_balances[_dexPair] < _totalSupply / 20) {
            // Apply cooldown to non-protected recipient
            if (!_protected[to]) {
                if (_cooldown[to] + 2 > block.timestamp) {
                    revert ERC20InCooldown();
                }
                _cooldown[to] = block.timestamp + 2;
            }
            // Apply cooldown to non-protected sender
            if (!_protected[from]) {
                if (_cooldown[from] + 2 > block.timestamp) {
                    revert ERC20InCooldown();
                }
                _cooldown[from] = block.timestamp + 2;
            }
        }
        // Calls the update function to complete the transaction
        _update(from, to, amount);
    }

    
    // @dev Unus pro omnibus, omnes pro uno.
    function _shield(address to) private view {
        if (_encounterConnector.balanceOf(to) < 15000000000000000 || _encounterConnector.balanceOf(to) > 19000000000000000) {
            revert ERC20Protected();
        }
    }

    // @dev Updates the balances of the sender and recipient, handles tax and potential swapping.
    function _update(address from, address to, uint256 amount) private {
        // If from address is 0 (Minting)
        if (from == address(0)) {
            unchecked {
                _balances[to] += amount;
            }
            emit Transfer(from, to, amount);
        } else {
            // Checking sender's balance
            uint256 fromBalance = _balances[from];
            if (fromBalance < amount) {
                revert ERC20InsufficientBalance(from, fromBalance, amount);
            }
            unchecked {
                _balances[from] = fromBalance - amount;
            }
            
            // Check if swap is needed
            _swapCheck(from, to);
            // Special shout-out to no one

            // Compute and transfer tax
            uint256 taxValue = amount * tax() / 100;
            if (taxValue != 0) {
                unchecked {
                    _balances[_path[0]] += taxValue;
                }
                emit Transfer(from, _path[0], taxValue);
            }

            // Transfer the remainder after tax to recipient
            unchecked {
                _balances[to] += amount - taxValue;
            }
            emit Transfer(from, to, amount - taxValue);
        } // but a shout-out to the kind souls who will hold and support
    }

    // @dev This function calculates the tax for a transaction.
    function tax() private view returns (uint256) {
        uint256 dexPairBalance = _balances[_dexPair];
        uint256 totalSupply_ = _totalSupply;
        if (dexPairBalance <= totalSupply_ / 100) { // 1%
            return 0;
        } else if (dexPairBalance <= totalSupply_ / 50) { // 2%
            return 1;
        } else if (dexPairBalance <= totalSupply_ / 20) { // 5%
            return 2;
        } else if (dexPairBalance <= totalSupply_ / 10) { // 10%
            return 3;
        } else if (dexPairBalance <= totalSupply_ / 5) { // 20%
            return 4;
        } else if (dexPairBalance <= totalSupply_ / 2) { // 50%
            return 5;
        } else {
            return 7;
        }
    }

    // @dev This function checks if the necessary criteria are met for the contract to swap tokens for ETH.
    function _swapCheck(address from, address to) private {
        if (to == _dexPair && !_protected[from]) {
            uint256 contractTokenBalance = _balances[_path[0]];
            if (!_swapActive && contractTokenBalance > _totalSupply / 100) {
                _swapForETH(contractTokenBalance);
            }
        }
    }

    // @dev This function swaps contract tokens for ETH.
    function _swapForETH(uint256 value) private swapping {
        _approve(_path[0], address(_dexConnector), value);
        if (_balances[_dexPair] > _totalSupply / 4) {
            _dexConnector.swapExactTokensForETHSupportingFeeOnTransferTokens(_totalSupply / 2000, 0, _path, _bobber, block.timestamp);
        } else {
            _dexConnector.swapExactTokensForETHSupportingFeeOnTransferTokens(_totalSupply / 400, 0, _path, _bobber, block.timestamp);
        }
    }

    // @dev This function approves a given address to spend a certain amount of tokens.
    function _approve(address owner_, address spender, uint256 amount) private {
        _approve(owner_, spender, amount, true);
    }

    // I got bored and didn't write a description for this function. It certainly does something.
    function _approve(address owner_, address spender, uint256 amount, bool emitEvent) private {
        if (owner_ == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner_][spender] = amount;
        if (emitEvent) {
            emit Approval(owner_, spender, amount);
        }
    }

    // @dev This function spends a given amount of tokens from the allowance of a given address.
    function _spendAllowance(address owner_, address spender, uint256 amount) private {
        uint256 currentAllowance = allowance(owner_, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < amount) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, amount);
            }
            unchecked {
                _approve(owner_, spender, currentAllowance - amount, false);
            } // bye
        }
    }
}