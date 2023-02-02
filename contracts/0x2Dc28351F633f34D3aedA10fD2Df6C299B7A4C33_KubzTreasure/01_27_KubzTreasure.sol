// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "@openzeppelin/contracts/utils/Strings.sol";
// import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./Guardian/Erc721LockRegistryDummy.sol";
import "./OPR/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "./interfaces/IERC721xHelper.sol";
import "./interfaces/IStaminaInfo.sol";

// import "hardhat/console.sol";

// https://yogapetz.gitbook.io/kubz-relic-crafting/how-crafting-work
contract KubzTreasure is
    ERC721xDummy,
    DefaultOperatorFiltererUpgradeable,
    ReentrancyGuardUpgradeable,
    IERC721xHelper,
    IStaminaInfo
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    string public baseTokenURI;
    address public signer;
    mapping(uint256 => uint256) public boxRarity;
    EnumerableSet.AddressSet claimedUsers;

    mapping(uint256 => uint256) public kubzToTreasure;
    address public signerAlt;
    IERC721 public kubzContract;
    uint256 public MAX_SUPPLY;

    // V3
    bool public canCraft;
    bool public canOpen;
    IERC721 public kzgContract;
    mapping(uint256 => uint256) kzgStamina; // tokenId => stamina (default 2100, max 2100, min 0)
    mapping(uint256 => uint256) kubzStamina; // tokenId => stamina (default 700, max 700, min 0)
    mapping(uint256 => uint256) kzgLastCraft; // tokenId => timestamp
    mapping(uint256 => uint256) kubzLastCraft; // tokenId => timestamp
    mapping(address => uint256) public potionsUsed; // address => potions used
    mapping(string => bool) public msrNonceUsed; // string => nonce used
    uint256 public mythicalUpgradeQuota;
    uint256 public mythicalUpgradeCount;
    uint256 public dragonMintQuota;
    uint256 public dragonMintCount;

    event RelicOpen(
        address sender,
        uint256 indexed tokenId,
        uint256 indexed rarity
    );
    event RelicCraft(
        address sender,
        uint256 indexed tokenId,
        uint256 indexed fromRarity,
        uint256 indexed burnRelicRarity,
        uint256[] kzgTokenIds,
        uint256[] kubzTokenIds,
        uint256[] burnRelicTokenIds
    );
    event RelicUpgrade(
        address sender,
        uint256 indexed tokenId,
        uint256 indexed fromRarity,
        uint256 indexed toRarity
    );
    event RelicMint(
        address sender,
        uint256 indexed tokenId,
        uint256 indexed rarity
    );

    function initialize(string memory baseURI) public initializer {
        ERC721xDummy.__ERC721x_init("Kubz Relic", "Kubz Relic");
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        DefaultOperatorFiltererUpgradeable.__DefaultOperatorFilterer_init();
        baseTokenURI = baseURI;
        MAX_SUPPLY = 39999;
    }

    function setMaxSupplyPhase(uint256 phase) public onlyOwner {
        if (phase == 1) {
            MAX_SUPPLY = 39999;
        } else if (phase == 2) {
            MAX_SUPPLY = 40079;
        }
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setAddresses(
        address signerAddress,
        address signerAltAddress,
        address kubzAddress
    ) external onlyOwner {
        signer = signerAddress;
        signerAlt = signerAltAddress;
        kubzContract = IERC721(kubzAddress);
    }

    function setupCrafting(
        bool _canCraft,
        bool _canOpen,
        address kzgAddress,
        uint256 _mythicalUpgradeQuota,
        uint256 _dragonMintQuota
    ) external onlyOwner {
        canCraft = _canCraft;
        canOpen = _canOpen;
        kzgContract = IERC721(kzgAddress);
        mythicalUpgradeQuota = _mythicalUpgradeQuota;
        dragonMintQuota = _dragonMintQuota;
    }

    // =============== AIR DROP ===============
    function ownerClaimRarities(uint256[] calldata rarities)
        external
        onlyOwner
    {
        uint256 start = _nextTokenId();
        safeMint(msg.sender, rarities.length);

        for (uint256 i = 0; i < rarities.length; i++) {
            uint256 tokenId = start + i;
            boxRarity[tokenId] = rarities[i];
        }
    }

    function safeMint(address receiver, uint256 quantity) internal {
        require(_totalMinted() + quantity <= MAX_SUPPLY, "exceed MAX_SUPPLY");
        _mint(receiver, quantity);
    }

    // =============== BASE URI ===============
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        returns (string memory)
    {
        return string.concat(super.tokenURI(_tokenId));
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    // =============== MARKETPLACE CONTROL ===============
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        public
        virtual
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(_from)
    {
        super.transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        virtual
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // =============== MISC ===============
    function getRelicRarity(uint256 tokenId) public view returns (uint256) {
        uint256 rarity = boxRarity[tokenId];
        if (rarity > 0) return rarity;
        if (tokenId >= 39661 && tokenId <= 39723) return 3;
        if (tokenId >= 39724 && tokenId <= 39999) return 2;
        return rarity;
    }

    function getBoxRarities(uint256 fromTokenId, uint256 toTokenId)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory part = new uint256[]((toTokenId - fromTokenId) + 1);
        for (uint256 tokenId = fromTokenId; tokenId <= toTokenId; tokenId++) {
            uint256 i = tokenId - fromTokenId;
            part[i] = _exists(tokenId) ? getRelicRarity(tokenId) : 0;
        }
        return part;
    }

    function getBoxRaritiesOf(uint256[] calldata tokenIds)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory part = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            part[i] = _exists(tokenId) ? getRelicRarity(tokenId) : 0;
        }
        return part;
    }

    // =============== V3: Crafting ===============
    function kzgActualStamina(uint256 tokenId) public view returns (uint256) {
        uint256 max = 2100;
        if (kzgLastCraft[tokenId] == 0) return max;
        uint256 stam = kzgStamina[tokenId] +
            ((block.timestamp - kzgLastCraft[tokenId]) / 288); // 86400 / 300
        if (stam > max) return max;
        return stam;
    }

    function kzgCanTransfer(uint256 tokenId) external view returns (bool) {
        return !canCraft || kzgActualStamina(tokenId) == 2100;
    }

    function kzgActualStaminaMultiple(uint256[] calldata tokenIds)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory part = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            part[i] = kzgActualStamina(tokenIds[i]);
        }
        return part;
    }

    function kubzActualStamina(uint256 tokenId) public view returns (uint256) {
        uint256 max = 700;
        if (kubzLastCraft[tokenId] == 0) return max;
        uint256 stam = kubzStamina[tokenId] +
            ((block.timestamp - kubzLastCraft[tokenId]) / 864); // 86400 / 100
        if (stam > max) return max;
        return stam;
    }

    function kubzCanTransfer(uint256 tokenId) external view returns (bool) {
        return !canCraft || kubzActualStamina(tokenId) == 700;
    }

    function kubzActualStaminaMultiple(uint256[] calldata tokenIds)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory part = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            part[i] = kubzActualStamina(tokenIds[i]);
        }
        return part;
    }

    function open(uint256[] calldata tokenIds) external {
        require(canOpen, "relic can't be opened yet");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            emit RelicOpen(msg.sender, tokenId, getRelicRarity(tokenId));
            _burn(tokenId);
        }
    }

    function craft(
        uint256 tokenId,
        uint256[] calldata kzgTokenIds,
        uint256[] calldata kubzTokenIds,
        uint256[] calldata burnRelicTokenIds
    ) public {
        require(canCraft, "crafting not open");
        require(ownerOf(tokenId) == msg.sender, "not owner of tokenId");
        require(kzgTokenIds.length <= 1, "at most 1 kzg");
        require(kubzTokenIds.length <= 3, "at most 3 kubz");
        require(
            kzgTokenIds.length + kubzTokenIds.length >= 1,
            "need kubz or kzg"
        );
        uint256 stamReq = 700;
        for (uint256 i = 0; i < kzgTokenIds.length; i++) {
            uint256 kzgTokenId = kzgTokenIds[i];
            require(kzgContract.ownerOf(kzgTokenId) == msg.sender);
            uint256 aStam = kzgActualStamina(kzgTokenId);
            require(aStam >= stamReq, "NES: kzg");
            kzgLastCraft[kzgTokenId] = block.timestamp;
            unchecked {
                kzgStamina[kzgTokenId] = aStam - stamReq;
            }
        }

        for (uint256 i = 0; i < kubzTokenIds.length; i++) {
            uint256 kubzTokenId = kubzTokenIds[i];
            require(kubzContract.ownerOf(kubzTokenId) == msg.sender);
            uint256 aStam = kubzActualStamina(kubzTokenId);
            require(aStam >= stamReq, "NES: kubz");
            kubzLastCraft[kubzTokenId] = block.timestamp;
            unchecked {
                kubzStamina[kubzTokenId] = aStam - stamReq;
            }
        }

        uint256 myRarity = getRelicRarity(tokenId);
        if (myRarity == 1) {
            require(burnRelicTokenIds.length <= 10, "tl1");
        } else if (myRarity == 2) {
            require(burnRelicTokenIds.length <= 5, "tl2");
        } else if (myRarity == 3) {
            require(burnRelicTokenIds.length <= 3, "tl3");
        } else {
            require(false, "cant craft");
        }

        uint256 burnRelicRarity = burnRelicTokenIds.length >= 1 && myRarity == 3
            ? getRelicRarity(burnRelicTokenIds[0])
            : myRarity;
        require(
            burnRelicRarity >= 1 && burnRelicRarity <= 3,
            "burning relic can be only uncommon, rare, legendary"
        );
        for (uint256 i = 0; i < burnRelicTokenIds.length; i++) {
            uint256 bTokenId = burnRelicTokenIds[i];
            require(bTokenId != tokenId, "cannot burn the crafting relic");
            require(
                getRelicRarity(bTokenId) == burnRelicRarity,
                "burning relic rarity must match burnRelicRarity"
            );
            _burn(bTokenId);
        }

        emit RelicCraft(
            msg.sender,
            tokenId,
            myRarity,
            burnRelicRarity,
            kzgTokenIds,
            kubzTokenIds,
            burnRelicTokenIds
        );
    }

    function checkValidityAlt(bytes calldata signature, string memory action)
        public
        view
        returns (bool)
    {
        require(
            ECDSA.recover(
                ECDSA.toEthSignedMessageHash(
                    keccak256(abi.encodePacked(msg.sender, action))
                ),
                signature
            ) == signerAlt,
            "invalid signature"
        );
        return true;
    }

    function usePotions(
        uint256[] calldata kubzTokenIds,
        uint256 myPotions,
        bytes calldata signature
    ) public {
        string memory action = string.concat(
            "kubz-relic_potions_",
            Strings.toString(myPotions)
        );
        checkValidityAlt(signature, action);
        for (uint256 i = 0; i < kubzTokenIds.length; i++) {
            require(
                kubzContract.ownerOf(kubzTokenIds[i]) == msg.sender,
                "not owner of kubzTokenIds"
            );
            uint256 aStam = kubzActualStamina(kubzTokenIds[i]);
            if (aStam < 200) {
                require(
                    myPotions - potionsUsed[msg.sender] >= 2,
                    "NEP: Kubz, 2"
                );
                unchecked {
                    potionsUsed[msg.sender] += 2;
                    kubzStamina[kubzTokenIds[i]] = 700;
                }
            } else if (aStam < 700) {
                require(
                    myPotions - potionsUsed[msg.sender] >= 1,
                    "NEP: Kubz, 1"
                );
                unchecked {
                    potionsUsed[msg.sender] += 1;
                    kubzStamina[kubzTokenIds[i]] = 700;
                }
            }
        }
    }

    function craftUsingPotions(
        uint256 tokenId,
        uint256[] calldata kzgTokenIds,
        uint256[] calldata kubzTokenIds,
        uint256[] calldata burnRelicTokenIds,
        uint256 myPotions,
        bytes calldata signature
    ) external {
        if (kubzTokenIds.length > 0) {
            usePotions(kubzTokenIds, myPotions, signature);
        }
        craft(tokenId, kzgTokenIds, kubzTokenIds, burnRelicTokenIds);
    }

    function upgradeRelic(
        uint256 tokenId,
        uint256 newRarity,
        bytes calldata signature
    ) external {
        string memory action = string.concat(
            "kubz-relic_upgrade_",
            Strings.toString(tokenId),
            ",",
            Strings.toString(newRarity)
        );
        checkValidityAlt(signature, action);
        require(ownerOf(tokenId) == msg.sender, "Not owner of token");
        uint256 oldRarity = getRelicRarity(tokenId);
        require(newRarity > oldRarity, "Relic can only be upgraded");
        if (newRarity == 4) {
            require(
                mythicalUpgradeCount + 1 <= mythicalUpgradeQuota,
                "mythical quota exceeded"
            );
            mythicalUpgradeCount += 1;
        }
        boxRarity[tokenId] = newRarity;
        emit RelicUpgrade(msg.sender, tokenId, oldRarity, newRarity);
    }

    function mintSpecialRelic(
        uint256 rarity,
        string calldata nonce,
        bytes calldata signature
    ) external {
        string memory action = string.concat(
            "kubz-relic_msr_",
            Strings.toString(rarity),
            ",",
            nonce
        );
        checkValidityAlt(signature, action);
        require(!msrNonceUsed[nonce], "already minted");
        if (rarity == 99) {
            require(
                dragonMintCount + 1 <= dragonMintQuota,
                "dragon quota exceeded"
            );
            dragonMintCount += 1;
        }
        msrNonceUsed[nonce] = true;
        uint256 tokenId = _nextTokenId();
        safeMint(msg.sender, 1);
        boxRarity[tokenId] = rarity;
        emit RelicMint(msg.sender, tokenId, rarity);
    }

    // =============== IERC721xHelper ===============
    function isUnlockedMultiple(uint256[] calldata tokenIds)
        external
        pure
        returns (bool[] memory)
    {
        bool[] memory part = new bool[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            part[i] = true;
        }
        return part;
    }

    function ownerOfMultiple(uint256[] calldata tokenIds)
        external
        view
        returns (address[] memory)
    {
        address[] memory part = new address[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            part[i] = ownerOf(tokenIds[i]);
        }
        return part;
    }

    function tokenNameByIndexMultiple(uint256[] calldata tokenIds)
        external
        pure
        returns (string[] memory)
    {
        string[] memory part = new string[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            part[i] = "Kubz Relic";
        }
        return part;
    }
}