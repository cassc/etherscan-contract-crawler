// SPDX-License-Identifier: MIT

/**
    ___           _              _       _        ___              ___
   /   \_   _ ___| |_ ___  _ __ (_) __ _( )__    / _ \_ __ ___    / _ \__ _ _ __ ___   ___
  / /\ / | | / __| __/ _ \| '_ \| |/ _` |/ __|  / /_)/ '__/ _ \  / /_\/ _` | '_ ` _ \ / _ \
 / /_//| |_| \__ \ || (_) | |_) | | (_| |\__ \ / ___/| | |  __/ / /_\\ (_| | | | | | |  __/
/___,'  \__, |___/\__\___/| .__/|_|\__,_||___/ \/    |_|  \___| \____/\__,_|_| |_| |_|\___|
        |___/             |_|
*/


pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DystopiaPreGame is ERC721, Ownable {

    using Strings for uint;
    using Counters for Counters.Counter;

    // URI
    string public bronzeURI = "ipfs://QmbwBoMNMRqPR1JA3hFHzskFTNVYnPcXpTfNv1WLSQA8kC/";
    string public silverURI = "ipfs://QmeS3NqktReUxdL2CyHYM6rjcL5R4vnDiVXvnKvVPWJ51C/";
    string public goldURI = "ipfs://QmZMZEUuniwqgQcnTLCrLnV76iFjJ3DujQE3xsNA8mgKLj/";

    uint32 saleStartTime;

    // PRICE
    uint256 public BRONZE_PRICE = 0.25 ether;
    uint256 public SILVER_PRICE = 0.4 ether;
    uint256 public GOLD_PRICE = 0.5 ether;

    // SUPPLY
    uint256 public BRONZE_SUPPLY_MAX = 200;
    uint256 public SILVER_SUPPLY_MAX = 75;
    uint256 public GOLD_SUPPLY_MAX = 50;

    uint256 private totalMinted = 0;

    // Counters
    Counters.Counter private bronzeTokenId;
    Counters.Counter private silverTokenId;
    Counters.Counter private goldTokenId;

    bool public salePaused = false;

    constructor() ERC721("Dystopia's Pre Game", "DPG") { 
        // Set sale start time
        saleStartTime = 1702237032; //Sun Dec 10 2023 19:37:12 GMT+0000

        // Set start token ID for each supply
        for (uint256 i = 0; i < 200; i++) {
            silverTokenId.increment();
        }
        for (uint256 i = 0; i < 275; i++) {
            goldTokenId.increment();
        }
    }

    /**
    * @notice Override total supply
    *
    * @return total of NFT minted
    **/
    function totalSupply() public view virtual returns (uint256) {
        return totalMinted;
    }

    /**
    * @notice Return bronze total supply
    *
    * @return bronze total NFT minted
    **/
    function bronzeTotalSupply() public view virtual returns (uint256) {
        return bronzeTokenId.current();
    }

    /**
    * @notice Return silver total supply
    *
    * @return silver total NFT minted
    **/
    function silverTotalSupply() public view virtual returns (uint256) {
        return silverTokenId.current() - 200;
    }

    /**
    * @notice Return gold total supply
    *
    * @return silver gold NFT minted
    **/
    function goldTotalSupply() public view virtual returns (uint256) {
        return goldTokenId.current() - 275;
    }

    /**
    * @notice Mint by token ID
    *
    * @param _to: address who mint NFT
    * @param _tokenId: id of token minted
    **/
    function _mintId(address _to, uint256 _tokenId) private {
        require(!_exists(_tokenId), "Token already minted");
        _safeMint(_to, _tokenId);
        totalMinted += 1;
    }

    modifier mintCompliance() {
        require(!salePaused, "Mint paused");
        require(block.timestamp > saleStartTime, "Mint inactive");
        _;
    }

    /**
    * @notice Mint bronze NFT
    *
    * @param _mintAmount: number of token to mint
    **/
    function mintBronze(uint256 _mintAmount) external payable mintCompliance {
        require(bronzeTokenId.current() < BRONZE_SUPPLY_MAX, "Bronze sold out");
        require(bronzeTokenId.current() + _mintAmount <= BRONZE_SUPPLY_MAX, "Bronze supply exceeded");
        require(msg.value >= BRONZE_PRICE * _mintAmount, "Insufficient funds");

        for (uint256 i = 0; i < _mintAmount; i++) {
            bronzeTokenId.increment();
            _mintId(msg.sender, bronzeTokenId.current());
        }

    }

    /**
    * @notice Mint silver NFT
    *
    * @param _mintAmount: number of token to mint
    **/
    function mintSilver(uint256 _mintAmount) external payable mintCompliance {
        uint256 maxSupply = BRONZE_SUPPLY_MAX + SILVER_SUPPLY_MAX;

        require(silverTokenId.current() < maxSupply, "Silver sold out");
        require(silverTokenId.current() + _mintAmount <= maxSupply, "Silver supply exceeded");
        require(msg.value >= SILVER_PRICE * _mintAmount, "Insufficient funds");

        for (uint256 i = 0; i < _mintAmount; i++) {
            silverTokenId.increment();
            _mintId(msg.sender, silverTokenId.current());
        }

    }

    /**
    * @notice Mint gold NFT
    *
    * @param _mintAmount: number of token to mint
    **/
    function mintGold(uint256 _mintAmount) external payable mintCompliance {
        uint256 maxSupply = BRONZE_SUPPLY_MAX + SILVER_SUPPLY_MAX + GOLD_SUPPLY_MAX;

        require(goldTokenId.current() < maxSupply, "Gold sold out");
        require(goldTokenId.current() + _mintAmount <= maxSupply, "Gold supply exceeded");
        require(msg.value >= GOLD_PRICE * _mintAmount, "Insufficient funds");

        for (uint256 i = 0; i < _mintAmount; i++) {
            goldTokenId.increment();
            _mintId(msg.sender, goldTokenId.current());
        }

    }

    /**
    * @notice Airdrop NFT on one address
    *
    * @param _address: address to airdrop NFT
    * @param _type: type of supply airdropped (1 = bronze, 2 = silver, 3 = gold)
    * @param _mintAmount: number of token to mint
    **/
    function gift(address _address, uint256 _type, uint256 _mintAmount) public onlyOwner payable mintCompliance {
        // Gift bronze NFT
        if(_type == 1) {
            require(bronzeTokenId.current() < BRONZE_SUPPLY_MAX, "Bronze sold out");
            require(bronzeTokenId.current() + _mintAmount <= BRONZE_SUPPLY_MAX, "Bronze supply exceeded");
            require(msg.value >= BRONZE_PRICE * _mintAmount, "Insufficient funds");

            for (uint256 i = 0; i < _mintAmount; i++) {
                bronzeTokenId.increment();
                _mintId(_address, bronzeTokenId.current());
            }
        }
        // Gift silver NFT
        if(_type == 2) {
            uint256 maxSupply = BRONZE_SUPPLY_MAX + SILVER_SUPPLY_MAX;

            require(silverTokenId.current() < maxSupply, "Silver sold out");
            require(silverTokenId.current() + _mintAmount <= maxSupply, "Silver supply exceeded");
            require(msg.value >= SILVER_PRICE * _mintAmount, "Insufficient funds");

            for (uint256 i = 0; i < _mintAmount; i++) {
                silverTokenId.increment();
                _mintId(_address, silverTokenId.current());
            }
        }
        // Gift gold NFT
        if(_type == 3) {
            uint256 maxSupply = BRONZE_SUPPLY_MAX + SILVER_SUPPLY_MAX + GOLD_SUPPLY_MAX;

            require(goldTokenId.current() < maxSupply, "Gold sold out");
            require(goldTokenId.current() + _mintAmount <= maxSupply, "Gold supply exceeded");
            require(msg.value >= GOLD_PRICE * _mintAmount, "Insufficient funds");

            for (uint256 i = 0; i < _mintAmount; i++) {
                goldTokenId.increment();
                _mintId(_address, goldTokenId.current());
            }
        }
    }

    /**
    * @notice Update status of contract
    *
    * @param _state: state of pause
    **/
    function pauseSale(bool _state) public onlyOwner {
        salePaused = _state;
    }

    /**
    * @notice Update time of sales start
    *
    * @param startTime_: time of sales start
    **/
    function setSaleStartTime(uint32 startTime_) public onlyOwner {
        saleStartTime = startTime_;
    }

    /**
    * @notice Update bronze NFT price
    *
    * @param _BRONZE_PRICE: price of bronze NFT
    **/
    function setBronzePrice(uint256 _BRONZE_PRICE) public onlyOwner {
        BRONZE_PRICE = _BRONZE_PRICE;
    }

    /**
    * @notice Update silver NFT price
    *
    * @param _SILVER_PRICE: price of silver NFT
    **/
    function setSilverPrice(uint256 _SILVER_PRICE) public onlyOwner {
        SILVER_PRICE = _SILVER_PRICE;
    }

    /**
    * @notice Update gold NFT price
    *
    * @param _GOLD_PRICE: price of gold NFT
    **/
    function setGoldPrice(uint256 _GOLD_PRICE) public onlyOwner {
        GOLD_PRICE = _GOLD_PRICE;
    }

    /**
    * @notice Withdraw all funds of smart contract to contract owner
    **/
    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /// METADATA URI ///

    /**
    * @notice Update bronze NFT URI
    *
    * @param _newBronzeURI: bronze NFT URI
    **/
    function setBronzeURI(string memory _newBronzeURI) public onlyOwner {
        bronzeURI = _newBronzeURI;
    }

    /**
    * @notice Update silver NFT URI
    *
    * @param _newSilverURI: silver NFT URI
    **/
    function setSilverURI(string memory _newSilverURI) public onlyOwner {
        silverURI = _newSilverURI;
    }

    /**
    * @notice Update gold NFT URI
    *
    * @param _newGoldURI: gold NFT URI
    **/
    function setGoldURI(string memory _newGoldURI) public onlyOwner {
        goldURI = _newGoldURI;
    }

    /**
    * @notice Return token UI by token id
    *
    * @param _tokenId: token id
    **/
    function tokenURI(uint256  _tokenId) public view virtual override returns (string memory) {
        require(_tokenId != 0, "URI query for nonexistent token");
        if(_tokenId <= 200) return string(abi.encodePacked(bronzeURI, "bronze.json"));
        if(_tokenId <= 275) return string(abi.encodePacked(silverURI, "silver.json"));
        if(_tokenId <= 325) return string(abi.encodePacked(goldURI, "gold.json"));
        revert("URI query for nonexistent token");
    }

}