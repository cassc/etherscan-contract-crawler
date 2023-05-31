// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract WOLSBT is ERC721, ERC721Enumerable, Ownable {
    using Strings for *;

    string baseURI;
    string public baseExtension = ".json";
    uint256 private _platinumCost = 0.028 ether;
    uint256 private _alCost = 0.035 ether;
    uint256 private _publicCost = 0.04 ether;
    uint256 public maxSupply = 2000;
    uint256 public maxMintAmountPerAddress = 5;
    uint256 public totalMintCount = 0;
    uint256 public ownerMintCount = 0;
    bool public paused = false;
    mapping(address => uint256) private _alMintedCount;
    mapping(address => uint256) private _mintedCount;
    mapping(uint256 => string) public mintedType;

    bytes32 public platinumMerkleRoot;
    bytes32 public goldMerkleRoot;
    bytes32 public silverMerkleRoot;
    bytes32 public bronzeMerkleRoot;
    bool public publicSale = false;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        bytes32 _platinumMerkleRoot,
        bytes32 _goldMerkleRoot,
        bytes32 _silverMerkleRoot,
        bytes32 _bronzeMerkleRoot
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setPlatinumMerkleRoot(_platinumMerkleRoot);
        setGoldMerkleRoot(_goldMerkleRoot);
        setSilverMerkleRoot(_silverMerkleRoot);
        setBronzeMerkleRoot(_bronzeMerkleRoot);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function getTotalMintedCount(address senderAddr)
        public
        view
        returns (uint256)
    {
        return _alMintedCount[senderAddr] + _mintedCount[senderAddr];
    }

    function getALMintedCount(address senderAddr)
        public
        view
        returns (uint256)
    {
        return _alMintedCount[senderAddr];
    }

    function getMintedCount(address senderAddr) public view returns (uint256) {
        return _mintedCount[senderAddr];
    }

    function totalMintPrice(
        uint256 _mintAmount,
        bytes32[] calldata _merkleProof
    ) private view returns (uint256) {
        if (publicSale) {
            return _publicCost * _mintAmount;
        } else if (_stringEqual(getRole(_merkleProof), "platinum")) {
            return _platinumCost * _mintAmount;
        } else {
            return _alCost * _mintAmount;
        }
    }

    function _publicMint(uint256 _mintAmount) private {
        uint256 mintableCount = 5;
        uint256 mintedCount = getMintedCount(msg.sender);
        require(
            mintedCount + _mintAmount <= mintableCount,
            "reached to your max public mint count per person."
        );

        uint256 supply = totalSupply();

        if (mintedCount == 0) {
            uint256 tokenId = supply + 1;
            _mintedCount[msg.sender] = _mintAmount;
            mintedType[tokenId] = "public";
            _safeMint(msg.sender, supply + 1);
        } else {
            _mintedCount[msg.sender] = mintedCount + _mintAmount;
        }
    }

    function _alMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        private
    {
        uint256 mintableCount = _getALMintableCount(_merkleProof);
        uint256 mintedCount = getALMintedCount(msg.sender);
        require(
            mintedCount + _mintAmount <= mintableCount,
            "reached to your max AL mint count."
        );

        uint256 supply = totalSupply();

        if (mintedCount == 0) {
            uint256 tokenId = supply + 1;
            _alMintedCount[msg.sender] = _mintAmount;
            mintedType[tokenId] = getRole(_merkleProof);
            _safeMint(msg.sender, supply + 1);
        } else {
            _alMintedCount[msg.sender] = mintedCount + _mintAmount;
        }
    }

    function mint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        public
        payable
    {
        require(!paused, "mint is paused.");
        require(_mintAmount > 0, "mint amount should be greater than zero.");
        require(
            ownerMintCount + totalMintCount + _mintAmount <= maxSupply,
            "reached to max supply."
        );
        require(
            msg.value == totalMintPrice(_mintAmount, _merkleProof),
            "wrong mint value."
        );

        totalMintCount += _mintAmount;
        if (publicSale) {
            _publicMint(_mintAmount);
        } else {
            _alMint(_mintAmount, _merkleProof);
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        address owner = ownerOf(tokenId);
        uint256 mintedCount = _stringEqual(mintedType[tokenId], "public")
            ? _mintedCount[owner]
            : _alMintedCount[owner];

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        mintedType[tokenId],
                        "-",
                        mintedCount.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    // for whitelist
    function _getALMintableCount(bytes32[] calldata _merkleProof)
        private
        view
        returns (uint256)
    {
        if (_bronzeRole(_merkleProof)) {
            return 1;
        } else if (_silverRole(_merkleProof)) {
            return 3;
        } else if (_goldRole(_merkleProof)) {
            return 5;
        } else if (_platinumRole(_merkleProof)) {
            return 5;
        } else {
            return 0;
        }
    }

    function getRole(bytes32[] calldata _merkleProof)
        public
        view
        returns (string memory)
    {
        if (publicSale) {
            return "public";
        } else if (_bronzeRole(_merkleProof)) {
            return "bronze";
        } else if (_silverRole(_merkleProof)) {
            return "silver";
        } else if (_goldRole(_merkleProof)) {
            return "gold";
        } else if (_platinumRole(_merkleProof)) {
            return "platinum";
        } else {
            return "none";
        }
    }

    function _platinumRole(bytes32[] calldata _merkleProof)
        private
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, platinumMerkleRoot, leaf);
    }

    function _goldRole(bytes32[] calldata _merkleProof)
        private
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, goldMerkleRoot, leaf);
    }

    function _silverRole(bytes32[] calldata _merkleProof)
        private
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, silverMerkleRoot, leaf);
    }

    function _bronzeRole(bytes32[] calldata _merkleProof)
        private
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, bronzeMerkleRoot, leaf);
    }

    // for SBT
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId, /* firstTokenId */
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        require(from == address(0), "Err: token is SOUL BOUND");
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // utils
    function _stringEqual(string memory a, string memory b)
        private
        pure
        returns (bool)
    {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }

    function _toLower(string calldata str)
        internal
        pure
        returns (string memory)
    {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    // owner actions
    function ownerMint(uint256 _mintAmount) public onlyOwner {
        ownerMintCount = _mintAmount;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setPlatinumMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        platinumMerkleRoot = _merkleRoot;
    }

    function setGoldMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        goldMerkleRoot = _merkleRoot;
    }

    function setSilverMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        silverMerkleRoot = _merkleRoot;
    }

    function setBronzeMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        bronzeMerkleRoot = _merkleRoot;
    }

    function setPublicSale(bool _newStatus) public onlyOwner {
        publicSale = _newStatus;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}