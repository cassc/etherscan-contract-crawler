// SPDX-License-Identifier: MIT

//This contract was developed by MetaLogics.io. Contact us at [email protected] for any queries

pragma solidity ^0.8.17;

import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./ERC4907.sol";
import "./ONFT721Core.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract CyberSyndicate is ERC4907("CyberSyndicate", "CSE"), DefaultOperatorFilterer, ERC2981, Ownable, ONFT721Core {
    using Counters for Counters.Counter;
    Counters.Counter internal tokenIdCounter;

    uint256 public totalSupply;

    string public imagesLink;
    bool public revealed = false;
    uint16 public constant maxSupply = 3333;
    uint256 public reservedNfts = 30;
    uint256 public buyActiveTime = 1682704800;
    uint8 public constant maxMintAmount = 20;
    uint256 public nftPrice = 0.09 * 1e18;

    string public notRevealedImagesLink;
    mapping(address => uint256) public userMints;

    // multiple WL configs
    mapping(address => uint256) public userMintsWL;
    mapping(bytes => bool) public _signatureUsed;
    mapping(uint256 => uint256) public maxMintPresales;
    mapping(uint256 => uint256) public itemPricePresales;
    uint256 public presaleActiveTime = 1682694000;

    constructor(
        uint256 _minGasToTransferAndStore,
        address _lzEndpoint
    ) ONFT721Core(_minGasToTransferAndStore, _lzEndpoint) {
        _setDefaultRoyalty(msg.sender, 500); // 5.00 %
        maxMintPresales[0] = 10;
        itemPricePresales[0] = 0.07 ether;
    }

    function _debitFrom(address _from, uint16, bytes memory, uint _tokenId) internal virtual override {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "ONFT721: not owner not approved");
        require(ERC721.ownerOf(_tokenId) == _from, "ONFT721: incorrect owner");
        _transfer(_from, address(this), _tokenId);
    }

    function _creditTo(uint16, address _toAddress, uint _tokenId) internal virtual override {
        require(!_exists(_tokenId) || (_exists(_tokenId) && ERC721.ownerOf(_tokenId) == address(this)));
        if (!_exists(_tokenId)) {
            _safeMint(_toAddress, _tokenId);
        } else {
            _transfer(address(this), _toAddress, _tokenId);
        }
    }

    function buyNft(uint256 _mintAmount) public payable {
        require(block.timestamp > buyActiveTime, "contract paused");
        require(_mintAmount > 0, "quantity > 0");
        require(numberMinted(msg.sender) + _mintAmount <= maxMintAmount, "max mint amount exceeded");
        require(tokenIdCounter.current() + _mintAmount + reservedNfts <= maxSupply, "limit exceeded");
        require(msg.value == nftPrice * _mintAmount, "low funds");

        mintNfts(msg.sender, _mintAmount);
    }

    function mintNfts(address mintTo, uint256 number) internal {
        for (uint i = 1; i <= number; i++) {
            tokenIdCounter.increment();
            uint256 newTokenId = tokenIdCounter.current();
            _safeMint(mintTo, newTokenId);
        }
        userMints[mintTo] += number;
        totalSupply += number;
    }

    function mintNftsWL(address mintTo, uint256 number) internal {
        for (uint i = 1; i <= number; i++) {
            tokenIdCounter.increment();
            uint256 newTokenId = tokenIdCounter.current();
            _safeMint(mintTo, newTokenId);
        }
        userMintsWL[mintTo] += number;
        totalSupply += number;
    }

    function numberMinted(address sender) public view returns (uint256) {
        return userMints[sender];
    }

    function numberMintedWL(address sender) public view returns (uint256) {
        return userMintsWL[sender];
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC4907, ERC2981, ONFT721Core) returns (bool) {
        return
            ERC4907.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            ONFT721Core.supportsInterface(interfaceId);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                assembly {
                    mstore8(ptr, byte(mod(value, 10), "0123456789abcdef"))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");

        if (!revealed) return notRevealedImagesLink;

        string memory currentBaseURI = imagesLink;
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, toString(tokenId), ".json"))
                : "";
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    function airdrop(address[] calldata _sendNftsTo, uint256 _howMany) external onlyOwner {
        reservedNfts -= _sendNftsTo.length * _howMany;
        require(tokenIdCounter.current() + _sendNftsTo.length * _howMany <= maxSupply, "limit exceeded");

        for (uint256 i = 0; i < _sendNftsTo.length; i++) mintNfts(_sendNftsTo[i], _howMany);
    }

    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) public onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function revealFlip() public onlyOwner {
        revealed = !revealed;
    }

    function set_nftPrice(uint256 _nftPrice) public onlyOwner {
        nftPrice = _nftPrice;
    }

    function set_imagesLink(string memory _imagesLink) public onlyOwner {
        imagesLink = _imagesLink;
    }

    function set_notRevealedImagesLink(string memory _notRevealedImagesLink) public onlyOwner {
        notRevealedImagesLink = _notRevealedImagesLink;
    }

    function set_buyActiveTime(uint256 _buyActiveTime) public onlyOwner {
        buyActiveTime = _buyActiveTime;
    }

    address public signer = msg.sender;

    function set_signer(address _signer) public onlyOwner {
        signer = _signer;
    }

    // WL Config

    function purchaseWhitelist(
        uint256 _howMany,
        bytes32 _signedMessageHash,
        uint256 _rootNumber,
        bytes memory _signature
    ) external payable {
        require(block.timestamp > presaleActiveTime, "Presale is not active");
        require(_howMany > 0 && _howMany <= 10, "Invalid quantity");

        require(_signatureUsed[_signature] == false, "Signature is already used");

        require(msg.value == _howMany * itemPricePresales[_rootNumber], "low eth value");
        require(numberMintedWL(msg.sender) + _howMany <= maxMintPresales[_rootNumber], "exceeds max allowed");

        require(_signature.length == 65, "Invalid signature");
        address recoveredSigner = verifySignature(_signedMessageHash, _signature);
        require(recoveredSigner == signer, "Invalid signature");
        _signatureUsed[_signature] = true;

        require(tokenIdCounter.current() + _howMany + reservedNfts <= maxSupply, "limit exceeded");

        mintNftsWL(msg.sender, _howMany);
    }

    // function to return the messageHash
    function messageHash(string memory _message) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _message));
    }

    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        /*
            Signature is produced by signing a keccak256 hash with the following format:
            "\x19Ethereum Signed Message\n" + len(msg) + msg
            */
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    // verifySignature helper function
    function verifySignature(bytes32 _signedMessageHash, bytes memory _signature) public pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        require(_signature.length == 65, "Invalid signature");

        // Divide the signature into its three components
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := and(mload(add(_signature, 65)), 255)
        }

        // Ensure the validity of v
        // Ensure the validity of v
        if (v < 27) {
            v += 27;
        }
        require(v == 27 || v == 28, "Invalid signature v value");

        // Recover the signer's address
        address signerRec = ecrecover(_signedMessageHash, v, r, s);
        require(signerRec != address(0), "Invalid signature");

        return signerRec;
    }

    function setPresale(uint256 _rootNumber, uint256 _maxMintPresales, uint256 _itemPricePresale) external onlyOwner {
        maxMintPresales[_rootNumber] = _maxMintPresales;
        itemPricePresales[_rootNumber] = _itemPricePresale;
    }

    function setPresaleActiveTime(uint256 _presaleActiveTime) external onlyOwner {
        presaleActiveTime = _presaleActiveTime;
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override(ERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public virtual override(ERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override(ERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}