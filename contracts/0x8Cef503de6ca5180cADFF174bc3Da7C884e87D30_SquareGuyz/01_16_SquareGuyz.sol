//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract SquareGuyz is ERC721AQueryable, ReentrancyGuard, Ownable {
    uint256 public maxSupply = 8888;
    bool private _paused = false;
    uint256 public PUBLIC_MINT_PRICE = 0.001 ether;
    bool public revealed = true;
    uint256 public MAX_FREE_MINT_PER_WALLET = 5;
    uint256 public MAX_PER_TX = 10;
    bytes32 public root;
    mapping(address => bool) whitelistUserMinted;
    uint256 public MAX_FREE_MINT = 4444;
    mapping(address => bool) userFreeMinted;

    // TODO: 记得Deploy to mainet的时候，要把这个uriPrefix修改为正确的指向json的目录
    string public uriPrefix =
        "ar://bLlRFRTUioMMbT7eIqxehNvfrjwtK_Dujk6PIA0HU_4/";
    using Strings for uint256;

    constructor(bytes32 _root) ERC721A("SquareGuyz NFT", "SQG") {
        root = _root;
    }

    function whitelistMint(uint256 _quantity, bytes32[] memory proof)
        public
        payable
    {
        require(
            _quantity <= MAX_FREE_MINT_PER_WALLET,
            "Quantity must be 1 in white list minting stage"
        );
        require(
            whitelistUserMinted[_msgSender()] == false,
            "You have minted 1 NFT in white list minting stage"
        );
        require(
            isValid(proof, keccak256(abi.encodePacked(_msgSender()))),
            "You are not on the white list"
        );
        require(_paused == false, "Mint paused");
        require(_quantity > 0, "Invalid quantity!");
        require(totalSupply() + _quantity <= maxSupply, "Max supply exceed!");

        _safeMint(_msgSender(), _quantity);

        whitelistUserMinted[_msgSender()] = true;
    }

    function freeMint() public payable {
        require(
            userFreeMinted[_msgSender()] == false,
            "You have minted 1 free NFT"
        );
        require(_paused == false, "Mint paused");
        require(
            totalSupply() + MAX_FREE_MINT_PER_WALLET <= MAX_FREE_MINT,
            "Max free exceed!"
        );
        _safeMint(_msgSender(), MAX_FREE_MINT_PER_WALLET);
        userFreeMinted[_msgSender()] = true;
    }

    // First 4,444 free then 0.001 ETH each! Max supply 8,888. Max 10 NFTs per transaction. Instant reveal.
    function mint(uint256 _quantity) public payable {
        require(_paused == false, "Mint paused");
        require(_quantity > 0, "Invalid quantity!");
        require(_quantity <= MAX_PER_TX, "Max 10 per transaction");
        require(totalSupply() + _quantity <= maxSupply, "Max supply exceed!");
        require(msg.value >= PUBLIC_MINT_PRICE * _quantity, "Incorrect price");

        _safeMint(_msgSender(), _quantity);
    }

    /**
     * @dev token id starts with 1
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @dev override base URI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    /**
     * @dev get token URI by token ID
     */
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

        if (revealed) {
            return
                bytes(currentBaseURI).length > 0
                    ? string(
                        abi.encodePacked(
                            currentBaseURI,
                            tokenId.toString(),
                            ".json"
                        )
                    )
                    : "";
        } else {
            return string(abi.encodePacked(currentBaseURI, "1.json"));
        }
    }

    /**
     @dev withdraw
     */
    function withdraw() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        (bool os, ) = payable(owner()).call{value: balance}("");
        require(os);
    }

    function changeBaseURI(string memory baseURI) public onlyOwner {
        uriPrefix = baseURI;
    }

    function changeMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function ownerMint(uint256 _quantity) public onlyOwner {
        require(_quantity > 0, "Invalid mint ammount!");
        require(totalSupply() + _quantity <= maxSupply, "Max supply exceed!");

        _safeMint(_msgSender(), _quantity);
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    function unpause() public onlyOwner {
        require(
            _paused == true,
            "Make sure it was paused so it can be unpause"
        );
        _paused = false;
    }

    function pause() public onlyOwner {
        require(_paused == false, "Already paused");

        _paused = true;
    }

    function reveal() public onlyOwner {
        require(revealed == false, "Already revealed");

        revealed = true;
    }

    function changePrice(uint256 _price) public onlyOwner {
        PUBLIC_MINT_PRICE = _price;
    }

    function setWhitelistMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        root = _merkleRoot;
    }

    function isValid(bytes32[] memory proof, bytes32 leaf)
        public
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }

    function changeMaxFreeMint(uint256 _quantity) public onlyOwner {
        MAX_FREE_MINT_PER_WALLET = _quantity;
    }
}