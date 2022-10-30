// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

interface IMebLpStake {
    function award(address token, uint256 amount) external;
}

interface IDonate {
    function queryDonatedList() external view returns (address[] memory);
}

contract MetaStakeDonate is AccessControlEnumerableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function initialize() external initializer {
        __ReentrancyGuard_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        stakeRate = 5e17;
        donateRate = 5e17;

        mai = 0x35803e77c3163FEd8A942536C1c8e0d5bF90f906;
        donate = 0x8DDeaD5dA29A08E35110eE0c216A85cBE2C65884;
        stake = 0x949Ea644969E3bb1b64BC519977146cBaf81bd7E;
    }

    uint128 public stakeRate;
    uint128 public donateRate;

    address public mai;
    address public donate;
    address public stake;

    uint256 public donateBalance;

    function setRate(uint128 newStakeRate, uint128 newDonateRate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        stakeRate = newStakeRate;
        donateRate = newDonateRate;
    }

    function recharge(uint256 amount) external nonReentrant {
        IERC20Upgradeable(mai).safeTransferFrom(msg.sender, address(this), amount);

        uint256 stakeBalance = (amount * stakeRate) / 1e18;
        IERC20Upgradeable(mai).approve(stake, stakeBalance);
        IMebLpStake(stake).award(mai, stakeBalance);

        donateBalance += (amount * donateRate) / 1e18;
    }

    function processDonate() external nonReentrant {
        require(donateBalance > 0, "Insufficient of DonateBalance");
        address[] memory donates = IDonate(donate).queryDonatedList();
        require(donates.length > 0, "Donate is empty");
        uint256 perDonate = donateBalance / donates.length;
        donateBalance = 0;
        for (uint256 i = 0; i < donates.length; i++) {
            IERC20Upgradeable(mai).safeTransfer(donates[i], perDonate);
        }
    }

    function settle(IERC20Upgradeable token, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        token.safeTransfer(msg.sender, amount);
    }
}