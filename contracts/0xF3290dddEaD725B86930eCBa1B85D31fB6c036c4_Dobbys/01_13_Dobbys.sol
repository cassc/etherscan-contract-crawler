// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interface/IRandomness.sol";
import "hardhat/console.sol";

contract Dobbys is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    bytes32 public merkleRoot;
    mapping(uint => mapping(address => bool)) public whitelistClaimed;
    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;
    string public legendaryMetadataUri;

    uint256[] public cost;
    uint256 public maxSupply;
    uint256 public legendarySupply;
    uint256[] public maxMintAmountsPerTx;
    uint256[] public supplyLimiters;
    uint256 public currentPhase;

    bool public paused = true;
    bool public whitelistMintEnabled = false;
    bool public revealed = false;

    struct Minting {
        address minter;
        uint256 amount;
    }

    struct Metadata {
        string dna;
        uint256 edition;
    }

    mapping(uint256 => Metadata) public metadata;
    mapping(uint256 => uint256) randomValueByTokenId;
    uint256[] private ids;
    uint256 private index;
    uint256 public metadataCount;
    IRandomness private rn;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256[] memory _cost,
        uint256[] memory _supplyLimiters,
        uint256 _legendarySupply,
        uint256[] memory _maxMintAmountsPerTx,
        string memory _hiddenMetadataUri,
        string memory _legendaryMetadataUri,
        address _rn
    ) ERC721A(_tokenName, _tokenSymbol) {
        cost = _cost;
        legendarySupply = _legendarySupply;
        maxMintAmountsPerTx = _maxMintAmountsPerTx;
        setHiddenMetadataUri(_hiddenMetadataUri);
        setLegendaryMetadataUri(_legendaryMetadataUri);
        rn = IRandomness(_rn);
        ids = new uint256[](_supplyLimiters[currentPhase]);
        supplyLimiters = _supplyLimiters;
        setSupplyLimitersAndMaxSupply(supplyLimiters); // set maxSupply
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountsPerTx[currentPhase],
            "Invalid mint amount!"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply - legendarySupply,
            "Max supply exceeded!"
        );
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= cost[currentPhase] * _mintAmount, "Insufficient funds!");
        _;
    }

    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
    public
    payable
    mintCompliance(_mintAmount)
    mintPriceCompliance(_mintAmount)
    {
        // Verify whitelist requirements
        require(whitelistMintEnabled, "The whitelist sale is not enabled!");
        require(!whitelistClaimed[currentPhase][_msgSender()], "Address already claimed!");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof!"
        );

        whitelistClaimed[currentPhase][_msgSender()] = true;
        fulfillRandomness(_msgSender(), _mintAmount);
    }

    function mint(uint256 _mintAmount)
    public
    payable
    mintCompliance(_mintAmount)
    mintPriceCompliance(_mintAmount)
    {
        require(!paused, "The contract is paused!");
        fulfillRandomness(_msgSender(), _mintAmount);
    }

    function mintForAddress(uint256 _mintAmount, address _receiver)
    public
    mintCompliance(_mintAmount)
    onlyOwner
    {
        fulfillRandomness(_receiver, _mintAmount);
    }

    function getPrevTotalSupply() private view returns (uint256) {
        uint256 _prevTotalSupply;
        for (uint256 i = 0; i < currentPhase; i++) {
            _prevTotalSupply += supplyLimiters[i];
        }
        return _prevTotalSupply;
    }

    function pickRandomUniqueId(uint256 seed) private returns (uint256 _id) {
        uint256 len = ids.length - index++;
        require(len > 0, "General NFTs sold out!");
        uint256 randomIndex = seed % len;
        _id = ids[randomIndex] != 0 ? ids[randomIndex] : randomIndex;
        ids[randomIndex] = uint256(ids[len - 1] == 0 ? len - 1 : ids[len - 1]);
        ids[len - 1] = 0;
    }

    function generateRandomByTokenIds(uint256 _tokenId, uint256 _seed) private {
        uint256 randomSeed = uint256(keccak256(abi.encode(_seed, _tokenId)));
        uint256 randomId = pickRandomUniqueId(randomSeed);
        uint256 prevTotalSupply = getPrevTotalSupply();
        randomValueByTokenId[_tokenId] = randomId + 1 + prevTotalSupply;
    }

    function fulfillRandomness(address _minter, uint256 _amount) private {
        require(_minter != address(0));

        uint256 startId = totalSupply() + 1;
        uint256 endId = startId + _amount;
        uint256 remain;
        uint256 prevTotalSupply = getPrevTotalSupply() + supplyLimiters[currentPhase] + 1;
        if(endId > prevTotalSupply) {
            remain = endId - prevTotalSupply;
            endId = prevTotalSupply;
        }
        for (uint256 i = startId; i < endId; i++) {
            uint256 _randomness = rn.getRandom(i);
            generateRandomByTokenIds(i, _randomness);
        }
        _safeMint(_minter, _amount - remain);

        if(remain != 0) {
            currentPhase++;
            ids = new uint256[](supplyLimiters[currentPhase]);
            index = 0;

            for (uint256 i = endId; i < startId + _amount; i++) {
                uint256 _randomness = rn.getRandom(i);
                generateRandomByTokenIds(i, _randomness);
            }
            _safeMint(_minter, startId + _amount - endId);
        } else {
            if (
                totalSupply() == getPrevTotalSupply() + supplyLimiters[currentPhase] && 
                currentPhase < supplyLimiters.length - 1
            ) {
                currentPhase++;
                ids = new uint256[](supplyLimiters[currentPhase]);
                index = 0;
            }
        }
    }

    function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = _startTokenId();
        uint256 ownedTokenIndex = 0;
        address latestOwnerAddress;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply
        ) {
            TokenOwnership memory ownership = _ownershipAt(currentTokenId);

            if (!ownership.burned && ownership.addr != address(0)) {
                latestOwnerAddress = ownership.addr;
            }

            if (latestOwnerAddress == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        if (_tokenId <= maxSupply - legendarySupply) {
            string memory currentBaseURI = _baseURI();
            uint256 randomIdByTokenId = randomValueByTokenId[_tokenId];
            return
            bytes(currentBaseURI).length > 0
            ? string(
                abi.encodePacked(
                    currentBaseURI,
                    Strings.toString(
                        metadata[randomIdByTokenId].edition
                    ),
                    uriSuffix
                )
            )
            : "";
        } else {
            return
            string(
                abi.encodePacked(
                    legendaryMetadataUri,
                    Strings.toString(
                        _tokenId - (maxSupply - legendarySupply)
                    ),
                    uriSuffix
                )
            );
        }
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setCost(uint256 phase, uint256 _cost) public onlyOwner {
        require(phase >= currentPhase, "Cannot change mint limit for past phases");
        cost[phase] = _cost;
    }

    function setMaxMintAmountPerTx(uint256 phase, uint256 _maxMintAmountPerTx)
    public
    onlyOwner
    {
        require(phase >= currentPhase, "Cannot change mint limit for past phases");
        require(_maxMintAmountPerTx <= supplyLimiters[phase], "Cannot be larger than phase supply");
        maxMintAmountsPerTx[phase] = _maxMintAmountPerTx;
    }

    function currentMaxMintAmountPerTx() public view returns (uint256){
        return maxMintAmountsPerTx[currentPhase];
    }

    function currentCost() public view returns (uint256){
        return cost[currentPhase];
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
    public
    onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setLegendaryMetadataUri(string memory _legendaryMetadataUri)
    public
    onlyOwner
    {
        legendaryMetadataUri = _legendaryMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setWhitelistMintEnabled(bool _state) public onlyOwner {
        whitelistMintEnabled = _state;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setSupplyLimitersAndMaxSupply(uint256[] memory _supplyLimiters) public onlyOwner {
        supplyLimiters = _supplyLimiters;
        uint256 _maxSupply;
        for (uint256 i = 0; i < _supplyLimiters.length; i++) {
            _maxSupply += _supplyLimiters[i];
        }
        require(_maxSupply >= totalSupply(), "Cannot size down supply lower than minted supply");
        maxSupply = _maxSupply + legendarySupply;
        ids = new uint256[](supplyLimiters[currentPhase]);
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os,) = payable(owner()).call{value : address(this).balance}("");
        require(os);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function ownerMint(uint256 _mintAmount) public onlyOwner {
        require(
            totalSupply() + _mintAmount <= maxSupply - legendarySupply,
            "Max supply exceeded!"
        );

        if (_mintAmount > 0) {
            fulfillRandomness(_msgSender(), _mintAmount);
        }
    }

    function legendaryMint(address[] calldata _addresses) public onlyOwner {
        require(
            _addresses.length == legendarySupply,
            "Invalid legendary addresses count!"
        );
        require(
            totalSupply() == maxSupply - legendarySupply,
            "General NFTs not sold out!"
        );
        for (uint256 i = 0; i < _addresses.length; i++) {
            _safeMint(_addresses[i], 1);
        }
    }

    function uploadMetadata(Metadata[] calldata _metadata) public onlyOwner {
        require(
            metadataCount + _metadata.length <= maxSupply - legendarySupply,
            "Max metadata amount exceeded!"
        );
        for (uint256 i = 0; i < _metadata.length; i++) {
            // tokenId start from num 1.
            metadata[metadataCount + i + 1] = Metadata(
                _metadata[i].dna,
                _metadata[i].edition
            );
        }
        metadataCount += _metadata.length;
    }
}