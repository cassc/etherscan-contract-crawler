//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "openzeppelin-solidity/contracts/utils/Strings.sol";
import "../biconomy/EIP712MetaTransaction.sol";

/**
 * DGFamily Collection
 * https://drops.unxd.com/dgfamily
 */
contract DGFamilyCollection is
    ERC721URIStorage,
    Ownable,
    EIP712MetaTransaction
{
    using Strings for uint256;
    using SafeMath for uint256;

    string private baseURI;
    uint256 public constant MAX_PUBLIC_SUPPLY = 5000;
    uint256 public totalSupply;
    uint256 public royaltyPercentage;
    address public glassBoxContract;
    address public privateSaleContract;
    mapping(uint256 => bool) public privateSaleTokenIds;

    /*********************************
     *  EVENTS
     *********************************/
    event RoyaltyPercentageChanged(uint256 indexed newPercentage);
    event BaseUriUpdated(string indexed uri);

    /** @notice Initiator
     * @param tokenName The name of the NFT token
     * @param tokenSymbol The symbol of the NFT tokens
     * @param _baseUri The tokenURI base string
     * @param _royaltyPercentage Percentage of royalty to be taken per sale
     * @param _privateSaleTokenIds List of tokensIds to used in private sale
     */

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        string memory _baseUri,
        uint256 _royaltyPercentage,
        uint256[] memory _privateSaleTokenIds
    )
        ERC721(tokenName, tokenSymbol)
        EIP712MetaTransaction("NftCollectionBatch", "1")
    {
        baseURI = _baseUri;
        royaltyPercentage = _royaltyPercentage;
        for (uint256 i = 0; i < _privateSaleTokenIds.length; i = i.add(1)) {
            privateSaleTokenIds[_privateSaleTokenIds[i]] = true;
        }
    }

    modifier onlyGlassBoxOrOwnerOrPrivateSale() {
        require(
            glassBoxContract == msgSender() || owner() == msgSender() || privateSaleContract == msgSender(),
            "UNAUTHORIZED_ACCESS"
        );
        _;
    }

    /** @notice Set baseURI for metafile root path
     *  @dev Emits "BaseUriUpdates"
     * @param uri The new uri for tokenURI bsae
     */
    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
        emit BaseUriUpdated(baseURI);
    }

    /** @notice Sets royalty percentage for secondary sale
     * @dev Emits "RoyaltyPercentageChanged"
     * @param _percentage The percentage of royalty to be deducted
     */
    function setRoyaltyPercentage(uint256 _percentage) external onlyOwner {
        royaltyPercentage = _percentage;

        emit RoyaltyPercentageChanged(royaltyPercentage);
    }

    /**
     * Mint the NFT.
     * @param destination wallet address
     * @return tokenId of newly minted nft.
     */
    function generate(address destination, uint256 tokenIndex)
        external
        onlyGlassBoxOrOwnerOrPrivateSale
        returns (uint256)
    {
        require(destination != address(0), "ADDRESS_CAN_NOT_BE_ZERO");
        require(
            totalSupply < MAX_PUBLIC_SUPPLY,
            "MAX_PUBLIC_SUPPLY_REACHED"
        );
        if ((privateSaleContract == msgSender()) || (owner() == msgSender())) {
            require(
                privateSaleTokenIds[tokenIndex],
                "PRIVATE_SALE_PERMISSION_DENIED"
            );
        }
        totalSupply = totalSupply.add(1);
        _safeMint(destination, tokenIndex);
        return tokenIndex;
    }

    /**
     * Get royalty amount at any specific price.
     * @param _price: price for sale.
     */
    function getRoyaltyInfo(uint256 _price)
        external
        view
        returns (uint256 royaltyAmount, address royaltyReceiver)
    {
        require(_price > 0, "PRICE_CAN_NOT_BE_ZERO");
        uint256 royalty = (_price.mul(royaltyPercentage)).div(100);

        return (royalty, owner());
    }

    /**
     * Set the glass box contract address which will be calling the generate NFT method.
     * @param _address: glass box contract address.
     */
    function setGlassBoxContract(address _address) external onlyOwner {
        glassBoxContract = _address;
    }

    /**
     * Set the private sale contract address which will be calling the generate NFT method.
     * @param _address: contract address.
     */
    function setPrivateSaleContract(address _address) external onlyOwner {
        privateSaleContract = _address;
    }

    /** @notice Provides token URI of the NFT
     * @param _tokenId The id of the specific NFT
     * @return The URI string for the token's metadata file
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721URIStorage)
        returns (string memory)
    {
        if (totalSupply == 0) {
            return _baseURI();
        }
        require(_exists(_tokenId), "TOKEN_DOES_NOT_EXIST");

        /// @dev Convert string to bytes so we can check if it's empty or not.
        return string(abi.encodePacked(_baseURI(), _tokenId.toString()));
    }

    /**
     * @dev See {IERC721-transferFrom}.
     * @notice Only Trusted Marketplace contract can use
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(
            _isApprovedOrOwner(msgSender(), tokenId),
            "CALLER_NOT_APPROVED"
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     * @notice Only Trusted Marketplace contract can use
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(msgSender(), tokenId),
            "CALLER_NOT_APPROVED"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    /// @dev Overridden function to prevent Owner from relinquishing Ownership by accident
    function renounceOwnership() public view override onlyOwner {
        revert("CAN_NOT_RENOUNCE_OWNERSHIP");
    }

    /**@dev Returns baseURI
     */

    function approve(address to, uint256 tokenId) public virtual override {
        address tokenOwner = ERC721.ownerOf(tokenId);
        require(to != tokenOwner, "ERC721:APPROVAL_TO_CURRENT_OWNER");

        require(
            msgSender() == tokenOwner ||
                isApprovedForAll(tokenOwner, msgSender()),
            "ERC721:APPROVE_CALLER_NOT_OWNER_OR_APPROVED_FOR_ALL"
        );

        _approve(to, tokenId);
    }

    /**
     * Get base URI for collection.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}