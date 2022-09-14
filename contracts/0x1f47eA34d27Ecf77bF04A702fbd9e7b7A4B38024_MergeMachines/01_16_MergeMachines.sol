// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

// ███╗   ████████████████╗ ██████╗███████╗    ███╗   ███╗█████╗ ████████╗  ███████╗   ████████████████╗
// ████╗ ██████╔════██╔══████╔════╝██╔════╝    ████╗ ██████╔══████╔════██║  ████████╗  ████╔════██╔════╝
// ██╔████╔███████╗ ██████╔██║  ████████╗      ██╔████╔███████████║    ███████████╔██╗ ███████╗ ███████╗
// ██║╚██╔╝████╔══╝ ██╔══████║   ████╔══╝      ██║╚██╔╝████╔══████║    ██╔══██████║╚██╗████╔══╝ ╚════██║
// ██║ ╚═╝ ███████████║  ██╚██████╔███████╗    ██║ ╚═╝ ████║  ██╚████████║  ██████║ ╚██████████████████║
// ╚═╝     ╚═╚══════╚═╝  ╚═╝╚═════╝╚══════╝    ╚═╝     ╚═╚═╝  ╚═╝╚═════╚═╝  ╚═╚═╚═╝  ╚═══╚══════╚══════
//                                                                  ( ^ ◡ ^)_旦”” cooked by @nftchef

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "erc721a/contracts/ERC721A.sol";

//----------------------------------------------------------------------------
// OpenSea proxy
//----------------------------------------------------------------------------
import "./common/ContextMixin.sol";
import "./common/NativeMetaTransaction.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

//----------------------------------------------------------------------------
// Main contract
//----------------------------------------------------------------------------

contract MergeMachines is
    ERC721A,
    ContextMixin,
    NativeMetaTransaction,
    Ownable,
    Pausable,
    ReentrancyGuard,
    PaymentSplitter
{
    using Strings for uint256;
    using ECDSA for bytes32;

    uint128 public SUPPLY = 3333;
    // limit starts at 9 for phase 0
    uint128 public MINT_LIMIT = 9;

    // phases:
    // ethrminators: 0
    // partners: 1
    // public: 2
    uint256 public PHASE = 0;

    // @dev enforce a per-address lifetime limit based on the mintBalances mapping
    bool public publicWalletLimit = true;

    string public PROVENANCE_HASH; // keccak256

    mapping(address => uint256) public mintBalances;

    string internal baseTokenURI;
    address[] internal payees;
    address internal _SIGNER;

    // opensea proxy
    address private immutable _proxyRegistryAddress;

    event Minted(uint256 supply);

    constructor(
        string memory _initialURI,
        address[] memory _payees,
        uint256[] memory _shares,
        address proxyRegistryAddress
    )
        payable
        ERC721A("Merge Machines", "MERGE")
        Pausable()
        PaymentSplitter(_payees, _shares)
    {
        _pause();
        baseTokenURI = _initialURI;
        payees = _payees;
        _proxyRegistryAddress = proxyRegistryAddress;
    }

    function purchase(uint256 _quantity)
        public
        payable
        nonReentrant
        whenNotPaused
    {
        require(PHASE >= 2, "Public closed");
        require(_quantity <= MINT_LIMIT, "Quantity exceeds MINT_LIMIT");
        if (publicWalletLimit) {
            require(
                _quantity + mintBalances[msg.sender] <= MINT_LIMIT,
                "Quantity exceeds per-wallet limit"
            );
        }

        mint(_quantity);
    }

    function presalePurchase(
        uint256 _quantity,
        bytes32 _hash,
        bytes memory _signature
    ) external payable whenNotPaused {
        require(
            checkHash(_hash, _signature, _SIGNER),
            "Address is not on Presale List"
        );

        // @dev Presale always enforces a per-wallet limit
        require(
            _quantity + mintBalances[msg.sender] <= MINT_LIMIT,
            "Quantity exceeds per-wallet limit"
        );

        mint(_quantity);
    }

    function mint(uint256 _quantity) internal {
        require(
            _quantity + totalSupply() <= SUPPLY,
            "Purchase exceeds available supply"
        );

        _safeMint(msg.sender, _quantity);

        mintBalances[msg.sender] += _quantity;
        emit Minted(totalSupply());
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), '"ERC721Metadata: tokenId does not exist"');

        return string(abi.encodePacked(baseTokenURI, tokenId.toString()));
    }

    function senderMessageHash() internal view returns (bytes32) {
        bytes32 message = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(address(this), msg.sender, PHASE))
            )
        );
        return message;
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts
     *  to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function checkHash(
        bytes32 _hash,
        bytes memory signature,
        address _account
    ) internal view returns (bool) {
        bytes32 senderHash = senderMessageHash();
        if (senderHash != _hash) {
            return false;
        }
        return _hash.recover(signature) == _account;
    }

    //----------------------------------------------------------------------------
    // Only Owner
    //----------------------------------------------------------------------------

    function setSigner(address _address) external onlyOwner {
        _SIGNER = _address;
    }

    // @dev gift a single token to each address passed in through calldata
    // @param _recipients Array of addresses to send a single token to
    function gift(address[] calldata _recipients) external onlyOwner {
        uint256 recipients = _recipients.length;
        require(
            recipients + totalSupply() <= SUPPLY,
            "_quantity exceeds supply"
        );

        for (uint256 i = 0; i < recipients; i++) {
            _safeMint(_recipients[i], 1);
        }
        emit Minted(totalSupply());
    }

    function setPaused(bool _state) external onlyOwner {
        _state ? _pause() : _unpause();
    }

    function setWalletLimit(bool _state) external onlyOwner {
        publicWalletLimit = _state;
    }

    function setProvenance(string memory _provenance) external onlyOwner {
        PROVENANCE_HASH = _provenance;
    }

    function setBaseURI(string memory _URI) external onlyOwner {
        baseTokenURI = _URI;
    }

    // @dev: blockchain is forever, you never know, you might need these...
    function setPhase(uint128 _phase) external onlyOwner {
        PHASE = _phase;
    }

    function setSupply(uint128 _supply) external onlyOwner {
        SUPPLY = _supply;
    }

    function setPublicLimit(uint128 _limit) external onlyOwner {
        MINT_LIMIT = _limit;
    }

    function withdrawAll() external onlyOwner {
        for (uint256 i = 0; i < payees.length; i++) {
            release(payable(payees[i]));
        }
    }
}