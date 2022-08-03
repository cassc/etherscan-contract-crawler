// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

/// @title BaseNFT
contract BubblyNFT is ERC721AQueryable, ReentrancyGuard, ERC2981, Ownable {
    /// Constants
    uint256 public constant MAX_SUPPLY = 3333;
    uint256 public constant MAX_TEAM_MINT_QUANTIY = 200;

    address public constant DEV_ADDRESS =
        0xEc98863460e0FCdB528B6131869604AA0a1d4432;
    address public constant TEAM_ADDRESS =
        0x0508dA03cd0e523ccDED37Fa1E2D5fDF7773C0fD;

    uint256 private constant _SALES_ROUND_PAUSE = 0;
    uint256 private constant _SALES_ROUND_TEAM = 1;
    uint256 private constant _SALES_ROUND_WHITELIST = 2;
    uint256 private constant _SALES_ROUND_RAFFLE = 3;
    uint256 private constant _SALES_ROUND_PUBLIC = 4;

    /// Public Variables
    string public prefixURI = "ipfs://__CID__/";
    string public suffixURI = ".json";
    string public hiddenMetadataUri = "https://raw.githubusercontent.com/Artari-punk/Whitelist-Dapp/main/metadata.json";
   
    bool public revealed = false;
    bytes32 public merkleRoot = 0x0;
    uint256 public tokenPrice = 49000000000000000;
    uint256 public maxPerWallet = 3;
    uint256 public quantityForMint = 3133;
    uint256 public salesRound = 0;
    uint256 public isTeamMinted = 0;

    mapping(address => mapping(uint256 => uint256))
        public userRoundMintedAmount;

    /// Modifiers
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is not wallet");
        _;
    }

    constructor() ERC721A("Bubbly", "BUB") {}

    /// Owner Methods
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setQuantityForMint(uint256 _quantityForMint) public onlyOwner {
        require(_quantityForMint <= MAX_SUPPLY, "exceed max supply");

        quantityForMint = _quantityForMint;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) public onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    function setTokenPrice(uint256 _tokenPrice) public onlyOwner {
        tokenPrice = _tokenPrice;
    }

    function setPrefixURI(string memory _prefixURI) public onlyOwner {
        prefixURI = _prefixURI;
    }

    function setSuffixURI(string memory _suffixURI) public onlyOwner {
        suffixURI = _suffixURI;
    }

    function setSalesRound(uint256 _salesRound) public onlyOwner {
        salesRound = _salesRound;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function emergencySafe() public onlyOwner {
        selfdestruct(payable(TEAM_ADDRESS));
    }

    function withdraw() public onlyOwner {
        // Dev wallet
        (bool hs, ) = payable(DEV_ADDRESS).call{
            value: (address(this).balance * 5) / 100
        }("");
        require(hs);

        // Team wallet
        (bool os, ) = payable(TEAM_ADDRESS).call{value: address(this).balance}(
            ""
        );
        require(os);
    }

    /// Mint Methods
    function mintToTeam(address _to) public onlyOwner {
        require(_to != address(0), "invalid receiver");
        require(_SALES_ROUND_TEAM == salesRound, "invalid mint round");
        require(isTeamMinted == 0, "team minted");

        isTeamMinted = 1;

        _mint(_to, MAX_TEAM_MINT_QUANTIY);
    }

    function mint(
        bytes32[] memory _proof,
        uint256 _maxQuantity,
        uint256 _quantity
    ) public payable callerIsUser {
        require(
            _SALES_ROUND_WHITELIST == salesRound ||
                _SALES_ROUND_RAFFLE == salesRound ||
                _SALES_ROUND_PUBLIC == salesRound,
            "invalid mint round"
        );

        if (
            _SALES_ROUND_WHITELIST == salesRound ||
            _SALES_ROUND_RAFFLE == salesRound
        ) {
            require(merkleRoot != 0x0, "merkle root is not yet set");

            bytes32 leaf = keccak256(
                abi.encodePacked(
                    address(this),
                    _msgSender(),
                    _maxQuantity,
                    salesRound
                )
            );
            require(
                MerkleProof.verify(_proof, merkleRoot, leaf),
                "invalid merkle proof"
            );
        }

        if (_SALES_ROUND_PUBLIC == salesRound) {
            _maxQuantity = maxPerWallet;
        }

        require(
            _totalMinted() + _quantity <= quantityForMint,
            "exceed max quantity for mint"
        );
        require(
            userRoundMintedAmount[_msgSender()][salesRound] + _quantity <=
                _maxQuantity,
            "exceed mint amount"
        );
        require(msg.value >= tokenPrice * _quantity, "insufficient ether");

        userRoundMintedAmount[_msgSender()][salesRound] += _quantity;

        _mint(_msgSender(), _quantity);
    }

    /// Methods
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for non existent token");

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        return
            bytes(prefixURI).length != 0
                ? string(
                    abi.encodePacked(prefixURI, _toString(tokenId), suffixURI)
                )
                : "";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}