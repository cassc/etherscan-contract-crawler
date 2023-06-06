// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";

contract EchiGirls is ERC721A, Ownable {
    using Strings for uint256;

    // ================== VARAIBLES =======================

    bytes32 public merkleRootWl;
    bool public revealed = false;
    bool public isPaused = true;

    string private uriPrefix = "";
    string private uriSuffix = ".json";
    string private hiddenMetadataUri;

    uint256[] public price = [0.0049 ether, 0.0049 ether];
    uint256[] public maxTX = [5, 10];
    uint256[] public noCost = [2, 1];

    uint256 public noCostLimit = 2000;
    uint256 public maxSupply = 4444;

    uint256 public NC_MINTED = 0;

    mapping(address => uint256) public MINT_COUNT;
    mapping(address => bool) public CLAIMED;

    // ================== CONTRUCTOR =======================

    constructor() ERC721A("EchiGirls", "EG") {
        setHiddenMetadataUri("ipfs://__CID__/hidden.json");
    }

    // ================== MINT FUNCTIONS =======================

    /**
     * @notice Mint
     */
    function mint(uint256 _quantity, bytes32[] calldata _merkleProof)
        external
        payable
    {
        require(!isPaused, "The contract is paused!");

        uint256 maxTx = maxTX[1];
        uint256 free = noCost[1];
        uint256 salePrice = price[1];
        if (isWhitelist(_merkleProof)) {
            maxTx = maxTX[0];
            free = noCost[0];
            salePrice = price[0];
        }
        // Normal requirements
        require(totalSupply() + _quantity <= maxSupply, "Sold out!");
        require(_quantity > 0 && _quantity <= maxTx, "Invalid mint amount!");
        require(
            MINT_COUNT[msg.sender] + _quantity <= maxTx,
            "Max mint per wallet exceeded!"
        );

        if (
            !CLAIMED[msg.sender] && free != 0 && NC_MINTED + free <= noCostLimit
        ) {
            if (_quantity <= free) {
                require(msg.value >= 0, "Please send the exact amount.");
                NC_MINTED += _quantity;
            } else {
                require(
                    msg.value >= salePrice * (_quantity - free),
                    "Please send the exact amount."
                );
                NC_MINTED += free;
            }
            CLAIMED[msg.sender] = true;
        } else {
            require(
                msg.value >= salePrice * _quantity,
                "Please send the exact amount."
            );
        }

        // Mint
        _safeMint(msg.sender, _quantity);

        // Mapping update
        MINT_COUNT[msg.sender] += _quantity;
    }

    /**
     * @notice Team Mint
     */
    function teamMint(uint256 _quantity) external onlyOwner {
        require(
            _quantity > 0,
            "Minimum 1 NFT has to be minted per transaction"
        );
        require(totalSupply() + _quantity <= maxSupply, "Sold out");
        _safeMint(msg.sender, _quantity);
    }

    /**
     * @notice airdrop
     */
    function airdrop(address _to, uint256 _quantity) external onlyOwner {
        require(!isPaused, "The contract is paused!");
        require(_quantity + totalSupply() <= maxSupply, "Sold out");
        _safeMint(_to, _quantity);
    }

    /**
     * @notice Check if the address is in the white list or not
     */
    function isWhitelist(bytes32[] calldata _merkleProof)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (MerkleProof.verify(_merkleProof, merkleRootWl, leaf)) {
            return true;
        }
        return false;
    }

    // ================== SETUP FUNCTIONS =======================

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setIsPaused(bool _state) external onlyOwner {
        isPaused = _state;
    }

    function setWhitelist(bytes32 _merkleRoot) external onlyOwner {
        merkleRootWl = _merkleRoot;
    }

    function setPrice(uint256[] memory _price) public onlyOwner {
        price = _price;
    }

    function setMaxTX(uint256[] memory _maxTX) public onlyOwner {
        maxTX = _maxTX;
    }

    function setNoCost(uint256[] memory _noCost) public onlyOwner {
        noCost = _noCost;
    }

    function setNoCostLimit(uint256 _noCostLimit) public onlyOwner {
        noCostLimit = _noCostLimit;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);
            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
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
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}