// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Feetsies is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public MAX_SUPPLY = 4000;
    uint256 public MAX_PUBLIC_SUPPLY = 3250;
    uint256 public MAX_PUBLIC_MINT = 5;
    uint256 public MAX_WHITELIST_MINT = 1;
    uint256 public PUBLIC_SALE_PRICE = .003 ether;
    uint256 public WHITELIST_SALE_PRICE = 0 ether;

    string private baseTokenUri = "";
    string public hiddenTokenUri = "ipfs://QmXc2fGKp7ong2gqLYFuAMuUx4oz6K5rRtq3k2HP3VHTFq/unrevealed.json";

    bool public isRevealed;

    enum MintStage {
        PAUSED,
        PUBLIC,
        WHITELIST
    }

    MintStage public stage = MintStage.PAUSED;

    bytes32 private merkleRoot;

    mapping(address => uint256) public totalWhitelistMint;

    constructor() ERC721A("Feetsies", "FEET") {}

    function mint(uint256 _quantity) external payable {
        require(stage == MintStage.PUBLIC, "Public sale is not active yet");
        require(
            (totalSupply() + _quantity) <= MAX_PUBLIC_SUPPLY,
            "Beyond max public supply"
        );
        require(
            _quantity <= MAX_PUBLIC_MINT,
            "You can not mint more than max per transaction"
        );
        require(
            msg.value >= (PUBLIC_SALE_PRICE * _quantity),
            "Wrong mint price"
        );

        _safeMint(msg.sender, _quantity);
    }

    function whitelistMint(bytes32[] memory _merkleProof, uint256 _quantity)
        external
        payable
    {
        require(
            stage == MintStage.WHITELIST,
            "Whitelist sale is not active yet"
        );
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Beyond max supply");
        require(
            (totalWhitelistMint[msg.sender] + _quantity) <= MAX_WHITELIST_MINT,
            "You can not mint any more with this wallet"
        );
        require(
            msg.value >= (WHITELIST_SALE_PRICE * _quantity),
            "Wrong mint price"
        );
        //create leaf node
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, sender),
            "You are not whitelisted."
        );

        totalWhitelistMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function teamMint(address receiver, uint256 mintAmount) external onlyOwner {
        _safeMint(receiver, mintAmount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

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

        uint256 trueId = tokenId + 1;

        if (!isRevealed) {
            return hiddenTokenUri;
        }
        //string memory baseURI = _baseURI();
        return
            bytes(baseTokenUri).length > 0
                ? string(
                    abi.encodePacked(baseTokenUri, trueId.toString(), ".json")
                )
                : "";
    }

    function setTokenUri(string memory _baseTokenUri) external onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    function setPlaceHolderUri(string memory _hiddenTokenUri)
        external
        onlyOwner
    {
        hiddenTokenUri = _hiddenTokenUri;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function getMerkleRoot() external view returns (bytes32) {
        return merkleRoot;
    }

    function setMintStage(MintStage _stage) public onlyOwner {
        stage = _stage;
    }

    function setWhitelistSalePrice(uint256 newPrice) external onlyOwner {
        WHITELIST_SALE_PRICE = newPrice;
    }

    function setPublicSalePrice(uint256 newPrice) external onlyOwner {
        PUBLIC_SALE_PRICE = newPrice;
    }

    function setMaxPublicMint(uint256 amount) external onlyOwner {
        MAX_PUBLIC_MINT = amount;
    }

    function toggleReveal() external onlyOwner {
        isRevealed = !isRevealed;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Withdraw failed.");
    }
}