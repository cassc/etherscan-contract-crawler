// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./Guardian/Erc721LockRegistry.sol";
import "./OPR/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

contract DigiMonkz is
    ERC721x,
    DefaultOperatorFiltererUpgradeable
{
    string public baseTokenURI;
    string public tokenURISuffix;
    string public tokenURIOverride;

    address private signer;

    uint256 public MAX_SUPPLY;
    uint256 public claimStartAfter;
    mapping(address => bool) public hasClaimed; // address => claimed
    mapping(uint256 => bool) public sendNFTLocked;


    function initialize(address _signer, string memory baseURI)
        public
        initializer
    {
        DefaultOperatorFiltererUpgradeable.__DefaultOperatorFilterer_init();

        ERC721x.__ERC721x_init("DigiMonkz", "DigiMonkz");
        baseTokenURI = baseURI;
        signer = _signer;

        MAX_SUPPLY = 111;
    }

    function setSigner(address addr) external onlyOwner {
        signer = addr;
    }

    // =============== Claim ===============

    function setClaimStartAfter(uint256 timestamp) external onlyOwner {
        claimStartAfter = timestamp;
    }

    function checkValidity(bytes calldata signature, string memory action)
        public
        view
        returns (bool)
    {
        require(
            ECDSA.recover(
                ECDSA.toEthSignedMessageHash(
                    keccak256(abi.encodePacked(msg.sender, action))
                ),
                signature
            ) == signer,
            "invalid signature"
        );
        return true;
    }

    function claim(bytes calldata signature) external {
        require(
            claimStartAfter > 0 && block.timestamp >= claimStartAfter,
            "claim not started"
        );
        require(checkValidity(signature, "digimonkz:claim"), "invalid");
        require(!hasClaimed[msg.sender], "Already claimed");
        hasClaimed[msg.sender] = true;
        safeMint(msg.sender, 1);
    }

    function safeMint(address receiver, uint256 quantity) internal {
        require(_totalMinted() + quantity <= MAX_SUPPLY, "exceed MAX_SUPPLY");
        _mint(receiver, quantity);
    }

    // =============== Airdrop ===============

    function airdrop(address[] memory receivers) external onlyOwner {
        require(receivers.length >= 1, "at least 1 receiver");
        for (uint256 i; i < receivers.length; i++) {
            address receiver = receivers[i];
            safeMint(receiver, 1);
        }
    }

    function airdropWithAmounts(
        address[] memory receivers,
        uint256[] memory amounts
    ) external onlyOwner {
        require(receivers.length >= 1, "at least 1 receiver");
        for (uint256 i; i < receivers.length; i++) {
            address receiver = receivers[i];
            safeMint(receiver, amounts[i]);
        }
    }

    // =============== URI ===============

    function compareStrings(string memory a, string memory b)
        public
        pure
        returns (bool)
    {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        returns (string memory)
    {
        if (bytes(tokenURIOverride).length > 0) {
            return tokenURIOverride;
        }
        return string.concat(super.tokenURI(_tokenId), tokenURISuffix);
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function setTokenURISuffix(string calldata _tokenURISuffix)
        external
        onlyOwner
    {
        if (compareStrings(_tokenURISuffix, "!empty!")) {
            tokenURISuffix = "";
        } else {
            tokenURISuffix = _tokenURISuffix;
        }
    }

    function setTokenURIOverride(string calldata _tokenURIOverride)
        external
        onlyOwner
    {
        if (compareStrings(_tokenURIOverride, "!empty!")) {
            tokenURIOverride = "";
        } else {
            tokenURIOverride = _tokenURIOverride;
        }
    }

    // =============== MARKETPLACE CONTROL ===============

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721x) onlyAllowedOperator(from) {
        require(sendNFTLocked[tokenId] == false, "Cannot transfer - currently locked");
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public payable override(ERC721x) onlyAllowedOperator(from) {
        require(sendNFTLocked[tokenId] == false, "Cannot transfer - currently locked");
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    
    function setNFTLock(uint256 _nftNumber) public {
        require(ownerOf(_nftNumber) == tx.origin, "Not Owner");
        sendNFTLocked[_nftNumber] = true;
    }
    
    function setNFTUnLock(uint256 _nftNumber) public {
        require(ownerOf(_nftNumber) == tx.origin, "Not Owner");
        sendNFTLocked[_nftNumber] = false;
    }

}