//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.14;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract HyperionsFree is
    ERC721A,
    Ownable,
    ERC721ABurnable,
    ERC721AQueryable,
    ReentrancyGuard
{
    uint256 public constant MAX_SUPPLY = 270;

    uint256 public whitelistPrice = 0.00 ether;
    uint256 public publicPrice = 0.00 ether;
    uint256 public maxPerAddress = 1;

    bool public paused = false;
    bool public onlyWhitelisted = true;

    string public baseUri;
    bytes32 public whitelistMerkleRoot;

    mapping(address => uint256) public claimedWhitelist;

    constructor() payable ERC721A("Hyperion's Free", "HYPSF") {}

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        require(_exists(_tokenId), "Token does not exist!");
        return
            string(
                abi.encodePacked(baseUri, Strings.toString(_tokenId), ".json")
            );
    }

    function mint(uint256 _qty, bytes32[] calldata _merkleProof)
        public
        payable
        nonReentrant
    {
        _checkPaused();
        _checkCanMint(_qty);
        if (onlyWhitelisted) {
            require(
                _isWhitelisted(msg.sender, _merkleProof),
                "Not a whitelisted user!"
            );
            require(
                claimedWhitelist[msg.sender] < maxPerAddress,
                "Max NFTs per address is claimed!"
            );
            require(msg.value >= whitelistPrice * _qty, "Insufficient funds!");
        } else {
            require(msg.value >= publicPrice * _qty, "Insufficient funds!");
        }
        claimedWhitelist[msg.sender] += 1;
        _safeMint(msg.sender, _qty);
    }

    function giftToken(address _to, uint256 _qty) public onlyOwner {
        _checkCanMint(_qty);
        _safeMint(_to, _qty);
    }

    function setBaseUri(string calldata _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
    }

    function setWhitelistMerkleRoot(bytes32 _root) public onlyOwner {
        whitelistMerkleRoot = _root;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setWhitelistPrice(uint256 _price) public onlyOwner {
        whitelistPrice = _price;
    }

    function setPublicPrice(uint256 _price) public onlyOwner {
        publicPrice = _price;
    }

    function setMaxPerAddress(uint256 _val) public onlyOwner {
        maxPerAddress = _val;
    }

    function withdraw() public {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "Withdraw failed!");
    }

    function renounceOwnership() public pure override {
        return; // disable renounce ownership ...
    }

    // utils ---------------------------------------------------------------
    function _isWhitelisted(address _user, bytes32[] calldata _merkleProof)
        internal
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(_user));
        require(
            MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf),
            "Invalid proof!"
        );
        return true;
    }

    function _checkCanMint(uint256 _qty) internal view {
        require(totalSupply() + _qty < MAX_SUPPLY + 1, "Max supply exceeded!");
    }

    function _checkPaused() internal view {
        require(!paused, "Contract is paused!");
    }
}