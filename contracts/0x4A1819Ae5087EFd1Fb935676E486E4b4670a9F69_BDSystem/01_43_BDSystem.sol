// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./libraries/ErrorCodes.sol";
import "./interfaces/IBDSystem.sol";
import "./interfaces/ISupervisor.sol";
import "./interfaces/IMnt.sol";
import "./InterconnectorLeaf.sol";

contract BDSystem is IBDSystem, Initializable, AccessControl, InterconnectorLeaf {
    using SafeERC20Upgradeable for IMnt;

    struct Agreement {
        /// Emission boost for liquidity provider
        uint256 liquidityProviderBoost;
        /// Percentage of the total emissions earned by the representative
        uint256 representativeBonus;
        /// The number of the block in which agreement ends.
        uint32 endBlock;
        /// Business Development Representative
        address representative;
    }

    uint256 internal constant EXP_SCALE = 1e18;

    /// Linking the liquidity provider with the agreement
    mapping(address => Agreement) public providerToAgreement;
    /// Counts liquidity providers of the representative
    mapping(address => uint256) public representativesProviderCounter;

    constructor() {
        _disableInitializers();
    }

    function initialize(address admin_) external initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
    }

    /*** Admin functions ***/

    /// @inheritdoc IBDSystem
    function createAgreement(
        address liquidityProvider_,
        address representative_,
        uint256 representativeBonus_,
        uint256 liquidityProviderBoost_,
        uint32 endBlock_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // (1 + liquidityProviderBoost) * (1 + representativeBonus) <= 150%
        require(
            (EXP_SCALE + liquidityProviderBoost_) * (EXP_SCALE + representativeBonus_) <= 1.5e36,
            ErrorCodes.EC_INVALID_BOOSTS
        );
        // one account at one time can be a liquidity provider once,
        require(!isAccountLiquidityProvider(liquidityProvider_), ErrorCodes.EC_ACCOUNT_IS_ALREADY_LIQUIDITY_PROVIDER);
        // one account can't be a liquidity provider and a representative at the same time
        require(
            !isAccountRepresentative(liquidityProvider_) && !isAccountLiquidityProvider(representative_),
            ErrorCodes.EC_PROVIDER_CANT_BE_REPRESENTATIVE
        );

        // we are distribution MNT tokens for liquidity provider
        // slither-disable-next-line reentrancy-no-eth,reentrancy-benign,reentrancy-events
        rewardsHub().distributeAllMnt(liquidityProvider_);

        // we are creating agreement between liquidity provider and representative
        providerToAgreement[liquidityProvider_] = Agreement({
            representative: representative_,
            liquidityProviderBoost: liquidityProviderBoost_,
            representativeBonus: representativeBonus_,
            endBlock: endBlock_
        });
        representativesProviderCounter[representative_]++;

        emit AgreementAdded(
            liquidityProvider_,
            representative_,
            representativeBonus_,
            liquidityProviderBoost_,
            uint32(_getBlockNumber()),
            endBlock_
        );
    }

    /// @inheritdoc IBDSystem
    function removeAgreement(address liquidityProvider_, address representative_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        Agreement storage agreement = providerToAgreement[liquidityProvider_];
        require(agreement.representative == representative_, ErrorCodes.EC_INVALID_PROVIDER_REPRESENTATIVE);

        emit AgreementEnded(
            liquidityProvider_,
            representative_,
            agreement.representativeBonus,
            agreement.liquidityProviderBoost,
            agreement.endBlock
        );

        // We call emission system for liquidity provider, so liquidity provider and his representative will accrue
        // MNT tokens with their emission boosts
        // slither-disable-next-line reentrancy-no-eth,reentrancy-benign
        rewardsHub().distributeAllMnt(liquidityProvider_);

        // We remove agreement between liquidity provider and representative
        delete providerToAgreement[liquidityProvider_];
        representativesProviderCounter[representative_]--;
    }

    /*** Helper special functions ***/

    /// @inheritdoc IBDSystem
    function isAccountLiquidityProvider(address account_) public view returns (bool) {
        return providerToAgreement[account_].representative != address(0);
    }

    /// @inheritdoc IBDSystem
    function isAccountRepresentative(address account_) public view returns (bool) {
        return representativesProviderCounter[account_] > 0;
    }

    /// @inheritdoc IBDSystem
    function isAgreementExpired(address account_) external view returns (bool) {
        require(isAccountLiquidityProvider(account_), ErrorCodes.EC_ACCOUNT_HAS_NO_AGREEMENT);
        return providerToAgreement[account_].endBlock <= _getBlockNumber();
    }

    /// @dev Function to simply retrieve block number
    ///      This exists mainly for inheriting test contracts to stub this result.
    function _getBlockNumber() internal view virtual returns (uint256) {
        return block.number;
    }

    function rewardsHub() internal view returns (IRewardsHub) {
        return getInterconnector().rewardsHub();
    }
}