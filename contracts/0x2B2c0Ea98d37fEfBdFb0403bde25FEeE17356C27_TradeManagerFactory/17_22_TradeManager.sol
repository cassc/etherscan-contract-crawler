// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { ERC20 } from "@solmate/tokens/ERC20.sol";
import { SafeTransferLib } from "@solmate/utils/SafeTransferLib.sol";
import { AutomationCompatibleInterface } from "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import { Owned } from "@solmate/auth/Owned.sol";
import { LinkTokenInterface } from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import { IKeeperRegistrar, RegistrationParams } from "src/interfaces/chainlink/IKeeperRegistrar.sol";
import { LimitOrderRegistry } from "src/LimitOrderRegistry.sol";
import { UniswapV3Pool } from "src/interfaces/uniswapV3/UniswapV3Pool.sol";

/**
 * @title Trade Manager
 * @notice Automates claiming limit orders for the LimitOrderRegistry.
 * @author crispymangoes
 * @dev Future improvements.
 *      - could add logic into the LOR that checks if the caller is a users TradeManager, and if so that allows the caller to
 *        create/edit orders on behalf of the user.
 *      - add some bool that dictates where assets go, like on claim should assets be returned here, or to the owner
 *      - Could allow users to funds their upkeep through this contract, which would interact with pegswap if needed.
 */
