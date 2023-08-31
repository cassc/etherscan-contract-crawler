//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin-norm/contracts/access/Ownable.sol";
import "@openzeppelin-norm/contracts/security/Pausable.sol";
import "@openzeppelin-norm/contracts/utils/Address.sol";
import "../interfaces/sellerFinancing/ISellerFinancing.sol";
import "../interfaces/sanctions/SanctionsList.sol";

/// @title MarketplaceIntegration
/// @custom:version 1.0
/// @author zishansami102 (zishansami.eth)
/// @custom:contributor captnseagraves (captnseagraves.eth)

contract MarketplaceIntegration is Ownable, Pausable {
    using Address for address payable;

    /// @dev Internal constant address for the Chainalysis OFAC sanctions oracle
    address private constant SANCTIONS_CONTRACT = 0x40C57923924B5c5c5455c48D93317139ADDaC8fb;

    /// @notice The base value for fees in the protocol.
    uint256 private constant BASE_BPS = 10_000;

    /// @dev The status of sanctions checks
    bool internal _sanctionsPause;

    uint256 public marketplaceFeeBps;

    address payable public marketplaceFeeRecipient;

    address public sellerFinancingContractAddress;

    error ZeroAddress();

    error InsufficientMsgValue(uint256 given, uint256 expected);

    error SanctionedAddress(address account);

    constructor(
        address _sellerFinancingContractAddress,
        address _marketplaceFeeRecipient,
        uint256 _marketplaceFeeBps
    ) {
        _requireNonZeroAddress(_sellerFinancingContractAddress);
        _requireNonZeroAddress(_marketplaceFeeRecipient);

        sellerFinancingContractAddress = _sellerFinancingContractAddress;
        marketplaceFeeRecipient = payable(_marketplaceFeeRecipient);
        marketplaceFeeBps = _marketplaceFeeBps;
    }

    /// @param newSellerFinancingContractAddress New address for SellerFinancing contract
    function updateSellerFinancingContractAddress(
        address newSellerFinancingContractAddress
    ) external onlyOwner {
        _requireNonZeroAddress(newSellerFinancingContractAddress);
        sellerFinancingContractAddress = newSellerFinancingContractAddress;
    }

    /// @param newMarketplaceFeeRecipient New address for MarketplaceFeeRecipient
    function updateMarketplaceFeeRecipient(address newMarketplaceFeeRecipient) external onlyOwner {
        _requireNonZeroAddress(newMarketplaceFeeRecipient);
        marketplaceFeeRecipient = payable(newMarketplaceFeeRecipient);
    }

    /// @param newMarketplaceFeeBps New value for marketplaceFeeBps
    function updateMarketplaceFeeBps(uint256 newMarketplaceFeeBps) external onlyOwner {
        marketplaceFeeBps = newMarketplaceFeeBps;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function pauseSanctions() external onlyOwner {
        _sanctionsPause = true;
    }

    function unpauseSanctions() external onlyOwner {
        _sanctionsPause = false;
    }

    function buyWithFinancing(
        ISellerFinancing.Offer memory offer,
        bytes calldata signature,
        address buyer,
        uint256 nftId
    ) external payable whenNotPaused {
        _requireIsNotSanctioned(msg.sender);
        _requireIsNotSanctioned(buyer);

        uint256 marketplaceFeeAmount = (offer.price * marketplaceFeeBps) / BASE_BPS;
        if (msg.value < offer.downPaymentAmount + marketplaceFeeAmount) {
            revert InsufficientMsgValue(msg.value, offer.downPaymentAmount + marketplaceFeeAmount);
        }
        marketplaceFeeRecipient.sendValue(marketplaceFeeAmount);

        ISellerFinancing(sellerFinancingContractAddress).buyWithFinancing{
            value: msg.value - marketplaceFeeAmount
        }(offer, signature, buyer, nftId);
    }

    function _requireNonZeroAddress(address given) internal pure {
        if (given == address(0)) {
            revert ZeroAddress();
        }
    }

    function _requireIsNotSanctioned(address addressToCheck) internal view {
        if (!_sanctionsPause) {
            SanctionsList sanctionsList = SanctionsList(SANCTIONS_CONTRACT);
            bool isToSanctioned = sanctionsList.isSanctioned(addressToCheck);
            if (isToSanctioned) {
                revert SanctionedAddress(addressToCheck);
            }
        }
    }
}