// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "erc721a/contracts/ERC721A.sol";
import "./lib/signed.sol";

contract Skulourful is ERC721A, Pausable, Ownable, ReentrancyGuard, Signed {
    using Strings for uint256;
    using SafeMath for uint256;

    string private baseURI;
    string private baseExtension;
    string private unrevealURI;
    uint256 public mintPrice = 0.049 ether;
    uint256 public maxPublic = 2;
    uint256 public maxOG = 2;
    uint256 public maxSkulist = 2;
    bool public isReveal = false;
    uint256 public skulistSaleStart;
    uint256 public ogSaleStart;
    uint256 public publicSaleStart;
    uint256 public collectionSize = 6666;
    uint public maxBatchSize = 10;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor() ERC721A("Skulourful", "SKUL") {
        setSaleTime(1666807200, 1666808100, 1666814400);
    }

    mapping(address => uint256) public userMintBalance; // user addresss => mint Balance
    mapping(address => uint256) public userMintSkulistBalance; // user addresss => mint Balance
    mapping(address => uint256) public userMintOGBalance; // user addresss => mint Balance
    mapping(address => bool) public userOGFreeClaim; // user addresss => already claim free

    // WITHDRAW
    function withdraw() external payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    //PAUSE
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // MINTING
    function mint(uint8 amount)
        external
        payable
        callerIsUser
        nonReentrant
        whenNotPaused
    {
        require(block.timestamp >= publicSaleStart, "Minting not start");
        require(amount > 0, "Must mint minimum 1");
        require(msg.value >= amount * mintPrice, "Incorrect payable amount");
        require(amount <= maxBatchSize, "Mint limit per tx reached");
        require(
            userMintBalance[msg.sender].add(amount) <= maxPublic,
            "Limit per address reached"
        );

        uint256 supply = totalSupply();
        require(supply + amount <= collectionSize, "Max supply reached");

        _safeMint(msg.sender, amount);
        userMintBalance[msg.sender] = userMintBalance[msg.sender].add(amount);
    }

    function mintPrivate(
        uint8 amount,
        bytes calldata signature,
        bool isOG
    ) external payable callerIsUser nonReentrant whenNotPaused {
        require(amount <= maxBatchSize, "Mint limit per tx reached");
        require(msg.value >= amount * mintPrice, "Incorrect payable amount");
        require(amount > 0, "Must mint minimum 1");

        uint256 supply = totalSupply();
        if (isOG) {
            require(block.timestamp >= ogSaleStart, "Minting for OG not start");

            verifySignatureOG(signature, isOG);
            if (userOGFreeClaim[msg.sender] == false) {
                if (supply.add(1) <= collectionSize) {
                    _safeMint(msg.sender, 1);
                    supply = supply.add(1);
                    userOGFreeClaim[msg.sender] = true;
                }
            }
            require(supply.add(amount) <= collectionSize, "Max supply reached");
            require(
                userMintOGBalance[msg.sender].add(amount) <= maxOG,
                "Max Limit for OG reached"
            );

            _safeMint(msg.sender, amount);
            userMintOGBalance[msg.sender] = userMintOGBalance[msg.sender].add(
                amount
            );
        } else {
            require(
                block.timestamp >= skulistSaleStart,
                "Minting for Skulist not start"
            );
            verifySignature(signature);
            require(supply.add(amount) <= collectionSize, "Max supply reached");
            require(
                userMintSkulistBalance[msg.sender].add(amount) <= maxSkulist,
                "Max Limit for Skulist reached"
            );

            _safeMint(msg.sender, amount);
            userMintSkulistBalance[msg.sender] = userMintSkulistBalance[
                msg.sender
            ].add(amount);
        }
    }

    function mintTo(uint256[] calldata quantity, address[] calldata recipient)
        external
        payable
        onlyOwner
    {
        require(
            quantity.length == recipient.length,
            "Must provide equal quantities and recipients"
        );

        uint256 totalQuantity;
        uint256 supply = totalSupply();
        for (uint256 i; i < quantity.length; ++i) {
            totalQuantity += quantity[i];
        }
        require(
            supply + totalQuantity <= collectionSize,
            "Mint/order exceeds supply"
        );
        delete totalQuantity;

        for (uint256 i; i < recipient.length; ++i) {
            _safeMint(recipient[i], quantity[i]);
        }
    }

    // URL MATTER
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(tokenId > 0, "ERC721Metadata: Nonexistent token");
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");

        if (!isReveal) {
            return unrevealURI;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function setBaseURI(string calldata newURI, string calldata newExtension)
        external
        onlyOwner
    {
        baseURI = newURI;
        baseExtension = newExtension;
    }

    function setUnrevealURI(string calldata newURI) external onlyOwner {
        unrevealURI = newURI;
    }

    function setIsReveal(bool _isReveal) external onlyOwner {
        isReveal = _isReveal;
    }

    //owner function
    function setSaleTime(
        uint256 _ogSaleStart,
        uint256 _skulistSaleStart,
        uint256 _publicSaleStart
    ) public onlyOwner {
        ogSaleStart = _ogSaleStart;
        skulistSaleStart = _skulistSaleStart;
        publicSaleStart = _publicSaleStart;
    }

    function setMaxAddress(
        uint256 publicAmount,
        uint256 privateSkulistAmount,
        uint256 privateOGAmount
    ) external onlyOwner {
        maxPublic = publicAmount;
        maxSkulist = privateSkulistAmount;
        maxOG = privateOGAmount;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setCollectionSize(uint256 _newCollectionSize) external onlyOwner {
        collectionSize = _newCollectionSize;
    }

    //view function
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function isPresale() public view returns (bool) {
        return block.timestamp <= publicSaleStart;
    }

    function isStartMinting() public view returns (bool) {
        if (paused()) return false;
        return ogSaleStart <= block.timestamp;
    }

    //start token id
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}