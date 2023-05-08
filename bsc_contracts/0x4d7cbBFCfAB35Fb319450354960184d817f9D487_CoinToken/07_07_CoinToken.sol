pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CoinToken is Ownable, ERC20 {
    using SafeMath for uint256;

    uint256 private _transferFee;
    uint256 private feeDenominator;
    bool public isTakeFee;

    mapping(address => bool) tokenBlacklist;
    mapping(address => bool) tokenWhitelist;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply_
    ) public ERC20(name_, symbol_) {
        _mint(msg.sender, initialSupply_);
        _transferFee = 1;
        feeDenominator = 1000;
        isTakeFee = false;
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    function mint(address _account, uint256 _amount) public onlyOwner {
        _mint(_account, _amount);
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        require(tokenBlacklist[msg.sender] == false);
        require(tokenBlacklist[to] == false);

        return _sibTransfer(_msgSender(), to, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        require(tokenBlacklist[msg.sender] == false);
        require(tokenBlacklist[sender] == false);
        require(tokenBlacklist[recipient] == false);
        address spender = _msgSender();
        _spendAllowance(sender, spender, amount);
        return _sibTransfer(sender, recipient, amount);
    }

    function _sibTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        uint256 amountReceived = takeFee(sender, amount);
        _transfer(sender, recipient, amountReceived);
        return true;
    }

    function takeFee(
        address sender,
        uint256 amount
    ) internal returns (uint256) {
        if (!isTakeFee) {
            return amount;
        }
        uint256 feeAmount = (amount * _transferFee) / feeDenominator;
        _transfer(sender, address(this), feeAmount);
        return amount - feeAmount;
    }

    function setIsTakeFee(bool _isTakeFee) external onlyOwner {
        isTakeFee = _isTakeFee;
    }

    function _blackList(
        address _address,
        bool _isBlackListed
    ) external onlyOwner returns (bool) {
        require(tokenBlacklist[_address] != _isBlackListed);
        tokenBlacklist[_address] = _isBlackListed;

        return true;
    }
}