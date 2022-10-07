// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Traits is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    struct PlantZombie {
        bool isPlant;
        uint8 alphaIndex;
        uint128 mintAt;
    }

    mapping(address => bool) public controller;

    mapping(uint256 => uint256) public randomSeed;

    uint256 public maxRevealTokenId;

    // use Alias Algorithm to generate alpha score
    uint8[] private rarities;
    uint8[] private aliases;

    modifier onlyController() {
        require(controller[msg.sender], "Traits: only controller");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();

        rarities = [8, 160, 73, 255];
        aliases = [2, 3, 3, 3];
    }

    function fulfillRandomWords(uint256 _round, uint256 _seed)
        external
        onlyController
    {
        randomSeed[_round] = _seed;
        maxRevealTokenId = (_round + 1) * 1000 - 1;
    }

    function selectTraits(uint256 _seed)
        internal
        view
        returns (PlantZombie memory t)
    {
        t.isPlant = (_seed & 0xFFFF) % 10 != 0;
        _seed >>= 16;
        t.alphaIndex = selectTrait(uint16(_seed & 0xFFFF));
        t.mintAt = uint128(block.number);
        return t;
    }

    function selectTrait(uint16 salt) internal view returns (uint8) {
        uint8 trait = uint8(salt) % uint8(rarities.length);
        if (salt >> 8 < rarities[trait]) return trait;
        return aliases[trait];
    }

    function getTokenTraits(uint256 _tokenId)
        external
        view
        onlyController
        returns (PlantZombie memory)
    {
        uint256 salt = random(_tokenId, getRandomSeed(_tokenId));
        PlantZombie memory t = selectTraits(salt);
        return t;
    }

    function setController(address _controller, bool _isController)
        external
        onlyOwner
    {
        controller[_controller] = _isController;
    }

    function random(uint256 _tokenId, uint256 _seed)
        internal
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(_tokenId, _seed)));
    }

    function getRandomSeed(uint256 _tokenId) public view returns (uint256) {
        uint256 round = _tokenId / 1000;
        require(randomSeed[round] != 0, "Seed is not yet generated");
        return randomSeed[round];
    }

    function getRandom(uint256 _tokenId) external view returns (uint256) {
        require(controller[msg.sender], "You are not the controller");
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        _tokenId,
                        tx.origin,
                        blockhash(block.number - 1),
                        block.timestamp
                    )
                )
            );
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}