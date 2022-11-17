//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../ERC721/ERC721.sol";

contract CNSToken is ERC721, AccessControl, Ownable {
    using Counters for Counters.Counter;
    bytes32 public constant Controller = keccak256("Controller");

    string internal metadataEndpoint = "https://metadata.cns.community/token/";

    Counters.Counter private _tokenIds;
    mapping(uint256 => string) internal _tokenURIs;

    constructor(string memory _tokenName, string memory _tokenSymbol)
        ERC721(_tokenName, _tokenSymbol)
    {}

    function setRole(address _address) public onlyOwner {
        _grantRole(Controller, _address);
    }

    /**
     * @dev Override Transfer Function to Soulbound
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override onlyRole(Controller) {
        require(to != address(0), "ERC721: transfer to the zero address");

        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function changeURIEndpoint(string memory _endpoint) public onlyOwner {
        metadataEndpoint = _endpoint;
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI)
        public
        onlyRole(Controller)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return metadataEndpoint;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory base = _baseURI();
        string memory strToken = Strings.toString(tokenId);
        return string(abi.encodePacked(base, strToken));
    }

    function currentId() public view returns (uint256) {
        return _tokenIds.current();
    }

    function incrementId() public onlyRole(Controller) {
        _tokenIds.increment();
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */

    function mint(address to, uint256 tokenId) public onlyRole(Controller) {
        _mint(to, tokenId);
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function burn(uint256 tokenId) public onlyRole(Controller) {
        _burn(tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function getMetadataEndpoint() public view returns (string memory) {
        return metadataEndpoint;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }
}