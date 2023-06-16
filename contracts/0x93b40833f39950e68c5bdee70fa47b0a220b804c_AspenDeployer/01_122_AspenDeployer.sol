// SPDX-License-Identifier: Apache-2.0

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                           //
//                      _'                    AAA                                                                                            //
//                    !jz_                   A:::A                                                                                           //
//                 ;Lzzzz-                  A:::::A                                                                                          //
//              '1zzzzxzz'                 A:::::::A                                                                                         //
//            !xzzzzzzi~                  A:::::::::A             ssssssssss   ppppp   ppppppppp       eeeeeeeeeeee    nnnn  nnnnnnnn        //
//         ;izzzzzzj^`                   A:::::A:::::A          ss::::::::::s  p::::ppp:::::::::p    ee::::::::::::ee  n:::nn::::::::nn      //
//              `;^.`````               A:::::A A:::::A       ss:::::::::::::s p:::::::::::::::::p  e::::::eeeee:::::een::::::::::::::nn     //
//              -;;;;;;;-              A:::::A   A:::::A      s::::::ssss:::::spp::::::ppppp::::::pe::::::e     e:::::enn:::::::::::::::n    //
//           .;;;;;;;_                A:::::A     A:::::A      s:::::s  ssssss  p:::::p     p:::::pe:::::::eeeee::::::e  n:::::nnnn:::::n    //
//         ;;;;;;;;`                 A:::::AAAAAAAAA:::::A       s::::::s       p:::::p     p:::::pe:::::::::::::::::e   n::::n    n::::n    //
//      _;;;;;;;'                   A:::::::::::::::::::::A         s::::::s    p:::::p     p:::::pe::::::eeeeeeeeeee    n::::n    n::::n    //
//            ;{jjjjjjjjj          A:::::AAAAAAAAAAAAA:::::A  ssssss   s:::::s  p:::::p    p::::::pe:::::::e             n::::n    n::::n    //
//         `+IIIVVVVVVVVI`        A:::::A             A:::::A s:::::ssss::::::s p:::::ppppp:::::::pe::::::::e            n::::n    n::::n    //
//       ^sIVVVVVVVVVVVVI`       A:::::A               A:::::As::::::::::::::s  p::::::::::::::::p  e::::::::eeeeeeee    n::::n    n::::n    //
//    ~xIIIVVVVVVVVVVVVVI`      A:::::A                 A:::::As:::::::::::ss   p::::::::::::::pp    ee:::::::::::::e    n::::n    n::::n    //
//  -~~~;;;;;;;;;;;;;;;;;      AAAAAAA                   AAAAAAAsssssssssss     p::::::pppppppp        eeeeeeeeeeeeee    nnnnnn    nnnnnn    //
//                                                                              p:::::p                                                      //
//                                                                              p:::::p                                                      //
//                                                                             p:::::::p                                                     //
//                                                                             p:::::::p                                                     //
//                                                                             p:::::::p                                                     //
//                                                                             ppppppppp                                                     //
//                                                                                                                                           //
//  Website: https://aspenft.io/                                                                                                             //
//  Twitter: https://twitter.com/aspenft                                                                                                     //
//                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "./core/CoreRegistryEnabled.sol";
import "./core/interfaces/ICoreRegistry.sol";
import "./drop/lib/CurrencyTransferLib.sol";
import "./drop/AspenERC721DropFactory.sol";
import "./drop/AspenSBT721DropFactory.sol";
import "./drop/AspenERC1155DropFactory.sol";
import "./paymentSplit/AspenPaymentSplitterFactory.sol";
import "./generated/deploy/BaseAspenDeployerV3.sol";
import "./api/errors/IUUPSUpgradeableErrors.sol";
import "./api/errors/ICoreErrors.sol";
import "./api/config/IGlobalConfig.sol";

