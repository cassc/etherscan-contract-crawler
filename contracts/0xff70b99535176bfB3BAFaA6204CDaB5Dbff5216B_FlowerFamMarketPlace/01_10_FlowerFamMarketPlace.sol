// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/IFlowerFam.sol";
import "./interfaces/IBee.sol";
import "./interfaces/IFlowerFamNewGen.sol";
import "./interfaces/IHoney.sol";
import "./interfaces/IFlowerFamRandomizer.sol";

contract IFlowerFamEcoSystem {
    function upgradeFlower(address user, uint256 flowerFamId) external {}
    function restorePowerOfBee(address user, uint256 flowerFamId, bool isFam, uint256 beeId, uint256 restorePeriods) external {}
    function speciesToHoneyProduction(uint256 species) external view returns (uint256) {}
}

contract FlowerFamMarketPlace is OwnableUpgradeable {
    IFlowerFam public flowerFamNFT;
    IBee public beeNFT;
    IFlowerFamNewGen public flowerFamNewGenNFT;
    IHoney public HoneyToken;

    IFlowerFamEcoSystem public ecoSystem;
    IFlowerFamRandomizer public randomizer;

    uint256 public beeProbability;
    uint256 public beeProbabilityBase;
    uint256 public newGenFlowerProbability;
    uint256 public newGenFlowerProbabilityBase;

    uint128 public beePrice;
    uint128 public seedPrice;

    uint256 public beeSupply;
    uint256 public newGenSupply;

    uint128 public upgradeDiscountFactor;

    constructor(
        address _flowerFamNFT,
        address _beeNFT,
        address _flowerFamNewGen,
        address _honeyToken,
        address _randomizer,
        address _ecoSystem
    ) {}

    function initialize(        
        address _flowerFamNFT,
        address _beeNFT,
        address _flowerFamNewGen,
        address _honeyToken,
        address _randomizer,
        address _ecoSystem
    ) public initializer {
        __Ownable_init();

        flowerFamNFT = IFlowerFam(_flowerFamNFT);
        beeNFT = IBee(_beeNFT);
        flowerFamNewGenNFT = IFlowerFamNewGen(_flowerFamNewGen);
        HoneyToken = IHoney(_honeyToken);
        ecoSystem = IFlowerFamEcoSystem(_ecoSystem);
        randomizer = IFlowerFamRandomizer(_randomizer);

        beeProbability = 50; /// @dev 50%
        beeProbabilityBase = 100; /// @dev bee probability is with base 100.
        newGenFlowerProbability = 80; /// @dev 80%
        newGenFlowerProbabilityBase = 100; /// @dev new gen flower probability is with base 100.

        beePrice = 1300 ether;
        seedPrice = 200 ether;

        beeSupply = 250;
        newGenSupply = 300;
    }

    receive() external payable {}

    function getUpgradePriceBySpecies(uint256 species) public view returns (uint128) {
        if (species == 0)
            return 536 ether / 10 / upgradeDiscountFactor;
        else if (species == 1)
            return 1071 ether / 10 / upgradeDiscountFactor;
        else if (species == 2)
            return 150 ether / upgradeDiscountFactor;
        else if (species == 3)
            return 4286 ether / 10 / upgradeDiscountFactor;
        else if (species == 4)
            return 750 ether / upgradeDiscountFactor;

        revert("invalid species");
    }

    function attractBee(uint256[] memory flowersWithBees) external {
        require(flowerFamNFT.balanceOf(msg.sender) + flowerFamNewGenNFT.balanceOf(msg.sender) > 0, "Cannot attract bee without any flowers");
        require(beeNFT.totalSupply() < beeSupply, "Bee supply exceeded");

        HoneyToken.spendEcoSystemBalance(msg.sender, beePrice, flowersWithBees, "");
        if (randomizer.rngDecision(msg.sender, beeProbability, beeProbabilityBase)) {
            beeNFT.mint(msg.sender, 1);
        }
    }

    function plantSeed(uint256[] memory flowersWithBees) external {        
        require(flowerFamNewGenNFT.totalSupply() < newGenSupply, "New gen supply exceeded");
        require(flowerFamNFT.balanceOf(msg.sender) > 0, "Cannot plantseed without any flowers");

        HoneyToken.spendEcoSystemBalance(msg.sender, seedPrice, flowersWithBees, "");
        if (randomizer.rngDecision(msg.sender, newGenFlowerProbability, newGenFlowerProbabilityBase)) {
            flowerFamNewGenNFT.mint(msg.sender, 1);
        }
    }

    function upgradeFlower(uint256 flowerId, uint256[] memory flowersWithBees) external {        
        uint256 species = randomizer.getSpeciesOfId(flowerId);
        uint128 upgradePrice = getUpgradePriceBySpecies(species);
        HoneyToken.spendEcoSystemBalance(msg.sender, upgradePrice, flowersWithBees, "");
        ecoSystem.upgradeFlower(msg.sender, flowerId);
    }

    function boostBee(uint256 flowerId, bool isFam, uint256 beeId, uint128 restoreAmount, uint256[] memory flowersWithBees) external {               
        uint256 species = randomizer.getSpeciesOfId(flowerId);
        /// @dev boost price is 3x lost per week, which is 15% of flower earnings
        uint128 boostPrice = uint128(ecoSystem.speciesToHoneyProduction(species) * 15 / 100) * restoreAmount;

        HoneyToken.spendEcoSystemBalance(msg.sender, boostPrice, flowersWithBees, "");
        ecoSystem.restorePowerOfBee(msg.sender, flowerId, isFam, beeId, restoreAmount);
    }

    function setEco(address eco) external onlyOwner {
        ecoSystem = IFlowerFamEcoSystem(eco);
    }

    function setRandomizer(address rmz) external onlyOwner {
        randomizer = IFlowerFamRandomizer(rmz);
    }

    function setBeeProbability(uint256 prob, uint256 base) external onlyOwner {
        beeProbability = prob;
        beeProbabilityBase = base;
    }

    function setNewGenProbability(uint256 prob, uint256 base) external onlyOwner {
        newGenFlowerProbability = prob;
        newGenFlowerProbabilityBase = base;
    }

    function setPrices(uint128 bee, uint128 seed) external onlyOwner {
        beePrice = bee;
        seedPrice = seed;
    }

    function setBeeSupply(uint256 newSupply) external onlyOwner {
        beeSupply = newSupply;
    }

    function setNewGenSupply(uint256 newSupply) external onlyOwner {
        newGenSupply = newSupply;
    }

    function setAddresses(address flowerfam, address newgen, address bee) external onlyOwner {
        flowerFamNFT = IFlowerFam(flowerfam);
        flowerFamNewGenNFT = IFlowerFamNewGen(newgen);
        beeNFT = IBee(bee);
    }

    function setUpgradeDiscountFactor(uint128 newDiscount) external onlyOwner {
        upgradeDiscountFactor = newDiscount;
    }
}