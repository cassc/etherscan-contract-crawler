// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "ERC721A.sol";
import "ReentrancyGuard.sol";
import "Ownable.sol";
import "Address.sol";
import "ECDSA.sol";

struct NftConfig {
    address signer;
    string baseUrl;
    uint256 maxSupply;
    address payable salesWallet;
}

struct MintRequest {
    // IDs are used against reply attacks
    uint128 id;
    uint256 ethPrice;
    uint256 amount;
    // how long will the request be valid (deadline)
    uint256 deadline;
    // signature for the request
    bytes signature;
}

contract FoundersNft is ERC721A, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;
    using Address for address payable;

    NftConfig public config;
    mapping(uint128 => bool) public usedRequests;
    bytes32 public immutable mintSalt = keccak256("mint");

    constructor(NftConfig memory _config) public ERC721A("PunksClub Founders NFT", "PCFNDRS") {
        config = _config;
    }

    function setSigner(address _signer) public onlyOwner {
        require(_signer != address(0));
        config.signer = _signer;
    }

    function setBaseUrl(string memory _baseUrl) public onlyOwner {
        config.baseUrl = _baseUrl;
    }

    function setSalesWallet(address payable _salesWallet) public onlyOwner {
        require(_salesWallet != address(0));
        config.salesWallet = _salesWallet;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(_tokenId)) {
            revert URIQueryForNonexistentToken();
        }

        return
            string(
                abi.encodePacked(config.baseUrl, _toString(_tokenId), ".json")
            );
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId, true);
    }

    function mint(MintRequest calldata _request) external payable nonReentrant {
        require(!usedRequests[_request.id], "Request already used");
        require(
            _totalMinted() + _request.amount <= config.maxSupply,
            "Too many tokens"
        );
        require(_request.deadline > block.timestamp, "Request expired");

        bytes32 hashed = keccak256(
            abi.encode(
                // salt is used in case we are signing more things with the same key
                mintSalt,
                // chainid is needed to make sure signatures won't be reused across chains
                block.chainid,
                // same as with salt - prevent accidental signature reuse
                address(this),
                // id is needed to protect from reply attacks so it acts as a nonce
                _request.id,
                // needed so the signatures are not valid for eternity
                _request.deadline,
                // msg sender is needed to ensure no one will be able to use someone else's signature
                // (by front-running transaction for example)
                _msgSender(),
                // rest of the data
                _request.ethPrice,
                _request.amount
            )
        );

        address _signedBy = hashed.recover(_request.signature);
        require(_signedBy == config.signer, "Request not signed by signer");

        usedRequests[_request.id] = true;

        if (_request.ethPrice > 0) {
            require(msg.value >= _request.ethPrice, "Not enough ETH");
            uint256 remaining = msg.value - _request.ethPrice;
            config.salesWallet.sendValue(_request.ethPrice);
            if (remaining > 0) {
                payable(_msgSender()).sendValue(remaining);
            }
        }

        _safeMint(_msgSender(), _request.amount);
    }
}