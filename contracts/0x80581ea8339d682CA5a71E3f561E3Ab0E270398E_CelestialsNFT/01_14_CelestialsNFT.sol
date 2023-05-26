// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721A.sol";

contract CelestialsNFT is Ownable, ERC721A, ReentrancyGuard {
    using Strings for uint256;

    string private baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 0.085 ether;
    uint256 public constant maxSupply = 7777; // how many NFTs total. This is hardcoded by design and not modifiable at runtime
    uint256 private constant constMaxBatchSize = 100;  // this is purely for the requirements of this version of ERC721a: An unrealistic upper bound to keep the running time in check
    uint256 public maxMintPerAddress = 20; // max amount mintable per address
    uint256 public presaleStartDate = 1644138000; // initial date/time in unix epoch seconds - https://www.epochconverter.com/
    uint256 public presaleDuration = 27 hours;

    bool public paused = false; // allows pausing minting if needed

    bytes32 private whitelistRoot; // root of the Merkle tree that validates whitelisted addresses

    constructor(
        string memory _initBaseURI,
        uint256 _presaleStart,
        uint256 _presaleDuration,
        bytes32 _whitelistRoot
    ) ERC721A ("Celestials ETH", "CELESTIAL", constMaxBatchSize, maxSupply) {
        setBaseURI(_initBaseURI);
        setPresaleStartDate(_presaleStart);
        setPresaleDuration(_presaleDuration);
        setWhitelistRoot(_whitelistRoot);
    }

    // public mint function, used during general sale and also by the owner at any time
    function mint(uint256 _mintAmount) public payable {
        require(!paused, "Contract is paused");

        uint256 presaleEndDate = presaleStartDate + presaleDuration;
        bool onlyWhitelistedCanMint = (block.timestamp >= presaleStartDate &&
            block.timestamp < presaleEndDate);
        bool onlyOwnerCanMint = (block.timestamp < presaleStartDate);

        require(_mintAmount > 0, "Mint amount required >= 1");

        require(totalSupply() + _mintAmount <= maxSupply, "Sold out");

        if (msg.sender != owner()) {
            require(!onlyOwnerCanMint, "Minting period not open yet");
            require(
                !onlyWhitelistedCanMint,
                "Presale is active: use mintPresale()"
            );

            uint256 ownerMintedCount = uint256(_numberMinted(msg.sender));

            require(
                ownerMintedCount + _mintAmount <= maxMintPerAddress,
                "Max mint amount per address exceeded"
            );
            require(msg.value >= cost * _mintAmount, "Insufficient funds.");
        }

        _safeMint(msg.sender, _mintAmount);
    }

    // mintPresale(): This function to be called only during the presale period.
    //
    // It requires external data to validate that the address is whitelisted and allowed
    // to mint a certain amount.
    //
    // This data comes from a backend server that stores key-value pairs where the key
    // is the address and the value is a combined {index, merkleProof, amountReserved} dict
    // This is handled by the minting dapp on the frontend
    function mintPresale(
        uint256 index,
        bytes32[] calldata merkleProof,
        uint256 amountReserved,
        uint256 amountToBuy
    ) external payable {
        require(!paused, "Contract is paused");
        uint256 presaleEndDate = presaleStartDate + presaleDuration;
        bool onlyWhitelistedCanMint = (block.timestamp >= presaleStartDate &&
            block.timestamp < presaleEndDate);

        require(
            onlyWhitelistedCanMint,
            "Not currently during presale, use mint()"
        );

        // By default you cannot mint for free during the whitelist :)
        bool mintsForFree = false;

        bytes32 node = keccak256(
            abi.encodePacked(index, msg.sender, amountReserved)
        );

        // This check here makes sure that
        // 1. only whitelisted addresses can mint and
        // 2. nobody can mint more than they're allotted (amountReserved)
        // because it's all concatenated and checked against the Merkle tree as a single value
        require(
            MerkleProof.verify(merkleProof, whitelistRoot, node),
            "MerkleDistributor: Invalid proof"
        );

        // amountReserved >= 100 means that the address can mint for free.
        // How many? amountReserved / 100. So 200 = 2 free mints, 100 = 1 free mint
        //
        // This is a way of encoding 2 separate parameters into a single integer number:
        // 1. the number they can mint at presale and 2. whether they can do so for free
        //
        // The main limitation of this is that you can't combine whitelisting for paid
        // mints and whitelisting for free mints for the same address. A second address
        // would be required for the same person to have access to both options, paid and free
        if (amountReserved >= 100) {
            amountReserved = amountReserved / 100;
            mintsForFree = true;
        }

        require(
            !(_numberMinted(msg.sender) >= amountReserved),
            "Max presale mint amount exceeded"
        );

        address account = msg.sender;

        uint256 resultingNumber = _numberMinted(account) + amountToBuy;

        require(
            resultingNumber <= amountReserved,
            "Attempting to buy too many"
        );

        if (!mintsForFree) {
            require(msg.value >= cost * amountToBuy, "Insufficient funds.");
        }

        require(
            totalSupply() + amountToBuy <= maxSupply,
            "Sold out"
        );

        _safeMint(account, amountToBuy);
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

        string memory currentBaseURI = baseURI;
        uint256 artworkNumber = tokenId + 1;

        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        artworkNumber.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function getPrice(uint256 amountToBuy) public view returns (uint256) {
        return amountToBuy * cost;
    }

    function getWhitelistRoot() public view onlyOwner returns (bytes32) {
        return whitelistRoot;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setMaxMintPerAddress(uint256 _maxMintPerAddress) public onlyOwner {
        maxMintPerAddress = _maxMintPerAddress;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setPresaleStartDate(uint256 _presaleStart) public onlyOwner {
        presaleStartDate = _presaleStart;
    }

    function setPresaleDuration(uint256 _presaleDuration) public onlyOwner {
        presaleDuration = _presaleDuration;
    }

    function setWhitelistRoot(bytes32 _whitelistRoot) public onlyOwner {
        whitelistRoot = _whitelistRoot;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}