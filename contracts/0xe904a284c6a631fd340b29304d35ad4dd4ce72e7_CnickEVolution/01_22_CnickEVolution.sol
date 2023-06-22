// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "erc721b/contracts/extensions/ERC721BPausable.sol";
import "erc721b/contracts/extensions/ERC721BStaticTokenURI.sol";
import "erc721b/contracts/extensions/ERC721BContractURIStorage.sol";

import "./lib/Treasury.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "erc721b/contracts/presets/ERC721BPresetStandard.sol";

contract CnickEVolution is
    Ownable,
    ERC721BPresetStandard,
    ERC721BPausable,
    ERC721BContractURIStorage,
    Treasury
{
    using Strings for uint256;
    enum SalePublicity {
        PRIVATE,
        PUBLIC
    }

    // EVENTS  *****************************************************
    event ReceivedEther(address indexed sender, uint256 indexed amount);
    event AllowlistSignerUpdated(address _signer);

    uint256 public constant MAX_SUPPLY = 500;
    uint256 public constant MAX_PER_WALLET = 10;
    uint256 public currentMaxSupply = 50;
    uint256 public mintPrice = 0.1 ether;
    SalePublicity public publicSale = SalePublicity.PRIVATE;

    address[] private mintPayees = [
        0xC1e227135D7115E40B589fF1a491cA8d1dE21E48, // Cnick
        0xBB11b7858BDdf9D6B3d9bdbcd4D579Ba9AC9741d, // Artist
        0xBa4491E278CA6cCDbA68749673dEF8A0112C1F8f // Dev
    ];

    uint256[] private mintShares = [77, 20, 3];

    bytes32 public merkleRoot;

    mapping(address => uint256) private walletMints;

    constructor(
        string memory name,
        string memory symbol,
        string memory contractUri,
        string memory baseUri,
        address[] memory operators
    )
        payable
        ERC721BPresetStandard(name, symbol)
        Treasury(mintPayees, mintShares)
    {
        _setContractURI(contractUri);
        _setBaseURI(baseUri);
        _pause();
        for (uint256 i = 0; i < operators.length; i++) {
            setApprovalForAll(operators[i], true);
        }
    }

    // External functions *****************************************************
    function setBaseTokenURI(string memory uri) external virtual onlyOwner {
        _setBaseURI(uri);
    }

    // Public functions *****************************************************

    function pause() public virtual onlyOwner {
        _pause();
    }

    function unpause() public virtual onlyOwner {
        _unpause();
    }

    function togglePublicSale() public virtual onlyOwner {
        if (publicSale == SalePublicity.PRIVATE)
            publicSale = SalePublicity.PUBLIC;
        else publicSale = SalePublicity.PRIVATE;
    }

    function setMintPrice(uint256 _newMintPrice) public onlyOwner {
        mintPrice = _newMintPrice;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setCurrentSupply(uint256 _currentMaxSupply) public onlyOwner {
        currentMaxSupply = _currentMaxSupply > MAX_SUPPLY
            ? MAX_SUPPLY
            : _currentMaxSupply;
    }

    function publicMint(uint256 numberOfTokens) public payable {
        require(!paused(), "Minting is paused");
        require(publicSale == SalePublicity.PUBLIC, "It is not public sale");

        require(
            (totalSupply() + numberOfTokens) <= currentMaxSupply,
            "Not enough CNEV remaining"
        );

        require(
            msg.value == mintPrice * numberOfTokens,
            "Incorrect payment amount"
        );

        require(
            (walletMints[msg.sender] + numberOfTokens) <= MAX_PER_WALLET,
            "Mint limit exceeded"
        );

        walletMints[msg.sender] = walletMints[msg.sender] + numberOfTokens;
        _safeMint(msg.sender, numberOfTokens);
    }

    function allowListMint(
        uint256 numberOfTokens,
        bytes32[] calldata _merkleProof
    ) public payable {
        require(!paused(), "Minting is paused");
        require(publicSale == SalePublicity.PRIVATE, "It is not private sale");

        require(
            msg.value == (mintPrice * numberOfTokens),
            "Incorrect payment amount"
        );
        require(
            (walletMints[msg.sender] + numberOfTokens) <= MAX_PER_WALLET,
            "Mint limit exceeded"
        );
        require(
            (totalSupply() + numberOfTokens) <= currentMaxSupply,
            "Not enough CNEV remaining"
        );

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof."
        );

        walletMints[msg.sender] = walletMints[msg.sender] + numberOfTokens;

        _safeMint(msg.sender, numberOfTokens);
    }

    function withdrawAll() public onlyOwner {
        require(address(this).balance > 0, "No balance to withdraw");

        for (uint256 i = 0; i < mintPayees.length; i++) {
            super.release(payable(super.payee(i)));
        }
    }

    // Public functions that are view *****************************************************

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(IERC721Metadata)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert NonExistentToken();

        string memory _tokenURI = tokenId.toString();
        string memory base = baseTokenURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }

        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return
            bytes(base).length > 0
                ? string(abi.encodePacked(base, tokenId.toString()))
                : "";
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override(ERC721B, IERC721)
        returns (address)
    {
        return super.ownerOf(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721B, ERC721BPresetStandard)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function totalSupply()
        public
        view
        virtual
        override(ERC721B)
        returns (uint256)
    {
        return super.totalSupply();
    }

    // Internal functions *****************************************************

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 amount
    ) internal virtual override(ERC721B, ERC721BPausable) {
        super._beforeTokenTransfers(from, to, startTokenId, amount);
    }

    function _exists(uint256 tokenId)
        internal
        view
        virtual
        override(ERC721B)
        returns (bool)
    {
        return super._exists(tokenId);
    }
}