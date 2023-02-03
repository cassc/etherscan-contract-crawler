// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract KreaToken is Context, ERC20, Ownable {
    using SafeMath for uint256;

    address payable private _wallet;
    uint8 private constant _feeDivisor = 10;

    mapping(address => bool) private _isExcluded;

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner
    ) ERC20(name, symbol) {
        _mint(owner, initialSupply);
        _wallet = payable(owner);
    }

    function decimals() public pure override returns (uint8) {
        return 0;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function wallet() external view returns (address payable) {
        return _wallet;
    }

    function setWallet(address payable account) external onlyOwner {
        require(account != address(0), "Wallet is the zero address");
        _wallet = account;
    }

    function isExcluded(address account) external view returns (bool) {
        return _isExcluded[account];
    }

    function exclude(address account) external onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        _isExcluded[account] = true;
    }

    function include(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is not excluded");
        _isExcluded[account] = false;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        if (!_isExcluded[from]) {
            uint256 fee = amount.div(_feeDivisor);
            super._transfer(from, _wallet, fee);
            amount = amount.sub(fee);
        }
        super._transfer(from, to, amount);
    }
}