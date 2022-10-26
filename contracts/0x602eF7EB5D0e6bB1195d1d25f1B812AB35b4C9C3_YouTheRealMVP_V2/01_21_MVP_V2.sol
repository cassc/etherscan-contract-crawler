// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./Guardian/Erc721LockRegistry.sol";

contract YouTheRealMVP_V2 is ERC721x {
    uint256 public MAX_SUPPLY;
    string public baseTokenURI;

    event BaseURIChanged(string baseURI);

    // =============== V2 ===============
    bool public canStake;
    mapping(uint256 => uint256) public tokensLastStakedAt; // tokenId => timestamp
    event Stake(uint256 tokenId, address by, uint256 stakedAt);
    event Unstake(
        uint256 tokenId,
        address by,
        uint256 stakedAt,
        uint256 unstakedAt
    );

    mapping(address => bool) public whitelistedMarketplaces;
    mapping(address => bool) public blacklistedMarketplaces;
    uint8 public marketplaceRestriction;
    event MarketplaceWhitelisted(address indexed market, bool whitelisted);
    event MarketplaceBlacklisted(address indexed market, bool blacklisted);
    // ==============================

    function initialize(string memory baseURI) public initializer {
        ERC721x.__ERC721x_init(
            "YOU THE REAL MVP",
            "MVP"
        );
        baseTokenURI = baseURI;
        MAX_SUPPLY = 420;
    }

    function airdrop(address receiver, uint256 tokenAmount) external onlyOwner {
        require(
            totalSupply() + tokenAmount <= MAX_SUPPLY,
            "would exceed MAX_SUPPLY"
        );
        _safeMint(receiver, tokenAmount);
    }

    function giveaway(address[] memory receivers) external onlyOwner {
        require(receivers.length >= 1, "at least 1 receiver");
        require(
            totalSupply() + receivers.length <= MAX_SUPPLY,
            "would exceed MAX_SUPPLY"
        );
        for (uint256 i; i < receivers.length; i++) {
            address receiver = receivers[i];
            _safeMint(receiver, 1);
        }
    }

    function giveawayWithAmounts(
        address[] memory receivers,
        uint256[] memory amounts
    ) external onlyOwner {
        require(receivers.length >= 1, "at least 1 receiver");
        require(
            receivers.length == amounts.length,
            "receivers.length must equal amounts.length"
        );
        uint256 total = 0;
        for (uint256 i; i < amounts.length; i++) {
            uint256 amount = amounts[i];
            require(amount >= 1, "each receiver should receive at least 1");
            total += amount;
        }
        require(totalSupply() + total <= MAX_SUPPLY, "would exceed MAX_SUPPLY");
        for (uint256 i; i < receivers.length; i++) {
            address receiver = receivers[i];
            _safeMint(receiver, amounts[i]);
        }
    }

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "there is nothing to withdraw");
        _withdraw(owner(), address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "could not withdraw");
    }

    function burnSupply(uint256 maxSupplyNew) external onlyOwner {
        require(maxSupplyNew > 0, "new max supply should > 0");
        require(maxSupplyNew < MAX_SUPPLY, "can only reduce max supply");
        require(
            maxSupplyNew >= totalSupply(),
            "cannot burn more than current supply"
        );
        MAX_SUPPLY = maxSupplyNew;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
        emit BaseURIChanged(baseURI);
    }

    function tokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory)
    {
        unchecked {
            uint256[] memory a = new uint256[](balanceOf(owner));
            uint256 end = _currentIndex;
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            for (uint256 i; i < end; i++) {
                TokenOwnership memory ownership = _ownerships[i];
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    a[tokenIdsIdx++] = i;
                }
            }
            return a;
        }
    }

    // =============== STAKING ===============

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721x) {
        require(
            tokensLastStakedAt[tokenId] == 0,
            "Cannot transfer staked token"
        );
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override(ERC721x) {
        require(
            tokensLastStakedAt[tokenId] == 0,
            "Cannot transfer staked token"
        );
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function stake(uint256 tokenId) public {
        require(canStake, "staking not open");
        require(
            msg.sender == ownerOf(tokenId) || msg.sender == owner(),
            "caller must be owner of token or contract owner"
        );
        require(tokensLastStakedAt[tokenId] == 0, "already staking");
        tokensLastStakedAt[tokenId] = block.timestamp;
        emit Stake(tokenId, msg.sender, tokensLastStakedAt[tokenId]);
    }

    function unstake(uint256 tokenId) public {
        require(
            msg.sender == ownerOf(tokenId) || msg.sender == owner(),
            "caller must be owner of token or contract owner"
        );
        require(tokensLastStakedAt[tokenId] > 0, "not staking");
        uint256 lsa = tokensLastStakedAt[tokenId];
        tokensLastStakedAt[tokenId] = 0;
        emit Unstake(tokenId, msg.sender, block.timestamp, lsa);
    }

    function setTokensStakeStatus(uint256[] memory tokenIds, bool setStake)
        external
    {
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if (setStake) {
                stake(tokenId);
            } else {
                unstake(tokenId);
            }
        }
    }

    function setCanStake(bool b) external onlyOwner {
        canStake = b;
    }

    // =============== MARKETPLACE CONTROL ===============

    function checkGuardianOrMarketplace(address operator) internal view {
        // Always allow guardian contract
        if (approvedContract[operator]) return;
        require(
            !(marketplaceRestriction == 1 && blacklistedMarketplaces[operator]),
            "Marketplace blacklisted"
        );
        require(
            !(marketplaceRestriction == 2 &&
                !whitelistedMarketplaces[operator]),
            "Marketplace not whitelisted"
        );
        return;
    }

    function approve(address to, uint256 tokenId)
        public
        virtual
        override(ERC721AUpgradeable)
    {
        checkGuardianOrMarketplace(to);
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override(ERC721AUpgradeable)
    {
        checkGuardianOrMarketplace(operator);
        super.setApprovalForAll(operator, approved);
    }

    function whitelistMarketplaces(address[] calldata markets, bool whitelisted)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < markets.length; i++) {
            address market = markets[i];
            whitelistedMarketplaces[market] = whitelisted;
            emit MarketplaceWhitelisted(market, whitelisted);
        }
    }

    function blacklistMarketplaces(address[] calldata markets, bool blacklisted)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < markets.length; i++) {
            address market = markets[i];
            blacklistedMarketplaces[market] = blacklisted;
            emit MarketplaceBlacklisted(market, blacklisted);
        }
    }

    // 0 = no restriction, 1 = blacklist, 2 = whitelist
    function setMarketplaceRestriction(uint8 rule) external onlyOwner {
        marketplaceRestriction = rule;
    }

    function _mayTransfer(address operator, uint256 tokenId)
        private
        view
        returns (bool)
    {
        if (operator == ownerOf(tokenId)) return true;
        checkGuardianOrMarketplace(msg.sender);
        return true;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override(ERC721AUpgradeable) {
        for (
            uint256 tokenId = startTokenId;
            tokenId < startTokenId + quantity;
            tokenId += 1
        ) {
            if (
                from != address(0) &&
                to != address(0) &&
                !_mayTransfer(msg.sender, tokenId)
            ) {
                revert("MVP: illegal operator");
            }
        }
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }
}