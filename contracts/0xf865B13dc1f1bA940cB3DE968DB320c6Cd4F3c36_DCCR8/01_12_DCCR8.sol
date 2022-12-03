// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// @author: olive

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///                                                                                                                          ///
///                                                            ___..............._                                           ///
///     /$$$$$$$   /$$$$$$   /$$$$$$                  __.. ' _'.""""""\\""""""""- .`-._                                      ///
///    | $$__  $$ /$$__  $$ /$$__  $$       ______.-'         (_) |      \\           ` \\`-. _                              ///
///    | $$  \ $$| $$  \__/| $$  \__/      /_       --------------'-------\\---....______\\__`.`  -..___                     ///
///    | $$  | $$| $$      | $$            | T      _.----._              |x...           |          _.._`--. _              ///
///    | $$  | $$| $$      | $$            | |    .' ..--.. `.            |XX   DCCR8  == |       .'.---..`.     -._         ///
///    | $$  | $$| $$    $$| $$    $$      \_j   /  /  __  \  \           |XXXXXXXXXXX==  |      / /  __  \ \        `-.     ///
///    | $$$$$$$/|  $$$$$$/|  $$$$$$/       _|  |  |  /  \  |  |          |""'            |     / |  /  \  | |          |    ///
///    |_______/  \______/  \______/       |__\_j  |  \__/  |  L__________|_______________|_____j |  \__/  | L__________J    ///
///                                              `'\ \      / ./__________________________________\ \      / /___________\   ///
///                                                 `.`----'.'   dp                                `.`----'.'                ///
///                                                   `""""'                                         `""""'                  ///
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract DCCR8 is ERC721AQueryable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public MAX_ELEMENTS = 21000;
    uint256 public ELEMENTS_DIVIDER = 10000;

    string[] public baseTokenURIs;

    uint256 private tokenIdTracker = 0;

    bool public META_REVEAL = false;
    uint256 public HIDE_FROM = 1;
    uint256 public HIDE_TO = 21000;
    string public sampleTokenURI;

    mapping(address => bool) internal admins;

    event NewMaxElement(uint256 max);

    constructor()
        ERC721A("Dream Cars Collection R8", "DCCR8")
    {
        admins[msg.sender] = true;
    }

    modifier onlyAdmin() {
        require(admins[_msgSender()], "DCCR8: Caller is not the admin");
        _;
    }

    function setBaseURI(string[] memory _baseURIs)
        public
        onlyAdmin
    {
        baseTokenURIs = _baseURIs;
    }

    function setSampleURI(string memory sampleURI) public onlyAdmin {
        sampleTokenURI = sampleURI;
    }

    function totalToken() public view returns (uint256) {
        return tokenIdTracker;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (!META_REVEAL && tokenId >= HIDE_FROM && tokenId <= HIDE_TO)
            return sampleTokenURI;

        string memory baseURI = baseTokenURIs[(tokenId / ELEMENTS_DIVIDER)];
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A, IERC721A)
        returns (address)
    {
        return super.ownerOf(tokenId);
    }

    function setMaxElement(uint256 _max) public onlyOwner {
        MAX_ELEMENTS = _max;
        emit NewMaxElement(MAX_ELEMENTS);
    }

    function setElementDivider(uint256 _divider) public onlyOwner {
        ELEMENTS_DIVIDER = _divider;
    }

    function setMetaReveal(
        bool _reveal,
        uint256 _from,
        uint256 _to
    ) public onlyAdmin {
        META_REVEAL = _reveal;
        HIDE_FROM = _from;
        HIDE_TO = _to;
    }

    function giftMint(address[] memory _addrs, uint256[] memory _tokenAmounts)
        public
        onlyAdmin
    {
        uint256 totalQuantity = 0;
        uint256 total = totalToken();
        for (uint256 i = 0; i < _addrs.length; i++) {
            totalQuantity += _tokenAmounts[i];
        }
        require(total + totalQuantity <= MAX_ELEMENTS, "DCCR8: Max limit");

        for (uint256 i = 0; i < _addrs.length; i++) {
            tokenIdTracker = tokenIdTracker + _tokenAmounts[i];
            _safeMint(_addrs[i], _tokenAmounts[i]);
        }
    }

    function addAdminRole(address _address) external onlyOwner {
        admins[_address] = true;
    }

    function revokeAdminRole(address _address) external onlyOwner {
        admins[_address] = false;
    }

    function hasAdminRole(address _address) external view returns (bool) {
        return admins[_address];
    }

    function burn(uint256[] calldata tokenIds) external onlyAdmin {
        for (uint8 i = 0; i < tokenIds.length; i++) {
            _burn(tokenIds[i]);
        }
    }

    function _startTokenId()
        internal
        view
        virtual
        override(ERC721A)
        returns (uint256)
    {
        return 1;
    }
}