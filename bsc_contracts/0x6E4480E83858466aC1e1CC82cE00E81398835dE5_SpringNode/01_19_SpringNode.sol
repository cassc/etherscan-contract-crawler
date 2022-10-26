// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IHandler.sol";
import "./OwnersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SpringNode is ERC721EnumerableUpgradeable, OwnersUpgradeable {
    using Counters for Counters.Counter;

    address public handler;
    mapping(uint256 => string) public tokenIdsToType;

    Counters.Counter private _tokenIdCounter;
    string private uriBase;

    mapping(address => bool) public isBlacklisted;

    bool public openCreateNft;

    address[] public nodeOwners;
    mapping(address => bool) public nodeOwnersInserted;

    mapping(address => bool) public isAuthorized;
    
    function setIsAuthorized(address _new, bool _value) external onlyOwners {
		isAuthorized[_new] = _value;
	}

    function initialize(string memory uri, address _handler)
        external
        initializer
    {
        __SpringNode_init(uri, _handler);
    }

    function __SpringNode_init(string memory uri, address _handler)
        internal
        onlyInitializing
    {
        __Owners_init_unchained();
        __ERC721_init_unchained("Spring Node", "SN");
        __SpringNode_init_unchained(uri, _handler);
    }

    function __SpringNode_init_unchained(string memory uri, address _handler)
        internal
        onlyInitializing
    {
        uriBase = uri;
        handler = _handler;
        openCreateNft = false;
    }

    modifier onlyHandler() {
        require(msg.sender == handler, "SpringNode: God mode not activated");
        _;
    }

    // external
    function burnBatch(address user, uint256[] memory tokenIds)
        external
        onlyHandler
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(ownerOf(tokenIds[i]) == user, "SpringNode: Not nft owner");
            super._burn(tokenIds[i]);
        }
    }

    function generateNfts(
        string memory name,
        address user,
        uint256 count
    ) external onlyHandler returns (uint256[] memory) {
        require(!isBlacklisted[user], "SpringNode: Blacklisted address");
        require(openCreateNft, "SpringNode: Not open");

        if (nodeOwnersInserted[user] == false) {
            nodeOwners.push(user);
            nodeOwnersInserted[user] = true;
        }

        uint256[] memory tokenIds = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            tokenIds[i] = tokenId;
            tokenIdsToType[tokenId] = name;
            _safeMint(user, tokenId);
            _tokenIdCounter.increment();
        }

        return tokenIds;
    }

    // external setters
    function setTokenIdToType(uint256 tokenId, string memory nodeType)
        external
        onlyHandler
    {
        tokenIdsToType[tokenId] = nodeType;
    }

    function setBaseURI(string memory _new) external onlyOwners {
        uriBase = _new;
    }

    function setHandler(address _new) external onlyOwners {
        handler = _new;
    }

    function setIsBlacklisted(address _new, bool _value) external onlyOwners {
        isBlacklisted[_new] = _value;
    }

    function setOpenCreateNft(bool _new) external onlyOwners {
        openCreateNft = _new;
    }

    // external view
    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    function tokensOfOwner(address user)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory result = new uint256[](balanceOf(user));
        for (uint256 i = 0; i < balanceOf(user); i++)
            result[i] = tokenOfOwnerByIndex(user, i);
        return result;
    }

    function tokensOfOwnerByIndexesBetween(
        address user,
        uint256 iStart,
        uint256 iEnd
    ) external view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](iEnd - iStart);
        for (uint256 i = iStart; i < iEnd; i++)
            result[i - iStart] = tokenOfOwnerByIndex(user, i);
        return result;
    }

    function getNodeOwnersSize() external view returns (uint256) {
        return nodeOwners.length;
    }

    function getNodeOwnersBetweenIndexes(uint256 iStart, uint256 iEnd)
        external
        view
        returns (address[] memory)
    {
        address[] memory no = new address[](iEnd - iStart);
        for (uint256 i = iStart; i < iEnd; i++) no[i - iStart] = nodeOwners[i];
        return no;
    }

    function getAttribute(uint256 tokenId)
        external
        view
        returns (string memory)
    {
        return IHandler(handler).getAttribute(tokenId);
    }

    // public

    // internal
    function _baseURI() internal view override returns (string memory) {
        return uriBase;
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require(
            !isBlacklisted[from] && !isBlacklisted[to],
            "SpringNode: Blacklisted address"
        );

        if (nodeOwnersInserted[to] == false) {
            nodeOwners.push(to);
            nodeOwnersInserted[to] = true;
        }

        super._transfer(from, to, tokenId);
        IHandler(handler).nodeTransferFrom(from, to, tokenId);
    }

    // ERC721 && ERC721Enumerable required overriding
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        if(AddressUpgradeable.isContract(to) && !isAuthorized[to])
            revert("SpringNode: unauthorized contract");
        super._beforeTokenTransfer(from, to, tokenId);
    }
    function release(IERC20 token, address account) external onlyOwners {
        uint256 totalReceived = token.balanceOf(address(this));
        SafeERC20.safeTransfer(token, account, totalReceived);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}