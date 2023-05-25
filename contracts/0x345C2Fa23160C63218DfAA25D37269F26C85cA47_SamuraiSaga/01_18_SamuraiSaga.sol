// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/INftCollection.sol";
import "./libraries/Recoverable.sol";

/**
 * @title SamuraiSaga
 * @notice Samurai Saga ERC721 NFT collection
 * http://samuraisaga.com
 */
contract SamuraiSaga is Ownable, ERC721Enumerable, Recoverable, INftCollection {
    using SafeERC20 for IERC20;
    using Strings for uint256;

    uint256 public immutable maxSupply;

    bool public isLocked;
    string public baseURI;
    string public contractURI;

    event Lock();

    receive() external payable {}

    /**
     * @notice Constructor
     * @param _maxSupply: NFT max totalSupply
     */
    constructor(uint256 _maxSupply) ERC721("Samurai Saga", "SSAGA") {
        maxSupply = _maxSupply;
    }

    /**
     * @notice Allows the owner to lock the contract
     * @dev Callable by owner
     */
    function lock() external onlyOwner {
        require(!isLocked, "Operations: Contract is locked");
        require(bytes(baseURI).length > 0, "Operations: BaseUri not set");
        isLocked = true;
        emit Lock();
    }

    /**
     * @notice Allows the owner to mint a token to a specific address
     * @param _to: address to receive the token
     * @param _tokenId: tokenId
     * @dev Callable by owner
     */
    function mint(address _to, uint256 _tokenId) external onlyOwner {
        require(totalSupply() < maxSupply, "NFT: Total supply reached");
        _mint(_to, _tokenId);
    }

    /**
     * @notice Allows the owner to set the base URI to be used for all token IDs
     * @param _uri: base URI
     * @dev Callable by owner
     */
    function setBaseURI(string memory _uri) external onlyOwner {
        require(!isLocked, "Operations: Contract is locked");
        baseURI = _uri;
    }

    function setContractURI(string memory _uri) external onlyOwner {
        require(!isLocked, "Operations: Contract is locked");
        contractURI = _uri;
    }

    /**
     * @notice Returns a list of token IDs owned by `user` given a `cursor` and `size` of its token list
     * @param user: address
     * @param cursor: cursor
     * @param size: size
     */
    function tokensOfOwnerBySize(
        address user,
        uint256 cursor,
        uint256 size
    ) external view returns (uint256[] memory, uint256) {
        uint256 length = size;
        if (length > balanceOf(user) - cursor) {
            length = balanceOf(user) - cursor;
        }

        uint256[] memory values = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            values[i] = tokenOfOwnerByIndex(user, cursor + i);
        }

        return (values, cursor + length);
    }

    /**
     * @notice Returns the Uniform Resource Identifier (URI) for a token ID
     * @param tokenId: token ID
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Invalid tokenId");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function transferOwnership(address newOwner) public override(Ownable, INftCollection) {
        Ownable.transferOwnership(newOwner);
    }
}