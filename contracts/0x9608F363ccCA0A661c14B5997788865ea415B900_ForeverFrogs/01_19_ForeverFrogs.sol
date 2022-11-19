// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721AQueryable.sol";
import "./ForeverFrogsEgg.sol";
import "./DefaultOperatorFilterer.sol";

contract ForeverFrogs is ERC721AQueryable, Ownable, PaymentSplitter, DefaultOperatorFilterer {
    using Strings for uint;

    uint16 public maxSupply = 7777;

    uint8 public maxPerTx            = 25;
    uint8 public maxMintForEgg       = 100;
    uint8 public maxMintForOg        = 200;
    uint8 public maxMintForWhitelist = 200;
    uint8 public maxMintPerAddress   = 250;
    uint8 public maxBurnEggsPerTx    = 10;

    uint8 public freeMintMaxPerTx      = 5;
    uint8 public freeMintMaxPerAddress = 5;
    uint16 public freeMintUntilSupply  = 0;

    uint32 public mintStartTime  = 1668790800;
    uint64 public ogPrice        = 0.015 ether;
    uint64 public whitelistPrice = 0.02 ether;
    uint64 public price          = 0.025 ether;

    bool public isEggMintActive = true;

    bytes32 public ogMerkleRoot;
    bytes32 public whitelistMerkleRoot;

    string private baseURI;

    enum Step {
        Before,
        OgMint,
        WhitelistMint,
        PublicMint,
        SoldOut
    }

    mapping(address => uint8) private eggsByAddress;
    mapping(address => uint8) private ogByAddress;
    mapping(address => uint8) private whitelistByAddress;
    mapping(address => uint8) private nftByAddress;
    mapping(uint256 => bool) private alreadyBurnedEggs;

    ForeverFrogsEgg public foreverFrogsEgg;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;

    constructor(address[] memory _team, uint[] memory _teamShares, bytes32 _ogMerkleRoot, bytes32 _whitelistMerkleRoot)
    ERC721A("Forever Frogs", "FF")
    PaymentSplitter(_team, _teamShares)
    {
        foreverFrogsEgg = ForeverFrogsEgg(0x507d28427Cfa14dEF489c3ec53817C002E23DA4B);
        ogMerkleRoot = _ogMerkleRoot;
        whitelistMerkleRoot = _whitelistMerkleRoot;
        _safeMint(msg.sender, 3);
    }

    event BurnAndMintEvent(uint256[] indexed burnedIds, address indexed owner);
    event OgMintEvent(uint256 indexed quantity, address indexed owner);
    event WhitelistMintEvent(uint256 indexed quantity, address indexed owner);
    event MintEvent(uint256 indexed quantity, address indexed owner);

    function getStep() public view returns(Step actualStep) {
        if (block.timestamp < mintStartTime)
            return Step.Before;

        if (block.timestamp >= mintStartTime && block.timestamp < mintStartTime + 1 hours)
            return Step.OgMint;

        if (block.timestamp >= mintStartTime + 1 hours && block.timestamp < mintStartTime + 2 hours)
            return Step.WhitelistMint;

        if (block.timestamp >= mintStartTime + 2 hours) {
            if (totalMinted() < maxSupply)
                return Step.PublicMint;
        }

        return Step.SoldOut;
    }

    function burnAndMint(uint256[] calldata ids) external senderControl {
        uint256 quantity = ids.length;

        require(isEggMintActive, "Burn egg to mint is not available");
        require(quantity > 0, "You must burn at least 1 egg");
        require(quantity < maxBurnEggsPerTx + 1, "You can not burn too many eggs at once");
        require(totalMinted() + quantity < maxSupply + 1, "Max supply exceeded");
        require(eggsByAddress[msg.sender] + quantity < maxMintForEgg + 1, "Max eggs mint reached for your address");
        require(foreverFrogsEgg.isApprovedForAll(msg.sender, address(this)), "Not enough rights from eggs smart contract");

        for (uint8 i = 0; i < quantity; i++) {
            ForeverFrogsEgg.TokenOwnership memory egg = foreverFrogsEgg.explicitOwnershipOf(ids[i]);
            require(alreadyBurnedEggs[ids[i]] != true, "This egg has already been burned");
            require(egg.addr == msg.sender, "You need to own the egg");
        }

        for (uint8 i = 0; i < quantity; i++) {
            foreverFrogsEgg.safeTransferFrom(msg.sender, deadAddress, ids[i]);
            alreadyBurnedEggs[ids[i]] = true;
        }

        eggsByAddress[msg.sender] += uint8(quantity);

        _safeMint(msg.sender, quantity);

        emit BurnAndMintEvent(ids, msg.sender);
    }

    function ogMint(uint256 _quantity, bytes32[] calldata _proof) external payable senderControl {
        require(getStep() == Step.OgMint, "OG mint is not available");
        require(_quantity > 0, "Mint 0 has no sense");
        require(_quantity < maxPerTx + 1, "Max NFTs per transaction reached");
        require(totalMinted() + _quantity < maxSupply + 1, "Max supply exceeded");
        require(msg.value >= ogPrice * _quantity, "Not enough funds");
        require(isOgWhiteListed(msg.sender, _proof), "Not an OG");
        require(ogByAddress[msg.sender] + _quantity < maxMintForOg + 1, "Max OG reached for your address");
        require(nftByAddress[msg.sender] + _quantity < maxMintPerAddress + 1, "Max per wallet reached");

        ogByAddress[msg.sender] += uint8(_quantity);
        nftByAddress[msg.sender] += uint8(_quantity);

        _safeMint(msg.sender, _quantity);

        emit OgMintEvent(_quantity, msg.sender);
    }

    function whitelistMint(uint256 _quantity, bytes32[] calldata _proof) external payable senderControl {
        require(getStep() == Step.WhitelistMint, "Whitelist mint is not available");
        require(_quantity > 0, "Mint 0 has no sense");
        require(_quantity < maxPerTx + 1, "Max NFTs per transaction reached");
        require(totalMinted() + _quantity < maxSupply + 1, "Max supply exceeded");
        require(msg.value >= whitelistPrice * _quantity, "Not enough funds");
        require(isWhiteListed(msg.sender, _proof), "Not whitelisted");
        require(whitelistByAddress[msg.sender] + _quantity < maxMintForWhitelist + 1, "Max whitelist reached for your address");
        require(nftByAddress[msg.sender] + _quantity < maxMintPerAddress + 1, "Max per wallet reached");

        whitelistByAddress[msg.sender] += uint8(_quantity);
        nftByAddress[msg.sender] += uint8(_quantity);

        _safeMint(msg.sender, _quantity);

        emit WhitelistMintEvent(_quantity, msg.sender);
    }

    function mint(uint256 _quantity) external payable senderControl {
        require(getStep() == Step.PublicMint, "Public mint is not available");
        require(totalMinted() + _quantity < maxSupply + 1, "Max supply exceeded");

        if (
            freeMintUntilSupply > 0 &&
            totalMinted() + _quantity <= freeMintUntilSupply
        ) {
            require(_quantity < freeMintMaxPerTx + 1, "Max NFTs per transaction reached");
            require(nftByAddress[msg.sender] + _quantity < freeMintMaxPerAddress + 1, "Max per wallet reached");
        } else {
            require(_quantity < maxPerTx + 1, "Max NFTs per transaction reached");
            require(msg.value >= _quantity * price, "Insufficient funds");
            require(nftByAddress[msg.sender] + _quantity < maxMintPerAddress + 1, "Max per wallet reached");
        }

        nftByAddress[msg.sender] += uint8(_quantity);

        _safeMint(msg.sender, _quantity);

        emit MintEvent(_quantity, msg.sender);
    }

    function airdrop(address _to, uint256 _quantity) external onlyOwner {
        require(totalMinted() + _quantity < maxSupply + 1, "Max supply exceeded");

        _safeMint(_to, _quantity);
    }

    //Whitelist
    function setWhitelistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        whitelistMerkleRoot = _merkleRoot;
    }

    function isWhiteListed(address _account, bytes32[] calldata _proof) internal view returns(bool) {
        return _verifyWhitelist(leaf(_account), _proof);
    }

    function _verifyWhitelist(bytes32 _leaf, bytes32[] memory _proof) internal view returns(bool) {
        return MerkleProof.verify(_proof, whitelistMerkleRoot, _leaf);
    }

    //OGs
    function setOgMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        ogMerkleRoot = _merkleRoot;
    }

    function isOgWhiteListed(address _account, bytes32[] calldata _proof) internal view returns(bool) {
        return _verifyOg(leaf(_account), _proof);
    }

    function _verifyOg(bytes32 _leaf, bytes32[] memory _proof) internal view returns(bool) {
        return MerkleProof.verify(_proof, ogMerkleRoot, _leaf);
    }


    function leaf(address _account) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(_account));
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function tokenURI(uint256 tokenId) public view virtual override (ERC721A, IERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return string(abi.encodePacked(baseURI, _toString(tokenId)));
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function flipEggMintState() external onlyOwner {
        isEggMintActive = !isEggMintActive;
    }

    function setPrice(uint64 _price) external onlyOwner {
        price = _price;
    }

    function setOgPrice(uint64 _price) external onlyOwner {
        ogPrice = _price;
    }

    function setWhitelistPrice(uint64 _price) external onlyOwner {
        whitelistPrice = _price;
    }

    function setMintStartTime(uint32 _timestamp) external onlyOwner {
        mintStartTime = _timestamp;
    }

    function setForeverFrogsEgg(address _address) external onlyOwner {
        foreverFrogsEgg = ForeverFrogsEgg(_address);
    }

    function setMaxSupply(uint16 _supply) external onlyOwner {
        require(totalMinted() < maxSupply, "Sold out!");
        require(_supply >= totalMinted());
        maxSupply = _supply;
    }

    function setMaxPerTx(uint8 _max) external onlyOwner {
        maxPerTx = _max;
    }

    function setMaxMintForEgg(uint8 _max) external onlyOwner {
        maxMintForEgg = _max;
    }

    function setMaxMintForOg(uint8 _max) external onlyOwner {
        maxMintForOg = _max;
    }

    function setMaxMintForWhitelist(uint8 _max) external onlyOwner {
        maxMintForWhitelist = _max;
    }

    function setMaxMintPerAddress(uint8 _max) external onlyOwner {
        maxMintPerAddress = _max;
    }

    function setMaxBurnEggsPerTx(uint8 _max) external onlyOwner {
        maxBurnEggsPerTx = _max;
    }

    function setFreeMintUntilSupply(uint16 _supply) external onlyOwner {
        if (_supply <= maxSupply) {
            freeMintUntilSupply = _supply;
        }
    }

    function setFreeMintMaxPerTx(uint8 _max) external onlyOwner {
        freeMintMaxPerTx = _max;
    }

    function setFreeMintMaxPerAddress(uint8 _max) external onlyOwner {
        freeMintMaxPerAddress = _max;
    }

    function burnedEggsFromAddress(address _address) external view returns (uint8) {
        return eggsByAddress[_address];
    }

    function ogMintedFromAddress(address _address) external view returns (uint8) {
        return ogByAddress[_address];
    }

    function whitelistMintedFromAddress(address _address) external view returns (uint8) {
        return whitelistByAddress[_address];
    }

    function nftMintedFromAddress(address _address) external view returns (uint8) {
        return nftByAddress[_address];
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    modifier senderControl() {
        require(msg.sender == tx.origin);
        _;
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override (IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override (IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    payable
    override (IERC721A, ERC721A)
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}