// SPDX-License-Identifier: BUSL-1.1
// GameFi Core™ by CDEVS

pragma solidity 0.8.10;

import "./IBaseInstaller.sol";

interface IGameFiInstallerV1 is IBaseInstaller {
    struct InstallerV1Settings {
        // general
        address envAdmin;
        address envOperator;
        string envName;
        string envTag;
        // core
        address gameFiCoreImpl;
        bytes gameFiCoreInitializeData;
        bytes createPropertyAvatarData;
        bytes createPropertyNameData;
        bytes createCollectionAvatarsData;
        bytes createCollectionBoxesData;
        // shops
        address gameFiShopsImpl;
        // marketplace
        address gameFiMarketplaceImpl;
        // router
        address gameFiRouterImpl;
        // multitransactor
        address multitransactorImpl;
    }

    function deployEnvironment(InstallerV1Settings memory envSettings)
        external
        returns (uint256 environmentId, Environment memory environment);
}