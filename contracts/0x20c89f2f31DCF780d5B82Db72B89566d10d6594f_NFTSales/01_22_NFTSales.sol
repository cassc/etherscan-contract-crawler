// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

import "./INFTSalesFactory.sol";
import "./INFTSales.sol";
import "../INFTView.sol";

import "../lib/StringsW0x.sol";

/**
*****************
TEMPLATE CONTRACT
*****************
Although this code is available for viewing on GitHub and here, the general public is NOT given a license to freely deploy smart contracts based on this code, on any blockchains.
To prevent confusion and increase trust in the audited code bases of smart contracts we produce, we intend for there to be only ONE official Factory address on the blockchain producing the corresponding smart contracts, and we are going to point a blockchain domain name at it.
Copyright (c) Intercoin Inc. All rights reserved.
ALLOWED USAGE.
Provided they agree to all the conditions of this Agreement listed below, anyone is welcome to interact with the official Factory Contract at the this address to produce smart contract instances, or to interact with instances produced in this manner by others.
Any user of software powered by this code MUST agree to the following, in order to use it. If you do not agree, refrain from using the software:
DISCLAIMERS AND DISCLOSURES.
Customer expressly recognizes that nearly any software may contain unforeseen bugs or other defects, due to the nature of software development. Moreover, because of the immutable nature of smart contracts, any such defects will persist in the software once it is deployed onto the blockchain. Customer therefore expressly acknowledges that any responsibility to obtain outside audits and analysis of any software produced by Developer rests solely with Customer.
Customer understands and acknowledges that the Software is being delivered as-is, and may contain potential defects. While Developer and its staff and partners have exercised care and best efforts in an attempt to produce solid, working software products, Developer EXPRESSLY DISCLAIMS MAKING ANY GUARANTEES, REPRESENTATIONS OR WARRANTIES, EXPRESS OR IMPLIED, ABOUT THE FITNESS OF THE SOFTWARE, INCLUDING LACK OF DEFECTS, MERCHANTABILITY OR SUITABILITY FOR A PARTICULAR PURPOSE.
Customer agrees that neither Developer nor any other party has made any representations or warranties, nor has the Customer relied on any representations or warranties, express or implied, including any implied warranty of merchantability or fitness for any particular purpose with respect to the Software. Customer acknowledges that no affirmation of fact or statement (whether written or oral) made by Developer, its representatives, or any other party outside of this Agreement with respect to the Software shall be deemed to create any express or implied warranty on the part of Developer or its representatives.
INDEMNIFICATION.
Customer agrees to indemnify, defend and hold Developer and its officers, directors, employees, agents and contractors harmless from any loss, cost, expense (including attorney’s fees and expenses), associated with or related to any demand, claim, liability, damages or cause of action of any kind or character (collectively referred to as “claim”), in any manner arising out of or relating to any third party demand, dispute, mediation, arbitration, litigation, or any violation or breach of any provision of this Agreement by Customer.
NO WARRANTY.
THE SOFTWARE IS PROVIDED “AS IS” WITHOUT WARRANTY. DEVELOPER SHALL NOT BE LIABLE FOR ANY DIRECT, INDIRECT, SPECIAL, INCIDENTAL, CONSEQUENTIAL, OR EXEMPLARY DAMAGES FOR BREACH OF THE LIMITED WARRANTY. TO THE MAXIMUM EXTENT PERMITTED BY LAW, DEVELOPER EXPRESSLY DISCLAIMS, AND CUSTOMER EXPRESSLY WAIVES, ALL OTHER WARRANTIES, WHETHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING WITHOUT LIMITATION ALL IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE OR USE, OR ANY WARRANTY ARISING OUT OF ANY PROPOSAL, SPECIFICATION, OR SAMPLE, AS WELL AS ANY WARRANTIES THAT THE SOFTWARE (OR ANY ELEMENTS THEREOF) WILL ACHIEVE A PARTICULAR RESULT, OR WILL BE UNINTERRUPTED OR ERROR-FREE. THE TERM OF ANY IMPLIED WARRANTIES THAT CANNOT BE DISCLAIMED UNDER APPLICABLE LAW SHALL BE LIMITED TO THE DURATION OF THE FOREGOING EXPRESS WARRANTY PERIOD. SOME STATES DO NOT ALLOW THE EXCLUSION OF IMPLIED WARRANTIES AND/OR DO NOT ALLOW LIMITATIONS ON THE AMOUNT OF TIME AN IMPLIED WARRANTY LASTS, SO THE ABOVE LIMITATIONS MAY NOT APPLY TO CUSTOMER. THIS LIMITED WARRANTY GIVES CUSTOMER SPECIFIC LEGAL RIGHTS. CUSTOMER MAY HAVE OTHER RIGHTS WHICH VARY FROM STATE TO STATE. 
LIMITATION OF LIABILITY. 
TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, IN NO EVENT SHALL DEVELOPER BE LIABLE UNDER ANY THEORY OF LIABILITY FOR ANY CONSEQUENTIAL, INDIRECT, INCIDENTAL, SPECIAL, PUNITIVE OR EXEMPLARY DAMAGES OF ANY KIND, INCLUDING, WITHOUT LIMITATION, DAMAGES ARISING FROM LOSS OF PROFITS, REVENUE, DATA OR USE, OR FROM INTERRUPTED COMMUNICATIONS OR DAMAGED DATA, OR FROM ANY DEFECT OR ERROR OR IN CONNECTION WITH CUSTOMER'S ACQUISITION OF SUBSTITUTE GOODS OR SERVICES OR MALFUNCTION OF THE SOFTWARE, OR ANY SUCH DAMAGES ARISING FROM BREACH OF CONTRACT OR WARRANTY OR FROM NEGLIGENCE OR STRICT LIABILITY, EVEN IF DEVELOPER OR ANY OTHER PERSON HAS BEEN ADVISED OR SHOULD KNOW OF THE POSSIBILITY OF SUCH DAMAGES, AND NOTWITHSTANDING THE FAILURE OF ANY REMEDY TO ACHIEVE ITS INTENDED PURPOSE. WITHOUT LIMITING THE FOREGOING OR ANY OTHER LIMITATION OF LIABILITY HEREIN, REGARDLESS OF THE FORM OF ACTION, WHETHER FOR BREACH OF CONTRACT, WARRANTY, NEGLIGENCE, STRICT LIABILITY IN TORT OR OTHERWISE, CUSTOMER'S EXCLUSIVE REMEDY AND THE TOTAL LIABILITY OF DEVELOPER OR ANY SUPPLIER OF SERVICES TO DEVELOPER FOR ANY CLAIMS ARISING IN ANY WAY IN CONNECTION WITH OR RELATED TO THIS AGREEMENT, THE SOFTWARE, FOR ANY CAUSE WHATSOEVER, SHALL NOT EXCEED 1,000 USD.
TRADEMARKS.
This Agreement does not grant you any right in any trademark or logo of Developer or its affiliates.
LINK REQUIREMENTS.
Operators of any Websites and Apps which make use of smart contracts based on this code must conspicuously include the following phrase in their website, featuring a clickable link that takes users to intercoin.app:
"Visit https://intercoin.app to launch your own NFTs, DAOs and other Web3 solutions."
STAKING OR SPENDING REQUIREMENTS.
In the future, Developer may begin requiring staking or spending of Intercoin tokens in order to take further actions (such as producing series and minting tokens). Any staking or spending requirements will first be announced on Developer's website (intercoin.org) four weeks in advance. Staking requirements will not apply to any actions already taken before they are put in place.
CUSTOM ARRANGEMENTS.
Reach out to us at intercoin.org if you are looking to obtain Intercoin tokens in bulk, remove link requirements forever, remove staking requirements forever, or get custom work done with your Web3 projects.
ENTIRE AGREEMENT
This Agreement contains the entire agreement and understanding among the parties hereto with respect to the subject matter hereof, and supersedes all prior and contemporaneous agreements, understandings, inducements and conditions, express or implied, oral or written, of any nature whatsoever with respect to the subject matter hereof. The express terms hereof control and supersede any course of performance and/or usage of the trade inconsistent with any of the terms hereof. Provisions from previous Agreements executed between Customer and Developer., which are not expressly dealt with in this Agreement, will remain in effect.
SUCCESSORS AND ASSIGNS
This Agreement shall continue to apply to any successors or assigns of either party, or any corporation or other entity acquiring all or substantially all the assets and business of either party whether by operation of law or otherwise.
ARBITRATION
All disputes related to this agreement shall be governed by and interpreted in accordance with the laws of New York, without regard to principles of conflict of laws. The parties to this agreement will submit all disputes arising under this agreement to arbitration in New York City, New York before a single arbitrator of the American Arbitration Association (“AAA”). The arbitrator shall be selected by application of the rules of the AAA, or by mutual agreement of the parties, except that such arbitrator shall be an attorney admitted to practice law New York. No party to this agreement will challenge the jurisdiction or venue provisions as provided in this section. No party to this agreement will challenge the jurisdiction or venue provisions as provided in this section.
**/
contract NFTSales is ERC721EnumerableUpgradeable, OwnableUpgradeable, INFTSales, IERC721ReceiverUpgradeable, ReentrancyGuardUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using StringsW0x for uint256;

    uint8 internal constant SERIES_SHIFT_BITS = 192; // 256 - 64
    uint192 internal constant MAX_TOKEN_INDEX = type(uint192).max;

    address public currency;
    uint64 public seriesId;
    uint256 public price;
    address public beneficiary;
    uint64 public duration;
    uint32 public rateInterval;
    uint192 public currentAutoIndex;
    uint16 public rateAmount;
    bool public evenIfNotOnSale;
    bool public allowTransfers;

    address public factoryAddress;

    uint256 internal seriesPart;

    struct TokenData {
        address recipient;
        uint64 untilTimestamp;
    }
    
    uint256 purchaseBucketLastIntervalIndex;
    uint256 purchaseBucketLastIntervalAmount;

    string public baseURI;
    string public suffix;

    mapping(uint256 => TokenData) public pending;
    mapping(address => uint16) public specialPurchaseLicenses;
    mapping(address => mapping(uint256 => uint256)) public usedLicenses;

    EnumerableSetUpgradeable.AddressSet specialPurchasesList;

    error StillPending(uint64 daysLeft, uint64 secondsLeft);
    error InvalidAddress(address addr);
    error InsufficientFunds(address currency, uint256 expected, uint256 sent);
    error UnknownTokenIdForClaim(uint256 tokenId);
    error TransferCommissionFailed();
    error RefundFailed();
    error ShouldBeTokenOwner(address account);
    error InvalidInput();
    error NotEnoughLicenses();
    error NotInWhiteList(address account);
    error NotInListForAutoMint(address account, uint64 seriesId);
    error SeriesMaxTokenLimitExceeded(uint64 seriesId);
    error TooMuchBoughtInCurrentInterval(uint256 currentInterval, uint256 willBeBought, uint32 maxAmount);
    error SeriesIsNotOnSale(uint64 seriesId);
    error IncorrectInputParameters();
    error NoTransfersAllowed();

    /**
     * @notice initialization
     * @param _currency currency for every sale NFT token
     * @param _price price amount for every sale NFT token
     * @param _beneficiary address where which receive funds after sale
     * @param _autoindex from what index contract will start autoincrement from each series(if owner doesnot set before) 
     * @param _duration locked time when NFT will be locked after sale
     * @param _rateInterval interval in which contract should sell not more than `_rateAmount` tokens
     * @param _rateAmount amount of tokens that can be minted in each `_rateInterval`
     * @custom:calledby factory on initialization
     * @custom:shortd initialization instance
     */
    function initialize(
        uint64 _seriesId,
        address _currency,
        uint256 _price,
        address _beneficiary,
        uint192 _autoindex,
        uint64 _duration,
        uint32 _rateInterval,
        uint16 _rateAmount
    )
        external
        //override
        initializer
    {
        __Ownable_init();
        __ReentrancyGuard_init();

        factoryAddress = owner();

        __NFTSales_init(_seriesId, _currency, _price, _beneficiary, _autoindex, _duration, _rateInterval, _rateAmount);

        
    }

    /********************************************************************
     ****** external section *********************************************
     *********************************************************************/
    /**
     * @notice purchase tokens using special promotion from this instance
     * @param amount the number per address
     * @param accounts array of addresses, each gets amount of tokens
     * @custom:calledby an authorized user
     * @custom:shortd sell NFT tokens
     */
    function specialPurchase(
        uint256 amount,
        address[] memory accounts
    ) external payable nonReentrant {
        address buyer = _msgSender();

        if (!specialPurchasesList.contains(buyer)) {
            revert NotInWhiteList(buyer);
        }

        uint256 l = accounts.length;
        for (uint256 i = 0; i < l; ++i) {
            _purchase(amount, accounts[i], buyer, true);
        }
    }
    
    /**
     * @notice purchase tokens using special promotion from this instance
     * @param amount the number per address
     * @param account address, gets amount of tokens
     * @param contracts array of NFT smart contracts, added with specialPurchaseLicensesAdd, can contain duplicates
     * @param tokenIds array of tokenIds corresponding to the smart contracts
     * @custom:calledby an authorized user
     * @custom:shortd sell NFT tokens
     */
    function specialPurchaseByLicenses(
        uint256 amount,
        address account,
        address[] memory contracts,
        uint256[] memory tokenIds
    ) external payable nonReentrant {
        address buyer = _msgSender();

        uint256 allowedAmount = 0;
        uint256 cl = contracts.length;
        uint256 tl = tokenIds.length;
        if (cl != tl) {
            revert InvalidInput();
        }
        for (uint256 i = 0; i < cl; ++i) {
            if (
                usedLicenses[contracts[i]][tokenIds[i]] > 0 || 
                IERC721Upgradeable(contracts[i]).ownerOf(tokenIds[i]) != buyer
            ) {
                continue;
            }
            uint256 additionalAmount = specialPurchaseLicenses[contracts[i]]; // 0 by default
            allowedAmount += additionalAmount;
            if (allowedAmount > amount) {
                additionalAmount -= (allowedAmount - amount);
            }
            usedLicenses[contracts[i]][tokenIds[i]] = additionalAmount;
            if (allowedAmount >= amount) {
                break;
            }
        }
        if (allowedAmount < amount) {
            revert NotEnoughLicenses();
        }
        _purchase(amount, account, buyer, true); // also checks global purchase limits
    }

    /**
     * @notice if tokens are on sale in the actual NFT contract, purchase some
     * @param amount the number per address
     * @param accounts array of addresses, each gets amount of tokens
     * @custom:calledby anyone
     * @custom:shortd sell NFT tokens
     */
    function purchase(
        uint256 amount,
        address[] memory accounts
    ) external payable nonReentrant {
        address buyer = _msgSender();
        uint256 l = accounts.length;
        for (uint256 i = 0; i < l; ++i) {
            _purchase(amount, accounts[i], buyer, false);
        }
    }

    /**
     * @notice amount of days+1 that left to unlocked
     * @param tokenId tokenId that need to view remaining days to be unlocked
     * @return amount of days+1 that left to unlocked
     * @custom:calledby person in the whitelist
     * @custom:shortd locked days
     */
    function remainingDays(uint256 tokenId) external view returns (uint64) {
        _validateTokenId(tokenId);
        return _remainingDays(tokenId);
    }

    /**
     * @notice distribute unlocked tokens
     * @param tokenIds array of tokens that need to be unlocked
     * @custom:calledby everyone
     * @custom:shortd claim locked tokens
     */
    function distributeUnlockedTokens(uint256[] memory tokenIds) external {
        _claim(tokenIds, false);
    }

    /**
     * @notice claim unlocked tokens
     * @param tokenIds array of tokens that need to be unlocked
     * @custom:calledby owner of tokenIds
     * @custom:shortd claim locked tokens
     */
    function claim(uint256[] memory tokenIds) external {
        _claim(tokenIds, true);
    }

    function onERC721Received(
        address, /*operator*/
        address, /*from*/
        uint256, /*tokenId*/
        bytes calldata /*data*/
    ) external pure returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    /**
     * Adding addresses list to whitelist (specialPurchasesList)
     *
     * Requirements:
     *
     * - `addresses` cannot contains the zero address.
     *
     * @param addresses list of addresses which will be added to specialPurchasesList
     */
    function specialPurchasesListAdd(address[] memory addresses) external onlyOwner {
        _whitelistManage(specialPurchasesList, addresses, true);
    }

    /**
     * Removing addresses list from whitelist (specialPurchasesList)
     *
     * Requirements:
     *
     * - `addresses` cannot contains the zero address.
     *
     * @param addresses list of addresses which will be removed from specialPurchasesList
     */
    function specialPurchasesListRemove(address[] memory addresses) external onlyOwner {
        _whitelistManage(specialPurchasesList, addresses, false);
    }
    
    /**
     * Adding external NFT contract to specialPurchaseLicenses list
     *
     * Requirements:
     *
     * - `contract_` must be an NFT contract supporting ownerOf function
     *
     * @param contract_ address of external NFT contract
     * @param amount number of tokens that can be minted per external NFT
     */
    function specialPurchaseLicensesAdd(address contract_, uint16 amount) external onlyOwner {
        specialPurchaseLicenses[contract_] = amount;
    }
    
    /**
     * Removing external NFT contract from specialPurchaseLicenses list
     *
     * Requirements:
     *
     * - `contract_` must be a contract that was previously added
     *
     * @param contract_ address of external NFT contract
     */
    function specialPurchaseLicensesRemove(address contract_) external onlyOwner {
        delete specialPurchaseLicenses[contract_];
    }

    /**
     * @param index index from what will be autogenerated tokenid for seriesId
     */
    function setAutoIndex(uint192 index) external onlyOwner {
        currentAutoIndex = index;
    }

    /**
     * Checking Is account in common whitelist
     * @param account address
     * @return true if account in the whitelist. otherwise - no
     */
    function isWhitelisted(address account) external view returns (bool) {
        return specialPurchasesList.contains(account);
    }

    /**
    * @dev whether tokens can be minted through `specialPurchase` even if series is not on sale
    * @param flag boolean
    */
    function setEvenIfNotOnSale(bool flag) external onlyOwner {
        evenIfNotOnSale = flag;
    }

    /**
    * @dev whether to allow transfers of NFTs to other recipients while they are pending.
    *  When the pending period comes to an end, the recipient at that time can claim it.
    * @param allow boolean
    */
    function setAllowTransfers(bool allow) external onlyOwner {
        allowTransfers = allow;
    }

    /**
    * getting array of whitelisted addresses. used by frontend. return all addresses
    */
    function whitelisted() external view returns(address[] memory ret) {
        uint256 len = specialPurchasesList.length();
        ret = new address[](len);
        for (uint256 i = 0; i<len; i++) {
           ret[i] = specialPurchasesList.at(i);
        }
    }

    /**
    * getting array of whitelisted addresses. overloaded. used by frontend. supports pagination
    * @param page number of page
    * @param count amount of addresess of page number
    * @return ret array of whitelisted addresses
    * note that 
    *   if there are no any addresses on the page - method will return zero array
    *   if addresses exists but their amounts less than `count` - returns array will be without zero values and size will be less
    *   else returns array will be with length equal `count`
    */
    function whitelisted(uint256 page, uint256 count) external view returns(address[] memory ret) {
        if (page == 0 || count == 0) {
            revert IncorrectInputParameters();
        }

        uint256 len = specialPurchasesList.length();
        uint256 ifrom = page*count-count;

        if (
            len == 0 || 
            ifrom >= len
        ) {
            ret = new address[](0);
        } else {

            count = ifrom+count > len ? len-ifrom : count ;
            ret = new address[](count);

            for (uint256 i = ifrom; i<ifrom+count; i++) {
                ret[i-ifrom] = specialPurchasesList.at(i);
                
            }
        }
    }

    /**
    * @notice tokens data for pending tokens
    * @param tokenId tokenId
    * @return recipient recipient address
    * @return secondsLeft seconds left to unlock
    */
    function tokenInfo(uint256 tokenId) external view returns(address recipient, uint64 secondsLeft) {
        return(
            pending[tokenId].recipient,
            pending[tokenId].untilTimestamp > block.timestamp ? uint64(pending[tokenId].untilTimestamp-block.timestamp) : 0
        );
    }


    /**
    * @return amount addresses from the special purchases list
    */
    function whitelistedCount() external view returns(uint256) {
        return specialPurchasesList.length();
    }


    /**
    * @dev sets the default baseURI for the whole contract
    * @param baseURI_ the prefix to prepend to URIs
    */
    function setBaseURI(string calldata baseURI_) onlyOwner external {
        baseURI = baseURI_;
    }
    
    /**
    * @dev sets the default URI suffix for the whole contract
    * @param suffix_ the suffix to append to URIs
    */
    function setSuffix(string calldata suffix_) onlyOwner external {
        suffix = suffix_;
    }

    /********************************************************************
     ****** public section ***********************************************
     *********************************************************************/

    function remainingToBuyInCurrentInterval() public view returns(uint256) {
        uint256 currentInterval = currentBucketInterval();
        return purchaseBucketLastIntervalIndex == currentInterval ? rateAmount - purchaseBucketLastIntervalAmount : rateAmount;
    }

    /********************************************************************
     ****** override ERC721MetadataUpgradeable methods *******************
     *********************************************************************/

    /**
     * @dev Returns the token collection name.
     */
    function name() public view override returns (string memory) {
        address NFTcontract = INFTSalesFactory(factoryAddress).instanceToNFTContract(address(this));
        string memory externalName = IERC721MetadataUpgradeable(NFTcontract).name();
        return string(abi.encodePacked("VAULT FOR ", externalName));
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view override returns (string memory) {
        address NFTcontract = INFTSalesFactory(factoryAddress).instanceToNFTContract(address(this));
        string memory externalSymbol = IERC721MetadataUpgradeable(NFTcontract).symbol();
        return string(abi.encodePacked(externalSymbol, "_VAULT"));
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);

        //return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";

        if (bytes(baseURI).length == 0) {
            return string(abi.encodePacked(baseURI, tokenId.toHexString(), suffix));
        }
        address NFTcontract = INFTSalesFactory(factoryAddress).instanceToNFTContract(address(this));
        return IERC721MetadataUpgradeable(NFTcontract).tokenURI(tokenId);
    }

    /********************************************************************
     ****** override ERC721Upgradeable methods ***************************
     *********************************************************************/

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = pending[tokenId].recipient;
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view override returns (bool) {
        return pending[tokenId].recipient != address(0);
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
    ) internal override {

        super._transfer(from, to, tokenId);
        pending[tokenId].recipient = to;

    }

    /********************************************************************
     ****** internal section *********************************************
     *********************************************************************/
    
    function _purchase(
        uint256 amount,
        address account,
        address buyer,
        bool isSpecialPurchase
    ) internal {

        require(amount != 0);

        if (isSpecialPurchase) {
            uint256 currentInterval = currentBucketInterval();

            if (purchaseBucketLastIntervalIndex != currentInterval) {
                purchaseBucketLastIntervalIndex = currentInterval;
                purchaseBucketLastIntervalAmount = 0;
            }

            purchaseBucketLastIntervalAmount += amount;
            if (purchaseBucketLastIntervalAmount > rateAmount) {
                revert TooMuchBoughtInCurrentInterval(currentInterval, purchaseBucketLastIntervalAmount, rateAmount);
            }
        }

        // generate token ids
        (uint256[] memory tokenIds, address currencyAddr, uint256 currencyTotalPrice, uint192 lastIndex) = _getTokenIds(amount, isSpecialPurchase);
        currentAutoIndex = lastIndex + 1;
        
        // confirm pay
        _confirmPay(currencyTotalPrice, currencyAddr, buyer);

        _distributeTokens(tokenIds, account);
    }

    function _distributeTokens(uint256[] memory tokenIds, address account) internal {
        address[] memory addresses = new address[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            addresses[i] = account;
        }

        // distribute tokens
        if (duration == 0) {
            INFTSalesFactory(factoryAddress)._doMintAndDistribute(tokenIds, addresses);
        } else {
            address[] memory selfAddresses = new address[](tokenIds.length);
            for (uint256 i = 0; i < tokenIds.length; i++) {
                selfAddresses[i] = address(this);
                pending[tokenIds[i]] = TokenData(addresses[i], duration + uint64(block.timestamp));
                _mint(addresses[i], tokenIds[i]);
            }
            INFTSalesFactory(factoryAddress)._doMintAndDistribute(tokenIds, selfAddresses);
        }
    }

    function _confirmPay(uint256 totalPrice, address currencyToPay, address buyer) internal {
        bool transferSuccess;

        if (currencyToPay == address(0)) {
            if (msg.value < totalPrice) {
                revert InsufficientFunds(currencyToPay, totalPrice, msg.value);
            }

            (transferSuccess, ) = (beneficiary).call{gas: 3000, value: (totalPrice)}(new bytes(0));
            if (!transferSuccess) {
                revert TransferCommissionFailed();
            }

            uint256 refundAmount = msg.value - totalPrice;
            if (refundAmount > 0) {
                // or maybe need a minimal value when refund triggered?
                (transferSuccess, ) = (buyer).call{gas: 3000, value: (refundAmount)}(new bytes(0));
                if (!transferSuccess) {
                    revert RefundFailed();
                }
            }
        } else {
            IERC20Upgradeable(currencyToPay).transferFrom(buyer, beneficiary, totalPrice);
        }
    }

    function _whitelistManage(
        EnumerableSetUpgradeable.AddressSet storage list,
        address[] memory addresses,
        bool state
    ) internal {
        for (uint256 i = 0; i < addresses.length; i++) {
            if (addresses[i] == address(0)) {
                revert InvalidAddress(addresses[i]);
            }
            if (state) {
                list.add(addresses[i]);
            } else {
                list.remove(addresses[i]);
            }
        }
    }

    function __NFTSales_init(
        uint64 _seriesId,
        address _currency,
        uint256 _price,
        address _beneficiary,
        uint192 _autoindex,
        uint64 _duration,
        uint32 _rateInterval,
        uint16 _rateAmount
    ) internal onlyInitializing {
        seriesId = _seriesId;
        currency = _currency;
        price = _price;
        beneficiary = _beneficiary;
        currentAutoIndex = _autoindex;
        duration = _duration;
        rateInterval = _rateInterval;
        rateAmount = _rateAmount;

        seriesPart = (uint256(seriesId) << SERIES_SHIFT_BITS);
    }

    function _claim(uint256[] memory tokenIds, bool shouldCheckOwner) internal nonReentrant {
        address NFTcontract = INFTSalesFactory(getFactory()).instanceToNFTContract(address(this));
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            _checkTokenForClaim(tokenId, shouldCheckOwner);

            IERC721Upgradeable(NFTcontract).safeTransferFrom(address(this), pending[tokenId].recipient, tokenId);

            delete pending[tokenIds[i]];
            _burn(tokenId);
        }
    }

    function getFactory() internal view returns (address) {
        return factoryAddress; // deployer of contract. this can't make sense if deployed manually
    }

    function remainingLockedTime(uint256 tokenId) internal view returns (uint64) {
        return
            pending[tokenId].untilTimestamp > uint64(block.timestamp)
                ? pending[tokenId].untilTimestamp - uint64(block.timestamp)
                : 0;
    }

    /**
     * @notice it's internal method. Expect that token id exists. means `locked[tokenId].owner != address(0)`
     * @param tokenId token id
     * @return days that left to unlock  plus one day
     */
    function _remainingDays(uint256 tokenId) internal view returns (uint64) {
        return (remainingLockedTime(tokenId) / 86400) + 1;
    }

    function _validateTokenId(uint256 tokenId) internal view {
        if (pending[tokenId].recipient == address(0)) {
            revert UnknownTokenIdForClaim(tokenId);
        }
    }

    function _checkTokenForClaim(uint256 tokenId, bool shouldCheckOwner) internal view {
        _validateTokenId(tokenId);

        if (pending[tokenId].untilTimestamp >= uint64(block.timestamp)) {
            revert StillPending(_remainingDays(tokenId), remainingLockedTime(tokenId));
        }

        // if !(
        //     (shouldCheckOwner == false) ||
        //     (
        //         shouldCheckOwner == true &&
        //         pending[tokenId].owner == _msgSender()
        //     )
        // ) {
        //      revert ShouldBeOwner(_msgSender());
        // }

        if ((shouldCheckOwner) && (!shouldCheckOwner || pending[tokenId].recipient != _msgSender())) {
            revert ShouldBeTokenOwner(_msgSender());
        }
    }

    /**
     * for special purchase get getTokenSaleInfo externally to get currency and token separately for each token
     */
    function _getTokenIds(
        uint256 amount, 
        bool isSpecialPurchase
    ) 
        internal 
        view 
        returns (
            uint256[] memory tokenIds, 
            address currencyAddr, 
            uint256 currencyTotalPrice, 
            uint192 lastIndex
        ) 
    {
        tokenIds = new uint256[](amount);

        uint256 amountLeft = amount;

        uint256 tokenId;

        lastIndex = currentAutoIndex;


        address NFTContract = INFTSalesFactory(factoryAddress).instanceToNFTContract(address(this));

        // Is this whole series for sale?
        //INFT.SeriesInfo memory seriesData = INFT(NFTContract).seriesInfo(seriesId);
        // bool isSeriesOnSale = (seriesData.saleInfo.onSaleUntil > block.timestamp);
        uint64 saleInfo_onSaleUntil;
        address saleInfo_currency;
        (, , saleInfo_onSaleUntil, saleInfo_currency, , , , , ) = INFTView(NFTContract).getSeriesInfo(seriesId);
        bool isSeriesOnSale = (saleInfo_onSaleUntil > block.timestamp);
        //console.log(seriesData.saleInfo.onSaleUntil);
        

        if (
            (!isSpecialPurchase && !isSeriesOnSale) ||
            (isSpecialPurchase && !isSeriesOnSale && !evenIfNotOnSale)
        ) {
            revert SeriesIsNotOnSale(seriesId);
        }

        while (lastIndex != MAX_TOKEN_INDEX) {

            tokenId = seriesPart + lastIndex;

            //exists means that  _owners[tokenId] != address(0) && _owners[tokenId] != DEAD_ADDRESS;
            (/*bool isOnSale*/, bool exists, INFT.SaleInfo memory data, /*address beneficiary*/) = INFTView(NFTContract).getTokenSaleInfo(tokenId);

            if (!exists) {
                // !exists - means only virtuals

                // for usual purchase:
                // - increment total price
                // for special purchase - move out of cycle and just calcualte amount*price(stored in contract)
                if (!isSpecialPurchase) {
                    currencyTotalPrice += data.price;
                }
                
                amountLeft--;
                tokenIds[amountLeft] = tokenId; // did it slightly cheaper and do fill from "N-1" to "0" and avoid "stack too deep" error

            }
            if (amountLeft == 0) {
                break;
            }
            lastIndex++;
        }

        if (isSpecialPurchase) {
            currencyAddr = currency;
            currencyTotalPrice = amount * price;
        } else {
            //currencyAddr = seriesData.saleInfo.currency;
            currencyAddr = saleInfo_currency;
            //currencyTotalPrice calculated inside cycle
        }

        if (lastIndex == MAX_TOKEN_INDEX || amountLeft != 0) {
            revert SeriesMaxTokenLimitExceeded(seriesId);
        }

    }

    function getSeriesId(uint256 tokenId) internal pure returns (uint64) {
        return uint64(tokenId >> SERIES_SHIFT_BITS);
    }

    function currentBucketInterval() internal view returns(uint256) {
        return block.timestamp / rateInterval * rateInterval;
    }
}