// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Inheritance
import "@openzeppelin/contracts-4.4.1/token/ERC20/IERC20.sol";
import "../interfaces/IPosition.sol";

// Libraries
import "@openzeppelin/contracts-4.4.1/utils/math/SafeMath.sol";

// Internal references
import "./PositionalMarket.sol";

contract Position is IERC20, IPosition {
    using SafeMath for uint;

    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    PositionalMarket public market;

    mapping(address => uint) public override balanceOf;
    uint public override totalSupply;

    // The argument order is allowance[owner][spender]
    mapping(address => mapping(address => uint)) private allowances;

    // Enforce a 1 cent minimum amount
    uint internal constant _MINIMUM_AMOUNT = 1e16;

    address public thalesAMM;

    bool public initialized = false;

    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _thalesAMM
    ) external {
        require(!initialized, "Positional Market already initialized");
        initialized = true;
        name = _name;
        symbol = _symbol;
        market = PositionalMarket(msg.sender);
        thalesAMM = _thalesAMM;
    }

    /// @notice allowance inherited IERC20 function
    /// @param owner address of the owner
    /// @param spender address of the spender
    /// @return uint256 number of tokens
    function allowance(address owner, address spender) external view override returns (uint256) {
        if (spender == thalesAMM) {
            return type(uint256).max;
        } else {
            return allowances[owner][spender];
        }
    }

    /// @notice mint function mints Position token
    /// @param minter address of the minter
    /// @param amount value to mint token for
    function mint(address minter, uint amount) external onlyMarket {
        _requireMinimumAmount(amount);
        totalSupply = totalSupply.add(amount);
        balanceOf[minter] = balanceOf[minter].add(amount); // Increment rather than assigning since a transfer may have occurred.

        emit Transfer(address(0), minter, amount);
        emit Issued(minter, amount);
    }

    /// @notice exercise function exercises Position token
    /// @dev This must only be invoked after maturity.
    /// @param claimant address of the claiming address
    function exercise(address claimant) external onlyMarket {
        uint balance = balanceOf[claimant];

        if (balance == 0) {
            return;
        }

        balanceOf[claimant] = 0;
        totalSupply = totalSupply.sub(balance);

        emit Transfer(claimant, address(0), balance);
        emit Burned(claimant, balance);
    }

    /// @notice exerciseWithAmount function exercises Position token
    /// @dev This must only be invoked after maturity.
    /// @param claimant address of the claiming address
    /// @param amount amount of tokens for exercising
    function exerciseWithAmount(address claimant, uint amount) external override onlyMarket {
        require(amount > 0, "Can not exercise zero amount!");

        require(balanceOf[claimant] >= amount, "Balance must be greather or equal amount that is burned");

        balanceOf[claimant] = balanceOf[claimant] - amount;
        totalSupply = totalSupply.sub(amount);

        emit Transfer(claimant, address(0), amount);
        emit Burned(claimant, amount);
    }

    /// @notice expire function is used for Position selfdestruct
    /// @dev This must only be invoked after the exercise window is complete.
    /// Any options which have not been exercised will linger.
    /// @param beneficiary address of the Position token
    function expire(address payable beneficiary) external onlyMarket {
        selfdestruct(beneficiary);
    }

    /// @notice transfer is ERC20 function for transfer tokens
    /// @param _to address of the receiver
    /// @param _value value to be transferred
    /// @return success
    function transfer(address _to, uint _value) external override returns (bool success) {
        return _transfer(msg.sender, _to, _value);
    }

    /// @notice transferFrom is ERC20 function for transfer tokens
    /// @param _from address of the sender
    /// @param _to address of the receiver
    /// @param _value value to be transferred
    /// @return success
    function transferFrom(
        address _from,
        address _to,
        uint _value
    ) external override returns (bool success) {
        if (msg.sender != thalesAMM) {
            uint fromAllowance = allowances[_from][msg.sender];
            require(_value <= fromAllowance, "Insufficient allowance");
            allowances[_from][msg.sender] = fromAllowance.sub(_value);
        }
        return _transfer(_from, _to, _value);
    }

    /// @notice approve is ERC20 function for token approval
    /// @param _spender address of the spender
    /// @param _value value to be approved
    /// @return success
    function approve(address _spender, uint _value) external override returns (bool success) {
        require(_spender != address(0));
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @notice getBalanceOf ERC20 function gets token balance of an account
    /// @param account address of the account
    /// @return uint
    function getBalanceOf(address account) external view override returns (uint) {
        return balanceOf[account];
    }

    /// @notice getTotalSupply ERC20 function gets token total supply
    /// @return uint
    function getTotalSupply() external view override returns (uint) {
        return totalSupply;
    }

    /// @notice transfer is internal function for transfer tokens
    /// @param _from address of the sender
    /// @param _to address of the receiver
    /// @param _value value to be transferred
    /// @return success
    function _transfer(
        address _from,
        address _to,
        uint _value
    ) internal returns (bool success) {
        market.requireUnpaused();
        require(_to != address(0) && _to != address(this), "Invalid address");

        uint fromBalance = balanceOf[_from];
        require(_value <= fromBalance, "Insufficient balance");

        balanceOf[_from] = fromBalance.sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);

        emit Transfer(_from, _to, _value);
        return true;
    }

    /// @notice _requireMinimumAmount checks that amount is greater than minimum amount
    /// @param amount value to be checked
    /// @return uint amount
    function _requireMinimumAmount(uint amount) internal pure returns (uint) {
        require(amount >= _MINIMUM_AMOUNT || amount == 0, "Balance < $0.01");
        return amount;
    }

    modifier onlyMarket() {
        require(msg.sender == address(market), "Only market allowed");
        _;
    }

    event Issued(address indexed account, uint value);
    event Burned(address indexed account, uint value);
}