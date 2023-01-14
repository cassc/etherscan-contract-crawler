// SPDX-License-Identifier: MIT
/*


                                    $MEMELAND
                                   kevinLAND$$$
                                mVp           meme
                               meME      BRIAN6 9$
                              $sa|ya$   ISdicKbuTT
                              !mVP$! $ca pta  inM$
                              !j$oe$y!! TREASUREM$
                               !MV $P!$         M$
                               M$zpotatozmvp    M$           Cumm
                               A$C$$staking$    M$          CHRIS
                               R$H       MVP $d ontLAND   mvpR m$
                               C$U       $$$ 69 T$rustverify IMvP
                               O$N      9gag ceo   captain  aS$o
                               !9GA     pOTATOZ$       RAY$9999$
                                 G!     !!$DICK$!         dyno
                                 poTa    BUTTZ!           m$
                                   to                   9gag
                                    LETSFUCKING!  GROW!!!
                                    RAY$    ISMVP ME
                                   DERE K!   lanD me
                                 kArEnc IS j6r9an LA
                                 tReASURE$ meMelandnD


*/
pragma solidity ^0.8.14;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./Guardian/Erc721LockRegistry.sol";
import "./OPR/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

contract PotatozV3 is
    ERC721x,
    ReentrancyGuardUpgradeable,
    DefaultOperatorFiltererUpgradeable
{
    string public baseTokenURI;
    string public tokenURISuffix;
    address private signer;

    uint256 public MAX_SUPPLY;
    uint256 public MAX_TOKENS_MINTED_PER_ADDRESS;
    uint256 public mintStartAfter;

    bool public canStake;
    string public tokenURIOverride;
    mapping(address => uint256) public tokensMintedPerAddress; // address => times minted
    mapping(uint256 => uint256) public tokensLastStakedAt; // tokenId => timestamp

    // event Mint(address minter, uint256 tokenId);
    event Stake(uint256 tokenId, address by, uint256 stakedAt);
    event Unstake(
        uint256 tokenId,
        address by,
        uint256 stakedAt,
        uint256 unstakedAt
    );

    mapping(uint256 => uint256) public tokensLevel;

    // =============== V2 ===============
    mapping(address => bool) public whitelistedMarketplaces;
    mapping(address => bool) public blacklistedMarketplaces;
    uint8 public marketplaceRestriction;
    event MarketplaceWhitelisted(address indexed market, bool whitelisted);
    event MarketplaceBlacklisted(address indexed market, bool blacklisted);
    // ==============================

    // =============== V3 ===============
    bool public allowStakedTransfer; // Unused
    bool public canStakeTransfer;


    function initialize(address _signer, string memory baseURI)
        public
        initializer
    {
        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        ERC721x.__ERC721x_init("Potatoz", "Potatoz");
        baseTokenURI = baseURI;
        signer = _signer;

        MAX_SUPPLY = 9999;
        MAX_TOKENS_MINTED_PER_ADDRESS = 1;
        mintStartAfter = 0;
    }

    function initializeV2() public onlyOwner reinitializer(2) {
        DefaultOperatorFiltererUpgradeable.__DefaultOperatorFilterer_init();
    }

    function checkMintValidity(
        bytes32 hash,
        bytes calldata signature,
        uint256 validUntil
    ) public view returns (bool) {
        require(
            ECDSA.toEthSignedMessageHash(
                keccak256(abi.encodePacked(msg.sender, "allow", validUntil))
            ) == hash,
            "invalid hash"
        );
        require(ECDSA.recover(hash, signature) == signer, "invalid signature");
        return true;
    }

    function mint(
        bytes32 hash,
        bytes calldata signature,
        uint256 validUntil
    ) external {
        require(
            mintStartAfter > 0 && block.timestamp >= mintStartAfter,
            "mint not started"
        );
        require(block.timestamp <= validUntil, "expired");
        require(checkMintValidity(hash, signature, validUntil), "invalid");
        require(
            _numberMinted(msg.sender) + 1 <= MAX_TOKENS_MINTED_PER_ADDRESS,
            "tokensMintedPerAddress exceed MAX_TOKENS_MINTED_PER_ADDRESS"
        );
        // uint256 tokenId = totalSupply();
        safeMint(msg.sender, 1);
        // emit Mint(msg.sender, tokenId);
    }

    function safeMint(address receiver, uint256 quantity) internal {
        require(_totalMinted() + quantity <= MAX_SUPPLY, "exceed MAX_SUPPLY");
        _mint(receiver, quantity, "", false);
    }

    function giveaway(address[] memory receivers) external onlyOwner {
        require(receivers.length >= 1, "at least 1 receiver");
        // require(
        //     totalSupply() + receivers.length <= MAX_SUPPLY,
        //     "would exceed MAX_SUPPLY"
        // );
        for (uint256 i; i < receivers.length; i++) {
            address receiver = receivers[i];
            safeMint(receiver, 1);
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
        // uint256 total = 0;
        // for (uint256 i; i < amounts.length; i++) {
        //     uint256 amount = amounts[i];
        //     require(amount >= 1, "each receiver should receive at least 1");
        //     total += amount;
        // }
        // require(totalSupply() + total <= MAX_SUPPLY, "would exceed MAX_SUPPLY");
        for (uint256 i; i < receivers.length; i++) {
            address receiver = receivers[i];
            safeMint(receiver, amounts[i]);
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
            maxSupplyNew >= _totalMinted(),
            "cannot burn more than current supply"
        );
        MAX_SUPPLY = maxSupplyNew;
    }

    function setSigner(address addr) external onlyOwner {
        signer = addr;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function setTokenURISuffix(string memory _tokenURISuffix)
        external
        onlyOwner
    {
        tokenURISuffix = _tokenURISuffix;
    }

    function setTokenURIOverride(string memory _tokenURIOverride)
        external
        onlyOwner
    {
        tokenURIOverride = _tokenURIOverride;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (bytes(tokenURIOverride).length > 0) {
            return tokenURIOverride;
        }
        return string.concat(super.tokenURI(_tokenId), tokenURISuffix);
    }

    function setMintStartAfter(uint256 timestamp) external onlyOwner {
        mintStartAfter = timestamp;
    }

    function setMaxTokensMintedPerAddress(uint256 m) external onlyOwner {
        MAX_TOKENS_MINTED_PER_ADDRESS = m;
    }

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

    // V3
    function setCanStakeTransfer(bool b) external onlyOwner {
        canStakeTransfer = b;
    }

    function stakeTransferAll(
        address from,
        address to
    ) public {
        require(canStakeTransfer, "Staked transfer not open");
        require(msg.sender == from, "Sender must be from token owner");
        uint256[] memory tokenIds = tokensOfOwner(msg.sender);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            super.transferFrom(from, to, tokenIds[i]);
        }
    }

    /// @dev Returns the tokenIds of the address. O(totalSupply) in complexity.
    function tokensOfOwner(address owner)
        public
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
                revert("Potatoz: illegal operator");
            }
        }
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }
}