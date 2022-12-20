// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

interface IExt {
    function award(address token, uint256 amount) external;
}

contract LpStakeAllot is AccessControlUpgradeable, UUPSUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address usdtMebLp;
    address musdMebLp;

    address usdtMebLpStake;
    address musdMebLpStake;

    function initialize() external initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function award(address token, uint256 amount) external {
        IERC20Upgradeable(token).safeTransferFrom(msg.sender, address(this), amount);

        uint256 usdtMebLpStakeAmount = IERC20Upgradeable(usdtMebLp).balanceOf(usdtMebLpStake);
        uint256 musdMebLpStakeAmount = IERC20Upgradeable(musdMebLp).balanceOf(musdMebLpStake);

        uint256 usdtMebLpStakeAllot = (amount * usdtMebLpStakeAmount) / (usdtMebLpStakeAmount + musdMebLpStakeAmount);
        uint256 musdMebLpStakeAllot = amount - usdtMebLpStakeAllot;

        IERC20Upgradeable(token).safeApprove(usdtMebLpStake, usdtMebLpStakeAllot);
        IExt(usdtMebLpStake).award(token, usdtMebLpStakeAllot);

        IERC20Upgradeable(token).safeApprove(musdMebLpStake, musdMebLpStakeAllot);
        IExt(musdMebLpStake).award(token, musdMebLpStakeAllot);
    }

    function setUsdtMebLp(address newUsdtMebLp) external onlyRole(DEFAULT_ADMIN_ROLE) {
        usdtMebLp = newUsdtMebLp;
    }

    function setMusdMebLp(address newMusdMebLp) external onlyRole(DEFAULT_ADMIN_ROLE) {
        musdMebLp = newMusdMebLp;
    }

    function setUsdtMebLpStake(address newUsdtMebLpStake) external onlyRole(DEFAULT_ADMIN_ROLE) {
        usdtMebLpStake = newUsdtMebLpStake;
    }

    function setMusdMebLpStake(address newMusdMebLpStake) external onlyRole(DEFAULT_ADMIN_ROLE) {
        musdMebLpStake = newMusdMebLpStake;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}