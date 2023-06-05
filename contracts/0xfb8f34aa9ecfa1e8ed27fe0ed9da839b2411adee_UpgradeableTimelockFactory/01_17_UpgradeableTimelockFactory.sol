// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./libs/@openzeppelin/contracts/access/Ownable.sol";
import "./libs/@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./libs/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./libs/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./proxy/IntellaXProxy.sol";
import "./interfaces/IOwnable.sol";

contract UpgradeableTimelockFactory is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    address public timelockOwner;

    address[] public ecosystems;

    mapping(address => bool) private _validAddress;

    event EcosystemTimelockCreated(address impl, address proxyAdmin, bytes callData);
    event Rescued(address token, uint256 amount);
    event TimelockOwnerChanged(address timelockOwner, address newTimelockOwner, address msgSender);

    constructor(IERC20 _token) Ownable() {
        require(address(_token) != address(0), "token address cannot be zero");
        token = _token;
    }

    function createEcosystemTimelock(
        address impl,
        address proxyAdmin,
        bytes memory callData
    ) external onlyOwner nonReentrant {
        require(timelockOwner != address(0), "timelock owner address must not be zero");
        address timelock = address(new IntellaXProxy(impl, proxyAdmin, callData));

        IOwnable(timelock).transferOwnership(timelockOwner);
        ecosystems.push(timelock);
        _validAddress[timelock] = true;

        emit EcosystemTimelockCreated(impl, proxyAdmin, callData);
    }

    function rescue(address targetToken) external onlyOwner nonReentrant {
        uint256 amount = IERC20(targetToken).balanceOf(address(this));
        if (amount > 0) {
            IERC20(targetToken).safeTransfer(owner(), amount);
            emit Rescued(targetToken, amount);
        }
    }

    function isValidAddress(address target) external view returns (bool) {
        return _validAddress[target];
    }

    function setTimelockOwner(address newTimelockOwner) external onlyOwner {
        require(newTimelockOwner != address(0), "timelock owner address must not be zero");

        emit TimelockOwnerChanged(timelockOwner, newTimelockOwner, msg.sender);
        timelockOwner = newTimelockOwner;
    }
}