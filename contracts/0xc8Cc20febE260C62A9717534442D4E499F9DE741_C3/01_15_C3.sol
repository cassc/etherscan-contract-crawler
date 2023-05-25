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

contract C3 is ERC721("C3", "Component 3"), IERC2981, Ownable, nonReentrant {
    using Address for address payable;

    string public baseTokenURI =
        "ipfs://QmYSXVqUrLZpznHxEpvfgg9Pmdfr4uDacQ8JKV1syXArfS";
    uint16 internal tokenCount = 1;
    uint8 public royaltyDivisor = 20;
    bool public saleIsActive = false;
    bool private isOpenSeaProxyActive = true;

    address internal openSeaProxyRegistryAddress =
        0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    bytes32 public MerkleRoot =
        0x5637eb2439c7a395425ac6e98f3d9e9e92a6d9841a8736b9a4ecab862871dbb2;

    mapping(address => uint8) public userClaims;

    /**
     * SETTERS
     */

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        MerkleRoot = _root;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseTokenURI = _uri;
    }

    function switchSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setRoyaltyDivisor(uint8 _divisor) external onlyOwner {
        royaltyDivisor = _divisor;
    }

    function setIsOpenSeaProxyActive(bool _isActive) external onlyOwner {
        isOpenSeaProxyActive = _isActive;
    }

    function setOpenSeaProxyAddress(address _address) external onlyOwner {
        openSeaProxyRegistryAddress = _address;
    }

    /**
     * USER FUNCTIONS
     */

    function getTokenCount() external view returns (uint256) {
        return tokenCount - 1;
    }

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
        bytes32[] calldata _proof,
        bytes1 _allowance,
        uint8 _amount
    ) external reentryLock {
        require(saleIsActive, "Sale is not active");
        require(_amount > 0 && _amount <= uint8(_allowance), "Invalid amount");
        require(
            MerkleProof.verify(
                _proof,
                MerkleRoot,
                keccak256(abi.encodePacked(msg.sender, _allowance))
            ),
            "Unauthorized"
        );
        if (userClaims[msg.sender] + _amount > uint8(_allowance))
            revert("Exceeds user allowance");

        userClaims[msg.sender] += _amount;

        uint16 _tokenCount = tokenCount;

        for (uint256 i; i < _amount; i++) {
            _safeMint(msg.sender, _tokenCount++);
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

    /** @dev This will be used to mint extra C3 for giveaways */
    function ownerMint(uint256 _amount) external onlyOwner {
        uint16 _tokenCount = tokenCount;
        for (uint256 i; i < _amount; i++) {
            _safeMint(msg.sender, _tokenCount++);
        }
        tokenCount = _tokenCount;
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