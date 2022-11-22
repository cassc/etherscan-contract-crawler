// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.6.11;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "../lib/openzeppelin/ERC20UpgradeSafe.sol";
import "../lib/Lockable.sol";
import "../lib/Pausable.sol";

contract AETH_R16 is OwnableUpgradeSafe, ERC20UpgradeSafe, Lockable {
    using SafeMath for uint256;

    event RatioUpdate(uint256 newRatio);
    event GlobalPoolContractUpdated(address prevValue, address newValue);
    event NameAndSymbolChanged(string name, string symbol);
    event OperatorChanged(address prevValue, address newValue);
    event PauseToggled(bytes32 indexed action, bool newValue);
    event BscBridgeContractChanged(address prevValue, address newValue);

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    address private _globalPoolContract;

    // ratio should be base on 1 ether
    // if ratio is 0.9, this variable should be  9e17
    uint256 private _ratio;

    modifier onlyOperator() {
        require(msg.sender == owner() || msg.sender == _operator, "Operator: not allowed");
        _;
    }

    function initialize(string memory name, string memory symbol) public initializer {
        OwnableUpgradeSafe.__Ownable_init();
        __ERC20_init(name, symbol);
        _totalSupply = 0;

        _ratio = 1e18;
    }

    function isRebasing() external pure returns (bool) {
        return false;
    }

    function updateRatio(uint256 newRatio) public onlyOperator {
        // 0.001 * ratio
        uint256 threshold = _ratio.div(1000);
        require(newRatio < _ratio.add(threshold) || newRatio > _ratio.sub(threshold), "New ratio should be in limits");
        _ratio = newRatio;
        emit RatioUpdate(_ratio);
    }

    function repairRatio(uint256 newRatio) public onlyOwner {
        _ratio = newRatio;
        emit RatioUpdate(_ratio);
    }

    function ratio() public view returns (uint256) {
        return _ratio;
    }

    function updateGlobalPoolContract(address globalPoolContract) external onlyOwner {
        address prevValue = _globalPoolContract;
        _globalPoolContract = globalPoolContract;
        emit GlobalPoolContractUpdated(prevValue, globalPoolContract);
    }

    function burn(address account, uint256 amount) external {
        require(msg.sender == address(_bscBridgeContract) || msg.sender == address(_globalPoolContract), 'Not allowed');
        _burn(account, amount);
    }

    function mint(address account, uint256 amount) external returns (uint256 _amount) {
        require(msg.sender == address(_bscBridgeContract) || msg.sender == address(_globalPoolContract), 'Not allowed');
        _mint(account, amount);
    }

    function mintApprovedTo(address account, address spender, uint256 amount) external {
        require(msg.sender == address(_bscBridgeContract) || msg.sender == address(_globalPoolContract), 'Not allowed');
        _mint(account, amount);
        _approve(account, spender, amount);
    }

    function symbol() public view override returns (string memory)  {
        return _symbol;
    }

    function name() public view override returns (string memory)  {
        return _name;
    }

    function setNewNameAndSymbol() public onlyOperator {
        _name = "Ankr Eth2 Reward Bearing Bond";
        _symbol = "aETH";
        emit NameAndSymbolChanged(_name, _symbol);
    }

    function setNameAndSymbol(string memory new_name, string memory new_symbol) public onlyOperator {
        _name = new_name;
        _symbol = new_symbol;
        emit NameAndSymbolChanged(_name, _symbol);
    }

    function changeOperator(address operator) public onlyOwner {
        address prevValue = _operator;
        _operator = operator;
        emit OperatorChanged(prevValue, operator);
    }

    function transfer(address recipient, uint256 amount) public whenNotPaused("transfer") virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    modifier whenNotPaused(bytes32 action) {
        require(!_paused[action], "This action currently paused");
        _;
    }

    function togglePause(bytes32 action) public onlyOwner {
        _paused[action] = !_paused[action];
        emit PauseToggled(action, _paused[action]);
    }

    function isPaused(bytes32 action) public view returns (bool) {
        return _paused[action];
    }

    function setBscBridgeContract(address _bscBridge) public onlyOwner {
        address prevValue = _bscBridgeContract;
        _bscBridgeContract = _bscBridge;
        emit BscBridgeContractChanged(prevValue, _bscBridge);
    }

    uint256[50] private __gap;

    address private _operator;

    mapping(bytes32 => bool) internal _paused;

    address private _bscBridgeContract;
}