// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./efficientReentrantGuard.sol";
import "./efficientMerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract PAPP is ERC721, IERC2981, Ownable, nonReentrant {
    using Address for address payable;

    string public baseTokenURI =
        "ipfs://QmY7eMWtDbSisfD5FjNyCt5CGpVKkRtZ3jPXm4KWByAgUM";
    uint16 public tokenCount = 0;
    uint8 public royaltyDivisor = 20;
    bool public saleIsActive = false;
    bool private isOpenSeaProxyActive = true;

    address private openSeaProxyRegistryAddress;
    bytes32 public MerkleRoot =
        0x6b7cd3ade91654f85cf349014fee88ec1c00ead3cc80c0200b2b31f90f7df3aa;

    mapping(address => uint8) public userClaims;

    constructor(address _openSeaProxyRegistryAddress)
        ERC721("Psychedelics Anonymous Printing Press", "PAPP")
    {
        openSeaProxyRegistryAddress = _openSeaProxyRegistryAddress;
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        MerkleRoot = _root;
    }

    function setRoyaltyDivisor(uint8 _divisor) external onlyOwner {
        royaltyDivisor = _divisor;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseTokenURI = _uri;
    }

    function switchSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /**
     * User Functions
     */

    function checkProofWithKey(
        address _sender,
        bytes32[] memory proof,
        bytes1 key
    ) public view returns (bool) {
        bytes32 senderHash = keccak256(abi.encodePacked(_sender, key));
        bool proven = MerkleProof.verify(proof, MerkleRoot, senderHash);
        return proven;
    }

    function claim(
        bytes32[] memory _proof,
        bytes1 _allowance,
        uint8 _amount
    ) external reentryLock {
        require(saleIsActive, "Sale is not active");
        require(
            _amount > 0 && _amount <= uint8(_allowance),
            "Cannot mint that amount"
        );
        require(
            MerkleProof.verify(
                _proof,
                MerkleRoot,
                keccak256(abi.encodePacked(msg.sender, _allowance))
            ),
            "Unauthorized"
        );
        require(
            userClaims[msg.sender] + _amount < uint8(_allowance) + 1,
            "Exceeds user allowance"
        );

        userClaims[msg.sender] += _amount;

        uint16 _tokenCount = tokenCount;

        for (uint256 i; i < _amount; i++) {
            _safeMint(msg.sender, ++_tokenCount);
        }

        tokenCount = _tokenCount;
    }

    function burn(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    // function to disable gasless listings for security in case
    // opensea ever shuts down or is compromised
    function setIsOpenSeaProxyActive(bool _isOpenSeaProxyActive)
        external
        onlyOwner
    {
        isOpenSeaProxyActive = _isOpenSeaProxyActive;
    }

    function setOpenSeaProxyRegistryAddress(
        address _openSeaProxyRegistryAddress
    ) external onlyOwner {
        openSeaProxyRegistryAddress = _openSeaProxyRegistryAddress;
    }

    /**
     * OVERRIDES
     */

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(baseTokenURI));
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Get a reference to OpenSea's proxy registry contract by instantiating
        // the contract using the already existing address.
        ProxyRegistry proxyRegistry = ProxyRegistry(
            openSeaProxyRegistryAddress
        );
        if (
            isOpenSeaProxyActive &&
            address(proxyRegistry.proxies(owner)) == operator
        ) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @dev See {IERC2981-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");

        return (
            0x218B622bbe4404c01f972F243952E3a1D2132Dec,
            salePrice / royaltyDivisor
        );
    }
}

/***************************************
 * @author: 🍖                         *
 * @team:   Asteria                     *
 ****************************************/