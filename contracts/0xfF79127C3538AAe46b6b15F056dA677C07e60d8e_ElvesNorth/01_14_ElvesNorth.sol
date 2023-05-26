//SPDX-License-Identifier: MIT

/*
    ________ _    _____________    ____  ______   ________  ________   _   ______  ____  ________  __
   / ____/ /| |  / / ____/ ___/   / __ \/ ____/  /_  __/ / / / ____/  / | / / __ \/ __ \/_  __/ / / /
  / __/ / / | | / / __/  \__ \   / / / / /_       / / / /_/ / __/    /  |/ / / / / /_/ / / / / /_/ /
 / /___/ /__| |/ / /___ ___/ /  / /_/ / __/      / / / __  / /___   / /|  / /_/ / _, _/ / / / __  /
/_____/_____/___/_____//____/   \____/_/        /_/ /_/ /_/_____/  /_/ |_/\____/_/ |_| /_/ /_/ /_/

Website: https://elvesofthenorth.com/
Twitter: https://twitter.com/EotnNFT

*/


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ElvesNorth is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_ELVES = 8888;
    uint256 public price = 0.04 ether;

    // Flag to Toggle Elves public and pre-sale
    bool public publicSaleOpen = false;
    bool public preSaleOpen = false;
    bool public lock = false;

    uint256 public maxMintPerTx = 6;
    uint256 public maxMintPerAddress = 8888;

    address private _signerAddress;
    mapping(address => uint256) public mintPerAddress;
    mapping(bytes32 => bool) private _usedHashes;
    string public prefixURI;
    string public commonURI;


    constructor() ERC721("Elves of the North", "ELVES") { }

    // Public Mint
    function mint(uint256 _count) public payable {
        require(publicSaleOpen, "public mint not open");
        require(_count <= maxMintPerTx, "max mint per tx");
        require(mintPerAddress[msg.sender] + _count <= maxMintPerAddress, "max mint per address");
        require(msg.value == _count * price, "invalid price");
        require(totalSupply() + _count <= MAX_ELVES, "max elves reached");

        mintPerAddress[msg.sender] += _count;
        for (uint256 i = 1; i <= _count; i++) {
            _safeMint(msg.sender, totalSupply()+1);
        }
        // totalSupply += _count;

    }

    // Presale Mint
    function mintWhitelist(
        uint256 _count,
        uint256 _maxCount,
        bytes memory _sig)
        external
        payable
    {
        require(preSaleOpen, "preSale mint not open");
        require(_count > 0 && _count <= _maxCount, "count invalid");
        require(totalSupply() + _count <= MAX_ELVES, "max elves reached");
        require(msg.value == (_count * price), "invalid eth sent");

        bytes32 hash = keccak256(abi.encode(_msgSender(), _maxCount));
        require(!_usedHashes[hash], "hash already used");
        require(matchSigner(hash, _sig), "invalid signer");

        _usedHashes[hash] = true;
        for (uint256 i = 1; i <= _count; i++) {
            _safeMint(msg.sender, totalSupply()+1);
        }
    }

    function matchSigner(bytes32 _hash, bytes memory _signature) private view returns(bool) {
        return _signerAddress == ECDSA.recover(ECDSA.toEthSignedMessageHash(_hash), _signature);
    }

    function isWhiteList(
        address _sender,
        uint256 _count,
        uint256 _maxCount,
        bytes calldata _sig
    ) public view returns(bool) {
        bytes32 _hash = keccak256(abi.encode(_sender, _maxCount));
        if (!matchSigner(_hash, _sig)) {
            return false;
        }
        if (_count > _maxCount) {
            return false;
        }
        if (_usedHashes[_hash]) {
            return false;
        }
        return true;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (bytes(commonURI).length != 0) {
            return commonURI;
        }
        return string(abi.encodePacked(prefixURI, tokenId.toString()));
    }

    // ************** Admin functions **************
    function togglePublicSale() external onlyOwner {
        publicSaleOpen = !publicSaleOpen;
    }

    function togglePreSale() external onlyOwner {
        preSaleOpen = !preSaleOpen;
    }

    function setMaxMintPerTx(uint256 _maxMint) external onlyOwner {
       maxMintPerTx = _maxMint;
    }

    function setMaxMintPerAddress(uint256 _maxMint) external onlyOwner {
        maxMintPerAddress = _maxMint;
    }

    function setSignerAddress(address _signer) external onlyOwner {
        require(_signer != address(0), "signer address zero");
        _signerAddress = _signer;
    }

    function withdraw(address payable _to) external onlyOwner {
        require(_to != address(0), "cannot withdraw to address(0)");
        require(address(this).balance > 0, "empty balance");
        _to.transfer(address(this).balance);
    }

    function gift(address _to, uint256 _count) external onlyOwner {
        require(_to != address(0), "cannot withdraw to address(0)");
        require(totalSupply() + _count <= MAX_ELVES, "max elves reached");

        for (uint256 i = 1; i <= _count; i++) {
            _safeMint(_to, totalSupply()+1);
        }
    }

    function lockBaseURI() external onlyOwner {
        require(!lock, "already locked");
        lock = true;
    }

    function setPrefixURI(string calldata _uri) external onlyOwner {
        require(!lock, "already locked");
        prefixURI = _uri;
        commonURI = '';
    }

    function setCommonURI(string calldata _uri) external onlyOwner {
        require(!lock, "already locked");
        commonURI = _uri;
        prefixURI = '';
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }
}