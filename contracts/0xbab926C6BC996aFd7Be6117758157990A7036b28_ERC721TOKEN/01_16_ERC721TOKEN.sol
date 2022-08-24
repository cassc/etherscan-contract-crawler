// SPDX-License-Identifier: MIT
// Collectify Launchapad Contracts v1.0.0
// Creator: Hging

pragma solidity ^0.8.4;

// import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
// import './ERC721.sol';
import './ERC721Enumerable.sol';
import './IERC721Enumerable.sol';
import './ERC2981.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract ERC721TOKEN is ERC2981, ERC721Enumerable, Ownable {
    bytes32 public merkleRoot;
    uint256 public maxSupply;
    uint256 public mintPrice;
    uint256 public maxCountPerAddress;
    uint256 public _privateMintCount;
    string public baseURI;
    MintTime public privateMintTime;
    MintTime public publicMintTime;
    TimeZone public timeZone;

    struct MintTime {
        uint64 startAt;
        uint64 endAt;
    }

    struct TimeZone {
        uint8 offset;
        string text;
    }

    struct MintState {
        bool privateMinted;
        bool publicMinted;
    }

    mapping(address => bool) internal privateClaimList;
    mapping(address => bool) internal publicClaimList;

    constructor(
        string memory name,
        string memory symbol,
        uint256 _mintPrice,
        uint256 _maxSupply,
        uint8 _maxCountPerAddress,
        string memory _uri,
        uint96 royaltyFraction,
        TimeZone memory _timezone,
        MintTime memory _privateMintTime,
        MintTime memory _publicMintTime
    ) ERC721(name, symbol) {
        mintPrice = _mintPrice;
        maxSupply = _maxSupply;
        maxCountPerAddress = _maxCountPerAddress;
        baseURI = _uri;
        timeZone = _timezone;
        privateMintTime = _privateMintTime;
        publicMintTime = _publicMintTime;
        _setDefaultRoyalty(_msgSender(), royaltyFraction);
    }

    function  _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function isMinted(address owner) public view returns (MintState memory) {
        return(
            MintState(
                privateClaimList[owner],
                publicClaimList[owner]
            )
        );
    }

    function changeBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function changeMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function changeMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function changeMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function changemaxPerAddress(uint8 _maxPerAddress) public onlyOwner {
        maxCountPerAddress = _maxPerAddress;
    }

    function changeDefaultRoyalty(uint96 _royaltyFraction) public onlyOwner {
        _setDefaultRoyalty(_msgSender(), _royaltyFraction);
    }

    function changeRoyalty(uint256 _tokenId, uint96 _royaltyFraction) public onlyOwner {
        _setTokenRoyalty(_tokenId, _msgSender(), _royaltyFraction);
    }

    function changePrivateMintTime(MintTime memory _mintTime) public onlyOwner {
        privateMintTime = _mintTime;
    }

    function changePublicMintTime(MintTime memory _mintTime) public onlyOwner {
        publicMintTime = _mintTime;
    }

    function changeMintTime(MintTime memory _publicMintTime, MintTime memory _privateMintTime) public onlyOwner {
        privateMintTime = _privateMintTime;
        publicMintTime = _publicMintTime;
    }

    function privateMint(uint256 quantity, uint256 whiteQuantity, bytes32[] calldata merkleProof) external payable {
        require(block.timestamp >= privateMintTime.startAt && block.timestamp <= privateMintTime.endAt, "error: 10000 time is not allowed");
        uint256 supply = totalSupply();
        require(supply + quantity <= maxSupply, "error: 10001 supply exceeded");
        require(mintPrice * quantity <= msg.value, "error: 10002 price insufficient");
        address claimAddress = _msgSender();
        require(!privateClaimList[claimAddress], 'error:10003 already claimed');
        require(
            MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(claimAddress, whiteQuantity))),
            'error:10004 not in the whitelist'
        );
        for(uint256 i; i < quantity; i++){
            _safeMint( claimAddress, supply + i );
        }
        privateClaimList[claimAddress] = true;
        _privateMintCount = _privateMintCount + quantity;
    }

    function publicMint(uint256 quantity) external payable {
        require(block.timestamp >= publicMintTime.startAt && block.timestamp <= publicMintTime.endAt, "error: 10000 time is not allowed");
        require(quantity <= maxCountPerAddress, "error: 10004 max per address exceeded");
        uint256 supply = totalSupply();
        require(supply + quantity <= maxSupply, "error: 10001 supply exceeded");
        require(mintPrice * quantity <= msg.value, "error: 10002 price insufficient");
        address claimAddress = _msgSender();
        require(!publicClaimList[claimAddress], 'error:10003 already claimed');
        // _safeMint(claimAddress, quantity);
        for(uint256 i; i < quantity; i++){
            _safeMint( claimAddress, supply + i );
        }
        publicClaimList[claimAddress] = true;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981, ERC721Enumerable)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            ERC2981.supportsInterface(interfaceId);
    }

    // This allows the contract owner to withdraw the funds from the contract.
    function withdraw(uint amt) external onlyOwner {
        (bool sent, ) = payable(_msgSender()).call{value: amt}("");
        require(sent, "GG: Failed to withdraw Ether");
    }
}