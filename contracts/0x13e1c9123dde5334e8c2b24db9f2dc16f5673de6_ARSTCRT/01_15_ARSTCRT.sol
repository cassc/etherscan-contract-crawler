// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC721A.sol";

contract ARSTCRT is Ownable, ERC721A {
    using ECDSA for bytes32;

    address private signerAddress = 0xAc41f41Fb962C8164967355E53cf287BA39489B3;
    uint256 public immutable maxMint;
    uint256 public immutable ringSupply;
    string private _baseTokenURI;
    bool public presaleLive = false;
    bool public publicLive = false;
    bool public shareLive = false;
    uint256 public shareValue;

    mapping(uint256 => bool) public isClaimed;

    event SignerAddress(address indexed _from, address _to);

    constructor(
        uint256 maxMint_,
        uint256 ringSupply_,
        string memory baseTokenURI_
    ) ERC721A("ARSTCRT", "ARSTCRT", maxMint_) {
        maxMint = maxMint_;
        _baseTokenURI = baseTokenURI_;
        ringSupply = ringSupply_;
    }

    function toggleSale(
        bool _presale,
        bool _public,
        bool _share
    ) external onlyOwner {
        presaleLive = _presale;
        publicLive = _public;
        shareLive = _share;
    }

    function setShareValue() external onlyOwner {
        for (uint256 i = 0; i < totalSupply(); i++) {
            isClaimed[i] = false;
        }
        shareValue = (address(this).balance * 4) / 10;
    }

    function getShare() external {
        require(shareLive, "Share session not open yet");
        uint256 _share = shareValue / totalSupply();
        uint256 _validToken = 0;
        for (uint256 i = 0; i < balanceOf(msg.sender); i++) {
            uint256 _tokenId = tokenOfOwnerByIndex(msg.sender, i);
            if (!isClaimed[_tokenId]) {
                isClaimed[_tokenId] = true;
                _validToken++;
            }
        }
        uint256 _val = _share * _validToken;
        payable(msg.sender).transfer(_val);
    }

    function pubMint() payable external {
        require(publicLive, "Public sale not open yet");
        require(_numberMinted(msg.sender) < 1, "Supply Runs Out");
        require(totalSupply() < ringSupply, "Sold out");
        _safeMint(msg.sender, 1);
    }

    function presaleMint(
        uint256 _nonce,
        bytes32 _msgHash,
        bytes memory _signature
    ) external {
        isValidWhitelist(msg.sender, _nonce, _msgHash, _signature);
        require(presaleLive, "Presale not open yet");
        require(_numberMinted(msg.sender) + 2 <= maxMint, "Supply Runs Out");
        require(totalSupply() + 2 <= ringSupply, "Sold out");
        _safeMint(msg.sender, 2);
    }

    function setSignerAddress(address _newSigner) external onlyOwner {
        signerAddress = _newSigner;
        emit SignerAddress(msg.sender, signerAddress);
    }

    function isValidWhitelist(
        address _whitelistAddress,
        uint256 _nonce,
        bytes32 _messageHash,
        bytes memory _signature
    ) private view returns (bool) {
        require(
            _messageHash ==
                ECDSA.toEthSignedMessageHash(
                    hashWhitelist(_whitelistAddress, _nonce)
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

    function hashWhitelist(address _whitelistAddress, uint256 _nonce)
        private
        pure
        returns (bytes32)
    {
        bytes memory hashData = abi.encodePacked(_whitelistAddress, _nonce);
        bytes32 hashStructz = keccak256(hashData);
        return hashStructz;
    }
}