// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "./interfaces/ICryptoPunksMarket.sol";

/**
 * @title ShapeShifter
 * @dev The other Shape--
 *   If shape it might be called that shape had none
 *  Distinguishable in member, joint, or limb;
 *  Or substance might be called that shadow seemed,
 *  For each seemed either--black it stood as Night,
 *  Fierce as ten Furies, terrible as Hell
 */
contract ShapeShifter is Ownable, ERC165, IERC721, IERC721Metadata {
    using Strings for uint256;

    string public name;

    string public symbol;

    address public tokenAddress;

    string public baseTokenURI;

    uint256 public _totalSupply;

    /// @notice all hail the king
    bool public isPunks;

    mapping(address => bool) public minters;

    string public constant R =
        "For Spirits, when they please, Can either sex assume, or both; so soft And uncompounded is their essence pure, Not tried or manacled with joint or limb, Nor founded on the brittle strength of bones, Like cumbrous flesh; but, in what shape they choose, Dilated or condensed, bright or obscure, Can execute their airy purposes, And works of love or enmity fulfil.";

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _tokenAddress,
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI
    ) {
        tokenAddress = _tokenAddress;
        name = _name;
        symbol = _symbol;
        baseTokenURI = _baseTokenURI;
    }

    /*//////////////////////////////////////////////////////////////
                         METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI, tokenId.toString()));
    }

    function totalSupply() public view returns (uint256) {
        if (_totalSupply == 0) {
            return IERC721Enumerable(tokenAddress).totalSupply();
        } else {
            return _totalSupply;
        }
    }

    /*//////////////////////////////////////////////////////////////
                      CONTRACT OWNER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    function setTotalSupply(uint256 _newTotalSupply) public onlyOwner {
        _totalSupply = _newTotalSupply;
    }

    function setIsPunks(bool _newIsPunks) public onlyOwner {
        isPunks = _newIsPunks;
    }

    function setIsMinter(address minter, bool _newIsMinter) public onlyOwner {
        minters[minter] = _newIsMinter;
    }

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    function ownerOf(uint256 id) public view returns (address owner) {
        return
            isPunks
                ? ICryptoPunksMarket(tokenAddress).punkIndexToAddress(id)
                : IERC721(tokenAddress).ownerOf(id);
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        return IERC721(tokenAddress).balanceOf(owner);
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    function getApproved(uint256 tokenId)
        public
        view
        returns (address operator)
    {
        return address(0);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        returns (bool)
    {
        return false;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function mint(address receiver, uint256 tokenId) public {
        require(minters[msg.sender], "not a minter");
        emit Transfer(address(0), receiver, tokenId);
    }

    function mintBulk(address receiver, uint256[] memory tokenIds) public {
        require(minters[msg.sender], "not a minter");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            emit Transfer(address(0), receiver, tokenIds[i]);
        }
    }

    function approve(address spender, uint256 id) public {
        require(false, "WONT APPROVE");
    }

    function setApprovalForAll(address operator, bool approved) public {
        require(false, "WONT APPROVE");
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public {
        require(ownerOf(id) == to, "not owner");
        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public {
        transferFrom(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public {
        transferFrom(from, to, id);
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}