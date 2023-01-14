// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract KillaKrystals is ERC721A, Ownable, DefaultOperatorFilterer {
    mapping(address => bool) public authorities;
    mapping(uint256 => uint256) public tokenTiers;
    mapping(uint256 => bool) public lockedTokens;
    bool public lockingEnabled;

    string public baseURI;

    error NotAllowed();
    error TokenIsLocked();
    error TokenNotLocked();
    error LockingDisabled();

    event TokensLocked(uint256[] indexed tokens);

    constructor() ERC721A("KillaKrystals", "KillaKrystals") {}

    function mint(address recipient, uint256[] calldata tiers) external {
        if (!authorities[msg.sender]) revert NotAllowed();

        uint256 start = _nextTokenId();
        uint256 index = start;

        for (uint256 i = 0; i < tiers.length; i++) {
            uint256 amount = tiers[i];
            if (amount == 0) continue;

            tokenTiers[index] = i + 1;
            index += amount;
        }

        uint256 total = index - start;
        _mint(recipient, total);
    }

    function lockTokens(uint256[] memory tokens) external {
        if (!lockingEnabled) revert LockingDisabled();
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 token = tokens[i];
            if (msg.sender != ownerOf(token)) revert NotAllowed();
            lockedTokens[token] = true;
        }
        emit TokensLocked(tokens);
    }

    function burnTokens(uint256[] memory tokens) external {
        if (!authorities[msg.sender]) revert NotAllowed();
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 token = tokens[i];
            if (!lockedTokens[token]) revert TokenNotLocked();
            _burn(token);
        }
    }

    function toggleAuthority(address addr, bool enabled) external onlyOwner {
        authorities[addr] = enabled;
    }

    function toggleLocking(bool enabled) external onlyOwner {
        lockingEnabled = enabled;
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        baseURI = uri;
    }

    function getTier(uint256 tokenId) public view returns (uint256) {
        while (tokenTiers[tokenId] == 0 && tokenId > 1) tokenId--;
        return tokenTiers[tokenId];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId))
            return string(abi.encodePacked(baseURI, "burned"));

        uint256 tier = getTier(tokenId);
        if (lockedTokens[tokenId]) {
            return
                string(abi.encodePacked(baseURI, _toString(tier), "-locked"));
        }

        return string(abi.encodePacked(baseURI, _toString(tier)));
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    modifier checkLock(uint256 tokenId) virtual {
        if (lockedTokens[tokenId]) revert TokenIsLocked();
        _;
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) checkLock(tokenId) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) checkLock(tokenId) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) checkLock(tokenId) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}