// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import 'erc721a/contracts/ERC721A.sol';
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MidasVIP is ERC721A, ReentrancyGuard, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;
    
    string private _baseUri = '';
    bytes32 private constant GET_MEMBERSHIP_TYPEHASH = keccak256(
        "GetMembershipWhitelistRequest(address walletAddress,uint mintQty)");

    mapping(address => bool) public _whitelistClaimed;

    uint256 public maxSupply;
    uint private startTime;
    uint private endTime;

    bytes32 private immutable DOMAIN_SEPARATOR;
    
    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseUri_,
        uint256 maxSupply_,
        uint startTime_,
        uint endTime_
    )
        ERC721A(name_, symbol_)
    {
        maxSupply = maxSupply_;
        startTime = startTime_;
        endTime = endTime_;
        _baseUri = baseUri_;
        
        // Calculate the domain separator
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256("Kaching VIP Membership"),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }
    
    function mintWhitelist(uint256 numberOfTokens, bytes calldata signature) external payable nonReentrant {
        require(block.timestamp >= startTime, "Minting period hasn't started yet.");
        require(block.timestamp <= endTime, "Minting period is over.");
        require(_verify(getTypedDataHash(msg.sender, numberOfTokens), signature), "This hash's signature is invalid.");
        require(!_whitelistClaimed[msg.sender], 'You have already minted.');
        require(
            totalSupply()+numberOfTokens <= maxSupply,
            "Sold out."
        );

        _safeMint(msg.sender, numberOfTokens);
        _whitelistClaimed[msg.sender] = true;
    }

    function mintRemaining(uint256 amount) external payable onlyOwner {
        require(
            totalSupply()+amount <= maxSupply,
            "Sold out."
        );
        
        if (amount == 0) {
            amount = maxSupply - totalSupply();
        }
        _safeMint(msg.sender, amount);
    }

    function mintAdmin(address[] memory addresses) external payable onlyOwner {
        require(
            totalSupply()+addresses.length <= maxSupply,
            "Sold out."
        );

        for (uint j = 0; j != addresses.length; j += 1) {
            _safeMint(addresses[j], 1);
        }
    }

    // computes the hash of a get membership whitelist request
    function getStructHash(address _address, uint _mintQty)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    GET_MEMBERSHIP_TYPEHASH,
                    _address,
                    _mintQty
                )
            );
    }

    // computes the hash of the fully encoded EIP-712 message for the domain, which can be used to recover the signer
    function getTypedDataHash(address _address, uint _mintQty)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    getStructHash(_address, _mintQty)
                )
            );
    }

    function _verify(bytes32 hash, bytes memory signature) internal view returns (bool) {
        return (_recover(hash, signature) == owner());
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : '';
    }

    function _recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        return hash.recover(signature);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function setBaseURI(string memory baseUri_) external onlyOwner {
        _baseUri = baseUri_;
    }

    function setMintPeriod(uint _startTime, uint _endTime) external onlyOwner {
        if (_startTime != 0) {
            startTime = _startTime;
        }

        if (_endTime != 0) {
            endTime = _endTime;
        }
    }

    function isMintPeriod() public view returns (bool) {
        return (block.timestamp >= startTime) && (block.timestamp <= endTime);
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function resetClaimed(address wallet_addr) external onlyOwner {
        _whitelistClaimed[wallet_addr] = false;
    }
}