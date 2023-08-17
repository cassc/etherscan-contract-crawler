//██████╗ ███████╗ █████╗ ██╗  ██╗██╗   ██╗    ██████╗ ██╗██████╗ ██████╗ ███████╗
//██╔══██╗██╔════╝██╔══██╗██║ ██╔╝╚██╗ ██╔╝    ██╔══██╗██║██╔══██╗██╔══██╗██╔════╝
//██████╔╝█████╗  ███████║█████╔╝  ╚████╔╝     ██████╔╝██║██████╔╝██║  ██║███████╗
//██╔═══╝ ██╔══╝  ██╔══██║██╔═██╗   ╚██╔╝      ██╔══██╗██║██╔══██╗██║  ██║╚════██║
//██║     ███████╗██║  ██║██║  ██╗   ██║       ██████╔╝██║██║  ██║██████╔╝███████║
//╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝       ╚═════╝ ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝
                                                        
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract PeakyBirds is ERC721URIStorage, Ownable, ReentrancyGuard, IERC2981 {
    using Strings for uint256;

    string public baseURI = "ipfs://bafybeigausqbtbko3c4uiza4zkgazlvkitgaz4k2zoheocoozqaj5ycwxi/";
    uint256 public maxSupply = 4349;
    uint256 public currentSupply = 0;
    uint256 public maxMintedByOwner = 149;
    uint256 public mintedCountByOwner = 0;
    mapping(uint256 => address payable) public currentHolders;
    uint256[] public allTokenIds;
    mapping(address => bool) public whitelist;
    bool public mintingPausedForHolders = true;
    bool public mintingPausedForWhitelisted = true;
    bool public mintingPausedForOthers = true;

    uint256 public costForNonWhitelisted = 45000000000000000;
    uint256 public costForWhitelisted = 40000000000000000;
    uint256 public costForHolders = 30000000000000000;

    address public otherNFTContract; 
    uint256 public auctionReserve = 1826;
    address public auctionHouse;

    // Royalty percentage
    uint256 public constant royaltyPercentage = 750; // Represented in basis points (7.5%)

    // Mapping to store the creator's address for each token ID
    mapping(uint256 => address payable) public creators;

    event Minted(address indexed user, uint256 tokenId);
    event Whitelisted(address indexed user);
    event RemovedFromWhitelist(address indexed user);

    constructor(address _otherNFTContract) ERC721("PeakyBirds", "PB") {
        otherNFTContract = _otherNFTContract;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory baseURIForToken = _baseURI();
        return bytes(baseURIForToken).length > 0
            ? string(abi.encodePacked(baseURIForToken, tokenId.toString(), ".json"))
            : '';
    }

    function setAuctionHouse(address _auctionHouse) public onlyOwner {
        auctionHouse = _auctionHouse;
    }

    function getRequiredPayment(address user, uint256 numTokens) internal view returns (uint256) {
        if (whitelist[user]) {
            return costForWhitelisted * numTokens;
        } else if (IERC721(otherNFTContract).balanceOf(user) > 0) {
            return costForHolders * numTokens;
        } else {
            return costForNonWhitelisted * numTokens;
        }
    }
    
function safeMint(uint256 numberOfTokens) public payable nonReentrant {
    if (whitelist[msg.sender]) {
        require(!mintingPausedForWhitelisted, "Minting is currently paused for whitelisted users");
    } else if (IERC721(otherNFTContract).balanceOf(msg.sender) > 0) {
        require(!mintingPausedForHolders, "Minting is currently paused for holders of the other NFT");
    } else {
        require(!mintingPausedForOthers, "Minting is currently paused for others");
    }

    require(numberOfTokens > 0 && numberOfTokens <= 3, "You can mint between 1 and 3 tokens at a time.");
    require(currentSupply + numberOfTokens <= maxSupply, "Exceeds max supply");

    uint256 requiredPayment = getRequiredPayment(msg.sender, numberOfTokens);
    require(msg.value >= requiredPayment, "Insufficient Ether sent");

    for (uint256 i = 0; i < numberOfTokens; i++) {
        uint256 tokenId = randomTokenId();
        _safeMint(msg.sender, tokenId);
        currentSupply++;
        creators[tokenId] = payable(msg.sender); // Store the creator's address when minting
        emit Minted(msg.sender, tokenId);
    }

    // Refund excess ether
    uint256 excessAmount = msg.value - requiredPayment;
    if (excessAmount > 0) {
        payable(msg.sender).transfer(excessAmount);
    }
}

function randomTokenId() internal view returns (uint256) {
    uint256 tokenId;
    uint256 attempts = 0;
    do {
        tokenId = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, attempts, block.prevrandao))) % maxSupply;
        attempts++;
    } while (tokenExists(tokenId) && attempts < maxSupply - currentSupply);
    require(attempts < maxSupply - currentSupply, "Failed to generate a unique token ID");
    return tokenId;
}

