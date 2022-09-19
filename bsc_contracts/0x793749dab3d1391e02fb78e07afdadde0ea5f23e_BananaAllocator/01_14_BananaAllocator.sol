// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./lib/IMasterApe.sol";
import "./lib/IAnyswapV4Router.sol";
import "./utils/SweeperUpgradeable.sol";

contract BananaAllocator is SweeperUpgradeable {
    IMasterApe public masterApe;
    IERC20 public bananaAddress;
    IAnyswapV4Router public anyswapRouter;
    uint256 public bananaRoutesLength;

    struct BananaRoute {
        address toAddress;
        ActionId actionId;
        uint256 chainId;
        uint256 minimumBanana;
    }

    enum ActionId {
        SIMPLE,
        BRIDGE
    }

    mapping(uint256 => BananaRoute) public getBananaRouteFromPid;
    uint256[] public bananaRoutePids;

    event MovedBanana(uint256 pid, uint256 amount, address to, uint256 chainId);
    event AddedBananaRoute(
        uint256 farmPid,
        address toAddress,
        ActionId actionId,
        uint256 chainId,
        uint256 minimumBanana
    );
    event RemovedBananaRoute(uint256 index, uint256 pid);
    event ChangedBananaMinimum(uint256 pid, uint256 newMinimum);

    function initialize(
        IMasterApe _masterApe,
        IERC20 _bananaAddress,
        IAnyswapV4Router _anyswapRouter
    ) public initializer {
        initializeSweeper(new address[](0), true);
        masterApe = _masterApe;
        bananaAddress = _bananaAddress;
        anyswapRouter = _anyswapRouter;
    }

    /// @notice Move banana based on index
    /// @param index index of banana route to move banana
    function moveBananaIndex(uint256 index) external {
        require(index < bananaRoutesLength, "BananaAllocator: Index out of bounds");
        _moveBanana(bananaRoutePids[index], true);
    }

    /// @notice Move banana for all banana routes
    /// @param revert_ revert if one fails
    function moveBananaAll(bool revert_) external {
        for (uint256 index = 0; index < bananaRoutesLength; index++) {
            _moveBanana(bananaRoutePids[index], revert_);
        }
    }

    /// @notice Move banana based on farm pid
    /// @param pid farm pid of banana route to move banana
    function moveBananaPid(uint256 pid) external {
        _moveBanana(pid, true);
    }

    /// @notice Move banana based on multiple farm pids
    /// @param pids farm pids of banana route to move banana
    /// @param revert_ revert if one fails
    function moveBananaPids(uint256[] memory pids, bool revert_) external {
        for (uint256 index = 0; index < pids.length; index++) {
            _moveBanana(pids[index], revert_);
        }
    }

    function _moveBanana(uint256 pid, bool revert_) private {
        BananaRoute memory bananaRoute = getBananaRouteFromPid[pid];

        if (bananaRoute.toAddress != address(0)) {
            if (revert_) {
                revert("BananaAllocator: No configured route found");
            } else {
                return;
            }
        }

        uint256 pendingRewards = masterApe.pendingCake(pid, address(this));
        if (pendingRewards < bananaRoute.minimumBanana) {
            if (revert_) {
                revert("BananaAllocator: not enough rewards");
            } else {
                return;
            }
        }

        uint256 balanceBefore = bananaAddress.balanceOf(address(this));
        masterApe.deposit(pid, 0);
        uint256 newTokens = bananaAddress.balanceOf(address(this)) - balanceBefore;

        if (bananaRoute.actionId == ActionId.SIMPLE) {
            //Simple transfer on same chain
            bananaAddress.transfer(bananaRoute.toAddress, newTokens);
        } else if (bananaRoute.actionId == ActionId.BRIDGE) {
            //anyswap/multichain bridging to different address
            anyswapRouter.anySwapOutUnderlying(
                address(bananaAddress),
                bananaRoute.toAddress,
                newTokens,
                bananaRoute.chainId
            );
        }
        emit MovedBanana(pid, newTokens, bananaRoute.toAddress, bananaRoute.chainId);
    }

    /// @notice Add a banana route
    /// @param farmPid farm pid
    /// @param toAddress address the banana should transfer to
    /// @param actionId action id
    /// @param chainId chain id for cross chain banana transfers
    /// @param minimumBanana minimum banana collected to activate banana transfer
    function addBananaRoute(
        uint256 farmPid,
        address toAddress,
        ActionId actionId,
        uint256 chainId,
        uint256 minimumBanana
    ) external onlyOwner {
        if (actionId == ActionId.BRIDGE)
            require(chainId != 0 && chainId != block.chainid, "BananaAllocator: wrong settings");

        bananaRoutesLength++;
        require(toAddress != address(0), "BananaAllocator: Can't send to null address");
        BananaRoute memory tempRoute = getBananaRouteFromPid[farmPid];
        require(tempRoute.toAddress == address(0), "BananaAllocator: Banana route with this pid already exists");

        getBananaRouteFromPid[farmPid] = BananaRoute(toAddress, actionId, chainId, minimumBanana);
        bananaRoutePids.push(farmPid);
        emit AddedBananaRoute(farmPid, toAddress, actionId, chainId, minimumBanana);
    }

    /// @notice remove a banana route by pid
    /// @param pid pid of banana route to remove
    function removeBananaRoutePid(uint256 pid) external onlyOwner {
        uint256 index = type(uint256).max;

        for (uint256 i = 0; i < bananaRoutePids.length; i++) {
            uint256 _pid = bananaRoutePids[i];
            if (_pid == pid) {
                index = i;
                continue;
            }
        }
        require(index != type(uint256).max, "BananaAllocator: pid not found");

        bananaRoutePids[index] = bananaRoutePids[bananaRoutesLength - 1];
        bananaRoutePids.pop();
        delete getBananaRouteFromPid[pid];
        bananaRoutesLength--;
        emit RemovedBananaRoute(index, pid);
    }

    /// @notice stake into masterApe farm
    /// @param pid pid of farm to stake in
    function stakeFarm(uint256 pid) external onlyOwner {
        (address farmToken, , , ) = masterApe.getPoolInfo(pid);
        uint256 balance = IERC20(farmToken).balanceOf(address(this));
        require(balance > 0, "BananaAllocator: no tokens to stake");
        IERC20(farmToken).approve(address(masterApe), balance);
        masterApe.deposit(pid, balance);
    }

    /// @notice unstake from masterApe farm
    /// @param pid pid of farm to unstake from
    function unstakeFarm(uint256 pid) external onlyOwner {
        (uint256 balance, ) = masterApe.userInfo(pid, address(this));
        masterApe.withdraw(pid, balance);
    }

    /// @notice emergency unstake from masterApe farm
    /// @param pid pid of farm to unstake from
    function emergencyUnstakeFarm(uint256 pid) external onlyOwner {
        masterApe.emergencyWithdraw(pid);
    }

    /// @notice Change the minimum banana that needs to be collected to active banana transfer
    /// @param pid pid of farm
    /// @param newMinimum new banana minimum
    function changeMinimumBanana(uint256 pid, uint256 newMinimum) external onlyOwner {
        BananaRoute storage bananaRoute = getBananaRouteFromPid[pid];
        bananaRoute.minimumBanana = newMinimum;
        emit ChangedBananaMinimum(pid, newMinimum);
    }
}