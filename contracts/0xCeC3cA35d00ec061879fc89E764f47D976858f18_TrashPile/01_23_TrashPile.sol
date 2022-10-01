// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TrashBase.sol";
import "./EIP712Whitelisting.sol";

contract TrashPile is TrashBase, EIP712Whitelisting {
    // Number of common variations for each trait
    uint8[8] private ntraits = [7, 7, 5, 8, 7, 8, 5, 7];

    uint256 public constant maxMinted = 7995; // Max supply is 7999, 7995 minted plus 4 legendaries airdropped
    uint256 public constant maxLegendaries = 4; // 4 unique legendaries airdropped to random holders after mint

    uint256 public presaleStartTime;
    uint256 public presaleEndTime;
    uint256 public constant maxPresale = 1200; // Whitelist presale max number, these are "taken" from maxMinted

    constructor(
        address _proxyRegistryAddress,
        uint256 _saleStartTime,
        uint256 _saleEndTime,
        address coordinator,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        bytes32 _defaultKeyHash,
        uint64 _vrfsubid
        ) 
        TrashBase(
        "Piles of Trash", "PILES",
        _proxyRegistryAddress,
        _saleStartTime,
        _saleEndTime,
        coordinator,
        _callbackGasLimit,
        _requestConfirmations,
        _defaultKeyHash,
        _vrfsubid
        )
        EIP712Whitelisting()
    {
        setWhitelistSigningAddress(msg.sender);
    }

    function mintPresale(bytes calldata signature) external requiresWhitelist(signature) {
        require(msg.sender == tx.origin, "Contract mint not allowed");
        require(_minted < maxPresale, "Sold out");
        require(!hasMinted[msg.sender], "Already minted");
        require(block.timestamp > presaleStartTime, "Sale has not started");
        require(block.timestamp < presaleEndTime, "Sale has ended");

        hasMinted[msg.sender] = true;

        // Always mint 3
        _mint(msg.sender, 3);
    }

    function setPreSalePeriod(uint256 _startTime, uint256 _endTime) external onlyOwner {
        presaleStartTime = _startTime;
        presaleEndTime = _endTime;
    }

    function mint() public payable {
        require(msg.sender == tx.origin, "Contract mint not allowed");
        require(msg.value == 8800000000000000, "Include payment");
        // Number of NFTs minted until now must be less than 7995
        require(_minted < maxMinted, "Sold out");
        require(!hasMinted[msg.sender], "Already minted");
        require(block.timestamp > saleStartTime, "Sale has not started");
        require(block.timestamp < saleEndTime, "Sale has ended");

        hasMinted[msg.sender] = true;

        // Always mint 3
        _mint(msg.sender, 3);
    }

    function burn(uint256 tokenId, address redeemTo) external {
        require(block.timestamp > saleEndTime + 86400, "Cannot burn until one day after sale");
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Trash: transfer caller is not owner nor approved"
        );
        uint256 nftrarity = rarity(tokenId);
        require(tokenId < nextCountId, "Cannot burn as token is not in vault");
        _burn(tokenId);

        if (redeemTo == address(0)) {
            ITrashCan(feeVault).emptyBurn(nftrarity);
        } else {
            ITrashCan(feeVault).redeemBurn(nftrarity, redeemTo);
        }
    }

    function redeemValue(uint256 tokenId) external view returns (uint256) {
        return (feeVault.balance * rarity(tokenId)) / ITrashCan(feeVault).totalPoints();
    }

    function traits(uint256 tokenId) external view returns(uint256[9] memory _traits) {
        // Check if this is a legendary
        if (firstLegendaryId > 0 && firstLegendaryId <= tokenId && tokenId < firstLegendaryId + maxLegendaries) {
            // Set the correct legendary trait, from 1 to maxLegendaries
            _traits[8] = tokenId - firstLegendaryId + 1;
            // Every other trait is 0 for legendaries
            return _traits;
        }
        // Not legendary, _traits[8] remains 0.

        uint256 tokenSeed = seed(tokenId);

        uint256 rareTraits = 500 / ((tokenSeed % 10000) + 90); // number of rare traits, 0 to 5

        // Roll random trait to make rare
        uint8 nextRareTrait = uint8(accessByte(tokenSeed, uint8(rareTraits) + 10) % ntraits.length);

        // Continue until no more rare traits to assign
        while(rareTraits > 0) {
            // Trait already assigned
            if (_traits[nextRareTrait] != 0) {
                // If it's greater than zero, go back one trait
                // And try again
                if (nextRareTrait > 0) {
                    --nextRareTrait;
                    continue;
                } else {
                    // If we're at 0, jump to the last trait
                    // And try again
                    nextRareTrait = uint8(ntraits.length) - 1;
                    continue;
                }
            }
            // Trait not assigned
            // ntraits[i] + 1 is the ID for the rare variation of that trait
            _traits[nextRareTrait] = ntraits[nextRareTrait] + 1;
            --rareTraits;
            nextRareTrait = uint8(accessByte(tokenSeed, uint8(ntraits.length + rareTraits)) % ntraits.length);
        }

        // Roll 8 common traits, 0 to ntraits.length
        for (uint8 i = 0; i < ntraits.length; i++) {
            // Trait must be rare, skip it
            if (_traits[i] != 0) {
                continue;
            }
            // Select number between 1 and ntraits
            // By rolling between 0 and (ntraits - 1) and adding 1
            // This is our (common) trait ID
            // 0 would indicate absence
            _traits[i] = (accessByte(tokenSeed, i) % ntraits[i]) + 1;
        }

        // Cannot show cat twice
        if (_traits[6] == 6 && _traits[7] == 8) {
            _traits[7] = 9;
        }

        return _traits;
    }

    /* 
    * `10000 / (seed(tokenId) % 10000)` represents the rarity of the NFT.
    * For example, a result of 20 would mean this NFT is 1 in 20, so among the 5% most rare,
    * meaning only 5 out of 100 NFTs (500 out of 10000) are as good or better than this one.
    * Notice that the actual rarity has a bias added (+190 on the denominator)
    * This is to reduce the extremes, bringing the maximum rarity value down to ~55 from 10000 (!)
    * Otherwise the top 1% of NFTs would all have over 100 times the value of an "average" one,
    * the top 0.1% would all have over 1000 times the average value, etc. up to 10k.
    * In practice this is now always between 1 and ~55, and determines the NFT's share of the vault.
    *
    * A function that is proportional to this one but with a different bias is used to determine
    * the number of rare traits an NFT has. Any NFT with a rarity() score of over 18 here is guaranted to be
    * assigned one or more rare traits by the corresponding function. Higher scores result in more rare traits.
    */
    function _rarity(uint256 tokenId) internal view returns(uint256) {
        return (10000 / ((seed(tokenId) % 10000) + 190)) + 1;
    }

    function rarity(uint256 tokenId) public view returns(uint256) {
        // Check if it's a legendary
        if (firstLegendaryId > 0 && firstLegendaryId <= tokenId && tokenId < firstLegendaryId + maxLegendaries) {
            // Legendaries have fixed rarity
            return 100;
        }
        // Use regular algorithm
        return _rarity(tokenId);
    }

    function rareTraits(uint256 tokenId) public view returns(uint256) {
        // Check if it's a legendary
        if (firstLegendaryId > 0 && firstLegendaryId <= tokenId && tokenId < firstLegendaryId + maxLegendaries) {
            // Legendaries have fixed rarity
            return 1;
        }

        return 500 / ((seed(tokenId) % 10000) + 90); // number of rare traits, 0 to 5
    }

    // Add total rarity points to vault on-chain
    uint256 public nextCountId;

    function addToVault(uint256 amount) external onlyOwner {
        require(nextCountId < _minted, "Count is complete");

        uint256 max = nextCountId + amount < _minted ? nextCountId + amount : _minted;
        uint256 i;
        uint256 total = 0;
        for (i = nextCountId; i < max; ++i) {
            if (!_exists(i)) continue;
            total += rarity(i);
        }
        nextCountId = i;
        ITrashCan(feeVault).addPoints(total);
    }

    function totalRarityPoints() external view returns (uint256) {
        uint256 total;

        for (uint256 i = 0; i < _minted; ++i) {
            if (!_exists(i)) continue;
            total += rarity(i);
        }
        return total;
    }

    // First id of legendary
    uint256 public firstLegendaryId = 0;

    // Mint maxLegendaries number of legendaries and airdrop them to random NFT holders
    function mintLegendaries() external onlyOwner {
        require(firstLegendaryId == 0, "Legendaries already minted");

        // Get random seed
        uint256 legendarySeed = seed(0);

        firstLegendaryId = _minted;

        for (uint256 i = 0; i < maxLegendaries; ++i) {
            // Pick a random tokenId between 0 and last tokenId minted
            uint256 tokenId = uint256(keccak256(abi.encode(legendarySeed, keccak256("legendary"), i))) % _minted;
            // If token does not exist (burned), skip this legendary
            if (!_exists(tokenId)) continue;
            // Mint an NFT to the owner of that tokenId
            _mint(ownerOf(tokenId), 1);
        }
    }
}