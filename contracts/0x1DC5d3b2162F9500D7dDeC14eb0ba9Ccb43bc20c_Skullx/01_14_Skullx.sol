// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// For readability purpose only. It could be replaced with ERC721
contract AeonsContract {
    function ownerOf(uint256 tokenId) public view virtual returns (address) {}
}

contract Skullx is ERC721Enumerable, Ownable, ReentrancyGuard {
    string public skullxProvenance;

    AeonsContract aeonsContract;

    uint256 public constant MAX_SKULLX = 10000;
    uint256 public constant SUMMON_LIMIT = 10;
    uint256 public constant SKULLX_BASE_PRICE = 0.08 ether;

    uint256 public publicSaleStartingPrice;
    uint256 public publicSaleDuration;
    uint256 public publicSaleStartTime;

    bool public publicSaleActive;
    bool public aeonsPreSaleActive;
    bool public originsFreeMintActive;

    uint256 public reservedLeft = 150;

    mapping(uint256 => bool) private aeonsUsedList;
    mapping(address => uint256) private originsListClaimAvailable;

    string public baseURI;

    address w0 = 0xF65b1bC72ffe0c8BcbC91da87abc53aC8Cf884FD;
    address w1 = 0x7057092E6fB32683c7aB292420fFFe11B9929a9b;
    address w2 = 0x74F963A0741BCc06112AFAb7B0863eA2Ce405e8C;
    address w3 = 0xE0D0c735A5779919363dB1DEEE102fa5536C93fE;

    constructor(
        string memory name,
        string memory symbol,
        string memory uri,
        address aeonsAddress)
    ERC721(name, symbol) {
        setBaseURI(uri);
        aeonsContract = AeonsContract(aeonsAddress);
        // Team
        _safeMint( w0, 1);
        _safeMint( w1, 2);
        _safeMint( w2, 3);
    }

    event PublicSaleStart(
        uint256 indexed saleDuration,
        uint256 indexed saleStartTime
    );
    event PublicSalePaused(
        uint256 indexed currentPrice,
        uint256 indexed timeElapsed
    );

    // ---------------------
    // PUBLIC SALE FUNCTIONS
    // ---------------------
    modifier whenPublicSaleActive() {
        require(publicSaleActive, "Public sale is not active");
        _;
    }

    function summon(uint256 numSkullx) external payable whenPublicSaleActive nonReentrant {
        uint256 supply = totalSupply();
        require(numSkullx <= SUMMON_LIMIT, 'Exceeds SUMMON_LIMIT');
        require(supply + numSkullx <= MAX_SKULLX - reservedLeft, 'Exceeds MAX_SKULLX');

        uint256 costToMint = getMintPrice() * numSkullx;
        require(costToMint <= msg.value, 'ETH amount is not sufficient');

        // Start index at 1
        for (uint256 i; i < numSkullx; i++) {
            _safeMint(msg.sender, supply + i + 1);
        }

        if (msg.value > costToMint) {
            Address.sendValue(payable(msg.sender), msg.value - costToMint);
        }
    }

    function startPublicSale(uint256 saleDuration, uint256 saleStartPrice)
    external
    onlyOwner
    {
        require(!publicSaleActive, "Public sale has already begun");
        publicSaleDuration = saleDuration;
        publicSaleStartingPrice = saleStartPrice;
        publicSaleStartTime = block.timestamp;
        publicSaleActive = true;
        emit PublicSaleStart(saleDuration, publicSaleStartTime);
    }

    function pausePublicSale() external onlyOwner whenPublicSaleActive {
        uint256 currentSalePrice = getMintPrice();
        publicSaleActive = false;
        emit PublicSalePaused(currentSalePrice, getElapsedSaleTime());
    }

    function getElapsedSaleTime() internal view returns (uint256) {
        return
        publicSaleStartTime > 0 ? block.timestamp - publicSaleStartTime : 0;
    }

    function getRemainingSaleTime() external view returns (uint256) {
        require(publicSaleStartTime > 0, "Public sale hasn't started yet");
        if (getElapsedSaleTime() >= publicSaleDuration) {
            return 0;
        }

        return (publicSaleStartTime + publicSaleDuration) - block.timestamp;
    }

    function getMintPrice() public view whenPublicSaleActive returns (uint256) {
        uint256 elapsed = getElapsedSaleTime();
        if (elapsed >= publicSaleDuration) {
            return SKULLX_BASE_PRICE;
        } else {
            uint256 currentPrice = ((publicSaleDuration - elapsed) *
            publicSaleStartingPrice) / publicSaleDuration;
            return
            currentPrice > SKULLX_BASE_PRICE
            ? currentPrice
            : SKULLX_BASE_PRICE;
        }
    }

    // -----------------------
    // AEONS PRESALE FUNCTIONS
    // -----------------------
    function isAeonPresaleUsed(uint256 aeonId) public view returns (bool) {
        require(aeonId < 2001 && aeonId > 0, "Invalid Aeon id");
        return aeonsUsedList[aeonId];
    }

    function aeonsPresaleSummon(uint256[] calldata aeonIds) external payable nonReentrant {
        uint256 supply = totalSupply();
        require(aeonsPreSaleActive, 'Presale not active');

        for (uint256 i = 0; i < aeonIds.length; i++) {
            require(aeonsContract.ownerOf(aeonIds[i]) == msg.sender, "Not the Aeon owner");
            require(aeonsUsedList[aeonIds[i]] == false, 'Aeon already used');
        }

        require(supply + aeonIds.length <= MAX_SKULLX - reservedLeft, 'Exceeds MAX_SKULLX');
        require(SKULLX_BASE_PRICE * aeonIds.length <= msg.value, 'ETH amount is not sufficient');

        for (uint256 i = 0; i < aeonIds.length; i++) {
            // Start index at 1
            aeonsUsedList[aeonIds[i]] = true;
            _safeMint(msg.sender, supply + i + 1);
        }
    }

    function toggleAeonsPresaleActive() external onlyOwner {
        aeonsPreSaleActive = !aeonsPreSaleActive;
    }

    // ----------------------------------
    // SKULLX ORIGINS FREE MINT FUNCTIONS
    // ----------------------------------
    function addToOriginsList(address[] calldata addresses, uint256[] calldata numOrigins) external onlyOwner {
        require(addresses.length == numOrigins.length, "Param arrays must be the same length");
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");

            originsListClaimAvailable[addresses[i]] = numOrigins[i];
        }
    }

    function removeFromOriginsList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");
            originsListClaimAvailable[addresses[i]] = 0;
        }
    }

    function getOriginsListClaimAvailable(address owner) external view returns (uint256){
        return originsListClaimAvailable[owner];
    }

    function originsFreeSummon(uint256 numSkullx) external payable nonReentrant {
        uint256 supply = totalSupply();
        require(originsFreeMintActive, 'Free summon phase for Skullx role is not active');
        require(originsListClaimAvailable[msg.sender] >= numSkullx, 'Exceeds free mints available');
        require(supply + numSkullx <= MAX_SKULLX - reservedLeft, 'Exceeds MAX_SKULLX');

        // Start index at 1
        for (uint256 i; i < numSkullx; i++) {
            originsListClaimAvailable[msg.sender]--;
            _safeMint(msg.sender, supply + i + 1);
        }
    }

    function toggleOriginsFreeMintActive() external onlyOwner {
        originsFreeMintActive = !originsFreeMintActive;
    }

    // ---------------
    // OTHER FUNCTIONS
    // ---------------
    function giveAway(address to, uint256 numSkullx) external onlyOwner() {
        require(numSkullx <= reservedLeft, "Exceeds reserved Skullx left");
        uint256 supply = totalSupply();

        // Start index at 1
        for (uint256 i; i < numSkullx; i++) {
            _safeMint(to, supply + i + 1);
        }

        reservedLeft -= numSkullx;
    }

    function setProvenanceHash(string memory provenanceHash) external onlyOwner {
        skullxProvenance = provenanceHash;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function withdrawAll() external payable onlyOwner {
        uint256 percent = address(this).balance / 100;
        require(payable(w0).send(percent * 52));
        require(payable(w1).send(percent * 32));
        require(payable(w2).send(percent * 11));
        require(payable(w3).send(percent * 5));
    }
}