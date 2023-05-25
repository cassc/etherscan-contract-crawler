// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract ShibaArmy is ERC721, Ownable {
    using Strings for uint256;

    enum saleTypes {WHITELIST, PRESALE, PUBLICSALE}

    struct saleConfig {
        uint256 price;
        uint256 maxAvailable;
        uint256 maxPerWallet;
        uint256 maxPerDogeArmy;
        saleTypes saleType;
    }

    saleConfig private publicSale = saleConfig(
        .25 ether,
        10000,
        10000,
        10000,
        saleTypes.PUBLICSALE
    );

    saleConfig private preSale = saleConfig(
        .2 ether,
        10000,
        10000,
        1,
        saleTypes.PRESALE
    );
    
    saleConfig private whitelistSale = saleConfig(
        .15 ether,
        2000,
        10,
        1,
        saleTypes.WHITELIST
    );

    IERC721 immutable private DOGE_ARMY;

    uint256 constant public MAX_SHIBA = 10000;
    
    uint256 public totalSupply;

    bool public isURIFrozen;
    bool public revealed;

    mapping(uint256 => bool) public isDogeArmyMintClaimed; // presale
    mapping(address => uint256) public numDogeArmyHolderMintClaimed; // whitelist

    uint256[] public provenanceIds;
    
    string public unrevealedURI = "ipfs://QmRYAGJoQ55vykWG4uGVJUt5jCddUP3p2zChs3KXnsNQrM";
    string public baseURI;

    event DogeArmyMintClaimed(uint256 id);
    event totalDogeArmyHolderMinted(address holder, uint256 numMinted);

    constructor(ERC721 _dogeArmy) ERC721("ShibaArmy", "SA") {
        DOGE_ARMY = _dogeArmy;
    }

    uint256 public tokensSold;
    uint256 public launchTime;

    bool public saleActive;
    bool public publicSaleStarted;

    event saleLaunched(uint256 launchTime);

    function mint(uint256 numTokensToMint, uint256[] calldata dogeArmyClaimIDs) external payable {
        // check that sale is active
        require(saleActive);
        require(!isSalePaused, "Sale has been paused by owner");

        // determine what sale type we are currently in
        saleConfig memory config = getSaleConfig();

        require(config.maxAvailable >= tokensSold + numTokensToMint, "Not enough available tokens to mint");
        require(MAX_SHIBA >= tokensSold + numTokensToMint, "Not enough available tokens to mint");
        
        if(config.maxPerWallet != MAX_SHIBA) {
            require(config.maxPerWallet >= numDogeArmyHolderMintClaimed[msg.sender] + numTokensToMint, "Wallet has already claimed maximum mints");
            numDogeArmyHolderMintClaimed[msg.sender] += numTokensToMint;
            emit totalDogeArmyHolderMinted(msg.sender, numDogeArmyHolderMintClaimed[msg.sender]);
        }

        bool isDogeArmyMatch = false;

        if(config.maxPerDogeArmy != MAX_SHIBA){
            isDogeArmyMatch = true;
            require(dogeArmyClaimIDs.length == numTokensToMint);
        }
        
        for (uint256 i = 0; i < numTokensToMint; i++) {
            if(isDogeArmyMatch){
                require(!isDogeArmyMintClaimed[dogeArmyClaimIDs[i]], "DogeArmy Mint already claimed"); // has the Doge Army token already been used to claim a mint
                require(DOGE_ARMY.ownerOf(dogeArmyClaimIDs[i]) == msg.sender, "Caller not the owner of Doge Army Token");
                isDogeArmyMintClaimed[dogeArmyClaimIDs[i]] = true;
                emit DogeArmyMintClaimed(dogeArmyClaimIDs[i]);
            }
            _safeMint(msg.sender, ++totalSupply);
            tokensSold++;
        }
    }

    // returns the current sale config
    function getSaleConfig() public view returns (saleConfig memory currentConfig) {
        if(publicSaleStarted) {
            return publicSale;
        }

        uint256 daysSinceSaleStarted = (block.timestamp - launchTime)  / 60 / 60 / 24;

        if(daysSinceSaleStarted < 4){ // check for whitelist sale window
            // 500 per day of whitelist sale
            uint256 currentMaxAvailable = (daysSinceSaleStarted + 1) * 500;

            currentConfig = saleConfig(
                whitelistSale.price,
                currentMaxAvailable,
                whitelistSale.maxPerWallet,
                whitelistSale.maxPerDogeArmy,
                saleTypes.WHITELIST
            );

            return currentConfig;

        } else if (daysSinceSaleStarted < 7){ // check for presale window
            return preSale;
        }
    }

    // Owner functions

    function launchSale() external onlyOwner {
        require(!saleActive);
        launchTime = block.timestamp;
        saleActive = true;

        emit saleLaunched(launchTime);
    }

    function launchPublicSale() external onlyOwner {
        uint256 daysSinceSaleStarted = (block.timestamp - launchTime) % (1 days);
        require(saleActive);
        require(daysSinceSaleStarted > 7);
        publicSaleStarted = true;
    }

    bool isSalePaused = false;
    event salePauseToggled(bool isSalePaused);

    function toggleSalePaused() external onlyOwner {
        isSalePaused = !isSalePaused;
        emit salePauseToggled(isSalePaused);
    }

    function reserve(uint256 amount, address destination) external onlyOwner {
        require(amount > 0, "cannot mint 0");
        require(totalSupply + amount <= MAX_SHIBA, "Sold Out");

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(destination, ++totalSupply);
        }
    }

    function freezeURI() external onlyOwner {
        isURIFrozen = true;
        // emit PermanentURI(string ""_value"", uint256 indexed 0);
    }

    function withdraw() external onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function reveal() external onlyOwner {
        revealed = true;
    }

    function setUnrevealedURI(string calldata _unrevealedURI) external onlyOwner {
        unrevealedURI = _unrevealedURI;
    }

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        require(!isURIFrozen, "URI is Frozen");
        baseURI = _newBaseURI;
    }

    function addProvenance(uint256 id) external onlyOwner {
        provenanceIds.push(id);
    }

    // view/pure functions
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if(revealed == false) {
            return unrevealedURI;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString())) 
            : "";
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

}