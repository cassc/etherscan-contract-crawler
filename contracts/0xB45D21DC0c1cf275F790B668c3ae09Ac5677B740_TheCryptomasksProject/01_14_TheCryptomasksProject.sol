// SPDX-License-Identifier: MIT

// The Cryptomasks Project
// author: sadat.eth

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract TheCryptomasksProject is ERC721, IERC2981, ReentrancyGuard, Ownable {
    using Strings for uint256;

    // Sale status
    bool private phase1 = false;
    bool private phase2 = false;
    bool private phase3 = false;
    bool public paused = true;

    // Sale configuration
    uint256 public priceCommon = 0.02 ether;
    uint256 public priceRare = 0.04 ether;
    uint256 public priceEpic = 0.06 ether;
    uint256 public priceLegendary = 0.12 ether;
    uint256 public priceMythic = 0.25 ether;
    uint256 public pricePublicSale = 0.03 ether;
    
    // Token allocation 
    uint256 public maxSupply = 555;
    uint256 private mythicCounter = 1;
    uint256 private legendaryCounter = 5;
    uint256 private epicCounter = 30;
    uint256 private rareCounter = 115;
    uint256 private commonCounter = 270;
    
    // Marketplace configuration
    string public baseURI = "ipfs://Qmbpnw4zHg3XvhPz2QyUuHPMWgxfT3SstQUv9Z1bEgmTS8/";
    string private collectionURI = "ipfs://QmQwYkbVj7TcamQa3NsuGvFVpEGTKWks8RPkSm19sEktVS/";
    address private proxyAddr = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    // Funds distribution
    address private projectWallet;
    address private royaltyReceiver;
    uint256 private royaltyPercentBps;
    
    // Sale records
    bytes32 private whitelist;
    uint256 private limit = 5;
    mapping(address => bool) public claimed;
    mapping(address => bool) public minted;
    mapping(address => uint256) public mints;
    mapping(address => bool) private partners;

    constructor() ERC721("TheCryptomasksProject", "MASK") {}

    // Custom functions public

    function claim(uint256 rank, bytes32[] calldata proof) public payable canMint() {
        require(phase1, "phase 1 not started");
        require(!claimed[msg.sender], "already claimed");
        require(_verify(_leaf(msg.sender, rank), proof), "invalid proof");
        uint256 tokenId = _getTokenId(rank);
        _mint(msg.sender, tokenId);
        _updateCounter(tokenId);
        claimed[msg.sender] = true;
    }

    function presaleMint(uint256 rank, bytes32[] calldata proof) public payable canMint() {
        require(phase2, "phase 2 not started");
        require(!minted[msg.sender], "already minted");
        require(_verify(_leaf(msg.sender, rank), proof), "invalid proof");
        uint256 tokenId = _getTokenId(rank);
        require(msg.value >= getPrice(tokenId), "funds n/a");
        _mint(msg.sender, tokenId);
        _updateCounter(tokenId);
        minted[msg.sender] = true;
    }

    function publicMint() public payable canMint() {
        require(phase3, "phase 3 not started");
        require(mints[msg.sender] < limit, "minted max");
        uint256 tokenId = _getTokenIdRandom();
        require(msg.value >= pricePublicSale, "funds n/a");
        _mint(msg.sender, tokenId);
        _updateCounter(tokenId);
        mints[msg.sender] += 1;

    }

    function getPrice(uint256 rank) public view returns (uint256 priceIs) {
        if (rank == 1) { return priceMythic; }
        if (rank == 2) { return priceLegendary; }
        if (rank == 3) { return priceEpic; }
        if (rank == 4) { return priceRare; }
        if (rank == 5) { return priceCommon; }
    }

    function getSaleStatus() public view returns (uint256 phaseIs) {
        if (phase1) { return 1; }
        if (phase2) { return 2; }
        if (phase3) { return 3; }
        else { return 0; }
    }

    // Custom functions internal

    modifier canMint() {
        require(tx.origin == msg.sender, "humans only");
        require(!paused, "contract paused");
        require(totalSupply() < maxSupply, "sold out");
        _;
    }

    function _getTokenId(uint256 rank) internal virtual returns (uint256 newToken) {
        require(0 < rank && rank < 6, "ranks are 1-5");
        if (rank == 1) {
            require(mythicCounter < 5, "supply n/a");
            return mythicCounter;
        }
        if (rank == 2) {
            require(legendaryCounter < 30, "supply n/a");
            return legendaryCounter;
        }
        if (rank == 3) {
            require(epicCounter < 115, "supply n/a");
            return epicCounter;
        }
        if (rank == 4) {
            require(rareCounter < 270, "supply n/a");
            return rareCounter;
        }
        if (rank == 5) {
            require(commonCounter < 555, "supply n/a");
            return commonCounter;
        }
    }

    function _random() internal view returns (uint256) {
        uint256 randomnumber = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            msg.sender,
            totalSupply()
            ))) % 5;
            randomnumber = randomnumber + 1;
        return randomnumber;
    }

    function _getTokenIdRandom() internal view returns (uint256 newToken) {
        uint256 luck = _random();

        if (luck == 5) {
            if (mythicCounter < 5) { return mythicCounter; }
            if (legendaryCounter < 30) { return legendaryCounter; }
            if (epicCounter < 115) { return epicCounter; }
            if (rareCounter < 270) { return rareCounter; }
            if (commonCounter < 555) { return commonCounter; }
        }
        else if (luck == 4) {
            if (legendaryCounter < 30) { return legendaryCounter; }
            if (epicCounter < 115) { return epicCounter; }
            if (rareCounter < 270) { return rareCounter; }
            if (commonCounter < 555) { return commonCounter; }
            if (mythicCounter < 5) { return mythicCounter; }
        }
        else if (luck == 3) {
            if (epicCounter < 115) { return epicCounter; }
            if (rareCounter < 270) { return rareCounter; }
            if (commonCounter < 555) { return commonCounter; }
            if (mythicCounter < 5) { return mythicCounter; }
            if (legendaryCounter < 30) { return legendaryCounter; }
        }
        else if (luck == 2) {
            if (rareCounter < 270) { return rareCounter; }
            if (epicCounter < 115) { return epicCounter; }
            if (legendaryCounter < 30) { return legendaryCounter; }
            if (mythicCounter < 5) { return mythicCounter; }
            if (commonCounter < 555) { return commonCounter; }
        }
        else if (luck == 1) {
            if (commonCounter < 555) { return commonCounter; }
            if (rareCounter < 270) { return rareCounter; }
            if (epicCounter < 115) { return epicCounter; }
            if (legendaryCounter < 30) { return legendaryCounter; }
            if (mythicCounter < 5) { return mythicCounter; }
        }
    }

    function _updateCounter(uint256 tokenId) internal virtual {
        if (0 < tokenId && tokenId < 5) { mythicCounter++; }
        if (4 < tokenId && tokenId < 30) { legendaryCounter++; }
        if (29 < tokenId && tokenId < 115) { epicCounter++; }
        if (114 < tokenId && tokenId < 270) { rareCounter++; }
        if (269 < tokenId && tokenId < 556) { commonCounter++; }
    }

    function _leaf(address account, uint256 rank) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, rank));
    }

    function _verify(bytes32 _leafNode, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProof.verify(proof, whitelist, _leafNode);
    }

    // Custom functions owner

    function airdropRandom(address[] memory _addresses) public payable onlyOwner canMint() {
        require(_addresses.length + totalSupply() < maxSupply, "supply n/a");
        for (uint256 i; i < _addresses.length; i++) {
            uint256 tokenId = _getTokenIdRandom();
            _mint(_addresses[i], tokenId);
            _updateCounter(tokenId);
        }
    }

    function airdrop(address[] memory _addresses, uint256 rank) public payable onlyOwner canMint() {
        require(0 < rank && rank < 6, "ranks are 1-5");
        if (rank == 1) {
            require(_addresses.length + mythicCounter < 5, "supply n/a");
            for (uint256 i; i < _addresses.length; i++) {
                _mint(_addresses[i], mythicCounter);
                mythicCounter++;
            }
        }
        if (rank == 2) {
            require(_addresses.length + legendaryCounter < 30, "supply n/a");
            for (uint256 i; i < _addresses.length; i++) {
                _mint(_addresses[i], legendaryCounter);
                legendaryCounter++;
            }
        }
        if (rank == 3) {
            require(_addresses.length + epicCounter < 115, "supply n/a");
            for (uint256 i; i < _addresses.length; i++) {
                _mint(_addresses[i], epicCounter);
                epicCounter++;
            }
        }
        if (rank == 4) {
            require(_addresses.length + rareCounter < 270, "supply n/a");
            for (uint256 i; i < _addresses.length; i++) {
                _mint(_addresses[i], rareCounter);
                rareCounter++;
            }
        }
        if (rank == 5) {
            require(_addresses.length + commonCounter < 555, "supply n/a");
            for (uint256 i; i < _addresses.length; i++) {
                _mint(_addresses[i], commonCounter);
                commonCounter++;
            }
        }
    }

    function giveaway(address wallet, uint256 rank) public payable onlyOwner canMint() {
        require(wallet != address(0), "invalid address");
        require(0 < rank && rank < 6, "ranks are 1-5");
        if (rank == 1) {
            require(mythicCounter < 5, "supply n/a");
            _mint(wallet, mythicCounter);
            mythicCounter++;
        }
        if (rank == 2) {
            require(legendaryCounter < 30, "supply n/a");
            _mint(wallet, legendaryCounter);
            legendaryCounter++;
        }
        if (rank == 3) {
            require(epicCounter < 115, "supply n/a");
            _mint(wallet, epicCounter);
            epicCounter++;
        }
        if (rank == 4) {
            require(rareCounter < 270, "supply n/a");
            _mint(wallet, rareCounter);
            rareCounter++;
        }
        if (rank == 5) {
            require(commonCounter < 555, "supply n/a");
            _mint(wallet, commonCounter);
            commonCounter++;
        }
    }

    function setWhitelist(bytes32 whitelistRoot) public onlyOwner {
        whitelist = whitelistRoot;
    }

    function setPresaleConfig(uint256 _common, uint256 _rare, uint256 _epic, uint256 _legend, uint256 _mythic) public onlyOwner {
        priceCommon = _common;
        priceRare = _rare;
        priceEpic = _epic;
        priceLegendary = _legend;
        priceMythic = _mythic;
    }

    function setPublicSaleConfig(uint256 _publicPrice, uint256 _limitPerWallet) public onlyOwner {
        pricePublicSale = _publicPrice;
        limit = _limitPerWallet;
    }

    function setCollectionURI(string memory _collectionURI) public onlyOwner {
        collectionURI = _collectionURI;
    }

    function setOpenseaProxy(address _proxyAddr) public onlyOwner {
        proxyAddr = _proxyAddr;
    }

    function setPartner(address _partnerAddr) public onlyOwner {
        partners[_partnerAddr] = !partners[_partnerAddr];
    }

    function setPaused() public onlyOwner {
        paused = !paused;
    }

    function startPhase1() public onlyOwner {
        phase1 = true;
        phase2 = false;
        phase3 = false;
    }

    function startPhase2() public onlyOwner {
        phase1 = false;
        phase2 = true;
        phase3 = false;
    }

    function startPhase3() public onlyOwner {
        phase1 = false;
        phase2 = false;
        phase3 = true;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setRoyalty(address _royaltyReceiver, uint256 _percentBPs) public onlyOwner {
        royaltyReceiver = _royaltyReceiver;
        royaltyPercentBps = _percentBPs;
    }

    function setProjectWallet(address _projectWallet) public onlyOwner {
        projectWallet = _projectWallet;
    }

    function withdrawETH() public onlyOwner nonReentrant {
        require(projectWallet != address(0), "no wallet found");
        (bool success, ) = payable(projectWallet).call{value: address(this).balance}("");
        require(success, "withdraw failed");
    }

    // Standard functions marketplaces

    function isApprovedForAll(address owner, address operator) public override view returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyAddr);
        if (address(proxyRegistry.proxies(owner)) == operator || partners[operator]) return true;
        return super.isApprovedForAll(owner, operator);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        require(_exists(_tokenId), "Cannot query non-existent token");
        return (royaltyReceiver, (_salePrice * royaltyPercentBps) / 10000);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return (interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId));
    }

    function contractURI() public view returns (string memory) {
        return collectionURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    function totalSupply() public view returns (uint256) {
        // Since our distribution is complex
        uint256 m = mythicCounter - 1;
        uint256 l = legendaryCounter - 5;
        uint256 e = epicCounter - 30;
        uint256 r = rareCounter - 115;
        uint256 c = commonCounter - 270;
        uint256 totalMinted = m + l + e + r + c;
        return totalMinted;
    }

    function walletOfOwner(address _address) public virtual view returns (uint256[] memory) {
        uint256 _balance = balanceOf(_address);
        uint256[] memory _tokens = new uint256[] (_balance);
        uint256 _index;
        uint256 _loop = totalSupply();
        for (uint256 i = 0; i < _loop; i++) {
            bool _exists = _exists(i);
            if (_exists) {
                if (ownerOf(i) == _address) { _tokens[_index] = i; _index++; }
            }
            else if (!_exists && _tokens[_balance -1] == 0) { _loop++; }
        }
        return _tokens;
    }
}

contract OwnableDelegateProxy { }

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}