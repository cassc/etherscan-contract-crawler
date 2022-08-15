//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IERC721H.sol";
import "./base64.sol";

contract ERC721HCollection is IERC721H, ERC721Enumerable, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(uint256 => EnumerableSet.AddressSet) tokenId2AuthorizedAddresses;
    mapping(uint256 => mapping(address=> string)) tokenId2Address2Value;
    mapping(uint256 => string) tokenId2ImageUri;

    string private _imageURI;

    constructor() ERC721("Hyperlink NFT Collection", "HNFT") {}

    modifier onlyTokenOwner(uint256 tokenId) {
        require(tx.origin == ownerOf(tokenId) || _msgSender() == ownerOf(tokenId), "should be the token owner");
        _;
    }

    modifier onlySlotManager(uint256 tokenId) {
        require(_msgSender() == ownerOf(tokenId) || tokenId2AuthorizedAddresses[tokenId].contains(_msgSender()), "address should be authorized");
        _;
    }

    function setSlotUri(uint256 tokenId, string calldata value) override external onlySlotManager(tokenId) {
        tokenId2Address2Value[tokenId][_msgSender()] = value;

        emit SlotUriUpdated(tokenId, _msgSender(), value);
    }

    function getSlotUri(uint256 tokenId, address slotManagerAddr) override external view returns (string memory) {
        return tokenId2Address2Value[tokenId][slotManagerAddr];
    }

    function authorizeSlotTo(uint256 tokenId, address slotManagerAddr) override external onlyTokenOwner(tokenId) {
        if (!tokenId2AuthorizedAddresses[tokenId].contains(slotManagerAddr)) {
            tokenId2AuthorizedAddresses[tokenId].add(slotManagerAddr);
            emit SlotAuthorizationCreated(tokenId, slotManagerAddr);
        }
    }

    function revokeAuthorization(uint256 tokenId, address slotManagerAddr) override external onlyTokenOwner(tokenId) {
        tokenId2AuthorizedAddresses[tokenId].remove(slotManagerAddr);
        delete tokenId2Address2Value[tokenId][slotManagerAddr];

        emit SlotAuthorizationRevoked(tokenId, slotManagerAddr);
    }

    function revokeAllAuthorizations(uint256 tokenId) override external onlyTokenOwner(tokenId) {
        for (uint256 i = tokenId2AuthorizedAddresses[tokenId].length() - 1;i > 0; i--) {
            address addr = tokenId2AuthorizedAddresses[tokenId].at(i);
            tokenId2AuthorizedAddresses[tokenId].remove(addr);
            delete tokenId2Address2Value[tokenId][addr];

            emit SlotAuthorizationRevoked(tokenId, addr);
        }

        if (tokenId2AuthorizedAddresses[tokenId].length() > 0) {
            address addr = tokenId2AuthorizedAddresses[tokenId].at(0);
            tokenId2AuthorizedAddresses[tokenId].remove(addr);
            delete tokenId2Address2Value[tokenId][addr];

            emit SlotAuthorizationRevoked(tokenId, addr);
        }
    }

    function isSlotManager(uint256 tokenId, address addr) public view returns (bool) {
        return tokenId2AuthorizedAddresses[tokenId].contains(addr);
    }

    // !!expensive, should call only when no gas is needed;
    function getSlotManagers(uint256 tokenId) external view returns (address[] memory) {
        return tokenId2AuthorizedAddresses[tokenId].values();
    }

    function _mintToken(uint256 tokenId, string calldata imageUri) private {
        _safeMint(msg.sender, tokenId);
        tokenId2ImageUri[tokenId] = imageUri;
    }

    function mint(string calldata imageUri) external {
        uint256 tokenId = totalSupply() + 1;
        _mintToken(tokenId, imageUri);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(
            _exists(_tokenId),
            "URI query for nonexistent token"
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                abi.encodePacked(
                                    "Hyperlink NFT Collection # ",
                                    Strings.toString(_tokenId)
                                ),
                                '",',
                                '"description":"Hyperlink NFT collection created with Parami Foundation"',
                                ',',
                                '"image":"',
                                tokenId2ImageUri[_tokenId],
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function setImageURI(uint256 tokenId, string calldata uri) external onlyTokenOwner(tokenId) {
        tokenId2ImageUri[tokenId] = uri;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable)
        returns (bool)
    {
        return interfaceId == type(IERC721H).interfaceId || super.supportsInterface(interfaceId);
    }
}