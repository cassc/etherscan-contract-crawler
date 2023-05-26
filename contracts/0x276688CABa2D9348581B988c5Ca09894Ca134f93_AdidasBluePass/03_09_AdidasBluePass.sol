// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

contract AdidasBluePass is ERC721ABurnable, ERC721AQueryable, Ownable {
    string private _name;
    string private _symbol;
    string public contractUri;
    string public baseUri;

    bool public locked;
    bool public uniqueMetadata;

    mapping(address => bool) public authorized;

    constructor(
        string memory __name,
        string memory __symbol,
        string memory _baseUri,
        string memory _contractUri
    ) ERC721A(__name, __symbol) {
        _name = __name;
        _symbol = __symbol;
        baseUri = _baseUri;
        contractUri = _contractUri;
    }

    modifier onlyAuthorized() {
        require(
            authorized[msg.sender] || owner() == msg.sender,
            "Not authorized or owner"
        );
        _;
    }

    function name()
        public
        view
        virtual
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        return _name;
    }

    function symbol()
        public
        view
        virtual
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        return _symbol;
    }

    function setNameAndSymbol(
        string calldata newName,
        string calldata newSymbol
    ) public onlyOwner {
        _name = newName;
        _symbol = newSymbol;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function setBaseUri(string calldata _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    function setContractUri(string calldata _contractUri) public onlyOwner {
        contractUri = _contractUri;
    }

    function setUniqueMetadata(bool status) public onlyOwner {
        uniqueMetadata = status;
    }

    function mintPass(
        address[] calldata to,
        uint256[] calldata value
    ) external onlyOwner {
        require(to.length == value.length, "Mismatched lengths");
        unchecked {
            for (uint256 i = 0; i < to.length; i++) {
                _mint(to[i], value[i]);
            }
        }
        locked = true;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721A, IERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory base = _baseURI();
        if (uniqueMetadata) {
            return string(abi.encodePacked(base, _toString(tokenId), ".json"));
        } else {
            return base;
        }
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, IERC721A) returns (bool) {
        return ERC721A.supportsInterface(interfaceId);
    }

    function setLocked(bool _locked) external {
        locked = _locked;
    }

    function setAuthorized(address addr, bool status) public onlyOwner {
        authorized[addr] = status;
    }

    function redeemPass(uint256[] memory tokenIds) public onlyAuthorized {
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
        if (!(authorized[msg.sender] || owner() == msg.sender)) {
            require(!locked, "This token is non-transferable");
        }
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }
}