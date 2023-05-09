pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract Artem229 is ERC20, ERC20Burnable, Ownable {
    mapping(address => bool) private _blockedAddresses;
    uint256 private _burnPercentage = 98;
    uint256 private _lastBurnTimestamp;
    uint256 private _burnInterval = 12 days;
    uint256 private _transactionFee;

    constructor() ERC20("Artem 229", "ARM") {
        _mint(msg.sender, 100000 * (10 ** uint256(decimals())));
        _lastBurnTimestamp = block.timestamp;
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function setTransactionFee(uint256 fee) external onlyOwner {
        _transactionFee = fee;
    }

    function blockAddress(address account) external onlyOwner {
        _blockedAddresses[account] = true;
    }

    function unblockAddress(address account) external onlyOwner {
        _blockedAddresses[account] = false;
    }

    function isBlocked(address account) public view returns (bool) {
        return _blockedAddresses[account];
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        require(!isBlocked(from), "Artem229: Address is blocked");
        require(!isBlocked(to), "Artem229: Address is blocked");
        super._beforeTokenTransfer(from, to, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        uint256 feeAmount = (amount * _transactionFee) / 100;
        uint256 netAmount = amount - feeAmount;
        super._transfer(sender, recipient, netAmount);
        super._transfer(sender, address(this), feeAmount);
    }

    function airdrop(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
        require(recipients.length == amounts.length, "Artem229: Recipients and amounts length mismatch");
        for (uint256 i = 0; i < recipients.length; i++) {
            _transfer(msg.sender, recipients[i], amounts[i]);
        }
    }

    function burnLiquidityTokens() external onlyOwner {
        require(block.timestamp >= _lastBurnTimestamp + _burnInterval, "Artem229: Not time to burn tokens yet");
        uint256 balance = balanceOf(address(this));
        uint256 burnAmount = (balance * _burnPercentage) / 100;
        _burn(address(this), burnAmount);
        _lastBurnTimestamp = block.timestamp;
    }
}
