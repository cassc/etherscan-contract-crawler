pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DEVS is ERC721Enumerable, Ownable, ERC721Pausable, ERC721Burnable {

    using SafeMath for uint256;
    string public baseURI;
    address private devWallet = 0xF59EFc866Bb76EF4A9a5D509E0676DFB57726024;

    mapping(address => bool) presaleWhiteList;
    mapping(address => bool) collaboratorList;

    //Sale setup
    bool public sale;
    uint256 public tokenPrice = 0.06 ether;
    uint256 public maxSupply = 10000;
    uint256 public maxMintAmount = 10;

    //Presale setup
    bool public presale;
    uint256 public constant tokenPricePresale = 0.05 ether;

    //Collaborator setup
    bool public collaborator;
    uint256 public constant tokenPriceCollaborator = 0 ether;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    constructor(string memory _name, string memory _symbol, string memory _initBaseURI
    ) ERC721(_name, _symbol) {
        baseURI = _initBaseURI;
    }

    modifier isRunning() {
        require(!paused(), "Contract is paused");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function updateMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function updateBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return maxSupply;
    }

    function totalMint() public view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function updateMadWallet(address _address) public onlyOwner {
        devWallet = _address;
    }

    function mintPresale(address _to, uint256 _count, bool collaboratorActivate) public payable isRunning {
        uint256 currentTotal = totalMint();
        if (collaboratorActivate) {
            require(collaborator == true, "Collaborator has not yet started");
            require(collaboratorList[msg.sender], "You are not eligible for the Collaborator");
        } else {
            require(presale == true, "Pre-sale has not yet started");
            require(presaleWhiteList[msg.sender], "You are not eligible for the presale");
            require(msg.value >= tokenPricePresale * _count, "Insufficient amount sent");
        }
        require(
            currentTotal + _count <= maxSupply,
            "Pre-sale NFTs sold out"
        );
        for (uint256 i = 0; i < _count; i++) {
            _mintToken(_to);
        }
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function validateWhiteListOrCollaboratorList(address addresses, bool collaboratorActivate) public returns (bool){
        if (collaboratorActivate) {
            if (collaboratorList[addresses]) {
                return true;
            } else {
                return false;
            }
        } else {
            if (presaleWhiteList[addresses]) {
                return true;
            } else {
                return false;
            }
        }
    }

    function addToPresaleOrCollaborator(address[] calldata addresses, bool collaboratorActivate) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Cannot add null address");
            if (collaboratorActivate) {
                collaboratorList[addresses[i]] = true;
            } else {
                presaleWhiteList[addresses[i]] = true;
            }
        }
    }

    function startPresaleOrCollaborator(bool collaboratorActivate) public onlyOwner isRunning {
        if (collaboratorActivate) {
            require(!presale, "The presale is open, Unable to start sales to collaborators");
            require(!sale, "The sale is open, Unable to start sales to collaborators");
            collaborator = true;
        } else {
            require(!sale, "The sale is open, can't start Pre-sale anymore.");
            require(!collaborator, "The sale to collaborators is open, can't start Pre-sale anymore.");
            presale = true;
        }
    }

    function stopPresaleOrCollaborator(bool collaboratorActivate) public onlyOwner isRunning {
        if (collaboratorActivate) {
            collaborator = false;
        } else {
            presale = false;
        }
    }

    function startSale() public onlyOwner isRunning {
        require(!presale, "The Pre-sale is open, can't start the sale yet.");
        require(!collaborator, "The sale to collaborators is open, can't start the sale yet.");
        sale = true;
    }

    function pause(bool val) public onlyOwner {
        if (val == true) {
            _pause();
            return;
        }
        _unpause();
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _widthdraw(devWallet, balance);
    }

    function requirementsWidthdraw(bool success) private view {
        require(success, "Failed to widthdraw Ether");
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success,) = _address.call{value : _amount}("");
        requirementsWidthdraw(success);
    }

    function requirementsMint(uint256 currentTotal, uint256 _count) private view {
        require(sale == true, "Sale has not yet started");
        require(currentTotal + _count <= maxSupply, "NFTs sold out");
        require(_count <= maxMintAmount, "Exceeds max allowed mint limit");
        require(msg.value >= tokenPrice * _count, "Insufficient amount sent");
    }

    function mint(address _to, uint256 _count) public payable {
        uint256 currentTotal = totalMint();
        requirementsMint(currentTotal, _count);
        for (uint256 i = 0; i < _count; i++) {
            _mintToken(_to);
        }
    }

    function _mintToken(address _to) private {
        uint256 id = totalMint();
        _tokenIdTracker.increment();
        _safeMint(_to, id + 1);
    }


    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
    internal
    whenNotPaused
    override(ERC721, ERC721Enumerable, ERC721Pausable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function updateTokenPrice(uint256 _newCost) public onlyOwner {
        tokenPrice = _newCost;
    }

    function requirementsUpdateMaxMintAmount(uint256 _newMaxMintAmount) private view {
        require(_newMaxMintAmount >= 1, "Cannot use zero or minor");
    }

    function updateMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner {
        requirementsUpdateMaxMintAmount(_newMaxMintAmount);
        maxMintAmount = _newMaxMintAmount;
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}