// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CloudBunny is ERC721Enumerable, Ownable {
    string public baseURI;
    string public notRevealedUri;
    string public baseExtension = ".json";
    uint16 public maxSupply;
    bytes32 public whitelistMerkleRoot;
    uint256 public launchTime;
    uint64 public presalePrice = 0.008 ether;
    uint64 public publicPrice = 0.01 ether;
    uint8 public publicAmt = 4;
    uint8 public presaleAmt = 3;

    bool public revealed = false;

    mapping(address => uint8) public WLMinted;
    mapping(address => uint8) public PMinted;

    modifier AvailableMint(uint8 amount) {
        require(
            totalSupply() + amount <= maxSupply,
            "Sorry, this would exceed maximum bunny mints!"
        );
        _;
    }

    constructor(
        string memory _BaseURI,
        string memory _notRevealedUri,
        uint16 _maxSupply,
        address chiefAddress
    ) ERC721("CloudBunnies NFT", "CBN") {
        setBaseURI(_BaseURI);
        notRevealedUri = _notRevealedUri;
        maxSupply = _maxSupply;
        _mint(chiefAddress, 1);
    }

    function WLMint(uint8 _mintAmount, bytes32[] memory proof)
        public
        payable
        AvailableMint(_mintAmount)
    {
        require(
            msg.value == presalePrice * _mintAmount,
            "Wrong amount of Ether sent!"
        );
        require(isPresale(), "Presale is not available!");
        require(
            WLMinted[msg.sender] + _mintAmount <= presaleAmt,
            "Exceeds presale mint allowance!"
        );
        uint256 total = totalSupply();
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(proof, whitelistMerkleRoot, leaf),
            "Invalid Proof"
        );
        for (uint8 i = 1; i <= _mintAmount; i++) {
            _mint(msg.sender, total + i);
        }
        WLMinted[msg.sender] += _mintAmount;
    }

    function PMint(uint8 _mintAmount)
        public
        payable
        AvailableMint(_mintAmount)
    {
        require(
            msg.value == publicPrice * _mintAmount,
            "Wrong amount of Ether sent!"
        );
        require(isPublicSale(), "Public minting is not currently available!");
        require(
            PMinted[msg.sender] + _mintAmount <= publicAmt,
            "Exceeds public mint allowance!"
        );
        uint256 total = totalSupply();
        for (uint8 i = 1; i <= _mintAmount; i++) {
            _mint(msg.sender, total + i);
        }
        PMinted[msg.sender] += _mintAmount;
    }

    function isPresale() public view returns (bool) {
        return launchTime != 0 && block.timestamp - launchTime <= 1 days;
    }

    function isPublicSale() public view returns (bool) {
        return launchTime != 0 && block.timestamp - launchTime > 1 days;
    }

    function startLaunch() public onlyOwner {
        launchTime = block.timestamp;
    }

    function setMaxSupply(uint16 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMintPrice(uint64 mintPrice) public onlyOwner {
        publicPrice = mintPrice;
    }

    function setMintAmt(uint8 mintAmt) public onlyOwner {
        publicAmt = mintAmt;
    }

    function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot)
        external
        onlyOwner
    {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    function withdraw() public onlyOwner {
        
        (bool success, ) = owner().call{
            value: address(this).balance
        }("");
        require(success, "Failed to send to Owner.");
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function batchSafeTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds
    ) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            safeTransferFrom(_from, _to, _tokenIds[i]);
        }
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function reveal(bool state) public onlyOwner {
        revealed = state;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");
        return
            revealed
                ? string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(tokenId),
                        baseExtension
                    )
                )
                : notRevealedUri;
    }
}