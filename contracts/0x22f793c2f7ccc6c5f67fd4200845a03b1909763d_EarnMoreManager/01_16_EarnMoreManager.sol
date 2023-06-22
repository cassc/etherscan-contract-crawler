// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IEarnMoreManager.sol";

contract EarnMoreManager is Ownable, IEarnMoreManager {
    using SafeERC20 for IERC20;

    struct EarnMoreParams {
        address vault;
        address underlyingUniPool;
        address balanceCalculator;
    }

    address constant choAddress = 0xBBa39Fd2935d5769116ce38d46a71bde9cf03099;
    address constant choUniPool = 0x2cb162433E0caBAc4825E6d198a125829156cC92;

    address public treasury;

    address public proxyAdmin;
    address public earnMoreImplementation;

    uint256 public excludePercent;
    uint256 public earnMorePercent;

    uint256 public maxVeMultiplier;
    uint256 public maxVePortion;

    mapping(address => address) public vaultToEarnMore;
    mapping(address => bool) public whitelistedEarnMore;

    event AddRewards(uint256 amount);
    event RewardsRescued(uint256 amount);
    event NewTreasuty(address newValue);
    event NewExcludePercent(uint256 newValue);
    event NewEarnMorePercent(uint256 newValue);
    event NewMaxVeMultiplier(uint256 newValue);
    event NewMaxVePortion(uint256 newValue);
    event NewProxyAdmin(address newValue);
    event NewEarnMoreImplementation(address newValue);
    event NewEarnMore(address indexed vault, address indexed earnMore);
    event RemoveEarnMore(address indexed vault, address indexed earnMore);
    event RewardTransfered(
        address indexed earnMore,
        address indexed recepient,
        uint256 amount
    );

    modifier isWhitelistedEarnMore() {
        require(
            whitelistedEarnMore[msg.sender],
            "EarnMore contract is not whitelisted"
        );
        _;
    }

    constructor(
        address _treasury,
        uint256 _excludePercent,
        uint256 _earnMorePercent,
        uint256 _maxVeMultiplier,
        uint256 _maxVePortion,
        address _earnMoreImplementation,
        address _proxyAdmin,
        EarnMoreParams[] memory initialEarnMores
    ) {
        _setTreasury(_treasury);
        _setExcludedPercent(_excludePercent);
        _setEarnMorePercent(_earnMorePercent);
        _setProxyAdmin(_proxyAdmin);
        _setMaxVeMultiplier(_maxVeMultiplier);
        _setMaxVePortion(_maxVePortion);
        _setEarnMoreImplementation(_earnMoreImplementation);

        for (uint256 i = 0; i < initialEarnMores.length; i++) {
            addEarnMore(initialEarnMores[i]);
        }
    }

    function addRewards(uint256 amount) external {
        IERC20(choAddress).safeTransferFrom(msg.sender, address(this), amount);

        emit AddRewards(amount);
    }

    function rescueRewards(uint256 amount) external onlyOwner {
        IERC20(choAddress).safeTransfer(msg.sender, amount);

        emit RewardsRescued(amount);
    }

    /// Deploy EarnMoreProxy contract
    function addEarnMore(
        EarnMoreParams memory earnMoreParams
    ) public onlyOwner {
        require(
            vaultToEarnMore[earnMoreParams.vault] == address(0),
            "EarnMore for this address already exists"
        );
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            earnMoreImplementation,
            proxyAdmin,
            buildInitCalldata(earnMoreParams)
        ); // Unwrap params

        vaultToEarnMore[earnMoreParams.vault] = address(proxy);
        whitelistedEarnMore[address(proxy)] = true;

        emit NewEarnMore(earnMoreParams.vault, address(proxy));
    }

    function removeEarnMore(address vault) external onlyOwner {
        address earnMore = vaultToEarnMore[vault];
        whitelistedEarnMore[earnMore] = false;
        vaultToEarnMore[vault] = address(0);

        emit RemoveEarnMore(vault, earnMore);
    }

    function transferReward(
        address to,
        uint256 amount
    ) external isWhitelistedEarnMore returns (bool) {
        if (IERC20(choAddress).balanceOf(address(this)) >= amount) {
            if (amount > 0) {
                IERC20(choAddress).safeTransfer(to, amount);
            }

            emit RewardTransfered(msg.sender, to, amount);

            return true;
        }

        return false;
    }

    function getPercentEarnMoreInfo() external view returns (uint256, uint256) {
        return (excludePercent, earnMorePercent);
    }

    function getVeInfo() external view returns (uint256, uint256) {
        return (maxVePortion, maxVeMultiplier);
    }

    function setTreasury(address newValue) external onlyOwner {
        _setTreasury(newValue);
    }

    function setExcludedPercent(uint256 newValue) external onlyOwner {
        _setExcludedPercent(newValue);
    }

    function setEarnMorePercent(uint256 newValue) external onlyOwner {
        _setEarnMorePercent(newValue);
    }

    function setMaxVeMultiplier(uint256 newValue) external onlyOwner {
        _setMaxVeMultiplier(newValue);
    }

    function setMaxVePortion(uint256 newValue) external onlyOwner {
        _setMaxVePortion(newValue);
    }

    function _setTreasury(address newValue) internal {
        treasury = newValue;
        emit NewTreasuty(newValue);
    }

    function _setExcludedPercent(uint256 newValue) internal {
        excludePercent = newValue;
        emit NewExcludePercent(newValue);
    }

    function _setEarnMorePercent(uint256 newValue) internal {
        earnMorePercent = newValue;
        emit NewEarnMorePercent(newValue);
    }

    function _setMaxVeMultiplier(uint256 newValue) internal {
        maxVeMultiplier = newValue;
        emit NewMaxVeMultiplier(newValue);
    }

    function _setMaxVePortion(uint256 newValue) internal {
        maxVePortion = newValue;
        emit NewMaxVePortion(newValue);
    }

    function _setProxyAdmin(address newValue) internal {
        proxyAdmin = newValue;
        emit NewProxyAdmin(newValue);
    }

    function _setEarnMoreImplementation(address newValue) internal {
        earnMoreImplementation = newValue;
        emit NewEarnMoreImplementation(newValue);
    }

    function buildInitCalldata(
        EarnMoreParams memory earnMoreParams
    ) public view returns (bytes memory) {
        return
            abi.encodeWithSignature(
                "initialize(address,address,address,address,address)",
                earnMoreParams.vault,
                choUniPool,
                earnMoreParams.underlyingUniPool,
                earnMoreParams.balanceCalculator,
                msg.sender
            );
    }
}