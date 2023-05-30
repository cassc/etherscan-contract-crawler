// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████
██████████████████████████████▓╝╘███████████████████████████████
████████████████████████████▓▓    ▓█████████████████████████████
██████████████████████▓▀╙              ╙▀▓██████████████████████
███████████████████▀"     ,▄▄▄▄▄▄▄▄▄▄,     "▀███████████████████
████████████████▓╜    ▄█████████████████▓w    ╙█████████████████
██████████████▓┘   ╔███████████████████████▓╕   └███████████████
█████████████▓   ╓██▓╝``╙▓████████████▓╩```██▓,   ▀█████████████
████████████╝   ▄███▓     `▀████████▓"     ████▄   ▐████████████
███████████▓   ▓████▓   ╒    ▀███▓▀        █████▓   ▀███████████
██████████▓   ▐█████▓   ]▓▄    ╙╝    ▄▓[   █████▓L   ███████████
█████████▓╝   ██████▓   ]███▓,    ,▓██▓[   ██████▓   ╚██████████
███████Ü      ███████▓▓▓▓▓▓▓▓▓r   ▓▓▓▓▓▓▓▓▓██████▓      ║███████
████████▓▄╖   ██████▓                      ██████▓   ╓▄█████████
██████████▓   ▐██████▓&&&&&&&&    &&&&&&&&▄█████▓F   ███████████
███████████@   █████▓                      █████▓   ▐███████████
███████████▓L   █████▄╥▄▄▄▄▄╥╓    ▄▄▄▄▄▄▄▄▄████▓   ╔████████████
█████████████N   ▀████████████r   ███████████▓╝   ▄█████████████
██████████████▓    ▀██████████▓▄▄██████████▓╝   ,███████████████
████████████████▓,   "▀▓████████████████▓╝    ,▄████████████████
███████████████████▄      "╙▀▀▓▓▓▀▀▀╩"     ,▄███████████████████
██████████████████████▓▄µ              ╓▄███████████████████████
█████████████████████████████▓    ██████████████████████████████
██████████████████████████████▓,,███████████████████████████████
████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract MetaTravelers is ERC721Enumerable, ERC721Pausable, ERC721Burnable, VRFConsumerBase, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdTracker;
    string private _baseTokenURI;

    /**
     * @dev Minting variables
     */
    uint256 public constant PRICE = .09 ether;
    uint256 public constant MAX_QUANTITY = 3;
    uint256 public constant MAX_EA_QUANTITY = 5; // max quantity that each early adopter can mint
    uint256 public constant MAX_SUPPLY = 7777;
    uint256 public constant MAX_RESERVE = 33;
    uint256 public constant MAX_EARLY_ADOPTER = 2775;
    uint256 public constant MAX_PRESALE = 2997;
    uint256 public constant MAX_MINTPASS = 1332;
    
    mapping(address => bool) private _earlyAdopterList;
    mapping(address => bool) private _preSaleList;
    mapping(address => uint256) private _earlyAdopterPurchased;
    mapping(address => uint256) private _preSalePurchased;
    mapping(address => uint256) private _publicSalePurchased;
    mapping(address => uint256) private _mintPassQuantity;

    bool public isReserveComplete = false;
    bool public isEarlyAdopterSale = false;
    bool public isPreSale = false;
    bool public isMintPassSale = false;
    bool public isPublicSale = false;

    /**
     * @dev Provenance variables
     */
    string public provenanceHash;
    uint256 public startingIndex;
    
    /**
     * @dev Chainlink VRF variables
     */
    bytes32 internal _keyHash;
    uint256 internal _fee;

    /**
     * @dev Initializes the contract with the name, symbol, and baseTokenURI,
     * and pauses the contract by default
     */
    constructor (
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        address vrfCoordinator,
        address linkToken,
        bytes32 keyHash,
        uint256 fee
    )
    ERC721(name, symbol) 
    VRFConsumerBase(vrfCoordinator, linkToken)
    {
        _baseTokenURI = baseTokenURI;
        _keyHash = keyHash;
        _fee = fee;
        _pause();
    }

    event AssetsMinted(address owner, uint256 quantity);
    event RequestedRandomness(bytes32 requestId);
    event StartingIndexSet(bytes32 requestId, uint256 randomNumber);

    /**
     * @dev Update the base token URI for returning metadata
     */
    function setBaseTokenURI(string memory baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    /**
     * @dev Add wallet addresses to the Early Adopter mappings used for private sale
     */
    function addToEarlyAdopterList(address[] calldata addresses) external onlyOwner {
        for(uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Cannot add null address");
            require(!_earlyAdopterList[addresses[i]], "Duplicate entry");
            _earlyAdopterList[addresses[i]] = true;
        }
    }

    /**
     * @dev Add wallet addresses to the PreSale mappings used for private sale
     */
    function addToPreSaleList(address[] calldata addresses) external onlyOwner {
        for(uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Cannot add null address");
            require(!_preSaleList[addresses[i]], "Duplicate entry");
            _preSaleList[addresses[i]] = true;
        }
    }

    /**
     * @dev Add wallet addresses to the Mint Pass mapping used for private sale
     */
    function addToMintPassList(address[] calldata addresses, uint256[] calldata quantities) external onlyOwner {
        require(addresses.length == quantities.length);
        for(uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Cannot add null address");
            _mintPassQuantity[addresses[i]] = quantities[i];
        }
    }

    /**
     * @dev Returns the quantity available for the message sender to mint during the mint pass sale
     */
    function getMintPassQuantity(address user) external view returns (uint256) {
        return _mintPassQuantity[user];
    }

    /**
     * @dev Toggle whether early adopter minting is enabled/disabled
     */
    function toggleEarlyAdopter() external onlyOwner {
        isEarlyAdopterSale = !isEarlyAdopterSale;
    }

    /**
     * @dev Toggle whether preSale minting is enabled/disabled
     */
    function togglePreSale() external onlyOwner {
        isPreSale = !isPreSale;
    }

    /**
     * @dev Toggle whether mint pass minting is enabled/disabled
     */
    function toggleMintPassSale() external onlyOwner {
        isMintPassSale = !isMintPassSale;
    }

    /**
     * @dev Toggle whether public sale minting is enabled/disabled
     */
    function togglePublicSale() external onlyOwner {
        isPublicSale = !isPublicSale;
    }

    /**
     * @dev Base minting function to be reused by other minting functions
     */
    function _baseMint(address to) private {
        _tokenIdTracker.increment();
        _mint(to, _tokenIdTracker.current());
    }

    /**
     * @dev Early Adopter sale restricted to a list of specified wallet address
     */
    function earlyAdopterMint(address to, uint256 quantity) external payable {
        require(isEarlyAdopterSale, 'Early Adopter sale is not live');
        require(_earlyAdopterList[_msgSender()], "User not on Early Adopter list");
        require(totalSupply() + quantity <= MAX_EARLY_ADOPTER, "Early Adopter sale is sold out");
        require(_earlyAdopterPurchased[_msgSender()] + quantity <= MAX_EA_QUANTITY, "Limit per wallet exceeded");
        require(msg.value == PRICE * quantity, "Ether value sent is not correct");
        
        for(uint256 i=0; i<quantity; i++){
            _earlyAdopterPurchased[_msgSender()]++;
            _baseMint(to);
        }
        emit AssetsMinted(to, quantity);
    }

    /**
     * @dev PreSale restricted to a list of specified wallet address
     */
    function preSaleMint(address to, uint256 quantity) external payable {
        require(isPreSale, 'PreSale is not live');
        require(_preSaleList[_msgSender()], "User not on PreSale list");
        require(totalSupply() + quantity <= MAX_EARLY_ADOPTER + MAX_PRESALE, "PreSale is sold out");
        require(_preSalePurchased[_msgSender()] + quantity <= MAX_QUANTITY, "Limit per wallet exceeded");
        require(msg.value == PRICE * quantity, "Ether value sent is not correct");
        
        for(uint256 i=0; i<quantity; i++){
            _preSalePurchased[_msgSender()]++;
            _baseMint(to);
        }
        emit AssetsMinted(to, quantity);
    }

    /**
     * @dev Mint pass sale based on snapshot of mint pass holders
     */
    function mintPassMint(address to, uint256 quantity) external payable {
        require(isMintPassSale, 'Mint pass sale is not live');
        require(_mintPassQuantity[_msgSender()] > 0, "User does not have valid mint pass");
        require(totalSupply() + quantity <= MAX_EARLY_ADOPTER + MAX_PRESALE + 
            MAX_MINTPASS, "Mint pass sale is sold out");
        require(msg.value == PRICE * quantity, "Ether value sent is not correct");
        
        for(uint256 i=0; i<quantity; i++){
            require(_mintPassQuantity[_msgSender()] > 0, "No mint pass mints left");
            _mintPassQuantity[_msgSender()]--;
            _baseMint(to);
        }
        emit AssetsMinted(to, quantity);
    }

    /**
     * @dev Creates a new token for `to`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     *
     * See {ERC721-_mint}.
     */
    function publicSaleMint(address to, uint256 quantity) external payable {
        require(isPublicSale, "Public sale is not live");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Purchase exceeds max supply");
        require(quantity <= MAX_QUANTITY, "Order exceeds max quantity");
        require(msg.value == PRICE * quantity, "Ether value sent is not correct");
        require(_publicSalePurchased[_msgSender()] + quantity <= MAX_QUANTITY, "Limit per wallet exceeded");
        
        for(uint256 i=0; i<quantity; i++){
            _publicSalePurchased[_msgSender()]++;
            _baseMint(to);
        }
        emit AssetsMinted(to, quantity);
    }

    /**
     * @dev Reserve MetaTravelers
     */
    function reserveMetaTravelers() external onlyOwner {
        require(!isReserveComplete, "MetaTravelers: Already reserved");
        for(uint256 i=0; i<MAX_RESERVE; i++){
            _baseMint(_msgSender());
        }
        isReserveComplete = true;
        emit AssetsMinted(_msgSender(), MAX_RESERVE);
    }

    /**
     * @dev Set the provenanceHash used for verifying fair and random distribution
     */
    function setProvenanceHash(string memory newProvenanceHash) external onlyOwner {
        provenanceHash = newProvenanceHash;
    }

    /**
     * @dev Set the startingIndex using Chainlink VRF for provable on-chain randomness
     * See callback function 'fulfillRandomness'
     */
    function setStartingIndex() external onlyOwner returns (bytes32) {
        bytes memory tempProvenanceHash = bytes(provenanceHash); 
        require(tempProvenanceHash.length > 0, "Need to set provenance hash");
        require(startingIndex == 0, "Starting index is already set");
        require(LINK.balanceOf(address(this)) >= _fee, "Not enough LINK");
        bytes32 requestId = requestRandomness(_keyHash, _fee);
        emit RequestedRandomness(requestId);
        return requestId;
    }

    /**
     * @dev Callback function used by VRF Coordinator.
     * Sets the startingIndex based on the random number generated by Chainlink VRF
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        startingIndex = randomness % MAX_SUPPLY;
        
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex += 1;
        }
        emit StartingIndexSet(requestId, randomness);
    }

    /**
     * @dev Used to withdraw funds from the contract
     */
    function withdraw() external onlyOwner() {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
    }
    
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token.");
        return bytes(_baseTokenURI).length > 0 ? string(abi.encodePacked(_baseTokenURI, tokenId.toString())) : "";
    }

    /**
     * @dev Used to pause contract minting per ERC721Pausable
     */
    function pause() external onlyOwner() {
        _pause();
    }

    /**
     * @dev Used to unpause contract minting per ERC721Pausable
     */
    function unpause() external onlyOwner() {
        _unpause();
    }
    
    /**
     * @dev Required due to inheritance
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }     

    /**
     * @dev Required due to inheritance
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }   
}