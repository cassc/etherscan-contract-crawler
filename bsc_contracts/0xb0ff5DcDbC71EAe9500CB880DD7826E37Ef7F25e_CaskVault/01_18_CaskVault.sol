// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "@opengsn/contracts/src/BaseRelayRecipient.sol";


import "../interfaces/ICaskVault.sol";

contract CaskVault is
ICaskVault,
BaseRelayRecipient,
ERC20Upgradeable,
OwnableUpgradeable,
PausableUpgradeable,
ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20;

    modifier onlyProtocol {
        bool isProtocol = false;
        for (uint256 i = 0; i < protocols.length; i++) {
            if (_msgSender() == protocols[i]) {
                isProtocol = true;
                break;
            }
        }
        require(isProtocol, "!AUTH");
        _;
    }


    /************************** STATE **************************/

    address public reserved1;

    // base asset for vault - much is denominated in this
    address public baseAsset;

    // address of contract that collects and distributes fees
    address public feeDistributor;

    // assets supported by vault
    mapping(address => Asset) internal assets;
    address[] internal allAssets;

    // list of approved protocols that can perform payments
    address[] public protocols;

    // require deposit of at least this amount denominated in the baseAsset
    uint256 public minDeposit;

    // revert if price feed age is older than this number of seconds. set to 0 to disable check.
    uint256 public maxPriceFeedAge;

    // consumer funding profile
    mapping(address => FundingProfile) internal fundingProfiles;

    function initialize(
        address _baseAsset,
        address _baseAssetPriceFeed,
        address _feeDistributor
    ) public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __ERC20_init("Cask Vault Tokens","MASH");

        require(IERC20Metadata(_baseAsset).decimals() > 0, "!INVALID(baseAsset)");
        require(AggregatorV3Interface(_baseAssetPriceFeed).decimals() > 0, "!INVALID(baseAssetPriceFeed)");

        Asset storage asset = assets[_baseAsset];
        asset.priceFeed = _baseAssetPriceFeed;
        asset.assetDecimals = IERC20Metadata(_baseAsset).decimals();
        asset.priceFeedDecimals = AggregatorV3Interface(_baseAssetPriceFeed).decimals();
        asset.depositLimit = type(uint256).max;
        asset.slippageBps = 0;
        asset.allowed = true;
        allAssets.push(_baseAsset);

        baseAsset = _baseAsset;
        feeDistributor = _feeDistributor;
        minDeposit = 0;
        maxPriceFeedAge = 0;
    }
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function decimals() public view override(ERC20Upgradeable, IERC20MetadataUpgradeable) returns (uint8) {
        return IERC20Metadata(baseAsset).decimals();
    }

    function versionRecipient() public pure override returns(string memory) { return "2.2.0"; }

    function _msgSender() internal view override(ContextUpgradeable, BaseRelayRecipient)
    returns (address sender) {
        sender = BaseRelayRecipient._msgSender();
    }

    function _msgData() internal view override(ContextUpgradeable, BaseRelayRecipient)
    returns (bytes calldata) {
        return BaseRelayRecipient._msgData();
    }


    function protocolPayment(
        address _from,
        address _to,
        uint256 _value,
        uint256 _protocolFee,
        address _network,
        uint256 _networkFee
    ) external override nonReentrant onlyProtocol whenNotPaused {
        _protocolPayment(_from, _to, _value, _protocolFee, _network, _networkFee);
    }

    function protocolPayment(
        address _from,
        address _to,
        uint256 _value,
        uint256 _protocolFee
    ) external override nonReentrant onlyProtocol whenNotPaused {
        _protocolPayment(_from, _to, _value, _protocolFee, address(0), 0);
    }

    function protocolPayment(
        address _from,
        address _to,
        uint256 _value
    ) external override nonReentrant onlyProtocol whenNotPaused {
        _protocolPayment(_from, _to, _value, 0, address(0), 0);
    }

    function _protocolPayment(
        address _from,
        address _to,
        uint256 _value,
        uint256 _protocolFee,
        address _network,
        uint256 _networkFee
    ) internal {
        require(_value > _protocolFee + _networkFee, "!VALUE_TOO_LOW");

        FundingProfile memory profile = fundingProfiles[_from];

        if (profile.fundingSource == FundingSource.Personal) {
            uint256 assetAmount = _value;
            if (profile.fundingAsset != baseAsset) {
                Asset storage asset = assets[profile.fundingAsset];
                require(asset.allowed, "!NOT_ALLOWED(fundingAsset)");

                // convert to equivalent amount in specified asset and add slippage
                assetAmount = _convertPrice(baseAsset, profile.fundingAsset, _value);

                if (asset.slippageBps > 0) {
                    // the +1 is to fix underfunding due to decimal drops when the
                    // slippage is removed in the deposit
                    assetAmount = (assetAmount * 10000 / (10000 - asset.slippageBps)) + 1;
                }
            }
            _depositTo(_from, _from, profile.fundingAsset, assetAmount);
        } else {
            require(profile.fundingSource == FundingSource.Cask, "!INVALID(fundingSource)");
        }
        uint256 shares = _sharesForValue(_value);

        uint256 protocolFeeShares = 0;
        if (_protocolFee > 0) {
            protocolFeeShares = _sharesForValue(_protocolFee);
        }

        uint256 networkFeeShares = 0;
        if (_networkFee > 0 && _network != address(0)) {
            networkFeeShares = _sharesForValue(_networkFee);
        }

        _transfer(_from, _to, shares); // payment from consumer to provider

        if (protocolFeeShares > 0) {
            _transfer(_to, feeDistributor, protocolFeeShares); // take back fee from provider to fee distributor
        }
        if (networkFeeShares > 0) {
            _transfer(_to, _network, networkFeeShares); // take network fee from provider to network
        }

        emit Payment(_from, _to, _value, shares, _protocolFee, protocolFeeShares, _network,
            _networkFee, networkFeeShares);
    }

    function transferValue(
        address _recipient,
        uint256 _value
    ) external override nonReentrant whenNotPaused returns (bool) {
        uint256 amount = _sharesForValue(_value);
        _transfer(_msgSender(), _recipient, amount);
        emit TransferValue(_msgSender(), _recipient, _value, amount);
        return true;
    }

    function transferValueFrom(
        address _sender,
        address _recipient,
        uint256 _value
    ) external override nonReentrant whenNotPaused returns (bool) {
        uint256 amount = _sharesForValue(_value);
        _transfer(_sender, _recipient, amount);

        uint256 currentAllowance = allowance(_sender, _msgSender());
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(_sender, _msgSender(), currentAllowance - amount);
        }
        emit TransferValue(_sender, _recipient, _value, amount);
        return true;
    }

    function deposit(
        address _asset,
        uint256 _assetAmount
    ) external override nonReentrant whenNotPaused {
        _depositTo(_msgSender(), _msgSender(), _asset, _assetAmount);
    }

    function depositTo(
        address _to,
        address _asset,
        uint256 _assetAmount
    ) external override nonReentrant whenNotPaused {
        _depositTo(_msgSender(), _to, _asset, _assetAmount);
    }

    function _depositTo(
        address _assetFrom,
        address _sharesTo,
        address _asset,
        uint256 _assetAmount
    ) internal {
        require(assets[_asset].allowed, "!NOT_ALLOWED(asset)");
        require(_assetAmount > 0, "!INVALID(assetAmount)");
        require(_totalAssetBalance(_asset) + _assetAmount <= assets[_asset].depositLimit, "!DEPOSIT_LIMIT(asset)");

        uint256 baseAssetAmount = _assetAmount;
        if (_asset != baseAsset) {
            Asset storage asset = assets[_asset];

            // subtract slippage bps from deposited amount
            uint256 slippage = (_assetAmount * asset.slippageBps) / 10000;

            baseAssetAmount = _convertPrice(_asset, baseAsset, (_assetAmount - slippage));
        }

        require(baseAssetAmount >= minDeposit, "!MIN_DEPOSIT");

        // calculate shares before transferring new asset into vault
        uint256 shares = baseAssetAmount;
        if (totalSupply() > 0) {
            // use round up integer division so that deposits are not short changed
            shares = ((baseAssetAmount * totalSupply()) - 1) / _totalValue() + 1;
        }

        IERC20(_asset).safeTransferFrom(_assetFrom, address(this), _assetAmount);

        _mint(_sharesTo, shares);

        emit AssetDeposited(_sharesTo, _asset, _assetAmount, baseAssetAmount, shares);
    }

    function withdraw(
        address _asset,
        uint256 _shares
    ) external override nonReentrant whenNotPaused {
        _withdrawTo(_msgSender(), _asset, _shares);
    }

    function withdrawTo(
        address _recipient,
        address _asset,
        uint256 _shares
    ) external override nonReentrant whenNotPaused {
        _withdrawTo(_recipient, _asset, _shares);
    }

    function _withdrawTo(
        address _recipient,
        address _asset,
        uint256 _shares
    ) internal {
        require(assets[_asset].allowed, "!NOT_ALLOWED(asset)");
        require(_shares > 0, "!INVALID(sharesAmount)");

        // calculate amount before supply adjustment
        uint256 baseAmount = _shareValue(_shares);

        _burn(_msgSender(), _shares);

        uint256 assetAmount = baseAmount;
        if (_asset != baseAsset) {
            Asset storage asset = assets[_asset];

            assetAmount = _convertPrice(baseAsset, _asset, baseAmount);

            // subtract slippage bps from withdrawing amount
            uint256 slippage = (assetAmount * asset.slippageBps) / 10000;
            assetAmount = assetAmount - slippage;
        }

        // transfer requested stablecoin to _recipient
        IERC20(_asset).safeTransfer(_recipient, assetAmount);

        emit AssetWithdrawn(_recipient, _asset, assetAmount, baseAmount, _shares);
    }

    function currentValueOf(
        address _address
    ) external override view returns(uint256) {
        return _shareValue(balanceOf(_address));
    }

    function pricePerShare() external override view returns(uint256) {
        return _shareValue(10 ** assets[baseAsset].assetDecimals);
    }


    /************************** FUNDING SOURCE FUNCTIONS **************************/

    function fundingSource(
        address _address
    ) external view override returns(FundingProfile memory) {
        return fundingProfiles[_address];
    }

    function setFundingSource(
        FundingSource _fundingSource,
        address _fundingAsset
    ) external override {
        require(assets[_fundingAsset].allowed, "!ASSET_NOT_ALLOWED");

        FundingProfile storage profile = fundingProfiles[_msgSender()];

        profile.fundingSource = _fundingSource;
        profile.fundingAsset = _fundingAsset;

        emit SetFundingSource(_msgSender(), _fundingSource, _fundingAsset);
    }

    /************************** SHARES FUNCTIONS **************************/

    function sharesForValue(
        uint256 _value
    ) external override view returns(uint256) {
        return _sharesForValue(_value);
    }

    function _sharesForValue(
        uint256 _value
    ) internal view returns(uint256) {
        if (totalSupply() > 0) {
            return (_value * totalSupply()) / _totalValue();
        } else {
            return _value;
        }
    }

    function _shareValue(
        uint256 _shares
    ) internal view returns(uint256) {
        if (totalSupply() == 0) {
            return _shares;
        }
        return (_totalValue() * _shares) / totalSupply();
    }

    function totalValue() external override view returns(uint256) {
        return _totalValue();
    }
    function _totalValue() internal view returns(uint256) {
        uint256 total = 0;

        for (uint256 i = 0; i < allAssets.length; i++) {
            if (allAssets[i] == baseAsset) {
                total = total + _totalAssetBalance(baseAsset);
            } else {
                total = total + _convertPrice(allAssets[i], baseAsset, _totalAssetBalance(allAssets[i]));
            }
        }

        return total;
    }

    function totalAssetBalance(
        address _asset
    ) external override view returns(uint256) {
        return _totalAssetBalance(_asset);
    }
    function _totalAssetBalance(
        address _asset
    ) internal view returns(uint256) {
        return IERC20(_asset).balanceOf(address(this));
    }


    /************************** ADMIN FUNCTIONS **************************/

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function addProtocol(
        address _protocol
    ) external onlyOwner {
        protocols.push(_protocol);
        emit AddProtocol(_protocol);
    }

    function removeProtocol(
        address _protocol
    ) external onlyOwner {
        uint256 idx = protocols.length;
        for (uint256 i = 0; i < protocols.length; i++) {
            if (protocols[i] == _protocol) {
                idx = i;
                break;
            }
        }
        if (idx < protocols.length) {
            protocols[idx] = protocols[protocols.length - 1];
            protocols.pop();
        }
        emit RemoveProtocol(_protocol);
    }

    function protocolCount() external view returns(uint256) {
        return protocols.length;
    }

    function setFeeDistributor(
        address _feeDistributor
    ) external onlyOwner {
        feeDistributor = _feeDistributor;
        emit SetFeeDistributor(_feeDistributor);
    }

    function setMinDeposit(
        uint256 _minDeposit
    ) external onlyOwner {
        minDeposit = _minDeposit;
        emit SetMinDeposit(_minDeposit);
    }

    function setMaxPriceFeedAge(
        uint256 _maxPriceFeedAge
    ) external onlyOwner {
        maxPriceFeedAge = _maxPriceFeedAge;
        emit SetMaxPriceFeedAge(_maxPriceFeedAge);
    }

    function setTrustedForwarder(
        address _forwarder
    ) external onlyOwner {
        _setTrustedForwarder(_forwarder);
        emit SetTrustedForwarder(_forwarder);
    }


    /************************** ASSET FUNCTIONS **************************/

    function getBaseAsset() external view override returns(address) {
        return baseAsset;
    }

    function getAllAssets() external view override returns(address[] memory) {
        return allAssets;
    }

    function getAsset(
        address _asset
    ) external view override returns(Asset memory) {
        return assets[_asset];
    }

    function supportsAsset(
        address _asset
    ) external view override returns (bool) {
        return assets[_asset].allowed;
    }

    function allowAsset(
        address _asset,
        address _priceFeed,
        uint256 _depositLimit,
        uint256 _slippageBps
    ) external onlyOwner {
        require(IERC20Metadata(_asset).decimals() > 0, "!INVALID(asset)");
        require(AggregatorV3Interface(_priceFeed).decimals() > 0, "!INVALID(priceFeed)");

        Asset storage asset = assets[_asset];

        // add to allAsset list just the first time
        if (asset.assetDecimals == 0) {
            allAssets.push(_asset);
        }

        asset.allowed = true;
        asset.priceFeed = _priceFeed;
        asset.depositLimit = _depositLimit;
        asset.slippageBps = _slippageBps;
        asset.assetDecimals = IERC20Metadata(_asset).decimals();
        asset.priceFeedDecimals = AggregatorV3Interface(_priceFeed).decimals();

        emit AllowedAsset(_asset);
    }

    function disallowAsset(
        address _asset
    ) external onlyOwner {
        require(assets[_asset].allowed, "!ASSET_NOT_ALLOWED");

        assets[_asset].allowed = false;

        emit DisallowedAsset(_asset);
    }

    function convertPrice(
        address _fromAsset,
        address _toAsset,
        uint256 _fromAmount
    ) external view returns(uint256) {
        return _convertPrice(_fromAsset, _toAsset, _fromAmount);
    }

    function _convertPrice(
        address _fromAsset,
        address _toAsset,
        uint256 _fromAmount
    ) internal view returns(uint256) {
        require(_fromAsset != _toAsset, "!SAME_ASSET");
        require(assets[_fromAsset].priceFeed != address(0), "!INVALID(fromAsset)");
        require(assets[_toAsset].priceFeed != address(0), "!NOT_ALLOWED(toAsset)");

        if (_fromAmount == 0) {
            return 0;
        }

        int256 oraclePrice;
        uint256 updatedAt;

        ( , oraclePrice, , updatedAt, ) = AggregatorV3Interface(assets[_fromAsset].priceFeed).latestRoundData();
        uint256 fromOraclePrice = uint256(oraclePrice);
        require(maxPriceFeedAge == 0 || block.timestamp - updatedAt <= maxPriceFeedAge, "!PRICE_OUTDATED");
        ( , oraclePrice, , updatedAt, ) = AggregatorV3Interface(assets[_toAsset].priceFeed).latestRoundData();
        uint256 toOraclePrice = uint256(oraclePrice);
        require(maxPriceFeedAge == 0 || block.timestamp - updatedAt <= maxPriceFeedAge, "!PRICE_OUTDATED");

        if (assets[_fromAsset].priceFeedDecimals != assets[_toAsset].priceFeedDecimals) {
            // since oracle precision is different, scale everything
            // to _toAsset precision and do conversion
            return _scalePrice(_fromAmount, assets[_fromAsset].assetDecimals, assets[_toAsset].assetDecimals) *
                    _scalePrice(fromOraclePrice, assets[_fromAsset].priceFeedDecimals, assets[_toAsset].assetDecimals) /
                    _scalePrice(toOraclePrice, assets[_toAsset].priceFeedDecimals, assets[_toAsset].assetDecimals);
        } else {
            // oracles are already in same precision, so just scale _amount to asset precision,
            // and multiply by the price feed ratio
            return _scalePrice(_fromAmount, assets[_fromAsset].assetDecimals, assets[_toAsset].assetDecimals) *
                fromOraclePrice / toOraclePrice;
        }
    }

    function _scalePrice(
        uint256 _price,
        uint8 _priceDecimals,
        uint8 _decimals
    ) internal pure returns (uint256){
        if (_priceDecimals < _decimals) {
            return _price * uint256(10 ** uint256(_decimals - _priceDecimals));
        } else if (_priceDecimals > _decimals) {
            return _price / uint256(10 ** uint256(_priceDecimals - _decimals));
        }
        return _price;
    }

}