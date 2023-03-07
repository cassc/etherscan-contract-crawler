// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract XaveMarket is AccessControlEnumerable, ReentrancyGuard, ERC1155Holder {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    bytes32 public constant NFT_ADMIN = keccak256("NFT_ADMIN");
    bytes32 public constant WITHDRAW = keccak256("WITHDRAW");

    error TokenIdAlreadyListed(uint256 tokenId);
    error TokenIdNotListed(uint256 tokenId);
    error TokenIdHasNoOverridenPrice(uint256 tokenId);
    error CurrencyNotListedAsValid(address currency);

    event AddedOrRemovedFromMarket(bool isAdd, address nft, uint256[] tokenIds);
    event NftPurchased(
        address indexed _from,
        address indexed _ERC721,
        uint256[] _tokenIds,
        address _currency,
        uint256 _totalSpent
    );

    modifier onlyIfNftExists(address nft) {
        require(_nftSet.contains(nft), "Nft contract not found");
        _;
    }

    modifier onlyIfCurrencyExists(address currency) {
        require(_validCurrenciesSet.contains(currency), "Currency not found");
        _;
    }

    struct PurchaseKey {
        address erc1155;
        uint256 tokenId;
        uint256 amount;
    }

    // Limit de amount of nftTokens per purchase
    uint256 public maxTokenPurchase = 25;

    // Set of nfts
    EnumerableSet.AddressSet private _nftSet;

    // Set of accepted currencies
    EnumerableSet.AddressSet private _validCurrenciesSet;

    // nftContract => tokenId => listed
    mapping(address => EnumerableSet.UintSet) private _listedTokens;

    // nftContract => currencyAddress => price
    mapping(address => mapping(address => uint256)) private _defaultPrices;

    // nftContract => currencyAddress => tokenId=> price
    mapping(address => mapping(address => mapping(uint256 => uint256)))
        private _overridenPrices;

    // nftContract => tokenId => PurchaseKey
    mapping(address => mapping(uint256 => PurchaseKey)) private _purchaseKeys;

    // Set of erc1155 where address(this) owns one or more tokens (purchase keys)
    EnumerableSet.AddressSet private _erc1155Balance;

    // erc1155 => tokenIds owned
    mapping(address => EnumerableSet.UintSet) private _erc1155TokenIdBalance;

    constructor(address[] memory _validCurrencies) {
        require(_validCurrencies.length > 0, "validCurrencies cannot be empty");
        for (uint256 i = 0; i < _validCurrencies.length; i++) {
            require(
                isContract(_validCurrencies[i]),
                "Invalid currency address"
            );
            _validCurrenciesSet.add(_validCurrencies[i]);
        }

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function buyToken(
        address _nft,
        uint256[] calldata _tokenIds,
        address _currency
    )
        external
        onlyIfNftExists(_nft)
        onlyIfCurrencyExists(_currency)
        nonReentrant
    {
        require(_tokenIds.length > 0, "_tokenIds cannot be empty");
        require(
            _tokenIds.length <= maxTokenPurchase,
            "Cannot exceed the max amount of tokens"
        );

        address currency = _currency;
        address nft = _nft;
        address sender = msg.sender;
        uint256 totalAmount;
        IERC721 erc721 = IERC721(nft);

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];

            if (!_listedTokens[nft].contains(tokenId)) {
                revert TokenIdNotListed({tokenId: _tokenIds[i]});
            }

            uint256 price = _overridenPrices[nft][currency][tokenId];
            if (price == 0) {
                price = _defaultPrices[nft][currency];
            }
            require(price > 0, "No price found for currency");

            totalAmount += price;

            // remove from listing
            _listedTokens[nft].remove(tokenId);

            // Is erc1155 needed to make the purchase?
            PurchaseKey storage purchaseKey = _purchaseKeys[nft][tokenId];
            if (purchaseKey.erc1155 != address(0)) {
                IERC1155 erc1155 = IERC1155(purchaseKey.erc1155);
                require(
                    erc1155.balanceOf(sender, purchaseKey.tokenId) >
                        purchaseKey.amount,
                    "Need purchaseKey to buy this tokenId"
                );

                // Add tokenId to the list of erc1155 balance
                _erc1155Balance.add(purchaseKey.erc1155);
                _erc1155TokenIdBalance[purchaseKey.erc1155].add(
                    purchaseKey.tokenId
                );

                // Remove purchaseKey
                purchaseKey.erc1155 = address(0);

                // Transfer tokens of erc1155
                erc1155.safeTransferFrom(
                    sender,
                    address(this),
                    purchaseKey.tokenId,
                    purchaseKey.amount,
                    "0x0"
                );
            }

            // transfer tokenId from owner to sender
            address tokenOwner = erc721.ownerOf(tokenId);
            erc721.safeTransferFrom(tokenOwner, sender, tokenId);
        }

        IERC20 erc20 = IERC20(currency);

        // transfer (currency) from sender to this contract
        erc20.transferFrom(sender, address(this), totalAmount);

        emit NftPurchased(sender, nft, _tokenIds, currency, totalAmount);
        emit AddedOrRemovedFromMarket(false, nft, _tokenIds);
    }

    function getPrices(address nft, uint256 tokenId)
        external
        view
        onlyIfNftExists(nft)
        returns (address[] memory currencies, uint256[] memory amounts)
    {
        require(_validCurrenciesSet.length() > 0, "Not currencies found");
        require(_listedTokens[nft].contains(tokenId), "TokenId not listed");

        currencies = _validCurrenciesSet.values();
        amounts = new uint256[](currencies.length);
        for (uint256 i = 0; i < currencies.length; i++) {
            if (_overridenPrices[nft][currencies[i]][tokenId] > 0) {
                //overriden price
                amounts[i] = _overridenPrices[nft][currencies[i]][tokenId];
            } else {
                //default price
                amounts[i] = _defaultPrices[nft][currencies[i]];
            }
        }
    }

    function getPurchaseKey(address nft, uint256 tokenId)
        external
        view
        onlyIfNftExists(nft)
        returns (PurchaseKey memory)
    {
        return _purchaseKeys[nft][tokenId];
    }

    function addValidCurrency(address currency) external onlyRole(NFT_ADMIN) {
        require(isContract(currency), "Invalid currency address");
        require(
            !_validCurrenciesSet.contains(currency),
            "Currency already exists"
        );
        _validCurrenciesSet.add(currency);
    }

    function removeValidCurrency(address currency)
        external
        onlyRole(NFT_ADMIN)
        onlyIfCurrencyExists(currency)
    {
        require(
            IERC20(currency).balanceOf(address(this)) == 0,
            "Need to withdraw balance"
        );
        _validCurrenciesSet.remove(currency);
    }

    function addNftWithPrices(
        address nft,
        address[] calldata currency,
        uint256[] calldata amounts
    ) external onlyRole(NFT_ADMIN) {
        addNft(nft);
        addDefaultPrice(nft, currency, amounts);
    }

    function addNft(address nft) public onlyRole(NFT_ADMIN) {
        require(isContract(nft), "Invalid nft address");
        require(!_nftSet.contains(nft), "Nft already exists");
        _nftSet.add(nft);
    }

    //Also removes all default prices
    function removeNft(address nft)
        external
        onlyRole(NFT_ADMIN)
        onlyIfNftExists(nft)
    {
        address[] memory emptyCurrencies;
        //Will not remove nft/defaultPrice if it has listed tokens
        _removeDefaultPrice(nft, emptyCurrencies, true);

        _nftSet.remove(nft);
    }

    function addDefaultPrice(
        address nft,
        address[] calldata currency,
        uint256[] calldata amounts
    ) public onlyRole(NFT_ADMIN) onlyIfNftExists(nft) {
        require(currency.length > 0, "currencyToken cannot be empty");
        require(
            currency.length == amounts.length,
            "currency and amounts must be the same size"
        );
        for (uint256 i = 0; i < currency.length; i++) {
            require(amounts[i] > 0, "Amount cannot be 0");
            if (!_validCurrenciesSet.contains(currency[i])) {
                revert CurrencyNotListedAsValid({currency: currency[i]});
            }
            _defaultPrices[nft][currency[i]] = amounts[i];
        }
    }

    function defaulPrice(address nft, address currency)
        external
        view
        onlyRole(NFT_ADMIN)
        onlyIfNftExists(nft)
        onlyIfCurrencyExists(currency)
        returns (uint256)
    {
        return _defaultPrices[nft][currency];
    }

    function removeDefaultPrice(address nft, address[] memory currencies)
        external
        onlyRole(NFT_ADMIN)
        onlyIfNftExists(nft)
    {
        _removeDefaultPrice(nft, currencies, false);
    }

    function removeAllDefaultPrices(address nft)
        external
        onlyRole(NFT_ADMIN)
        onlyIfNftExists(nft)
    {
        address[] memory emptyCurrencies;
        _removeDefaultPrice(nft, emptyCurrencies, true);
    }

    function _removeDefaultPrice(
        address nft,
        address[] memory currencies,
        bool removeAll
    ) private {
        require(
            _listedTokens[nft].length() == 0,
            "Nft has tokens listed for sale"
        );

        if (!removeAll) {
            require(currencies.length > 0, "currency[] cannot be empty");
        } else {
            currencies = _validCurrenciesSet.values();
        }

        for (uint256 i = 0; i < currencies.length; i++) {
            if (!removeAll) {
                require(
                    _defaultPrices[nft][currencies[i]] > 0,
                    "Currency has no default price"
                );
            }
            if (_defaultPrices[nft][currencies[i]] > 0) {
                _defaultPrices[nft][currencies[i]] = 0;
            }
        }
    }

    // assumes erc1155TokenId exists or will exist
    function addUpdatePurchaseKey(
        address nft,
        uint256[] calldata tokenIds,
        address erc1155,
        uint256 erc1155TokenId,
        uint256 amount
    ) external onlyRole(NFT_ADMIN) onlyIfNftExists(nft) {
        require(tokenIds.length > 0, "tokenIds[] cannot be empty");
        require(amount > 0, "amount cannot be zero");
        require(isContract(erc1155), "Invalid erc1155 address");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _purchaseKeys[nft][tokenIds[i]].erc1155 = erc1155;
            _purchaseKeys[nft][tokenIds[i]].tokenId = erc1155TokenId;
            _purchaseKeys[nft][tokenIds[i]].amount = amount;
        }
    }

    function removePurchaseKey(address nft, uint256[] calldata tokenIds)
        external
        onlyRole(NFT_ADMIN)
        onlyIfNftExists(nft)
    {
        require(tokenIds.length > 0, "tokenIds[] cannot be empty");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                _purchaseKeys[nft][tokenIds[i]].erc1155 != address(0),
                "Purchase key not found for the tokenId"
            );
            _purchaseKeys[nft][tokenIds[i]].erc1155 = address(0);
            _purchaseKeys[nft][tokenIds[i]].amount = 0;
            _purchaseKeys[nft][tokenIds[i]].tokenId = 0;
        }
    }

    // Assumes each id in tokenIds exist in nft
    function addToMarket(address nft, uint256[] calldata tokenIds)
        external
        onlyRole(NFT_ADMIN)
        onlyIfNftExists(nft)
    {
        uint256 len = tokenIds.length;
        require(len > 0, "tokenIds[] cannot be empty");
        require(
            _hasDefaultPrice(nft),
            "Nft must have at least one default price"
        );

        for (uint256 i = 0; i < len; i++) {
            if (_listedTokens[nft].contains(tokenIds[i])) {
                revert TokenIdAlreadyListed({tokenId: tokenIds[i]});
            }
            _listedTokens[nft].add(tokenIds[i]);
        }
        emit AddedOrRemovedFromMarket(true, nft, tokenIds);
    }

    function removeFromMarket(address nft, uint256[] calldata tokenIds)
        external
        onlyRole(NFT_ADMIN)
        onlyIfNftExists(nft)
    {
        require(tokenIds.length > 0, "tokenIds[] cannot be empty");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (!_listedTokens[nft].contains(tokenIds[i])) {
                revert TokenIdNotListed({tokenId: tokenIds[i]});
            }

            _listedTokens[nft].remove(tokenIds[i]);
        }
        emit AddedOrRemovedFromMarket(false, nft, tokenIds);
    }

    // If the price was already overriden, it overrides with the new value
    function overridePrice(
        address nft,
        address currency,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    )
        external
        onlyRole(NFT_ADMIN)
        onlyIfNftExists(nft)
        onlyIfCurrencyExists(currency)
    {
        require(tokenIds.length > 0, "TokenIds[] cannot be empty");
        require(
            tokenIds.length == amounts.length,
            "tokenIds and amounts must be the same size"
        );

        require(
            _defaultPrices[nft][currency] > 0,
            "Can only override nft's default prices"
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(amounts[i] > 0, "Amount cannot be 0");
            _overridenPrices[nft][currency][tokenIds[i]] = amounts[i];
        }
    }

    function removeOverridePrice(
        address nft,
        address currency,
        uint256[] calldata tokenIds
    )
        external
        onlyRole(NFT_ADMIN)
        onlyIfNftExists(nft)
        onlyIfCurrencyExists(currency)
    {
        require(tokenIds.length > 0, "tokenIds[] cannot be empty");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (_overridenPrices[nft][currency][tokenIds[i]] == 0) {
                revert TokenIdHasNoOverridenPrice({tokenId: tokenIds[i]});
            }
            _overridenPrices[nft][currency][tokenIds[i]] = 0;
        }
    }

    function withdraw() external onlyRole(WITHDRAW) nonReentrant {
        address sender = msg.sender;
        uint256 bal;

        // Withdraw erc20
        IERC20 currency;
        bool withdrawn;
        for (uint256 i = 0; i < _validCurrenciesSet.length(); i++) {
            currency = (IERC20)(_validCurrenciesSet.at(i));
            bal = currency.balanceOf(address(this));
            if (bal > 0) {
                currency.transfer(sender, bal);
                if (!withdrawn) {
                    withdrawn = true;
                }
            }
        }

        // Withdraw erc1155
        uint256 erc1155Idx = _erc1155Balance.length();
        address erc1155;
        uint256 tokenId;
        uint256 tokenIdIdx;

        while (erc1155Idx > 0) {
            erc1155 = _erc1155Balance.at(erc1155Idx - 1);
            tokenIdIdx = _erc1155TokenIdBalance[erc1155].length();

            while (tokenIdIdx > 0) {
                tokenId = _erc1155TokenIdBalance[erc1155].at(tokenIdIdx - 1);
                bal = IERC1155(erc1155).balanceOf(address(this), tokenId);
                if (bal > 0) {
                    IERC1155(erc1155).safeTransferFrom(
                        address(this),
                        sender,
                        tokenId,
                        bal,
                        "0x0"
                    );
                    if (!withdrawn) {
                        withdrawn = true;
                    }
                }
                _erc1155TokenIdBalance[erc1155].remove(tokenId);
                tokenIdIdx--;
            }
            _erc1155Balance.remove(erc1155);
            erc1155Idx--;
        }

        require(withdrawn, "No balance available");
    }

    function setMaxToken(uint256 _maxTokenPurchase)
        external
        onlyRole(NFT_ADMIN)
    {
        maxTokenPurchase = _maxTokenPurchase;
    }

    function nftLength() external view returns (uint256) {
        return _nftSet.length();
    }

    function nftAt(uint256 index) external view returns (address nftAddress) {
        return _nftSet.at(index);
    }

    function listedTokensLength(address nft) external view returns (uint256) {
        return _listedTokens[nft].length();
    }

    function listedTokensAt(address nft, uint256 index)
        external
        view
        returns (uint256)
    {
        return _listedTokens[nft].at(index);
    }

    function isTokenListed(address nft, uint256 tokenId)
        external
        view
        returns (bool)
    {
        return _listedTokens[nft].contains(tokenId);
    }

    function validCurrencies() external view returns (address[] memory) {
        return _validCurrenciesSet.values();
    }

    function _hasDefaultPrice(address nft) private view returns (bool) {
        for (uint256 i = 0; i < _validCurrenciesSet.length(); i++) {
            if (_defaultPrices[nft][_validCurrenciesSet.at(i)] > 0) {
                return true;
            }
        }
        return false;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlEnumerable, ERC1155Receiver)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function isContract(address account) private view returns (bool) {
        return account.code.length > 0;
    }
}