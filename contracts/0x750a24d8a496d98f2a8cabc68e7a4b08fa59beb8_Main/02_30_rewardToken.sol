// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

// ,--------.,------.,------.  ,------.,--.   ,--.
// '--.  .--'|  .---'|  .-.  \ |  .-.  \\  `.'  /
//    |  |   |  `--, |  |  \  :|  |  \  :'.    /
//    |  |   |  `---.|  '--'  /|  '--'  /  |  |
//    `--'   `------'`-------' `-------'   `--'
// ,-----.  ,------.  ,---.  ,------.
// |  |) /_ |  .---' /  O  \ |  .--. '
// |  .-.  \|  `--, |  .-.  ||  '--'.'
// |  '--' /|  `---.|  | |  ||  |\  \
// `------' `------'`--' `--'`--' '--'
//  ,---.   ,-----.   ,--. ,--.  ,---.  ,------.
// '   .-' '  .-.  '  |  | |  | /  O  \ |  .-.  \
// `.  `-. |  | |  |  |  | |  ||  .-.  ||  |  \  :
// .-'    |'  '-'  '-.'  '-'  '|  | |  ||  '--'  /
// `-----'  `-----'--' `-----' `--' `--'`-------'
//

//    _ _______ ______     _______
//   | |__   __/ __ \ \   / / ____|
//  / __) | | | |  | \ \_/ / (___
//  \__ \ | | | |  | |\   / \___ \
//  (   / | | | |__| | | |  ____) |
//   |_|  |_|  \____/  |_| |_____/

// @nftchef

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";

interface iCoreContract {
    function balanceOf(address owner) external view returns (uint256);
}

contract RewardToken is ERC20, ERC20Pausable, ERC20Burnable, Ownable {
    // @dev: deployed erc721 contract of NFT's earning rewards
    iCoreContract public CoreToken;
    uint256 public constant REWARD_RATE = 10 ether;

    // 10 year supply
    uint256 private immutable _cap = 365336530 ether;

    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastClaimed;
    mapping(address => uint256) public balances;

    mapping(address => bool) public accessAddresses;

    event RewardClaimed(address indexed user, uint256 reward);

    constructor(address _coreContractAddress)
        ERC20("Teddy Bear Squad Toys", "TOYS")
    {
        /// @dev: Initialize the erc721 contract
        CoreToken = iCoreContract(_coreContractAddress);
    }

    // Only callable by the erc721 contract on mint/transferFrom/safeTransferFrom.
    // Updates reward amount and last claimed timestamp
    function updateReward(
        address from,
        address to,
        uint256 qty
    ) external {
        require(msg.sender == address(CoreToken));
        if (from != address(0)) {
            rewards[from] += getPendingReward(from);
            lastClaimed[from] = block.timestamp;
            balances[from] -= qty;
        }
        if (to != address(0)) {
            balances[to] += qty;
            rewards[to] += getPendingReward(to);
            lastClaimed[to] = block.timestamp;
        }
    }

    function claimReward() external whenNotPaused {
        uint256 claimable = rewards[msg.sender] + getPendingReward(msg.sender);
        require(
            ERC20.totalSupply() + claimable <= cap(),
            "ERC20Capped: cap exceeded"
        );
        _mint(msg.sender, claimable);

        emit RewardClaimed(msg.sender, claimable);

        /// @dev: reset the state of a users claimed state and last claimed
        rewards[msg.sender] = 0;
        lastClaimed[msg.sender] = block.timestamp;
    }

    function getTotalClaimable(address user) external view returns (uint256) {
        return rewards[user] + getPendingReward(user);
    }

    function blocktime() public returns (uint256) {
        return block.timestamp;
    }

    function getPendingReward(address _user) internal view returns (uint256) {
        return
            (balances[_user] *
                REWARD_RATE *
                (block.timestamp -
                    (
                        lastClaimed[_user] > 0
                            ? lastClaimed[_user]
                            : block.timestamp
                    ))) / 1 days;
    }

    // @dev: Allow the main contract to burn tokens when 'spending'
    function spend(address user, uint256 amount) external {
        require(
            accessAddresses[msg.sender] || msg.sender == address(CoreToken),
            "Address does not have permission to burn"
        );
        _burn(user, amount);
    }

    /**
     * @dev Required override
     */

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Pausable) whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    // ｡☆✼★━━━━━━━━ ( ˘▽˘)っ♨  only owner ━━━━━━━━━━━━━★✼☆｡

    function setAccessAddresses(address _address, bool _access)
        external
        onlyOwner
    {
        accessAddresses[_address] = _access;
    }

    function setCoreAddress(address _address) external onlyOwner {
        CoreToken = iCoreContract(_address);
    }

    function togglePaused() external onlyOwner {
        paused() ? _unpause() : _pause();
    }
}