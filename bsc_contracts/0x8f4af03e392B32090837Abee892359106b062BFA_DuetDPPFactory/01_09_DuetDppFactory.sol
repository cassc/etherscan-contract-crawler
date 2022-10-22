// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ICloneFactory } from "../lib/CloneFactory.sol";
import { IDPPOracle } from "../interfaces/IDPPOracle.sol";
import { IDPPController } from "../interfaces/IDPPController.sol";
import { IDPPOracleAdmin } from "../interfaces/IDPPOracleAdmin.sol";
import { IOracle } from "../external/interfaces/IOracle.sol";
import "../lib/Adminable.sol";

/// @title DppController
/// @author So. Lu
/// @notice Use this contract to create controller
contract DuetDPPFactory is Adminable, Initializable {
    // ============ default ============

    address public CLONE_FACTORY;
    address public WETH;
    address public dodoDefautMtFeeRateModel;
    address public dodoApproveProxy;
    address public dodoDefaultMaintainer;

    // ============ Templates ============

    address public dppTemplate;
    address public dppAdminTemplate;
    address public dppControllerTemplate;

    // ============registry and adminlist ==========

    // base->quote->dppController
    mapping(address => mapping(address => address)) public registry;

    // ============ Events ============

    event NewDPP(address baseToken, address quoteToken, address creator, address dpp, address dppController);
    event DelDPPCtrl(address baseToken, address quoteToken, address creator, address dppController);
    event UpdateMaintainer(address newMaintainer);
    event UpdateFeeModel(address newFeeModel);
    event UpdateDODOApprove(address newDODOApprove);
    event UpdateDppTemplate(address newDPPTemplate);
    event UpdateCtrlTemplate(address newCtrlTemp);
    event UpdateAdminTemplate(address newAdminTemp);

    constructor() initializer {}

    function initialize(
        address admin_,
        address cloneFactory_,
        address dppTemplate_,
        address dppAdminTemplate_,
        address dppControllerTemplate_,
        address defaultMaintainer_,
        address defaultMtFeeRateModel_,
        address dodoApproveProxy_,
        address weth_
    ) public initializer {
        require(admin_ != address(0), "Duet_dpp_factory: admin is zero address");
        _setAdmin(admin_);
        WETH = weth_;

        CLONE_FACTORY = cloneFactory_;
        dppTemplate = dppTemplate_;
        dppAdminTemplate = dppAdminTemplate_;
        dppControllerTemplate = dppControllerTemplate_;

        dodoDefaultMaintainer = defaultMaintainer_;
        dodoDefautMtFeeRateModel = defaultMtFeeRateModel_;
        dodoApproveProxy = dodoApproveProxy_;

        // emit events
        emit UpdateMaintainer(defaultMaintainer_);
        emit UpdateFeeModel(defaultMtFeeRateModel_);
        emit UpdateDODOApprove(dodoApproveProxy_);
        emit UpdateDppTemplate(dppTemplate_);
        emit UpdateCtrlTemplate(dppControllerTemplate_);
        emit UpdateAdminTemplate(dppAdminTemplate_);
    }

    // ============ Admin Operation Functions ============

    /// @notice change dpp param - dodo maintainer
    function updateDefaultMaintainer(address newMaintainer_) external onlyAdmin {
        require(newMaintainer_ != address(0), "Duet_dpp_factory: maintainer is zero address");
        dodoDefaultMaintainer = newMaintainer_;
        emit UpdateMaintainer(newMaintainer_);
    }

    /// @notice change dpp param - dodo feeModel
    function updateDefaultFeeModel(address newFeeModel_) external onlyAdmin {
        require(newFeeModel_ != address(0), "Duet_dpp_factory: feeModel is zero address");
        dodoDefautMtFeeRateModel = newFeeModel_;
        emit UpdateFeeModel(newFeeModel_);
    }

    /// @notice change dpp param - dodo approve
    function updateDodoApprove(address newDodoApprove_) external onlyAdmin {
        require(newDodoApprove_ != address(0), "Duet_dpp_factory: dodoApprove is zero address");
        dodoApproveProxy = newDodoApprove_;
        emit UpdateDODOApprove(newDodoApprove_);
    }

    function updateDppTemplate(address newDPPTemplate_) external onlyAdmin {
        require(newDPPTemplate_ != address(0), "Duet_dpp_factory: dpp template is zero address");
        dppTemplate = newDPPTemplate_;
        emit UpdateDppTemplate(newDPPTemplate_);
    }

    function updateAdminTemplate(address newDPPAdminTemplate_) external onlyAdmin {
        require(newDPPAdminTemplate_ != address(0), "Duet_dpp_factory: dpp admin template is zero address");
        dppAdminTemplate = newDPPAdminTemplate_;
        emit UpdateAdminTemplate(newDPPAdminTemplate_);
    }

    function updateControllerTemplate(address newController_) external onlyAdmin {
        require(newController_ != address(0), "Duet_dpp_factory: dpp ctrl template is zero address");
        dppControllerTemplate = newController_;
        emit UpdateCtrlTemplate(newController_);
    }

    function delOnePool(
        address baseToken_,
        address quoteToken_,
        address dppCtrlAddress_,
        address creator_
    ) external onlyAdmin {
        require(registry[baseToken_][quoteToken_] != address(0), "pool not exist");
        registry[baseToken_][quoteToken_] = address(0);
        emit DelDPPCtrl(baseToken_, quoteToken_, creator_, dppCtrlAddress_);
    }

    function getDppController(address base_, address quote_) public view returns (address dppAddress) {
        dppAddress = registry[base_][quote_];
    }

    // ============ Functions ============

    function _createDODOPrivatePool() internal returns (address newPrivatePool) {
        newPrivatePool = ICloneFactory(CLONE_FACTORY).clone(dppTemplate);
    }

    function _createDPPAdminModel() internal returns (address newDppAdminModel) {
        newDppAdminModel = ICloneFactory(CLONE_FACTORY).clone(dppAdminTemplate);
    }

    /// @notice create dpp Controller
    /// @param creator_ dpp controller's admin and dppAdmin's operator
    /// @param baseToken_ basetoken address
    /// @param quoteToken_ quotetoken address
    /// @param lpFeeRate_ lp fee rate, unit is 10**18, range in [0, 10**18], eg 3,00000,00000,00000 = 0.003 = 0.3%
    /// @param k_ a param for swap curve, limit in [0，10**18], unit is  10**18，0 is stable price curve，10**18 is bonding curve like uni
    /// @param i_ base to quote price, decimals 18 - baseTokenDecimals+ quoteTokenDecimals. If use oracle, i set here wouldn't be used.
    /// @param o_ oracle address
    /// @param isOpenTwap_ use twap price or not
    /// @param isOracleEnabled_ use oracle or not
    function createDPPController(
        address creator_,
        address baseToken_,
        address quoteToken_,
        uint256 lpFeeRate_,
        uint256 k_,
        uint256 i_,
        address o_,
        bool isOpenTwap_,
        bool isOracleEnabled_
    ) external onlyAdmin {
        require(
            registry[baseToken_][quoteToken_] == address(0) && registry[quoteToken_][baseToken_] == address(0),
            "HAVE CREATED"
        );
        if (isOracleEnabled_) {
            require(IOracle(o_).prices(address(baseToken_)) > 0, "Duet Dpp Factory: set invalid oracle");
        }
        address dppAddress;
        address dppController;
        {
            dppAddress = _createDODOPrivatePool();
            address dppAdminModel = _createDPPAdminModel();
            IDPPOracle(dppAddress).init(
                dppAdminModel,
                dodoDefaultMaintainer,
                baseToken_,
                quoteToken_,
                lpFeeRate_,
                dodoDefautMtFeeRateModel,
                k_,
                i_,
                o_,
                isOpenTwap_,
                isOracleEnabled_
            );

            dppController = _createDPPController(creator_, dppAddress, dppAdminModel);

            IDPPOracleAdmin(dppAdminModel).init(
                dppController, // owner
                dppAddress,
                dppController, // del dpp admin's operator
                dodoApproveProxy
            );
        }

        registry[baseToken_][quoteToken_] = dppController;
        emit NewDPP(baseToken_, quoteToken_, creator_, dppAddress, dppController);
    }

    function _createDPPController(
        address admin_,
        address dppAddress_,
        address dppAdminAddress_
    ) internal returns (address dppController) {
        dppController = ICloneFactory(CLONE_FACTORY).clone(dppControllerTemplate);
        IDPPController(dppController).init(admin_, dppAddress_, dppAdminAddress_, WETH);
    }
}