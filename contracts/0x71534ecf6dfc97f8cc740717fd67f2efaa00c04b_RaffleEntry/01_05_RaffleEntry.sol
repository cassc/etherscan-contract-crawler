// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error InvalidConstructorInputs();
error InvalidEntry();
error RaffleNotLive();
error PriceNotSet();
error AlreadyEnteredVariant();
error InsufficientFunds();
error InvalidRefund();
error FailedToRefund(address user);
error WithdrawFailed();

contract RaffleEntry is Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;

    enum ProductVariant {
        GOLD_PENDANT,
        SILVER_PENDANT,
        BLACK_HOODIE_XS,
        BLACK_HOODIE_S,
        BLACK_HOODIE_M,
        BLACK_HOODIE_L,
        BLACK_HOODIE_XL,
        BLACK_HOODIE_XXL,
        CLOUD_HOODIE_XS,
        CLOUD_HOODIE_S,
        CLOUD_HOODIE_M,
        CLOUD_HOODIE_L,
        CLOUD_HOODIE_XL,
        CLOUD_HOODIE_XXL
    }

    event EntryMade(ProductVariant indexed variant, address indexed sender);

    struct UserData {
        bool enteredGoldPendant;
        bool enteredSilverPendant;
        bool enteredBlackHoodie;
        bool enteredCloudHoodie;
        ProductVariant blackHoodieVariant;
        ProductVariant cloudHoodieVariant;
    }

    struct PriceInfo {
        uint256 silverPendant;
        uint256 goldPendant;
        uint256 hoodie;
    }

    uint256 public constant MAX_VARIANT_ENTRIES = 4;
    uint256 private constant NUM_VARIANTS = 14;

    bool public raffleLive;
    PriceInfo public priceInfo;
    EnumerableSet.AddressSet private _userSet;

    mapping(address => UserData) public userDataMap;
    mapping(ProductVariant => uint256) public raffleTotals;

    constructor(
        uint256 silverPendantPrice,
        uint256 goldPendantPrice,
        uint256 hoodiePrice
    ) {
        priceInfo = PriceInfo({
            silverPendant: silverPendantPrice,
            goldPendant: goldPendantPrice,
            hoodie: hoodiePrice
        });
    }

    function submitEntry(ProductVariant[] calldata variantIds)
        external
        payable
    {
        if (!raffleLive) {
            revert RaffleNotLive();
        }
        if (variantIds.length > MAX_VARIANT_ENTRIES) {
            revert InvalidEntry();
        }

        UserData memory userData = userDataMap[msg.sender];
        uint256 totalPrice = 0;

        for (uint256 i = 0; i < variantIds.length; ) {
            ProductVariant variantId = variantIds[i];
            uint256 variantPrice;

            if (variantId == ProductVariant.GOLD_PENDANT) {
                if (userData.enteredGoldPendant) {
                    revert AlreadyEnteredVariant();
                }
                variantPrice = priceInfo.goldPendant;
                userData.enteredGoldPendant = true;
            } else if (variantId == ProductVariant.SILVER_PENDANT) {
                if (userData.enteredSilverPendant) {
                    revert AlreadyEnteredVariant();
                }
                variantPrice = priceInfo.silverPendant;
                userData.enteredSilverPendant = true;
            } else if (uint256(variantId) >= 2 && uint256(variantId) <= 7) {
                if (userData.enteredBlackHoodie) {
                    revert AlreadyEnteredVariant();
                }
                variantPrice = priceInfo.hoodie;
                userData.enteredBlackHoodie = true;
                userData.blackHoodieVariant = variantId;
            } else {
                if (userData.enteredCloudHoodie) {
                    revert AlreadyEnteredVariant();
                }
                variantPrice = priceInfo.hoodie;
                userData.enteredCloudHoodie = true;
                userData.cloudHoodieVariant = variantId;
            }

            if (variantPrice == 0) {
                revert PriceNotSet();
            }

            emit EntryMade(variantId, msg.sender);

            unchecked {
                totalPrice += variantPrice;
                ++raffleTotals[variantId];
                ++i;
            }
        }

        if (msg.value < totalPrice) {
            revert InsufficientFunds();
        }

        userDataMap[msg.sender] = userData;
        _userSet.add(msg.sender);
    }

    // WARNING: this function should only be used off-chain due to an O(N) lookup
    function getUserList() external view returns (address[] memory) {
        uint256 length = _userSet.length();
        address[] memory userList = new address[](length);
        for (uint256 i; i < length; ++i) {
            userList[i] = _userSet.at(i);
        }
        return userList;
    }

    function getUserData(address user) external view returns (UserData memory) {
        UserData memory data = userDataMap[user];
        return data;
    }

    function getRaffleTotalValues() external view returns (uint256[] memory) {
        uint256[] memory values = new uint256[](NUM_VARIANTS);
        for (uint256 i = 0; i < NUM_VARIANTS; ++i) {
            values[i] = raffleTotals[ProductVariant(i)];
        }
        return values;
    }

    function setRaffleLive(bool value) external onlyOwner {
        raffleLive = value;
    }

    function setPrices(
        uint256 silverPendantPrice,
        uint256 goldPendantPrice,
        uint256 hoodiePrice
    ) external onlyOwner {
        priceInfo = PriceInfo({
            silverPendant: silverPendantPrice,
            goldPendant: goldPendantPrice,
            hoodie: hoodiePrice
        });
    }

    function refundUsers(address[] calldata users, uint256[] calldata amounts)
        external
        onlyOwner
        nonReentrant
    {
        if (users.length != amounts.length) {
            revert InvalidRefund();
        }
        for (uint256 i; i < users.length; ++i) {
            (bool sent, ) = users[i].call{value: amounts[i], gas: 30000}("");
            if (!sent) {
                revert FailedToRefund(users[i]);
            }
        }
    }

    function withdraw() external onlyOwner {
        (bool sent, ) = msg.sender.call{
            value: address(this).balance,
            gas: 30000
        }("");
        if (!sent) {
            revert WithdrawFailed();
        }
    }
}