function auctionMint(address to, uint256 tokenId) external {
    require(msg.sender == auctionHouse, "Only the auction house can call this function");
    _safeMint(to, tokenId);
    currentSupply = currentSupply + 1;
    allTokenIds.push(tokenId); // Add the token ID to the array
    // No need to store the winner's address here, it will be updated in the endAuction function
}

    
    function updateCurrentHolder(uint256 tokenId, address payable newHolder) external {
        require(msg.sender == auctionHouse, "Only the auction house can call this function");
        currentHolders[tokenId] = newHolder;
}


function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId,
    uint256 batchSize
) internal virtual override {
    super._beforeTokenTransfer(from, to, tokenId, batchSize);
    // Update the current holder's address when transferring
    currentHolders[tokenId] = payable(to);
}    
    // EIP-2981 compliant function to retrieve the royalty information for a token
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        uint256 royaltyBasisPoints = royaltyPercentage;
        return (currentHolders[tokenId], salePrice * royaltyBasisPoints / 10000);
    }

function setAuctionReserve(uint256 _auctionReserve) public onlyOwner {
    require(_auctionReserve <= maxSupply, "Auction reserve cannot exceed max supply");
    auctionReserve = _auctionReserve;
}


    function DevMint(address to, uint256 tokenId) public onlyOwner {
    require(
        mintedCountByOwner < maxMintedByOwner,
        "Max minted by owner reached"
    );

    _mint(to, tokenId);
    allTokenIds.push(tokenId); // Add the token ID to the array
    mintedCountByOwner = mintedCountByOwner + 1;

    // Update the current holder's address for the newly minted token
    currentHolders[tokenId] = payable(to);
}


    function toggleMintingPauseForHolders() public onlyOwner {
        mintingPausedForHolders = !mintingPausedForHolders;
    }

    function toggleMintingPauseForWhitelisted() public onlyOwner {
        mintingPausedForWhitelisted = !mintingPausedForWhitelisted;
    }

    function toggleMintingPauseForOthers() public onlyOwner {
        mintingPausedForOthers = !mintingPausedForOthers;
    }

    function burn(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        payable(msg.sender).transfer(balance);
    }

    function totalSupply() public view returns (uint256) {
        return currentSupply;
    }

    // Function to get all token holders
    function getAllTokenHolders() public view returns (address[] memory) {
        address[] memory holders = new address[](allTokenIds.length);
        for (uint256 i = 0; i < allTokenIds.length; i++) {
            holders[i] = currentHolders[allTokenIds[i]];
        }
        return holders;
    }

    function tokenExists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function addToWhitelist(address[] memory accounts) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            whitelist[accounts[i]] = true;
            emit Whitelisted(accounts[i]);
        }
    }

    function removeFromWhitelist(address[] memory accounts) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            whitelist[accounts[i]] = false;
            emit RemovedFromWhitelist(accounts[i]);
        }
    }

    function isWhitelisted(address account) public view returns (bool) {
        return whitelist[account];
    }
}