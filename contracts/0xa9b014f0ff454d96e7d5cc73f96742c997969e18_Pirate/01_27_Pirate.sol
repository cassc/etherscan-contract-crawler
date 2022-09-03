// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
// import "hardhat/console.sol";
import "../booty/IBooty.sol";
import "../errors.sol";
import "./IURIBuilder.sol";
import "./TraitSet.sol";
import "../utils/Random.sol";

// solhint-disable not-rely-on-time

contract Pirate is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using AddressUpgradeable for address;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    struct Stake {
        address owner;
        uint64 timestamp;
    }

    struct WeightSet {
        uint112 beard;
        uint112 femaleBody;
        uint32 gender;
        uint176 femaleHat;
        uint80 wings;
        uint96 hairColor;
        uint128 maleBody;
        uint32 unique;
        uint112 maleHair;
        uint144 special;
        uint256 maleClothing;
        uint256 maleHat;
        uint224 maleFace;
        uint144 femaleClothing;
        uint112 beardIfSkeleton;
        uint96 femaleFace;
        uint48 femaleHair;
        uint48 maleHairIfCrown;
        uint96 maleHairIfMask;
        uint144 maleFaceIfSkeleton;
        uint224 maleFaceIfCrown;
        uint192 maleFaceIfSpecial;
    }

    uint16 private _maxSupply;
    uint8 private _totalUniqueSupply;
    uint64 private _launchDate;
    uint256 private _mintPrice;
    uint256 private _nonce;

    bytes32[2] private _merkleRoots;

    mapping(address => uint256) private _mintCounts;
    mapping(uint256 => Stake) private _stakes;
    mapping(uint256 => TraitSet) private _traits;
    mapping(bytes32 => bool) private _traitHashes;

    IBooty private _booty;
    CountersUpgradeable.Counter private _tokenIdCounter;
    IURIBuilder private _uriBuilder;
    WeightSet private _weights;

    mapping(address => uint256) private _mintCounts2;

    modifier onlyEOA() {
        if (msg.sender.isContract() || msg.sender != tx.origin) {
            revert CallerNotEOA();
        }

        _;
    }

    constructor() initializer {}

    function initialize(uint16 maxSupply) public initializer {
        __ERC721_init("Pirate", "PIRAT");
        __ERC721Enumerable_init();
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        _maxSupply = maxSupply;
        _nonce = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender)));

        _weights.beard = 0x0384_0898_0898_0898_044c_044c_012c;
        _weights.beardIfSkeleton = 0x0514_0a28_0000_0a28_05dc_05dc_01f4;
        _weights.femaleBody = 0x07d0_07d0_0384_07d0_07d0_0384_00c8;
        _weights.femaleClothing = 0x0898_0898_0898_0898_012c_012c_012c_0096_0096;
        _weights.femaleFace = 0x0a8c_07d0_07d0_07d0_03e8_012c;
        _weights.femaleHair = 0x1194_1194_03e8;
        _weights.femaleHat = 0x05dc_0578_0578_0578_0578_0578_01c2_01c2_012c_0096_0096;
        _weights.gender = 0x2134_05dc;
        _weights.hairColor = 0x060e_0898_0898_0898_060e_012c;
        _weights.maleBody = 0x07d0_07d0_0352_07d0_07d0_0352_0096_0096;
        _weights.maleClothing = 0x0578_0578_0578_0578_0578_0578_0118_0118_0118_0104_0064_0064_0064_0064_0032_0032;
        _weights.maleFace = 0x0fa0_0320_0320_0320_0320_0320_0320_0113_0113_0113_0113_0022_0021_0021;
        _weights.maleFaceIfCrown = 0x0fa0_03c0_03c0_03c0_0000_03c0_03c0_016e_016e_0000_016e_0033_0033;
        _weights.maleFaceIfSkeleton = 0x1d4c_0000_0000_044c_0000_0000_0000_02bc_02bc;
        _weights.maleFaceIfSpecial = 0x1770_0384_0384_0384_0000_0000_0000_0190_0190_0000_0190_0064;
        _weights.maleHair = 0x06b8_06b8_06b8_02bc_06b8_06b8_02bc;
        _weights.maleHairIfCrown = 0x0fa0_0fa0_07d0;
        _weights.maleHairIfMask = 0x0708_0708_0708_03e8_0708_0708;
        _weights.maleHat = 0x03e8_03e8_03e8_03e8_03e8_03e8_03e8_03e8_0154_0154_0154_0154_0154_0064_0064_0064;
        _weights.special = 0x24b8_007d_007d_007d_007d_001e_001e_0014_0014;
        _weights.unique = 0x2690_0080;
        _weights.wings = 0x251c_0096_0096_0096_0032;
    }

    function bootyFor(uint256[] calldata tokenIds) external view returns (uint256) {
        uint256 amount;

        for (uint256 i; i < tokenIds.length; i++) {
            _ensureExists(tokenIds[i]);

            amount += _bootyFor(tokenIds[i]);
        }

        return amount;
    }

    function isStaked(uint256 tokenId) external view returns (bool) {
        _ensureExists(tokenId);

        return _stakes[tokenId].owner != address(0);
    }

    function mint(uint256 amount, bool staked) external onlyEOA {
        if (_launchDate + 125 hours > block.timestamp) {
            revert MintingUnavailable();
        }

        if (amount < 1 || amount > 4) {
            revert OutOfRange(1, 4);
        }

        _mintCore(msg.sender, amount, staked);
        _updateNonce();
    }

    function mint(bool staked, uint256[] calldata tokenIds) external onlyEOA {
        if (_launchDate > block.timestamp) {
            revert MintingUnavailable();
        }

        for (uint256 i; i < tokenIds.length; i++) {
            if (msg.sender != _stakes[tokenIds[i]].owner || _stakes[tokenIds[i]].timestamp >= _launchDate) {
                revert Unauthorized();
            }
        }

        uint256 maxAmount = _claimableAmountFor(tokenIds.length);

        if (maxAmount < 1 || maxAmount > 7) {
            revert OutOfRange(1, 7);
        }

        uint256 amount = _mintCounts2[msg.sender];

        if (amount >= maxAmount) {
            revert MintLimitExceeded(maxAmount);
        }

        _mintCounts2[msg.sender] = maxAmount;

        _mintCore(msg.sender, maxAmount - amount, staked);
        _updateNonce();
    }

    function mint(
        address to,
        uint256 amount,
        bool staked
    ) external onlyOwner {
        if (amount < 1 || amount > 55) {
            revert OutOfRange(1, 55);
        }

        _mintCore(to, amount, staked);
        _updateNonce();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function reclaim(uint256[] calldata tokenIds) external whenNotPaused {
        uint256 amount;

        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            if (msg.sender != _stakes[tokenId].owner) {
                revert Unauthorized();
            }

            amount += _bootyFor(tokenId);

            _transfer(address(this), msg.sender, tokenId);

            delete _stakes[tokenId];
        }

        _booty.mint(msg.sender, amount);
    }

    function setBooty(address address_) external onlyOwner {
        _booty = IBooty(address_);
    }

    function setLaunchDate(uint64 timestamp) external onlyOwner {
        _launchDate = timestamp;
    }

    function setURIBuilder(address address_) external onlyOwner {
        _uriBuilder = IURIBuilder(address_);
    }

    function stake(uint256[] calldata tokenIds) external whenNotPaused {
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            if (msg.sender != ownerOf(tokenId)) {
                revert Unauthorized();
            }

            _transfer(msg.sender, address(this), tokenId);
            _onStaked(msg.sender, tokenId);
        }
    }

    function stakeBalanceOf(address owner) public view returns (uint256) {
        uint256 balance;
        uint256 count = balanceOf(address(this));

        for (uint256 i; i < count; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(address(this), i);

            if (_stakes[tokenId].owner == owner) {
                balance++;
            }
        }

        return balance;
    }

    function stakedTokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256) {
        uint256 count = balanceOf(address(this));
        uint256 j;

        for (uint256 i; i < count; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(address(this), i);

            if (_stakes[tokenId].owner == owner) {
                if (j == index) {
                    return tokenId;
                }

                j++;
            }
        }

        revert TokenNotFound(index);
    }

    function traitsOf(uint256 tokenId) external view onlyOwner returns (TraitSet memory) {
        _ensureExists(tokenId);

        return _traits[tokenId];
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdrawBooty(uint256[] calldata tokenIds) external whenNotPaused {
        uint256 amount;

        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            if (msg.sender != _stakes[tokenId].owner) {
                revert Unauthorized();
            }

            amount += _bootyFor(tokenId);

            _stakes[tokenId].timestamp = uint64(block.timestamp);
        }

        _booty.mint(msg.sender, amount);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _ensureExists(tokenId);

        return _uriBuilder.build(tokenId, _traits[tokenId]);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _bootyFor(uint256 tokenId) private view returns (uint256) {
        return
            _stakes[tokenId].timestamp == 0 ? 0 : ((block.timestamp - _stakes[tokenId].timestamp) * 1 ether) / 1 days;
    }

    function _claimableAmountFor(uint256 balance) private pure returns (uint256) {
        if (balance >= 25) return 7;

        if (balance >= 21) return 6;

        if (balance >= 16) return 5;

        if (balance >= 12) return 4;

        if (balance >= 8) return 3;

        if (balance >= 4) return 2;

        if (balance >= 1) return 1;

        return 0;
    }

    function _ensureExists(uint256 tokenId) private view {
        if (!_exists(tokenId)) {
            revert TokenNotFound(tokenId);
        }
    }

    function _mintCore(
        address to,
        uint256 amount,
        bool staked
    ) private {
        if (amount + totalSupply() > _maxSupply) {
            revert SoldOut();
        }

        TraitSet memory traits;

        for (uint256 i; i < amount; i++) {
            _tokenIdCounter.increment();

            bytes32 hash_;
            uint256 tokenId = _tokenIdCounter.current();
            uint256 t = tokenId;

            do {
                t = uint256(keccak256(abi.encodePacked(t, _nonce)));

                traits = _randomTraits(t);

                if (traits.unique == Unique.None) {
                    hash_ = keccak256(
                        abi.encodePacked(
                            traits.beard,
                            traits.body,
                            traits.clothing,
                            traits.face,
                            traits.gender,
                            traits.hair,
                            traits.hairColor,
                            traits.hat,
                            traits.special,
                            traits.wings
                        )
                    );
                }
            } while (_traitHashes[hash_]);

            if (traits.unique == Unique.None) {
                _traitHashes[hash_] = true;
            } else {
                _totalUniqueSupply++;
            }

            _traits[tokenId] = traits;

            if (staked) {
                _mint(address(this), tokenId);
                _onStaked(to, tokenId);
            } else {
                _safeMint(to, tokenId);
            }
        }
    }

    function _onStaked(address owner, uint256 tokenId) private {
        _stakes[tokenId] = Stake({owner: owner, timestamp: uint64(block.timestamp)});
    }

    function _randomTraits(uint256 seed) private view returns (TraitSet memory) {
        TraitSet memory traits;

        uint256 unique = _tokenIdCounter.current() / (_maxSupply / 11);

        if ((unique + 1 > _totalUniqueSupply && _totalUniqueSupply < 11)) {
            bool isUnique;

            if (unique == _totalUniqueSupply + 1) {
                isUnique = true;
                unique--;
            } else {
                isUnique = Random.weighted(_weights.unique, 2, seed++) == 1;
            }

            if (isUnique) {
                traits.unique = Unique(unique + 1);

                return traits;
            }
        }

        traits.gender = Gender(Random.weighted(_weights.gender, 2, seed++));

        if (traits.gender == Gender.Male) {
            traits.special = Special(Random.weighted(_weights.special, 9, seed++));

            if (traits.special < Special.IvorySkeleton) {
                traits.body = uint8(Random.weighted(_weights.maleBody, 8, seed++) + 1);
                traits.wings = Wing(Random.weighted(_weights.wings, 5, seed++));
            }

            if (traits.special == Special.None || traits.special >= Special.IvorySkeleton) {
                MaleHat hat = MaleHat(Random.weighted(_weights.maleHat, 16, seed++));
                MaleFace face;

                if (traits.special == Special.None) {
                    traits.clothing = uint8(Random.weighted(_weights.maleClothing, 16, seed++) + 1);

                    if (hat != MaleHat.SamuraiHelmet) {
                        if (hat == MaleHat.Crown || hat == MaleHat.Headband || hat == MaleHat.RoyalCrown) {
                            face = MaleFace(Random.weighted(_weights.maleFaceIfCrown, 13, seed++));

                            traits.hair = uint8(Random.weighted(_weights.maleHairIfCrown, 3, seed++) + 2);
                        } else {
                            face = MaleFace(Random.weighted(_weights.maleFace, 14, seed++));

                            if (
                                (face >= MaleFace.BoneSkullMask && face <= MaleFace.SurgicalMask) ||
                                face == MaleFace.BlackSkullMask ||
                                face == MaleFace.OniMask ||
                                face == MaleFace.GoldSkullMask
                            ) {
                                traits.hair = uint8(Random.weighted(_weights.maleHairIfMask, 6, seed++) + 1);
                            } else {
                                traits.hair = uint8(Random.weighted(_weights.maleHair, 7, seed++) + 1);
                            }
                        }
                    }
                } else {
                    if (hat == MaleHat.SamuraiHelmet) {
                        hat = MaleHat.None;
                    }

                    face = MaleFace(Random.weighted(_weights.maleFaceIfSkeleton, 9, seed++));
                }

                traits.face = uint8(face);
                traits.hat = uint8(hat);

                if (face != MaleFace.NinjaMask && face != MaleFace.SurgicalMask) {
                    traits.beard = Beard(
                        Random.weighted(
                            traits.special >= Special.IvorySkeleton && traits.beard == Beard.Short
                                ? _weights.beardIfSkeleton
                                : _weights.beard,
                            7,
                            seed++
                        )
                    );
                }

                if (MaleHair(traits.hair) != MaleHair.None || traits.beard != Beard.None) {
                    traits.hairColor = HairColor(Random.weighted(_weights.hairColor, 6, seed++) + 1);
                }
            } else {
                traits.face = uint8(Random.weighted(_weights.maleFaceIfSpecial, 12, seed++));
            }
        } else if (traits.gender == Gender.Female) {
            traits.body = uint8(Random.weighted(_weights.femaleBody, 7, seed++));
            traits.clothing = uint8(Random.weighted(_weights.femaleClothing, 9, seed++));
            traits.face = uint8(Random.weighted(_weights.femaleFace, 6, seed++));
            traits.hair = uint8(Random.weighted(_weights.femaleHair, 3, seed++));
            traits.hairColor = HairColor(Random.weighted(_weights.hairColor, 6, seed++) + 1);
            traits.hat = uint8(Random.weighted(_weights.femaleHat, 11, seed++));
            traits.wings = Wing(Random.weighted(_weights.wings, 5, seed++));
        }

        return traits;
    }

    function _updateNonce() private {
        _nonce = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _nonce)));
    }
}