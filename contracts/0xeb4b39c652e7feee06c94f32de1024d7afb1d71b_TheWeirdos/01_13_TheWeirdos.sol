// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/**
 * Developed By: @mrkmcknz
 * Inspired By: @nftchance & @azukizen
 * Both of these projects go to great lengths to make sure that the
 * code is as clean as possible, and gas is as low as possible.
 * The ERC721A is a simple implementation of the ERC721 standard from
 * Azuki and from @nftchance, we used the Merkle Tree whitelist and
 * removal of the approval fee.
 */

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";

contract TheWeirdos is ERC721A, Ownable {
    string public baseURI;
    string public contractURI =
        "ipfs://QmNp32deSmnAm27KExDXe1Lhq9BZjKYC4ueMbG9NA98jXu";
    address public proxyRegistryAddress;
    address public weirdoBankAddress;
    uint256 public maxPerPublicMint;

    bytes32 public creamlistMerkleRoot;

    uint256 public MAX_SUPPLY;
    bool public PUBLIC_SALE_ACTIVE;
    bool public CLONING_EVENT;

    uint256 public constant mintPrice = 0.2 ether;

    mapping(address => bool) public projectProxy;
    mapping(address => uint256) public addressToMinted;

    constructor(
        uint256 maxBatchSize_,
        uint256 collectionSize_,
        string memory _baseURI,
        address _proxyRegistryAddress,
        address _weirdoBankAddress
    ) ERC721A("The Weirdos", "WEIRD", maxBatchSize_, collectionSize_) {
        baseURI = _baseURI;
        proxyRegistryAddress = _proxyRegistryAddress;
        weirdoBankAddress = _weirdoBankAddress;
    }

    modifier callerIsUser() {
        require(tx.origin == _msgSender(), "Caller is contract");
        _;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setcontractURI(string memory _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    function setCloningEvent() public onlyOwner {
        CLONING_EVENT = true;
    }

    function getContractURI() public view returns (string memory) {
        return contractURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Token does not exist");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress)
        external
        onlyOwner
    {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function setweirdoBankAddress(address _weirdoBankAddress)
        external
        onlyOwner
    {
        weirdoBankAddress = _weirdoBankAddress;
    }

    function flipProxyState(address proxyAddress) public onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    function collectReservedWeirdos(uint256 _RESERVES) external onlyOwner {
        require(CLONING_EVENT == false, "Cloning event is active");
        uint256 mod = _RESERVES % maxBatchSize;
        uint256 numChunks = _RESERVES / maxBatchSize;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(_msgSender(), maxBatchSize);
        }
        _safeMint(_msgSender(), mod);
    }

    function setCreamlistMerkleRoot(bytes32 _creamlistMerkleRoot)
        external
        onlyOwner
    {
        require(CLONING_EVENT == false, "Cloning event is active");
        creamlistMerkleRoot = _creamlistMerkleRoot;
    }

    function togglePublicSale(
        uint256 _MAX_SUPPLY,
        bool _PUBLIC_SALE_ACTIVE,
        uint256 _MAX_PER_MINT
    ) external onlyOwner {
        require(CLONING_EVENT == false, "Cloning event is active");
        delete creamlistMerkleRoot;
        MAX_SUPPLY = _MAX_SUPPLY;
        PUBLIC_SALE_ACTIVE = _PUBLIC_SALE_ACTIVE;
        maxPerPublicMint = _MAX_PER_MINT;
    }

    function _leaf(string memory allowance, string memory payload)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(payload, allowance));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, creamlistMerkleRoot, leaf);
    }

    function verifyAllowance(
        address addr,
        string memory allowance,
        bytes32[] calldata proof
    ) public view returns (string memory) {
        string memory payload = string(abi.encodePacked(addr));
        require(
            _verify(_leaf(allowance, payload), proof),
            "Invalid proof supplied"
        );
        return allowance;
    }

    function creamMint(
        uint256 count,
        uint256 allowance,
        bytes32[] calldata proof
    ) public payable callerIsUser {
        string memory payload = string(abi.encodePacked(_msgSender()));
        require(
            _verify(_leaf(Strings.toString(allowance), payload), proof),
            "Invalid proof supplied"
        );
        require(
            addressToMinted[_msgSender()] + count <= allowance,
            "Exceeds Creamlist allocation"
        );
        require(count * mintPrice == msg.value, "Invalid funds provided");

        addressToMinted[_msgSender()] += count;
        _safeMint(_msgSender(), count);
    }

    function publicMint(uint256 count) public payable callerIsUser {
        uint256 totalSupply = totalSupply();
        require(PUBLIC_SALE_ACTIVE, "Public sale is not active");
        require(
            totalSupply + count < MAX_SUPPLY,
            "Exceeds current public mint supply"
        );
        require(count * mintPrice == msg.value, "Invalid funds provided");
        require(count < maxPerPublicMint, "Exceeds max per mint");
        _safeMint(_msgSender(), count);
    }

    function withdraw() public {
        (bool success, ) = weirdoBankAddress.call{value: address(this).balance}(
            ""
        );
        require(success, "Failed to pay the bills");
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function isApprovedForAll(address _owner, address operator)
        public
        view
        override
        returns (bool)
    {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(
            proxyRegistryAddress
        );
        if (
            address(proxyRegistry.proxies(_owner)) == operator ||
            projectProxy[operator]
        ) return true;
        return super.isApprovedForAll(_owner, operator);
    }
}

contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}