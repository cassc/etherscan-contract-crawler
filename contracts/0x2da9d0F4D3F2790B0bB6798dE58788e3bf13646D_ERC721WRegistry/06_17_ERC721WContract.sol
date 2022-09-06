//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IERC721H.sol";

contract ERC721WContract is IERC721H, ERC721Enumerable, ERC721Holder, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    address private wrappedContract;
    address private creator;

    mapping(uint256 => EnumerableSet.AddressSet) tokenId2AuthorizedAddresses;
    mapping(uint256 => mapping(address=> string)) tokenId2Address2Value;

    event TokenWrapped (uint256 indexed tokenId);

    event TokenUnwrapped (uint256 indexed tokenId);

    constructor(string memory name, string memory symbol,
                address _wrappedContract, address _creator) ERC721(name, symbol) {
        require(
            (ERC165)(_wrappedContract).supportsInterface(
                type(IERC721).interfaceId
            ),
            "IERC721"
        );
        require(
            (ERC165)(_wrappedContract).supportsInterface(
                type(IERC721Metadata).interfaceId
            ),
            "not support IERC721Metadata"
        );

        wrappedContract = _wrappedContract;
        creator = _creator;

        _transferOwnership(_creator);
    }

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

    function revokeAllAuthorizations(uint256 tokenId) override public onlyTokenOwner(tokenId) {
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

    function wrap(uint256 tokenId) public {
        require((IERC721)(wrappedContract).ownerOf(tokenId) == _msgSender(), "should own tokenId");
        require((IERC721)(wrappedContract).getApproved(tokenId) == address(this), "should approve tokenId first");

        (IERC721)(wrappedContract).safeTransferFrom(_msgSender(), address(this), tokenId);

        if (_exists(tokenId) && ownerOf(tokenId) == address(this)) {
            _safeTransfer(address(this), _msgSender(), tokenId, "");
        } else {
            _safeMint(_msgSender(), tokenId);
        }

        emit TokenWrapped(tokenId);
    }

    function unwrap(uint256 tokenId) public onlyTokenOwner(tokenId) {
        (IERC721)(wrappedContract).safeTransferFrom(address(this), _msgSender(), tokenId);

        if (tokenId2AuthorizedAddresses[tokenId].length() != 0) {
            revokeAllAuthorizations(tokenId);
        }

        safeTransferFrom(_msgSender(), address(this), tokenId);
        emit TokenUnwrapped(tokenId);
    }

    function getWrappedContract() public view returns (address) {
        return wrappedContract;
    }

    function getCreator() public view returns (address) {
        return creator;
    }

    // !!expensive, should call only when no gas is needed;
    function getSlotManagers(uint256 tokenId) external view returns (address[] memory) {
        return tokenId2AuthorizedAddresses[tokenId].values();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable)
        returns (bool)
    {
        return
            interfaceId == type(IERC721H).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override returns(string memory) {
        return (IERC721Metadata)(wrappedContract).tokenURI(tokenId);
    }
}