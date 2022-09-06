// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../SYLToken/SYLVestingWallet.sol";

contract SYLBank is AccessControl {
    bytes32 public constant DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");

    ERC20Burnable immutable public erc20;
    SYLVestingWallet immutable public vestingWallet;
    mapping(address => uint256) public claimables;

    struct Reward {
        address to;
        uint256 amount;
    }

    event Swap(address indexed _address, uint256 _amount);
    event Claim(address indexed _address, uint256 _amount);
    event Airdrop(address indexed _address, uint256 _amount);

    constructor(address erc20Address, address vestingWalletAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        erc20 = ERC20Burnable(erc20Address);
        vestingWallet = SYLVestingWallet(vestingWalletAddress);
    }

    /**
     * @dev Swap function for exchanging SYLToken to karma point
     */
    function swap(uint256 amount) external virtual {
        erc20.transferFrom(msg.sender, address(this), amount);
        emit Swap(msg.sender, amount);
    }

    /**
     * @dev Claim function for user to claim its claimable
     */
    function claim() external {
        uint256 claimable = claimables[msg.sender];
        require(claimable > 0, "Zero claimable");

        // release vesting wallet to update beneficiary balance
        vestingWallet.release();

        address treasury = vestingWallet.beneficiary();
        uint256 treasuryBalance = erc20.balanceOf(treasury);

        // compare balance of treasury pool and claimable of msg.sender
        if (treasuryBalance >= claimable) {
            // primarily transfer amount from treasury to msg.sender
            erc20.transferFrom(treasury, msg.sender, claimable);
        } else {
            // primarily transfer amount from treasury to msg.sender
            erc20.transferFrom(treasury, msg.sender, treasuryBalance);
            // and then transfer claimable left from balance of SYLReward contract
            erc20.transfer(msg.sender, claimable - treasuryBalance);
        }
        claimables[msg.sender] = 0;
        emit Claim(msg.sender, claimable);
    }

    /**
     * @dev Setter for the claimables assigned to each users.
     */
    function addClaimables(Reward[] calldata items) external onlyRole(DISTRIBUTOR_ROLE) {
        for (uint256 i = 0; i < items.length; i++) {
            claimables[items[i].to] += items[i].amount;
        }
    }

    /**
     * @dev Removes claimable assigned to each users.
     *      Only use this function when claimables are set incorrectly.
     */
    function removeClaimables(address[] calldata addresses) external onlyRole(DISTRIBUTOR_ROLE) {
        for (uint256 i = 0; i < addresses.length; i++) {
            claimables[addresses[i]] = 0;
        }
    }

    /**
     * @dev Airdrop rewards to each users
     */
    function airdrop(Reward[] calldata items) external onlyRole(DISTRIBUTOR_ROLE) {
        for (uint256 i = 0; i < items.length; i++) {
            erc20.transfer(items[i].to, items[i].amount);
            emit Airdrop(items[i].to, items[i].amount);
        }
    }

    /**
     * @dev Burn SYLToken
     */
    function burn(uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        erc20.burn(amount);
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        erc20.transfer(msg.sender, erc20.balanceOf(address(this)));
    }
}