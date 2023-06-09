// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

contract XXAP35S is ERC721A, Ownable {
    using Strings for uint256;

    // ================== VARAIBLES =======================

    string private uriPrefix = "";
    string private uriSuffix = ".json";
    string private hiddenMetadataUri;
    bool public paused = true;
    bool public revealed = true;

    uint256 public salePrice = 0.004 ether;
    uint256 public maxFree = 2;
    uint256 public maxTx = 20;
    uint256 public maxFreeSupply = 2000;
    uint256 public maxSupply = 4973;

    uint256 public FREE_MINTED = 0;
    mapping(address => uint256) public CLAIMED;

    // ================== CONTRUCTOR =======================

    constructor() ERC721A("XXAP35S", "XXAP35S") {
        setHiddenMetadataUri("ipfs://__CID__/hidden.json");
    }

    // ================== MINT FUNCTIONS =======================

    /**
     * @notice Mint
     */
    function mint(uint256 _quantity) external payable {
        // Normal requirements
        require(!paused, "The contract is paused!");
        require(
            _quantity > 0,
            "Minimum 1 NFT has to be minted per transaction"
        );
        require(_quantity + balanceOf(msg.sender) <= maxTx, "No more!");
        require(_quantity + totalSupply() <= maxSupply, "Sold out");

        if (msg.sender != owner()) {
            if (
                !(CLAIMED[msg.sender] >= maxFree) && FREE_MINTED + maxFree <= maxFreeSupply
            ) {
                if (_quantity <= maxFree - CLAIMED[msg.sender]) {
                    require(msg.value >= 0, "Please send the exact amount.");
                } else {
                    require(
                        msg.value >=
                            salePrice *
                                (_quantity - (maxFree - CLAIMED[msg.sender])),
                        "Please send the exact amount."
                    );
                }
                FREE_MINTED += _quantity;
                CLAIMED[msg.sender] += _quantity;
            } else {
                require(
                    msg.value >= salePrice * _quantity,
                    "Please send the exact amount."
                );
            }
        }

        // Mint
        _safeMint(msg.sender, _quantity);
    }

    /**
     * @notice Team Mint
     */
    function teamMint(uint256 _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= maxSupply, "Sold out");
        _safeMint(msg.sender, _quantity);
    }

    /**
     * @notice airdrop
     */
    function airdrop(address _to, uint256 _quantity) external onlyOwner {
        require(!paused, "The contract is paused!");
        require(_quantity + totalSupply() <= maxSupply, "Sold out");
        _safeMint(_to, _quantity);
    }

    // ================== SETUP FUNCTIONS =======================

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setSalePrice(uint256 _newPrice) external onlyOwner {
        salePrice = _newPrice;
    }

    function setMaxFree(uint256 _maxFree) public onlyOwner {
        maxFree = _maxFree;
    }

    function setMaxTx(uint256 _maxTx) public onlyOwner {
        maxTx = _maxTx;
    }

    function setMaxFreeSupply(uint256 _maxFreeSupply) public onlyOwner {
        maxFreeSupply = _maxFreeSupply;
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