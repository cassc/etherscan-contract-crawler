// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import 'erc721psi/contracts/extension/ERC721PsiBurnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol';
import '@divergencetech/ethier/contracts/thirdparty/opensea/ProxyRegistry.sol';
import '../utils/WakumbaOwnedUpgradeable.sol';
import '../airdrop/SwordOfBravery.sol';
import './utils/IRandom.sol';

contract MountainNFT is
    ERC2981Upgradeable,
    WakumbaOwnedUpgradeable,
    ERC721PsiBurnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using StringsUpgradeable for uint256;
    using StringsUpgradeable for uint32;
    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;
    using ECDSAUpgradeable for bytes32;

    event MountainMinted(address owner, uint32[5] allocations, uint256 firstTokenId);

    uint256 public constant MAX_SUPPLY = 8000;

    string private __tokenBaseURI;
    address private __openSeaRegistry;

    // getRarityLevel(tokenId)
    uint32[MAX_SUPPLY] private __rarityLevel;
    // getLevelIndex(tokenId)
    uint32[MAX_SUPPLY] private __levelIndex;
    // getLevelSupply(swordId)
    uint32[5] private __levelSupply;

    bool public __whitelistSaleActive;
    bool public __publicSaleActive;

    BitMapsUpgradeable.BitMap __upgraded;
    mapping(address => uint8) private __publicMinted;

    uint8 public __maxPublicMintPerWallet;
    uint256 public __publicMint2ndPrice;

    // mint limits
    uint32[6] private __breakPoints;
    uint32[5] private __maxLimits;
    uint32[5] private __reservations;

    // contract dependencies
    SwordOfBravery private __swordContract;
    IRandom private __randContract;

    // Game attributes
    bytes24[MAX_SUPPLY] private att_names;
    uint8[MAX_SUPPLY] private att_restoreRate;
    uint16[MAX_SUPPLY] private att_strength;

    // Game Defaults
    uint8[5] private __defaultRestoreRates;
    uint16[5] private __defaultStrengths;

    /** New Storage Data Starts Here **/

    function initialize(address swordAddress, address randAddress) public initializer {
        __ERC721Psi_init('Mountain x DoDoFrens', 'MT');
        __ERC2981_init();
        __WakumbaOwned_init();
        _setDefaultRoyalty(address(0x6D1EEbad7efF9D1DFA600f4fC42F8F74d1f5E91e), 750);
        __openSeaRegistry = address(0xa5409ec958C83C3f309868babACA7c86DCB077c1);
        __swordContract = SwordOfBravery(swordAddress);
        __randContract = IRandom(randAddress);

        // init defaults
        __maxPublicMintPerWallet = 3;
        __publicMint2ndPrice = 0.003 ether;

        __breakPoints = [0, 3600, 5890, 7150, 7990, 8000]; // left: inclusive, right: exclusive
        __maxLimits = [
            __breakPoints[1] - __breakPoints[0],
            __breakPoints[2] - __breakPoints[1],
            __breakPoints[3] - __breakPoints[2],
            __breakPoints[4] - __breakPoints[3],
            __breakPoints[5] - __breakPoints[4]
        ];
        __reservations = [2960, 80, 130, 75, 10];

        // game attributes
        __defaultRestoreRates = [0, 18, 38, 58, 98];
        __defaultStrengths = [791, 841, 891, 941, 991];
    }

    // Getters
    function getRarityLevel(uint256 tokenId) public view returns (uint32) {
        return __rarityLevel[tokenId];
    }

    function getLevelIndex(uint256 tokenId) public view returns (uint32) {
        return __levelIndex[tokenId];
    }

    function getLevelSupply(uint32 rarityLevel) public view returns (uint32) {
        return __levelSupply[rarityLevel];
    }

    // Setters
    function setSwordContract(address addr) external onlyOwner {
        __swordContract = SwordOfBravery(addr);
    }

    function setRandContract(address addr) external onlyOwner {
        __randContract = IRandom(addr);
    }

    function setPublicMintSettings(uint8 perWalletQty, uint256 etherPrice) external onlyOwner {
        __maxPublicMintPerWallet = perWalletQty;
        __publicMint2ndPrice = etherPrice;
    }

    // Mint Functions
    function _feelsLucky(
        uint256 _tokenId,
        uint32 currLevel,
        uint32 qty
    ) internal {
        uint32[5] memory allocations = __randContract.getLuckyDraws(qty, __breakPoints, currLevel, 4);

        unchecked {
            uint32 wins;
            for (uint32 i = 0; i < 5; i++) {
                wins += allocations[i];
            }
            allocations[currLevel] = qty - wins;

            // Recalcuate the allocation based on reservations
            uint32[5] memory pools;
            uint32[5] memory supplies;

            for (uint32 k = 0; k < 2; k++)
                // loop twice to fill all holes
                for (uint32 i = 0; i < 5; i++) {
                    uint32 rarityLevel = 4 - i;

                    uint32 supply = supplies[rarityLevel];
                    if (supply == 0) {
                        if (__maxLimits[rarityLevel] > __levelSupply[rarityLevel]) {
                            supply = __maxLimits[rarityLevel] - __levelSupply[rarityLevel];
                        }
                        supplies[rarityLevel] = supply;
                    }
                    uint32 pool = pools[rarityLevel];
                    if (pool == 0) {
                        if (rarityLevel == currLevel) {
                            pool = supply;
                        } else if (supply > __reservations[rarityLevel]) {
                            pool = supply - __reservations[rarityLevel];
                        }
                        pools[rarityLevel] = pool;
                    }

                    /* Allocated Too Many, move extra parts to the next level */
                    if (allocations[rarityLevel] > pool) {
                        uint32 nextLevel = rarityLevel == 0 ? 4 : (rarityLevel - 1);
                        allocations[nextLevel] += allocations[rarityLevel] - pool;
                        allocations[rarityLevel] = pool;
                    }
                }

            // release current level reservations if sword already upgraded
            uint32 luckyTokensCount = qty - allocations[currLevel];
            if (luckyTokensCount > 0) {
                if (__reservations[currLevel] > luckyTokensCount) {
                    __reservations[currLevel] -= luckyTokensCount;
                } else {
                    __reservations[currLevel] = 0;
                }
            }
        }

        _tokenAlloc(allocations, _tokenId);

        // update seed for the next round
        __randContract.seed(block.timestamp);
    }

    function _tokenAlloc(uint32[5] memory allocations, uint256 tokenId) internal {
        uint8 rand = uint8(__randContract.getRand() % 10);
        uint256 _tokenId = tokenId;
        unchecked {
            for (uint32 rarityLevel = 0; rarityLevel < 5; rarityLevel++) {
                for (uint32 i = 0; i < allocations[rarityLevel]; i++) {
                    __rarityLevel[_tokenId] = rarityLevel;
                    __levelIndex[_tokenId] = __levelSupply[rarityLevel];
                    __levelSupply[rarityLevel] += 1;

                    // assign game attributes
                    if (rarityLevel > 0) {
                        att_restoreRate[_tokenId] = __defaultRestoreRates[rarityLevel] + (rand % 3);
                    }
                    att_strength[_tokenId] = __defaultStrengths[rarityLevel] + rand;

                    _tokenId++;
                }
            }
        }
        // notfiy client
        emit MountainMinted(_msgSender(), allocations, tokenId);
    }

    function swordMint(uint32 swordId, uint32 qty) public nonReentrant {
        require(totalSupply() + qty <= MAX_SUPPLY, 'Cannot exceed total supply');

        require(__whitelistSaleActive, 'Whitelist Sale has not started');

        require(__swordContract.balanceOf(_msgSender(), swordId) >= qty, 'Not enough swords to redeem');

        __swordContract.burn(_msgSender(), swordId, qty);

        // Mint NFTs
        uint256 _tokenId = totalSupply();
        _safeMint(_msgSender(), qty);

        // set Gen0 for game
        for (uint32 i = 0; i < qty; i++) {
            __upgraded.set(_tokenId + i);
        }

        if (swordId < 3) {
            // Common/Uncommon/Rare, do lucky enhance first and then mint
            _feelsLucky(_tokenId, swordId, qty);
        } else {
            // Legendary & Epic can do directly mint
            // (because all the 10 legendary swords are mint already, no need to reserve)
            uint32[5] memory allocations;
            allocations[swordId] = qty;
            _tokenAlloc(allocations, _tokenId);
        }
    }

    function publicMint(uint8 qty) public payable nonReentrant {
        require(totalSupply() + qty <= MAX_SUPPLY, 'Cannot exceed total supply');

        require(__publicSaleActive, 'Public Sale has not started');

        require(__publicMinted[_msgSender()] + qty <= __maxPublicMintPerWallet, 'Cannot exceed max mint per wallet');

        if (__publicMinted[_msgSender()] <= 0) {
            // 1 free per wallet
            require(__publicMint2ndPrice * (qty - 1) <= msg.value, 'Not enough eth for mint');
        } else {
            require(__publicMint2ndPrice * qty <= msg.value, 'Not enough eth for mint');
        }

        __publicMinted[_msgSender()] += qty;

        uint256 _tokenId = totalSupply();
        _safeMint(_msgSender(), qty);

        _feelsLucky(
            _tokenId,
            0, /* Public Mint Always Starts from Common Level */
            qty
        );
    }

    function setBreakPoints(uint32[6] calldata breakPoints, uint32[5] calldata reservations) external onlyOwner {
        __breakPoints = breakPoints;
        __maxLimits = [
            __breakPoints[1] - __breakPoints[0],
            __breakPoints[2] - __breakPoints[1],
            __breakPoints[3] - __breakPoints[2],
            __breakPoints[4] - __breakPoints[3],
            __breakPoints[5] - __breakPoints[4]
        ];
        __reservations = reservations;
    }

    function getRates()
        public
        view
        returns (
            uint32,
            uint32[5] memory,
            uint32[5] memory,
            uint32[6] memory
        )
    {
        return (
            __breakPoints[5], // total
            __maxLimits,
            __reservations,
            __breakPoints
        );
    }

    // Wakumba Power
    function sacraficeForHonor(uint256 tokenId) public onlyWakumbas {
        require(_exists(tokenId), 'Token does not exist');
        _burn(tokenId);
    }

    // URI Hack
    function setTokenBaseURI(string memory baseUri) public onlyOwner {
        __tokenBaseURI = baseUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return __tokenBaseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'ERC721Psi: URI query for nonexistent token');

        string memory baseURI = string(
            abi.encodePacked(
                _baseURI(),
                __rarityLevel[tokenId].toString(),
                '/',
                __levelIndex[tokenId].toString(),
                '/',
                tokenId.toString(),
                '?'
            )
        );

        string[4] memory parts;
        parts[0] = __upgraded.get(tokenId) ? 'GEN=0&' : 'GEN=1&';
        parts[1] = __upgraded.get(tokenId) && att_names[tokenId] != bytes32(0)
            ? string(abi.encodePacked('NAME=', att_names[tokenId], '&'))
            : '';
        parts[2] = __upgraded.get(tokenId)
            ? string(abi.encodePacked('RESTORES_P=', uint32(att_restoreRate[tokenId]).toString(), '&'))
            : '';
        parts[3] = __upgraded.get(tokenId)
            ? string(abi.encodePacked('STRENGTH_R=', uint32(att_strength[tokenId]).toString(), '&'))
            : '';
        return string.concat(baseURI, parts[0], parts[1], parts[2], parts[3]);
    }

    // ERC2981 Hooks
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    // Admin Hooks
    function setSalesStatus(bool wl, bool pub) public onlyOwner {
        __whitelistSaleActive = wl;
        __publicSaleActive = pub;
        // remove reservations when public sales starts
        if (__publicSaleActive) {
            __reservations = [0, 0, 0, 0, 0];
        }
    }

    // Gas optimize
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        if (address(ProxyRegistry(__openSeaRegistry).proxies(owner)) == operator) {
            return true;
        }
        if (isWakumba(operator)) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721PsiUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // Game Hooks
    function setName(uint256 tokenId, string calldata name) public {
        require(ownerOf(tokenId) == _msgSender(), 'token not owned');
        att_names[tokenId] = bytes24(abi.encodePacked(name));
    }

    function getGameAttributes(uint256 tokenId)
        public
        view
        returns (
            uint32,
            uint32,
            bytes24,
            bool
        )
    {
        return (att_strength[tokenId], att_restoreRate[tokenId], att_names[tokenId], __upgraded.get(tokenId));
    }

    // future Hooks
    function upgrade(
        uint256 tokenId,
        uint16 strength,
        uint8 restoreRate
    ) public onlyWakumbas {
        __upgraded.set(tokenId);
        att_strength[tokenId] = strength;
        att_restoreRate[tokenId] = restoreRate;
    }
}