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
pragma solidity ^0.8.16;

import "./Guardian/Erc721LockRegistry.sol";
import "./OPR/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "./interfaces/IPotatoz.sol";
import "./interfaces/ICaptainz.sol";
import "./interfaces/IMVP.sol";

contract CaptainzV2 is ERC721x, DefaultOperatorFiltererUpgradeable, ICaptainz {

    string public baseTokenURI;
    string public tokenURISuffix;
    string public tokenURIOverride;

    uint256 public MAX_SUPPLY;

    event QuestStarted(uint256 indexed tokenId, uint256 questStartedAt, uint256[] crews);
    event QuestEdited(uint256 indexed tokenId, uint256 questStartedAt, uint256[] crews, uint256 questEditedAt);
    event QuestStopped(
        uint256 indexed tokenId,
        uint256 questStartedAt,
        uint256 questStoppedAt
    );

    event ChestRevealed(uint256 indexed tokenId);

    IPotatoz public potatozContract;

    uint256 public MAX_CREWS;
    bool public canQuest;
    mapping(uint256 => uint256) public tokensLastQuestedAt; // captainz tokenId => timestamp
    mapping(uint256 => uint256[]) public questCrews; // captainz tokenId => potatoz tokenIds
    mapping(uint256 => uint256[]) public potatozCrew; // potatoz tokenId => captainz tokenId [array of 1 uint256]
    mapping(uint256 => bool) public revealed; // captains tokenId => revealed

    IMVP public mvpContract;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory baseURI) public initializer {
        DefaultOperatorFiltererUpgradeable.__DefaultOperatorFilterer_init();
        ERC721x.__ERC721x_init("Captainz", "Captainz");
        baseTokenURI = baseURI;
        MAX_SUPPLY = 9999;
    }

    function initializeV2() public onlyOwner reinitializer(2) {
        MAX_CREWS = 3;
    }

    function safeMint(address receiver, uint256 quantity) internal {
        require(_totalMinted() + quantity <= MAX_SUPPLY, "exceed MAX_SUPPLY");
        _mint(receiver, quantity);
    }

    // =============== Airdrop ===============

    function airdropWithAmounts(
        address[] memory receivers,
        uint256[] memory amounts
    ) external onlyOwner {
        require(receivers.length >= 1, "at least 1 receiver");
        for (uint256 i; i < receivers.length; i++) {
            address receiver = receivers[i];
            safeMint(receiver, amounts[i]);
        }
    }

    // =============== URI ===============

    function compareStrings(string memory a, string memory b)
        public
        pure
        returns (bool)
    {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        returns (string memory)
    {
        if (bytes(tokenURIOverride).length > 0) {
            return tokenURIOverride;
        }
        return string.concat(super.tokenURI(_tokenId), tokenURISuffix);
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function setTokenURISuffix(string calldata _tokenURISuffix)
        external
        onlyOwner
    {
        if (compareStrings(_tokenURISuffix, "!empty!")) {
            tokenURISuffix = "";
        } else {
            tokenURISuffix = _tokenURISuffix;
        }
    }

    function setTokenURIOverride(string calldata _tokenURIOverride)
        external
        onlyOwner
    {
        if (compareStrings(_tokenURIOverride, "!empty!")) {
            tokenURIOverride = "";
        } else {
            tokenURIOverride = _tokenURIOverride;
        }
    }

    // =============== Stake + MARKETPLACE CONTROL ===============

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721x) onlyAllowedOperator(from) {
        require(
            tokensLastQuestedAt[tokenId] == 0,
            "Cannot transfer questing token"
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
            tokensLastQuestedAt[tokenId] == 0,
            "Cannot transfer questing token"
        );
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    // =============== Questing ===============

    struct QuestInfo {
        uint256 tokenId;
        uint256[] potatozTokenIds;
    }

    function batchStartQuest(QuestInfo[] calldata questInfos) external {
        uint256 batch = questInfos.length;
        for (uint256 i; i < batch;) {
            startQuest(questInfos[i].tokenId, questInfos[i].potatozTokenIds);
            unchecked { ++i; }
        }
    }

    function batchEditQuest(QuestInfo[] calldata questInfos) external {
        require(canQuest, "questing not open");
        require(address(potatozContract) != address(0), "potatozContract not set");

        uint256 batch = questInfos.length;
        for (uint256 i; i < batch;) {
            uint256 tokenId = questInfos[i].tokenId;

            require(msg.sender == ownerOf(tokenId), "not owner of [captainz tokenId]");
            require(tokensLastQuestedAt[tokenId] > 0, "quested not started for [captainz tokenId]");

            _resetCrew(tokenId);
            unchecked { ++i; }
        }

        for (uint256 i; i < batch;) {
            uint256 tokenId = questInfos[i].tokenId;
            uint256[] calldata potatozTokenIds = questInfos[i].potatozTokenIds;

            require(potatozTokenIds.length <= MAX_CREWS, "too many crews [potatozTokenIds]");

            _addCrew(tokenId, potatozTokenIds);
            emit QuestEdited(tokenId, tokensLastQuestedAt[tokenId], potatozTokenIds, block.timestamp);
            unchecked { ++i; }
        }
    }

    function batchStopQuest(uint256[] calldata tokenIds) external {
        uint256 batch = tokenIds.length;
        for (uint256 i; i < batch;) {
            stopQuest(tokenIds[i]);
            unchecked { ++i; }
        }
    }

    function startQuest(uint256 tokenId, uint256[] calldata potatozTokenIds) public {
        require(canQuest, "questing not open");
        require(address(potatozContract) != address(0), "potatozContract not set");

        require(msg.sender == ownerOf(tokenId), "not owner of [captainz tokenId]");
        require(tokensLastQuestedAt[tokenId] == 0, "quested already started for [captainz tokenId]");
        require(potatozTokenIds.length <= MAX_CREWS, "too many crews [potatozTokenIds]");

        _addCrew(tokenId, potatozTokenIds);

        tokensLastQuestedAt[tokenId] = block.timestamp;
        emit QuestStarted(tokenId, block.timestamp, potatozTokenIds);

        if (!revealed[tokenId]) {
            revealed[tokenId] = true;
            emit ChestRevealed(tokenId);
        }
    }

    function editQuest(uint256 tokenId, uint256[] calldata potatozTokenIds) public {
        require(canQuest, "questing not open");
        require(address(potatozContract) != address(0), "potatozContract not set");

        require(msg.sender == ownerOf(tokenId), "not owner of [captainz tokenId]");
        require(tokensLastQuestedAt[tokenId] > 0, "quested not started for [captainz tokenId]");
        require(potatozTokenIds.length <= MAX_CREWS, "too many crews [potatozTokenIds]");

        _resetCrew(tokenId);
        _addCrew(tokenId, potatozTokenIds);

        emit QuestEdited(tokenId, tokensLastQuestedAt[tokenId], potatozTokenIds, block.timestamp);
    }

    function _addCrew(uint256 tokenId, uint256[] calldata potatozTokenIds) private {
        uint256 crews = potatozTokenIds.length;
        if (crews >= 1) {
            uint256[] memory wrapper = new uint256[](1);
            wrapper[0] = tokenId;
            for (uint256 i; i < crews;) {
                uint256 pTokenId = potatozTokenIds[i];
                require(potatozContract.nftOwnerOf(pTokenId) == msg.sender, "not owner of [potatoz tokenId]");
                if (!potatozContract.isPotatozStaking(pTokenId)) {
                    potatozContract.stakeExternal(pTokenId);
                }
                uint256[] storage existCheck = potatozCrew[pTokenId];
                if (existCheck.length != 0) {
                    removeCrew(pTokenId);
                }
                potatozCrew[pTokenId] = wrapper;
                unchecked { ++i; }
            }
            questCrews[tokenId] = potatozTokenIds;
        }
    }

    function removeCrew(uint256 potatozTokenId) public {
        require(address(potatozContract) != address(0), "potatozContract not set");
        require(
            msg.sender == potatozContract.nftOwnerOf(potatozTokenId) || msg.sender == address(potatozContract),
            "caller must be any: potatoz owner, potatoz"
        );

        uint256[] storage existCheck = potatozCrew[potatozTokenId];
        require(existCheck.length != 0, "potatozTokenId not questing");
        uint256 tokenId = existCheck[0];
        uint256 empty = MAX_SUPPLY;

        uint256[] memory pTokenIds = questCrews[tokenId];
        uint256 crews = pTokenIds.length;
        uint256 crewLength = pTokenIds.length;
        for (uint256 i; i < crews;) {
            uint256 pTokenId = pTokenIds[i];
            if (pTokenId == potatozTokenId) {
                pTokenIds[i] = empty;
                crewLength--;
            }
            unchecked { ++i; }
        }

        require(pTokenIds.length != crewLength, "potatozTokenId not in crew");

        uint256[] memory newCrews = new uint256[](crewLength);
        uint256 activeIdx;
        for (uint256 i; i < crews;) {
            if (pTokenIds[i] != empty) {
                newCrews[activeIdx++] = pTokenIds[i];
            }
            unchecked { ++i; }
        }

        questCrews[tokenId] = newCrews;
        potatozCrew[potatozTokenId] = new uint256[](0);
    }

    function _resetCrew(uint256 tokenId) private {
        uint256[] storage potatozTokenIds = questCrews[tokenId];
        uint256 crews = potatozTokenIds.length;
        if (crews >= 1) {
            uint256[] memory empty = new uint256[](0);
            for (uint256 i; i < crews;) {
                uint256 pTokenId = potatozTokenIds[i];
                potatozCrew[pTokenId] = empty;
                unchecked { ++i; }
            }
            questCrews[tokenId] = empty;
        }
    }

    function stopQuest(uint256 tokenId) public {
        require(msg.sender == ownerOf(tokenId) || msg.sender == owner(), "not owner of [captainz tokenId]");
        require(tokensLastQuestedAt[tokenId] > 0, "quested not started for [captainz tokenId]");
        if (address(mvpContract) != address(0) && mvpContract.isCaptainzBoosting(tokenId)) {
            mvpContract.removeCaptainz(tokenId);
        }
        _resetCrew(tokenId);

        uint256 tlqa = tokensLastQuestedAt[tokenId];
        tokensLastQuestedAt[tokenId] = 0;
        emit QuestStopped(tokenId, tlqa, block.timestamp);
    }

    function isPotatozQuesting(uint256 tokenId) external view returns (bool) {
        uint256[] storage existCheck = potatozCrew[tokenId];
        return existCheck.length > 0;
    }

    function getTokenInfo(uint256 tokenId) external view returns (uint256 lastQuestedAt, uint256[] memory crewTokenIds, bool hasRevealed) {
        return (tokensLastQuestedAt[tokenId], questCrews[tokenId], revealed[tokenId]);
    }

    function getActiveCrews(uint256 tokenId) external view returns (uint256[] memory) {
        require(address(potatozContract) != address(0), "potatozContract not set");
        address owner = ownerOf(tokenId);

        uint256[] memory pTokenIds = questCrews[tokenId];
        uint256 crews = pTokenIds.length;
        uint256 activeLength = pTokenIds.length;
        uint256 empty = MAX_SUPPLY;
        for (uint256 i; i < crews;) {
            uint256 pTokenId = pTokenIds[i];
            if (potatozContract.nftOwnerOf(pTokenId) != owner || !potatozContract.isPotatozStaking(pTokenId)) {
                pTokenIds[i] = empty;
                activeLength--;
            }
            unchecked { ++i; }
        }

        uint256[] memory activeCrews = new uint256[](activeLength);
        uint256 activeIdx;
        for (uint256 i; i < crews;) {
            if (pTokenIds[i] != empty) {
                activeCrews[activeIdx++] = pTokenIds[i];
            }
            unchecked { ++i; }
        }

        return activeCrews;
    }

    // =============== Admin ===============

    function setCanQuest(bool b) external onlyOwner {
        canQuest = b;
    }

    function setPotatozContract(address addr) external onlyOwner {
        potatozContract = IPotatoz(addr);
    }

    function setMvpContract(address addr) external onlyOwner {
        mvpContract = IMVP(addr);
    }
}