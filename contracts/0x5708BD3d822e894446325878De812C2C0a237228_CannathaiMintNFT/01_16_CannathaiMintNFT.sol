// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";


contract CannathaiMintNFT is ERC721A, Ownable, ReentrancyGuard, AccessControl{
    using Counters for Counters.Counter;

    uint8 MAX_PRIVATESALE_MINTS = 2;
    uint16 MAX_MINTS = 2000;
    uint16 MAX_SUPPLY = 2000;
    uint256 public earlyPresaleCost = 0.17 ether;
    uint256 public presaleCost = 0.195 ether;
    uint256 public publicsaleCost = 0.22 ether;

    string public contractURI;
    string public baseURI;
    uint96 royaltyFeesInBips;
    address royaltyAddress;

    Counters.Counter private freeMintCounters;
    Counters.Counter private earlyPrivateSaleCounters;
    Counters.Counter private privateSaleCounters;
    Counters.Counter private publicSaleCounters;

    address payable _owner;
    bool private _paused;
    bool private _pausedPublicSale;
    bool private _pausedPrivateSale;
    bool private _pausedEarlyPrivateSale;
    bool private _pausedFreeMint;
    bool private _pausedBurn;

    string public baseExtension = ".json";

    bytes32 public constant NFT_ADMIN = keccak256("NFT_ADMIN");

    mapping(address => bool) public greenListed;

    address[] public greenListedArray;

    mapping(address => uint256) public greenListMintNumberByAddress;
    mapping(address => uint256) public freeMintNumberByAddress;

    constructor(
        address owner,
        uint96 _royaltyFeesInBips, 
        string memory _contractURI, 
        string memory _baseURIstring
    ) ERC721A("CannathaiMotherPlantMint", "CMP") {
        royaltyFeesInBips = _royaltyFeesInBips;
        royaltyAddress = owner;
        contractURI = _contractURI;
        baseURI = _baseURIstring;

        _owner = payable(owner);

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier whenNotPaused() {
        require(!_paused, "[CannathaiMintNFT.whenNotPaused] Paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "[CannathaiMintNFT.whenPaused] Not Paused");
        _;
    }

    modifier whenFreeMintNotPaused() {
        require(!_pausedFreeMint, "[CannathaiMintNFT.whenFreeMintNotPaused] Free Mint Paused");
        _;
    }

    modifier whenFreeMintPaused() {
        require(_pausedFreeMint, "[CannathaiMintNFT.whenFreeMintPaused] Free Mint Not Paused");
        _;
    }
    
    modifier whenPublicSaleNotPaused() {
        require(!_pausedPublicSale, "[CannathaiMintNFT.whenPublicSaleNotPaused] Public Sale Paused");
        _;
    }

    modifier whenPublicSalePaused() {
        require(_pausedPublicSale, "[CannathaiMintNFT.whenPublicSalePaused] Public Sale Not Paused");
        _;
    }

    modifier whenEarlyPrivateSaleNotPaused() {
        require(!_pausedEarlyPrivateSale, "[CannathaiMintNFT.whenEarlyPrivateSaleNotPaused] Early Private Sale Paused");
        _;
    }

    modifier whenEarlyPrivateSalePaused() {
        require(_pausedEarlyPrivateSale, "[CannathaiMintNFT.whenEarlyPrivateSalePaused] Early Private Sale Not Paused");
        _;
    }
    
    modifier whenPrivateSaleNotPaused() {
        require(!_pausedPrivateSale, "[CannathaiMintNFT.whenPrivateSaleNotPaused] Private Sale Paused");
        _;
    }

    modifier whenPrivateSalePaused() {
        require(_pausedPrivateSale, "[CannathaiMintNFT.whenPrivateSalePaused] Private Sale Not Paused");
        _;
    }

    modifier whenBurnNotPaused() {
        require(!_pausedBurn, "[CannathaiMintNFT.whenBurnNotPaused] Burn Paused");
        _;
    }

    modifier whenBurnPaused() {
        require(_pausedBurn, "[CannathaiMintNFT.whenPrivateSalePaused] Burn Not Paused");
        _;
    }

    function freeMint(uint256 quantity) external payable nonReentrant whenFreeMintNotPaused{
        require(quantity + _numberMinted(msg.sender) <= MAX_MINTS, "Exceeded the limit");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        require(freeMintNumberByAddress[msg.sender] - 1 >= 0, "Exceed Free Mint number for this address");
                
        freeMintCounters.increment();
        freeMintNumberByAddress[msg.sender] -= 1;

        _safeMint(msg.sender, quantity);
    }
    
    function mintEarlyPrivateSale(uint8 quantity) external payable nonReentrant whenEarlyPrivateSaleNotPaused{
        require(quantity + _numberMinted(msg.sender) <= MAX_MINTS, "Exceeded the limit");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        require(msg.value >= earlyPresaleCost * quantity, "User doesn't have enough money");
        require(quantity <= MAX_PRIVATESALE_MINTS, "Exceeded the Private Sale limit");
        require(greenListed[msg.sender] == true, "Address is not in greenlist");
        require(greenListMintNumberByAddress[msg.sender] - 1 >= 0, "Exceed GrennList Mint number for this address");
                
        _owner.transfer(earlyPresaleCost * quantity);
        earlyPrivateSaleCounters.increment();
        greenListMintNumberByAddress[msg.sender] -= 1;

        _safeMint(msg.sender, quantity);
    }
    
    function mintPrivateSale(uint8 quantity) external payable nonReentrant whenPrivateSaleNotPaused{
        require(quantity + _numberMinted(msg.sender) <= MAX_MINTS, "Exceeded the limit");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        require(msg.value >= presaleCost * quantity, "User doesn't have enough money");
        require(quantity <= MAX_PRIVATESALE_MINTS, "Exceeded the Private Sale limit");
        require(greenListed[msg.sender] == true, "Address is not in greenlist");
        require(greenListMintNumberByAddress[msg.sender] - 1 >= 0, "Exceed GrennList Mint number for this address");
                
        _owner.transfer(presaleCost * quantity);
        privateSaleCounters.increment();
        greenListMintNumberByAddress[msg.sender] -= 1;

        _safeMint(msg.sender, quantity);
    }

    function mintPublicSale(uint256 quantity) external payable nonReentrant whenPublicSaleNotPaused {
        require(quantity + _numberMinted(msg.sender) <= MAX_MINTS, "Exceeded the limit");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        require(msg.value >= publicsaleCost * quantity, "Don't have enough money for public sale");

        _owner.transfer(publicsaleCost * quantity);
        publicSaleCounters.increment();

        _safeMint(msg.sender, quantity);
    }

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips) public onlyOwner whenNotPaused{
        royaltyAddress = _receiver;
        royaltyFeesInBips = _royaltyFeesInBips;
    }

    function setContractURI(string calldata _contractURI) public onlyOwner whenNotPaused{
        contractURI = _contractURI;
    }

    function royaltyInfo(uint256 _salePrice)
        external
        view
        virtual
        returns (address, uint256)
    {
        return (royaltyAddress, calculateRoyalty(_salePrice));
    }

    function calculateRoyalty(uint256 _salePrice) view public whenNotPaused returns (uint256) {
        return (_salePrice / 10000) * royaltyFeesInBips;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
        _exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId), baseExtension))
            : "";
    }

    /**
     * @dev Set tokenURI of NFT's Metadata
     * @param _baseURIstring - token uri you want to set
     */
    function setBaseURI(string memory _baseURIstring) public onlyOwner whenNotPaused{
        baseURI = _baseURIstring;
    }

    /**
     * @dev Get baseTokenURI of Metadata
     * @return baseTokenURI value 
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    /**
     * @dev burn NFT of given token id
     * @param _tokenId - token id of specific NFT
     */
    function burnNFT(uint256 _tokenId) public whenBurnNotPaused{
        _burn(_tokenId);
    }

    function setPublicCost(uint256 _newCost) public onlyOwner whenPaused {
        publicsaleCost = _newCost;
    }

    function setPresaleCost(uint256 _newCost) public onlyOwner whenPaused {
        presaleCost = _newCost;
    }

    function setEarlyPresaleCost(uint256 _newCost) public onlyOwner whenPaused {
        earlyPresaleCost = _newCost;
    }

    function totalPublicSaleMint() public view returns (uint256) {
        return publicSaleCounters.current();
    }

    function totalPrivateSaleMint() public view returns (uint256) {
        return privateSaleCounters.current();
    }

    function totalEarlyPrivateSaleMint() public view returns (uint256) {
        return earlyPrivateSaleCounters.current();
    }

    function totalFreeMint() public view returns (uint256) {
        return freeMintCounters.current();
    }

    function totalMint() public view returns (uint256) {
        uint256 total_mint = freeMintCounters.current() + earlyPrivateSaleCounters.current() + privateSaleCounters.current() + publicSaleCounters.current();
        return total_mint ;
    }

    function pause() external onlyOwner whenNotPaused {
        _paused = true;
    }

    function unpause() external onlyOwner whenPaused {
        _paused = false;
    }

    function pausePublicSale() external onlyOwner whenPublicSaleNotPaused {
        _pausedPublicSale = true;
    }

    function unpausePublicSale() external onlyOwner whenPublicSalePaused {
        _pausedPublicSale = false;
    }

    function pausePrivateSale() external onlyOwner whenPrivateSaleNotPaused {
        _pausedPrivateSale = true;
    }

    function unpausePrivateSale() external onlyOwner whenPrivateSalePaused {
        _pausedPrivateSale = false;
    }

    function pauseEarlyPrivateSale() external onlyOwner whenEarlyPrivateSaleNotPaused {
        _pausedEarlyPrivateSale = true;
    }

    function unpauseEarlyPrivateSale() external onlyOwner whenEarlyPrivateSalePaused {
        _pausedEarlyPrivateSale = false;
    }

    function pauseFreeMint() external onlyOwner whenFreeMintNotPaused {
        _pausedFreeMint = true;
    }

    function unpauseFreeMint() external onlyOwner whenFreeMintPaused {
        _pausedFreeMint = false;
    }

    function pauseBurn() external onlyOwner whenBurnNotPaused {
        _pausedBurn = true;
    }

    function unpauseBurn() external onlyOwner whenBurnPaused {
        _pausedBurn = false;
    }

    function addGreenlistUser(address _user) public onlyOwner {
        greenListed[_user] = true;
        greenListedArray.push(_user);
    }

    function removeGreenlistUser(address _user) public onlyOwner {
        greenListed[_user] = false;
        removeGreenlist(_user);
    }

    function getGreenlistUser(address _user) public view returns (bool) {
        return greenListed[_user];
    }

    function addGreenListMintNumberByAddress(address _user, uint256 _number) public onlyOwner {
        greenListMintNumberByAddress[_user] = _number;
    }

    function addFreeMintNumberByAddress(address _user, uint256 _number) public onlyOwner {
        freeMintNumberByAddress[_user] = _number;
    }

    function removeGreenlist(address _user) private {
        uint256 index = findIndex(_user);
        greenListedArray[index] = greenListedArray[greenListedArray.length - 1];
        greenListedArray.pop();
    }

    function findIndex(address _user) private view returns (uint256){
        for (uint256 i; i < greenListedArray.length; i++) {
            if (greenListedArray[i] == _user) {
                return i;
            }
        }
        revert(
            "[CannathaiNFT.findIndex] Can't find the address"
        );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}