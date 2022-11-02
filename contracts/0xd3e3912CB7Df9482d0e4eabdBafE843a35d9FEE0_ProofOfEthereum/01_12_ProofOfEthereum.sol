// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "ERC721A/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract ProofOfEthereum is ERC721AQueryable, Ownable, EIP712, ReentrancyGuard {
    using Strings for uint256;

    bytes32 public merkleRoot;
    mapping(address => bool) public whitelistClaimed;

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;

    uint256 public publicCost;
    uint256 public whitelistCost;
    uint256 public maxSupply;
    uint256 public maxMintAmountPerTxPublic;
    uint256 public maxMintAmountPerTxWhitelist;

    bool public paused = true;
    bool public whitelistMintEnabled = false;
    bool public revealed = false;

    address private treasuryAddress;
    address public signer;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _publicCost,
        uint256 _whitelistCost,
        uint256 _maxSupply,
        uint256 _maxMintAmountPerTxPublic,
        uint256 _maxMintAmountPerTxWhitelist,
        string memory _hiddenMetadataUri,
        address _treasuryAddress,
        address _signer
    ) EIP712("ProofOfEthereum", "1") ERC721A(_tokenName, _tokenSymbol) {
        setPublicCost(_publicCost); // 0.02604
        setWhitelistCost(_whitelistCost); //0.03
        maxSupply = _maxSupply; //2604
        setMaxMintAmountPerTxPublic(_maxMintAmountPerTxPublic); // 4
        setMaxMintAmountPerTxWhitelist(_maxMintAmountPerTxWhitelist); // 2
        setHiddenMetadataUri(_hiddenMetadataUri);
        setTreasury(_treasuryAddress);
        setSigner(_signer);
    }

    modifier mintCompliancePublic(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTxPublic,
            "Invalid mint amount!"
        );
        require(totalSupply() + _mintAmount <= maxSupply, "Sold Out!");
        _;
    }

    modifier mintComplianceWhitelist(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTxWhitelist,
            "Invalid mint amount!"
        );
        require(totalSupply() + _mintAmount <= maxSupply, "Sold out!");
        _;
    }

    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        public
        payable
        mintComplianceWhitelist(_mintAmount)
    {
        require(
            whitelistMintEnabled,
            "The whitelist sale has not started. Come check again later!"
        );
        require(
            !whitelistClaimed[_msgSender()],
            "This address has already claimed their WL spot!"
        );
        require(
            msg.value == whitelistCost * _mintAmount,
            "Insufficient funds!"
        );
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof!"
        );
        whitelistClaimed[_msgSender()] = true;
        _safeMint(_msgSender(), _mintAmount);
        (bool os, ) = payable(treasuryAddress).call{
            value: address(this).balance
        }("");
        require(os);
    }

    struct Voucher {
        address wallet;
        bytes signature;
    }

    function publicMint(Voucher calldata voucher, uint256 _mintAmount)
        public
        payable
        mintCompliancePublic(_mintAmount)
    {
        require(!paused, "The mint has been paused!");
        require(msg.value == publicCost * _mintAmount, "Insufficient funds!");
        _verifySignature(voucher);
        _safeMint(_msgSender(), _mintAmount);
        (bool os, ) = payable(treasuryAddress).call{
            value: address(this).balance
        }("");
        require(os);
    }

    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function _verifySignature(Voucher calldata voucher) internal view {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(keccak256("Approved(address wallet)"), _msgSender())
            )
        );
        require(
            signer == ECDSA.recover(digest, voucher.signature),
            "Invalid signer"
        );
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function mintFromOwner(uint256 _mintAmount, address _receiver)
        external
        onlyOwner
    {
        require(totalSupply() + _mintAmount <= maxSupply, "Sold Out!");
        _safeMint(_receiver, _mintAmount);
    }

    function setTreasury(address _treasury) public onlyOwner {
        treasuryAddress = _treasury;
    }

    function setPublicCost(uint256 _cost) public onlyOwner {
        publicCost = _cost;
    }

    function setWhitelistCost(uint256 _cost) public onlyOwner {
        whitelistCost = _cost;
    }

    function setMaxMintAmountPerTxPublic(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        maxMintAmountPerTxPublic = _maxMintAmountPerTx;
    }

    function setMaxMintAmountPerTxWhitelist(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        maxMintAmountPerTxWhitelist = _maxMintAmountPerTx;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setWhitelistMintEnabled(bool _state) public onlyOwner {
        whitelistMintEnabled = _state;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(treasuryAddress).call{
            value: address(this).balance
        }("");
        require(os);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}