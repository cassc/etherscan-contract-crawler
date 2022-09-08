// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../SYLToken/ISYLVestingWallet.sol";

contract SYLBankV1 is Initializable, PausableUpgradeable, AccessControlUpgradeable {
    bytes32 public constant DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");

    ERC20Burnable public erc20;
    ISYLVestingWallet public treasuryVested;
    mapping(address => uint256) public claimables;

    uint256 public burnAmount;
    uint256 public burnPercentage;

    struct Reward {
        address to;
        uint256 amount;
    }

    event Swap(address indexed _address, uint256 _amount);
    event Claim(address indexed _address, uint256 _amount);
    event Airdrop(address indexed _address, uint256 _amount);

    function initialize(
        address erc20Address,
        address vestedWalletAddress,
        uint256 amount,
        uint256 percentage
    ) public initializer {
        __Pausable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        erc20 = ERC20Burnable(erc20Address);
        treasuryVested = ISYLVestingWallet(vestedWalletAddress);

        burnAmount = amount;
        burnPercentage = percentage;
    }

    /**
     * @dev Swap function for exchanging SYLToken to karma point
     */
    function swap(uint256 amount) external whenNotPaused {
        erc20.transferFrom(msg.sender, address(this), amount);
        emit Swap(msg.sender, amount);
    }

    /**
     * @dev Claim function for user to claim its claimable
     */
    function claim() external whenNotPaused {
        uint256 claimable = claimables[msg.sender];
        require(claimable > 0, "Zero claimable");

        _beforeClaim(claimable);

        // release vesting wallet to update beneficiary balance
        treasuryVested.release();

        address treasury = treasuryVested.beneficiary();
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

    function _beforeClaim(uint256 claimable) private {
        if (_fixedBurnEnabled()) {
            erc20.burnFrom(msg.sender, burnAmount);
        }
        if (_percentageBurnEnabled()) {
            erc20.burnFrom(msg.sender, claimable * burnPercentage / 100);
        }
    }

    function _percentageBurnEnabled() private view returns (bool) {
        return burnPercentage != 0;
    }

    function _fixedBurnEnabled() private view returns (bool) {
        return burnAmount != 0;
    }

    /**
    * @dev Burn SYLToken
     */
    function burn(uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        erc20.burn(amount);
    }

    /**
     * @dev Emergency withdraw in case of migration
     */
    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        erc20.transfer(msg.sender, erc20.balanceOf(address(this)));
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function setBurnAmountPerClaim(uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        burnAmount = amount;
    }

    function setBurnPercentagePerClaim(uint256 percentage) external onlyRole(DEFAULT_ADMIN_ROLE) {
        burnPercentage = percentage;
    }
}