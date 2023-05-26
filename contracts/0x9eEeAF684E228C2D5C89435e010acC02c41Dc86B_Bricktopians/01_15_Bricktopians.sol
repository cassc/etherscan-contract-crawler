// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Bricktopians is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using ECDSA for bytes32;

    string private _baseTokenURI;

    string public provenanceHash;

    uint256 public maxSupply = 9999;
    uint256 public maxPresale = 9000;

    mapping(address => bool) private _usedNonces;
    address private _signerAddress;

    uint256 public price = 0.08 ether;

    bool public saleLive = false;
    bool public presaleLive = false;
    bool public saleX2Live = false;

    constructor() ERC721("Bricktopians", "BTP") {}

    function publicsaleBuy(uint256 qty) external payable {
        require(saleLive, "sale is not live");
        require(qty <= 10, "no more than 10");
        require(totalSupply() + qty <= maxSupply, "out of stock");
        require(price * qty == msg.value, "exact amount needed");
        require(!_usedNonces[msg.sender], "nonce already used");
        for (uint256 i = 0; i < qty; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function publicsaleBuyX2(uint256 qty) external payable {
        require(saleLive, "sale is not live");
        require(qty <= 10, "no more than 10");
        require(totalSupply() + qty <= maxSupply, "out of stock");
        require(price * qty == msg.value, "exact amount needed");
        for (uint256 i = 0; i < qty; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function presaleBuy(
        bytes memory sig,
        uint256 qty,
        uint256 limit
    ) external payable nonReentrant {
        require(presaleLive, "presale is not live");
        require(
            matchAddresSigner(hashTransactionEIP191(msg.sender, limit), sig),
            "no direct minting"
        );
        require(qty <= limit, "no more than allocated limit");
        require(qty <= 10, "no more than 10");
        require(totalSupply() + qty <= maxPresale, "presale supply reached");
        require(price * qty == msg.value, "exact amount needed");
        require(!_usedNonces[msg.sender], "nonce already used");

        _usedNonces[msg.sender] = true;
        for (uint256 i = 0; i < qty; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function adminMint(uint256 qty, address to) public onlyOwner {
        require(qty > 0, "minimum 1 token");
        require(totalSupply() + qty <= maxSupply, "admin supply reached");
        for (uint256 i = 0; i < qty; i++) {
            _safeMint(to, totalSupply() + 1);
        }
    }

    function setSignerAddress(address addr) external onlyOwner {
        _signerAddress = addr;
    }

    function getSignatureAddress(bytes32 message, bytes memory signature)
        public
        pure
        returns (address)
    {
        assert(signature.length == 65);
        uint8 v;
        bytes32 r;
        bytes32 s;
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        return ecrecover(message, v, r, s);
    }

    function hashTransactionEIP191(address sender, uint256 limit)
        public
        pure
        returns (bytes32)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                hashTransaction(sender, limit)
            )
        );
        return hash;
    }

    function hashTransaction(address sender, uint256 limit)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(sender, limit));
    }

    function matchAddresSigner(bytes32 hash, bytes memory signature)
        private
        view
        returns (bool)
    {
        return _signerAddress == getSignatureAddress(hash, signature);
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function burn(uint256 tokenId) public virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    function isApprovedOrOwner(address _spender, uint256 _tokenId)
        external
        view
        returns (bool)
    {
        return _isApprovedOrOwner(_spender, _tokenId);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            string(
                abi.encodePacked(_baseTokenURI, _tokenId.toString(), ".json")
            );
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseTokenURI = newBaseURI;
    }

	function withdrawEarnings() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

    function presaleOnOff() external onlyOwner {
        presaleLive = !presaleLive;
    }

    function publicSaleOnOff() external onlyOwner {
        saleLive = !saleLive;
    }

    function publicSaleX2OnOff() external onlyOwner {
        saleX2Live = !saleX2Live;
    }

    function isPresaleLive() public view returns (bool) {
        return presaleLive;
    }

    function isPublicSaleLive() public view returns (bool) {
        return saleLive;
    }

    function getPrice() public view returns (uint256) {
        return price;
    }

    function changePrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function changeMaxPresale(uint256 _newMaxPresale) external onlyOwner {
        maxPresale = _newMaxPresale;
    }

    function setProvenanceHash(string memory _provenanceHash)
        external
        onlyOwner
    {
        bytes memory tempEmptyStringTest = bytes(provenanceHash);
        require(tempEmptyStringTest.length == 0, "provenance hash already set");
        provenanceHash = _provenanceHash;
    }

    function decreaseMaxSupply(uint256 newMaxSupply) external onlyOwner {
        require(newMaxSupply < maxSupply, "decrease only");
        maxSupply = newMaxSupply;
    }
}