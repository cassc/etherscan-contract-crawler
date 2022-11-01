// SPDX-License-Identifier: MIT


pragma solidity ^0.8.9;

import "Ownable.sol";
import "ReentrancyGuard.sol";
import "ERC721A.sol";
import "Strings.sol";
import "MerkleProof.sol";



contract OxDarkSide is Ownable, ERC721A, ReentrancyGuard {
    uint256 public immutable maxPerWallet = 100;
    uint256 public immutable maxPerFreeMint = 1;
    uint256 public immutable freeMints = 150;

    uint256 public immutable devMints;
    uint256 public immutable maxPerTx;
    uint256 public immutable actualCollectionSize;

    uint256 public publicMintPrice = .01 ether;
    bool public publicSaleActive = false;
    bool public ogMintActive = false;

    bytes32 public merkleRoot;
    mapping(address => uint256) ogListAmount;
    mapping(address => uint256) amountMintedByDevs;

    constructor(uint256 maxBatchSize_, uint256 collectionSize_, uint256 amountForDevs_)
        ERC721A(
            "0xDarkSide",
            "0xDS",
            maxBatchSize_,
            collectionSize_
        )
    {
        maxPerTx = maxBatchSize_;
        actualCollectionSize = collectionSize_;
        devMints = amountForDevs_;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function publicSaleMint(uint256 quantity) external payable callerIsUser {
        require(
            totalSupply() + quantity <= collectionSize,
            "reached max supply"
        );
        require(
            walletQuantity(msg.sender) + quantity <= maxPerWallet,
            "can not mint this many"
        );
        require(quantity <= maxPerTx, "can not mint this many at one time");
        require(quantity * publicMintPrice == msg.value, "incorrect funds");
        require(publicSaleActive, "public sale has not begun yet");
        _safeMint(msg.sender, quantity);
    }

    function ogMint(uint256 quantity) external callerIsUser {
        require(
            totalSupply() + quantity <= freeMints,
            "there are no more OG mints!"
        );
        require(ogMintActive, "og mint is not currently active");
        require(ogListAmount[msg.sender] + quantity <= maxPerFreeMint, "you cant mint anymore og mints");

        ogListAmount[msg.sender]+=quantity;
        _safeMint(msg.sender, quantity);
    }


    function devMint(uint256 quantity) external onlyOwner {
        require(
            totalSupply() + quantity <= collectionSize,
            "too many already minted before dev mint, try minting less if contract isn't sold out"
        );
        require(amountMintedByDevs[msg.sender] + quantity <= devMints, "there are no more dev mints");
        amountMintedByDevs[msg.sender]+=quantity;
        _safeMint(msg.sender, quantity);
    }


    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setOwnersExplicit(uint256 quantity)
        external
        onlyOwner
        nonReentrant
    {
        _setOwnersExplicit(quantity);
    }

    function walletQuantity(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    function batchTransferFrom(address _from, address _to, uint256[] memory _tokenIds) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }
    // Chef Jugg
    function togglePublicMint() public onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    function toggleOgMint() public onlyOwner {
        ogMintActive = !ogMintActive;
    }

    function setMerkleRoot(bytes32 _passedRoot) public onlyOwner {
        merkleRoot = _passedRoot;
    }
}