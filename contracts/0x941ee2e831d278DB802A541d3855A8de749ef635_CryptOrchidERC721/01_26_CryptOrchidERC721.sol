// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6 <0.9.0;

import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/presets/ERC721PresetMinterPauserAutoId.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../Libraries/CurrentTime.sol";

contract CryptOrchidERC721 is ERC721PresetMinterPauserAutoId, Ownable, VRFConsumerBase, CurrentTime {
    using SafeMathChainlink for uint256;
    using Strings for string;
    using Counters for Counters.Counter;

    struct CryptOrchid {
        string species;
        uint256 plantedAt;
        uint256 waterLevel;
    }
    mapping(uint256 => CryptOrchid) public cryptorchids;

    enum Stage {Unsold, Seed, Flower, Dead}

    bool internal saleStarted = false;
    bool internal growingStarted = false;

    uint256 public constant MAX_CRYPTORCHIDS = 10000;
    uint256 public constant GROWTH_CYCLE = 604800; // 7 days
    uint256 public constant WATERING_WINDOW = 10800; // 3 hours
    uint256 internal constant MAX_TIMESTAMP = 2**256 - 1;
    string internal constant GRANUM_IPFS = "QmWd1mn7DuGyx9ByfNeqCsgdSUsJZ1cragitgaygsqDvEm";

    uint16[10] private limits = [0, 3074, 6074, 8074, 9074, 9574, 9824, 9924, 9974, 9999];
    string[10] private genum = [
        "shenzhenica orchidaceae",
        "phalaenopsis micholitzii",
        "guarianthe aurantiaca",
        "vanda coerulea",
        "cypripedium calceolus",
        "paphiopedilum vietnamense",
        "miltonia kayasimae",
        "platanthera azorica",
        "dendrophylax lindenii",
        "paphiopedilum rothschildianum"
    ];

    string[10] private speciesIPFSConstant = [
        "QmV7nsQgHNvwyRxbbhP59iH3grqSfq3g7joSPaS1JGRmJa/shenzhenica-orchidaceae.json",
        "QmV7nsQgHNvwyRxbbhP59iH3grqSfq3g7joSPaS1JGRmJa/phalaenopsis-micholitzii.json",
        "QmV7nsQgHNvwyRxbbhP59iH3grqSfq3g7joSPaS1JGRmJa/guarianthe-aurantiaca.json",
        "QmV7nsQgHNvwyRxbbhP59iH3grqSfq3g7joSPaS1JGRmJa/vanda-coerulea.json",
        "QmV7nsQgHNvwyRxbbhP59iH3grqSfq3g7joSPaS1JGRmJa/cypripedium-calceolus.json",
        "QmV7nsQgHNvwyRxbbhP59iH3grqSfq3g7joSPaS1JGRmJa/paphiopedilum-vietnamense.json",
        "QmV7nsQgHNvwyRxbbhP59iH3grqSfq3g7joSPaS1JGRmJa/miltonia-kayasimae.json",
        "QmV7nsQgHNvwyRxbbhP59iH3grqSfq3g7joSPaS1JGRmJa/platanthera-azorica.json",
        "QmV7nsQgHNvwyRxbbhP59iH3grqSfq3g7joSPaS1JGRmJa/dendrophylax-lindenii.json",
        "QmV7nsQgHNvwyRxbbhP59iH3grqSfq3g7joSPaS1JGRmJa/paphiopedilum-rothschildianum.json"
    ];

    string[10] private deadSpeciesIPFSConstant = [
        "QmU8MNznT6FD1v5XdnSeA6cEYqxpj7MgkECpot3aCERerX/shenzhenica-orchidaceae.json",
        "QmU8MNznT6FD1v5XdnSeA6cEYqxpj7MgkECpot3aCERerX/phalaenopsis-micholitzii.json",
        "QmU8MNznT6FD1v5XdnSeA6cEYqxpj7MgkECpot3aCERerX/guarianthe-aurantiaca.json",
        "QmU8MNznT6FD1v5XdnSeA6cEYqxpj7MgkECpot3aCERerX/vanda-coerulea.json",
        "QmU8MNznT6FD1v5XdnSeA6cEYqxpj7MgkECpot3aCERerX/cypripedium-calceolus.json",
        "QmU8MNznT6FD1v5XdnSeA6cEYqxpj7MgkECpot3aCERerX/paphiopedilum-vietnamense.json",
        "QmU8MNznT6FD1v5XdnSeA6cEYqxpj7MgkECpot3aCERerX/miltonia-kayasimae.json",
        "QmU8MNznT6FD1v5XdnSeA6cEYqxpj7MgkECpot3aCERerX/platanthera-azorica.json",
        "QmU8MNznT6FD1v5XdnSeA6cEYqxpj7MgkECpot3aCERerX/dendrophylax-lindenii.json",
        "QmU8MNznT6FD1v5XdnSeA6cEYqxpj7MgkECpot3aCERerX/paphiopedilum-rothschildianum.json"
    ];

    Counters.Counter private _tokenIds;

    bytes32 internal keyHash;
    uint256 internal vrfFee;
    uint256 public randomResult;
    address public VRFCoordinator;
    address public LinkToken;

    event RequestedRandomness(bytes32 requestId);
    event Planted(uint256 tokenId, string latinSpecies, uint256 timestamp, address tokenOwner);
    event Watered(uint256 tokenId, uint256 waterLevel);
    event Killed(uint256 tokenId);

    mapping(bytes32 => uint256) public requestToToken;
    mapping(bytes32 => string) private speciesIPFS;
    mapping(bytes32 => string) private deadSpeciesIPFS;

    constructor(
        address _VRFCoordinator,
        address _LinkToken,
        bytes32 _keyhash
    )
        public
        payable
        VRFConsumerBase(_VRFCoordinator, _LinkToken)
        ERC721PresetMinterPauserAutoId("CryptOrchids", "ORCHD", "ipfs://")
    {
        VRFCoordinator = _VRFCoordinator;
        LinkToken = _LinkToken;
        keyHash = _keyhash;
        vrfFee = 2000000000000000000; // 2 LINK

        for (uint256 index = 0; index < genum.length; index++) {
            speciesIPFS[keccak256(abi.encode(genum[index]))] = speciesIPFSConstant[index];
            deadSpeciesIPFS[keccak256(abi.encode(genum[index]))] = deadSpeciesIPFSConstant[index];
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        (string memory species, , , ) = getTokenMetadata(tokenId);

        if (growthStage(tokenId) == Stage.Seed) {
            return string(abi.encodePacked(baseURI(), GRANUM_IPFS));
        }

        if (growthStage(tokenId) == Stage.Flower) {
            return string(abi.encodePacked(baseURI(), speciesIPFS[keccak256(abi.encode(species))]));
        }

        return string(abi.encodePacked(baseURI(), deadSpeciesIPFS[keccak256(abi.encode(species))]));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(address(0) == to || alive(tokenId), "Dead CryptOrchids cannot be transferred");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function currentPrice() public view returns (uint256 price) {
        uint256 currentSupply = totalSupply();
        if (currentSupply >= 9900) {
            return 1000000000000000000; // 9900+: 1.00 ETH
        } else if (currentSupply >= 9500) {
            return 640000000000000000; // 9500-9500:  0.64 ETH
        } else if (currentSupply >= 7500) {
            return 320000000000000000; // 7500-9500:  0.32 ETH
        } else if (currentSupply >= 3500) {
            return 160000000000000000; // 3500-7500:  0.16 ETH
        } else if (currentSupply >= 1500) {
            return 80000000000000000; // 1500-3500:  0.08 ETH
        } else if (currentSupply >= 500) {
            return 60000000000000000; // 500-1500:   0.06 ETH
        } else {
            return 40000000000000000; // 0 - 500     0.04 ETH
        }
    }

    function startSale() public onlyOwner {
        saleStarted = true;
    }

    function startGrowing() public onlyOwner {
        growingStarted = true;
    }

    /**
     * @dev Withdraw ether from this contract (Callable by owner only)
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    receive() external payable {}

    function webMint(uint256 units) public payable {
        require(saleStarted, "The Nursery is closed");
        require(units <= MAX_CRYPTORCHIDS - totalSupply(), "Not enough bulbs left");
        require(totalSupply() < MAX_CRYPTORCHIDS, "Sale has already ended");
        require(units > 0 && units <= 20, "You can plant minimum 1, maximum 20 CryptOrchids");
        require(SafeMathChainlink.add(totalSupply(), units) <= MAX_CRYPTORCHIDS, "Exceeds MAX_CRYPTORCHIDS");
        require(msg.value >= SafeMathChainlink.mul(currentPrice(), units), "Ether value sent is below the price");

        for (uint256 i = 0; i < units; i++) {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            cryptorchids[newItemId] = CryptOrchid({species: "granum", plantedAt: MAX_TIMESTAMP, waterLevel: 0});
            _safeMint(msg.sender, newItemId);
        }
    }

    function germinate(uint256 tokenId, uint256 userProvidedSeed) public {
        require(growingStarted, "Germination starts 2021-04-12T16:00:00Z");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Only the Owner can germinate a CryptOrchid.");
        _requestRandom(tokenId, userProvidedSeed);
    }

    function _requestRandom(uint256 tokenId, uint256 userProvidedSeed) internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= vrfFee, "Not enough LINK - germination unavailable");
        requestId = requestRandomness(keyHash, vrfFee, userProvidedSeed);
        requestToToken[requestId] = tokenId;
        emit RequestedRandomness(requestId);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint256 tokenId = requestToToken[requestId];
        CryptOrchid storage orchid = cryptorchids[tokenId];
        string memory species = pickSpecies(SafeMathChainlink.mod(randomness, 10000));
        orchid.species = species;
        orchid.plantedAt = currentTime();
        address tokenOwner = ownerOf(tokenId);
        emit Planted(tokenId, species, currentTime(), tokenOwner);
    }

    function alive(uint256 tokenId) public view returns (bool) {
        return growthStage(tokenId) != Stage.Dead;
    }

    function flowering(uint256 tokenId) public view returns (bool) {
        return growthStage(tokenId) == Stage.Flower;
    }

    function growthStage(uint256 tokenId) public view returns (Stage) {
        CryptOrchid memory orchid = cryptorchids[tokenId];
        if (orchid.plantedAt == 0) return Stage.Unsold;
        if (orchid.plantedAt == MAX_TIMESTAMP) return Stage.Seed;
        uint256 currentWaterLevel = orchid.waterLevel;
        uint256 elapsed = currentTime() - orchid.plantedAt;
        uint256 fullCycles = SafeMathChainlink.div(uint256(elapsed), GROWTH_CYCLE);
        uint256 modulo = SafeMathChainlink.mod(elapsed, GROWTH_CYCLE);

        if (currentWaterLevel == fullCycles) {
            return Stage.Flower;
        }

        if (SafeMathChainlink.add(currentWaterLevel, 1) == fullCycles && modulo < WATERING_WINDOW) {
            return Stage.Flower;
        }

        return Stage.Dead;
    }

    function water(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Only the Owner can water a CryptOrchid.");

        if (!alive(tokenId)) {
            emit Killed(tokenId);
            return;
        }

        CryptOrchid storage orchid = cryptorchids[tokenId];

        uint256 wateringLevel = orchid.waterLevel;
        uint256 elapsed = currentTime() - orchid.plantedAt;
        uint256 fullCycles = SafeMathChainlink.div(uint256(elapsed), GROWTH_CYCLE);

        if (wateringLevel > fullCycles) {
            emit Killed(tokenId);
            return;
        }

        uint256 newWaterLevel = SafeMathChainlink.add(wateringLevel, 1);
        orchid.waterLevel = newWaterLevel;

        emit Watered(tokenId, newWaterLevel);
    }

    function compost(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Only the Owner can compost a CryptOrchid.");

        burn(tokenId);
    }

    function getTokenMetadata(uint256 tokenId)
        public
        view
        returns (
            string memory,
            uint256,
            uint256,
            Stage
        )
    {
        return (
            cryptorchids[tokenId].species,
            cryptorchids[tokenId].plantedAt,
            cryptorchids[tokenId].waterLevel,
            growthStage(tokenId)
        );
    }

    function heartbeat(uint256 tokenId) public {
        if (growthStage(tokenId) == Stage.Dead) {
            emit Killed(tokenId);
        }
    }

    /**
     * @notice Pick species for random number index
     * @param randomIndex uint256
     * @return species string
     */
    function pickSpecies(uint256 randomIndex) private view returns (string memory) {
        for (uint256 i = 0; i < 10; i++) {
            if (randomIndex <= limits[i]) {
                return genum[i];
            }
        }
    }
}