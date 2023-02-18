// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./Guardian/Erc721LockRegistry.sol";
import "./OPR/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "./interfaces/ICaptainz.sol";

contract YouTheRealMVP_V4 is ERC721x, DefaultOperatorFiltererUpgradeable {
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

    // =============== BOOSTING ===============
    ICaptainz public captainzContract;

    uint256 public MAX_QUESTING_CAPTAINZ;
    mapping(uint256 => uint256[]) public boostedQuestingCaptainz; // MVP tokenId => captainz tokenIds
    mapping(uint256 => uint256[]) public questingCaptainzToMVP; // Captainz tokenId => MVP tokenId [array of 1 uint256]
    mapping(uint256 => uint256) public captainzLastBoostedAt; // Captainz tokenId => timestamp
    // ==============================

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory baseURI) public initializer {
        ERC721x.__ERC721x_init(
            "YOU THE REAL MVP",
            "MVP"
        );
        baseTokenURI = baseURI;
        MAX_SUPPLY = 420;
    }

    function initializeV2() public onlyOwner reinitializer(2) {
        DefaultOperatorFiltererUpgradeable.__DefaultOperatorFilterer_init();
    }

    // =============== BOOSTING ===============

    function initializeV4() public onlyOwner reinitializer(4) {
        MAX_QUESTING_CAPTAINZ = 9;
    }

    // ==============================

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

    // V3
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721x) onlyAllowedOperator(from) {
        require(
            tokensLastStakedAt[tokenId] == 0,
            "Cannot transfer staked token"
        );
        super.transferFrom(from, to, tokenId);
    }

    // V3
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override(ERC721x) onlyAllowedOperator(from) {
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
        // V4
        _resetCaptainz(tokenId);
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

    // =============== BOOSTING ===============

    struct BoostInfo {
        uint256 tokenId;
        uint256[] captainzTokenIds;
    }

    function batchStartBoost(BoostInfo[] calldata boostInfos) external {
        uint256 batch = boostInfos.length;
        for (uint256 i; i < batch; ) {
            startBoost(boostInfos[i].tokenId, boostInfos[i].captainzTokenIds);
            unchecked { ++i; }
        }
    }

    function batchEditBoost(BoostInfo[] calldata boostInfos) external {
        uint256 batch = boostInfos.length;
        for (uint256 i; i < batch; ) {
            editBoost(boostInfos[i].tokenId, boostInfos[i].captainzTokenIds);
            unchecked { ++i; }
        }
    }

    function batchStopBoost(uint256[] calldata tokenIds) external {
        uint batch = tokenIds.length;
        for (uint256 i = 0; i < batch; ) {
            unstake(tokenIds[i]);
            unchecked { ++i; }
        }
    }

    function startBoost(uint256 tokenId, uint256[] calldata captainzTokenIds) public {
        require(captainzTokenIds.length <= MAX_QUESTING_CAPTAINZ, "too many questingCaptainz [captainzTokenIds]");

        stake(tokenId);
        _addCaptainz(tokenId, captainzTokenIds, new uint256[](0));
    }

    function editBoost(uint256 tokenId, uint256[] calldata captainzTokenIds) public {
        require(canStake, "boosting/staking not open");

        require(msg.sender == ownerOf(tokenId), "not owner of [MVP tokenId]");
        require(tokensLastStakedAt[tokenId] > 0, "boosting/staking not started for [MVP tokenId]");
        require(captainzTokenIds.length <= MAX_QUESTING_CAPTAINZ, "too many questingCaptainz [captainzTokenIds]");

        _addCaptainz(tokenId, captainzTokenIds, _resetCaptainz(tokenId));
    }

    function _addCaptainz(uint256 tokenId, uint256[] calldata captainzTokenIds, uint256[] memory prevBoostedAt) private {
        require(address(captainzContract) != address(0), "captainzContract not set");
        if (captainzTokenIds.length >= 1) {
            uint256[] memory wrapper = new uint256[](1);
            wrapper[0] = tokenId;
            uint batch = captainzTokenIds.length;
            uint prevBoostedLength = prevBoostedAt.length;
            for (uint256 i = 0; i < batch; ) {
                uint256 cTokenId = captainzTokenIds[i];
                require(captainzContract.ownerOf(cTokenId) == msg.sender, "not owner of [captainz tokenId]");
                require(captainzContract.tokensLastQuestedAt(cTokenId) > 0, "captainz [captainz tokenId] must be questing");
                uint256[] storage existCheck = questingCaptainzToMVP[cTokenId];
                if (existCheck.length != 0) {
                    removeCaptainz(cTokenId);
                }
                questingCaptainzToMVP[cTokenId] = wrapper;
                uint256 boostedAt = block.timestamp;
                if (i < prevBoostedLength && prevBoostedAt[i] != 0) boostedAt = prevBoostedAt[i];
                captainzLastBoostedAt[cTokenId] = boostedAt;
                unchecked { ++i; }
            }
            boostedQuestingCaptainz[tokenId] = captainzTokenIds;
        }
    }

    function removeCaptainz(uint256 captainzTokenId) public {
        require(address(captainzContract) != address(0), "captainzContract not set");
        require(
            msg.sender == captainzContract.ownerOf(captainzTokenId) || msg.sender == address(captainzContract),
            "caller must be any: captainz owner, captainz"
        );

        uint256[] storage existCheck = questingCaptainzToMVP[captainzTokenId];
        require(existCheck.length != 0, "captainzTokenId not boosting");
        uint256 tokenId = existCheck[0];

        uint256 empty = MAX_SUPPLY;

        uint256[] memory cTokenIds = boostedQuestingCaptainz[tokenId];
        uint256 questing = cTokenIds.length;
        uint256 newLength = cTokenIds.length;
        for (uint256 i; i < questing; ) {
            uint256 cTokenId = cTokenIds[i];
            if (cTokenId == captainzTokenId) {
                cTokenIds[i] = empty;
                newLength--;
            }
            unchecked { ++i; }
        }

        require(cTokenIds.length != newLength, "captainzTokenId not in quest");

        uint256[] memory newQuestingCaptainz = new uint256[](newLength);
        uint256 activeIdx;
        for (uint256 i; i < questing; ) {
            if (cTokenIds[i] != empty) {
                newQuestingCaptainz[activeIdx++] = cTokenIds[i];
            }
            unchecked { ++i; }
        }

        boostedQuestingCaptainz[tokenId] = newQuestingCaptainz;
        questingCaptainzToMVP[captainzTokenId] = new uint256[](0);
        captainzLastBoostedAt[captainzTokenId] = 0;
    }

    function _resetCaptainz(uint256 tokenId) private returns (uint256[] memory) {
        uint256[] storage captainzTokenIds = boostedQuestingCaptainz[tokenId];
        uint256[] memory prevBoostedAt = new uint256[](captainzTokenIds.length);
        if (captainzTokenIds.length >= 1) {
            uint256[] memory empty = new uint256[](0);
            uint batch = captainzTokenIds.length;
            for (uint256 i = 0; i < batch; ) {
                uint256 cTokenId = captainzTokenIds[i];
                questingCaptainzToMVP[cTokenId] = empty;
                prevBoostedAt[i] = captainzLastBoostedAt[cTokenId];
                captainzLastBoostedAt[cTokenId] = 0;
                unchecked { ++i; }
            }
            boostedQuestingCaptainz[tokenId] = empty;
        }
        return prevBoostedAt;
    }

    function isCaptainzBoosting(uint256 tokenId) external view returns (bool) {
        uint256[] storage existCheck = questingCaptainzToMVP[tokenId];
        return existCheck.length > 0;
    }

    function getTokenInfo(uint256 tokenId) external view returns (uint256 lastBoostedAt, uint256[] memory questingCaptainzTokenIds, uint256[] memory questingCaptainzLastBoostedAt) {
        uint256[] storage captainzTokenIds = boostedQuestingCaptainz[tokenId];
        uint256 captainzLength = captainzTokenIds.length;
        questingCaptainzLastBoostedAt = new uint256[](captainzLength);
        for (uint256 i = 0; i < captainzLength; ) {
            questingCaptainzLastBoostedAt[i] = captainzLastBoostedAt[captainzTokenIds[i]];
            unchecked { ++i; }
        }
        return (tokensLastStakedAt[tokenId], boostedQuestingCaptainz[tokenId], questingCaptainzLastBoostedAt);
    }

    function getCaptainzInfo(uint256 captainzTokenId) external view returns (uint256 tokenId, uint256 lastBoostedAt, bool boosting) {
        require(address(captainzContract) != address(0), "captainzContract not set");
        uint256[] storage existCheck = questingCaptainzToMVP[captainzTokenId];
        if (existCheck.length == 0) return (0, 0, false);
        tokenId = existCheck[0];
        if (captainzContract.ownerOf(captainzTokenId) != ownerOf(tokenId)) return (0, 0, false);
        return (tokenId, captainzLastBoostedAt[captainzTokenId], true);
    }

    struct CaptainzCrew {
        uint256 tokenId;
        uint256 lastBoostedAt;
        uint256[] crewIds;
    }

    function getCaptainzCrews(uint256 tokenId) external view returns (CaptainzCrew[] memory) {
        uint256[] storage captainzTokenIds = boostedQuestingCaptainz[tokenId];
        uint256 captainzLength = captainzTokenIds.length;
        CaptainzCrew[] memory captainzCrews = new CaptainzCrew[](captainzLength);
        for (uint256 i = 0; i < captainzLength; ) {
            uint256 cTokenId = captainzTokenIds[i];
            captainzCrews[i].tokenId = cTokenId;
            captainzCrews[i].lastBoostedAt = captainzLastBoostedAt[cTokenId];
            captainzCrews[i].crewIds = captainzContract.getActiveCrews(cTokenId);
            unchecked { ++i; }
        }
        return captainzCrews;
    }

    function setCaptainzContract(address addr) external onlyOwner {
        captainzContract = ICaptainz(addr);
    }

    // ================================================
}