// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "[email protected]/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "[email protected]/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface OpenSea {
    function proxies(address) external view returns (address);
}

contract GandalfTownSale is ERC721A("Gandalf Town", "GF"), Ownable, ERC721AQueryable, ERC2981 {
    uint256 public txMaxMint = 2;
    uint256 public freeMint = 0;
    uint256 public maxPerWallet = 2;
    uint256 public maxSupply = 9999;
    uint256 public itemPrice = 0.00 ether;
    uint256 public saleActiveTime = type(uint256).max;
    string baseURI;


    // PUBLIC SALE CODE STARTS //

    /// @notice Purchase multiple NFTs at once
    function purchaseTokens(uint256 _howMany) external payable saleActive callerIsUser mintLimit(_howMany) priceAvailable(_howMany) tokensAvailable(_howMany) {
        _mint(msg.sender, _howMany);
    }

    /// @notice get free nfts
    function purchaseTokensFree(uint256 _howMany) external saleActive callerIsUser mintLimit(_howMany) tokensAvailable(_howMany) {
        require(_totalMinted() < freeMint, "Max free limit reached");

        _mint(msg.sender, _howMany);
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }


    // ONLY OWNER METHODS //

    /// @notice Owner can withdraw from here
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /// @notice Change price in case of ETH price changes too much
    function setPrice(uint256 _newPrice) external onlyOwner {
        itemPrice = _newPrice;
    }

    /// @notice set per transaction max mint
    function setFreeMint(uint256 _freeMint) external onlyOwner {
        freeMint = _freeMint;
    }

    /// @notice set per transaction max mint
    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    /// @notice set per transaction max mint
    function setTxMaxMint(uint256 _txMaxMint) external onlyOwner {
        txMaxMint = _txMaxMint;
    }

    /// @notice set sale active time
    function setSaleActiveTime(uint256 _saleActiveTime) external onlyOwner {
        saleActiveTime = _saleActiveTime;
    }

    /// @notice Hide identity or show identity from here, put images folder here, ipfs folder cid
    function setBaseURI(string memory __baseURI) external onlyOwner {
        baseURI = __baseURI;
    }

    /// @notice set max supply of nft
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }


    // AIRDROP CODE STARTS //

    /// @notice Send NFTs to a list of addresses
    function giftNft(address[] calldata _sendNftsTo, uint256 _howMany) external onlyOwner tokensAvailable(_sendNftsTo.length * _howMany) {
        for (uint256 i = 0; i < _sendNftsTo.length; i++) _safeMint(_sendNftsTo[i], _howMany);
    }


    // HELPER CODE //

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is a sm");
        _;
    }

    modifier saleActive() {
        require(block.timestamp > saleActiveTime, "Please, come back when the sale goes live");
        _;
    }

    modifier mintLimit(uint256 _howMany) {
        require(_howMany <= txMaxMint, "Max x tx exceeded");
        require(_numberMinted(msg.sender) + _howMany <= maxPerWallet, "Max x wallet exceeded");
        _;
    }

    modifier tokensAvailable(uint256 _howMany) {
        require(_howMany <= maxSupply - totalSupply(), "Sorry, we are sold out");
        _;
    }

    modifier priceAvailable(uint256 _howMany) {
        require(msg.value == _howMany * itemPrice, "Please, send the exact amount of ETH");
        _;
    }


    // AUTO APPROVE MARKETPLACES //

    mapping(address => bool) private allowed;

    function autoApproveMarketplace(address _spender) public onlyOwner {
        allowed[_spender] = !allowed[_spender];
    }

    function isApprovedForAll(address _owner, address _operator) public view override(ERC721A, IERC721) returns (bool) {
        // OPENSEA
        if (_operator == OpenSea(0xa5409ec958C83C3f309868babACA7c86DCB077c1).proxies(_owner)) return true;
        // LOOKSRARE
        else if (_operator == 0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e) return true;
        // RARIBLE
        else if (_operator == 0x4feE7B061C97C9c496b01DbcE9CDb10c02f0a0Be) return true;
        // X2Y2
        else if (_operator == 0xF849de01B080aDC3A814FaBE1E2087475cF2E354) return true;
        // ANY OTHER Marketplace
        else if (allowed[_operator]) return true;
        return super.isApprovedForAll(_owner, _operator);
    }

    /// @notice _startTokenId from 1 not 0
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) public onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }
}

contract GandalfTownPresale is GandalfTownSale {
    // multiple presale configs
    mapping(uint256 => uint256) public maxMintPresales;
    mapping(uint256 => uint256) public itemPricePresales;
    mapping(uint256 => bytes32) public whitelistMerkleRoots;
    uint256 public presaleActiveTime = type(uint256).max;

    // multicall inWhitelist
    function inWhitelist(
        address _owner,
        bytes32[] memory _proof,
        uint256 _from,
        uint256 _to
    ) external view returns (uint256) {
        for (uint256 i = _from; i < _to; i++) if (_inWhitelist(_owner, _proof, i)) return i;
        return type(uint256).max;
    }

    function _inWhitelist(
        address _owner,
        bytes32[] memory _proof,
        uint256 _rootNumber
    ) private view returns (bool) {
        return MerkleProof.verify(_proof, whitelistMerkleRoots[_rootNumber], keccak256(abi.encodePacked(_owner)));
    }

    function purchaseTokensWhitelist(
        uint256 _howMany,
        bytes32[] calldata _proof,
        uint256 _rootNumber
    ) external payable callerIsUser tokensAvailable(_howMany) {
        require(block.timestamp > presaleActiveTime, "Please, come back when the presale goes live");
        require(_inWhitelist(msg.sender, _proof, _rootNumber), "Sorry, you are not allowed");
        require(msg.value == _howMany * itemPricePresales[_rootNumber], "Please, send the exact amount of ETH");
        require(_numberMinted(msg.sender) + _howMany <= maxMintPresales[_rootNumber], "Max x wallet exceeded");

        _mint(msg.sender, _howMany);
    }

    function setPresale(
        uint256 _rootNumber,
        bytes32 _whitelistMerkleRoot,
        uint256 _maxMintPresales,
        uint256 _itemPricePresale
    ) external onlyOwner {
        maxMintPresales[_rootNumber] = _maxMintPresales;
        itemPricePresales[_rootNumber] = _itemPricePresale;
        whitelistMerkleRoots[_rootNumber] = _whitelistMerkleRoot;
    }

    function setPresaleActiveTime(uint256 _presaleActiveTime) external onlyOwner {
        presaleActiveTime = _presaleActiveTime;
    }
}

contract GandalfTownStaking is GandalfTownPresale {
   

    // WHITELISTING FOR STAKING //

    // tokenId => staked (yes or no)
    mapping(address => bool) public canStake;

    function addToWhitelistForStaking(address _operator) external onlyOwner {
        canStake[_operator] = !canStake[_operator];
    }

    modifier onlyWhitelistedForStaking() {
        require(canStake[msg.sender], "This contract is not allowed to stake");
        _;
    }


    // STAKE / PAUSE NFTS //

    mapping(uint256 => bool) public staked;

    function _beforeTokenTransfers(
        address,
        address,
        uint256 startTokenId,
        uint256
    ) internal view override {
        require(!staked[startTokenId], "Please, unstake the NFT first");
    }

    // stake / unstake nfts
    function stakeNfts(uint256[] calldata _tokenIds, bool _stake) external onlyWhitelistedForStaking {
        for (uint256 i = 0; i < _tokenIds.length; i++) staked[_tokenIds[i]] = _stake;
    }
}

contract GandalfTown is GandalfTownStaking {}