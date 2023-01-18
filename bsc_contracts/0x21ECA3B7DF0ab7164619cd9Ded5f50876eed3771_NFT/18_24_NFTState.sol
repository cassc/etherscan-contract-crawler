// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
pragma abicoder v2;

import "./NFTStorage.sol";
import "./INFTState.sol";
//import "hardhat/console.sol";

contract NFTState is NFTStorage, INFTState {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;
    using StringsW0x for uint256;
    

    function initialize(
        string memory name_, 
        string memory symbol_, 
        string memory contractURI_, 
        string memory baseURI_, 
        string memory suffixURI_, 
        address costManager_,
        address producedBy_
    ) 
        public 
        //override
        onlyInitializing
    {

        __Ownable_init();
        __ReentrancyGuard_init();
        __ERC721_init(name_, symbol_, costManager_, producedBy_);
        _contractURI = contractURI_;
        baseURI = baseURI_;
        suffix = suffixURI_;
 
    }
    

    /********************************************************************
    ****** external section *********************************************
    *********************************************************************/
    
    /**
    * @dev sets the default baseURI for the whole contract
    * @param baseURI_ the prefix to prepend to URIs
    */
    function setBaseURI(
        string calldata baseURI_
    ) 
        external
    {
        requireOnlyOwner();
        baseURI = baseURI_;
        _accountForOperation(
            OPERATION_SETMETADATA << OPERATION_SHIFT_BITS,
            0x100,
            0
        );
    }
    
    /**
    * @dev sets the default URI suffix for the whole contract
    * @param suffix_ the suffix to append to URIs
    */
    function setSuffix(
        string calldata suffix_
    ) 
        external
    {
        requireOnlyOwner();
        suffix = suffix_;
        _accountForOperation(
            OPERATION_SETMETADATA << OPERATION_SHIFT_BITS,
            0x010,
            0
        );
    }

    /**
    * @dev sets contract URI. 
    * @param newContractURI new contract URI
    */
    function setContractURI(string memory newContractURI) external {
        requireOnlyOwner();
        _contractURI = newContractURI;
        _accountForOperation(
            OPERATION_SETMETADATA << OPERATION_SHIFT_BITS,
            0x001,
            0
        );
    }

    /**
    * @dev sets information for series with 'seriesId'. 
    * @param seriesId series ID
    * @param info new info to set
    */
    function setSeriesInfo(
        uint64 seriesId, 
        SeriesInfo memory info 
    ) 
        external
    {
        CommunitySettings memory emptySettings = CommunitySettings(address(0), 0);
        _setSeriesInfo(seriesId, info, emptySettings, emptySettings);
    }

    /**
    * @dev sets information for series with 'seriesId'. 
    * @param seriesId series ID
    * @param info new info to set
    */
    function setSeriesInfo(
        uint64 seriesId, 
        SeriesInfo memory info,
        CommunitySettings memory transferWhitelistSettings,
        CommunitySettings memory buyWhitelistSettings
    ) 
        external
    {
        _setSeriesInfo(seriesId, info, transferWhitelistSettings, buyWhitelistSettings);
    }

    /**
    * @dev sets information for series with 'seriesId'. 
    * @param seriesId series ID
    * @param info new info to set
    */
    function _setSeriesInfo(
        uint64 seriesId, 
        SeriesInfo memory info,
        CommunitySettings memory transferWhitelistSettings,
        CommunitySettings memory buyWhitelistSettings
    ) 
        internal
    {
        _requireCanManageSeries(seriesId);
        if (info.saleInfo.onSaleUntil > seriesInfo[seriesId].saleInfo.onSaleUntil && 
            info.saleInfo.onSaleUntil > block.timestamp
        ) {
            emit SeriesPutOnSale(
                seriesId, 
                info.saleInfo.price,
                info.saleInfo.autoincrement, 
                info.saleInfo.currency, 
                info.saleInfo.onSaleUntil
            );
        } else if (info.saleInfo.onSaleUntil <= block.timestamp ) {
            emit SeriesRemovedFromSale(seriesId);
        }
        
        seriesInfo[seriesId] = info;
        mintedCountBySetSeriesInfo[seriesId] = 0;

        seriesWhitelists[seriesId].transfer = transferWhitelistSettings;
        seriesWhitelists[seriesId].buy = buyWhitelistSettings;

        _accountForOperation(
            (OPERATION_SETSERIESINFO << OPERATION_SHIFT_BITS) | seriesId,
            uint256(uint160(info.saleInfo.currency)),
            info.saleInfo.price
        );
        
    }

    /**
    * set commission paid to contract owner
    * @param commission new commission info
    */
    function setOwnerCommission(
        CommissionInfo memory commission
    ) 
        external 
    {   
        requireOnlyOwner();
        commissionInfo = commission;

        _accountForOperation(
            OPERATION_SETOWNERCOMMISSION << OPERATION_SHIFT_BITS,
            uint256(uint160(commission.ownerCommission.recipient)),
            commission.ownerCommission.value
        );

    }

    /**
    * set commission for series
    * @param commissionData new commission data
    */
    function setCommission(
        uint64 seriesId, 
        CommissionData memory commissionData
    ) 
        external 
    {
        _requireCanManageSeries(seriesId);
        require(
            (
                commissionData.value <= commissionInfo.maxValue &&
                commissionData.value >= commissionInfo.minValue &&
                commissionData.value + commissionInfo.ownerCommission.value < FRACTION
            ),
            "COMMISSION_INVALID"
        );
        require(commissionData.recipient != address(0), "RECIPIENT_INVALID");
        seriesInfo[seriesId].commission = commissionData;
        
        _accountForOperation(
            (OPERATION_SETCOMMISSION << OPERATION_SHIFT_BITS) | seriesId,
            commissionData.value,
            uint256(uint160(commissionData.recipient))
        );
        
    }

    /**
    * clear commission for series
    * @param seriesId seriesId
    */
    function removeCommission(
        uint64 seriesId
    ) 
        external 
    {
        _requireCanManageSeries(seriesId);
        delete seriesInfo[seriesId].commission;
        
        _accountForOperation(
            (OPERATION_REMOVECOMMISSION << OPERATION_SHIFT_BITS) | seriesId,
            0,
            0
        );
        
    }

    /**
    * @dev lists on sale NFT with defined token ID with specified terms of sale
    * @param tokenId token ID
    * @param price price for sale 
    * @param currency currency of sale 
    * @param duration duration of sale 
    */
    function listForSale(
        uint256 tokenId,
        uint256 price,
        address currency,
        uint64 duration
    )
        external 
    {
        (bool success, /*bool isExists*/, /*SaleInfo memory data*/, /*address owner*/) = _getTokenSaleInfo(tokenId);
        
        _requireCanManageToken(tokenId);
        require(!success, "already on sale");
        require(duration > 0, "invalid duration");

        uint64 seriesId = getSeriesId(tokenId);
        SaleInfo memory newSaleInfo = SaleInfo({
            onSaleUntil: uint64(block.timestamp) + duration,
            currency: currency,
            price: price,
            autoincrement:0
        });
        SaleInfoToken memory saleInfoToken = SaleInfoToken({
            saleInfo: newSaleInfo,
            ownerCommissionValue: commissionInfo.ownerCommission.value,
            authorCommissionValue: seriesInfo[seriesId].commission.value
        });
        _setSaleInfo(tokenId, saleInfoToken);

        emit TokenPutOnSale(
            tokenId, 
            _msgSender(), 
            newSaleInfo.price, 
            newSaleInfo.currency, 
            newSaleInfo.onSaleUntil
        );
        
        _accountForOperation(
            (OPERATION_LISTFORSALE << OPERATION_SHIFT_BITS) | seriesId,
            uint256(uint160(currency)),
            price
        );
    }
    
    /**
    * @dev removes from sale NFT with defined token ID
    * @param tokenId token ID
    */
    function removeFromSale(
        uint256 tokenId
    )
        external 
    {
        (bool success, /*bool isExists*/, SaleInfo memory data, /*address owner*/) = _getTokenSaleInfo(tokenId);
        require(success, "token not on sale");
        _requireCanManageToken(tokenId);
        clearOnSaleUntil(tokenId);

        emit TokenRemovedFromSale(tokenId, _msgSender());
        
        uint64 seriesId = getSeriesId(tokenId);
        _accountForOperation(
            (OPERATION_REMOVEFROMSALE << OPERATION_SHIFT_BITS) | seriesId,
            uint256(uint160(data.currency)),
            data.price
        );
    }

    /**
    * @dev mints and distributes NFTs with specified IDs
    * to specified addresses
    * @param tokenIds list of NFT IDs t obe minted
    * @param addresses list of receiver addresses
    */
    function mintAndDistribute(
        uint256[] memory tokenIds, 
        address[] memory addresses
    )
        external 
    {
        uint256 len = addresses.length;
        require(tokenIds.length == len, "lengths should be the same");

        for(uint256 i = 0; i < len; i++) {
            _requireCanManageSeries(getSeriesId(tokenIds[i]));
            _mint(addresses[i], tokenIds[i]);
        }
        
        _accountForOperation(
            OPERATION_MINTANDDISTRIBUTE << OPERATION_SHIFT_BITS,
            len,
            0
        );
    }

    /**
    * @dev mints and distributes `amount` NFTs by `seriesId` to `account`
    * @param seriesId seriesId
    * @param account receiver addresses
    * @param amount amount of tokens
    * @custom:calledby owner or series author
    * @custom:shortd mint and distribute new tokens
    */
    function mintAndDistributeAuto(
        uint64 seriesId, 
        address account,
        uint256 amount
    )
        external
    {
        _requireCanManageSeries(seriesId);

        uint256 tokenId;
        uint256 tokenIndex = (uint256(seriesId) << SERIES_SHIFT_BITS);
        uint192 j;

        for(uint256 i = 0; i < amount; i++) {
            for(j = seriesTokenIndex[seriesId]; j < MAX_TOKEN_INDEX; j++) {
                tokenId = tokenIndex + j;

                if (tokensInfo[tokenId].owner == address(0)) { 
                    // save last index
                    seriesTokenIndex[seriesId] = j;

                    break;
                }
                
            }
            // unreachable but must be
            if (j == MAX_TOKEN_INDEX) { revert("series max token limit exceeded");}
            _mint(account, tokenId);
        }

        _accountForOperation(
            OPERATION_MINTANDDISTRIBUTE << OPERATION_SHIFT_BITS,
            amount,
            0
        );
        
        
    }
   
    /********************************************************************
    ****** public section ***********************************************
    *********************************************************************/
    function buy(
        uint256[] memory tokenIds,
        address currency,
        uint256 totalPrice,
        bool safe,
        uint256 hookCount,
        address buyFor
    ) 
        public 
        virtual
        payable 
        //nonReentrant 
    {
        require(tokenIds.length > 0, "invalid tokenIds");
        uint64 seriesId = getSeriesId(tokenIds[0]);

        validateBuyer(seriesId);
        validateHookCount(seriesId, hookCount);
        
        uint256 left = totalPrice;

        for(uint256 i = 0; i < tokenIds.length; i ++) {
            (bool success, bool exists, SaleInfo memory data, address beneficiary) = _getTokenSaleInfo(tokenIds[i]);

            //require(currency == data.currency, "wrong currency for sale");
            require(left >= data.price, "insufficient amount sent");
            left -= data.price;

            _commissions_payment(
                tokenIds[i], 
                currency, 
                (currency == address(0) ? true : false), 
                data.price, 
                success, 
                data, 
                beneficiary
            );

            _buy(tokenIds[i], exists, data, beneficiary, buyFor, safe);
            
            
            _accountForOperation(
                (OPERATION_BUY << OPERATION_SHIFT_BITS) | seriesId, 
                0,
                data.price
            );
        }

    }

    /**
    * @dev buys NFT for native coin with undefined id. 
    * Id will be generate as usually by auto inrement but belong to seriesId
    * and transfer token if it is on sale
    * @param seriesId series ID whene we can find free token to buy
    * @param price amount of specified native coin to pay
    * @param safe use safeMint and safeTransfer or not, 
    * @param hookCount number of hooks 
    */
    function buyAuto(
        uint64 seriesId, 
        uint256 price, 
        bool safe, 
        uint256 hookCount
    ) 
        public 
        payable 
        //nonReentrant 
    {

        _buyAuto(seriesId, address(0), price, safe, hookCount, _msgSender());
    }
    /**
    * @dev buys NFT for native coin with undefined id. 
    * Id will be generate as usually by auto inrement but belong to seriesId
    * and transfer token if it is on sale
    * @param seriesId series ID whene we can find free token to buy
    * @param price amount of specified native coin to pay
    * @param safe use safeMint and safeTransfer or not, 
    * @param hookCount number of hooks 
    * @param buyFor address of new nft owner
    */
    function buyAuto(
        uint64 seriesId, 
        uint256 price, 
        bool safe, 
        uint256 hookCount,
        address buyFor
    ) 
        public 
        payable 
        //nonReentrant 
    {

        _buyAuto(seriesId, address(0), price, safe, hookCount, buyFor);
    }

    function _buyAuto(
        uint64 seriesId, 
        address currency, 
        uint256 price, 
        bool safe, 
        uint256 hookCount,
        address buyFor
    ) 
        internal
    {
        
        validateBuyer(seriesId);
        validateHookCount(seriesId, hookCount);

        (bool success, bool exists, SaleInfo memory data, address beneficiary, uint256 tokenId) = _getTokenSaleInfoAuto(seriesId);

        _commissions_payment(tokenId, currency, (currency == address(0) ? true : false), price, success, data, beneficiary);
        
        _buy(tokenId, exists, data, beneficiary, buyFor, safe);
        
        
        _accountForOperation(
            (OPERATION_BUY << OPERATION_SHIFT_BITS) | seriesId, 
            0,
            price
        );

    }
    
    /**
    * @dev buys NFT for native coin with undefined id. 
    * Id will be generate as usually by auto inrement but belong to seriesId
    * and transfer token if it is on sale
    * @param seriesId series ID whene we can find free token to buy
    * @param currency address of token to pay with
    * @param price amount of specified token to pay
    * @param safe use safeMint and safeTransfer or not
    * @param hookCount number of hooks 
    */
    function buyAuto(
        uint64 seriesId, 
        address currency, 
        uint256 price, 
        bool safe, 
        uint256 hookCount
    ) 
        public 
        //nonReentrant 
    {

        _buyAuto(seriesId, currency, price, safe, hookCount, _msgSender());
    }

    /**
    * @dev buys NFT for native coin with undefined id. 
    * Id will be generate as usually by auto inrement but belong to seriesId
    * and transfer token if it is on sale
    * @param seriesId series ID whene we can find free token to buy
    * @param currency address of token to pay with
    * @param price amount of specified token to pay
    * @param safe use safeMint and safeTransfer or not
    * @param hookCount number of hooks 
    * @param buyFor address of new nft owner
    */
    function buyAuto(
        uint64 seriesId, 
        address currency, 
        uint256 price, 
        bool safe, 
        uint256 hookCount,
        address buyFor
    ) 
        public 
        //nonReentrant 
    {
        _buyAuto(seriesId, currency, price, safe, hookCount, buyFor);
    }


    /** 
    * @dev sets name and symbol for contract
    * @param newName new name 
    * @param newSymbol new symbol 
    */
    function setNameAndSymbol(
        string memory newName, 
        string memory newSymbol
    ) 
        public 
    {
        requireOnlyOwner();
        _setNameAndSymbol(newName, newSymbol);
    }
    
  
    

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = _ownerOf(tokenId);

        require(to != owner, "ERC721: approval to current owner");
        address ms = _msgSender();
        require(
            ms == owner || _isApprovedForAll(owner, ms),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        _requireCanManageToken(tokenId);

        _transfer(from, to, tokenId);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _requireCanManageToken(tokenId);
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Transfers `tokenId` token from sender to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by sender.
     *
     * Emits a {Transfer} event.
     */
    function transfer(
        address to,
        uint256 tokenId
    ) public virtual {
        _requireCanManageToken(tokenId);
        _transfer(_msgSender(), to, tokenId);
    }

    /**
     * @dev Safely transfers `tokenId` token from sender to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by sender.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransfer(
        address to,
        uint256 tokenId
    ) public virtual override {
        _requireCanManageToken(tokenId);
        _safeTransfer(_msgSender(), to, tokenId, "");
    }

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        _requireCanManageToken(tokenId);
        _burn(tokenId);
        
        _accountForOperation(
            OPERATION_BURN << OPERATION_SHIFT_BITS,
            tokenId,
            0
        );
    }

    
   /**
    * @dev the owner should be absolutely sure they trust the trustedForwarder
    * @param trustedForwarder_ must be a smart contract that was audited
    */
    function setTrustedForwarder(
        address trustedForwarder_
    )
        public 
        override
    {
        requireOnlyOwner();
        _setTrustedForwarder(trustedForwarder_);
    }

    /**
    * @dev link safeHook contract to certain series
    * @param seriesId series ID
    * @param contractAddress address of SafeHook contract
    */
    function pushTokenTransferHook(
        uint64 seriesId, 
        address contractAddress
    )
        public 
    {
        requireOnlyOwner();
        try ISafeHook(contractAddress).supportsInterface(type(ISafeHook).interfaceId) returns (bool success) {
            if (success) {
                hooks[seriesId].add(contractAddress);
            } else {
                revert("wrong interface");
            }
        } catch {
            revert("wrong interface");
        }

        emit NewHook(seriesId, contractAddress);

    }

    function freeze(
        uint256 tokenId
    ) 
        public 
    {
        string memory baseURI;
        string memory suffix;
        (baseURI, suffix) = _baseURIAndSuffix(tokenId);
        _freeze(tokenId, baseURI, suffix);
    }

    function freeze(
        uint256 tokenId, 
        string memory baseURI, 
        string memory suffix
    ) 
        public 
    {
        _freeze(tokenId, baseURI, suffix);
    }

    
    function unfreeze(
        uint256 tokenId
    ) 
        public 
    {
        tokensInfo[tokenId].freezeInfo.exists = false;
    }
    

    /********************************************************************
    ****** internal section *********************************************
    *********************************************************************/

    function validateBuyer(uint64 seriesId) internal {

        if (seriesWhitelists[seriesId].buy.community != address(0)) {
            bool success = ICommunity(seriesWhitelists[seriesId].buy.community).hasRole(_msgSender(), seriesWhitelists[seriesId].buy.role);
            //require(success, "buyer not in whitelist");
            require(success, "BUYER_INVALID");
        }
    }

    function _freeze(uint256 tokenId, string memory baseURI_, string memory suffix_) internal 
    {
        require(_ownerOf(tokenId) == _msgSender(), "token isn't owned by sender");
        tokensInfo[tokenId].freezeInfo.exists = true;
        tokensInfo[tokenId].freezeInfo.baseURI = baseURI_;
        tokensInfo[tokenId].freezeInfo.suffix = suffix_;
        
    }
   
    function _transferOwnership(
        address newOwner
    ) 
        internal 
        virtual 
        override
    {
        super._transferOwnership(newOwner);
        _setTrustedForwarder(address(0));
    }

    function _buy(
        uint256 tokenId, 
        bool exists, 
        SaleInfo memory data, 
        address owner, 
        address recipient, 
        bool safe
    ) 
        internal 
        virtual 
    {
        _storeHookCount(tokenId);

        if (exists) {
            if (safe) {
                _safeTransfer(owner, recipient, tokenId, new bytes(0));
            } else {
                _transfer(owner, recipient, tokenId);
            }
            emit TokenBought(
                tokenId, 
                owner, 
                recipient, 
                data.currency, 
                data.price
            );
        } else {

            if (safe) {
                _safeMint(recipient, tokenId);
            } else {
                _mint(recipient, tokenId);
            }
            emit Transfer(owner, recipient, tokenId);
            emit TokenBought(
                tokenId, 
                owner, 
                recipient, 
                data.currency, 
                data.price
            );
        }
         
    }

    
    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(
        string memory name_, 
        string memory symbol_, 
        address costManager_, 
        address producedBy_
    ) 
        internal 
        onlyInitializing
    {
        
        _setNameAndSymbol(name_, symbol_);
        
        __CostManagerHelper_init(_msgSender());
        _setCostManager(costManager_);

        _accountForOperation(
            OPERATION_INITIALIZE << OPERATION_SHIFT_BITS,
            uint256(uint160(producedBy_)),
            0
        );
    }
    
    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "recipient must implement ERC721Receiver interface");
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event. if flag `skipEvent` is false
     */
    function _mint(
        address to, 
        uint256 tokenId
    ) 
        internal 
        virtual 
    {
        _storeHookCount(tokenId);

        require(to != address(0), "can't mint to the zero address");
        require(tokensInfo[tokenId].owner == address(0), "token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        tokensInfo[tokenId].owner = to;

        uint64 seriesId = getSeriesId(tokenId);
        mintedCountBySeries[seriesId] += 1;
        mintedCountBySetSeriesInfo[seriesId] += 1;

        if (seriesInfo[seriesId].limit != 0) {
            require(
                mintedCountBySeries[seriesId] <= seriesInfo[seriesId].limit, 
                "series token limit exceeded"
            );
        }
        

        emit Transfer(address(0), to, tokenId);
        
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = _ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        
        _balances[DEAD_ADDRESS] += 1;
        tokensInfo[tokenId].owner = DEAD_ADDRESS;
        clearOnSaleUntil(tokenId);
        emit Transfer(owner, DEAD_ADDRESS, tokenId);

    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {

        require(_ownerOf(tokenId) == from, "token isn't owned by from address");
        require(to != address(0), "can't transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        tokensInfo[tokenId].owner = to;

        clearOnSaleUntil(tokenId);

        emit Transfer(from, to, tokenId);
        
        _accountForOperation(
            (OPERATION_TRANSFER << OPERATION_SHIFT_BITS) | getSeriesId(tokenId),
            uint256(uint160(from)),
            uint256(uint160(to))
        );
        
    }
    
    /**
    * @dev sets sale info for the NFT with 'tokenId'
    * @param tokenId token ID
    * @param info information about sale 
    */
    function _setSaleInfo(
        uint256 tokenId, 
        SaleInfoToken memory info 
    ) 
        internal 
    {
        //salesInfoToken[tokenId] = info;
        tokensInfo[tokenId].salesInfoToken = info;
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        tokensInfo[tokenId].tokenApproval = to;
        emit Approval(_ownerOf(tokenId), to, tokenId);
    }
    
    /** 
    * @dev sets name and symbol for contract
    * @param newName new name 
    * @param newSymbol new symbol 
    */
    function _setNameAndSymbol(
        string memory newName, 
        string memory newSymbol
    ) 
        internal 
    {
        _name = newName;
        _symbol = newSymbol;
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {

        //safe hook
        uint64 seriesId = uint64(tokenId >> SERIES_SHIFT_BITS);
        for (uint256 i = 0; i < tokensInfo[tokenId].hooksCountByToken; i++) {
            try ISafeHook(hooks[seriesId].at(i)).executeHook(from, to, tokenId)
			returns (bool success) {
                if (!success) {
                    revert("Transfer Not Authorized");
                }
            } catch Error(string memory reason) {
                // This is executed in case revert() was called with a reason
	            revert(reason);
	        } catch {
                revert("Transfer Not Authorized");
            }
        }
        ////
        if (to != address(0) && seriesWhitelists[seriesId].transfer.community != address(0)) {
            bool success = ICommunity(seriesWhitelists[seriesId].transfer.community).hasRole(to, seriesWhitelists[seriesId].transfer.role);
            //require(success, "recipient not in whitelist");
            require(success, "RECIPIENT_INVALID");
            
        }
    ////

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }

        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }

    }

    function clearOnSaleUntil(uint256 tokenId) internal {
        if (tokensInfo[tokenId].salesInfoToken.saleInfo.onSaleUntil > 0 ) tokensInfo[tokenId].salesInfoToken.saleInfo.onSaleUntil = 0;
    }

    function _requireCanManageSeries(uint64 seriesId) internal view virtual {
        require(_canManageSeries(seriesId), "you can't manage this series");
    }
             
    function _requireCanManageToken(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "token doesn't exist");
        require(_canManageToken(tokenId), "you can't manage this token");
    }

    function _canManageToken(uint256 tokenId) internal view returns (bool) {
        return __ownerOf(tokenId) == _msgSender()
            || _getApproved(tokenId) == _msgSender()
            || _isApprovedForAll(__ownerOf(tokenId), _msgSender());
    }

    function _canManageSeries(uint64 seriesId) internal view returns(bool) {
        return owner() == _msgSender() || seriesInfo[seriesId].author == _msgSender();
    }
    
    /**
    * @dev returns count of hooks for series with `seriesId`
    * @param seriesId series ID
    */
    function hooksCount(
        uint64 seriesId
    ) 
        internal 
        view 
        returns(uint256) 
    {
        return hooks[seriesId].length();
    }

    /**
    * @dev validates hook count
    * @param seriesId series ID
    * @param hookCount hook count
    */
    function validateHookCount(
        uint64 seriesId,
        uint256 hookCount
    ) 
        internal 
        view 
    {
        require(hookCount == hooksCount(seriesId), "wrong hookCount");
    }

    /** 
    * @dev used to storage hooksCountByToken at this moment
    */
    function _storeHookCount(
        uint256 tokenId
    )
        internal
    {
        tokensInfo[tokenId].hooksCountByToken = hooks[uint64(tokenId >> SERIES_SHIFT_BITS)].length();
    }

    /**
    * payment while buying. combined version for payable and for tokens
    */
    function _commissions_payment(
        uint256 tokenId,
        address currency,
        bool isPayable,
        uint256 price, 
        bool success,
        SaleInfo memory data, 
        address beneficiary
    )
        internal
    {
        require(success, "token is not on sale");

        require(
            (isPayable && address(0) == data.currency) ||
            (!isPayable && currency == data.currency),
            "wrong currency for sale"
        );

        uint256 amount = (isPayable ? msg.value : IERC20Upgradeable(data.currency).allowance(_msgSender(), address(this)));
        require(amount >= data.price && price >= data.price, "insufficient amount sent");

        uint256 left = data.price;
        (address[2] memory addresses, uint256[2] memory values, uint256 length) = calculateCommission(tokenId, data.price);

        // commissions payment
        bool transferSuccess;
        for(uint256 i = 0; i < length; i++) {
            if (isPayable) {
                (transferSuccess, ) = addresses[i].call{gas: 3000, value: values[i]}(new bytes(0));
                require(transferSuccess, "TRANSFER_COMMISSION_FAILED");
            } else {
                IERC20Upgradeable(data.currency).transferFrom(_msgSender(), addresses[i], values[i]);
            }
            left -= values[i];
        }

        // payment to beneficiary and refund
        if (isPayable) {
            (transferSuccess, ) = beneficiary.call{gas: 3000, value: left}(new bytes(0));
            require(transferSuccess, "TRANSFER_TO_OWNER_FAILED");

            // try to refund
            if (amount > data.price) {
                // todo 0: if  EIP-2771 using. to whom refund will be send? msg.sender or trusted forwarder
                (transferSuccess, ) = msg.sender.call{gas: 3000, value: (amount - data.price)}(new bytes(0));
                require(transferSuccess, "REFUND_FAILED");
            }

        } else {
            IERC20Upgradeable(data.currency).transferFrom(_msgSender(), beneficiary, left);
        }

    }

    /**
    * @dev calculate commission for `tokenId`
    *  if param exists equal true, then token doesn't exists yet. 
    *  otherwise we should use snapshot parameters: ownerCommission/authorCommission, that hold during listForSale.
    *  used to prevent increasing commissions
    * @param tokenId token ID to calculate commission
    * @param price amount of specified token to pay 
    */
    function calculateCommission(
        uint256 tokenId,
        uint256 price
    ) 
        internal 
        view 
        returns(
            address[2] memory addresses, 
            uint256[2] memory values,
            uint256 length
        ) 
    {
        uint64 seriesId = getSeriesId(tokenId);
        length = 0;
        uint256 sum;
        // contract owner commission
        if (commissionInfo.ownerCommission.recipient != address(0)) {
            uint256 oc = tokensInfo[tokenId].salesInfoToken.ownerCommissionValue;
            if (commissionInfo.ownerCommission.value < oc)
                oc = commissionInfo.ownerCommission.value;
            if (oc != 0) {
                addresses[length] = commissionInfo.ownerCommission.recipient;
                sum += oc;
                values[length] = oc * price / FRACTION;
                length++;
            }
        }

        // author commission
        if (seriesInfo[seriesId].commission.recipient != address(0)) {
            uint256 ac = tokensInfo[tokenId].salesInfoToken.authorCommissionValue;
            if (seriesInfo[seriesId].commission.value < ac) 
                ac = seriesInfo[seriesId].commission.value;
            if (ac != 0) {
                addresses[length] = seriesInfo[seriesId].commission.recipient;
                sum += ac;
                values[length] = ac * price / FRACTION;
                length++;
            }
        }

        require(sum < FRACTION, "invalid commission");

    }

    /********************************************************************
    ****** private section **********************************************
    *********************************************************************/

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }


   
    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = _balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        tokensInfo[tokenId].ownedTokensIndex = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        tokensInfo[tokenId].allTokensIndex = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _balanceOf(from) - 1;
        uint256 tokenIndex = tokensInfo[tokenId].ownedTokensIndex;

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            tokensInfo[lastTokenId].ownedTokensIndex = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        tokensInfo[tokenId].ownedTokensIndex = 0;
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = tokensInfo[tokenId].allTokensIndex;

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        tokensInfo[lastTokenId].allTokensIndex = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        tokensInfo[tokenId].allTokensIndex = 0;
        _allTokens.pop();
    }

}