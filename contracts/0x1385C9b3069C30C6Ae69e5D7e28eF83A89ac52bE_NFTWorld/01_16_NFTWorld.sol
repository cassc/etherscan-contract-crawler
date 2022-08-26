// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract NFTWorld is ERC721Enumerable, Ownable {
    using SafeERC20 for IERC20;

    uint public immutable maxSupply;
    uint public currentTokenId;
    bool public isLocked;
    string public baseURI;

    event Lock();
    event NonFungibleTokenRecovery(address indexed token, uint256 tokenId);
    event TokenRecovery(address indexed token, uint256 amount);

    mapping(uint256 => string) public tokenHash;
    mapping(address => bool) public minter;

    modifier onlyMinter() {
        require(minter[_msgSender()], "MNFTWorld: caller is not the minter");
        _;
    }
    /**
     * @notice Constructor
     * @param _name: NFT name
     * @param _symbol: NFT symbol
     * @param _maxSupply: NFT max totalSupply
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        string memory _uri
    ) ERC721(_name, _symbol) {
        maxSupply = _maxSupply;
        minter[_msgSender()] = true;
        baseURI = _uri;
    }
    /**
     * @notice Allows the owner to lock the contract
     * @dev Callable by owner
     */
    function lock() external onlyOwner {
        require(!isLocked, "Operations: Contract is locked");
        isLocked = true;
        emit Lock();
    }

    /**
     * @notice Allows the owner to mint a token to a specific address
     * @param _to: address to receive the token
     * @param _tokenId: tokenId
     * @dev Callable by owner
     */
    function mint(address _to, uint256 _tokenId, string memory _tokenHash) external onlyMinter {
        require(totalSupply() < maxSupply, "NFT: Total supply reached");
        require(_tokenId <= currentTokenId+1, "NFT: invalid token Id");
        _mint(_to, _tokenId);
        tokenHash[_tokenId] = _tokenHash;
        currentTokenId++;
    }
    function mints(uint n, address _to, string[] memory _tokenHash) external onlyMinter {
        require(totalSupply() < maxSupply, "NFT: Total supply reached");
        for(uint i = 0; i < n; i++) {
            uint tokenId = currentTokenId + i + 1;
            _mint(_to, tokenId);
            tokenHash[tokenId] = _tokenHash[i];
        }
        currentTokenId += n;
    }
    function mints(uint n, address _to, string memory _tokenHash) external onlyMinter {
        require(totalSupply() < maxSupply, "NFT: Total supply reached");
        for(uint i = 0; i < n; i++) {
            uint tokenId = currentTokenId + i + 1;
            _mint(_to, tokenId);
            tokenHash[tokenId] = _tokenHash;
        }
        currentTokenId += n;
    }
    /**
         * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) external virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
    /**
     * @notice Allows the owner to recover non-fungible tokens sent to the contract by mistake
     * @param _token: NFT token address
     * @param _tokenId: tokenId
     * @dev Callable by owner
     */
    function recoverNonFungibleToken(address _token, uint256 _tokenId) external onlyOwner {
        IERC721(_token).transferFrom(address(this), address(msg.sender), _tokenId);

        emit NonFungibleTokenRecovery(_token, _tokenId);
    }

    /**
     * @notice Allows the owner to recover tokens sent to the contract by mistake
     * @param _token: token address
     * @dev Callable by owner
     */
    function recoverToken(address _token) external onlyOwner {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        require(balance != 0, "Operations: Cannot recover zero balance");

        IERC20(_token).safeTransfer(address(msg.sender), balance);

        emit TokenRecovery(_token, balance);
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenHash[tokenId])) : "";
    }
    function setMinter(address _minter) public onlyOwner {
        minter[_minter] = !minter[_minter];
    }
}