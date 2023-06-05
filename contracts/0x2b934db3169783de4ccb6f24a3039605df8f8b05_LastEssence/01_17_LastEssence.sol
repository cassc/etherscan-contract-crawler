// SPDX-License-Identifier: MIT

pragma solidity >=0.8.13;

import {ERC721A} from "ERC721A.sol";
import {Ownable} from "Ownable.sol";
import {ReentrancyGuard} from "ReentrancyGuard.sol";
import {Strings} from "Strings.sol";
import {PaymentSplitter} from "PaymentSplitter.sol";
import {MerkleProof} from "MerkleProof.sol";

error SaleNotStarted();
error NotOnReservedList();
error AlreadyClaimed();
error QuantityOffLimits();
error MaxSupplyReached();
error InsufficientFunds();
error NonExistentTokenURI();

contract LastEssence is Ownable, ERC721A, ReentrancyGuard, PaymentSplitter {
    using Strings for uint256;

    uint256 public immutable maxSupply = 3444;
    uint256 public immutable reserveSupply = 2254;

    uint256 public maxTokensPerTx = 5;
    uint256 public price = 0.022 ether;
    uint256 public reserveSaleStart = 1654444800;
    uint256 public reserveSaleEnd = reserveSaleStart + 7 hours;
    uint256 public claimed;

    bool public revealed;

    bytes32 public merkleRoot;

    string private _baseTokenURI;
    string private notRevealedUri;

    mapping(address => bool) private reserveClaimed;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory _initNotRevealedUri,
        uint256 maxBatchSize_,
        address[] memory payees_,
        uint256[] memory shares_
    ) ERC721A(name_, symbol_, maxBatchSize_) PaymentSplitter(payees_, shares_) {
        reserveForTeam();
        setNotRevealedURI(_initNotRevealedUri);
    }

    function reserveSaleMint(uint256 quantity, bytes32[] memory proof)
        external
        payable
    {
        // Validation
        if (
            block.timestamp < reserveSaleStart ||
            block.timestamp > reserveSaleEnd
        ) revert SaleNotStarted();
        if (
            !(
                MerkleProof.verify(
                    proof,
                    merkleRoot,
                    keccak256(abi.encodePacked(msg.sender))
                )
            )
        ) revert NotOnReservedList();
        if (totalSupply() + quantity > maxSupply || claimed + 1 > reserveSupply)
            revert MaxSupplyReached();
        if (quantity == 0 || quantity > maxTokensPerTx)
            revert QuantityOffLimits();
        if (reserveClaimed[msg.sender]) revert AlreadyClaimed();
        // State changes
        reserveClaimed[msg.sender] = true;
        claimed++;
        // Interactions
        // if public supply is minted, only one per address can be minted
        if (totalSupply() + quantity > maxSupply - reserveSupply + claimed) {
            if (msg.value < price) revert InsufficientFunds();
            _safeMint(msg.sender, 1);
            // if msg.value is for larger quantity, send the rest back
            if (msg.value > price) {
                payable(msg.sender).transfer(msg.value - price);
            }
        } else {
            if (msg.value != price * quantity) revert InsufficientFunds();
            _safeMint(msg.sender, quantity);
        }
    }

    function publicSaleMint(uint256 quantity) external payable {
        // Validation
        if (block.timestamp < reserveSaleStart) revert SaleNotStarted();
        if (msg.value != price * quantity) revert InsufficientFunds();
        if (quantity == 0 || quantity > maxTokensPerTx)
            revert QuantityOffLimits();
        // check if reserve sale period is over
        if (block.timestamp > reserveSaleEnd) {
            // reserve sale ended so all available for public
            if (totalSupply() + quantity > maxSupply) revert MaxSupplyReached();
        } else {
            // reserve sale open so limited supply for public
            if (totalSupply() + quantity > maxSupply - reserveSupply + claimed)
                revert MaxSupplyReached();
        }
        // Interactions
        _safeMint(msg.sender, quantity);
    }

    function isSaleOpen() public view returns (bool) {
        if (block.timestamp < reserveSaleStart) {
            return false;
        }
        return true;
    }

    function isReserveSaleOver() public view returns (bool) {
        if (block.timestamp < reserveSaleEnd) {
            return false;
        }
        return true;
    }

    function isAlreadyClaimed(address user) public view returns (bool) {
        if (reserveClaimed[user]) {
            return true;
        }
        return false;
    }

    function airdrop(address _to, uint256 quantity) external onlyOwner {
        if (totalSupply() + quantity > maxSupply) revert MaxSupplyReached();
        _safeMint(_to, quantity);
    }

    function setReserveSaleStart(uint256 _timestamp) external onlyOwner {
        reserveSaleStart = _timestamp;
    }

    function setReserveSaleEnd(uint256 _timestamp) external onlyOwner {
        reserveSaleEnd = _timestamp;
    }

    function setPrice(uint64 _price) external onlyOwner {
        price = _price;
    }

    function setMaxTokensPerTx(uint256 _maxTokensPerTx) external onlyOwner {
        maxTokensPerTx = _maxTokensPerTx;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function reserveForTeam() internal {
        _safeMint(0x6Cef9181747B2139CE4410a123997146e247DeBe, 5);
        _safeMint(0x0010F22e270Ea56eAA66Ca9D801F516A0853aaA6, 5);
        _safeMint(0xe9F37DCa944c8Bb9b71A0ee28202CED03390136B, 5);
        _safeMint(0x83882460157B1a14EA50A7e47a992aF0BEAb9331, 5);
        _safeMint(0x97956FCcEF9AFFC8fFb0D2a6C35a3b8D108F048b, 5);
        _safeMint(0x044Ab09cFd9312695F390AE1689C4661454fB64B, 5);
        _safeMint(0xE576C0f771BC3B4E5eabCCb425Ae533D9e00E953, 5);
        _safeMint(0x2bDAC6F14d46bd7e4e12d4865e92183DA34c8a99, 5);
        _safeMint(0xe5E334D0BB07B54B8f308871B793222186d15BCa, 5);
        _safeMint(0xbd4886Ab438a530a9f51fbc07Cb78597Eaf79eCF, 5);
        _safeMint(0x020cA4Aa1A32814a80Bde4c0ED67e1495836d27f, 5);
        _safeMint(0xec7d9C4462Cc30B102dF9e8Dfb8dA85a28C993EA, 45);
    }

    function setOwnersExplicit(uint256 quantity)
        external
        onlyOwner
        nonReentrant
    {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnerOfToken(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert NonExistentTokenURI();
        if (revealed == false) {
            return notRevealedUri;
        }
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }
}