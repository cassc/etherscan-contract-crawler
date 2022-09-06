// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./ERC721A.sol";
import "./lib/signed.sol";

contract MarshallInuFightClub is
    ERC721A,
    Pausable,
    Ownable,
    ReentrancyGuard,
    Signed
{
    using Strings for uint256;
    using SafeMath for uint256;

    string private baseURI;
    string private baseExtension;
    string private unrevealURI;
    uint256 public mintPrice = 0.077 ether;
    uint256 public maxPublic = 10;
    uint256 public maxPrivateVIP = 10;
    uint256 public maxPrivate = 4;
    bool public isReveal = false;
    uint256 public privateSaleStart;
    uint256 public privateSaleEnd;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor() ERC721A("Marshall Inu Fight Club", "MRIFC", 10, 4444) {
        setPrivateSaleTime(1658224800, 1658275200); // 19 July 6AM tp 19 July 8PM
    }

    mapping(address => uint256) userMintBalance; // user addresss => mint Balance
    mapping(address => uint256) userMintWLBalance; // user addresss => mint Balance

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
    function mint(
        uint8 amount,
        bytes calldata signature,
        bool isVIP
    ) external payable callerIsUser nonReentrant whenNotPaused {
        require(block.timestamp >= privateSaleStart, "Minting not start");
        require(amount > 0, "Must mint minimum 1");
        require(msg.value >= amount * mintPrice, "Incorrect payable amount");
        require(amount <= maxBatchSize, "Mint limit per tx reached");

        uint256 supply = totalSupply();

        require(supply + amount <= collectionSize, "Max supply reached");

        if (block.timestamp <= privateSaleEnd) {
            if (!isVIP) {
                require(
                    userMintWLBalance[_msgSender()].add(amount) <= maxPrivate,
                    "Limit per address reached"
                );
                verifySignature(signature);
            } else {
                require(
                    userMintWLBalance[_msgSender()].add(amount) <=
                        maxPrivateVIP,
                    "Limit per address reached"
                );
                verifySignatureVIP(signature, isVIP);
            }
            _safeMint(msg.sender, amount);
            userMintWLBalance[_msgSender()] = userMintWLBalance[_msgSender()]
                .add(amount);
        } else {
            require(
                userMintBalance[_msgSender()].add(amount) <= maxPublic,
                "Limit per address reached"
            );
            _safeMint(msg.sender, amount);
            userMintBalance[_msgSender()] = userMintBalance[_msgSender()].add(
                amount
            );
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

    function setBaseURI(string calldata newURI) external onlyOwner {
        baseURI = newURI;
    }

    function setUnrevealURI(string calldata newURI) external onlyOwner {
        unrevealURI = newURI;
    }

    function setIsReveal(bool _isReveal) external onlyOwner {
        isReveal = _isReveal;
    }

    function setPrivateSaleTime(
        uint256 _privateSaleStart,
        uint256 _privateSaleEnd
    ) public onlyOwner {
        require(
            _privateSaleEnd > _privateSaleStart,
            "end time must be greater than start time"
        );
        privateSaleStart = _privateSaleStart;
        privateSaleEnd = _privateSaleEnd;
    }

    function setMaxAddress(
        uint256 publicAmount,
        uint256 privateAmount,
        uint256 privateVIPAmount
    ) external onlyOwner {
        maxPublic = publicAmount;
        maxPrivate = privateAmount;
        maxPrivateVIP = privateVIPAmount;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function isPresale() public view returns (bool) {
        return
            privateSaleStart <= block.timestamp &&
            privateSaleEnd >= block.timestamp;
    }

    function isStartMinting() public view returns (bool) {
        if (paused()) return false;
        return privateSaleStart <= block.timestamp;
    }
}