// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../openzep/token/ERC721/ERC721.sol";
import "../openzep/token/ERC721/extensions/ERC721Enumerable.sol";
import "../openzep/token/ERC721/extensions/ERC721Burnable.sol";
import "../openzep/access/Ownable.sol";
import "../openzep/utils/math/SafeMath.sol";
import "../openzep/utils/Counters.sol";
import "../openzep/token/ERC721/extensions/ERC721Pausable.sol";


contract GreatGenesisGorillas is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable {


    address[] private teamWallets = [
        0x535a23852CD726000856CF370B42c9A6D37779A9,
        0x704c7dA8D117Ff5cf3C3268EeCaB6A80188B2AAc
    ];

    uint256[] private teamShares = [90,10];


    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    mapping(address => uint256) private whitelist;

    uint256 public MAX_ELEMENTS = 2000;
    uint256 public constant PRICE = 60 * 10**15;
    uint256 public constant MAX_BY_MINT = 5;
    string public GENESIS_PROVENANCE = "";
    string public baseTokenURI;
    // bool public canChangeSupply = true;
    bool public presaleOpen = false;
    bool public mainSaleOpen = false;
    uint256 private presaleMaxPerMint = 5;

    // Reserve 21 Gorillas for Team
    uint public gorillaReserveMax = 21;
    uint public preMintedGorillas = 0;

    event CreateGorillas(uint256 indexed id);

    constructor(string memory baseURI) ERC721("GreatGenesisGorillas", "GGG") {
        setBaseURI(baseURI); // use original sketch as baseURI egg
        pause(true); // contract starts paused
    }

    modifier saleIsOpen {
        require(_totalSupply() <= MAX_ELEMENTS, "Sale end");
        if (_msgSender() != owner()) {
            require(!paused(), "Pausable: paused");
        }
        _;
    }

    modifier onlyOwnerOrTeam() {
        require(
            teamWallets[0] == msg.sender || teamWallets[1] == msg.sender || owner() == msg.sender,
            "caller is neither Team Wallet nor Owner"
        );
        _;
    }

    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }

    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }

    function mint(address _to, uint256 _count) public payable saleIsOpen {
        require(mainSaleOpen, "Public sale hasn't started!");
        uint256 total = _totalSupply();
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(total <= MAX_ELEMENTS, "Sale end");
        require(_count <= MAX_BY_MINT, "Exceeds number");
        require(msg.value >= price(_count), "Value below price");

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to);
        }
    }

    function mintPresale(address _to, uint256 _count) public payable {
        require(presaleOpen);
        require(_count <= whitelist[msg.sender]);
        uint256 total = _totalSupply();
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(msg.value >= (_count * PRICE), "Value below price");

        for (uint256 i = 0; i < _count; i++) {
          _mintAnElement(_to);
        }

        whitelist[msg.sender] = whitelist[msg.sender] - _count;
    }

    // Minting by team
    function preMintGorilla(address[] memory recipients) external onlyOwnerOrTeam {

        uint256 totalRecipients = recipients.length;
        uint256 total = _totalSupply();

        require(total + totalRecipients <= MAX_ELEMENTS, "Max limit");

        require(
            totalRecipients > 0,
            "Number of recipients must be greater than 0"
        );

        require(
            preMintedGorillas + totalRecipients <= gorillaReserveMax,
            "Exceeds max pre-mint Gorillas"
        );

        for (uint256 i = 0; i < totalRecipients; i++) {
            address to = recipients[i];
            require(to != address(0), "receiver can not be empty address");
            _mintAnElement(to);
        }

        preMintedGorillas += totalRecipients;
    }

    function togglePresaleMint() public onlyOwner {
        presaleOpen = !presaleOpen;
    }

    function enableMainSale() public onlyOwner {
        mainSaleOpen = true;
    }

    // adds to whitelist with specified amounts
    function addToWhitelistAmounts(address[] memory _listToAdd, uint256[] memory _amountPerAddress) public onlyOwner {
        uint256 totalAddresses = _listToAdd.length;
        uint256 totalAmounts = _amountPerAddress.length;

        require(totalAddresses == totalAmounts, "Amounts of entered items do not match");

        for (uint256 i = 0; i < totalAddresses; i++) {
          whitelist[_listToAdd[i]] = _amountPerAddress[i];
        }
    }

    function saleIsActive() public view returns (bool) {
        if(paused()) {
            return false;
        } else {
            return true;
        }
    }

    function _mintAnElement(address _to) private {
        uint id = _totalSupply();
        _tokenIdTracker.increment();
        _safeMint(_to, id);
        emit CreateGorillas(id);
    }

    function price(uint256 _count) public pure returns (uint256) {
        return PRICE.mul(_count);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function getBaseURI() public view returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        GENESIS_PROVENANCE = provenanceHash;
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function pause(bool val) public onlyOwner {
        if (val == true) {
            _pause();
            return;
        }
        _unpause();
    }

    function withdrawAll() public payable onlyOwnerOrTeam {
        uint256 balance = address(this).balance;
        require(balance > 0);

        _widthdraw(teamWallets[0], balance.mul(teamShares[0]).div(100));
        _widthdraw(teamWallets[1], address(this).balance);
     }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function withdrawAllBackup() public payable onlyOwnerOrTeam {
        uint256 balance = address(this).balance;
        require(balance > 0);

        _withdrawBackup(teamWallets[0], balance.mul(teamShares[0]).div(100));
        _withdrawBackup(teamWallets[1], address(this).balance);
    }

    function _withdrawBackup(address _address, uint256 _amount) private {
        payable(_address).transfer(_amount);
    }


    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
}