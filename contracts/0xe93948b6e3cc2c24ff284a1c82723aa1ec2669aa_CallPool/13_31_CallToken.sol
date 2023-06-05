//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721, IERC165, IERC721, IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {ICallToken} from "./interfaces/ICallToken.sol";
import {ICallPoolDeployer} from "./interfaces/ICallPoolDeployer.sol";
import {ICallPoolState} from "./interfaces/pool/ICallPoolState.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Errors} from "./Errors.sol";

contract CallToken is ERC721, IERC721Enumerable, ICallToken, Ownable {
    using Strings for uint256;

    address public immutable override factory;
    address public immutable override nft;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    string private _baseTokenURI;

    constructor() ERC721("NFTCall ", "call") Ownable() {
        (factory, nft, , , ,) = ICallPoolDeployer(msg.sender).parameters();
    }

    modifier onlyFactoryOwner() {
        require(_msgSender() == Ownable(factory).owner(), Errors.CP_CALLER_IS_NOT_FACTORY_OWNER);
        _;
    }

    function name() public view override returns (string memory) {
        return string(abi.encodePacked(ERC721.name(), IERC721Metadata(nft).name(), " Call"));

    }

    function symbol() public view override returns (string memory) {
        return string(abi.encodePacked(ERC721.symbol(), IERC721Metadata(nft).symbol()));
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(block.timestamp <= ICallPoolState(Ownable.owner()).getEndTime(tokenId), "token is expired");
        string memory baseURI = _baseTokenURI;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function ownerOf(uint256 tokenId) public view virtual override(IERC721, ERC721) returns(address) {
        require(block.timestamp <= ICallPoolState(Ownable.owner()).getEndTime(tokenId), "token is expired");
        return ERC721.ownerOf(tokenId);
    }

    function balanceOf(address owner) public view virtual override(IERC721, ERC721) returns(uint256) {
        uint256 balance = 0;
        uint256 currentTime = block.timestamp;
        for(uint256 i = 0; i < _allTokens.length; ++i){
            uint256 tokenId = _allTokens[i];
            if(ERC721.ownerOf(tokenId) == owner && currentTime <= ICallPoolState(Ownable.owner()).getEndTime(tokenId)){
                balance += 1;
            }
        }
        return balance;
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(IERC721, ERC721) {
        uint256 endTime = ICallPoolState(Ownable.owner()).getEndTime(tokenId);
        require(block.timestamp <= endTime, "token is expired");
        ERC721.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(IERC721, ERC721) {
        uint256 endTime = ICallPoolState(Ownable.owner()).getEndTime(tokenId);
        require(block.timestamp <= endTime, "token is expired");
        ERC721.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override(IERC721, ERC721) {
        uint256 endTime = ICallPoolState(Ownable.owner()).getEndTime(tokenId);
        require(block.timestamp <= endTime, "token is expired");
        ERC721.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < _allTokens.length, "owner index out of bounds");
        uint256 currentTime = block.timestamp;
        uint256 userIndex = 0;
        for(uint256 i = 0; i < _allTokens.length; ++i) {
            uint256 tokenId = _allTokens[i];
            if(ERC721.ownerOf(tokenId) == owner && currentTime <= ICallPoolState(Ownable.owner()).getEndTime(tokenId)){
                if(userIndex == index){
                    return tokenId;
                }
                else{
                    userIndex += 1;
                }
            }
        }
        revert("owner index out of bounds");
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        uint256 supply = 0;
        uint256 currentTime = block.timestamp;
        for(uint256 i = 0; i < _allTokens.length; ++i){
            uint256 tokenId = _allTokens[i];
            if(currentTime <= ICallPoolState(Ownable.owner()).getEndTime(tokenId)){
                supply += 1;
            }
        }
        return supply;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        uint256 currentIndex = 0;
        uint256 currentTime = block.timestamp;
        for(uint256 i = 0; i < _allTokens.length; ++i){
            uint256 tokenId = _allTokens[i];
            if(currentTime <= ICallPoolState(Ownable.owner()).getEndTime(tokenId)){
                if(currentIndex == index){
                    return tokenId;
                }
                else{
                    currentIndex += 1;
                }
            }
        }
        revert("ERC721Enumerable: global index out of bounds");
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } 
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
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
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    function mint(address user, uint256 tokenId) external override onlyOwner {
        _safeMint(user, tokenId);
        emit Mint(user, tokenId);
    }

    function burn(uint256 tokenId) external override onlyOwner {
        address owner = ERC721.ownerOf(tokenId);
        _burn(tokenId);
        emit Burn(owner, tokenId);
    }

    function open( address user, uint256 tokenId) external override onlyOwner {
        emit MetadataUpdate(tokenId);
        _transfer(ERC721.ownerOf(tokenId), user, tokenId);
    }

    function updateBaseURI(string calldata baseURI) external override onlyFactoryOwner {
        _baseTokenURI = baseURI;
        emit BaseURIUpdated(baseURI);
        emit BatchMetadataUpdate(0, type(uint256).max);
    }
}