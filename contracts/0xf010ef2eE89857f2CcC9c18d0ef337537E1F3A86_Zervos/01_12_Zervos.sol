// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Zervos is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private supply;

    string public uriPrefix = "";
    string public uriSuffix = ".json";

    uint256 public maxSupply;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        string memory _uriPrefix
    ) ERC721(_name, _symbol) {
        maxSupply = _maxSupply;
        setUriPrefix(_uriPrefix);
    }

    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    function mintForAddress(address _receiver) public onlyOwner {
        require(supply.current() + 1 <= maxSupply, "Max supply exceeded!");
        supply.increment();
        _safeMint(_receiver, supply.current());
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    /**
     * @notice Zervos: Block transfers.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721) {
        require(
            from == address(0) || to == address(0),
            "Zervos: Non-Transferable"
        );
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @notice Zervos: Block approvals.
     */
    function setApprovalForAll(address operator, bool _approved)
        public
        virtual
        override(ERC721)
    {
        revert("Zervos: Non-Transferable");
    }

    /**
     * @notice Zervos: Block approvals.
     */
    function approve(address to, uint256 tokenId)
        public
        virtual
        override(ERC721)
    {
        revert("Zervos: Non-Transferable");
    }
}