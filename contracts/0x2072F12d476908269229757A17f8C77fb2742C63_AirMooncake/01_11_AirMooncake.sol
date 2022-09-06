// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

pragma solidity ^0.8.7;

interface IQueryable {
    function tokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory);

    function ownerOf(uint256 tokenId) external view returns (address);
}

contract AirMooncake is ERC721AQueryable, Ownable, Pausable, ReentrancyGuard {
    event BaseURIChanged(string newBaseURI);
    event RevealingURIChanged(string newRevealingURI);
    event WhitelistSaleConfigChanged(WhitelistSaleConfig config);
    event Withdraw(address indexed account, uint256 amount);
    event ContractSealed();

    struct WhitelistSaleConfig {
        uint64 mintQuota;
        uint256 startTime;
        bytes32 merkleRoot;
        uint256 price;
    }

    uint64 public constant MAX_TOKEN = 4000;
    uint64 public constant MAX_TOKEN_PER_MINT = 2;

    WhitelistSaleConfig public whitelistSaleConfig;
    bool public contractSealed;
    string public baseURI;
    string public revealingURI;
    address public contractAddress;

    mapping(uint256 => bool) public hasExchanged;

    constructor() ERC721A("Air Mooncake", "AM") {}

    /***********************************|
    |               Core                |
    |__________________________________*/

    // ratio -> 1:2
    /**
     * @notice exchangeSale is used for exchange sale.
     * The ratio is 1:2, you can mint 2 tokens per DHA.
     * @param tokenIds the tokens of owner.
     */
    function exchangeSale(uint256[] calldata tokenIds)
        external
        payable
        callerIsUser
        nonReentrant
    {
        uint256 size = tokenIds.length;
        require(isWhitelistSaleEnabled(), "exchange sale has not enabled");
        require(size > 0, "invalid number of tokens");
        require(isDHATokensEnabled(tokenIds), "all DHA tokens has not enabled");

        uint64 numberOfTokens = uint64(size) * 2;
        require(
            totalMinted() + numberOfTokens <= MAX_TOKEN,
            "max supply exceeded"
        );

        uint256 price = getWhitelistSalePrice();
        uint256 amount = price * numberOfTokens;
        require(amount <= msg.value, "ether value sent is not correct");

        for (uint256 i = 0; i < size; i++) {
            hasExchanged[tokenIds[i]] = true;
        }
        _safeMint(_msgSender(), numberOfTokens);
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
     * @param signature_ merkle proof
     */
    function whitelistSale(
        uint64 numberOfTokens_,
        bytes32[] calldata signature_
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

        _sale(numberOfTokens_, getWhitelistSalePrice());
        _setAux(_msgSender(), whitelistMinted);
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
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
        emit Withdraw(_msgSender(), balance);
    }

    /***********************************|
    |               Getter              |
    |__________________________________*/

    function exchangeableTokensOfOwner(address owner)
        external
        view
        virtual
        returns (uint256[] memory)
    {
        uint256[] memory tokens = IQueryable(contractAddress).tokensOfOwner(
            owner
        );

        uint256 size = 0;
        for (uint256 i = 0; i < tokens.length; ++i) {
            if (hasExchanged[tokens[i]] == false) {
                ++size;
            }
        }

        uint256 j = 0;
        uint256[] memory exchangeableTokens = new uint256[](size);
        for (uint256 i = 0; i < tokens.length; ++i) {
            if (hasExchanged[tokens[i]] == false) {
                exchangeableTokens[j++] = tokens[i];
            }
        }

        return exchangeableTokens;
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
        return
            whitelistSaleConfig.startTime > 0 &&
            block.timestamp > whitelistSaleConfig.startTime &&
            whitelistSaleConfig.price >= 0 &&
            whitelistSaleConfig.merkleRoot != "";
    }

    /**
     * @notice isDHATokensEnabled is used to verify whether all dha tokens belong to sender and exchangeable.
     */
    function isDHATokensEnabled(uint256[] calldata tokenIds)
        internal
        view
        returns (bool)
    {
        uint256 size = tokenIds.length;
        address sender = _msgSender();
        for (uint256 i = 0; i < size; ++i) {
            if (hasExchanged[tokenIds[i]]) {
                return false;
            }
            address owner = IQueryable(contractAddress).ownerOf(tokenIds[i]);
            if (owner != sender) {
                return false;
            }
        }
        return true;
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

    function setContractAddress(address contractAddress_) external onlyOwner {
        contractAddress = contractAddress_;
    }

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
        emit RevealingURIChanged(revealingURI_);
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
        require(config_.price >= 0, "sale price must greater than zero");
        whitelistSaleConfig = config_;
        emit WhitelistSaleConfigChanged(config_);
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