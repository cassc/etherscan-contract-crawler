// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./SceneStorage.sol";

contract SceneContractV1 is SceneStorage {
    // Initialization function
    function initialize() public initializer {
        __ERC721_init("AstroChimpz Scenes", "ASTROSCENES");
        __Ownable_init();
        __ERC721Royalty_init();

        tokenCounter = 0;
        CollectionWalletAddress = 0xB941FF1C44e3b60d919565791E05d33185f16FE3;
        // _setDefaultRoyalty(CollectionWalletAddress, 75000);

        baseUri = "https://s3.amazonaws.com/livesssets.astrochimpz.com/scene_json/";
        baseExtension = "_metadata.json";
        unRevealURI = "https://s3.amazonaws.com/livesssets.astrochimpz.com/scene_default.json";

        maxMintCount = 750;
        revealTime = 48 hours;
        tokenPrice = 70000000000000000;

        saleStatus = 1;
        maxPerWallet = 3;
    }

    /**
     * @dev owner can update metadata uri links
     *
     * @param _base base uri.
     * @param _extension extenstion uri. i.e .json
     * @param _unreveal_uri unreveal default uri.
     *
     * Requirements:
     * - msg.sender must be owner of contract.
     *
     */
    function updateDefaultURI(
        string memory _base,
        string memory _extension,
        string memory _unreveal_uri
    ) external virtual onlyOwner {
        baseUri = _base;
        baseExtension = _extension;
        unRevealURI = _unreveal_uri;

        emit UpdatedURI(baseUri, baseExtension, unRevealURI);
    }

    /**
     * @dev owner update the important data.
     *
     * @param _max_count max count of total scenes to be minted.
     * @param _reveal_time reveal original metadata time
     * @param _price tpoken price for sale.
     * @param _collection_address collection address for collecting eth price and royalties.
     *
     * Requirements:
     * - msg.sender must be owner of contract.
     *
     */
    function updateData(
        uint256 _max_count,
        uint256 _reveal_time,
        uint256 _price,
        address _collection_address
    ) external virtual onlyOwner {
        maxMintCount = _max_count;
        revealTime = _reveal_time;
        tokenPrice = _price;
        require(
            _collection_address != address(0),
            "SceneContract: Zero address should not be assigned"
        );
        CollectionWalletAddress = _collection_address;

        emit UpdatedData(
            CollectionWalletAddress,
            maxMintCount,
            tokenPrice,
            revealTime
        );
    }

    /**
     * @dev owner can on and off the public and presale
     *
     * @param _status Sale status. (1: presale 2: public sale 0: stop all)
     * @param _max_per_wallet max count per wallet address can mint.
     *
     * Requirements:
     * - msg.sender must be owner of contract.
     *
     */
    function updateSaleStatus(
        uint256 _status,
        uint256 _max_per_wallet
    ) external onlyOwner {
        saleStatus = _status;
        maxPerWallet = _max_per_wallet;

        emit UpdatedSaleStatus(saleStatus, maxPerWallet);
    }

    /**
     * @dev owner can whitelist addresses for presale
     *
     * @param _addresses array of address
     * @param _status status if addresses are whitlisted or not
     *
     * Requirements:
     * - msg.sender must be owner of contract.
     *
     */
    function whitelistAddress(
        address[] calldata _addresses,
        bool _status
    ) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            require(
                isWhitelistedAddress[_addresses[i]] != _status &&
                    _addresses[i] != address(0),
                "SceneContract: Invalid address for whitelisting"
            );
            isWhitelistedAddress[_addresses[i]] = _status;
        }
    }

    /**
     * @dev owner can blacklist addresses form platform
     *
     * @param _addresses array of address
     * @param _status status if addresses are whitlisted or not
     *
     * Requirements:
     * - msg.sender must be owner of contract.
     *
     */
    function blacklistAddress(
        address[] calldata _addresses,
        bool _status
    ) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            require(
                isBlacklisted[_addresses[i]] != _status &&
                    _addresses[i] != address(0),
                "SceneContract: Invalid address for blacklisting"
            );
            isBlacklisted[_addresses[i]] = _status;
        }
    }

    /**
     * @dev owner can airdrop tokens to addresses
     *
     * @param _addresses array of address
     *
     * Requirements:
     * - msg.sender must be owner of contract.
     *
     *
     * Emits a {Airdrop} event.
     */
    function airdrop(address[] calldata _addresses) external onlyOwner {
        uint256[] memory ids = new uint256[](_addresses.length);

        for (uint256 i = 0; i < _addresses.length; i++) {
            tokenCounter += 1;
            _mint(_addresses[i], tokenCounter);
            ids[i] = tokenCounter;
        }
        emit Airdrop(_addresses, ids);
    }

    /**
     * @dev user can mint the tokens through sales
     *
     * @param _mintAmount amount of tokens
     *
     * Requirements:
     * - sale must be ON.
     *
     *
     * Emits a {Minted} event.
     */
    function sale(uint256 _mintAmount) external payable {
        require(
            ((saleStatus == 1 &&
                isWhitelistedAddress[msg.sender] &&
                whitelistedAddressCount[msg.sender] + _mintAmount <=
                maxPerWallet) ||
                (saleStatus == 2 &&
                    (publicAddressCount[msg.sender] + _mintAmount <=
                        maxPerWallet))),
            "SceneContract: Sale is closed or Exceeds limit amount by user"
        );
        require(
            (_mintAmount + tokenCounter) <= maxMintCount &&
                (_mintAmount * tokenPrice) == msg.value,
            "SceneContract: Exceeds limit or invalid price"
        );

        uint256[] memory ids = new uint256[](_mintAmount);
        for (uint256 i; i < _mintAmount; i++) {
            tokenCounter += 1;
            _mint(_msgSender(), tokenCounter);
            revealTimestamp[tokenCounter] = block.timestamp;
            ids[i] = tokenCounter;
        }

        payable(CollectionWalletAddress).transfer(msg.value);

        if (saleStatus == 1) {
            whitelistedAddressCount[msg.sender] += _mintAmount;
        } else if (saleStatus == 2) {
            publicAddressCount[msg.sender] += _mintAmount;
        }

        emit Minted(_msgSender(), ids);
    }

    /**
     * @dev owner set default royalties for all tokenIds.
     *
     * @param receiver receiver address.
     * @param feeNumerator percent number.
     *
     * Requirements:
     * - msg.sender must be owner of the contract.
     *
     */
    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external virtual onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev owner set royalties per token id.
     *
     * @param receiver receiver address.
     * @param feeNumerator percent number.
     * @param tokenId token id.
     *
     * Requirements:
     * - msg.sender must be owner of the contract.
     *
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external virtual onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @dev user can view token URIs w.r.t token ids
     *
     * @param _tokenId token id.
     *
     * Returns
     * - token URI.
     *
     */
    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(_tokenId),
            "SceneContract: URI query for nonexistent token"
        );
        if (revealTimestamp[_tokenId] + revealTime > block.timestamp) {
            return unRevealURI;
        }
        return
            string(
                abi.encodePacked(
                    baseUri,
                    StringsUpgradeable.toString(_tokenId),
                    baseExtension
                )
            );
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        require(
            !isBlacklisted[from] && !isBlacklisted[to],
            "SceneContract: Address is blacklisted"
        );
        firstTokenId;
        batchSize;
    }
}