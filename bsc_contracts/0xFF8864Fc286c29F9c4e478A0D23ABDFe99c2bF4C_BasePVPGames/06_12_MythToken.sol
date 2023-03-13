// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "ERC20.sol";
import "IdexRouter.sol";
import "Ownable.sol";
import "IBEP20.sol";
import "PancakeSwapFactory.sol";
import "PancakeSwapRouter.sol";
import "SafeMath.sol";

contract MythToken {
    using SafeMath for uint256;

    uint8 private constant _decimals = 9;
    uint256 public _maxSupplyPossible = 1200000 * (10 ** _decimals);
    uint256 private _totalSupply = 1000000 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply;
    uint256 public _walletMax = (_totalSupply * 250) / 10000;

    string private constant _name = "Myth";
    string private constant _symbol = "MYTH";
    address public owner;

    mapping(address => uint256) private _balances;
    mapping(address => bool) public isAuthorizedForTokenMints;
    mapping(address => mapping(address => uint256)) private _allowances;

    event tokensMinted(uint256 amount, address mintedTo, address mintedBy);
    event tokensBurned(uint256 amount, address mintedTo, address mintedBy);
    event accountAuthorized(address account, bool status);

    constructor() {
        isAuthorizedForTokenMints[msg.sender] = true;
        _balances[msg.sender] = _totalSupply;
        owner = msg.sender;
    }

    receive() external payable {}

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function mintTokens(uint256 amount, address account) external {
        require(isAuthorizedForTokenMints[msg.sender], "Not Authorized");
        _balances[account] += amount;
        _totalSupply += amount;
        emit tokensMinted(amount, account, msg.sender);
    }

    function burnTokens(uint256 amount, address account) external {
        require(isAuthorizedForTokenMints[msg.sender], "Not Authorized");
        _balances[account] -= amount;
        _totalSupply -= amount;
        emit tokensBurned(amount, account, msg.sender);
    }

    function changeAuthorization(address _address, bool _status) external {
        require(msg.sender == owner, "only owner");
        isAuthorizedForTokenMints[_address] = _status;
        emit accountAuthorized(_address, _status);
    }
}