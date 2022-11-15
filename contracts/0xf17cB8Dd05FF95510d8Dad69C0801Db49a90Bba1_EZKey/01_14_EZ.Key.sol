//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface IEZMeta is IERC721 {
    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();
    /**
     * A mint was attempted after max supply was already reached.
     */
    error MintAttemptWhenMaxSupplyReached();
}

contract EZKey is IEZMeta, ERC721, Ownable, AccessControl {
    uint16 public maxSupply = 1111;
    // The tokenId of the next token to be minted.
    uint16 private _currentIndex;
    string private _baseTokenURI;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(
        string memory name,
        string memory symbol,
        string memory baseUri_,
        uint16 maxSupply_,
        address minter
    ) ERC721(name, symbol) {
        _currentIndex = 1;
        _baseTokenURI = baseUri_;
        maxSupply = maxSupply_;
        _grantRole(MINTER_ROLE, minter);
    }

    function mintSingle(address receiver, uint256 id) public {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        if (_currentIndex <= maxSupply) {
            _safeMint(receiver, id);
            _currentIndex++;
        } else {
            revert MintAttemptWhenMaxSupplyReached();
        }
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    function addMinter(address minter) external onlyOwner {
        _grantRole(MINTER_ROLE, minter);
    }

    function removeMinter(address minter) external onlyOwner {
        _revokeRole(MINTER_ROLE, minter);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
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

        return
            bytes(baseURI_).length != 0
                ? string(abi.encodePacked(baseURI_, Strings.toString(tokenId)))
                : "";
    }

    function totalSupply() public view returns (uint16) {
        return maxSupply;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}