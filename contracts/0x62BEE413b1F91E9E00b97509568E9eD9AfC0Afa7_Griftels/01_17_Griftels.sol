// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////
//  _______  ______    ___   _______  _______  _______  ___      _______ //
// |       ||    _ |  |   | |       ||       ||       ||   |    |       |//
// |    ___||   | ||  |   | |    ___||_     _||    ___||   |    |  _____|//
// |   | __ |   |_||_ |   | |   |___   |   |  |   |___ |   |    | |_____ //
// |   ||  ||    __  ||   | |    ___|  |   |  |    ___||   |___ |_____  |//
// |   |_| ||   |  | ||   | |   |      |   |  |   |___ |       | _____| |//
// |_______||___|  |_||___| |___|      |___|  |_______||_______||_______|//
// @custom:security-contact [email protected] ////////////////////
///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";

contract Griftels is
    ERC721,
    ERC721Enumerable,
    Pausable,
    Ownable,
    ReentrancyGuard
{
    using Strings for string;
    using ECDSA for bytes32;

    address private signer;
    string private baseTokenURI;
    uint256 public maxSupply = 666;
    uint256 public mintPrice;
    bool public mintingEnabled;

    mapping(address => mapping(uint256 => bool)) private seenNonces;

    event Mint(address indexed account, uint256 tokenId);
    event Received(address indexed account, uint256 value);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI,
        address _signer,
        uint256 _mintPrice
    ) ERC721(_name, _symbol) {
        baseTokenURI = _baseTokenURI;
        mintPrice = _mintPrice;
        mintingEnabled = false;
        signer = _signer;
    }

    function mintByOwner(
        uint256 grifterId,
        uint256 nonce,
        bytes memory signature
    ) public payable nonReentrant {
        require(!paused(), "mintByOwner: Minting is paused");
        require(mintingEnabled, "mintByOwner: Minting is disabled");
        require(msg.value == mintPrice, "mintByOwner: Wrong ETH amount sent");
        require(totalSupply() < maxSupply, "mintByOwner: Max supply reached");
        require(grifterId > 0, "mintByOwner: Out of Range");
        require(!_exists(grifterId), "mintByOwner: Griftel already minted");
        require(verifySignature(grifterId, nonce, signature), "mintByOwner: Invalid signature");

        _safeMint(msg.sender, grifterId);
        emit Mint(msg.sender, grifterId);
    }

    function verifySignature(
        uint256 grifterId,
        uint256 nonce,
        bytes memory signature
    ) internal returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, grifterId, nonce));
        bytes32 message = ECDSA.toEthSignedMessageHash(hash);
        address receivedAddress = ECDSA.recover(message, signature);
        require(receivedAddress != address(0), "verifySignature: Cannot be 0x0");
        require(!seenNonces[receivedAddress][nonce], "verifySignature: Nonce already used");
        seenNonces[receivedAddress][nonce] = true;
        
        return receivedAddress == signer;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMintingEnabled() external onlyOwner {
        mintingEnabled = !mintingEnabled;
    }

    receive() external payable {
        emit Received(_msgSender(), msg.value);
    }

    function withdraw() public payable onlyOwner {
        require(
            payable(_msgSender()).send(address(this).balance),
            "Unable to Withdraw ETH"
        );
    }

    function ownersTokens(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokens = balanceOf(_owner);
        if (tokens == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokens);
            uint256 index;
            for (index = 0; index < tokens; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "tokenURI: Griftel Doesn't Exist");
        return
            string(
                abi.encodePacked(baseTokenURI, "/", uint2str(tokenId), ".json")
            );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}