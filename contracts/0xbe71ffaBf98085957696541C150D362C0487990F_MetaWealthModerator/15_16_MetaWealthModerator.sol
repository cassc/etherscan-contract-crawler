/// SPDX-License-Identifier: None
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IMetaWealthModerator.sol";
import "./MetaWealthAccessControlled.sol";

contract MetaWealthModerator is
    MetaWealthAccessControlled,
    IMetaWealthModerator
{
    /// @notice List of supported currencies (name => address)
    mapping(address => bool) supportedCurrencies;

    /// @notice Active whitelist merkle root
    bytes32 public whitelistRoot;

    /// @notice MetaWealth platform's default currency
    address public override defaultCurrency;
    /// @notice Sets the default timestamp for when the assets can be defractionalized
    uint64 public override defaultUnlockPeriod; // 3-months
    uint32 public override exchangeFee;

    address public override treasuryWallet;
    uint32 public override fundraiseInvestorFee;
    uint32 public override fundraiseVendorFee;
    uint32 public override assetDepositShareholdersFee;

    /// @notice Array of all supported currencies to be fetched from outside
    address[] activeCurrencies;

    bytes32 public vendorWhitelistRoot;

    /// @notice Initialize exchange contract with necessary factories
    function initialize(
        address defaultCurrency_,
        bytes32 _initialRoot,
        bytes32 _initialVendorRoot
    ) public initializer {
        __RoleControl_init(_msgSender());
        defaultCurrency = defaultCurrency_;
        whitelistRoot = _initialRoot;
        vendorWhitelistRoot = _initialVendorRoot;
        defaultUnlockPeriod = 12 weeks;
        treasuryWallet = _msgSender();
        exchangeFee = 500;
        fundraiseInvestorFee = 290;
        fundraiseVendorFee = 175;
        assetDepositShareholdersFee = 500;

        emit CurrencySupportToggled(defaultCurrency, true, true);
        emit WhitelistRootUpdated("", whitelistRoot);
        emit UnlockPeriodChanged(0, defaultUnlockPeriod);
    }

    function isSupportedCurrency(
        address token
    ) external view override returns (bool) {
        return supportedCurrencies[token];
    }

    function setDefaultCurrency(
        address newCurrency
    ) external override onlyAdmin {
        emit CurrencySupportToggled(defaultCurrency, false, true);
        defaultCurrency = newCurrency;
        emit CurrencySupportToggled(defaultCurrency, true, true);
    }

    function toggleSupportedCurrency(
        address token
    ) external override onlyAdmin returns (bool newState) {
        supportedCurrencies[token] = !supportedCurrencies[token];
        newState = supportedCurrencies[token];

        if (!newState) {
            uint8 index;
            for (index = 0; index < activeCurrencies.length; index++) {
                if (activeCurrencies[index] == token) {
                    break;
                }
            }
            if (index != activeCurrencies.length) {
                activeCurrencies[index] = activeCurrencies[
                    activeCurrencies.length - 1
                ];
                activeCurrencies.pop();
            }
        } else {
            activeCurrencies.push(token);
        }

        emit CurrencySupportToggled(token, newState, false);
    }

    function getAllSupportedCurrencies()
        external
        view
        override
        returns (address[] memory)
    {
        return activeCurrencies;
    }

    function updateWhitelistRoot(bytes32 _newRoot) external override onlyAdmin {
        emit WhitelistRootUpdated(whitelistRoot, _newRoot);
        whitelistRoot = _newRoot;
    }

    function updateVendorWhitelistRoot(
        bytes32 _newRoot
    ) external override onlyAdmin {
        emit VendorWhitelistRootUpdated(vendorWhitelistRoot, _newRoot);
        vendorWhitelistRoot = _newRoot;
    }

    function checkWhitelist(
        bytes32[] calldata _merkleProof,
        address wallet
    ) public view override returns (bool) {
        if (whitelistRoot == "") {
            return true;
        }
        bytes32 leaf = keccak256(abi.encodePacked(wallet));
        return MerkleProof.verify(_merkleProof, whitelistRoot, leaf);
    }
    function checkVendorWhitelist(
        bytes32[] calldata _merkleProof,
        address wallet
    ) public view override returns (bool) {
        if (vendorWhitelistRoot == "") {
            return true;
        }
        bytes32 leaf = keccak256(abi.encodePacked(wallet));
        return MerkleProof.verify(_merkleProof, vendorWhitelistRoot, leaf);
    }

    function setDefaultUnlockPeriod(
        uint64 newPeriod
    ) external override onlyAdmin {
        emit UnlockPeriodChanged(defaultUnlockPeriod, newPeriod);
        defaultUnlockPeriod = newPeriod;
    }

    function setTreasuryWallet(
        address treasury
    ) external override onlySuperAdmin {
        treasuryWallet = treasury;
    }

    function setAssetDepositShareholdersFee(
        uint32 _fee
    ) external override onlyAdmin {
        assetDepositShareholdersFee = _fee;
    }

    function setExchangeFee(uint32 eFee) external override onlyAdmin {
        exchangeFee = eFee;
    }

    function setFundraiseVendorFee(uint32 _fee) external override onlyAdmin {
        fundraiseVendorFee = _fee;
    }

    function setFundraiseInvestorFee(uint32 _fee) external override onlyAdmin {
        fundraiseInvestorFee = _fee;
    }

    function calculateAssetDepositShareholdersFee(
        uint256 value
    ) public view override returns (uint256) {
        return _calculateFee(value, assetDepositShareholdersFee);
    }

    function calculateFundraiseVendorFee(
        uint256 value
    ) public view override returns (uint256) {
        return _calculateFee(value, fundraiseVendorFee);
    }

    function calculateFundraiseInvestorFee(
        uint256 value
    ) public view override returns (uint256) {
        return _calculateFee(value, fundraiseInvestorFee);
    }

    function calculateExchangeFee(
        uint256 value
    ) public view override returns (uint256) {
        return _calculateFee(value, exchangeFee);
    }

    function _calculateFee(
        uint256 value,
        uint32 _fee
    ) private pure returns (uint256) {
        return (value * _fee) / 10_000;
    }

    function version() public pure returns (string memory _version) {
        return "V2";
    }

    uint256[44] private __gap;
}