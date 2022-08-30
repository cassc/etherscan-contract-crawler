// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

pragma solidity ^0.8.7;

contract DunhuangArt is ERC721AQueryable, Ownable, Pausable, ReentrancyGuard {
    event BaseURIChanged(string newBaseURI);
    event WhitelistSaleConfigChanged(WhitelistSaleConfig config);
    event PublicSaleConfigChanged(PublicSaleConfig config);
    event RefundGuaranteeConfigChanged(RefundGuaranteeConfig config);
    event Withdraw(address indexed account, uint256 amount);
    event ContractSealed();

    struct WhitelistSaleConfig {
        uint64 mintQuota;
        uint256 startTime;
        uint256 endTime;
        bytes32 merkleRoot;
        uint256 price;
        uint256 discountPrice;
        bytes32 discountMerkleRoot;
    }

    struct PublicSaleConfig {
        uint256 startTime;
        uint256 price;
    }

    struct RefundGuaranteeConfig {
        uint256 endTime;
        address refundAddress;
    }

    uint64 public constant MAX_TOKEN = 3000;
    uint64 public constant MAX_TOKEN_PER_MINT = 2;

    WhitelistSaleConfig public whitelistSaleConfig;
    PublicSaleConfig public publicSaleConfig;
    RefundGuaranteeConfig public refundGuaranteeConfig;
    bool public contractSealed;
    string public baseURI;
    string public revealingURI;

    uint256[7] private discountFields = [0, 0, 0, 0, 0, 0, 0];
    mapping(uint256 => bool) public hasRefunded;

    constructor() ERC721A("Dunhuang Art", "DHA") {}

    /***********************************|
    |               Core                |
    |__________________________________*/

    function refund(uint256[] calldata tokenIds) external nonReentrant {
        require(isRefundGuaranteeActive(), "Refund expired");

        uint256 refundAmount = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(_msgSender() == ownerOf(tokenId), "Not token owner");
            require(!hasRefunded[tokenId], "Already refunded");
            hasRefunded[tokenId] = true;
            transferFrom(
                _msgSender(),
                refundGuaranteeConfig.refundAddress,
                tokenId
            );

            if (isTokenDiscountSale(tokenId)) {
                refundAmount += whitelistSaleConfig.discountPrice;
            } else {
                refundAmount += publicSaleConfig.price;
            }
        }
        payable(_msgSender()).transfer(refundAmount);
    }

    /**
     * @notice giveaway is used for airdropping to specific addresses.
     * The issuer also reserves tokens through this method.
     * This process is under the supervision of the community.
     * @param address_ the target address of airdrop
     * @param numberOfTokens_ the number of airdrop
     */
    function giveaway(address address_, uint64 numberOfTokens_)
        external
        onlyOwner
        nonReentrant
    {
        require(address_ != address(0), "zero address");
        require(numberOfTokens_ > 0, "invalid number of tokens");
        require(
            totalMinted() + numberOfTokens_ <= MAX_TOKEN,
            "max supply exceeded"
        );
        _safeMint(address_, numberOfTokens_);
    }

    /**
     * @notice whitelistSale is used for whitelist sale.
     * @param numberOfTokens_ quantity
     * @param signature_ merkel proof
     * @param discountSignature_ discount merkel proof
     */
    function whitelistSale(
        uint64 numberOfTokens_,
        bytes32[] calldata signature_,
        bytes32[] calldata discountSignature_
    ) external payable callerIsUser nonReentrant {
        require(isWhitelistSaleEnabled(), "whitelist sale has not enabled");
        require(
            isWhitelistAddress(_msgSender(), signature_),
            "caller is not in whitelist or invalid signature"
        );
        uint64 whitelistMinted = _getAux(_msgSender()) + numberOfTokens_;
        require(
            whitelistMinted <= whitelistSaleConfig.mintQuota,
            "max mint amount per wallet exceeded"
        );

        uint256 price;
        if (isDiscountAddress(_msgSender(), discountSignature_)) {
            price = getWhitelistDiscountPrice();

            uint256 startTokenId = _nextTokenId();
            uint256 end = startTokenId + numberOfTokens_;
            for (uint256 i = startTokenId; i < end; i++) {
                setTokenDiscountSale(i);
            }
        } else {
            price = getWhitelistSalePrice();
        }

        _sale(numberOfTokens_, price);
        _setAux(_msgSender(), whitelistMinted);
    }

    /**
     * @notice publicSale is used for public sale.
     * @param numberOfTokens_ quantity
     */
    function publicSale(uint64 numberOfTokens_)
        external
        payable
        callerIsUser
        nonReentrant
    {
        require(isPublicSaleEnabled(), "public sale has not enabled");
        _sale(numberOfTokens_, getPublicSalePrice());
    }

    /**
     * @notice internal method, _sale is used to sell tokens at the specified unit price.
     * @param numberOfTokens_ quantity
     * @param price_ unit price
     */
    function _sale(uint64 numberOfTokens_, uint256 price_) internal {
        require(numberOfTokens_ > 0, "invalid number of tokens");
        require(
            numberOfTokens_ <= MAX_TOKEN_PER_MINT,
            "can only mint MAX_TOKEN_PER_MINT tokens at a time"
        );
        require(
            totalMinted() + numberOfTokens_ <= MAX_TOKEN,
            "max supply exceeded"
        );
        uint256 amount = price_ * numberOfTokens_;
        require(amount <= msg.value, "ether value sent is not correct");
        _safeMint(_msgSender(), numberOfTokens_);
        refundExcessPayment(amount);
    }

    /**
     * @notice when the amount paid by the user exceeds the actual need, the refund logic will be executed.
     * @param amount_ the actual amount that should be paid
     */
    function refundExcessPayment(uint256 amount_) private {
        if (msg.value > amount_) {
            payable(_msgSender()).transfer(msg.value - amount_);
        }
    }

    /**
     * @notice issuer withdraws the ETH temporarily stored in the contract through this method.
     */
    function withdraw() external onlyOwner nonReentrant {
        require(
            block.timestamp > refundGuaranteeConfig.endTime,
            "Refund period not over"
        );
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
        emit Withdraw(_msgSender(), balance);
    }

    /***********************************|
    |               Getter              |
    |__________________________________*/

    function isTokenRefunded(uint256 tokenId_) public view returns (bool) {
        return hasRefunded[tokenId_];
    }
    
    function refundableTokensOfOwner(address owner)
        external
        view
        virtual
        returns (uint256[] memory)
    {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (
                uint256 i = _startTokenId();
                tokenIdsIdx != tokenIdsLength;
                ++i
            ) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }

            uint256 size = 0;
            for (uint256 i = 0; i < tokenIds.length; ++i) {
                if (isTokenRefunded(tokenIds[i]) == false) {
                    ++size;
                }
            }

            uint256 j = 0;
            uint256[] memory refundableTokens = new uint256[](size);
            for (uint256 i = 0; i < tokenIds.length; ++i) {
                if (isTokenRefunded(tokenIds[i]) == false) {
                    refundableTokens[j++] = tokenIds[i];
                }
            }
            return refundableTokens;
        }
    }

    function isRefundGuaranteeActive() public view returns (bool) {
        return (block.timestamp <= refundGuaranteeConfig.endTime);
    }

    function getRefundGuaranteeEndTime() public view returns (uint256) {
        return refundGuaranteeConfig.endTime;
    }

    function isTokenDiscountSale(uint256 tokenId_) public view returns (bool) {
        if (tokenId_ >= discountFields.length * 256) {
            return false;
        }

        uint256 i = tokenId_ / 256;
        uint256 j = tokenId_ % 256;

        return discountFields[i] & (1 << j) != 0;
    }

    function setTokenDiscountSale(uint256 tokenId_) private {
        require(tokenId_ < discountFields.length * 256, "out of range");

        uint256 i = tokenId_ / 256;
        uint256 j = tokenId_ % 256;

        discountFields[i] = discountFields[i] | (1 << j);
    }

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice isWhitelistSaleEnabled is used to return whether whitelist sale has been enabled.
     */
    function isWhitelistSaleEnabled() public view returns (bool) {
        if (
            whitelistSaleConfig.endTime > 0 &&
            block.timestamp > whitelistSaleConfig.endTime
        ) {
            return false;
        }
        return
            whitelistSaleConfig.startTime > 0 &&
            block.timestamp > whitelistSaleConfig.startTime &&
            whitelistSaleConfig.price > 0 &&
            whitelistSaleConfig.merkleRoot != "";
    }

    /**
     * @notice isPublicSaleEnabled is used to return whether the public sale has been enabled.
     */
    function isPublicSaleEnabled() public view returns (bool) {
        return
            publicSaleConfig.startTime > 0 &&
            block.timestamp > publicSaleConfig.startTime &&
            publicSaleConfig.price > 0;
    }

    /**
     * @notice isDiscountAddress is used to verify whether the given address_ and signature_ belong to discountMerkleRoot.
     * @param address_ address of the caller
     * @param signature_ merkle proof
     */
    function isDiscountAddress(address address_, bytes32[] calldata signature_)
        public
        view
        returns (bool)
    {
        if (whitelistSaleConfig.discountMerkleRoot == "") {
            return false;
        }
        return
            MerkleProof.verify(
                signature_,
                whitelistSaleConfig.discountMerkleRoot,
                keccak256(abi.encodePacked(address_))
            );
    }

    /**
     * @notice isWhitelistAddress is used to verify whether the given address_ and signature_ belong to merkleRoot.
     * @param address_ address of the caller
     * @param signature_ merkle proof
     */
    function isWhitelistAddress(address address_, bytes32[] calldata signature_)
        public
        view
        returns (bool)
    {
        if (whitelistSaleConfig.merkleRoot == "") {
            return false;
        }
        return
            MerkleProof.verify(
                signature_,
                whitelistSaleConfig.merkleRoot,
                keccak256(abi.encodePacked(address_))
            );
    }

    /**
     * @notice getPublicSalePrice is used to get the price of the public sale.
     * @return price
     */
    function getPublicSalePrice() public view returns (uint256) {
        return publicSaleConfig.price;
    }

    /**
     * @notice getWhitelistDiscountPrice is used to get the price of the whitelist discount sale.
     * @return discountPrice
     */
    function getWhitelistDiscountPrice() public view returns (uint256) {
        return whitelistSaleConfig.discountPrice;
    }

    /**
     * @notice getWhitelistSalePrice is used to get the price of the whitelist sale.
     * @return price
     */
    function getWhitelistSalePrice() public view returns (uint256) {
        return whitelistSaleConfig.price;
    }

    /**
     * @notice totalMinted is used to return the total number of tokens minted.
     * Note that it does not decrease as the token is burnt.
     */
    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    /**
     * @notice _baseURI is used to override the _baseURI method.
     * @return baseURI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI_ = _baseURI();
        if (bytes(baseURI_).length == 0) {
            return revealingURI;
        }

        return string(abi.encodePacked(baseURI_, _toString(tokenId), ".json"));
    }

    /***********************************|
    |               Setter              |
    |__________________________________*/

    /**
     * @notice setBaseURI is used to set the base URI in special cases.
     * @param baseURI_ baseURI
     */
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
        emit BaseURIChanged(baseURI_);
    }

    /**
     * @notice setRevealingURI is used to set the revealing URI in special cases.
     * @param revealingURI_ revealingURI
     */
    function setRevealingURI(string calldata revealingURI_) external onlyOwner {
        revealingURI = revealingURI_;
    }

    /**
     * @notice setRefundGuaranteeConfig is used to set the configuration related to refund.
     * This process is under the supervision of the community.
     * @param config_ config
     */
    function setRefundGuaranteeConfig(RefundGuaranteeConfig calldata config_)
        external
        onlyOwner
    {
        require(
            config_.refundAddress != address(0),
            "refund address must not be zero"
        );
        require(
            config_.endTime >= refundGuaranteeConfig.endTime,
            "end time only delay"
        );
        refundGuaranteeConfig = config_;
        emit RefundGuaranteeConfigChanged(config_);
    }

    /**
     * @notice setWhitelistSaleConfig is used to set the configuration related to whitelist sale.
     * This process is under the supervision of the community.
     * @param config_ config
     */
    function setWhitelistSaleConfig(WhitelistSaleConfig calldata config_)
        external
        onlyOwner
    {
        require(config_.price > 0, "sale price must greater than zero");
        require(
            config_.discountPrice > 0,
            "discount price must greater than zero"
        );
        whitelistSaleConfig = config_;
        emit WhitelistSaleConfigChanged(config_);
    }

    /**
     * @notice setPublicSaleConfig is used to set the configuration related to public sale.
     * This process is under the supervision of the community.
     * @param config_ config
     */
    function setPublicSaleConfig(PublicSaleConfig calldata config_)
        external
        onlyOwner
    {
        require(config_.price > 0, "sale price must greater than zero");
        publicSaleConfig = config_;
        emit PublicSaleConfigChanged(config_);
    }

    /***********************************|
    |               Pause               |
    |__________________________________*/

    /**
     * @notice hook function, used to intercept the transfer of token.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
        require(!paused(), "token transfer paused");
    }

    /**
     * @notice for the purpose of protecting user assets, under extreme conditions,
     * the circulation of all tokens in the contract needs to be frozen.
     * This process is under the supervision of the community.
     */
    function emergencyPause() external onlyOwner notSealed {
        _pause();
    }

    /**
     * @notice unpause the contract
     */
    function unpause() external onlyOwner notSealed {
        _unpause();
    }

    /**
     * @notice when the project is stable enough, the issuer will call sealContract
     * to give up the permission to call emergencyPause and unpause.
     */
    function sealContract() external onlyOwner {
        contractSealed = true;
        emit ContractSealed();
    }

    /***********************************|
    |             Modifier              |
    |__________________________________*/

    /**
     * @notice for security reasons, CA is not allowed to call sensitive methods.
     */
    modifier callerIsUser() {
        require(tx.origin == _msgSender(), "caller is another contract");
        _;
    }

    /**
     * @notice function call is only allowed when the contract has not been sealed
     */
    modifier notSealed() {
        require(!contractSealed, "contract sealed");
        _;
    }
}