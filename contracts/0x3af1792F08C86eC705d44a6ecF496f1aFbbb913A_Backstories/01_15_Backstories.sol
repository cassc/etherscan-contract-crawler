// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract Backstories is ERC2981, ERC721Enumerable, Ownable {

    // 0 = closed
    // 1 = open
    uint256 public _mintStatus;
    string public _contractURI;
    string public _baseTokenURI;

    uint256 public constant _MAX_LIMIT = 9_999;
    address public immutable _CC_ADDRESS;

    error MintingClosed();
    error ExceedsMax();
    error TokenExists();
    error InvalidCat();
    error InvalidData();

    /** Events */
    event LogMinted(address indexed user, uint256 tokenId);
    event LogBaseTokenUriSet(string newUri);
    event LogContractUriSet(string newUri);
    event LogMintWindowSet(uint256 isOpen);

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI,
        string memory contractURI,
        address ccAddress
    ) ERC721(name, symbol) {
        _baseTokenURI = baseURI;
        _contractURI = contractURI;
        _CC_ADDRESS = ccAddress;
    }

    /// @notice Check the open status of minting
    modifier open() {
        if (_mintStatus == 0) {
            revert MintingClosed();
        }
        _;
    }

    /// @notice This function mints the comics to the user
    /// @dev for token. The owner could change during that time
    /// @param to - Address to receive token
    /// @param tokenId - Id of corresponding CC token
    function mintStory(address to, uint256 tokenId) external open onlyOwner payable {
        _mintStory(to, tokenId);
    }

    /// @notice Bulk mint stories
    /// @dev Limit to 150 to be safe on gas
    /// @param tos - Addresses to receive token
    /// @param tokenIds - Ids of corresponding CC token
    function bulkMintStory(address[] calldata tos, uint256[] calldata tokenIds) external open onlyOwner payable {
        uint256 len = tos.length;
        if(len == 0 || len != tokenIds.length) revert InvalidData();

        uint256 i;
        do {
            _mintStory(tos[i], tokenIds[i]);
            unchecked {
                ++ i;
            }
        } while (i < len);
    }

    /// @notice Mint stories
    /// @param to - Addresse to receive token
    /// @param tokenId - Id of corresponding CC token
    function _mintStory (address to, uint256 tokenId) internal {
        if (tokenId > _MAX_LIMIT) revert ExceedsMax();
        if (_exists(tokenId)) revert TokenExists();

        // Reverts if token is burned/not minted
        // We dont care who owns it, could have transferred since BS was purchased
        ERC721(_CC_ADDRESS).ownerOf(tokenId);

        _mint(to, tokenId);
    }

    /** GETTERS */

    /// @notice Returns the base uri string - to the ERC721 contract
    /// @return string - Base uri string
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /// @notice Returns storefront data
    /// @return string - Contract uri string
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// @notice Returns the wallet of an address
    /// @param owner - Address to check
    /// @return uint256[] - Array of owners tokens
    function walletOfOwner(address owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount;) {
            tokensId[i] = tokenOfOwnerByIndex(owner, i);
            unchecked{
                ++i;
            }
        }
        return tokensId;
    }

    /** SETTERS */

    /// @notice Set the contract storefront URI
    /// @param newURI - The uri to be used
    function setContractURI(string memory newURI) external onlyOwner {
        _contractURI = newURI;

        emit LogContractUriSet(newURI);
    }

    /// @notice Set the contract base URI
    /// @param newURI - The uri to be used
    function setBaseURI(string memory newURI) external onlyOwner {
        _baseTokenURI = newURI;

        emit LogBaseTokenUriSet(newURI);
    }

    /// @notice Sets the mint window
    /// @param isOpen - 1 : window open, 0: closed
    function setMintWindow(uint256 isOpen) external onlyOwner {
        _mintStatus = isOpen;

        emit LogMintWindowSet(isOpen);
    }

    /// @notice Sets royalty values
    /// @param receiver - Address to set royalties to
    /// @param feeBasisPoints - Royalty as basis points
    function setDefaultRoyalty(address receiver, uint96 feeBasisPoints) external onlyOwner {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    /// @notice Check interface support
    /// @param interfaceId - Interface identifier
    /// @return boolean - Is the interfaceId supported
    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721Enumerable, ERC2981)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}