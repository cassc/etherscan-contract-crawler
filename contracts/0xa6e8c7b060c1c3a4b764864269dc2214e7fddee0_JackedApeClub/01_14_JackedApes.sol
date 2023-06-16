// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract JackedApeClub is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string public baseURI;
    string public notRevealedUri;
    string public baseExtension = ".json";
    uint256 public cost = 0.15 ether;
    uint256 public maxSupply = 8888;
    uint256 public maxSupplyForPresale = 7000;
    uint256 public maxMintAmount = 2;
    uint256 public nftPerWhitelistAddressLimit = 1;
    uint256 public nftPerOGAddressLimit = 2;
    bool public paused = false;
    bool public revealed = false;
    bool public onlyPresale = true;

    bytes32 private whitelistMerkleRoot;
    bytes32 private OGMerkleRoot;

    mapping(address => uint256) public addressMintedBalance;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(uint256 _mintAmount) public payable {
        require(!paused, "the contract is paused");
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "min mint is 1 NFT");
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
        // require(supply + _mintAmount <= maxSupply - reserved, "max NFT limit exceeded");

        if (msg.sender != owner()) {
            require(!onlyPresale, "Presale is on");
            require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
            require(msg.value >= cost * _mintAmount, "insufficient funds");
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            addressMintedBalance[msg.sender]++;
            _safeMint(msg.sender, supply + i);
        }
    }

    function whitelistMint(
        uint256 _mintAmount,
        bool _whitelist,
        bytes32[] calldata _merkleProof
    ) public payable {
        require(!paused, "the contract is paused");
        require(onlyPresale, "Presale is false");
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "min mint is 1 NFT");
        require(supply + _mintAmount <= maxSupplyForPresale, "max NFT limit for presale exceeded");

        uint256 ownerMintedCount = addressMintedBalance[msg.sender];

        if (_whitelist) {
            require(
                ownerMintedCount + _mintAmount <= nftPerWhitelistAddressLimit,
                "max NFT per whitelist address exceeded"
            );

            // Check if user is whitelisted
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf), "Invalid Proof, User not whitelisted");
        }

        if (!_whitelist) {
            require(ownerMintedCount + _mintAmount <= nftPerOGAddressLimit, "max NFT per OG address exceeded");
            // Check if user is whitelisted
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(_merkleProof, OGMerkleRoot, leaf), "Invalid Proof, User not OGListed");
        }

        require(msg.value >= cost * _mintAmount, "insufficient funds");

        for (uint256 i = 1; i <= _mintAmount; i++) {
            addressMintedBalance[msg.sender]++;
            _safeMint(msg.sender, supply + i);
        }
    }

    function setWhitelistMerkleRoot(bytes32 root) external onlyOwner {
        whitelistMerkleRoot = root;
    }

    function setOGMerkleRoot(bytes32 root) external onlyOwner {
        OGMerkleRoot = root;
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
                : "";
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    // function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    //     baseExtension = _newBaseExtension;
    // }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setNftPerWhitelistAddressLimit(uint256 _limit) public onlyOwner {
        nftPerWhitelistAddressLimit = _limit;
    }

    function setNftPerOGAddressLimit(uint256 _limit) public onlyOwner {
        nftPerOGAddressLimit = _limit;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setOnlyPresale(bool _state) public onlyOwner {
        onlyPresale = _state;
    }

    function withdraw() public payable onlyOwner {
        // uint256 balance = address(this).balance;
        (bool dy, ) = payable(0xDA66e4F7b6e36A1489788820870432b483230D92).call{
            value: (address(this).balance * 195) / 1000
        }("");
        require(dy);

        (bool ni, ) = payable(0x292BEC2537cEfaD1b002A7aD766C12DA096D5316).call{
            value: (address(this).balance * 2422360248) / 10000000000
        }("");
        require(ni);

        (bool br, ) = payable(0x63d73C33E75bFDB14C18A734713239b98357D552).call{
            value: (address(this).balance * 3278688525) / 10000000000
        }("");
        require(br);

        (bool or, ) = payable(0x6085Ab3dd565FDE4deeC682F9cD9250d7909eb66).call{
            value: (address(this).balance * 3536585366) / 10000000000
        }("");
        require(or);

        (bool mi, ) = payable(0x1C05D8263bFF5a05b037763396dD7A48FaeE3b6D).call{
            value: (address(this).balance * 1886792453) / 10000000000
        }("");
        require(mi);

        (bool ad, ) = payable(0x496031D43A681E510CBCFC281899F25e0D83B4B4).call{
            value: (address(this).balance * 2325581395) / 10000000000
        }("");
        require(ad);

        (bool hd, ) = payable(0x900168607D7fF7c545C11c0DAE5DB6e8223c0909).call{
            value: (address(this).balance * 3030303030) / 10000000000
        }("");
        require(hd);

        (bool da, ) = payable(0x662e7268D9316A565Ec40b6d4b71117aDF89D993).call{
            value: (address(this).balance * 2173913043) / 10000000000
        }("");
        require(da);

        (bool si, ) = payable(0x6Ea2f734c066CC8677b2C0Ce386CD827Ad1636CD).call{
            value: (address(this).balance * 1666666667) / 10000000000
        }("");
        require(si);

        (bool ma, ) = payable(0x906D21e683Db943C98253118E9fE477c89Cd2CEc).call{
            value: (address(this).balance * 1333333333) / 10000000000
        }("");
        require(ma);

        (bool cl, ) = payable(0x45F28e3423dB48B59846667fE1D02eEEba5c8fab).call{
            value: (address(this).balance * 1538461538) / 10000000000
        }("");
        require(cl);

        (bool ja, ) = payable(0x15918f246F415ED59a4ec7220118a16431E132F2).call{
            value: (address(this).balance * 9090909091) / 100000000000
        }("");
        require(ja);

        (bool cm, ) = payable(0x532407ec3681f15f54E10CD0D16920f4b35Eaf76).call{value: address(this).balance}("");
        require(cm);
    }
}