// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {INonfungiblePositionManager} from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import {IUniswapFeeCollector} from "./interfaces/IUniswapFeeCollector.sol";

contract UniswapFeeCollector is IUniswapFeeCollector {
    IERC20 public immutable baseToken;
    IERC20 public immutable rewardToken;
    INonfungiblePositionManager public immutable positionManager;

    address public immutable uniswapSwapRouterAddress;
    address public owner;
    address public runner;
    address public rewardCollectionAddress;
    uint256 private locked = 1; // Used in reentrancy check.

    constructor(
        address runnerAddress_,
        address rewardCollectionAddress_,
        address rewardTokenAddress_,
        address baseTokenAddress_,
        address uniswapSwapRouterAddress_,
        address positionManagerAddress_
    ) {
        rewardToken = IERC20(rewardTokenAddress_);
        baseToken = IERC20(baseTokenAddress_);
        positionManager = INonfungiblePositionManager(positionManagerAddress_);

        runner = runnerAddress_;
        rewardCollectionAddress = rewardCollectionAddress_;
        uniswapSwapRouterAddress = uniswapSwapRouterAddress_;

        owner = msg.sender;
    }

    /*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░                             Modifiers                             ░░░░
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

    modifier nonReentrant() {
        require(locked == 1, "UFC:LOCKED");

        locked = 2;

        _;

        locked = 1;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "UFC:CALLER_NOT_OWNER");
        _;
    }

    modifier onlyRunner() {
        require(msg.sender == runner, "UFC:CALLER_NOT_RUNNER");
        _;
    }

    /*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░                         Public Functions                          ░░░░
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

    /**
     * @inheritdoc IUniswapFeeCollector
     */
    function onERC721Received(address, address, uint256, bytes calldata) external virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @inheritdoc IUniswapFeeCollector
     */
    function collectFees(uint256 tokenId_)
        external
        override
        nonReentrant
        returns (uint256 amount0_, uint256 amount1_)
    {
        (amount0_, amount1_) = _collectFees(tokenId_);
        _sendRewards();
    }

    /**
     * @inheritdoc IUniswapFeeCollector
     */
    function collectFeesAndIncreaseLiquidity(uint256 tokenId_, bytes calldata data_)
        external
        override
        onlyRunner
        nonReentrant
    {
        _collectFees(tokenId_);
        _sendRewards();
        _increaseLiquidity(tokenId_, data_);
    }

    /**
     * @inheritdoc IUniswapFeeCollector
     */
    function increaseLiquidity(uint256 tokenId_, bytes calldata data_) external override onlyRunner nonReentrant {
        _increaseLiquidity(tokenId_, data_);
    }

    /**
     * @inheritdoc IUniswapFeeCollector
     */
    function withdrawPosition(uint256 tokenId_) external override onlyOwner nonReentrant {
        positionManager.transferFrom(address(this), owner, tokenId_);

        emit PositionWithdrawn(tokenId_);
    }

    /**
     * @inheritdoc IUniswapFeeCollector
     */
    function setRewardCollectionAddress(address rewardCollectionAddress_) external override onlyOwner {
        rewardCollectionAddress = rewardCollectionAddress_;

        emit RewardCollectionAddressChanged(rewardCollectionAddress);
    }

    /**
     * @inheritdoc IUniswapFeeCollector
     */
    function setRunnerAddress(address runnerAddress_) external override onlyOwner {
        runner = runnerAddress_;

        emit RunnerAddressChanged(runner);
    }

    /**
     * @inheritdoc IUniswapFeeCollector
     */
    function transferOwnership(address owner_) external override onlyOwner {
        require(owner_ != address(0), "UFC:ZERO_ADDRESS_CANNOT_BE_OWNER");
        _transferOwnership(owner_);
    }

    /*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░                        Internal Functions                         ░░░░
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

    /**
     * @notice Collects accrued fees from position, leaving them on the contract.
     * @param  tokenId_ Uniswap Non-Fungible Position Manager token ID representing LP position.
     * @return amount0_ Amount of tokens collected for first token in pool.
     * @return amount1_ Amount of tokens collected for second token in pool.
     */
    function _collectFees(uint256 tokenId_) internal returns (uint256 amount0_, uint256 amount1_) {
        INonfungiblePositionManager.CollectParams memory params_ = INonfungiblePositionManager.CollectParams({
            tokenId: tokenId_,
            recipient: address(this),
            amount0Max: type(uint128).max,
            amount1Max: type(uint128).max
        });

        (amount0_, amount1_) = positionManager.collect(params_);

        emit CollectFees(tokenId_, amount0_, amount1_);
    }

    /**
     * @notice Increses the liquidity of the position using the fees on the contract.
     * @param  tokenId_ Uniswap Non-Fungible Position Manager token ID representing LP position.
     * @param  data_ Calldata required to perform the swap & increase, generated by the Uniswap SDK.
     */
    function _increaseLiquidity(uint256 tokenId_, bytes calldata data_) internal {
        uint256 baseTokenBalance_ = baseToken.balanceOf(address(this));

        baseToken.approve(uniswapSwapRouterAddress, baseTokenBalance_);
        (bool success_,) = uniswapSwapRouterAddress.call{value: 0}(data_);
        baseToken.approve(uniswapSwapRouterAddress, 0);

        require(success_ == true, "UFC:UNISWAP_CALL_FAILED");

        emit IncreaseLiquidity(tokenId_, baseTokenBalance_ - baseToken.balanceOf(address(this)));
    }

    /**
     * @notice Transfers all reward tokens held by the contract to the rewardCollectionAddress.
     */
    function _sendRewards() internal {
        uint256 rewardTokenBalance_ = rewardToken.balanceOf(address(this));
        rewardToken.transfer(rewardCollectionAddress, rewardTokenBalance_);

        emit SendRewards(rewardCollectionAddress, rewardTokenBalance_);
    }

    /**
     * @notice Transfers ownership of the contract to a new account.
     * @param  owner_ New owner of the contract.
     */
    function _transferOwnership(address owner_) internal {
        address oldOwner_ = owner;
        owner = owner_;

        emit OwnershipTransferred(oldOwner_, owner_);
    }
}