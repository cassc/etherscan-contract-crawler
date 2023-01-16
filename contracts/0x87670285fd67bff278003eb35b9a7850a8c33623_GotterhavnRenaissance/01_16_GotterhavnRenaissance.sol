// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC721A.sol";

contract GotterhavnRenaissance is Ownable, ERC721A {
    using ECDSA for bytes32;

    address private signerAddress = 0xc6105F19E006Cc11B5F553e89fa705e9f870a091;
    uint256 public immutable maxMint;
    uint256 public immutable maxSupply;
    string private _baseTokenURI;
    bool public privateSale = false;
    bool public publicLive = false;

    mapping(address => bool) public isPrivateMinted;
    mapping(address => uint256) public totalPublicMint;

    constructor(
        uint256 maxMint_,
        uint256 maxSupply_,
        string memory baseTokenURI_
    ) ERC721A("Gotterhavn Renaissance", "GTVN", maxMint_) {
        maxMint = maxMint_;
        _baseTokenURI = baseTokenURI_;
        maxSupply = maxSupply_;
    }

    function toggleSale(bool _private, bool _public) external onlyOwner {
        privateSale = _private;
        publicLive = _public;
    }

    function pubMint() external {
        require(publicLive, "Public sale not open yet");
        require(totalPublicMint[msg.sender] < 1, "Supply Runs Out");
        require(totalSupply() + 1 <= maxSupply, "Sold out");
        totalPublicMint[msg.sender] = 1;
        _safeMint(msg.sender, 1);
    }

    function airdrop(address _wallet, uint256 _supply) external onlyOwner {
        require(totalSupply() + _supply <= maxSupply, "Sold out");
        _safeMint(_wallet, _supply);
    }

    function privateMint(
        uint256 _totalMint,
        uint256 _nonce,
        bytes32 _msgHash,
        bytes memory _signature
    ) external {
        isPrivateList(msg.sender, _totalMint, _nonce, _msgHash, _signature);
        require(privateSale, "Private sale not open yet");
        require(!isPrivateMinted[msg.sender], "You already claimed!");
        require(totalSupply() + _totalMint <= maxSupply, "Sold out");
        isPrivateMinted[msg.sender] = true;
        _safeMint(msg.sender, _totalMint);
    }

    function setSignerAddress(address _newSigner) external onlyOwner {
        signerAddress = _newSigner;
    }

    function isPrivateList(
        address _privateAddress,
        uint256 _totalMint,
        uint256 _nonce,
        bytes32 _messageHash,
        bytes memory _signature
    ) private view returns (bool) {
        require(
            _messageHash ==
                ECDSA.toEthSignedMessageHash(
                    hashPrivateList(_privateAddress, _totalMint, _nonce)
                ),
            "Invalid message hash"
        );
        require(
            signerAddress == ECDSA.recover(_messageHash, _signature),
            "Invalid signature"
        );
        return true;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function hashPrivateList(
        address _privateAddress,
        uint256 _totalMint,
        uint256 _nonce
    ) private pure returns (bytes32) {
        bytes memory hashData = abi.encodePacked(
            _privateAddress,
            _totalMint,
            _nonce
        );
        bytes32 hashStructz = keccak256(hashData);
        return hashStructz;
    }
}