// SPDX-License-Identifier: MIT


pragma solidity ^0.8.12;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/Strings.sol';
import "./ERC721A.sol";
import "./interfaces/IBananaToken.sol";

contract TempleExploration is ReentrancyGuard {
    function explore(uint256 _bananaQuantity) external nonReentrant {} 

    function worship(uint256 _tokenId, uint256 _bananaQuantity) external {}

    function gearUp(uint256 _bananaQuantity) external nonReentrant {}

    function expeditionLevel(address _address) public pure returns (uint256) {}
}

contract SpaceTravel is ReentrancyGuard {
    function chargeSpacecraft(uint256 _bananaToken) external nonReentrant{}
}

contract OhoohHaHaah is Ownable, ERC721A {
    using Strings for uint256;
    
    TempleExploration templeAddress;
    SpaceTravel spaceTravelAddress;
    address public bananaToken = address(0);

    enum AdventurePhase {
        LANDING,
        BANANA_HARVEST,
        TEMPLE_EXPLORATION,
        SPACE_TRAVEL
    }

    bool public wlSaleActive;
    bool public publicSaleActive;
    bool public revealed;

    AdventurePhase public monkeAdventurePhase;

    string public monkeVoyagerBase;
    string public notRevealURI;

    uint256 public constant maxSupply = 6666; 
    
    uint256 public constant MAX_TEAM_RESERVE = 88;

    uint256 public MAX_WHITELIST = 222; 

    uint256 public maxPerWL = 1;

    uint256 public maxPerTxn = 10;
    uint256 public maxPerWallet = 20;


    uint256 public WL_SALES_PRICE = 0 ether;
    uint256 public PUBLIC_SALES_PRICE = 0.003 ether;


    address public teamAddress;
    bytes32 public whitelistMerkleRoot;

    uint256 public wlMinted;
    mapping(address => uint256) public wlMintClaimed;
 

    constructor(
        address _team,
        bytes32 _whitelistMerkleRoot,
        string memory _monkeVoyagerBase,
        string memory _notRevealURI
    ) ERC721A("Monke Voyager", "MonkeVoyager") {
        teamAddress = _team;
        whitelistMerkleRoot = _whitelistMerkleRoot;
        monkeVoyagerBase = _monkeVoyagerBase;
        notRevealURI = _notRevealURI;
    }

    modifier isWlSaleActive() {
        require(wlSaleActive, "WL Sale hasn't started yet.");
        _;
    }

    modifier isPublicSaleActive() {
        require(publicSaleActive, "Public Sale hasn't started yet.");
        _;
    }

    modifier validateWLAddress(
        bytes32[] calldata _merkleProof,
        bytes32 _merkleRoot
    ) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, _merkleRoot, leaf),
            "You are not a whitelisted Monke"
        );
        _;
    }

    modifier validateSupply(uint256 _maxSupply, uint256 _quantity) {
        require(
            _totalMinted() + _quantity <= _maxSupply,
            "The current stage has all its Monke Voyagers out!"
        );
        _;
    }

    modifier validateMintPerWallet(uint256 _quantity) {
        require(_quantity <= maxPerTxn, "Too many Monkes in one transaction!");
        require(_numberMinted(msg.sender) - wlMintClaimed[msg.sender] + _quantity <= maxPerWallet, "You are recuiting too many Monke Voyagers my friend");
        _;
    }

    modifier validateWLStatus(uint256 _quantity) {
        require(wlMintClaimed[msg.sender] + _quantity <= maxPerWL, "Ah aah, no more WL Monkes for u");
        require(_numberMinted(msg.sender) - wlMintClaimed[msg.sender] + _quantity <= maxPerWallet, "You are recuiting too many Monke Voyagers my friend");
        _;
    }

    modifier atPhase(AdventurePhase phase) {
        require(monkeAdventurePhase == phase, "Galaxy map not initialize. Hold tight for the next chapter!");
        _;
    }

    /*==============================================================
    ==          Functions for LANDING (Minting) Phase             ==
    ==============================================================*/

    /**

    /**
     * @notice Welcome to the world of Monke Voyager, Whitelist holders. 1WL = 2 Monkes. Enjoy the ride!
     */
    function WLMint(uint256 _quantity, bytes32[] calldata _proof)
        external
        isWlSaleActive
        validateWLStatus(_quantity)
        validateSupply(MAX_WHITELIST, _quantity)
        validateSupply(maxSupply, _quantity)
        validateWLAddress(_proof, whitelistMerkleRoot)
        payable
    {
        require(msg.value >= WL_SALES_PRICE * _quantity, "Need to send more ETH.");
        wlMintClaimed[msg.sender] += _quantity;
        wlMinted += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    /**
     * @notice Welcome to the world of Monke Voyager! Oh Ooh Ah Aah Aaah!
     */
    function PublicMint(uint256 _quantity)
        external
        payable
        isPublicSaleActive
        validateSupply(maxSupply - MAX_WHITELIST, _quantity)
        validateMintPerWallet(_quantity)
    {
        require(msg.value >= PUBLIC_SALES_PRICE * _quantity, "Need to send more ETH.");
        _safeMint(msg.sender, _quantity);
    }
    /**
     * @notice Crew members will also ride with ya, Monkes! Oh Ooh Ah Aah Aaah!
     */
    function CrewMonkeLanding(uint256 _quantity) 
        external 
        payable 
        validateSupply(maxSupply - MAX_WHITELIST, _quantity)
        onlyOwner 
    {
        _safeMint(teamAddress, _quantity);
    }

    /*=====================================================================
    ==              Functions for BANANA HARVEST Phase                   ==
    =====================================================================*/
    function InitBananaHarvest(address _bananaTokenAddress) 
    external 
    onlyOwner {
        monkeAdventurePhase = AdventurePhase.BANANA_HARVEST;
        bananaToken = _bananaTokenAddress;
    }

    /**
     * @dev override to add/remove banana harvest on transfers/burns
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId,
        uint256 _quantity
    ) internal override {
        /**  @dev Always set Banana Token Address first,
         *   Otherwise mint will fail
        */
        if (from != address(0)) {
            IBananaToken(bananaToken).stopHarvest(from, _quantity);
        }

        if (to != address(0)) {
            IBananaToken(bananaToken).startHarvest(to, _quantity);
        }
        
        super._beforeTokenTransfers(from, to, tokenId, _quantity);
    }

    /*=====================================================================
    ==              Functions for TEMPLE_EXPLORATION Phase               ==
    =====================================================================*/
    
    /// @notice Temple Exploration is about to begin! Oh Ooh Ah Aah Aaah!
    function InitTempleExploration(address _templeAddress) 
    external 
    onlyOwner {
        monkeAdventurePhase = AdventurePhase.TEMPLE_EXPLORATION;
        templeAddress = TempleExploration(_templeAddress);
    }

    /// @notice Yas, Explore, yaaas! Oh Ooh Ah Aah Aaah!
    function templeExplore(uint256 _bananaQuantity) external {
        templeAddress.explore(_bananaQuantity);
    }

    function relicWorship(uint256 _tokenId, uint256 _bananaQuantity) external {
        templeAddress.worship(_tokenId, _bananaQuantity);
    }

    function expeditionLevel(address _address) public view returns (uint256) {
       return templeAddress.expeditionLevel(_address);
    }

    /// @notice Trade relic fragments for gears
    function gearUp(uint256 _bananaQuantity) external {
        templeAddress.gearUp(_bananaQuantity);
    } 


    /*=====================================================================
    ==                  Functions for SPACE_TRAVEL Phase                 ==
    =====================================================================*/
    
    /// @notice Space travel is about to begin! Oh Ooh Ah Aah Aaah!
    function InitSpaceTravel(address _spaceTravelAddress) 
    external 
    onlyOwner {
        monkeAdventurePhase = AdventurePhase.SPACE_TRAVEL;
        spaceTravelAddress = SpaceTravel(_spaceTravelAddress);
    }

    function ChargeSpacecraft(uint256 _bananaToken) external {
        spaceTravelAddress.chargeSpacecraft(_bananaToken);
    }


    /*=====================================================================
    ==                        Generic Control Functions                  ==
    =====================================================================*/
    
    /**
     * @notice new chapters! Oh Ooh Ah Aah Aaah!
     */
    function setAdventurePhase(uint256 _phase) external onlyOwner {
        monkeAdventurePhase = AdventurePhase(_phase);
    }

    function withdrawFunds() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function withdrawFundsToAddress(address _address, uint256 amount) external onlyOwner {
        (bool success, ) =_address.call{value: amount}("");
        require(success, "Transfer failed.");
    }

    function airdropToHolders(address[] calldata holderAddresses, uint256 _quantities) external onlyOwner{
        for (uint i = 0; i < holderAddresses.length; i++) {
            _safeMint(holderAddresses[i], _quantities);
        }
    }

    function setTeamAddress(address _team) external onlyOwner {
        teamAddress = _team;
    }

    function setMonkeVoyagerBase(string memory _monkeVoyagerBase) external onlyOwner {
        monkeVoyagerBase = _monkeVoyagerBase;
    }

    function setNotRevealURI(string memory _uri) external onlyOwner {
        notRevealURI = _uri;
    }

    function setWhitelistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        whitelistMerkleRoot = _merkleRoot;
    }

    function setWlSaleState(bool _state) external onlyOwner {
        wlSaleActive = _state;
    }

    function setPublicState(bool _state) external onlyOwner {
        publicSaleActive = _state;
    }

    function setRevealState(bool _state) external onlyOwner {
        revealed = _state;
    }

    function reduceWlSpots(uint256 _WlSpots) external onlyOwner {
        require(_WlSpots > wlMinted, 'New WL spot should be more than the current minted WL spot.');
        MAX_WHITELIST = _WlSpots;
    }

    function setMaxTxn(uint256 _quantity) external onlyOwner {
        maxPerTxn = _quantity;
    }

    function setWLNum(uint256 _quantity) external onlyOwner {
        maxPerWL = _quantity;
    }

    function setMaxWallet(uint256 _quantity) external onlyOwner {
        maxPerWallet = _quantity;
    }

    function setPublicPrice(uint256 newPrice) external onlyOwner {
        require(newPrice >= 0, "Token price must be greater than zero");
        PUBLIC_SALES_PRICE = newPrice;
    }

    function setWlPrice(uint256 newPrice) external onlyOwner {
        require(newPrice >= 0, "Token price must be greater than zero");
        WL_SALES_PRICE = newPrice;
    }

    /**
     * @dev override ERC721A _startTokenId()
     */
    function _startTokenId() 
        internal 
        view 
        virtual
        override 
        returns (uint256) {
        return 1;
    }
    /**
     * @dev override IERC721Metadata
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {

         require(_exists(_tokenId), "URI query for unclaimed Monke Voyager");

        if (!revealed) {
            return string(notRevealURI);
        }
        return string(abi.encodePacked(monkeVoyagerBase, _tokenId.toString(), ".json"));
    }

}