contract TradeManager is Initializable, AutomationCompatibleInterface, Owned {
    using SafeTransferLib for ERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    /*//////////////////////////////////////////////////////////////
                             STRUCTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Stores information used to claim orders in `performUpkeep`.
     * @param batchId The order batch id to claim
     * @param fee The Native fee required to claim the order
     */
    struct ClaimInfo {
        uint128 batchId;
        uint128 fee;
    }

    /*//////////////////////////////////////////////////////////////
                             GLOBAL STATE
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Set of batch IDs that the owner currently has orders in.
     */
    EnumerableSet.UintSet private ownerOrders;

    /**
     * @notice The limit order registry contract this trade manager interacts with.
     */
    LimitOrderRegistry public limitOrderRegistry;

    /**
     * @notice The gas limit used when the Trade Managers upkeep is created.
     */
    uint32 public constant UPKEEP_GAS_LIMIT = 500_000;

    /**
     * @notice The max amount of claims that can happen in a single upkeep.
     */
    uint256 public constant MAX_CLAIMS = 10;

    /**
     * @notice Allows owner to specify whether they want claimed tokens to be left
     *         in the TradeManager, or sent to their address.
     *         -true send tokens to their address
     *         -false leave tokens in the trade manager
     */
    bool public claimToOwner;

    constructor() Owned(address(0)) {}

    /*//////////////////////////////////////////////////////////////
                            INITIALIZE LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initialize function to setup this contract.
     * @param user The owner of this contract
     * @param _limitOrderRegistry The limit order registry this contract interacts with
     * @param LINK The Chainlink token needed to create an upkeep
     * @param registrar The Chainlink Automation Registrar contract
     * @param initialUpkeepFunds Amount of link to fund the upkeep with
     */
    function initialize(
        address user,
        LimitOrderRegistry _limitOrderRegistry,
        LinkTokenInterface LINK,
        IKeeperRegistrar registrar,
        uint256 initialUpkeepFunds
    ) external initializer {
        owner = user;
        limitOrderRegistry = _limitOrderRegistry;

        // Create a new upkeep.
        if (initialUpkeepFunds > 0) {
            ERC20(address(LINK)).safeTransferFrom(msg.sender, address(this), initialUpkeepFunds);
            ERC20(address(LINK)).safeApprove(address(registrar), initialUpkeepFunds);
            RegistrationParams memory params = RegistrationParams({
                name: "Trade Manager",
                encryptedEmail: abi.encode(0),
                upkeepContract: address(this),
                gasLimit: UPKEEP_GAS_LIMIT,
                adminAddress: user,
                checkData: abi.encode(0),
                offchainConfig: abi.encode(0),
                amount: uint96(initialUpkeepFunds)
            });
            registrar.registerUpkeep(params);
        }
    }

    /*//////////////////////////////////////////////////////////////
                              OWNER LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows owner to adjust `claimToOwner`.
     */
    function setClaimToOwner(bool state) external onlyOwner {
        claimToOwner = state;
    }

    /**
     * @notice See `LimitOrderRegistry.sol:newOrder`.
     */
    function newOrder(
        UniswapV3Pool pool,
        ERC20 assetIn,
        int24 targetTick,
        uint128 amount,
        bool direction,
        uint256 startingNode
    ) external onlyOwner {
        uint256 managerBalance = assetIn.balanceOf(address(this));
        // If manager lacks funds, transfer delta into manager.
        if (managerBalance < amount) assetIn.safeTransferFrom(msg.sender, address(this), amount - managerBalance);

        assetIn.safeApprove(address(limitOrderRegistry), amount);
        uint128 batchId = limitOrderRegistry.newOrder(pool, targetTick, amount, direction, startingNode);
        ownerOrders.add(batchId);
    }

    /**
     * @notice See `LimitOrderRegistry.sol:cancelOrder`.
     */
    function cancelOrder(UniswapV3Pool pool, int24 targetTick, bool direction) external onlyOwner {
        (uint128 amount0, uint128 amount1, uint128 batchId) = limitOrderRegistry.cancelOrder(
            pool,
            targetTick,
            direction
        );
        if (amount0 > 0) ERC20(pool.token0()).safeTransfer(owner, amount0);
        if (amount1 > 0) ERC20(pool.token1()).safeTransfer(owner, amount1);

        ownerOrders.remove(batchId);
    }

    /**
     * @notice See `LimitOrderRegistry.sol:claimOrder`.
     */
    function claimOrder(uint128 batchId) external onlyOwner {
        uint256 value = limitOrderRegistry.getFeePerUser(batchId);
        limitOrderRegistry.claimOrder{ value: value }(batchId, address(this));

        ownerOrders.remove(batchId);
    }

    /**
     @notice Allows owner to withdraw Native asset from this contract.
     */
    function withdrawNative(uint256 amount) external onlyOwner {
        payable(owner).transfer(amount);
    }

    /**
     * @notice Allows owner to withdraw any ERC20 from this contract.
     */
    function withdrawERC20(ERC20 token, uint256 amount) external onlyOwner {
        token.safeTransfer(owner, amount);
    }

    receive() external payable {}

    /*//////////////////////////////////////////////////////////////
                     CHAINLINK AUTOMATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Iterates through `ownerOrders` and stops early if total fee is greater than this contract native balance, or if max claims is met.
     */
    function checkUpkeep(bytes calldata) external view returns (bool upkeepNeeded, bytes memory performData) {
        uint256 nativeBalance = address(this).balance;
        // Iterate through owner orders, and build a claim array.

        uint256 count = ownerOrders.length();
        ClaimInfo[MAX_CLAIMS] memory claimInfo;
        uint256 claimCount;
        for (uint256 i; i < count; ++i) {
            uint128 batchId = uint128(ownerOrders.at(i));
            // Current order is not fulfilled.
            if (!limitOrderRegistry.isOrderReadyForClaim(batchId)) continue;
            uint128 fee = limitOrderRegistry.getFeePerUser(batchId);
            // Break if manager does not have enough native to pay for claim.
            if (fee > nativeBalance) break;
            // Subtract fee from balance.
            nativeBalance -= fee;
            claimInfo[claimCount].batchId = batchId;
            claimInfo[claimCount].fee = fee;
            claimCount++;
            // Break if max claims is reached.
            if (claimCount == MAX_CLAIMS) break;
        }

        if (claimCount > 0) {
            upkeepNeeded = true;
            performData = abi.encode(claimInfo);
        }
        // else nothing to do.
    }

    /**
     * @notice Accepts array of ClaimInfo.
     * @dev Passing in incorrect fee values will at worst cost the caller excess gas.
     *      If fee is too large, excess is returned, or LimitOrderRegistry reverts when it tries to transfer Wrapped Native.
     *      If fee is too small LimitOrderRegistry reverts when it tries to transfer Wrapped Native.
     */
    function performUpkeep(bytes calldata performData) external {
        // Accept claim array and claim all orders
        ClaimInfo[MAX_CLAIMS] memory claimInfo = abi.decode(performData, (ClaimInfo[10]));
        for (uint256 i; i < 10; ++i) {
            if (limitOrderRegistry.isOrderReadyForClaim(claimInfo[i].batchId)) {
                (ERC20 asset, uint256 assets) = limitOrderRegistry.claimOrder{ value: claimInfo[i].fee }(
                    claimInfo[i].batchId,
                    address(this)
                );
                ownerOrders.remove(claimInfo[i].batchId);
                if (claimToOwner) asset.safeTransfer(owner, assets);
            }
        }
    }

    function getOwnerBatchIds() external view returns (uint256[] memory ids) {
        ids = new uint256[](ownerOrders.length());
        for (uint256 i; i < ids.length; ++i) ids[i] = ownerOrders.at(i);
    }
}