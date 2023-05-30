//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 _   .-')       ('-.   .-') _      ('-.                         .-')      ('-.  _  .-')   
( '.( OO )_   _(  OO) (  OO) )    ( OO ).-.                    ( OO ).  _(  OO)( \( -O )  
 ,--.   ,--.)(,------./     '._   / . --. /       ,--. ,--.   (_)---\_)(,------.,------.  
 |   `.'   |  |  .---'|'--...__)  | \-.  \        |  | |  |   /    _ |  |  .---'|   /`. ' 
 |         |  |  |    '--.  .--'.-'-'  |  |       |  | | .-') \  :` `.  |  |    |  /  | | 
 |  |'.'|  | (|  '--.    |  |    \| |_.'  |       |  |_|( OO ) '..`''.)(|  '--. |  |_.' | 
 |  |   |  |  |  .--'    |  |     |  .-.  |       |  | | `-' /.-._)   \ |  .--' |  .  '.' 
 |  |   |  |  |  `---.   |  |     |  | |  |      ('  '-'(_.-' \       / |  `---.|  |\  \  
 `--'   `--'  `------'   `--'     `--' `--'        `-----'     `-----'  `------'`--' '--' 
       _ .-') _                    .-') _               ('-.                    .-') _    
      ( (  OO) )                  ( OO ) )            _(  OO)                  ( OO ) )   
       \     .'_  ,--. ,--.   ,--./ ,--,'  ,----.    (,------. .-'),-----. ,--./ ,--,'    
       ,`'--..._) |  | |  |   |   \ |  |\ '  .-./-')  |  .---'( OO'  .-.  '|   \ |  |\    
       |  |  \  ' |  | | .-') |    \|  | )|  |_( O- ) |  |    /   |  | |  ||    \|  | )   
       |  |   ' | |  |_|( OO )|  .     |/ |  | .--, \(|  '--. \_) |  |\|  ||  .     |/    
       |  |   / : |  | | `-' /|  |\    | (|  | '. (_/ |  .--'   \ |  | |  ||  |\    |     
       |  '--'  /('  '-'(_.-' |  | \   |  |  '--'  |  |  `---.   `'  '-'  '|  | \   |     
       `-------'   `-----'    `--'  `--'   `------'   `------'     `-----' `--'  `--'     
*/
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MetaUserDungeonCycleZero is ERC721, IERC2981, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private tokenCounter;

    string private baseURI;
    string public initialURI;
    address private openSeaProxyRegistryAddress;
    bool private isOpenSeaProxyActive = true;
    bool public isPublicSaleActive;

    uint256 public constant PUBLIC_SALE_PRICE = 0.06 ether;

    uint256 public maxDoors;
    uint256 public maxGiftedDoors;
    uint256 public numGiftedDoors;

    mapping(address => bool) public claimed;

    // ============ ACCESS CONTROL/SANITY MODIFIERS ============

    modifier publicSaleActive() {
        require(isPublicSaleActive, "Public sale is not open");
        _;
    }

    modifier canMintDoors(uint256 numberOfTokens) {
        require(
            tokenCounter.current() + numberOfTokens <=
                maxDoors - maxGiftedDoors,
            "Not enough doors remaining to mint"
        );
        _;
    }

    modifier canGiftDoors(uint256 num) {
        require(
            numGiftedDoors + num <= maxGiftedDoors,
            "Not enough doors remaining to gift"
        );
        require(
            tokenCounter.current() + num <= maxDoors,
            "Not enough doors remaining to mint"
        );
        _;
    }

    modifier isCorrectPayment(uint256 price, uint256 numberOfTokens) {
        require(
            price * numberOfTokens == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    constructor(
        address _openSeaProxyRegistryAddress,
        string memory _initialURI,
        uint256 _maxDoors,
        uint256 _maxGiftedDoors
    ) ERC721("Meta User Dungeon - Cycle Zero", "CYCLZERO") {
        openSeaProxyRegistryAddress = _openSeaProxyRegistryAddress;
        maxDoors = _maxDoors;
        maxGiftedDoors = _maxGiftedDoors;
        baseURI = _initialURI;
    }

    // ============ PUBLIC FUNCTIONS FOR MINTING ============

    function mint(uint256 numberOfTokens)
        external
        payable
        nonReentrant
        isCorrectPayment(PUBLIC_SALE_PRICE, numberOfTokens)
        publicSaleActive
        canMintDoors(numberOfTokens)
    {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, nextTokenId());
        }
    }

    // ============ PUBLIC READ-ONLY FUNCTIONS ============

    function getBaseURI() external view returns (string memory) {
        return baseURI;
    }

    function getLastTokenId() external view returns (uint256) {
        return tokenCounter.current();
    }

    // ============ OWNER-ONLY ADMIN FUNCTIONS ============

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    // function to disable gasless listings for security in case
    // opensea ever shuts down or is compromised
    function setIsOpenSeaProxyActive(bool _isOpenSeaProxyActive)
        external
        onlyOwner
    {
        isOpenSeaProxyActive = _isOpenSeaProxyActive;
    }

    function setIsPublicSaleActive(bool _isPublicSaleActive)
        external
        onlyOwner
    {
        isPublicSaleActive = _isPublicSaleActive;
    }

    function reserveForGifting(uint256 numToReserve)
        external
        nonReentrant
        onlyOwner
        canGiftDoors(numToReserve)
    {
        numGiftedDoors += numToReserve;

        for (uint256 i = 0; i < numToReserve; i++) {
            _safeMint(msg.sender, nextTokenId());
        }
    }

    function giftDoors(address[] calldata addresses)
        external
        nonReentrant
        onlyOwner
        canGiftDoors(addresses.length)
    {
        uint256 numToGift = addresses.length;
        numGiftedDoors += numToGift;

        for (uint256 i = 0; i < numToGift; i++) {
            _safeMint(addresses[i], nextTokenId());
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTokens(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    // ============ SUPPORTING FUNCTIONS ============

    function nextTokenId() private returns (uint256) {
        tokenCounter.increment();
        return tokenCounter.current();
    }

    // ============ FUNCTION OVERRIDES ============

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Override isApprovedForAll to allowlist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Get a reference to OpenSea's proxy registry contract by instantiating
        // the contract using the already existing address.
        ProxyRegistry proxyRegistry = ProxyRegistry(
            openSeaProxyRegistryAddress
        );
        if (
            isOpenSeaProxyActive &&
            address(proxyRegistry.proxies(owner)) == operator
        ) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");
        
        return string(abi.encodePacked(baseURI, "/", tokenId.toString(), ".json"));
        
    }

    /**
     * @dev See {IERC165-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");

        return (address(this), SafeMath.div(SafeMath.mul(salePrice, 5), 100));
    }
}

// These contract definitions are used to create a reference to the OpenSea
// ProxyRegistry contract by using the registry's address (see isApprovedForAll).
contract OwnableDelegateProxy {

}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}