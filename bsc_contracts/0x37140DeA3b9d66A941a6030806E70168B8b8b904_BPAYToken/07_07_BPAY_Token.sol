//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BPAYToken is ERC20, Ownable {
    uint256 public maxTxAmount = (totalSupply() * 1) / 100;
    uint256 private cooldownTime = 1 days;

    mapping(address => bool) private _isExcludedFromMaxTx;
    mapping(address => uint256) private _lockedUntil;
    mapping(address => uint256) private _timelock;
    mapping(address => bool) private _whitelist;
    mapping(address => bool) private _isExcludedFromFee;

    // Anti whale feature
    /**
     * @dev Set the maximum transaction amount as a percentage of the total supply.
     * Only the contract owner can call this function.
     * @param maxTxPercent The maximum transaction amount as a percentage of the total supply.
     */
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
        require(
            maxTxPercent > 0,
            "BPAYToken: maxTxPercent should be greater than 0"
        );
        require(
            block.timestamp > _timelock[msg.sender],
            "BPAYToken: Function is timelocked."
        );
        maxTxAmount = (totalSupply() * maxTxPercent) / 100;
        _timelock[msg.sender] = block.timestamp + cooldownTime;
    }

    /**
     * @dev Exclude an account from the maximum transaction amount limit.
     * Only the contract owner can call this function.
     * @param account The account to be excluded.
     */
    function excludeFromMaxTx(address account) external onlyOwner {
        require(
            account != address(0),
            "BPAYToken: Cannot exclude the zero address."
        );
        require(
            !_isExcludedFromMaxTx[account],
            "BPAYToken: Account is already excluded."
        );
        _isExcludedFromMaxTx[account] = true;
    }

    /**
     * @dev Include an account in the maximum transaction amount limit.
     * Only the contract owner can call this function.
     * @param account The account to be included.
     */
    function includeInMaxTx(address account) external onlyOwner {
        require(
            account != address(0),
            "BPAYToken: Cannot include the zero address."
        );
        require(
            _isExcludedFromMaxTx[account],
            "BPAYToken: Account is not excluded."
        );
        _isExcludedFromMaxTx[account] = false;
    }

    /**
    @dev Internal function to transfer tokens from one address to another.
    It checks whether the transfer amount exceeds the maximum transaction amount and whether the token transfer is locked for the sender.
    If the recipient is whitelisted, it transfers the tokens without any restrictions. If not, it checks whether the transfer amount exceeds the maximum transaction amount.
    @param sender The address sending the tokens
    @param recipient The address receiving the tokens
    @param amount The amount of tokens to transfer
    */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (
            (_isExcludedFromMaxTx[sender] == false &&
                _isExcludedFromMaxTx[recipient] == false) &&
            msg.sender != owner()
        ) {
            require(
                amount <= maxTxAmount,
                "BPAYToken: Transfer amount exceeds the maxTxAmount."
            );
        }
        require(
            block.timestamp > _lockedUntil[sender],
            "BPAYToken: Token transfer is locked."
        );
        if (_whitelist[recipient] == true) {
            super._transfer(sender, recipient, amount);
        } else {
            require(
                (amount <= maxTxAmount || msg.sender == owner()),
                "BPAYToken: Recipient is not whitelisted and transfer amount exceeds the maxTxAmount."
            );
            super._transfer(sender, recipient, amount);
        }
    }

    // No tax token
    /**
     * @dev Constructor that initializes the BPAYToken contract.
     * The contract owner receives the total supply of tokens, and sends the circulating supply to themselves.
     */
    constructor() ERC20("BPAY", "BPAY") {
        uint256 totalSupply = 10000000000 * 10**decimals();
    //    uint256 circulatingSupply = 2687500000 * 10**decimals();

        _mint(msg.sender, totalSupply);
    }

    /**
     * @dev Burns a specific amount of tokens from the sender's account.
     * @param amount The amount of token to be burned.
     */
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    /**
     * @dev Exclude an account from fee.
     * Can only be called by the owner.
     * @param account The account to exclude.
     */
    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    /**
     * @dev Include an account in fee.
     * Can only be called by the owner.
     * @param account The account to include.
     */
    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    /**
     * @dev Lock a specific amount of tokens for a specific duration of time.
     * Can only be called by the token holder.
     * @param amount The amount of tokens to be locked.
     * @param duration The duration in seconds for which the tokens should be locked.
     */
    function lockTokens(uint256 amount, uint256 duration) public {
        require(amount > 0, "BPAYToken: Amount should be greater than 0.");
        require(duration > 0, "BPAYToken: Duration should be greater than 0.");
        require(
            amount <= balanceOf(msg.sender),
            "BPAYToken: You do not have enough tokens to lock."
        );
        require(
            block.timestamp > _timelock[msg.sender],
            "BPAYToken: Function is timelocked."
        );
        require(
            _lockedUntil[msg.sender] < block.timestamp,
            "BPAYToken: Tokens are already locked."
        );

        _lockedUntil[msg.sender] = block.timestamp + duration;
        _timelock[msg.sender] = block.timestamp + cooldownTime;

        require(
            transfer(address(this), amount),
            "BPAYToken: Transfer to contract failed."
        );
    }

    /**
     * @dev Check if an account's tokens are currently locked.
     * @param account The account to check.
     * @return A boolean indicating whether the tokens are locked or not.
     */
    function isLocked(address account) external view returns (bool) {
        return block.timestamp <= _lockedUntil[account];
    }

    /**
     * @dev Add an address to the whitelist. Only the contract owner can call this function.
     * @param account The address to add to the whitelist
     */
    function addToWhitelist(address account) external onlyOwner {
        require(
            account != address(0),
            "BPAYToken: Cannot add the zero address to the whitelist."
        );
        require(
            !_whitelist[account],
            "BPAYToken: Address is already whitelisted."
        );
        _whitelist[account] = true;
    }

    /**
     * @dev Remove an address from the whitelist. Only the contract owner can call this function.
     * @param account The address to remove from the whitelist
     */
    function removeFromWhitelist(address account) external onlyOwner {
        _whitelist[account] = false;
    }

    /**
     * @dev Fallback function to receive ether sent to the contract. Reverts if called.
     */
    receive() external payable {
        revert("BPAYToken: Contract does not accept ETH");
    }
}