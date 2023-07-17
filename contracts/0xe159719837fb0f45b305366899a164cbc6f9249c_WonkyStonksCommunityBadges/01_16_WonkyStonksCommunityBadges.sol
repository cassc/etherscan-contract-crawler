// Solidity files have to start with this pragma.
// Version
pragma solidity >=0.4.22 <0.9.0;

// Import relevant libraries
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface IWonkyStonks {
    function balanceOf(address owner) external view returns (uint256 balance);
}

// Main definition of Wonky Stonks Community Badges (A LedgArt Community-driven Project) smart contract
contract WonkyStonksCommunityBadges is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string public baseTokenURI;

    uint256 public claimStartDate = 0;
    uint256 public claimEndDate = 1651600800;

    address private _wonkyStonksAddress = 0x518bA36F1ca6DfE3Bb1B098B8dD0444030e79D9f;

    mapping(address => uint256) public addressClaimed;
    mapping(uint256 => uint256) public badgeType;

    /**
     * Contract initialization.
     *
     * The `constructor` is executed only once when the contract is created.
     */
    constructor(string memory _baseTokenURI) ERC721("Wonky Stonks Community Badges", "WSCB") {
        baseTokenURI = _baseTokenURI;
    }
    
    /**
     * Override for ERC721 and ERC721URIStorage
     */
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    /**
     * Override for ERC721, ERC721Enumerable
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override (ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * Override for ERC721 and ERC271Enumerable
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * Override for ERC721URIStorage
     */
    function setBaseURI(string memory _newBaseTokenURI) public onlyOwner {
        baseTokenURI = _newBaseTokenURI;
    }

    /**
     * Override for ERC721URIStorage
     */
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * Override for ERC721 and ERC721URIStorage
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        string memory _uri = super.tokenURI(tokenId);

        if (bytes(_uri).length > 0) {
            if (badgeType[tokenId] > 9) {
                return string(abi.encodePacked(baseTokenURI, "3.json"));
            } else if (badgeType[tokenId] > 2) {
                return string(abi.encodePacked(baseTokenURI, "2.json"));
            } else if (badgeType[tokenId] > 0) {
                return string(abi.encodePacked(baseTokenURI, "1.json"));
            }
        }

        return _uri;
    }

    /**
     * Set the badge claim start date
     */
    function setClaimStartDate(uint256 startDate) public onlyOwner {
        claimStartDate = startDate;
    }
    
    /**
     * Set the badge claim end date
     */
    function setClaimEndDate(uint256 endDate) public onlyOwner {
        claimEndDate = endDate;
    }
    
    /**
     * Set the Wonky Stonks contract address
     */
    function setWonkyAddress(address wonkyStonksAddress) public onlyOwner {
        _wonkyStonksAddress = wonkyStonksAddress;
    }

    /**
     * Read-only function to retrieve the total number minted thus far
     */
    function getTotalMinted() external view returns (uint256) {
        return totalSupply();
    }

    /**
     * Read-only function to retrieve the current wallet Wonky Stonks balance
     */
    function wonkyStonksBalance() external view returns (uint256) {
        return IWonkyStonks(_wonkyStonksAddress).balanceOf(msg.sender);
    }

    /**
     * Read-only function to check claimability
     */
    function canClaim() public view returns (bool) {
        require(block.timestamp >= claimStartDate, "Claim is not open yet");
        require(block.timestamp <= claimEndDate, "Claim has ended");
        return (IWonkyStonks(_wonkyStonksAddress).balanceOf(msg.sender) > 0 && addressClaimed[msg.sender] == 0);
    }
    
    /**
     * Mint badge for address initiating mint
     * All mints are free (plus gas)
     */
    function mintBadge() public payable {
        require(block.timestamp >= claimStartDate, "Claim is not open yet");
        require(block.timestamp <= claimEndDate, "Claim has ended");
        require(addressClaimed[msg.sender] == 0, "Already claimed badge");

        uint256 stonksOwned = IWonkyStonks(_wonkyStonksAddress).balanceOf(msg.sender);

        require(stonksOwned > 0, "Must own more than 0 Wonky Stonks");

        uint256 itemId = _tokenIds.current();
        _safeMint(msg.sender, itemId);
        badgeType[itemId] = stonksOwned;
        _tokenIds.increment();
        addressClaimed[msg.sender] = stonksOwned;
    }

    /**
     * Allow contract owner to perform badge giveaways and reconciliation (some prefer to store Wonky Stonks in custodial wallets, etc)
     */
    function giveawayBadge(address toAddress, uint256 stonksOwned) public onlyOwner {
        require(stonksOwned > 0, "Must own more than 0 Wonky Stonks");
        
        uint256 itemId = _tokenIds.current();
        _safeMint(toAddress, itemId);
        badgeType[itemId] = stonksOwned;
        _tokenIds.increment();
        addressClaimed[toAddress] = stonksOwned;
    }

    /**
     * Allow the owner of the smart contract to withdraw the ether
     * Fees reimburse for creator and development costs, hosting expenses, and production of future features
     */
    function withdrawBalance() public onlyOwner {
        require(address(this).balance > 0, "Balance must be >0");
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success == true, "We failed to withdraw your ether");
    }
}