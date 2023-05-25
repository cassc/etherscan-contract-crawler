// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// ______          _          ______                                     _
// | ___ \        | |         |  _  \                                   | |
// | |_/ /_ _ _ __| |_ _   _  | | | |___  __ _  ___ _ __   ___ _ __ __ _| |_ ___  ___
// |  __/ _` | '__| __| | | | | | | / _ \/ _` |/ _ \ '_ \ / _ \ '__/ _` | __/ _ \/ __|
// | | | (_| | |  | |_| |_| | | |/ /  __/ (_| |  __/ | | |  __/ | | (_| | ||  __/\__ \
// \_|  \__,_|_|   \__|\__, | |___/ \___|\__, |\___|_| |_|\___|_|  \__,_|\__\___||___/
//                      __/ |             __/ |
//                     |___/             |___/

contract PartyDegenerates is ERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMath for uint16;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 public constant DEGENERATES_END_PRICE = 500000000000000000; //0.5 ETH
    uint16 public constant MAX_DEGENERATES_PER_TRANSACTION = 20;
    uint16 public constant MAX_DEGENERATES_TO_MINT = 10000;
    uint16 public constant NUM_RESERVED_NFTS = 200; //number of reserved NFTs for the team
    address RESERVE_VAULT_WALLET = 0x57Fd59f4F3095FEf355FbE65f60A1af89eC2Ead3; //send the reserved NFTs to this wallet before activating the public sale

    string public degeneratesProvenance;
    bool public provenanceLocked = false;
    //used to shift the token ids to the right by a random number of positions
    uint256 public indexRightShift;

    string private baseURI;

    // Public sale params
    uint256 public publicSaleDuration;
    uint256 public publicSaleStartTime;
    // Sale switch
    bool public publicSaleActive = false;

    // Public sale starting price - mutable, in case we need to pause and restart the sale
    uint256 public publicSaleDegenerateStartingPrice;

    //number of reserved NFTs minted
    uint256 public numReservedDegeneratesMinted;

    bool public locked = false;

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
    {}

    event PublicSaleStart(
        uint256 indexed _saleDuration,
        uint256 indexed _saleStartTime
    );

    event PublicSalePaused(
        uint256 indexed _currentPrice,
        uint256 indexed _timeElapsed
    );

    modifier notLocked() {
        require(!locked, "Contract methods are locked");
        _;
    }

    modifier notProvenanceLocked() {
        require(!provenanceLocked, "Provenance methods are locked");
        _;
    }

    modifier whenPublicSaleActive() {
        require(publicSaleActive, "Public sale is not active");
        _;
    }

    /*
    0	saleDuration	uint256	86400 sec = 24 hours
    1	saleStartPrice	uint256	2500000000000000000 wei = 2.5ETH
    */

    function startPublicSale(uint256 saleDuration, uint256 saleStartPrice)
        external
        onlyOwner
        notLocked
    {
        require(!publicSaleActive, "Public sale has already begun");
        publicSaleDuration = saleDuration;
        publicSaleDegenerateStartingPrice = saleStartPrice;
        publicSaleStartTime = block.timestamp;
        publicSaleActive = true;
        emit PublicSaleStart(saleDuration, publicSaleStartTime);
    }

    function lockContract() external onlyOwner notLocked {
        publicSaleActive = false;
        locked = true;
    }

    function pausePublicSale()
        external
        onlyOwner
        whenPublicSaleActive
        notLocked
    {
        uint256 currentSalePrice = getMintPrice();
        uint256 elapsedTime = getElapsedSaleTime();
        publicSaleStartTime = 0;
        publicSaleActive = false;
        emit PublicSalePaused(currentSalePrice, elapsedTime);
    }

    function getElapsedSaleTime() internal view returns (uint256) {
        return
            publicSaleStartTime > 0 ? block.timestamp - publicSaleStartTime : 0;
    }

    function getRemainingSaleTime() external view returns (uint256) {
        if (publicSaleStartTime == 0) {
            return 604800; //returns one week, this is the equivalent with publicSale has not started yet
        }
        if (getElapsedSaleTime() >= publicSaleDuration) {
            return 0;
        }

        return (publicSaleStartTime + publicSaleDuration) - block.timestamp;
    }

    function getMintPrice() public view returns (uint256) {
        if (!publicSaleActive) {
            return 0;
        }
        uint256 elapsed = getElapsedSaleTime();
        if (elapsed >= publicSaleDuration) {
            return DEGENERATES_END_PRICE;
        } else {
            int256 tempPrice = int256(publicSaleDegenerateStartingPrice) +
                ((int256(DEGENERATES_END_PRICE) -
                    int256(publicSaleDegenerateStartingPrice)) /
                    int256(publicSaleDuration)) *
                int256(elapsed);
            uint256 currentPrice = uint256(tempPrice);
            return
                currentPrice > DEGENERATES_END_PRICE
                    ? currentPrice
                    : DEGENERATES_END_PRICE;
        }
    }

    /* 
        Mints the reserved NFTs for partners, artists etc. 
    */
    function reserve(uint256 numDegeneratesToMint)
        public
        onlyOwner
        nonReentrant
        notLocked
    {
        require(
            numReservedDegeneratesMinted + numDegeneratesToMint <=
                NUM_RESERVED_NFTS,
            "Minting would exceed max supply of reserved NFTs"
        );
        require(numDegeneratesToMint > 0, "Must mint at least one degenerate");
        require(
            numDegeneratesToMint <= 50, //hardcoded to 50
            "Requested number exceeds maximum degenerates per transaction (50)"
        );

        for (uint256 i = 0; i < numDegeneratesToMint; i++) {
            if (_tokenIds.current() < MAX_DEGENERATES_TO_MINT) {
                _safeMint(RESERVE_VAULT_WALLET, _tokenIds.current());
                numReservedDegeneratesMinted = numReservedDegeneratesMinted + 1;
                _tokenIds.increment();
            }
        }
    }

    function _totalMinted() internal view returns (uint256) {
        return _tokenIds.current();
    }

    function getTotalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function mintDegenerates(uint256 numDegeneratesToMint)
        external
        payable
        whenPublicSaleActive
        nonReentrant
        notLocked
    {
        require(
            _tokenIds.current() + numDegeneratesToMint <=
                MAX_DEGENERATES_TO_MINT,
            "Minting would exceed max supply"
        );
        require(numDegeneratesToMint > 0, "Must mint at least one degenerate");
        require(
            numDegeneratesToMint <= MAX_DEGENERATES_PER_TRANSACTION,
            "Requested number exceeds maximum degenerates per transaction"
        );

        uint256 costToMint = getMintPrice() * numDegeneratesToMint;
        require(costToMint <= msg.value, "Ether value sent is not correct");

        for (uint256 i = 0; i < numDegeneratesToMint; i++) {
            if (_tokenIds.current() < MAX_DEGENERATES_TO_MINT) {
                _safeMint(msg.sender, _tokenIds.current());
                _tokenIds.increment();
            }
        }

        if (msg.value > costToMint) {
            Address.sendValue(payable(msg.sender), msg.value - costToMint);
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner notLocked {
        baseURI = uri;
    }

    function setProvenance(string memory provenance)
        external
        onlyOwner
        notLocked
        notProvenanceLocked
    {
        degeneratesProvenance = provenance;
        indexRightShift =
            random(degeneratesProvenance) %
            MAX_DEGENERATES_TO_MINT;
        //lock provenance
        provenanceLocked = true;
    }

    function random(string memory provenance) private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        provenance
                    )
                )
            );
    }
}