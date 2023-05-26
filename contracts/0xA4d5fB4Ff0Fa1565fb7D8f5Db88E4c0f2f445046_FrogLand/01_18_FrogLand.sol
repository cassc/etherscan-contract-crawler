// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

import '../interfaces/IOpenSeaCompatible.sol';
import '../interfaces/IFrogLand.sol';

contract FrogLand is Ownable, ERC721Enumerable, ReentrancyGuard, IFrogLand, IFrogLandAdmin, IOpenSeaCompatible {
    using Address for address;
    using Strings for uint256;
    using SafeMath for uint256;

    event PresaleActive(bool state);
    event SaleActive(bool state);
    event PresaleLimitChanged(uint256 limit);

    bool public saleIsActive;
    bool public presaleIsActive;

    uint256 public maxPurchaseQuantity;
    uint256 public maxMintableSupply;
    uint256 public maxAdminSupply;
    uint256 public MAX_TOKENS;
    uint256 public presaleLimit;
    bytes32 public presaleRoot;
    uint256 public price;

    uint256 private _adminMinted = 0;
    uint256 private _publicMinted = 0;

    string private _contractURI;
    string private _tokenBaseURI;
    string private _tokenRevealedBaseURI;

    mapping(address => uint256) private _presaleClaimedCount;

    constructor(
        string memory name,
        string memory symbol,
        bytes32 merkleRoot
    ) ERC721(name, symbol) {
        presaleRoot = merkleRoot;

        saleIsActive = false;
        presaleIsActive = false;

        presaleLimit = 7;

        //80000000000000000  0.08 eth
        price = 80000000000000000;
        maxPurchaseQuantity = 20;
        MAX_TOKENS = 10000;
        maxMintableSupply = 9750;
        maxAdminSupply = 250;

        _contractURI = 'https://froglandavatars.blob.core.windows.net/avatars/dist/opensea.json';
        _tokenBaseURI = 'ipfs://QmfWCVpwo5PbjXsEJH3WiCbv5TAyJFs191YLjX5J6YeKFy';
        _tokenRevealedBaseURI = '';
    }

    // IOpenSeaCompatible

    function contractURI() public view override returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory contract_uri) external override onlyOwner {
        _contractURI = contract_uri;
    }

    // IFrogLandMetadata

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'Token does not exist');

        string memory revealedBaseURI = _tokenRevealedBaseURI;
        return
            bytes(revealedBaseURI).length > 0
                ? string(abi.encodePacked(revealedBaseURI, tokenId.toString()))
                : _tokenBaseURI;
    }

    // IFrogLand

    function canMint(uint256 quantity) public view override returns (bool) {
        require(saleIsActive, "sale hasn't started");
        require(!presaleIsActive, 'only presale');
        require(totalSupply().add(quantity) <= MAX_TOKENS, 'quantity exceeds supply');
        require(_publicMinted.add(quantity) <= maxMintableSupply, 'quantity exceeds mintable');
        require(quantity <= maxPurchaseQuantity, 'quantity exceeds max');

        return true;
    }

    function canMintPresale(
        address owner,
        uint256 quantity,
        bytes32[] calldata proof
    ) public view override returns (bool) {
        require(!saleIsActive && presaleIsActive, "presale hasn't started");
        require(_verify(_leaf(owner), proof), 'invalid proof');
        require(totalSupply().add(quantity) <= MAX_TOKENS, 'quantity exceeds supply');
        require(_publicMinted.add(quantity) <= maxMintableSupply, 'quantity exceeds mintable');
        require(_presaleClaimedCount[owner].add(quantity) <= presaleLimit, 'quantity exceeds limit');

        return true;
    }

    function presaleMinted(address owner) external view override returns (uint256) {
        require(owner != address(0), 'black hole not allowed');
        return _presaleClaimedCount[owner];
    }

    function purchase(uint256 quantity) external payable override nonReentrant {
        require(canMint(quantity), 'cannot mint');
        require(msg.value >= price.mul(quantity), 'amount too low');

        for (uint256 i = 0; i < quantity; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < MAX_TOKENS) {
                _publicMinted += 1;
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function purchasePresale(uint256 quantity, bytes32[] calldata proof) external payable override nonReentrant {
        require(canMintPresale(msg.sender, quantity, proof), 'cannot mint presale');
        require(msg.value >= price.mul(quantity), 'amount too low');

        for (uint256 i = 0; i < quantity; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < MAX_TOKENS) {
                _publicMinted += 1;
                _presaleClaimedCount[msg.sender] += 1;
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    // IFrogLandAdmin

    function mintToAddress(uint256 quantity, address to) external override onlyOwner {
        require(totalSupply().add(quantity) <= MAX_TOKENS, 'quantity exceeds supply');
        require(_adminMinted.add(quantity) <= maxAdminSupply, 'quantity exceeds mintable');

        for (uint256 i = 0; i < quantity; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < MAX_TOKENS) {
                _adminMinted += 1;
                _safeMint(to, mintIndex);
            }
        }
    }

    function mintToAddresses(address[] calldata to) external override onlyOwner {
        require(totalSupply().add(to.length) <= MAX_TOKENS, 'quantity exceeds supply');
        require(_adminMinted.add(to.length) <= maxAdminSupply, 'quantity exceeds mintable');

        for (uint256 i = 0; i < to.length; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < MAX_TOKENS) {
                _adminMinted += 1;
                _safeMint(to[i], mintIndex);
            }
        }
    }

    function setBaseURI(string memory baseURI) external override onlyOwner {
        _tokenBaseURI = baseURI;
    }

    function setBaseURIRevealed(string memory baseURI) external override onlyOwner {
        _tokenRevealedBaseURI = baseURI;
    }

    function setPresaleLimit(uint256 limit) external override onlyOwner {
        presaleLimit = limit;
        emit PresaleLimitChanged(presaleLimit);
    }

    function setPresaleRoot(bytes32 merkleRoot) external override onlyOwner {
        presaleRoot = merkleRoot;
    }

    function togglePresaleIsActive() external override onlyOwner {
        presaleIsActive = !presaleIsActive;
        emit PresaleActive(presaleIsActive);
    }

    function toggleSaleIsActive() external override onlyOwner {
        saleIsActive = !saleIsActive;
        emit SaleActive(saleIsActive);
    }

    function withdraw() public override onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // _internal

    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProof.verify(proof, presaleRoot, leaf);
    }
}