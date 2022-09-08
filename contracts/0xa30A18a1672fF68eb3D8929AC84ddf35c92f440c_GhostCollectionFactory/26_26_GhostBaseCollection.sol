// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../node_modules/@openzeppelin/contracts/access/Ownable.sol';
import '../node_modules/@openzeppelin/contracts/utils/Counters.sol';
import '../node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

/**
 * @title GhostBaseCollection
 * @notice Ghost base collection by factory
 */
contract GhostBaseCollection is ERC721Enumerable, Ownable {
    using SafeERC20 for IERC20;
    using Strings for uint256;

    using Counters for Counters.Counter;
    // Used for generating the tokenId of new NFT minted
    Counters.Counter private _tokenIds;

    event NonFungibleTokenRecovery(address indexed token, uint256 tokenId);
    event TokenRecovery(address indexed token, uint256 amount);
    event Mint(uint256 tokenId, string name, string description, address creator);

    address public admin;

    address public creator;

    struct Token {
        string name; // name of nft
        string description; // description of nft
        string cid; // cid of ipfs
    }

    mapping(uint256 => Token) private _tokens; // Details about the collections

    /**
     * @notice Constructor
     */
    constructor(
        string memory name,
        string memory symbol,
        address _creator,
        address _admin
    ) ERC721(name, symbol) {
        admin = _admin;
        creator = _creator;
    }

    /**
     * @notice Allows the owner to mint a token to a specific address
     * @dev Callable by owner
     */
    function mint(
        string memory _name,
        string memory _description,
        string memory _cid,
        address _to
    ) external onlyOwner returns (uint256) {
        _tokenIds.increment();
        uint256 newId = _tokenIds.current();
        _mint(_to, newId);
        _tokens[newId] = Token({name: _name, description: _description, cid: _cid});
        emit Mint(newId, _name, _description, _to);
        return newId;
    }

    /**
     * @notice Allows the owner to recover non-fungible tokens sent to the contract by mistake
     * @param _token: NFT token address
     * @param _tokenId: tokenId
     * @dev Callable by owner
     */
    function recoverNonFungibleToken(address _token, uint256 _tokenId) external {
        require(msg.sender == admin, 'Operations: Cannot recover only by admin');
        IERC721(_token).transferFrom(address(this), address(msg.sender), _tokenId);
        emit NonFungibleTokenRecovery(_token, _tokenId);
    }

    /**
     * @notice Allows the owner to recover tokens sent to the contract by mistake
     * @param _token: token address
     * @dev Callable by owner
     */
    function recoverToken(address _token) external {
        require(msg.sender == admin, 'Operations: Cannot recover only by admin');
        uint256 balance = IERC20(_token).balanceOf(address(this));
        require(balance != 0, 'Operations: Cannot recover zero balance');
        IERC20(_token).safeTransfer(address(msg.sender), balance);
        emit TokenRecovery(_token, balance);
    }

    /**
     * @notice Returns the Uniform Resource Identifier (URI) for a token ID
     * @param tokenId: token ID
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
        return bytes(_tokens[tokenId].cid).length > 0 ? string(abi.encodePacked('ipfs://', _tokens[tokenId].cid)) : '';
    }
}