// in position collaterized by 0.5 UP on the left leg and 0.5 DOWN on the right leg

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "@openzeppelin/contracts-4.4.1/token/ERC20/IERC20.sol";
import "../interfaces/IPosition.sol";

// Internal references
import "./RangedMarket.sol";

contract RangedPosition is IERC20 {
    /* ========== STATE VARIABLES ========== */

    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    RangedMarket public rangedMarket;

    mapping(address => uint) public override balanceOf;
    uint public override totalSupply;

    // The argument order is allowance[owner][spender]
    mapping(address => mapping(address => uint)) private allowances;

    // Enforce a 1 cent minimum amount
    uint internal constant _MINIMUM_AMOUNT = 1e16;

    address public thalesRangedAMM;
    /* ========== CONSTRUCTOR ========== */

    bool public initialized = false;

    function initialize(
        address market,
        string calldata _name,
        string calldata _symbol,
        address _thalesRangedAMM
    ) external {
        require(!initialized, "Ranged Market already initialized");
        initialized = true;
        rangedMarket = RangedMarket(market);
        name = _name;
        symbol = _symbol;
        thalesRangedAMM = _thalesRangedAMM;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        if (spender == thalesRangedAMM) {
            return type(uint256).max;
        } else {
            return allowances[owner][spender];
        }
    }

    function burn(address claimant, uint amount) external onlyRangedMarket {
        balanceOf[claimant] = balanceOf[claimant] - amount;
        totalSupply = totalSupply - amount;
        emit Burned(claimant, amount);
        emit Transfer(claimant, address(0), amount);
    }

    function mint(address minter, uint amount) external onlyRangedMarket {
        _requireMinimumAmount(amount);
        totalSupply = totalSupply + amount;
        balanceOf[minter] = balanceOf[minter] + amount; // Increment rather than assigning since a transfer may have occurred.
        emit Mint(minter, amount);
        emit Transfer(address(0), minter, amount);
    }

    /* ---------- ERC20 Functions ---------- */

    function _transfer(
        address _from,
        address _to,
        uint _value
    ) internal returns (bool success) {
        require(_to != address(0) && _to != address(this), "Invalid address");

        uint fromBalance = balanceOf[_from];
        require(_value <= fromBalance, "Insufficient balance");

        balanceOf[_from] = fromBalance - _value;
        balanceOf[_to] = balanceOf[_to] + _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    function transfer(address _to, uint _value) external override returns (bool success) {
        return _transfer(msg.sender, _to, _value);
    }

    function transferFrom(
        address _from,
        address _to,
        uint _value
    ) external override returns (bool success) {
        if (msg.sender != thalesRangedAMM) {
            uint fromAllowance = allowances[_from][msg.sender];
            require(_value <= fromAllowance, "Insufficient allowance");
            allowances[_from][msg.sender] = fromAllowance - _value;
        }
        return _transfer(_from, _to, _value);
    }

    function approve(address _spender, uint _value) external override returns (bool success) {
        require(_spender != address(0));
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function getBalanceOf(address account) external view returns (uint) {
        return balanceOf[account];
    }

    function getTotalSupply() external view returns (uint) {
        return totalSupply;
    }

    modifier onlyRangedMarket {
        require(msg.sender == address(rangedMarket), "only the Ranged Market may perform these methods");
        _;
    }

    function _requireMinimumAmount(uint amount) internal pure returns (uint) {
        require(amount >= _MINIMUM_AMOUNT || amount == 0, "Balance < $0.01");
        return amount;
    }

    event Mint(address minter, uint amount);
    event Burned(address burner, uint amount);
}