contract AspenDeployer is
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    BaseAspenDeployerV3,
    CoreRegistryEnabled
{
    AspenERC721DropFactory drop721Factory;
    AspenSBT721DropFactory dropSBTFactory;
    AspenERC1155DropFactory drop1155Factory;
    AspenPaymentSplitterFactory paymentSplitterFactory;
    address drop721DelegateLogic;
    address drop1155DelegateLogic;
    address drop1155RestrictedLogic;
    address drop721RestrictedLogic;

    using ERC165CheckerUpgradeable for address;

    modifier isRegisterdOnCoreRegistry() {
        if (CORE_REGISTRY == address(0)) revert ICoreRegistryEnabledErrorsV0.CoreRegistryNotSet();
        _;
    }

    function initialize(
        AspenERC721DropFactory _drop721Factory,
        AspenSBT721DropFactory _dropSBTFactory,
        AspenERC1155DropFactory _drop1155Factory,
        AspenPaymentSplitterFactory _paymentSplitterFactory,
        address _drop1155DelegateLogic,
        address _drop721DelegateLogic,
        address _drop1155RestrictedLogic,
        address _drop721RestrictedLogic
    ) public virtual initializer {
        drop721Factory = _drop721Factory;
        dropSBTFactory = _dropSBTFactory;
        drop1155Factory = _drop1155Factory;
        paymentSplitterFactory = _paymentSplitterFactory;
        drop1155DelegateLogic = _drop1155DelegateLogic;
        drop721DelegateLogic = _drop721DelegateLogic;
        drop1155RestrictedLogic = _drop1155RestrictedLogic;
        drop721RestrictedLogic = _drop721RestrictedLogic;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev See ERC 165
    /// NOTE: Due to this function being overridden by 2 different contracts, we need to explicitly specify the interface here
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(BaseAspenDeployerV3, CoreRegistryEnabled, AccessControlUpgradeable) returns (bool) {
        return
            super.supportsInterface(interfaceId) ||
            BaseAspenDeployerV3.supportsInterface(interfaceId) ||
            AccessControlUpgradeable.supportsInterface(interfaceId);
    }

    /// ================================
    /// ========== Owner Only ==========
    /// ================================
    function reinitialize(
        AspenERC721DropFactory _drop721Factory,
        AspenSBT721DropFactory _dropSBTFactory,
        AspenERC1155DropFactory _drop1155Factory,
        AspenPaymentSplitterFactory _paymentSplitterFactory,
        address _drop1155DelegateLogic,
        address _drop721DelegateLogic,
        address _drop1155RestrictedLogic,
        address _drop721RestrictedLogic
    ) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        // NOTE: We DON'T want to re-init the CoreRegistry
        drop721Factory = _drop721Factory;
        dropSBTFactory = _dropSBTFactory;
        drop1155Factory = _drop1155Factory;
        paymentSplitterFactory = _paymentSplitterFactory;
        drop1155DelegateLogic = _drop1155DelegateLogic;
        drop721DelegateLogic = _drop721DelegateLogic;
        drop1155RestrictedLogic = _drop1155RestrictedLogic;
        drop721RestrictedLogic = _drop721RestrictedLogic;
    }

    function _authorizeUpgrade(address newImplementation) internal view override onlyRole(DEFAULT_ADMIN_ROLE) {
        (uint256 major, uint256 minor, uint256 patch) = this.implementationVersion();
        (uint256 newMajor, uint256 newMinor, uint256 newPatch) = IAspenVersionedV2(newImplementation)
            .implementationVersion();
        // Do not permit a breaking change via an UUPS proxy upgrade - this requires a new proxy. Otherwise, only allow
        // minor/patch versions to increase
        if (major != newMajor || minor > newMinor || (minor == newMinor && patch > newPatch)) {
            revert IUUPSUpgradeableErrorsV0.IllegalVersionUpgrade(major, minor, patch, newMajor, newMinor, newPatch);
        }
    }

    function resetCoreRegistry() public onlyRole(DEFAULT_ADMIN_ROLE) {
        CORE_REGISTRY = address(0);
    }

    /// ====================================
    /// ========== Deployment Fees =========
    /// ====================================

    function getDeploymentFeeDetails(
        address _account
    ) public view override returns (address feeReceiver, uint256 price, address currency) {
        return _getDeploymentFeeDetails(_account);
    }

    function getDefaultDeploymentFeeDetails()
        public
        view
        override
        returns (address feeReceiver, uint256 price, address currency)
    {
        return _getDeploymentFeeDetails(address(0));
    }

    /// ================================
    /// ========== Deployments =========
    /// ================================
    function deployAspenERC721Drop(
        IDropFactoryDataTypesV2.TokenDetails memory _tokenDetails,
        IDropFactoryDataTypesV2.FeeDetails memory _feeDetails,
        bytes32 _operatorFiltererId
    ) external payable override isRegisterdOnCoreRegistry returns (IAspenERC721DropV3) {
        IGlobalConfigV1 aspenConfig = IGlobalConfigV1(CORE_REGISTRY);
        /// Note: If operator id does NOT exist, it will throw an error here.
        /// Even in case we don't want to set an operator, we need to specify the NO_OPERATOR filterer id
        IOperatorFiltererDataTypesV0.OperatorFilterer memory filterer = aspenConfig.getOperatorFiltererOrDie(
            _operatorFiltererId
        );

        IDropFactoryDataTypesV2.DropConfig memory dropConfig = IDropFactoryDataTypesV2.DropConfig(
            drop721DelegateLogic,
            drop721RestrictedLogic,
            aspenConfig,
            _tokenDetails,
            _feeDetails,
            filterer
        );

        AspenERC721Drop newContract = drop721Factory.deploy(dropConfig);

        (uint256 major, uint256 minor, uint256 patch) = newContract.implementationVersion();
        string memory interfaceId = newContract.implementationInterfaceId();
        _payDeploymentFee(_msgSender(), address(newContract));
        emit AspenInterfaceDeployed(address(newContract), major, minor, patch, interfaceId);
        return IAspenERC721DropV3(address(newContract));
    }

    function deployAspenSBT721Drop(
        IDropFactoryDataTypesV2.TokenDetails memory _tokenDetails,
        IDropFactoryDataTypesV2.FeeDetails memory _feeDetails,
        bytes32 _operatorFiltererId
    ) external payable override isRegisterdOnCoreRegistry returns (IAspenERC721DropV3) {
        IGlobalConfigV1 aspenConfig = IGlobalConfigV1(CORE_REGISTRY);
        /// Note: If operator id does NOT exist, it will throw an error here.
        /// Even in case we don't want to set an operator, we need to specify the NO_OPERATOR filterer id
        IOperatorFiltererDataTypesV0.OperatorFilterer memory filterer = aspenConfig.getOperatorFiltererOrDie(
            _operatorFiltererId
        );

        IDropFactoryDataTypesV2.DropConfig memory dropConfig = IDropFactoryDataTypesV2.DropConfig(
            drop721DelegateLogic,
            drop721RestrictedLogic,
            aspenConfig,
            _tokenDetails,
            _feeDetails,
            filterer
        );

        AspenSBT721Drop newContract = dropSBTFactory.deploy(dropConfig);

        (uint256 major, uint256 minor, uint256 patch) = newContract.implementationVersion();
        string memory interfaceId = newContract.implementationInterfaceId();
        _payDeploymentFee(_msgSender(), address(newContract));
        emit AspenInterfaceDeployed(address(newContract), major, minor, patch, interfaceId);
        return IAspenERC721DropV3(address(newContract));
    }

    function deployAspenERC1155Drop(
        IDropFactoryDataTypesV2.TokenDetails memory _tokenDetails,
        IDropFactoryDataTypesV2.FeeDetails memory _feeDetails,
        bytes32 _operatorFiltererId
    ) external payable override isRegisterdOnCoreRegistry returns (IAspenERC1155DropV3) {
        IGlobalConfigV1 aspenConfig = IGlobalConfigV1(CORE_REGISTRY);
        /// Note: If operator id does NOT exist, it will throw an error here.
        /// Even in case we don't want to set an operator, we need to specify the NO_OPERATOR filterer id
        IOperatorFiltererDataTypesV0.OperatorFilterer memory filterer = aspenConfig.getOperatorFiltererOrDie(
            _operatorFiltererId
        );

        IDropFactoryDataTypesV2.DropConfig memory dropConfig = IDropFactoryDataTypesV2.DropConfig(
            drop1155DelegateLogic,
            drop1155RestrictedLogic,
            aspenConfig,
            _tokenDetails,
            _feeDetails,
            filterer
        );

        AspenERC1155Drop newContract = drop1155Factory.deploy(dropConfig);

        (uint256 major, uint256 minor, uint256 patch) = newContract.implementationVersion();
        string memory interfaceId = newContract.implementationInterfaceId();
        _payDeploymentFee(_msgSender(), address(newContract));
        emit AspenInterfaceDeployed(address(newContract), major, minor, patch, interfaceId);
        return IAspenERC1155DropV3(address(newContract));
    }

    function deployAspenPaymentSplitter(
        address[] memory payees,
        uint256[] memory shares_
    ) external override isRegisterdOnCoreRegistry returns (IAspenPaymentSplitterV2) {
        AspenPaymentSplitter newContract = paymentSplitterFactory.deploy(payees, shares_);
        string memory interfaceId = newContract.implementationInterfaceId();
        (uint256 major, uint256 minor, uint256 patch) = newContract.implementationVersion();
        emit AspenInterfaceDeployed(address(newContract), major, minor, patch, interfaceId);
        return IAspenPaymentSplitterV2(address(newContract));
    }

    /// ================================
    /// =========== Versioning =========
    /// ================================
    function aspenERC721DropVersion() external view override returns (uint256 major, uint256 minor, uint256 patch) {
        return drop721Factory.implementationVersion();
    }

    function aspenSBT721DropVersion() external view override returns (uint256 major, uint256 minor, uint256 patch) {
        return dropSBTFactory.implementationVersion();
    }

    function aspenERC1155DropVersion() external view override returns (uint256 major, uint256 minor, uint256 patch) {
        return drop1155Factory.implementationVersion();
    }

    function aspenPaymentSplitterVersion()
        external
        view
        override
        returns (uint256 major, uint256 minor, uint256 patch)
    {
        return paymentSplitterFactory.implementationVersion();
    }

    /// ================================
    /// =========== Features ===========
    /// ================================
    function aspenERC721DropFeatureCodes() external view override returns (uint256[] memory features) {
        return drop721Factory.implementation().supportedFeatureCodes();
    }

    function aspenSBT721DropFeatureCodes() external view override returns (uint256[] memory features) {
        return dropSBTFactory.implementation().supportedFeatureCodes();
    }

    function aspenERC1155DropFeatureCodes() external view override returns (uint256[] memory features) {
        return drop1155Factory.implementation().supportedFeatureCodes();
    }

    function aspenPaymentSplitterFeatureCodes() external view override returns (uint256[] memory features) {
        return paymentSplitterFactory.implementation().supportedFeatureCodes();
    }

    /// ================================
    /// ======== Interface Ids =========
    /// ================================
    function aspenERC721DropInterfaceId() external view override returns (string memory interfaceId) {
        return drop721Factory.implementation().implementationInterfaceId();
    }

    function aspenSBT721DropInterfaceId() external view override returns (string memory interfaceId) {
        return dropSBTFactory.implementation().implementationInterfaceId();
    }

    function aspenERC1155DropInterfaceId() external view override returns (string memory interfaceId) {
        return drop1155Factory.implementation().implementationInterfaceId();
    }

    function aspenPaymentSplitterInterfaceId() external view override returns (string memory interfaceId) {
        return paymentSplitterFactory.implementation().implementationInterfaceId();
    }

    /// ================================
    /// ======= Internal Methods =======
    /// ================================
    /// @dev This function checks if both the deployment fee and fee receiver address are set.
    ///     If they are, then it pays the deployment fee to the fee receiver.
    function _payDeploymentFee(address _payee, address _deployedcontract) internal {
        (address feeReceiver, uint256 deploymentFee, address currency) = _getDeploymentFeeDetails(_payee);
        if (deploymentFee > 0 && feeReceiver != address(0)) {
            CurrencyTransferLib.transferCurrency(currency, _payee, feeReceiver, deploymentFee);

            emit DeploymentFeePaid(_payee, feeReceiver, _deployedcontract, currency, deploymentFee);
        }
    }

    /// @dev Returns the deployment fees for a specific address by checking the tiered pricing system on core registry
    function _getDeploymentFeeDetails(
        address _account
    ) internal view returns (address feeReceiver, uint256 price, address currency) {
        IGlobalConfigV1 aspenConfig = IGlobalConfigV1(CORE_REGISTRY);
        return aspenConfig.getDeploymentFee(_account);
    }

    /// ================================
    /// ======== Miscellaneous =========
    /// ================================
    // Concrete implementation semantic version - provided for completeness but not designed to be the point of dispatch
    function minorVersion() public pure virtual override returns (uint256 minor, uint256 patch) {
        minor = 0;
        patch = 0;
    }
}