// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./../utils/LogicUpgradeable.sol";
import "./../Interfaces/ISwap.sol";

contract LendBorrowFarmingPair is LogicUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct FarmingPair {
        address tokenA;
        address tokenB;
        address xTokenA;
        address xTokenB;
        address swap;
        address swapMaster;
        address lpToken;
        uint256 poolID;
        address rewardsToken;
        address[][] path;
        address[] pathTokenA2BNB;
        address[] pathTokenB2BNB;
        address[] pathRewards2BNB;
        uint256 percentage;
    }

    FarmingPair[] farmingPairs;
    address strategy;

    event SetStrategy(address strategy);

    function __LendBorrowFarmingPair_init() public initializer {
        LogicUpgradeable.initialize();
    }

    receive() external payable {}

    fallback() external payable {}

    modifier onlyStrategy() {
        require(msg.sender == strategy, "F20");
        _;
    }

    /**
     * @notice Set Strategy
     * @param _strategy Address of LendBorrowFarmStrategy Contract
     */
    function setStrategy(address _strategy) external onlyOwner {
        require(strategy == address(0), "F19");
        strategy = _strategy;

        emit SetStrategy(_strategy);
    }

    /**
     * @notice Set the dividing percentage
     * @param _percentages percentage array
     */
    function setPercentages(uint256[] calldata _percentages)
        external
        onlyOwnerAndAdmin
    {
        uint256 _count = _percentages.length;
        uint256 sum = 0;

        require(_count == farmingPairs.length, "F9");

        for (uint256 index = 0; index < _count; ) {
            sum += _percentages[index];
            farmingPairs[index].percentage = _percentages[index];
            unchecked {
                ++index;
            }
        }

        require(sum == 10000, "F10");
    }

    /**
     * @notice Set farmingPairs
     * @param _farmingPairs Array of farming pairs
     */
    function setFarmingPairs(FarmingPair[] calldata _farmingPairs)
        external
        onlyOwnerAndAdmin
    {
        uint256 length = _farmingPairs.length;
        delete farmingPairs;

        for (uint256 i = 0; i < length; ) {
            require(_farmingPairs[i].tokenA != address(0), "F12");

            farmingPairs.push(_farmingPairs[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Get farmingPairs
     */
    function getFarmingPairs() external view returns (FarmingPair[] memory) {
        return farmingPairs;
    }

    /**
     * @notice Delete farmingPairs with bulk
     * @param indexesToDelete Array of index to be deleted, it should be sorted with ASC
     */
    function deleteFarmingPairList(uint256[] calldata indexesToDelete)
        external
        onlyOwnerAndAdmin
    {
        uint256 lengthIndexesToDelete = indexesToDelete.length;
        uint256 lengthFarmingPairs = farmingPairs.length;

        require(lengthIndexesToDelete <= lengthFarmingPairs, "F7");

        uint256 lastDeletedIndex = lengthFarmingPairs;
        for (uint256 index = 0; index < lengthIndexesToDelete; ) {
            uint256 indexToDelete = indexesToDelete[
                lengthIndexesToDelete - index - 1
            ];
            require(indexToDelete < lastDeletedIndex, "F8");

            farmingPairs[indexToDelete] = farmingPairs[lengthFarmingPairs - 1];
            farmingPairs.pop();

            lengthFarmingPairs--;
            lastDeletedIndex = indexToDelete;

            unchecked {
                ++index;
            }
        }
    }

    /* Strategy Functions */

    /**
     * @notice Convert Lp Token To Token
     */
    function getPriceFromLpToToken(
        address lpToken,
        uint256 value,
        address token,
        address swap,
        address[] memory path
    ) external view onlyStrategy returns (uint256) {
        //make price returned not affected by slippage rate
        uint256 totalSupply = IERC20Upgradeable(lpToken).totalSupply();
        address token0 = IPancakePair(lpToken).token0();
        uint256 totalTokenAmount = IERC20Upgradeable(token0).balanceOf(
            lpToken
        ) * (2);
        uint256 amountIn = (value * totalTokenAmount) / (totalSupply);

        if (amountIn == 0 || token0 == token) {
            return amountIn;
        }

        uint256[] memory price = IPancakeRouter01(swap).getAmountsOut(
            amountIn,
            path
        );
        return price[price.length - 1];
    }

    /**
     * @notice Convert Token To Lp Token
     */
    function getPriceFromTokenToLp(
        address lpToken,
        uint256 value,
        address token,
        address swap,
        address[] memory path
    ) external view onlyStrategy returns (uint256) {
        //make price returned not affected by slippage rate
        uint256 totalSupply = IERC20Upgradeable(lpToken).totalSupply();
        address token0 = IPancakePair(lpToken).token0();
        uint256 totalTokenAmount = IERC20Upgradeable(token0).balanceOf(lpToken);

        if (token0 == token) {
            return (value * (totalSupply)) / (totalTokenAmount) / 2;
        }

        uint256[] memory price = IPancakeRouter01(swap).getAmountsOut(
            (1 gwei),
            path
        );
        return
            (value * (totalSupply)) /
            ((price[price.length - 1] * 2 * totalTokenAmount) / (1 gwei));
    }

    /**
     * @notice Check pair percentages are valid in farming Pair
     */
    function checkPercentages() external view {
        uint256 _count = farmingPairs.length;
        uint256 sum = 0;

        for (uint256 index = 0; index < _count; ) {
            sum += farmingPairs[index].percentage;
            unchecked {
                ++index;
            }
        }

        require(sum == 10000, "F10");
    }

    /**
     * @notice FindPath for swap router
     */
    function findPath(uint256 id, address token)
        external
        view
        onlyStrategy
        returns (address[] memory path)
    {
        FarmingPair memory reserve = farmingPairs[id];
        uint256 length = reserve.path.length;

        for (uint256 i = 0; i < length; ) {
            if (reserve.path[i][reserve.path[i].length - 1] == token) {
                return reserve.path[i];
            }
            unchecked {
                ++i;
            }
        }
    }
}