/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/SafeCast.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {SignedSafeMath} from "@openzeppelin/contracts/math/SignedSafeMath.sol";

import {AddressArrayUtils} from "../../../lib/AddressArrayUtils.sol";
import {IController} from "../../../interfaces/IController.sol";
import {INAVIssuanceHook} from "../../../interfaces/INAVIssuanceHook.sol";
import {Invoke} from "../../lib/Invoke.sol";
import {IJasperVault} from "../../../interfaces/IJasperVault.sol";
import {IWETH} from "../../../interfaces/external/IWETH.sol";
import {ModuleBase} from "../../lib/ModuleBase.sol";
import {Position} from "../../lib/Position.sol";
import {PreciseUnitMath} from "../../../lib/PreciseUnitMath.sol";
import {ResourceIdentifier} from "../../lib/ResourceIdentifier.sol";

interface ISignalSuscriptionModule {
    function get_signal_provider(address) external view returns (address);
    function get_followers(address) external view returns (address[] memory);
        
    
}

/**
 * @title NavIssuanceModule
 * @author Set Protocol
 *
 * Module that enables issuance and redemption with any valid ERC20 token or ETH if allowed by the manager. Sender receives
 * a proportional amount of SetTokens on issuance or ERC20 token on redemption based on the calculated net asset value using
 * oracle prices. Manager is able to enforce a premium / discount on issuance / redemption to avoid arbitrage and front
 * running when relying on oracle prices. Managers can charge a fee (denominated in reserve asset).
 */
