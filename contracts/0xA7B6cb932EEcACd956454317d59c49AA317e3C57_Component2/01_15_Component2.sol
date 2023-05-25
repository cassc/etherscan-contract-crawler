// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./efficientReentrantGuard.sol";
import "./efficientMerkleProof.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract Component2 is ERC721, IERC2981, Ownable, nonReentrant {
    using Address for address payable;

    string public baseTokenURI =
        "ipfs://QmPPXoU8Kja2jZEM9MogYbe11s8qbF6KJwqC18Lj9qgBPV";
    uint16 public tokenCount = 0;
    bool public saleIsActive = false;
    uint8 public royaltyDivisor = 20;

    bytes32 public MerkleRoot =
        0x317d0e913d541be9fa22038ab90007224468b5db1e0bb0cda0efc3ad3810dca8;

    address private openSeaProxyRegistryAddress;
    bool private isOpenSeaProxyActive = true;

    mapping(address => uint8) public userClaims;

    constructor(address _openSeaProxyRegistryAddress)
        ERC721("Psychedelics Anonymous Component #2", "PAC2")
    {
        openSeaProxyRegistryAddress = _openSeaProxyRegistryAddress;
    }

    function setMerkleRoot(bytes32 _root) public onlyOwner {
        MerkleRoot = _root;
    }

    function setRoyaltyDivisor(uint8 _divisor) external onlyOwner {
        royaltyDivisor = _divisor;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        baseTokenURI = _uri;
    }

    function switchSaleState() public onlyOwner {
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
    ) public reentryLock {
        require(saleIsActive, "Sale is not active");
        require(_amount > 0, "Cannot mint 0");
        require(_amount < uint8(_allowance) + 1, "Allowance exceeded");
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
        for (uint256 i; i < _amount; i++) {
            _safeMint(msg.sender, ++tokenCount);
        }
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

        return (0x218B622bbe4404c01f972F243952E3a1D2132Dec, salePrice / royaltyDivisor);
    }
}

/****************************************
 * @author: 🍖                         *
 * @team:   Asteria                     *
 ****************************************/