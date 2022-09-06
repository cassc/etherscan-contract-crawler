// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PullPaymentUpgradeable.sol";
import "./mondo-megabits.sol";

contract MondoMarketplace is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PullPaymentUpgradeable,
    UUPSUpgradeable
{
    MondoTokens _mondoTokensContract;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address mondoTokensAddress) public payable initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __PullPayment_init();
        __UUPSUpgradeable_init();

        _mondoTokensContract = MondoTokens(mondoTokensAddress);
    }

    /* ----------------------------------------- EVENTS ----------------------------------------- */
    event TokenForSale(uint256 id, address owner, uint256 price);
    event TokenSaleCancelled(uint256 id, address owner, uint256 price);
    event TokenSold(uint256 id, address soldBy, uint256 price, address soldTo);

    /* ========================================================================================== */
    /*                                      SALE INFORMATION                                      */
    /* ========================================================================================== */

    // [tokenID][owner] -> uint256[] Prices
    mapping(uint256 => mapping(address => uint256[])) private _forSalePrices;

    // Returns the length of the array of prices for a given tokenID and owner.
    function getForSaleCount(uint256 tokenID, address owner) external view returns (uint256) {
        return _forSalePrices[tokenID][owner].length;
    }

    /* ========================================================================================== */
    /*                                  MARKETPLACE FUNCTIONALITY                                 */
    /* ========================================================================================== */

    function putUpForSale(uint256 id, uint256 price) external {
        require(price > 0, "Price isn't >0");
        require(
            _mondoTokensContract.balanceOf(_msgSender(), id) > _forSalePrices[id][_msgSender()].length,
            "None to sell"
        );

        _forSalePrices[id][_msgSender()].push(price);

        emit TokenForSale(id, _msgSender(), price);
    }

    function cancelSaleToTransfer(
        address owner,
        uint256 id,
        uint8 count
    ) external {
        require(_msgSender() == address(_mondoTokensContract));

        uint8 amountForSale = uint8(_forSalePrices[id][owner].length);
        require(count > 0 && count <= amountForSale, "Invalid amount to cancel");

        for (uint8 i = 0; i < count; i++) {
            uint256 price = _forSalePrices[id][owner][_forSalePrices[id][owner].length - 1];
            emit TokenSaleCancelled(id, owner, price);
        }
    }

    function cancelSale(uint256 id, uint256 price) external {
        require(removeFromSale(id, _msgSender(), price));
        emit TokenSaleCancelled(id, _msgSender(), price);
    }

    function removeFromSale(
        uint256 id,
        address owner,
        uint256 price
    ) private returns (bool) {
        uint8 salesLength = uint8(_forSalePrices[id][owner].length);
        require(salesLength > 0, "None for sale!");

        if (salesLength == 1) {
            if (price == _forSalePrices[id][owner][0]) {
                _forSalePrices[id][owner].pop();
                return true;
            } else {
                revert("Price doesn't match");
            }
        } else {
            uint8 priceIdx;
            bool priceIdxFound = false;
            for (uint8 i = 0; i < salesLength; ++i) {
                if (_forSalePrices[id][owner][i] == price) {
                    priceIdxFound = true;
                    priceIdx = i;
                    break;
                }
            }
            require(priceIdxFound, "Price not found");

            uint16 lastIdx = salesLength - 1;

            // Pop and swap:
            if (priceIdx == lastIdx) {
                _forSalePrices[id][owner].pop();
            } else {
                _forSalePrices[id][owner][priceIdx] = _forSalePrices[id][owner][lastIdx];
                _forSalePrices[id][owner].pop();
            }
            return true;
        }
    }

    function buy(uint256 id, address owner) external payable nonReentrant {
        uint256 price = (_mondoTokensContract.ROYALTY_DIVISOR() * msg.value) /
            (_mondoTokensContract.ROYALTY_DIVISOR() + 1); // price without royalties
        require(price > 0);

        uint8 salesLength = uint8(_forSalePrices[id][owner].length);
        require(salesLength > 0, "None for sale!");

        removeFromSale(id, owner, price);

        emit TokenSold(id, owner, price, _msgSender());

        // pay the seller
        _asyncTransfer(owner, price);

        // transfer token to the buyer
        _mondoTokensContract.safeTransferFrom(owner, _msgSender(), id, 1, "");
    }

    /* ============================================================================================================== */
    /*                                          ADMINISTRATIVE FUNCTIONALITY                                          */
    /* ============================================================================================================== */

    // For transferring all Eth to the owner.
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = _msgSender().call{value: balance}("");
        require(success, "Failed to send Ether");
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override(UUPSUpgradeable) onlyOwner {}
}