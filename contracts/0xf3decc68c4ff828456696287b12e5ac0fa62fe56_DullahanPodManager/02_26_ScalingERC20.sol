//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝


pragma solidity 0.8.16;
//SPDX-License-Identifier: BUSL-1.1

import "../oz/interfaces/IERC20.sol";
import "../oz/utils/Context.sol";
import {Errors} from  "../utils/Errors.sol";
import {WadRayMath} from  "../utils/WadRayMath.sol";

/** @title ScalingERC20 contract
 *  @author Paladin, inspired by Aave & OpenZeppelin implementations
 *  @notice ERC20 implementation of scaled balance token
*/
abstract contract ScalingERC20 is Context, IERC20 {
    using WadRayMath for uint256;

    // Constants

    /** @notice 1e18 scale */
    uint256 public constant UNIT = 1e18;

    /** @notice 1e27 - RAY - Initial Index for balance to scaled balance */
    uint256 internal constant INITIAL_INDEX = 1e27;

    // Structs

    /** @notice UserState struct 
    *   scaledBalance: scaled balance of the user
    *   index: last index for the user
    */
    struct UserState {
        uint128 scaledBalance;
        uint128 index;
    }

    // Storage

    /** @notice Total scaled supply */
    uint256 internal _totalSupply;

    /** @notice Allowances for users */
    mapping(address => mapping(address => uint256)) internal _allowances;

    /** @notice Token name */
    string private _name;
    /** @notice Token symbol */
    string private _symbol;
    /** @notice Token decimals */
    uint8 private _decimals;

    /** @notice User states */
    mapping(address => UserState) internal _userStates;


    // Events

    /** @notice Event emitted when minting */
    event Mint(address indexed user, uint256 scaledAmount, uint256 index);
    /** @notice Event emitted when burning */
    event Burn(address indexed user, uint256 scaledAmount, uint256 index);


    // Constructor

    constructor(
        string memory __name,
        string memory __symbol
    ) {
        _name = __name;
        _symbol = __symbol;
        _decimals = 18;
    }


    // View methods

    /**
    * @notice Get the name of the ERC20
    * @return string : Name
    */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
    * @notice Get the symbol of the ERC20
    * @return string : Symbol
    */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
    * @notice Get the decimals of the ERC20
    * @return uint256 : Number of decimals
    */
    function decimals() external view returns (uint8) {
        return _decimals;
    }

    /**
    * @notice Get the current total supply
    * @return uint256 : Current total supply
    */
    function totalSupply() public view override virtual returns (uint256) {
        uint256 _scaledSupply = _totalSupply;
        if(_scaledSupply == 0) return 0;
        return _scaledSupply.rayMul(_getCurrentIndex());
    }

    /**
    * @notice Get the current user balance
    * @param account Address of user
    * @return uint256 : User balance
    */
    function balanceOf(address account) public view override virtual returns (uint256) {
        return uint256(_userStates[account].scaledBalance).rayMul(_getCurrentIndex());
    }

    /**
    * @notice Get the current total scaled supply
    * @return uint256 : Current total scaled supply
    */
    function totalScaledSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
    * @notice Get the current user scaled balance
    * @param account Address of user
    * @return uint256 : User scaled balance
    */
    function scaledBalanceOf(address account) public view virtual returns (uint256) {
        return _userStates[account].scaledBalance;
    }

    /**
    * @notice Get the allowance of a spender for a given owner
    * @param owner Address of the owner
    * @param spender Address of the spender
    * @return uint256 : allowance amount
    */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }




    // Write methods

    /**
    * @notice Approve a spender to spend tokens
    * @param spender Address of the spender
    * @param amount Amount to approve
    * @return bool : success
    */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
    * @notice Increase the allowance given to a spender
    * @param spender Address of the spender
    * @param addedValue Increase amount
    * @return bool : success
    */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
    * @notice Decrease the allowance given to a spender
    * @param spender Address of the spender
    * @param subtractedValue Decrease amount
    * @return bool : success
    */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = allowance(owner, spender);
        if(currentAllowance < subtractedValue) revert Errors.ERC20_AllowanceUnderflow();
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
    * @notice Transfer tokens to the given recipient
    * @param recipient Address to receive the tokens
    * @param amount Amount to transfer
    * @return bool : success
    */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
    * @notice Transfer tokens from the spender to the given recipient
    * @param sender Address sending the tokens
    * @param recipient Address to receive the tokens
    * @param amount Amount to transfer
    * @return bool : success
    */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 _allowance = _allowances[sender][msg.sender];
        if(_allowance < amount) revert Errors.ERC20_AmountOverAllowance();
        if(_allowance != type(uint256).max) {
            _approve(
                sender,
                msg.sender,
                _allowances[sender][msg.sender] - amount
            );
        }
        _transfer(sender, recipient, amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }


    // Internal methods

    /**
    * @dev Get the current index to convert between balance and scaled balances
    * @return uint256 : Current index
    */
    // To implement in inheriting contract
    function _getCurrentIndex() internal virtual view returns(uint256) {}

    /**
    * @dev Approve a spender to spend tokens
    * @param owner Address of the woner
    * @param spender Address of the spender
    * @param amount Amount to approve
    */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        if(owner == address(0) || spender == address(0)) revert Errors.ERC20_ApproveAddressZero();

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
    * @dev Transfer tokens from the spender to the given recipient
    * @param sender Address sending the tokens
    * @param recipient Address to receive the tokens
    * @param amount Amount to transfer
    */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        if(sender == address(0) || recipient == address(0)) revert Errors.ERC20_AddressZero();
        if(sender == recipient) revert Errors.ERC20_SelfTransfer();
        if(amount == 0) revert Errors.ERC20_NullAmount();

        // Get the scaled amount to transfer for the given amount
        uint128 _scaledAmount = safe128(amount.rayDiv(_getCurrentIndex()));
        _transferScaled(sender, recipient, _scaledAmount);
    }

    /**
    * @dev Transfer the scaled amount of tokens
    * @param sender Address sending the tokens
    * @param recipient Address to receive the tokens
    * @param scaledAmount Scaled amount to transfer
    */
    function _transferScaled(
        address sender,
        address recipient,
        uint128 scaledAmount
    ) internal virtual {
        if(scaledAmount > _userStates[sender].scaledBalance) revert Errors.ERC20_AmountExceedBalance();

        _beforeTokenTransfer(sender, recipient, scaledAmount);

        unchecked {
            // Should never fail because of previous check
            // & because the scaledBalance of an user should never exceed the _totalSupply
            _userStates[sender].scaledBalance -= scaledAmount;
            _userStates[recipient].scaledBalance += scaledAmount;
        }

        _afterTokenTransfer(sender, recipient, scaledAmount);
    }

    /**
    * @dev Mint the given amount to the given address (by minting the correct scaled amount)
    * @param account Address to mint to
    * @param amount Amount to mint
    * @param _currentIndex Index to use to calculate the scaled amount
    * @return uint256 : Amount minted
    */
    function _mint(address account, uint256 amount, uint256 _currentIndex) internal virtual returns(uint256) {
        uint256 _scaledAmount = amount.rayDiv(_currentIndex);
        if(_scaledAmount == 0) revert Errors.ERC20_NullAmount();

        _beforeTokenTransfer(address(0), account, _scaledAmount);

        _userStates[account].index = safe128(_currentIndex);

        _totalSupply += _scaledAmount;
        _userStates[account].scaledBalance += safe128(_scaledAmount);

        _afterTokenTransfer(address(0), account, _scaledAmount);

        emit Mint(account, _scaledAmount, _currentIndex);
        emit Transfer(address(0), account, amount);

        return amount;
    }

    /**
    * @dev Burn the given amount from the given address (by burning the correct scaled amount)
    * @param account Address to burn from
    * @param amount Amount to burn
    * @param maxWithdraw True if burning the full balance
    * @return uint256 : Amount burned
    */
    function _burn(address account, uint256 amount, bool maxWithdraw) internal virtual returns(uint256) {
        uint256 _currentIndex = _getCurrentIndex();
        uint256 _scaledBalance = _userStates[account].scaledBalance;

        // if given maxWithdraw as true, we want to burn the whole balance for the user
        uint256 _scaledAmount = maxWithdraw ?  _scaledBalance: amount.rayDiv(_currentIndex);
        if(_scaledAmount == 0) revert Errors.ERC20_NullAmount();
        if(_scaledAmount > _scaledBalance) revert Errors.ERC20_AmountExceedBalance();

        _beforeTokenTransfer(account, address(0), _scaledAmount);
        
        _userStates[account].index = safe128(_currentIndex);

        _totalSupply -= _scaledAmount;
        _userStates[account].scaledBalance -= safe128(_scaledAmount);

        _afterTokenTransfer(account, address(0), _scaledAmount);
        
        emit Burn(account, _scaledAmount, _currentIndex);
        emit Transfer(account, address(0), amount);

        return amount;
    }


    // Virtual hooks

    /**
    * @dev Hook executed before each transfer
    * @param from Sender address
    * @param to Receiver address
    * @param amount Amount to transfer
    */
    // To implement in inheriting contract
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
    * @dev Hook executed after each transfer
    * @param from Sender address
    * @param to Receiver address
    * @param amount Amount to transfer
    */
    // To implement in inheriting contract
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}


    // Maths

    function safe128(uint256 n) internal pure returns (uint128) {
        if(n > type(uint128).max) revert Errors.NumberExceed128Bits();
        return uint128(n);
    }


}