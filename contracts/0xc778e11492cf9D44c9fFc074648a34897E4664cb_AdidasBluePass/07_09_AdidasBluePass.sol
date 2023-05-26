// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract AdidasBluePass is ERC721A, ERC2981, Ownable {
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Token symbol
    uint256 private _maxSupply;

    // Base uri
    string public baseUri = "";

    // Blocking transactions
    bool private locked = false;

    // Authorized operators
    mapping(address => bool) public authorized;

    // Unique metadata per token
    bool public uniqueMetadata;

    constructor(
        string memory __name,
        string memory __symbol,
        string memory _baseUri,
        uint256 __maxSupply
    ) ERC721A(__name, __symbol) {
        _name = __name;
        _symbol = __symbol;
        _maxSupply = __maxSupply;
        baseUri = _baseUri;
        _setDefaultRoyalty(msg.sender, 0);
    }

    modifier onlyAuthorized() {
        require(
            authorized[msg.sender] || owner() == msg.sender,
            "Not authorized or owner"
        );
        _;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    function isLocked() public view returns (bool) {
        return locked;
    }

    function setNameAndSymbol(
        string calldata __name,
        string calldata __symbol
    ) public onlyOwner {
        _name = __name;
        _symbol = __symbol;
    }

    // baseURI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    /**
     * @param _baseUri sets the new baseUri
     */
    function setBaseUri(string calldata _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    function setUniqueMetadata(bool status) public onlyOwner {
        uniqueMetadata = status;
    }

    /**
     * @param to array of destination addresses
     * @param value the amount of tokens to minted
     */
    function mintMany(
        address[] calldata to,
        uint256[] calldata value
    ) external onlyOwner {
        require(to.length == value.length, "Mismatched lengths");
        uint256 count = to.length;
        unchecked {
            for (uint256 i = 0; i < count; ) {
                // mint value amount for to address
                uint256 newMax = _totalMinted() + value[i];
                require(_maxSupply >= newMax, "Max supply reached");
                _mint(to[i], value[i]);
                i++;
            }
        }
        locked = true;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory base = _baseURI();
        if (uniqueMetadata) {
            return string(abi.encodePacked(base, _toString(tokenId), ".json"));
        } else {
            return base;
        }
    }

    // Interface Support
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    /**
     * @param _locked enables/disables Transfers
     */
    function setLocked(bool _locked) external {
        locked = _locked;
    }

    function setAuthorized(address addr, bool status) public onlyOwner {
        authorized[addr] = status;
    }

    function burn(uint256 tokenId) public {
        require(
            ownerOf(tokenId) == msg.sender,
            "Caller is not the token owner"
        );
        _burn(tokenId);
    }

    function burnByOperator(uint256[] memory tokenIds) public onlyAuthorized {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _burn(tokenIds[i]);
        }
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        if (!authorized[msg.sender]) {
            require(!locked, "This token is non-transferable");
        }
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }
}