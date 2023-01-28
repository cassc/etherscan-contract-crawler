// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.8;

import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "../interfaces/CrosschainFunctionCallInterface.sol";
import "../interfaces/IInsuranceFund.sol";
import {Errors} from "./libraries/helpers/Errors.sol";

contract FuturesGateway is
PausableUpgradeable,
OwnableUpgradeable,
ReentrancyGuardUpgradeable
{
    CrosschainFunctionCallInterface public futuresAdapter;
    IInsuranceFund public insuranceFund;
    uint256 public posiChainId;
    address public posiChainCrosschainGatewayContract;

    struct ManagerData {
        // fee = quoteAssetAmount / tollRatio (means if fee = 0.001% then tollRatio = 100000)
        uint24 takerTollRatio;
        uint24 makerTollRatio;
        uint40 baseBasicPoint;
        uint32 basicPoint;
        uint16 contractPrice;
        uint8 assetRfiPercent;
        // minimum order quantity in wei, input quantity must > minimumOrderQuantity
        uint80 minimumOrderQuantity;
        // minimum quantity = 0.001 then stepBaseSize = 1000
        uint32 stepBaseSize;
    }

    mapping(address => ManagerData) public positionManagerConfigData;

    enum Side {
        LONG,
        SHORT
    }

    enum SetTPSLOption {
        BOTH,
        ONLY_HIGHER,
        ONLY_LOWER
    }

    enum Method {
        OPEN_MARKET,
        OPEN_LIMIT,
        CANCEL_LIMIT,
        ADD_MARGIN,
        REMOVE_MARGIN,
        CLOSE_POSITION,
        INSTANTLY_CLOSE_POSITION,
        CLOSE_LIMIT_POSITION,
        CLAIM_FUND,
        SET_TPSL,
        UNSET_TP_AND_SL,
        UNSET_TP_OR_SL,
        OPEN_MARKET_BY_QUOTE
    }

    function initialize(
        address _futuresAdapter,
        address _posiChainCrosschainGatewayContract,
        uint256 _posiChainId,
        address _insuranceFund
    ) public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
        __Pausable_init();

        require(
            _posiChainCrosschainGatewayContract != address(0),
            Errors.VL_EMPTY_ADDRESS
        );
        require(_futuresAdapter != address(0), Errors.VL_EMPTY_ADDRESS);
        require(_insuranceFund != address(0), Errors.VL_EMPTY_ADDRESS);
        futuresAdapter = CrosschainFunctionCallInterface(_futuresAdapter);
        posiChainCrosschainGatewayContract = _posiChainCrosschainGatewayContract;
        posiChainId = _posiChainId;
        insuranceFund = IInsuranceFund(_insuranceFund);
    }

    function openMarketOrder(
        address _positionManager,
        Side _side,
        uint256 _quantity,
        uint16 _leverage,
        uint256 _depositedAmount
    ) public nonReentrant {
        validateOrderQuantity(_positionManager, _quantity);
        // TODO implement calculate fee based on leverage
        uint256 _fee = calcFeeBasedOnDepositAmount(
            _positionManager,
            _depositedAmount,
            _leverage,
        // false means this is not a limit order
            false
        );
        depositWithBonus(
            _positionManager,
            msg.sender,
            _depositedAmount,
            _fee,
            _leverage
        );
        futuresAdapter.crossBlockchainCall(
            posiChainId,
            posiChainCrosschainGatewayContract,
            uint8(Method.OPEN_MARKET),
            abi.encode(
                _positionManager,
                _side,
                _quantity,
                _leverage,
                msg.sender,
                _depositedAmount
            )
        );
    }

    function openLimitOrder(
        address _positionManager,
        Side _side,
        uint256 _uQuantity,
        uint128 _pip,
        uint16 _leverage,
        uint256 _depositedAmount
    ) public nonReentrant {
        validateOrderQuantity(_positionManager, _uQuantity);
        // TODO implement calculate fee based on leverage
        uint256 _fee = calcFeeBasedOnDepositAmount(
            _positionManager,
            _depositedAmount,
            _leverage,
        // true means this is a limit order
            true
        );
        depositWithBonus(
            _positionManager,
            msg.sender,
            _depositedAmount,
            _fee,
            _leverage
        );
        futuresAdapter.crossBlockchainCall(
            posiChainId,
            posiChainCrosschainGatewayContract,
            uint8(Method.OPEN_LIMIT),
            abi.encode(
                _positionManager,
                _side,
                _uQuantity,
                _pip,
                _leverage,
                msg.sender,
                _depositedAmount
            )
        );
    }

    function cancelLimitOrder(
        address _positionManager,
        uint64 _orderIdx,
        uint8 _isReduce
    ) external nonReentrant {
        futuresAdapter.crossBlockchainCall(
            posiChainId,
            posiChainCrosschainGatewayContract,
            uint8(Method.CANCEL_LIMIT),
            abi.encode(_positionManager, _orderIdx, _isReduce, msg.sender)
        );
    }

    function addMargin(address _positionManager, uint256 _amount)
    external
    nonReentrant
    {
        uint256 _depositAmount = calcDepositMargin(_positionManager, _amount);
        deposit(_positionManager, msg.sender, _depositAmount, 0);
        futuresAdapter.crossBlockchainCall(
            posiChainId,
            posiChainCrosschainGatewayContract,
            uint8(Method.ADD_MARGIN),
            abi.encode(_positionManager, _amount, msg.sender)
        );
    }

    function removeMargin(address _positionManager, uint256 _amount)
    external
    nonReentrant
    {
        futuresAdapter.crossBlockchainCall(
            posiChainId,
            posiChainCrosschainGatewayContract,
            uint8(Method.REMOVE_MARGIN),
            abi.encode(_positionManager, _amount, msg.sender)
        );
    }

    function closeMarketPosition(address _positionManager, uint256 _quantity)
    public
    nonReentrant
    {
        validateOrderQuantity(_positionManager, _quantity);
        futuresAdapter.crossBlockchainCall(
            posiChainId,
            posiChainCrosschainGatewayContract,
            uint8(Method.CLOSE_POSITION),
            abi.encode(_positionManager, _quantity, msg.sender)
        );
    }

    // @deprecated: Merge 2 function closeMarketPosition and instantlyClosePosition, bridge to the same function on posi chain
    // no different between 2 function closeMarketPosition and instantlyClosePosition
    function instantlyClosePosition(address _positionManager, uint256 _quantity)
    public
    nonReentrant
    {
        validateOrderQuantity(_positionManager, _quantity);
        futuresAdapter.crossBlockchainCall(
            posiChainId,
            posiChainCrosschainGatewayContract,
            uint8(Method.CLOSE_POSITION),
            abi.encode(_positionManager, _quantity, msg.sender)
        );
    }

    function closeLimitPosition(
        address _positionManager,
        uint128 _pip,
        uint256 _quantity
    ) public nonReentrant {
        validateOrderQuantity(_positionManager, _quantity);
        futuresAdapter.crossBlockchainCall(
            posiChainId,
            posiChainCrosschainGatewayContract,
            uint8(Method.CLOSE_LIMIT_POSITION),
            abi.encode(_positionManager, _pip, _quantity, msg.sender)
        );
    }

    function setTPSL(
        address _pmAddress,
        uint128 _higherPip,
        uint128 _lowerPip,
        SetTPSLOption _option
    ) external nonReentrant {
        futuresAdapter.crossBlockchainCall(
            posiChainId,
            posiChainCrosschainGatewayContract,
            uint8(Method.SET_TPSL),
            abi.encode(
                _pmAddress,
                msg.sender,
                _higherPip,
                _lowerPip,
                uint8(_option)
            )
        );
    }

    function unsetTPAndSL(address _pmAddress) external nonReentrant {
        futuresAdapter.crossBlockchainCall(
            posiChainId,
            posiChainCrosschainGatewayContract,
            uint8(Method.UNSET_TP_AND_SL),
            abi.encode(_pmAddress, msg.sender)
        );
    }

    function unsetTPOrSL(address _pmAddress, bool _isHigherPrice)
    external
    nonReentrant
    {
        futuresAdapter.crossBlockchainCall(
            posiChainId,
            posiChainCrosschainGatewayContract,
            uint8(Method.UNSET_TP_OR_SL),
            abi.encode(_pmAddress, msg.sender, _isHigherPrice)
        );
    }

    function claimFund(address _pmAddress) external nonReentrant {
        futuresAdapter.crossBlockchainCall(
            posiChainId,
            posiChainCrosschainGatewayContract,
            uint8(Method.CLAIM_FUND),
            abi.encode(_pmAddress, msg.sender)
        );
    }

    function calcFeeBasedOnDepositAmount(
        address _manager,
        uint256 _depositedAmount,
        uint256 _leverage,
        bool _isLimitOrder
    ) internal view returns (uint256 fee) {
        uint256 tollRatio;
        if (_isLimitOrder) {
            tollRatio = uint256(
                positionManagerConfigData[_manager].makerTollRatio
            );
        } else {
            tollRatio = uint256(
                positionManagerConfigData[_manager].takerTollRatio
            );
        }
        if (tollRatio != 0) {
            uint256 openNotional = _depositedAmount * _leverage;
            fee = openNotional / tollRatio;
        }
        return fee;
    }

    // Only use for testing
    function calcMarginAndFee(
        address _manager,
        uint256 _pQuantity,
        uint128 _pip,
        uint16 _leverage
    ) internal view returns (uint256 margin, uint256 fee) {
        uint256 notional = calcNotional(
            _manager,
            pipToPrice(_manager, _pip),
            _pQuantity
        );
        uint256 tollRatio = uint256(
            positionManagerConfigData[_manager].makerTollRatio
        );
        fee = 0;
        if (tollRatio != 0) {
            fee = notional / tollRatio;
        }
        margin = calcDepositMargin(_manager, notional / _leverage);
    }

    // Only use for testing
    function calcDepositMargin(address _manager, uint256 _margin)
    internal
    view
    returns (uint256)
    {
        // Calculate amount depend on RFI fee
        return
        (_margin * 100) /
        (100 - positionManagerConfigData[_manager].assetRfiPercent);
    }

    // Not used yet, only for coin-m
    function calcQuantity(address _manager, uint256 _quantity)
    internal
    view
    returns (uint256)
    {
        uint256 contractPrice = positionManagerConfigData[_manager]
        .contractPrice;
        if (contractPrice > 0) {
            return _quantity * contractPrice;
        }
        return _quantity;
    }

    // Only use for testing
    function calcNotional(
        address _manager,
        uint256 _price,
        uint256 _quantity
    ) internal view returns (uint256) {
        uint256 baseBasicPoint = positionManagerConfigData[_manager]
        .baseBasicPoint;
        // coin-m
        _quantity = calcQuantity(_manager, _quantity);
        if (positionManagerConfigData[_manager].contractPrice > 0) {
            return (_quantity * uint256(baseBasicPoint)) / _price;
        }
        //usd-m
        return (_quantity * _price) / uint256(baseBasicPoint);
    }

    function pipToPrice(address _manager, uint128 _pip)
    internal
    view
    returns (uint256)
    {
        return
        (uint256(_pip) *
        uint256(positionManagerConfigData[_manager].baseBasicPoint)) /
        uint256(positionManagerConfigData[_manager].basicPoint);
    }

    function deposit(
        address _manager,
        address _trader,
        uint256 _amount,
        uint256 _fee
    ) internal {
        insuranceFund.deposit(_manager, _trader, _amount, _fee);
    }

    function depositWithBonus(
        address _manager,
        address _trader,
        uint256 _amount,
        uint256 _fee,
        uint16 _leverage
    ) internal {
        (
        uint256 assetMarginWithoutFee,,
        uint256 bonusAssetMarginWithoutFee,
        bool isSufficientCollateral
        ) = insuranceFund.calculateBusdBonusAmount(
            _manager,
            _trader,
            _amount,
            _fee,
            _leverage * _amount
        );
        require(isSufficientCollateral, "Insufficient collateral, you need BUSD to open this order");
        insuranceFund.depositWithBonus(
            _manager,
            _trader,
            assetMarginWithoutFee,
            bonusAssetMarginWithoutFee,
            _fee
        );
    }

    function receiveFromOtherBlockchain(
        address _manager,
        address _trader,
        uint256 _amount
    ) external {
        require(msg.sender == address(futuresAdapter), "only futures adapter");
        insuranceFund.withdraw(_manager, _trader, _amount);
    }

    function liquidateAndDistributeReward(
        address _manager,
        address _liquidator,
        address _trader,
        uint256 _liquidatedBusdBonus,
        uint256 _liquidatorReward
    ) external {
        require(msg.sender == address(futuresAdapter), "only futures adapter");
        insuranceFund.liquidateAndDistributeReward(
            _manager,
            _liquidator,
            _trader,
            _liquidatedBusdBonus,
            _liquidatorReward
        );
    }

    function validateOrderQuantity(address _manager, uint256 _quantity)
    internal
    view
    {
        ManagerData memory managerConfigData = positionManagerConfigData[_manager];
        require(_quantity >= managerConfigData.minimumOrderQuantity, Errors.VL_INVALID_QUANTITY);
        if (managerConfigData.stepBaseSize != 0) {
            uint256 remainder = _quantity % (10**18 / managerConfigData.stepBaseSize);
            require(remainder == 0, Errors.VL_INVALID_QUANTITY);
        }
    }

    //******************************************************************************************************************
    // ONLY OWNER FUNCTIONS
    //******************************************************************************************************************

    function updateInsuranceFund(address _address) external onlyOwner {
        insuranceFund = IInsuranceFund(_address);
    }

    function setPositionManagerConfigData(
        address _positionManager,
        uint24 _takerTollRatio,
        uint24 _makerTollRatio,
        uint32 _basicPoint,
        uint40 _baseBasicPoint,
        uint16 _contractPrice,
        uint8 _assetRfiPercent,
        uint80 _minimumOrderQuantity,
        uint32 _stepBaseSize
    ) public onlyOwner {
        require(_positionManager != address(0), Errors.VL_EMPTY_ADDRESS);
        positionManagerConfigData[_positionManager]
        .takerTollRatio = _takerTollRatio;
        positionManagerConfigData[_positionManager]
        .makerTollRatio = _makerTollRatio;
        positionManagerConfigData[_positionManager].basicPoint = _basicPoint;
        positionManagerConfigData[_positionManager]
        .baseBasicPoint = _baseBasicPoint;
        positionManagerConfigData[_positionManager]
        .contractPrice = _contractPrice;
        positionManagerConfigData[_positionManager]
        .assetRfiPercent = _assetRfiPercent;
        positionManagerConfigData[_positionManager]
        .minimumOrderQuantity = _minimumOrderQuantity;
        positionManagerConfigData[_positionManager]
        .stepBaseSize = _stepBaseSize;
    }

    function updateManagerTakerTollRatio(
        address _positionManager,
        uint24 _takerTollRatio
    ) public onlyOwner {
        require(_positionManager != address(0), Errors.VL_EMPTY_ADDRESS);
        positionManagerConfigData[_positionManager]
        .takerTollRatio = _takerTollRatio;
    }

    function updateManagerMakerTollRatio(
        address _positionManager,
        uint24 _makerTollRatio
    ) public onlyOwner {
        require(_positionManager != address(0), Errors.VL_EMPTY_ADDRESS);
        positionManagerConfigData[_positionManager]
        .makerTollRatio = _makerTollRatio;
    }

    function setManagerBaseBasicPoint(
        address _positionManager,
        uint40 _baseBasicPoint
    ) public onlyOwner {
        require(_positionManager != address(0), Errors.VL_EMPTY_ADDRESS);
        positionManagerConfigData[_positionManager]
        .baseBasicPoint = _baseBasicPoint;
    }

    function setManagerBasicPoint(address _positionManager, uint32 _basicPoint)
    public
    onlyOwner
    {
        require(_positionManager != address(0), Errors.VL_EMPTY_ADDRESS);
        positionManagerConfigData[_positionManager].basicPoint = _basicPoint;
    }

    function setManagerContractPrice(
        address _positionManager,
        uint16 _contractPrice
    ) public onlyOwner {
        require(_positionManager != address(0), Errors.VL_EMPTY_ADDRESS);
        positionManagerConfigData[_positionManager]
        .contractPrice = _contractPrice;
    }

    function setManagerAssetRFI(
        address _positionManager,
        uint8 _assetRfiPercent
    ) public onlyOwner {
        require(_positionManager != address(0), Errors.VL_EMPTY_ADDRESS);
        positionManagerConfigData[_positionManager]
        .assetRfiPercent = _assetRfiPercent;
    }

    function setMinimumOrderQuantity(
        address _positionManager,
        uint80 _minimumOrderQuantity
    ) public onlyOwner {
        require(_positionManager != address(0), Errors.VL_EMPTY_ADDRESS);
        positionManagerConfigData[_positionManager]
        .minimumOrderQuantity = _minimumOrderQuantity;
    }

    function setStepBaseSize(
        address _positionManager,
        uint32 _stepBaseSize
    ) public onlyOwner {
        require(_positionManager != address(0), Errors.VL_EMPTY_ADDRESS);
        positionManagerConfigData[_positionManager]
        .stepBaseSize = _stepBaseSize;
    }

    function updateFuturesAdapterContract(address _futuresAdapterContract)
    external
    onlyOwner
    {
        require(_futuresAdapterContract != address(0), Errors.VL_EMPTY_ADDRESS);
        futuresAdapter = CrosschainFunctionCallInterface(
            _futuresAdapterContract
        );
    }

    function updatePosiChainId(uint256 _posiChainId) external onlyOwner {
        posiChainId = _posiChainId;
    }

    function updatePosiChainCrosschainGatewayContract(address _address)
    external
    onlyOwner
    {
        posiChainCrosschainGatewayContract = _address;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}