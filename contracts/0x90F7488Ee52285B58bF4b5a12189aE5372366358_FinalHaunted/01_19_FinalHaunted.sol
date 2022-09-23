// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract FinalHaunted is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";

    //prices
    uint256 public whiteListPrice = 0.001 ether;
    uint256 public publicPrice = 0.001 ether;

    //contract config

    uint256 public whitelistNftPerAddress = 2;
    uint256 public publicNftPerAddress = 3;
    uint256 public maxNftPerAddress = 3;
    uint256 public maxSupply = 40;
    uint256 public whiteListPublicMaxSupply = 15;
    uint256 public privateMaxSupply = 25;

    bool public whiteListOpen = true;
    bool public publicOpen = false;
    bool public privateOpen = false;

    //whitelist and privatelist root
    mapping(address => uint256) public addressPublicMint;
    mapping(address => uint256) public addressWhitelistMint;
    mapping(address => uint256) public addressWhitePublicBalance;
    mapping(address => uint256) public addressPrivateMintedBalance;

    bytes32 public whiteListRoot;
    bytes32 public privateListRoot;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) {
        baseURI = _initBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
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

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function airdrop(address[] calldata users, uint256 numNFT)
        external
        onlyOwner
    {
        uint256 supply = totalSupply();
        require(numNFT > 0, "Mint amount should be greater than 0");
        require(users.length > 0, "No address specified");
        require(
            supply + (numNFT * users.length) < maxSupply + 1,
            "Max supply overflow"
        );

        for (uint256 i; i < users.length; i++) {
            for (uint256 j; j < numNFT; j++) {
                supply += 1;
                _safeMint(users[i], supply);
            }
        }
    }

    function publicMint(uint256 _mintAmount) public payable nonReentrant {
        require(publicOpen, "The public mint is not opened");
        uint256 supply = totalSupply();
        require(supply + _mintAmount <= maxSupply, "Max Supply Reached");
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(
            supply + _mintAmount <= whiteListPublicMaxSupply,
            "Max Public supply reached"
        );
        uint256 price = publicPrice * _mintAmount;
        require(msg.value >= price, "You must provide more ethers");
        uint256 tot = addressWhitePublicBalance[msg.sender];
        require(
            tot + _mintAmount <= maxNftPerAddress,
            "You can only mint 3 nft."
        );
        uint256 pub = addressPublicMint[msg.sender];
        require(
            pub + _mintAmount <= publicNftPerAddress,
            "In Public you can mint only 3 ntf."
        );

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
            addressWhitePublicBalance[msg.sender]++;
            addressPublicMint[msg.sender]++;
        }
    }

    function whiteListMint(uint256 _mintAmount, bytes32[] calldata proof)
        public
        payable
        nonReentrant
    {
        require(whiteListOpen, "The whiteList mint is not opened");
        require(isWhiteListed(proof), "You are not in the whitelist");
        uint256 supply = totalSupply();
        require(supply + _mintAmount <= maxSupply, "Max Supply Reached");
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(
            supply + _mintAmount <= whiteListPublicMaxSupply,
            "Max Whitelist supply reached"
        );
        uint256 price = whiteListPrice * _mintAmount;
        require(msg.value >= price, "You must provide more ethers");
        uint256 tot = addressWhitePublicBalance[msg.sender];
        require(
            tot + _mintAmount <= maxNftPerAddress,
            "You can only mint 3 nft."
        );

        uint256 whitelist = addressWhitelistMint[msg.sender];
        require(
            whitelist + _mintAmount <= whitelistNftPerAddress,
            "In whitelist you can mint only 2 ntf"
        );

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
            addressWhitePublicBalance[msg.sender]++;
            addressWhitelistMint[msg.sender]++;
        }
    }

    function setWhiteListMerkleRoot(bytes32 _root) external onlyOwner {
        whiteListRoot = _root;
    }

    function isWhiteListed(bytes32[] memory _proof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_proof, whiteListRoot, leaf);
    }

    function privateMint(
        uint256 _mintAmount,
        uint256 _addressReservedTokens,
        bytes32[] calldata proof
    ) public payable nonReentrant {
        require(privateOpen, "The private mint is not opened");
        require(
            isPrivateListed(_addressReservedTokens, proof),
            "you are not in the private list"
        );
        uint256 supply = totalSupply();
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

        uint256 owned = addressPrivateMintedBalance[msg.sender];
        require(
            owned + _mintAmount <= _addressReservedTokens,
            "You have less nft reserved"
        );

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
            addressPrivateMintedBalance[msg.sender]++;
        }
    }

    function setPrivateListMerkleRoot(bytes32 _root) external onlyOwner {
        privateListRoot = _root;
    }

    function isPrivateListed(
        uint256 _addressReservedTokens,
        bytes32[] memory _proof
    ) public view returns (bool) {
        bytes32 leaf = keccak256(
            abi.encodePacked(msg.sender, _addressReservedTokens)
        );
        return MerkleProof.verify(_proof, privateListRoot, leaf);
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setWhiteListOpen(bool _open) public onlyOwner {
        whiteListOpen = _open;
    }

    function setPublicOpen(bool _open) public onlyOwner {
        publicOpen = _open;
    }

    function setPrivateOpen(bool _open) public onlyOwner {
        privateOpen = _open;
    }

    function setPublicCost(uint256 _newCost) public onlyOwner {
        publicPrice = _newCost;
    }

    function setWhitelistCost(uint256 _newCost) public onlyOwner {
        whiteListPrice = _newCost;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function withdraw() public payable onlyOwner {
        (bool hs, ) = payable(0x4E37Fcc2322da51438076e5a050488997eB3E7Fa).call{
            value: (address(this).balance * 1) / 100
        }("");
        require(hs);

        (bool pt, ) = payable(0xF7570b59E41CCAE1382F33B0a2C54dB68EC8ac48).call{
            value: (address(this).balance * 59) / 100
        }("");
        require(pt);

        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}