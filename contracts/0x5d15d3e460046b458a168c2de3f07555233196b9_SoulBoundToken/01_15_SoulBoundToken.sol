// SPDX-License-Identifier: MIT
// Collectify Launchapad Contracts v1.1.0
// Creator: Hging

pragma solidity ^0.8.4;

import './ERC721S.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract SoulBoundToken is ERC721S, ERC2981 {
    bytes32 public merkleRoot;
    uint256 public maxSupply;
    uint256 public mintPrice;
    uint256 public maxCountPerAddress;
    uint256 public _privateMintCount;
    string public baseURI;
    MintTime public privateMintTime;
    MintTime public publicMintTime;
    TimeZone public timeZone;
    address public tokenContract;

    struct MintTime {
        uint64 startAt;
        uint64 endAt;
    }

    struct TimeZone {
        int8 offset;
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
        MintTime memory _publicMintTime,
        address _tokenContract
    ) ERC721S(name, symbol) {
        mintPrice = _mintPrice;
        maxSupply = _maxSupply;
        maxCountPerAddress = _maxCountPerAddress;
        baseURI = _uri;
        timeZone = _timezone;
        privateMintTime = _privateMintTime;
        publicMintTime = _publicMintTime;
        tokenContract = _tokenContract;
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

    function revork(uint256 tokenId) public onlyOwner {
        _burn(tokenId);
    }

    function _privateMint(uint256 quantity, uint256 whiteQuantity, bytes32[] calldata merkleProof, address receiver) internal {
        require(block.timestamp >= privateMintTime.startAt && block.timestamp <= privateMintTime.endAt, "error: 10000 time is not allowed");
        uint256 supply = totalSupply();
        require(supply + quantity <= maxSupply, "error: 10001 supply exceeded");
        address claimAddress = _msgSender();
        if (owner() != claimAddress) {
            require(!privateClaimList[claimAddress], 'error:10003 already claimed');
        }
        require(quantity <= whiteQuantity, "error: 10004 quantity is not allowed");
        require(
            MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(claimAddress, whiteQuantity))),
            'error:10004 not in the whitelist'
        );
        if (tokenContract == address(0)) {
            require(mintPrice * quantity <= msg.value, "error: 10002 price insufficient");
        } else {
            (bool success, bytes memory data) = tokenContract.call(abi.encodeWithSelector(0x23b872dd, claimAddress, address(this), mintPrice * quantity));
            require(
                success && (data.length == 0 || abi.decode(data, (bool))),
                "error: 10002 price insufficient"
            );
        }
        privateClaimList[claimAddress] = true;
        _privateMintCount = _privateMintCount + quantity;
        _safeMint(receiver, quantity);
    }

    function privateMint(uint256 quantity, uint256 whiteQuantity, bytes32[] calldata merkleProof) external payable {
        _privateMint(quantity, whiteQuantity, merkleProof, _msgSender());
    }

    function privateMintFor(uint256 quantity, uint256 whiteQuantity, bytes32[] calldata merkleProof, address receiver) external payable {
        _privateMint(quantity, whiteQuantity, merkleProof, receiver);
    }

    function _publicMint(uint256 quantity, address receiver) internal {
        require(block.timestamp >= publicMintTime.startAt && block.timestamp <= publicMintTime.endAt, "error: 10000 time is not allowed");
        require(quantity <= maxCountPerAddress, "error: 10004 max per address exceeded");
        uint256 supply = totalSupply();
        require(supply + quantity <= maxSupply, "error: 10001 supply exceeded");
        address claimAddress = _msgSender();
        if (owner() != claimAddress) {
            require(!publicClaimList[claimAddress], 'error:10003 already claimed');
        }
        if (tokenContract == address(0)) {
            require(mintPrice * quantity <= msg.value, "error: 10002 price insufficient");
        } else {
            (bool success, bytes memory data) = tokenContract.call(abi.encodeWithSelector(0x23b872dd, claimAddress, address(this), mintPrice * quantity));
            require(
                success && (data.length == 0 || abi.decode(data, (bool))),
                "error: 10002 price insufficient"
            );
        }
        publicClaimList[claimAddress] = true;
        _safeMint(receiver, quantity);
    }

    function publicMint(uint256 quantity) external payable {
        _publicMint(quantity, _msgSender());
    }

    function publicMintFor(uint256 quantity, address receiver) external payable {
        _publicMint(quantity, receiver);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721S, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721S.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    // This allows the contract owner to withdraw the funds from the contract.
    function withdraw(uint amt) external onlyOwner {
        if (tokenContract == address(0)) {
            (bool sent, ) = payable(_msgSender()).call{value: amt}("");
            require(sent, "GG: Failed to withdraw Ether");
        } else {
            (bool success, bytes memory data) = tokenContract.call(abi.encodeWithSelector(0xa9059cbb, _msgSender(), amt));
            require(
                success && (data.length == 0 || abi.decode(data, (bool))),
                "GG: Failed to withdraw Ether"
            );
        }
    }
}