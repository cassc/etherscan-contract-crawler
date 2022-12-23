// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC4626} from "solmate/mixins/ERC4626.sol";
import {Owned} from "solmate/auth/Owned.sol";

import {ERC4626Factory} from "../../base/ERC4626Factory.sol";
import {IEulerEToken} from "../external/IEulerEToken.sol";
import {IEulerMarkets} from "../external/IEulerMarkets.sol";
import {IRewardsDistribution} from "../external/IRewardsDistribution.sol";
import {StakeableEulerERC4626} from "./StakeableEulerERC4626.sol";

/// @title EulerERC4626Factory
/// @author Sam Bugs
/// @notice Factory for creating EulerERC4626 contracts, that can handle staking
contract StakeableEulerERC4626Factory is ERC4626Factory, Owned {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    /// @notice Thrown when trying to deploy an EulerERC4626 vault using an asset without an eToken
    error StakeableEulerERC4626Factory__ETokenNonexistent();

    /// -----------------------------------------------------------------------
    /// Immutable params
    /// -----------------------------------------------------------------------

    /// @notice The Euler main contract address
    /// @dev Target of ERC20 approval when depositing
    address public immutable euler;

    /// @notice The Euler markets module address
    IEulerMarkets public immutable markets;

    /// @notice The rewards distribution address
    IRewardsDistribution public immutable rewardsDistribution;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(address euler_, IEulerMarkets markets_, IRewardsDistribution rewardsDistribution_, address owner_) Owned(owner_) {
        euler = euler_;
        markets = markets_;
        rewardsDistribution = rewardsDistribution_;
    }

    /// -----------------------------------------------------------------------
    /// Staking functions
    /// -----------------------------------------------------------------------

    /// @notice Returns how much was earned during staking
    function reward(StakeableEulerERC4626 vault) public view returns (address rewardsToken, uint256 earned) {
        return vault.reward();
    }

    /// @notice Allows owner to set or update a new staking contract. Will claim rewards from previous staking if available
    function updateStakingAddress(StakeableEulerERC4626 vault, uint256 rewardIndex, address recipient) external onlyOwner {
        vault.updateStakingAddress(rewardIndex, recipient);
    }

     /// @notice Allows owner to claim rewards and stop staking all together
    function stopStaking(StakeableEulerERC4626 vault, address recipient) external onlyOwner {
        vault.stopStaking(recipient);
    }

    /// @notice Allows owner to stake a certain amount of tokens
    function stake(StakeableEulerERC4626 vault, uint256 amount) external onlyOwner {
        vault.stake(amount);
    }

    /// @notice Allows owner to unstake a certain amount of tokens
    function unstake(StakeableEulerERC4626 vault, uint256 amount) external onlyOwner {
        vault.unstake(amount);
    }

    /// @notice Allows owner to claim all staking rewards
    function claimReward(StakeableEulerERC4626 vault, address recipient) public onlyOwner returns (address rewardsToken, uint256 earned) {
        return vault.claimReward(recipient);
    }

    /// -----------------------------------------------------------------------
    /// External functions
    /// -----------------------------------------------------------------------

    /// @inheritdoc ERC4626Factory
    function createERC4626(ERC20 asset) external virtual override returns (ERC4626 vault) {
        address eTokenAddress = markets.underlyingToEToken(address(asset));
        if (eTokenAddress == address(0)) {
            revert StakeableEulerERC4626Factory__ETokenNonexistent();
        }

        vault = new StakeableEulerERC4626{salt: bytes32(0)}(asset, euler, IEulerEToken(eTokenAddress), rewardsDistribution, address(this));

        emit CreateERC4626(asset, vault);
    }

    /// @inheritdoc ERC4626Factory
    function computeERC4626Address(ERC20 asset) external view virtual override returns (ERC4626 vault) {
        vault = ERC4626(
            _computeCreate2Address(
                keccak256(
                    abi.encodePacked(
                        // Deployment bytecode:
                        type(StakeableEulerERC4626).creationCode,
                        // Constructor arguments:
                        abi.encode(asset, euler, IEulerEToken(markets.underlyingToEToken(address(asset))), rewardsDistribution, address(this))
                    )
                )
            )
        );
    }
}