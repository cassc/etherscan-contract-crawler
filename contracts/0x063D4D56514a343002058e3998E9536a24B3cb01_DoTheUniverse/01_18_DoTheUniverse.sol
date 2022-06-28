// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "[email protected]/contracts/ERC721A.sol";
import "[email protected]/contracts/extensions/ERC721ABurnable.sol";
import "[email protected]/contracts/extensions/ERC721AQueryable.sol";

contract DoTheUniverseSale is ERC721A("Do The Universe", "DTU"), Ownable, ERC721AQueryable, ERC721ABurnable, ERC2981 {
    uint256 public constant maxSupply = 7777;
    uint256 public reservedUniverses = 77;
    uint256 public maxUniversesPerWallet = 5;

    uint256 public freeUniverses = 2777;
    uint256 public freeMaxUniversesPerWallet = 2;
    uint256 public freeSaleActiveTime = type(uint256).max;

    uint256 public firstFreeMints = 2;

    uint256 public universePrice = 0.01 ether;
    uint256 public saleActiveTime = type(uint256).max;

    uint256 public firstFreeSaleActiveTime = type(uint256).max;

    string universeMetadataURI;

    constructor() {
        _mint(msg.sender, 1);
    }

    function buyUniversesPaid(uint256 _universesQty) external payable saleActive(saleActiveTime) callerIsUser mintLimit(_universesQty, maxUniversesPerWallet) priceAvailable(_universesQty) universesAvailable(_universesQty) {
        require(_totalMinted() >= freeUniverses, "Get universes for free");

        _mint(msg.sender, _universesQty);
    }

    function buyUniversesFirstFreeRestPaid(uint256 _universesQty) external payable saleActive(firstFreeSaleActiveTime) callerIsUser mintLimit(_universesQty, maxUniversesPerWallet) priceAvailableFirstNftFree(_universesQty) universesAvailable(_universesQty) {
        require(_totalMinted() >= freeUniverses, "Get universes for free");

        _mint(msg.sender, _universesQty);
    }

    function buyUniversesFree(uint256 _universesQty) external saleActive(freeSaleActiveTime) callerIsUser mintLimit(_universesQty, freeMaxUniversesPerWallet) universesAvailable(_universesQty) {
        require(_totalMinted() < freeUniverses, "Max free limit reached");

        _mint(msg.sender, _universesQty);
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setUniversePrice(uint256 _newPrice) external onlyOwner {
        universePrice = _newPrice;
    }

    function setFreeUniverses(uint256 _freeUniverses) external onlyOwner {
        freeUniverses = _freeUniverses;
    }

    function setFirstFreeMints(uint256 _firstFreeMints) external onlyOwner {
        firstFreeMints = _firstFreeMints;
    }

    function setReservedUniverses(uint256 _reservedUniverses) external onlyOwner {
        reservedUniverses = _reservedUniverses;
    }

    function setMaxUniversesPerWallet(uint256 _maxUniversesPerWallet, uint256 _freeMaxUniversesPerWallet) external onlyOwner {
        maxUniversesPerWallet = _maxUniversesPerWallet;
        freeMaxUniversesPerWallet = _freeMaxUniversesPerWallet;
    }

    function setSaleActiveTime(
        uint256 _saleActiveTime,
        uint256 _freeSaleActiveTime,
        uint256 _firstFreeSaleActiveTime
    ) external onlyOwner {
        saleActiveTime = _saleActiveTime;
        freeSaleActiveTime = _freeSaleActiveTime;
        firstFreeSaleActiveTime = _firstFreeSaleActiveTime;
    }

    function setUniverseMetadataURI(string memory _universeMetadataURI) external onlyOwner {
        universeMetadataURI = _universeMetadataURI;
    }

    function giftUniverses(address[] calldata _sendNftsTo, uint256 _universesQty) external onlyOwner universesAvailable(_sendNftsTo.length * _universesQty) {
        reservedUniverses -= _sendNftsTo.length * _universesQty;
        for (uint256 i = 0; i < _sendNftsTo.length; i++) _safeMint(_sendNftsTo[i], _universesQty);
    }

    function _baseURI() internal view override returns (string memory) {
        return universeMetadataURI;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is a sm");
        _;
    }

    modifier saleActive(uint256 _saleActiveTime) {
        require(block.timestamp > _saleActiveTime, "Please, come back when the sale goes live");
        _;
    }

    modifier mintLimit(uint256 _universesQty, uint256 _maxUniversesPerWallet) {
        require(_numberMinted(msg.sender) + _universesQty <= _maxUniversesPerWallet, "Max x wallet exceeded");
        _;
    }

    modifier universesAvailable(uint256 _universesQty) {
        require(_universesQty + totalSupply() + reservedUniverses <= maxSupply, "Sorry, we are sold out");
        _;
    }

    modifier priceAvailable(uint256 _universesQty) {
        require(msg.value == _universesQty * universePrice, "Please, send the exact amount of ETH");
        _;
    }

    function getPrice(uint256 _qty) public view returns (uint256 price) {
        uint256 totalPrice = _qty * universePrice;
        uint256 numberMinted = _numberMinted(msg.sender);
        uint256 discountQty = firstFreeMints > numberMinted ? firstFreeMints - numberMinted : 0;
        uint256 discount = discountQty * universePrice;
        price = totalPrice > discount ? totalPrice - discount : 0;
    }

    modifier priceAvailableFirstNftFree(uint256 _universesQty) {
        require(msg.value == getPrice(_universesQty), "Please, send the exact amount of ETH");
        _;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC165, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setRoyalty(address _receiver, uint96 _feeNumerator) public onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }
}

contract UniverseApprovesMarketplaces is DoTheUniverseSale {
    mapping(address => bool) private allowed;

    function autoApproveMarketplace(address _spender) public onlyOwner {
        allowed[_spender] = !allowed[_spender];
    }

    function isApprovedForAll(address _owner, address _operator) public view override(ERC721A, IERC721) returns (bool) {
        // Opensea, LooksRare, Rarible, X2y2, Any Other Marketplace

        if (_operator == OpenSea(0xa5409ec958C83C3f309868babACA7c86DCB077c1).proxies(_owner)) return true;
        else if (_operator == 0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e) return true;
        else if (_operator == 0x4feE7B061C97C9c496b01DbcE9CDb10c02f0a0Be) return true;
        else if (_operator == 0xF849de01B080aDC3A814FaBE1E2087475cF2E354) return true;
        else if (allowed[_operator]) return true;
        return super.isApprovedForAll(_owner, _operator);
    }
}

contract DoTheUniverseStaking is UniverseApprovesMarketplaces {
    mapping(address => bool) public canStake;

    function addToWhitelistForStaking(address _operator) external onlyOwner {
        canStake[_operator] = !canStake[_operator];
    }

    modifier onlyWhitelistedForStaking() {
        require(canStake[msg.sender], "This contract is not allowed to stake");
        _;
    }

    mapping(uint256 => bool) public staked;

    function _beforeTokenTransfers(
        address,
        address,
        uint256 startTokenId,
        uint256
    ) internal view override {
        require(!staked[startTokenId], "Please, unstake the NFT first");
    }

    function stakeUniverses(uint256[] calldata _tokenIds, bool _stake) external onlyWhitelistedForStaking {
        for (uint256 i = 0; i < _tokenIds.length; i++) staked[_tokenIds[i]] = _stake;
    }
}

interface OpenSea {
    function proxies(address) external view returns (address);
}

contract DoTheUniverse is DoTheUniverseStaking {}