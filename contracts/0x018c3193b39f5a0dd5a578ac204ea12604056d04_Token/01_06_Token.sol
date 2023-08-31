// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";

contract Token is ERC721A, Ownable {
    enum Status {
        Waiting,
        Started,
        Finished
    }

    Status public status;
    string public baseURI;
    uint32 public freeMinted;

    // moving all configs under a 256 bit space to save cost
    struct Config {
        uint64 publicPrice;
        uint16 maxFreeSupply;
        uint16 maxSupply;
    }
    Config public config;

    // EVENTS
    event Minted(address minter, uint256 amount);
    event BaseURIChanged(string newBaseURI);
    event StatusChanged(Status status);

    // CONSTRUCTOR
    constructor(string memory initBaseURI) ERC721A("Skeleton Empire", "SKE") {
        baseURI = initBaseURI;
        config.publicPrice = 0.0006 ether;
        config.maxFreeSupply = 1000;
        config.maxSupply = 2222;
    }

    // MODIFIERS
    function mintComplianceBase(uint256 _qunatity) public view {
        require(
            totalSupply() + _qunatity <= config.maxSupply,
            "Exceed max supply"
        );
    }

    modifier mintComplianceForPublic(uint256 _qunatity) {
        mintComplianceBase(_qunatity);
        require(status == Status.Started, "Sale is not started");
        _;
    }

    modifier OnlyUser() {
        require(tx.origin == msg.sender, "Deny contract call.");
        _;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function maxFreeSupply() public view returns (uint16) {
        return config.maxFreeSupply;
    }

    // MINTING LOGICS
    function mintSkeleton(uint256 quantity)
        external
        payable
        OnlyUser
        mintComplianceForPublic(quantity)
    {
        uint32 minted = uint32(_numberMinted(msg.sender));
        uint32 freeAmount = 0;

        if (minted == 0 && (freeMinted + 1 <= config.maxFreeSupply)) {
            freeAmount = 1;
            freeMinted = freeMinted + 1;
        }

        _safeMint(msg.sender, quantity);

        uint256 requireValue = (quantity - freeAmount) * config.publicPrice;
        refundIfOver(requireValue);

        emit Minted(msg.sender, quantity);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Insufficient fund");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function numberMintedForPublic(address owner)
        public
        view
        returns (uint256)
    {
        return _numberMinted(owner) - uint256(_getAux(owner));
    }

    // SETTERS
    function setStatus(Status _status) external onlyOwner {
        status = _status;
        emit StatusChanged(status);
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURIChanged(newBaseURI);
    }

    function setPrice(uint256 _publicPrice)
        public
        onlyOwner
    {
        config.publicPrice = uint64(_publicPrice);
    }

    function setMaxSupply(uint256 _maxFreeSupply, uint256 _maxSupply) public onlyOwner {
        config.maxFreeSupply = uint16(_maxFreeSupply);
        config.maxSupply = uint16(_maxSupply);
    }

    // WITHDRAW
    function withdraw(address payable recipient) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "it`s over");
    }
}