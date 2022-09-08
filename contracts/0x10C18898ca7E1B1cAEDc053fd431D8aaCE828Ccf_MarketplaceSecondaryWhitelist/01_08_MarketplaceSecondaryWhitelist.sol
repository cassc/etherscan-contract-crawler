// SPDX-License-Identifier: ISC
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IMarketplaceSecondaryWhitelist.sol";

contract MarketplaceSecondaryWhitelist is Ownable, IMarketplaceSecondaryWhitelist {
    mapping (address => bool) public deployersCollection;

    modifier onlyDeployers() {
        require(deployersCollection[msg.sender] == true || msg.sender == owner(), "CollectionMinterRoyaltyFactory: only deployers or owner can call this function");
        _;
    }
  function addDeployers(address _address) external onlyOwner {
        require(deployersCollection[_address] == false, "CollectionMinterRoyaltyFactory: address already added");

        deployersCollection[_address] = true;
    }

    function removeDeployers(address _address) external onlyOwner {
        require(deployersCollection[_address] == true, "CollectionMinterRoyaltyFactory: address not already added");

        deployersCollection[_address] = false;
    }
    // ERC721 assets variables
    mapping (address => bool) public override is721Whitelisted;
    address[] whitelisted721Collections;

    // ERC1155 assets variables
    mapping (address => bool) public override is1155Whitelisted;
    address[] whitelisted1155Collections;

    // Payment tokens
    // NOTE: 0x00000... means BNB
    mapping (address => bool) public override isPaymentTokenWhitelisted;
    address[] public whitelistedPaymentTokens;

    /**
     * @notice Constructor
     */
    constructor () {
        // Whitelist BNB
        isPaymentTokenWhitelisted[address(0)] = true;
        whitelistedPaymentTokens.push(address(0));
    }

    /**
     * @notice Returns the list of whitelisted ERC721 collections
     */
    function getWhitelistedCollections721() external view override returns (address[] memory) {
        return whitelisted721Collections;
    }

    /**
     * @notice Returns the list of whitelisted ERC1155 collections
     */
    function getWhitelistedCollections1155() external view override returns (address[] memory) {
        return whitelisted1155Collections;
    }

    // PRIVILEGED METHODS
    /**
     * @notice Add collection to whitelist
     * @param _token Token to whitelist
     * @param _is721 True if the collections is an ERC721, false if it is an ERC1155
     */
    function addCollectionToWhitelist(address _token, bool _is721) external onlyDeployers {
        if (_is721) {
            require (! is721Whitelisted[_token], "MarketplaceWhitelist: Collection already whitelisted");
            is721Whitelisted[_token] = true;

            whitelisted721Collections.push(_token);
        } else {
            require (! is1155Whitelisted[_token], "MarketplaceWhitelist: Collection already whitelisted");
            is1155Whitelisted[_token] = true;

            whitelisted1155Collections.push(_token);
        }
    }

    /**
     * @notice Remove collection to whitelist
     * @param _index Index of the collection to remove
     * @param _is721 True if the collections is an ERC721, false if it is an ERC1155
     */
    function removeCollectionToWhitelist(uint _index, bool _is721) external onlyDeployers {
        address token;

        if (_is721) {
            require (_index < whitelisted721Collections.length, "MarketplaceWhitelist: Invalid index");
            token = whitelisted721Collections[_index];

            is721Whitelisted[token] = false;

            if (whitelisted721Collections.length == 1) {
                delete whitelisted721Collections;
            } else {
                uint last = whitelisted721Collections.length - 1;

                delete whitelisted721Collections[_index];
                whitelisted721Collections[_index] = whitelisted721Collections[last];
                delete whitelisted721Collections[last];
            }

        } else {
            require (_index < whitelisted1155Collections.length, "MarketplaceWhitelist: Invalid index");
            token = whitelisted1155Collections[_index];

            is1155Whitelisted[token] = false;

            if (whitelisted1155Collections.length == 1) {
                delete whitelisted1155Collections;
            } else {
                uint last = whitelisted1155Collections.length - 1;

                delete whitelisted1155Collections[_index];
                whitelisted1155Collections[_index] = whitelisted1155Collections[last];
                delete whitelisted1155Collections[last];
            }
        }
    }

    /**
     * @notice Add payment token to whitelist
     * @param _token Tokent to whitelist
     */
    function addPaymentTokenToWhitelist(address _token) external override onlyDeployers {
        require (! isPaymentTokenWhitelisted[_token], "MarketplaceWhitelist: Payment token already whitelisted");
        isPaymentTokenWhitelisted[_token] = true;

        whitelistedPaymentTokens.push(_token);
    }

    /**
     * @notice Remove payment token to whitelist
     * @param _index Index of the token to remove from whitelist
     */
    function removePaymentTokenToWhitelist(uint _index) external override onlyDeployers {
        require (_index < whitelistedPaymentTokens.length, "MarketplaceWhitelist: Invalid index");
        address token = whitelistedPaymentTokens[_index];

        isPaymentTokenWhitelisted[token] = false;

        if (whitelistedPaymentTokens.length == 1) {
            delete whitelistedPaymentTokens;
        } else {
            uint last = whitelistedPaymentTokens.length - 1;

            delete whitelistedPaymentTokens[_index];
            whitelistedPaymentTokens[_index] = whitelistedPaymentTokens[last];
            delete whitelistedPaymentTokens[last];
        }
    }

    /**
     * @notice Return the list of whitelisted payment tokens
     */
    function getWhitelistedPaymentTokens() external view override returns (address[] memory) {
        return whitelistedPaymentTokens;
    }
}