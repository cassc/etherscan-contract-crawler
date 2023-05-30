// SPDX-License-Identifier: MIT

pragma solidity >=0.4.25 <0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IToken.sol";

contract Token is IToken, ERC20, AccessControl {
    using SafeMath for uint256;

    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 private constant SWAPPER_ROLE = keccak256("SWAPPER_ROLE");
    bytes32 private constant SETTER_ROLE = keccak256("SETTER_ROLE");

    IERC20 private swapToken;
    bool private swapIsOver;
    uint256 private swapTokenBalance;

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), "Caller is not a minter");
        _;
    }

    modifier onlySetter() {
        require(hasRole(SETTER_ROLE, _msgSender()), "Caller is not a setter");
        _;
    }

    modifier onlySwapper() {
        require(hasRole(SWAPPER_ROLE, _msgSender()), "Caller is not a swapper");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _swapToken,
        address _swapper,
        address _setter
    ) public ERC20(_name, _symbol) {
        _setupRole(SWAPPER_ROLE, _swapper);
        _setupRole(SETTER_ROLE, _setter);
        swapToken = IERC20(_swapToken);
        swapIsOver = false;
    }

    function init(address[] calldata instances) external onlySetter {
        require(instances.length == 5, "NativeSwap: wrong instances number");

        for (uint256 index = 0; index < instances.length; index++) {
            _setupRole(MINTER_ROLE, instances[index]);
        }
        renounceRole(SETTER_ROLE, _msgSender());
        swapIsOver = true;
    }

    function getMinterRole() external pure returns (bytes32) {
        return MINTER_ROLE;
    }

    function getSwapperRole() external pure returns (bytes32) {
        return SWAPPER_ROLE;
    }

    function getSetterRole() external pure returns (bytes32) {
        return SETTER_ROLE;
    }

    function getSwapTOken() external view returns (IERC20) {
        return swapToken;
    }

    function getSwapTokenBalance(uint256) external view returns (uint256) {
        return swapTokenBalance;
    }

    function initDeposit(uint256 _amount) external onlySwapper {
        require(
            swapToken.transferFrom(_msgSender(), address(this), _amount),
            "Token: transferFrom error"
        );
        swapTokenBalance = swapTokenBalance.add(_amount);
    }

    function initWithdraw(uint256 _amount) external onlySwapper {
        require(_amount <= swapTokenBalance, "amount > balance");
        swapTokenBalance = swapTokenBalance.sub(_amount);
        swapToken.transfer(_msgSender(), _amount);
    }

    function initSwap() external onlySwapper {
        require(!swapIsOver, "swap is over");
        uint256 balance = swapTokenBalance;
        swapTokenBalance = 0;
        require(balance > 0, "balance <= 0");
        _mint(_msgSender(), balance);
    }

    function mint(address to, uint256 amount) external override onlyMinter {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external override onlyMinter {
        _burn(from, amount);
    }

    // Helpers
    function getNow() external view returns (uint256) {
        return now;
    }
}