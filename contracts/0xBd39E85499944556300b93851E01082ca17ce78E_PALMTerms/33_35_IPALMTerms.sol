// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {
    IArrakisV2Factory
} from "@arrakisfi/v2-core/contracts/interfaces/IArrakisV2Factory.sol";
import {
    IArrakisV2Resolver
} from "@arrakisfi/v2-core/contracts/interfaces/IArrakisV2Resolver.sol";
import {IArrakisV2Extended} from "./IArrakisV2Extended.sol";
import {IPALMManager} from "./IPALMManager.sol";
import {SetupPayload, IncreaseBalance} from "../structs/SPALMTerms.sol";

interface IPALMTerms {
    // #region events.

    event SetEmolument(uint16 oldEmolument, uint16 newEmolment);
    event SetTermTreasury(address oldTermTreasury, address newTermTreasury);
    event SetManager(address oldManager, address newManager);
    event SetResolver(
        IArrakisV2Resolver oldResolver,
        IArrakisV2Resolver newResolver
    );

    event AddVault(address creator, address vault);
    event DelegateVault(address creator, address vault, address delegate);

    event SetupVault(address creator, address vault);
    event IncreaseLiquidity(address creator, address vault);
    event RenewTerm(address vault, uint256 emolument0, uint256 emolument1);
    event CloseTerm(
        address creator,
        address vault,
        uint256 amount0,
        uint256 amount1,
        address to,
        uint256 emolument0,
        uint256 emolument1
    );

    // #region vault modification events.

    event LogAddPools(address creator, address vault, uint24[] feeTiers);

    event LogRemovePools(address creator, address vault, address[] pools);

    event LogWhitelistRouters(
        address creator,
        address vault,
        address[] routers
    );

    event LogBlacklistRouters(
        address creator,
        address vault,
        address[] routers
    );

    // #endregion vault modification events.

    // #region PALMManager interaction events.

    event LogSetVaultData(address creatorOrDelegate, address vault, bytes data);

    event LogSetVaultStratByName(
        address creatorOrDelegate,
        address vault,
        string strat
    );

    event LogSetDelegate(address creator, address vault, address delegate);

    event LogWithdrawVaultBalance(
        address creator,
        address vault,
        address to,
        uint256 sentBack
    );

    // #endregion PALMManager interaction events.

    // #endregion events.

    function openTerm(SetupPayload calldata setup_)
        external
        payable
        returns (address vault);

    function increaseLiquidity(IncreaseBalance calldata increaseBalance_)
        external;

    function renewTerm(IArrakisV2Extended vault_) external;

    function closeTerm(
        IArrakisV2Extended vault_,
        address to_,
        address newOwner_,
        address newManager_
    ) external;

    // #region Vault configuration functions.

    function addPools(IArrakisV2Extended vault_, uint24[] calldata feeTiers_)
        external;

    function removePools(IArrakisV2Extended vault_, address[] calldata pools_)
        external;

    function whitelistRouters(
        IArrakisV2Extended vault_,
        address[] calldata routers_
    ) external;

    function blacklistRouters(
        IArrakisV2Extended vault_,
        address[] calldata routers_
    ) external;

    // #endregion Vault configuration functions.

    // #region PALMManager configuration functions.

    function setVaultData(address vault_, bytes calldata data_) external;

    function setVaultStratByName(address vault_, string calldata strat_)
        external;

    function setDelegate(address vault_, address delegate_) external;

    function withdrawVaultBalance(
        address vault_,
        uint256 amount_,
        address payable to_
    ) external;

    function setManager(address manager_) external;

    // #endregion PALMManager configuration functions.

    function v2factory() external view returns (IArrakisV2Factory);

    function termTreasury() external view returns (address);

    function manager() external view returns (address);

    function emolument() external view returns (uint16);
}