contract NavIssuanceModule is ModuleBase, ReentrancyGuard {
    using AddressArrayUtils for address[];
    using Invoke for IJasperVault;
    using Position for IJasperVault;
    using PreciseUnitMath for uint256;
    using PreciseUnitMath for int256;
    using ResourceIdentifier for IController;
    using SafeMath for uint256;
    using SafeCast for int256;
    using SafeCast for uint256;
    using SignedSafeMath for int256;

    /* ============ Events ============ */

    event SetTokenNAVIssued(
        IJasperVault indexed _jasperVault,
        address _issuer,
        address _to,
        address _reserveAsset,
        address _hookContract,
        uint256 _setTokenQuantity,
        uint256 _managerFee,
        uint256 _premium
    );

    event SetTokenNAVRedeemed(
        IJasperVault indexed _jasperVault,
        address _redeemer,
        address _to,
        address _reserveAsset,
        address _hookContract,
        uint256 _setTokenQuantity,
        uint256 _managerFee,
        uint256 _premium
    );

    event ReserveAssetAdded(
        IJasperVault indexed _jasperVault,
        address _newReserveAsset
    );

    event ReserveAssetRemoved(
        IJasperVault indexed _jasperVault,
        address _removedReserveAsset
    );

    event PremiumEdited(IJasperVault indexed _jasperVault, uint256 _newPremium);

    event ManagerFeeEdited(
        IJasperVault indexed _jasperVault,
        uint256 _newManagerFee,
        uint256 _index
    );

    event FeeRecipientEdited(
        IJasperVault indexed _jasperVault,
        address _feeRecipient
    );

    /* ============ Structs ============ */

    struct NAVIssuanceSettings {
        INAVIssuanceHook managerIssuanceHook; // Issuance hook configurations
        INAVIssuanceHook managerRedemptionHook; // Redemption hook configurations
        address[] reserveAssets; // Allowed reserve assets - Must have a price enabled with the price oracle
        address feeRecipient; // Manager fee recipient
        uint256[2] managerFees; // Manager fees. 0 index is issue and 1 index is redeem fee (0.01% = 1e14, 1% = 1e16)
        uint256 maxManagerFee; // Maximum fee manager is allowed to set for issue and redeem
        uint256 premiumPercentage; // Premium percentage (0.01% = 1e14, 1% = 1e16). This premium is a buffer around oracle
        // prices paid by user to the JasperVault, which prevents arbitrage and oracle front running
        uint256 maxPremiumPercentage; // Maximum premium percentage manager is allowed to set (configured by manager)
        uint256 minSetTokenSupply; // Minimum JasperVault supply required for issuance and redemption
        // to prevent dramatic inflationary changes to the JasperVault's position multiplier
    }

    struct ActionInfo {
        uint256 preFeeReserveQuantity; // Reserve value before fees; During issuance, represents raw quantity
        // During redeem, represents post-premium value
        uint256 protocolFees; // Total protocol fees (direct + manager revenue share)
        uint256 managerFee; // Total manager fee paid in reserve asset
        uint256 netFlowQuantity; // When issuing, quantity of reserve asset sent to JasperVault
        // When redeeming, quantity of reserve asset sent to redeemer
        uint256 setTokenQuantity; // When issuing, quantity of SetTokens minted to mintee
        // When redeeming, quantity of JasperVault redeemed
        uint256 previousSetTokenSupply; // JasperVault supply prior to issue/redeem action
        uint256 newSetTokenSupply; // JasperVault supply after issue/redeem action
        int256 newPositionMultiplier; // JasperVault position multiplier after issue/redeem
        uint256 newReservePositionUnit; // JasperVault reserve asset position unit after issue/redeem
    }

    /* ============ State Variables ============ */

    // Wrapped ETH address
    IWETH public immutable weth;

    // Mapping of JasperVault to NAV issuance settings struct
    mapping(IJasperVault => NAVIssuanceSettings) public navIssuanceSettings;

    // Mapping to efficiently check a JasperVault's reserve asset validity
    // JasperVault => reserveAsset => isReserveAsset
    mapping(IJasperVault => mapping(address => bool)) public isReserveAsset;

    /* ============ Constants ============ */

    // 0 index stores the manager fee in managerFees array, percentage charged on issue (denominated in reserve asset)
    uint256 internal constant MANAGER_ISSUE_FEE_INDEX = 0;

    // 1 index stores the manager fee percentage in managerFees array, charged on redeem
    uint256 internal constant MANAGER_REDEEM_FEE_INDEX = 1;

    // 0 index stores the manager revenue share protocol fee % on the controller, charged in the issuance function
    uint256 internal constant PROTOCOL_ISSUE_MANAGER_REVENUE_SHARE_FEE_INDEX =
        0;

    // 1 index stores the manager revenue share protocol fee % on the controller, charged in the redeem function
    uint256 internal constant PROTOCOL_REDEEM_MANAGER_REVENUE_SHARE_FEE_INDEX =
        1;

    // 2 index stores the direct protocol fee % on the controller, charged in the issuance function
    uint256 internal constant PROTOCOL_ISSUE_DIRECT_FEE_INDEX = 2;

    // 3 index stores the direct protocol fee % on the controller, charged in the redeem function
    uint256 internal constant PROTOCOL_REDEEM_DIRECT_FEE_INDEX = 3;

    mapping(IJasperVault => mapping(address => bool)) public IROwers;

    ISignalSuscriptionModule public signalSuscriptionModule;

    modifier ValidIROwer(IJasperVault _jasperVault) {

        require(
            IROwers[_jasperVault][msg.sender] &&
                signalSuscriptionModule.get_signal_provider(
                    address(_jasperVault)
                ) ==
                address(0x00) && signalSuscriptionModule.get_followers(address(_jasperVault)).length==0,
            "Not authorized user"
        );
        _;
    }

    /* ============ Constructor ============ */

    /**
     * @param _controller               Address of controller contract
     * @param _weth                     Address of wrapped eth
     */
    constructor(
        IController _controller,
        address _signalSuscriptionModule,
        IWETH _weth
    ) public ModuleBase(_controller) {
        weth = _weth;
        signalSuscriptionModule = ISignalSuscriptionModule(
            _signalSuscriptionModule
        );
    }

    /* ============ External Functions ============ */

    /**
     * Deposits the allowed reserve asset into the JasperVault and mints the appropriate % of Net Asset Value of the JasperVault
     * to the specified _to address.
     *
     * @param _jasperVault                     Instance of the JasperVault contract
     * @param _reserveAsset                 Address of the reserve asset to issue with
     * @param _reserveAssetQuantity         Quantity of the reserve asset to issue with
     * @param _minSetTokenReceiveQuantity   Min quantity of JasperVault to receive after issuance
     * @param _to                           Address to mint JasperVault to
     */
    function issue(
        IJasperVault _jasperVault,
        address _reserveAsset,
        uint256 _reserveAssetQuantity,
        uint256 _minSetTokenReceiveQuantity,
        address _to
    )
        external
        nonReentrant
        onlyValidAndInitializedSet(_jasperVault)
        ValidIROwer(_jasperVault)
    {
        _validateCommon(_jasperVault, _reserveAsset, _reserveAssetQuantity);

        _callPreIssueHooks(
            _jasperVault,
            _reserveAsset,
            _reserveAssetQuantity,
            msg.sender,
            _to
        );

        ActionInfo memory issueInfo = _createIssuanceInfo(
            _jasperVault,
            _reserveAsset,
            _reserveAssetQuantity
        );

        _validateIssuanceInfo(
            _jasperVault,
            _minSetTokenReceiveQuantity,
            issueInfo
        );

        _transferCollateralAndHandleFees(
            _jasperVault,
            IERC20(_reserveAsset),
            issueInfo
        );

        _handleIssueStateUpdates(_jasperVault, _reserveAsset, _to, issueInfo);
    }

    /**
     * Wraps ETH and deposits WETH if allowed into the JasperVault and mints the appropriate % of Net Asset Value of the JasperVault
     * to the specified _to address.
     *
     * @param _jasperVault                     Instance of the JasperVault contract
     * @param _minSetTokenReceiveQuantity   Min quantity of JasperVault to receive after issuance
     * @param _to                           Address to mint JasperVault to
     */
    function issueWithEther(
        IJasperVault _jasperVault,
        uint256 _minSetTokenReceiveQuantity,
        address _to
    )
        external
        payable
        nonReentrant
        onlyValidAndInitializedSet(_jasperVault)
        ValidIROwer(_jasperVault)
    {
        weth.deposit{value: msg.value}();

        _validateCommon(_jasperVault, address(weth), msg.value);

        _callPreIssueHooks(
            _jasperVault,
            address(weth),
            msg.value,
            msg.sender,
            _to
        );

        ActionInfo memory issueInfo = _createIssuanceInfo(
            _jasperVault,
            address(weth),
            msg.value
        );

        _validateIssuanceInfo(
            _jasperVault,
            _minSetTokenReceiveQuantity,
            issueInfo
        );

        _transferWETHAndHandleFees(_jasperVault, issueInfo);

        _handleIssueStateUpdates(_jasperVault, address(weth), _to, issueInfo);
    }

    /**
     * Redeems a JasperVault into a valid reserve asset representing the appropriate % of Net Asset Value of the JasperVault
     * to the specified _to address. Only valid if there are available reserve units on the JasperVault.
     *
     * @param _jasperVault                     Instance of the JasperVault contract
     * @param _reserveAsset                 Address of the reserve asset to redeem with
     * @param _setTokenQuantity             Quantity of SetTokens to redeem
     * @param _minReserveReceiveQuantity    Min quantity of reserve asset to receive
     * @param _to                           Address to redeem reserve asset to
     */
    function redeem(
        IJasperVault _jasperVault,
        address _reserveAsset,
        uint256 _setTokenQuantity,
        uint256 _minReserveReceiveQuantity,
        address _to
    )
        external
        nonReentrant
        onlyValidAndInitializedSet(_jasperVault)
        ValidIROwer(_jasperVault)
    {
        _validateCommon(_jasperVault, _reserveAsset, _setTokenQuantity);

        _callPreRedeemHooks(_jasperVault, _setTokenQuantity, msg.sender, _to);

        ActionInfo memory redeemInfo = _createRedemptionInfo(
            _jasperVault,
            _reserveAsset,
            _setTokenQuantity
        );

        _validateRedemptionInfo(
            _jasperVault,
            _minReserveReceiveQuantity,
            redeemInfo
        );

        _jasperVault.burn(msg.sender, _setTokenQuantity);

        // Instruct the JasperVault to transfer the reserve asset back to the user
        _jasperVault.strictInvokeTransfer(
            _reserveAsset,
            _to,
            redeemInfo.netFlowQuantity
        );

        _handleRedemptionFees(_jasperVault, _reserveAsset, redeemInfo);

        _handleRedeemStateUpdates(_jasperVault, _reserveAsset, _to, redeemInfo);
    }

    /**
     * Redeems a JasperVault into Ether (if WETH is valid) representing the appropriate % of Net Asset Value of the JasperVault
     * to the specified _to address. Only valid if there are available WETH units on the JasperVault.
     *
     * @param _jasperVault                     Instance of the JasperVault contract
     * @param _setTokenQuantity             Quantity of SetTokens to redeem
     * @param _minReserveReceiveQuantity    Min quantity of reserve asset to receive
     * @param _to                           Address to redeem reserve asset to
     */
    function redeemIntoEther(
        IJasperVault _jasperVault,
        uint256 _setTokenQuantity,
        uint256 _minReserveReceiveQuantity,
        address payable _to
    )
        external
        nonReentrant
        onlyValidAndInitializedSet(_jasperVault)
        ValidIROwer(_jasperVault)
    {
        _validateCommon(_jasperVault, address(weth), _setTokenQuantity);

        _callPreRedeemHooks(_jasperVault, _setTokenQuantity, msg.sender, _to);

        ActionInfo memory redeemInfo = _createRedemptionInfo(
            _jasperVault,
            address(weth),
            _setTokenQuantity
        );

        _validateRedemptionInfo(
            _jasperVault,
            _minReserveReceiveQuantity,
            redeemInfo
        );

        _jasperVault.burn(msg.sender, _setTokenQuantity);

        // Instruct the JasperVault to transfer WETH from JasperVault to module
        _jasperVault.strictInvokeTransfer(
            address(weth),
            address(this),
            redeemInfo.netFlowQuantity
        );

        weth.withdraw(redeemInfo.netFlowQuantity);

        // _to.transfer(redeemInfo.netFlowQuantity);
         (bool success, )=_to.call{value:redeemInfo.netFlowQuantity}("");
         require(success,"tranfer fail");
        _handleRedemptionFees(_jasperVault, address(weth), redeemInfo);

        _handleRedeemStateUpdates(_jasperVault, address(weth), _to, redeemInfo);
    }

    /**
     * SET MANAGER ONLY. Add an allowed reserve asset
     *
     * @param _jasperVault                     Instance of the JasperVault
     * @param _reserveAsset                 Address of the reserve asset to add
     */
    function addReserveAsset(
        IJasperVault _jasperVault,
        address _reserveAsset
    ) external onlyManagerAndValidSet(_jasperVault) {
        require(
            !isReserveAsset[_jasperVault][_reserveAsset],
            "Reserve asset already exists"
        );

        navIssuanceSettings[_jasperVault].reserveAssets.push(_reserveAsset);
        isReserveAsset[_jasperVault][_reserveAsset] = true;

        emit ReserveAssetAdded(_jasperVault, _reserveAsset);
    }

    /**
     * SET MANAGER ONLY. Remove a reserve asset
     *
     * @param _jasperVault                     Instance of the JasperVault
     * @param _reserveAsset                 Address of the reserve asset to remove
     */
    function removeReserveAsset(
        IJasperVault _jasperVault,
        address _reserveAsset
    ) external onlyManagerAndValidSet(_jasperVault) {
        require(
            isReserveAsset[_jasperVault][_reserveAsset],
            "Reserve asset does not exist"
        );

        navIssuanceSettings[_jasperVault].reserveAssets = navIssuanceSettings[
            _jasperVault
        ].reserveAssets.remove(_reserveAsset);
        delete isReserveAsset[_jasperVault][_reserveAsset];

        emit ReserveAssetRemoved(_jasperVault, _reserveAsset);
    }

    /**
     * SET MANAGER ONLY. Edit the premium percentage
     *
     * @param _jasperVault                     Instance of the JasperVault
     * @param _premiumPercentage            Premium percentage in 10e16 (e.g. 10e16 = 1%)
     */
    function editPremium(
        IJasperVault _jasperVault,
        uint256 _premiumPercentage
    ) external onlyManagerAndValidSet(_jasperVault) {
        require(
            _premiumPercentage <=
                navIssuanceSettings[_jasperVault].maxPremiumPercentage,
            "Premium must be less than maximum allowed"
        );

        navIssuanceSettings[_jasperVault]
            .premiumPercentage = _premiumPercentage;

        emit PremiumEdited(_jasperVault, _premiumPercentage);
    }

    /**
     * SET MANAGER ONLY. Edit manager fee
     *
     * @param _jasperVault                     Instance of the JasperVault
     * @param _managerFeePercentage         Manager fee percentage in 10e16 (e.g. 10e16 = 1%)
     * @param _managerFeeIndex              Manager fee index. 0 index is issue fee, 1 index is redeem fee
     */
    function editManagerFee(
        IJasperVault _jasperVault,
        uint256 _managerFeePercentage,
        uint256 _managerFeeIndex
    ) external onlyManagerAndValidSet(_jasperVault) {
        require(
            _managerFeePercentage <=
                navIssuanceSettings[_jasperVault].maxManagerFee,
            "Manager fee must be less than maximum allowed"
        );

        navIssuanceSettings[_jasperVault].managerFees[
            _managerFeeIndex
        ] = _managerFeePercentage;

        emit ManagerFeeEdited(
            _jasperVault,
            _managerFeePercentage,
            _managerFeeIndex
        );
    }

    /**
     * SET MANAGER ONLY. Edit the manager fee recipient
     *
     * @param _jasperVault                     Instance of the JasperVault
     * @param _managerFeeRecipient          Manager fee recipient
     */
    function editFeeRecipient(
        IJasperVault _jasperVault,
        address _managerFeeRecipient
    ) external onlyManagerAndValidSet(_jasperVault) {
        require(
            _managerFeeRecipient != address(0),
            "Fee recipient must not be 0 address"
        );

        navIssuanceSettings[_jasperVault].feeRecipient = _managerFeeRecipient;

        emit FeeRecipientEdited(_jasperVault, _managerFeeRecipient);
    }

    /**
     * SET MANAGER ONLY. Initializes this module to the JasperVault with hooks, allowed reserve assets,
     * fees and issuance premium. Only callable by the JasperVault's manager. Hook addresses are optional.
     * Address(0) means that no hook will be called.
     *
     * @param _jasperVault                     Instance of the JasperVault to issue
     * @param _navIssuanceSettings          NAVIssuanceSettings struct defining parameters
     */
    function initialize(
        IJasperVault _jasperVault,
        NAVIssuanceSettings memory _navIssuanceSettings,
        address[] memory _iROwer
    )
        external
        onlySetManager(_jasperVault, msg.sender)
        onlyValidAndPendingSet(_jasperVault)
    {
        require(
            _navIssuanceSettings.reserveAssets.length > 0,
            "Reserve assets must be greater than 0"
        );
        require(
            _navIssuanceSettings.maxManagerFee < PreciseUnitMath.preciseUnit(),
            "Max manager fee must be less than 100%"
        );
        require(
            _navIssuanceSettings.maxPremiumPercentage <
                PreciseUnitMath.preciseUnit(),
            "Max premium percentage must be less than 100%"
        );
        require(
            _navIssuanceSettings.managerFees[0] <=
                _navIssuanceSettings.maxManagerFee,
            "Manager issue fee must be less than max"
        );
        require(
            _navIssuanceSettings.managerFees[1] <=
                _navIssuanceSettings.maxManagerFee,
            "Manager redeem fee must be less than max"
        );
        require(
            _navIssuanceSettings.premiumPercentage <=
                _navIssuanceSettings.maxPremiumPercentage,
            "Premium must be less than max"
        );
        require(
            _navIssuanceSettings.feeRecipient != address(0),
            "Fee Recipient must be non-zero address."
        );
        // Initial mint of Set cannot use NAVIssuance since minSetTokenSupply must be > 0
        require(
            _navIssuanceSettings.minSetTokenSupply > 0,
            "Min JasperVault supply must be greater than 0"
        );

        for (
            uint256 i = 0;
            i < _navIssuanceSettings.reserveAssets.length;
            i++
        ) {
            require(
                !isReserveAsset[_jasperVault][
                    _navIssuanceSettings.reserveAssets[i]
                ],
                "Reserve assets must be unique"
            );
            isReserveAsset[_jasperVault][
                _navIssuanceSettings.reserveAssets[i]
            ] = true;
        }

        navIssuanceSettings[_jasperVault] = _navIssuanceSettings;
        for (uint256 i = 0; i < _iROwer.length; i++) {
            IROwers[_jasperVault][_iROwer[i]] = true;
        }
        _jasperVault.initializeModule();
    }

    /**
     * Removes this module from the JasperVault, via call by the JasperVault. Issuance settings and
     * reserve asset states are deleted.
     */
    function removeModule() external override {
        IJasperVault jasperVault = IJasperVault(msg.sender);
        for (
            uint256 i = 0;
            i < navIssuanceSettings[jasperVault].reserveAssets.length;
            i++
        ) {
            delete isReserveAsset[jasperVault][
                navIssuanceSettings[jasperVault].reserveAssets[i]
            ];
        }

        delete navIssuanceSettings[jasperVault];
    }

    receive() external payable {}

    /* ============ External Getter Functions ============ */

    function getReserveAssets(
        IJasperVault _jasperVault
    ) external view returns (address[] memory) {
        return navIssuanceSettings[_jasperVault].reserveAssets;
    }

    function getIssuePremium(
        IJasperVault _jasperVault,
        address _reserveAsset,
        uint256 _reserveAssetQuantity
    ) external view returns (uint256) {
        return
            _getPremium(
                _jasperVault,
                _reserveAsset,
                _reserveAssetQuantity
            );
    }

    function getRedeemPremium(
        IJasperVault _jasperVault,
        address _reserveAsset,
        uint256 _setTokenQuantity
    ) external view returns (uint256) {
        return
            _getPremium(_jasperVault, _reserveAsset, _setTokenQuantity);
    }

    function getManagerFee(
        IJasperVault _jasperVault,
        uint256 _managerFeeIndex
    ) external view returns (uint256) {
        return navIssuanceSettings[_jasperVault].managerFees[_managerFeeIndex];
    }

    /**
     * Get the expected SetTokens minted to recipient on issuance
     *
     * @param _jasperVault                     Instance of the JasperVault
     * @param _reserveAsset                 Address of the reserve asset
     * @param _reserveAssetQuantity         Quantity of the reserve asset to issue with
     *
     * @return  uint256                     Expected SetTokens to be minted to recipient
     */
    function getExpectedSetTokenIssueQuantity(
        IJasperVault _jasperVault,
        address _reserveAsset,
        uint256 _reserveAssetQuantity
    ) external view returns (uint256) {
        (, , uint256 netReserveFlow) = _getFees(
            _jasperVault,
            _reserveAssetQuantity,
            PROTOCOL_ISSUE_MANAGER_REVENUE_SHARE_FEE_INDEX,
            PROTOCOL_ISSUE_DIRECT_FEE_INDEX,
            MANAGER_ISSUE_FEE_INDEX
        );

        uint256 setTotalSupply = _jasperVault.totalSupply();

        return
            _getSetTokenMintQuantity(
                _jasperVault,
                _reserveAsset,
                netReserveFlow,
                setTotalSupply
            );
    }

    /**
     * Get the expected reserve asset to be redeemed
     *
     * @param _jasperVault                     Instance of the JasperVault
     * @param _reserveAsset                 Address of the reserve asset
     * @param _setTokenQuantity             Quantity of SetTokens to redeem
     *
     * @return  uint256                     Expected reserve asset quantity redeemed
     */
    function getExpectedReserveRedeemQuantity(
        IJasperVault _jasperVault,
        address _reserveAsset,
        uint256 _setTokenQuantity
    ) external view returns (uint256) {
        uint256 preFeeReserveQuantity = _getRedeemReserveQuantity(
            _jasperVault,
            _reserveAsset,
            _setTokenQuantity
        );

        (, , uint256 netReserveFlows) = _getFees(
            _jasperVault,
            preFeeReserveQuantity,
            PROTOCOL_REDEEM_MANAGER_REVENUE_SHARE_FEE_INDEX,
            PROTOCOL_REDEEM_DIRECT_FEE_INDEX,
            MANAGER_REDEEM_FEE_INDEX
        );

        return netReserveFlows;
    }

    /**
     * Checks if issue is valid
     *
     * @param _jasperVault                     Instance of the JasperVault
     * @param _reserveAsset                 Address of the reserve asset
     * @param _reserveAssetQuantity         Quantity of the reserve asset to issue with
     *
     * @return  bool                        Returns true if issue is valid
     */
    function isIssueValid(
        IJasperVault _jasperVault,
        address _reserveAsset,
        uint256 _reserveAssetQuantity
    ) external view returns (bool) {
        uint256 setTotalSupply = _jasperVault.totalSupply();

        return
            _reserveAssetQuantity != 0 &&
            isReserveAsset[_jasperVault][_reserveAsset] &&
            setTotalSupply >=
            navIssuanceSettings[_jasperVault].minSetTokenSupply;
    }

    /**
     * Checks if redeem is valid
     *
     * @param _jasperVault                     Instance of the JasperVault
     * @param _reserveAsset                 Address of the reserve asset
     * @param _setTokenQuantity             Quantity of SetTokens to redeem
     *
     * @return  bool                        Returns true if redeem is valid
     */
    function isRedeemValid(
        IJasperVault _jasperVault,
        address _reserveAsset,
        uint256 _setTokenQuantity
    ) external view returns (bool) {
        uint256 setTotalSupply = _jasperVault.totalSupply();

        if (
            _setTokenQuantity == 0 ||
            !isReserveAsset[_jasperVault][_reserveAsset] ||
            setTotalSupply <
            navIssuanceSettings[_jasperVault].minSetTokenSupply.add(
                _setTokenQuantity
            )
        ) {
            return false;
        } else {
            uint256 totalRedeemValue = _getRedeemReserveQuantity(
                _jasperVault,
                _reserveAsset,
                _setTokenQuantity
            );

            (, , uint256 expectedRedeemQuantity) = _getFees(
                _jasperVault,
                totalRedeemValue,
                PROTOCOL_REDEEM_MANAGER_REVENUE_SHARE_FEE_INDEX,
                PROTOCOL_REDEEM_DIRECT_FEE_INDEX,
                MANAGER_REDEEM_FEE_INDEX
            );

            uint256 existingUnit = _jasperVault
                .getDefaultPositionRealUnit(_reserveAsset)
                .toUint256();

            return
                existingUnit.preciseMul(setTotalSupply) >=
                expectedRedeemQuantity;
        }
    }

    /* ============ Internal Functions ============ */

    function _validateCommon(
        IJasperVault _jasperVault,
        address _reserveAsset,
        uint256 _quantity
    ) internal view {
        require(_quantity > 0, "Quantity must be > 0");
        require(
            isReserveAsset[_jasperVault][_reserveAsset],
            "Must be valid reserve asset"
        );
    }

    function _validateIssuanceInfo(
        IJasperVault _jasperVault,
        uint256 _minSetTokenReceiveQuantity,
        ActionInfo memory _issueInfo
    ) internal view {
        // Check that total supply is greater than min supply needed for issuance
        // Note: A min supply amount is needed to avoid division by 0 when JasperVault supply is 0
        require(
            _issueInfo.previousSetTokenSupply >=
                navIssuanceSettings[_jasperVault].minSetTokenSupply,
            "Supply must be greater than minimum to enable issuance"
        );

        require(
            _issueInfo.setTokenQuantity >= _minSetTokenReceiveQuantity,
            "Must be greater than min JasperVault"
        );
    }

    function _validateRedemptionInfo(
        IJasperVault _jasperVault,
        uint256 _minReserveReceiveQuantity,
        ActionInfo memory _redeemInfo
    ) internal view {
        // Check that new supply is more than min supply needed for redemption
        // Note: A min supply amount is needed to avoid division by 0 when redeeming JasperVault to 0
        require(
            _redeemInfo.newSetTokenSupply >=
                navIssuanceSettings[_jasperVault].minSetTokenSupply,
            "Supply must be greater than minimum to enable redemption"
        );

        require(
            _redeemInfo.netFlowQuantity >= _minReserveReceiveQuantity,
            "Must be greater than min receive reserve quantity"
        );
    }

    function _createIssuanceInfo(
        IJasperVault _jasperVault,
        address _reserveAsset,
        uint256 _reserveAssetQuantity
    ) internal view returns (ActionInfo memory) {
        ActionInfo memory issueInfo;

        issueInfo.previousSetTokenSupply = _jasperVault.totalSupply();

        issueInfo.preFeeReserveQuantity = _reserveAssetQuantity;

        (
            issueInfo.protocolFees,
            issueInfo.managerFee,
            issueInfo.netFlowQuantity
        ) = _getFees(
            _jasperVault,
            issueInfo.preFeeReserveQuantity,
            PROTOCOL_ISSUE_MANAGER_REVENUE_SHARE_FEE_INDEX,
            PROTOCOL_ISSUE_DIRECT_FEE_INDEX,
            MANAGER_ISSUE_FEE_INDEX
        );

        issueInfo.setTokenQuantity = _getSetTokenMintQuantity(
            _jasperVault,
            _reserveAsset,
            issueInfo.netFlowQuantity,
            issueInfo.previousSetTokenSupply
        );

        (
            issueInfo.newSetTokenSupply,
            issueInfo.newPositionMultiplier
        ) = _getIssuePositionMultiplier(_jasperVault, issueInfo);

        issueInfo.newReservePositionUnit = _getIssuePositionUnit(
            _jasperVault,
            _reserveAsset,
            issueInfo
        );

        return issueInfo;
    }

    function _createRedemptionInfo(
        IJasperVault _jasperVault,
        address _reserveAsset,
        uint256 _setTokenQuantity
    ) internal view returns (ActionInfo memory) {
        ActionInfo memory redeemInfo;

        redeemInfo.setTokenQuantity = _setTokenQuantity;

        redeemInfo.preFeeReserveQuantity = _getRedeemReserveQuantity(
            _jasperVault,
            _reserveAsset,
            _setTokenQuantity
        );

        (
            redeemInfo.protocolFees,
            redeemInfo.managerFee,
            redeemInfo.netFlowQuantity
        ) = _getFees(
            _jasperVault,
            redeemInfo.preFeeReserveQuantity,
            PROTOCOL_REDEEM_MANAGER_REVENUE_SHARE_FEE_INDEX,
            PROTOCOL_REDEEM_DIRECT_FEE_INDEX,
            MANAGER_REDEEM_FEE_INDEX
        );

        redeemInfo.previousSetTokenSupply = _jasperVault.totalSupply();

        (
            redeemInfo.newSetTokenSupply,
            redeemInfo.newPositionMultiplier
        ) = _getRedeemPositionMultiplier(
            _jasperVault,
            _setTokenQuantity,
            redeemInfo
        );

        redeemInfo.newReservePositionUnit = _getRedeemPositionUnit(
            _jasperVault,
            _reserveAsset,
            redeemInfo
        );

        return redeemInfo;
    }

    /**
     * Transfer reserve asset from user to JasperVault and fees from user to appropriate fee recipients
     */
    function _transferCollateralAndHandleFees(
        IJasperVault _jasperVault,
        IERC20 _reserveAsset,
        ActionInfo memory _issueInfo
    ) internal {
        transferFrom(
            _reserveAsset,
            msg.sender,
            address(_jasperVault),
            _issueInfo.netFlowQuantity
        );

        if (_issueInfo.protocolFees > 0) {
            transferFrom(
                _reserveAsset,
                msg.sender,
                controller.feeRecipient(),
                _issueInfo.protocolFees
            );
        }

        if (_issueInfo.managerFee > 0) {
            transferFrom(
                _reserveAsset,
                msg.sender,
                navIssuanceSettings[_jasperVault].feeRecipient,
                _issueInfo.managerFee
            );
        }
    }

    /**
     * Transfer WETH from module to JasperVault and fees from module to appropriate fee recipients
     */
    function _transferWETHAndHandleFees(
        IJasperVault _jasperVault,
        ActionInfo memory _issueInfo
    ) internal {
        weth.transfer(address(_jasperVault), _issueInfo.netFlowQuantity);

        if (_issueInfo.protocolFees > 0) {
            weth.transfer(controller.feeRecipient(), _issueInfo.protocolFees);
        }

        if (_issueInfo.managerFee > 0) {
            weth.transfer(
                navIssuanceSettings[_jasperVault].feeRecipient,
                _issueInfo.managerFee
            );
        }
    }

    function _handleIssueStateUpdates(
        IJasperVault _jasperVault,
        address _reserveAsset,
        address _to,
        ActionInfo memory _issueInfo
    ) internal {
        _jasperVault.editPositionMultiplier(_issueInfo.newPositionMultiplier);

        _jasperVault.editDefaultPosition(
            _reserveAsset,
            _issueInfo.newReservePositionUnit
        );

        _jasperVault.mint(_to, _issueInfo.setTokenQuantity);

        emit SetTokenNAVIssued(
            _jasperVault,
            msg.sender,
            _to,
            _reserveAsset,
            address(navIssuanceSettings[_jasperVault].managerIssuanceHook),
            _issueInfo.setTokenQuantity,
            _issueInfo.managerFee,
            _issueInfo.protocolFees
        );
    }

    function _handleRedeemStateUpdates(
        IJasperVault _jasperVault,
        address _reserveAsset,
        address _to,
        ActionInfo memory _redeemInfo
    ) internal {
        _jasperVault.editPositionMultiplier(_redeemInfo.newPositionMultiplier);

        _jasperVault.editDefaultPosition(
            _reserveAsset,
            _redeemInfo.newReservePositionUnit
        );

        emit SetTokenNAVRedeemed(
            _jasperVault,
            msg.sender,
            _to,
            _reserveAsset,
            address(navIssuanceSettings[_jasperVault].managerRedemptionHook),
            _redeemInfo.setTokenQuantity,
            _redeemInfo.managerFee,
            _redeemInfo.protocolFees
        );
    }

    function _handleRedemptionFees(
        IJasperVault _jasperVault,
        address _reserveAsset,
        ActionInfo memory _redeemInfo
    ) internal {
        // Instruct the JasperVault to transfer protocol fee to fee recipient if there is a fee
        payProtocolFeeFromSetToken(
            _jasperVault,
            _reserveAsset,
            _redeemInfo.protocolFees
        );

        // Instruct the SetToken to transfer manager fee to manager fee recipient if there is a fee
        if (_redeemInfo.managerFee > 0) {
            _jasperVault.strictInvokeTransfer(
                _reserveAsset,
                navIssuanceSettings[_jasperVault].feeRecipient,
                _redeemInfo.managerFee
            );
        }
    }


    function _getPremium(
                IJasperVault _jasperVault,
        address /* _reserveAsset */,
        uint256 /* _setTokenQuantity */
    ) internal view virtual returns (uint256) {
        return navIssuanceSettings[_jasperVault].premiumPercentage;
    }

    /**
     * Returns the fees attributed to the manager and the protocol. The fees are calculated as follows:
     *
     * ManagerFee = (manager fee % - % to protocol) * reserveAssetQuantity
     * Protocol Fee = (% manager fee share + direct fee %) * reserveAssetQuantity
     *
     * @param _jasperVault                     Instance of the SetToken
     * @param _reserveAssetQuantity         Quantity of reserve asset to calculate fees from
     * @param _protocolManagerFeeIndex      Index to pull rev share NAV Issuance fee from the Controller
     * @param _protocolDirectFeeIndex       Index to pull direct NAV issuance fee from the Controller
     * @param _managerFeeIndex              Index from NAVIssuanceSettings (0 = issue fee, 1 = redeem fee)
     *
     * @return  uint256                     Fees paid to the protocol in reserve asset
     * @return  uint256                     Fees paid to the manager in reserve asset
     * @return  uint256                     Net reserve to user net of fees
     */
    function _getFees(
        IJasperVault _jasperVault,
        uint256 _reserveAssetQuantity,
        uint256 _protocolManagerFeeIndex,
        uint256 _protocolDirectFeeIndex,
        uint256 _managerFeeIndex
    ) internal view returns (uint256, uint256, uint256) {
        (
            uint256 protocolFeePercentage,
            uint256 managerFeePercentage
        ) = _getProtocolAndManagerFeePercentages(
                _jasperVault,
                _protocolManagerFeeIndex,
                _protocolDirectFeeIndex,
                _managerFeeIndex
            );

        // Calculate total notional fees
        uint256 protocolFees = protocolFeePercentage.preciseMul(
            _reserveAssetQuantity
        );
        uint256 managerFee = managerFeePercentage.preciseMul(
            _reserveAssetQuantity
        );

        uint256 netReserveFlow = _reserveAssetQuantity.sub(protocolFees).sub(
            managerFee
        );

        return (protocolFees, managerFee, netReserveFlow);
    }

    function _getProtocolAndManagerFeePercentages(
        IJasperVault _jasperVault,
        uint256 _protocolManagerFeeIndex,
        uint256 _protocolDirectFeeIndex,
        uint256 _managerFeeIndex
    ) internal view returns (uint256, uint256) {
        // Get protocol fee percentages
        uint256 protocolDirectFeePercent = controller.getModuleFee(
            address(this),
            _protocolDirectFeeIndex
        );
        uint256 protocolManagerShareFeePercent = controller.getModuleFee(
            address(this),
            _protocolManagerFeeIndex
        );
        uint256 managerFeePercent = navIssuanceSettings[_jasperVault]
            .managerFees[_managerFeeIndex];

        // Calculate revenue share split percentage
        uint256 protocolRevenueSharePercentage = protocolManagerShareFeePercent
            .preciseMul(managerFeePercent);
        uint256 managerRevenueSharePercentage = managerFeePercent.sub(
            protocolRevenueSharePercentage
        );
        uint256 totalProtocolFeePercentage = protocolRevenueSharePercentage.add(
            protocolDirectFeePercent
        );

        return (totalProtocolFeePercentage, managerRevenueSharePercentage);
    }

    function _getSetTokenMintQuantity(
        IJasperVault _jasperVault,
        address _reserveAsset,
        uint256 _netReserveFlows, // Value of reserve asset net of fees
        uint256 _setTotalSupply
    ) internal view returns (uint256) {
        uint256 premiumPercentage = _getPremium(
            _jasperVault,
            _reserveAsset,
            _netReserveFlows
        );
        uint256 premiumValue = _netReserveFlows.preciseMul(premiumPercentage);

        // Get valuation of the SetToken with the quote asset as the reserve asset. Returns value in precise units (1e18)
        // Reverts if price is not found
        uint256 setTokenValuation = controller
            .getSetValuer()
            .calculateSetTokenValuation(_jasperVault, _reserveAsset);

        // Get reserve asset decimals
        uint256 reserveAssetDecimals = ERC20(_reserveAsset).decimals();
        uint256 normalizedTotalReserveQuantityNetFees = _netReserveFlows
            .preciseDiv(10 ** reserveAssetDecimals);
        uint256 normalizedTotalReserveQuantityNetFeesAndPremium = _netReserveFlows
                .sub(premiumValue)
                .preciseDiv(10 ** reserveAssetDecimals);

        // Calculate SetTokens to mint to issuer
        uint256 denominator = _setTotalSupply
            .preciseMul(setTokenValuation)
            .add(normalizedTotalReserveQuantityNetFees)
            .sub(normalizedTotalReserveQuantityNetFeesAndPremium);
        return
            normalizedTotalReserveQuantityNetFeesAndPremium
                .preciseMul(_setTotalSupply)
                .preciseDiv(denominator);
    }

    function _getRedeemReserveQuantity(
        IJasperVault _jasperVault,
        address _reserveAsset,
        uint256 _setTokenQuantity
    ) internal view returns (uint256) {
        // Get valuation of the SetToken with the quote asset as the reserve asset. Returns value in precise units (10e18)
        // Reverts if price is not found
        uint256 setTokenValuation = controller
            .getSetValuer()
            .calculateSetTokenValuation(_jasperVault, _reserveAsset);

        uint256 totalRedeemValueInPreciseUnits = _setTokenQuantity.preciseMul(
            setTokenValuation
        );
        // Get reserve asset decimals
        uint256 reserveAssetDecimals = ERC20(_reserveAsset).decimals();
        uint256 prePremiumReserveQuantity = totalRedeemValueInPreciseUnits
            .preciseMul(10 ** reserveAssetDecimals);

        uint256 premiumPercentage = _getPremium(
            _jasperVault,
            _reserveAsset,
            _setTokenQuantity
        );
        uint256 premiumQuantity = prePremiumReserveQuantity.preciseMulCeil(
            premiumPercentage
        );

        return prePremiumReserveQuantity.sub(premiumQuantity);
    }

    /**
     * The new position multiplier is calculated as follows:
     * inflationPercentage = (newSupply - oldSupply) / newSupply
     * newMultiplier = (1 - inflationPercentage) * positionMultiplier
     */
    function _getIssuePositionMultiplier(
        IJasperVault _jasperVault,
        ActionInfo memory _issueInfo
    ) internal view returns (uint256, int256) {
        // Calculate inflation and new position multiplier. Note: Round inflation up in order to round position multiplier down
        uint256 newTotalSupply = _issueInfo.setTokenQuantity.add(
            _issueInfo.previousSetTokenSupply
        );
        int256 newPositionMultiplier = _jasperVault
            .positionMultiplier()
            .mul(_issueInfo.previousSetTokenSupply.toInt256())
            .div(newTotalSupply.toInt256());

        return (newTotalSupply, newPositionMultiplier);
    }

    /**
     * Calculate deflation and new position multiplier. Note: Round deflation down in order to round position multiplier down
     *
     * The new position multiplier is calculated as follows:
     * deflationPercentage = (oldSupply - newSupply) / newSupply
     * newMultiplier = (1 + deflationPercentage) * positionMultiplier
     */
    function _getRedeemPositionMultiplier(
        IJasperVault _jasperVault,
        uint256 _setTokenQuantity,
        ActionInfo memory _redeemInfo
    ) internal view returns (uint256, int256) {
        uint256 newTotalSupply = _redeemInfo.previousSetTokenSupply.sub(
            _setTokenQuantity
        );
        int256 newPositionMultiplier = _jasperVault
            .positionMultiplier()
            .mul(_redeemInfo.previousSetTokenSupply.toInt256())
            .div(newTotalSupply.toInt256());

        return (newTotalSupply, newPositionMultiplier);
    }

    /**
     * The new position reserve asset unit is calculated as follows:
     * totalReserve = (oldUnit * oldSetTokenSupply) + reserveQuantity
     * newUnit = totalReserve / newSetTokenSupply
     */
    function _getIssuePositionUnit(
        IJasperVault _jasperVault,
        address _reserveAsset,
        ActionInfo memory _issueInfo
    ) internal view returns (uint256) {
        uint256 existingUnit = _jasperVault
            .getDefaultPositionRealUnit(_reserveAsset)
            .toUint256();
        uint256 totalReserve = existingUnit
            .preciseMul(_issueInfo.previousSetTokenSupply)
            .add(_issueInfo.netFlowQuantity);

        return totalReserve.preciseDiv(_issueInfo.newSetTokenSupply);
    }

    /**
     * The new position reserve asset unit is calculated as follows:
     * totalReserve = (oldUnit * oldSetTokenSupply) - reserveQuantityToSendOut
     * newUnit = totalReserve / newSetTokenSupply
     */
    function _getRedeemPositionUnit(
        IJasperVault _jasperVault,
        address _reserveAsset,
        ActionInfo memory _redeemInfo
    ) internal view returns (uint256) {
        uint256 existingUnit = _jasperVault
            .getDefaultPositionRealUnit(_reserveAsset)
            .toUint256();
        uint256 totalExistingUnits = existingUnit.preciseMul(
            _redeemInfo.previousSetTokenSupply
        );

        uint256 outflow = _redeemInfo
            .netFlowQuantity
            .add(_redeemInfo.protocolFees)
            .add(_redeemInfo.managerFee);

        // Require withdrawable quantity is greater than existing collateral
        require(
            totalExistingUnits >= outflow,
            "Must be greater than total available collateral"
        );

        return
            totalExistingUnits.sub(outflow).preciseDiv(
                _redeemInfo.newSetTokenSupply
            );
    }

    /**
     * If a pre-issue hook has been configured, call the external-protocol contract. Pre-issue hook logic
     * can contain arbitrary logic including validations, external function calls, etc.
     */
    function _callPreIssueHooks(
        IJasperVault _jasperVault,
        address _reserveAsset,
        uint256 _reserveAssetQuantity,
        address _caller,
        address _to
    ) internal {
        INAVIssuanceHook preIssueHook = navIssuanceSettings[_jasperVault]
            .managerIssuanceHook;
        if (address(preIssueHook) != address(0)) {
            preIssueHook.invokePreIssueHook(
                _jasperVault,
                _reserveAsset,
                _reserveAssetQuantity,
                _caller,
                _to
            );
        }
    }

    /**
     * If a pre-redeem hook has been configured, call the external-protocol contract.
     */
    function _callPreRedeemHooks(
        IJasperVault _jasperVault,
        uint256 _setQuantity,
        address _caller,
        address _to
    ) internal {
        INAVIssuanceHook preRedeemHook = navIssuanceSettings[_jasperVault]
            .managerRedemptionHook;
        if (address(preRedeemHook) != address(0)) {
            preRedeemHook.invokePreRedeemHook(
                _jasperVault,
                _setQuantity,
                _caller,
                _to
            );
        }
    }
}