// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
--<--< made with love by <--<[email protected]
<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
--<--<- leftover photos -<--<[email protected]
<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
--< https://leftover.photos [email protected]
<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
<3<3<3<3 --<--<--<[email protected] <3<3<3<3<3
<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721Leftoverphotos.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract Leftoverphotos is Ownable, ERC721Leftoverphotos, ReentrancyGuard {
    
    // token metadata uri, set by method
    string private _baseTokenURI;

    // contract metadata uri, set by method
    string private _baseContractURI;
    
    // price per token, set to default in code
    uint256 public pricePublic = .0111 ether;

    // price per token, set to default in code
    uint256 public priceReserved = 0 ether;
    
    // status booleans for public mint
    bool public isPublicMintActive = false;

    // status booleans for private mint
    bool public isReservedMintActive = false;
    
    // total tokens in reserve right now for nicelist
    uint256 private reservedTokens = 0;

    // storage of reserved tokens per address
    mapping (address => uint256) private _reserved;

    // constructor method
    constructor(
        uint256 collectionSize_,
        uint256 maxBatchSize_
    ) ERC721Leftoverphotos(
        "Leftover Photos",
        "LEFTOVERPHOTO",
        collectionSize_,
        maxBatchSize_
    ) {}

    // check if the sender is the user
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Caller is another contract");
        _;
    }

    // returns the URI location of the NFT metadata at a URL or IPFS
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // sets the URI location of the NFT metadata
    // ex. https://example.com/metadata/ resolves to https://example.com/metadata/1
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // For OpenSea to automate reading of your contract data
    // https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() public view returns (string memory) {
        return _baseContractURI;
    }

    // sets the URI location of the NFT metadata
    // https://example.com/contract-metadata
    function setContractURI(string calldata newContractURI) external onlyOwner {
        _baseContractURI = newContractURI;
    }
    
    // returns the total possibel NFTs in the collection
    function getCollectionSize() public view returns (uint256) {
        return collectionSize;
    }

    // returns the maximum NFTs allowed to be minted in 1 batch
    function getMaxBatchSize() public view returns (uint256) {
        return maxBatchSize;
    }

    // turns the public mint on and off
    // mint allows minting at the price
    function flipPublicMintState() public onlyOwner {
        isPublicMintActive = !isPublicMintActive;
    }

    // turns the reserved mint on and off
    // reserved mint allows minting only for reserved addresses
    function flipReservedMintState() public onlyOwner {
        isReservedMintActive = !isReservedMintActive;
    }

    // function to handle the price
    // if the free mint is active the price is 0
    // otherwise the price is the price
    function setPricePublic(uint256 newPrice) public onlyOwner {
        pricePublic = newPrice;
    }

    // function to handle the price
    // if the free mint is active the price is 0
    // otherwise the price is the price
    function setPriceReserved(uint256 newPrice) public onlyOwner {
        priceReserved = newPrice;
    }

    // checks how many an specific address minted
    function numberMinted(address _addr) public view returns (uint256) {
        return _numberMinted(_addr);
    }

    // see who owns which token
    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return ownershipOf(tokenId);
    }

    // withdraw from contract
    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    // ADMIN MINT
    // mints to a wallet, owner only
    function adminMint(address _addr, uint256 _quantity) public onlyOwner {
        require(
            totalSupply() + _quantity <= collectionSize,
            "Max supply on admin mint"
        );
        _safeMint(_addr, _quantity);
    }

    // PUBLIC MINT
    function mint(uint256 quantity) external payable callerIsUser {
        require(
            isPublicMintActive,
            "Public mint not active"
        );
        require(
            msg.value >= (pricePublic * quantity),
            "Price not enough for public mint"
        );
        require(
            totalSupply() + quantity <= collectionSize,
            "Max supply on public mint"
        );
        _safeMint(msg.sender, quantity);
    }

    // RESERVED MINT
    function reservedMint(uint256 quantity) external payable callerIsUser {
        require(
            isReservedMintActive,
            "Reserved mint not active"
        );
        // limits total 1 wallet can mint in reserved mint to total in 1 batch
        require(
            numberMinted(msg.sender) + quantity <= maxBatchSize,
            "Exceeds limit in reserved mint"
        );
        require(
            msg.value >= (priceReserved * quantity),
            "Price not enough for reserve mint"
        );
        require(
            totalSupply() + quantity <= collectionSize,
            "Max supply on reserved mint"
        );
        require(
            _reserved[msg.sender] >= quantity,
            "You do not have that many reserved tokens"
        );

        reservedTokens -= quantity;
        _reserved[msg.sender] -= quantity;

        _safeMint(msg.sender, quantity);
    }

    // adds reserved tokens for a single address
    function reservedAdd(address _addr, uint256 _quantity) external onlyOwner {
        _reserved[_addr] += _quantity;
        reservedTokens += _quantity;
    }

    // adds reserved tokens for multiple addresses
    function reservedAddBatch(address[] calldata _addrs, uint256[] calldata _quantity) external onlyOwner {
        uint size = _addrs.length;
        uint256 total = 0;
        require(
            _addrs.length == _quantity.length,
            "Array mismatch"
        );
        for (uint256 i = 0; i < size; i++) {
            _reserved[_addrs[i]] += _quantity[i];
            total += _quantity[i];
        }
        reservedTokens += total;
    }

    // removed reserved tokens from an address
    function reservedRemove(address _addr) external onlyOwner {
         reservedTokens -= _reserved[_addr];
         _reserved[_addr] = 0;
    }

    // lets a wallet check their reserve status
    function reservedCheck() public view callerIsUser returns (uint256) {
        return _reserved[msg.sender];
    }

    // lets the owner check any address
    function reservedCheckOwner(address _addr) view external onlyOwner returns (uint256) {
        return _reserved[_addr];
    }

}