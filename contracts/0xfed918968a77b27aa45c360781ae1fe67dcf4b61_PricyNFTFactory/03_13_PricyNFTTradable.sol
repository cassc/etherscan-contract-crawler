// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import './ERC721A.sol';
import './extensions/ERC721AQueryable.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title PricyNFTTradable
 * PricyNFTTradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
contract PricyNFTTradable is ERC721A, ERC721AQueryable, Ownable {
    using Strings for uint256;

    /// @dev Events of the contract
    event Minted(
        uint256 tokenId,
        address beneficiary,
        string tokenUri,
        address minter
    );
    event UpdatePlatformFee(uint256 platformFee);
    event UpdateFeeRecipient(address payable feeRecipient);

    address auction;
    address marketplace;

    /// @notice Platform fee
    uint256 public platformFee;

    /// @notice Platform fee receipient
    address payable public feeReceipient;
    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    /// @notice Contract constructor
    constructor(
        string memory _name,
        string memory _symbol,
        address _auction,
        address _marketplace,
        uint256 _platformFee,
        address payable _feeReceipient
    ) ERC721A(_name, _symbol) {
        auction = _auction;
        marketplace = _marketplace;
        platformFee = _platformFee;
        feeReceipient = _feeReceipient;
    }

    /**
     @notice Method for updating platform fee
     @dev Only admin
     @param _platformFee uint256 the platform fee to set
     */
    function updatePlatformFee(uint256 _platformFee) external onlyOwner {
        platformFee = _platformFee;
        emit UpdatePlatformFee(_platformFee);
    }

    /**
     @notice Method for updating platform fee address
     @dev Only admin
     @param _feeReceipient payable address the address to sends the funds to
     */
    function updateFeeRecipient(address payable _feeReceipient)
        external
        onlyOwner
    {
        feeReceipient = _feeReceipient;
        emit UpdateFeeRecipient(_feeReceipient);
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */
    function mint(address _to, string calldata _tokenUri) external payable {
        require(msg.value >= platformFee, "Insufficient funds to mint.");

        uint256 newTokenId = _currentIndex;
        _safeMint(_to, 1);
        _setTokenURI(newTokenId, _tokenUri);

        // Send ETH fee to fee recipient
        (bool success, ) = feeReceipient.call{value: msg.value}("");
        require(success, "Transfer failed");

        emit Minted(newTokenId, _to, _tokenUri, _msgSender());
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        return _tokenURI;
    }

    /**
    @notice Burns a DigitalaxGarmentNFT, releasing any composed 1155 tokens held by the token itself
    @dev Only the owner or an approved sender can call this method
    @param _tokenId the token ID to burn
    */
    function burn(uint256 _tokenId) external {
        address operator = _msgSender();
        require(
            ownerOf(_tokenId) == operator || isApproved(_tokenId, operator),
            "Only garment owner or approved"
        );

        // Destroy token mappings
        _burn(_tokenId);
    }

    /**
     * @dev checks the given token ID is approved either for all or the single token ID
     */
    function isApproved(uint256 _tokenId, address _operator)
        public
        view
        returns (bool)
    {
        return
            isApprovedForAll(ownerOf(_tokenId), _operator) ||
            getApproved(_tokenId) == _operator;
    }

    /**
     * Override isApprovedForAll to whitelist Pricy contracts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist Pricy auction, marketplace contracts for easy trading.
        if (auction == operator || marketplace == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
}