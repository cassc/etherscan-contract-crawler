// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

    error NotInWhitelist();
    error InvalidAmountOfEthers();
    error CantSendEthersToWallet();
    error LimitExceeded();
    error PrivateSaleNotStarted();


contract NFTTrump is ERC721A, Ownable, Pausable {
    using Counters for Counters.Counter;

    uint256 public immutable totalNFTSupply;
    uint256 public mintPricePublic;
    uint256 public mintPricePrivate;
    uint256 public constant _maxCountMintPublic = 100;
    uint256 public constant _maxCountMintPrivate = 10;
    string private _baseURIAddress;
    address private immutable _wallet;
    // whitelist
    bytes32 private _merkleRoot;
    bool public isPrivateSale;

    mapping(address => uint256) private _walletMintCount;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        uint256 _mintPricePublic,
        uint256 _mintPricePrivate,
        address wallet_,
        string memory baseURIAddress_,
        bytes32 merkleRoot,
        bool isPrivate
    ) ERC721A(_name, _symbol) {
        totalNFTSupply = _totalSupply;
        mintPricePublic = _mintPricePublic;
        mintPricePrivate = _mintPricePrivate;
        _wallet = wallet_;
        _baseURIAddress = baseURIAddress_;
        _merkleRoot = merkleRoot;
        isPrivateSale = isPrivate;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setMerkleRoot(bytes32 merkleRoot_) public onlyOwner {
        _merkleRoot = merkleRoot_;
    }

    function setPrivateSale() public onlyOwner {
        isPrivateSale = true;
    }

    function setPublicSale() public onlyOwner {
        isPrivateSale = false;
    }

    function changeBaseURI(string memory baseURI_) public onlyOwner {
        _baseURIAddress = baseURI_;
    }

    function setMintPricePublic(uint256 _price) public onlyOwner {
        mintPricePublic = _price;
    }

    function setMintPricePrivate(uint256 _price) public onlyOwner {
        mintPricePrivate = _price;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIAddress;
    }

    function getPricePublic(uint256 _count) public view returns (uint256) {
        return _count * mintPricePublic;
    }

    function getPricePrivate(uint256 _count) public view returns (uint256) {
        return _count * mintPricePrivate;
    }

    function getCountWalletNft() public view returns (uint) {
        return _walletMintCount[_msgSender()];
    }

    function ownerMint(address _to, uint256 _count) public payable onlyOwner {
        _safeMint(_to, _count);
    }

    function privateMint(uint256 _count, bytes32[] calldata _merkleProof) public whenNotPaused payable validateProof(_merkleProof){
        require(isPrivateSale, "Buying nft is only available for public");
        require((getCountWalletNft() + _count) <= _maxCountMintPrivate, "You cant by nft.");
        require((totalSupply() + _count) <= totalNFTSupply, "Total supply exceeded. Use less amount.");
        uint costWei = getPricePrivate(_count);
        require(msg.value >= costWei, "Not enough ethers to buy");
        (bool sent, ) = payable(_wallet).call{value: address(this).balance}("");
        require(sent, 'Cant send money to owners wallet.');
        _walletMintCount[_msgSender()] += _count;

        _safeMint(_msgSender(), _count);
    }

    function publicMint(uint256 _count) public whenNotPaused payable {
        require(!isPrivateSale, "Buying nft is only available for private");
        require((getCountWalletNft() + _count) <= _maxCountMintPublic, "You cant by nft.");
        require((totalSupply() + _count) <= totalNFTSupply, "Total supply exceeded. Use less amount.");
        uint costWei = getPricePublic(_count);
        require(msg.value >= costWei, "Not enough ethers to buy");
        (bool sent, ) = payable(_wallet).call{value: address(this).balance}("");
        require(sent, 'Cant send money to owners wallet.');
        _walletMintCount[_msgSender()] += _count;

        _safeMint(_msgSender(), _count);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    modifier validateProof(bytes32[] calldata _merkleProof) {
        if (isPrivateSale) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            if (!MerkleProof.verify(_merkleProof, _merkleRoot, leaf)) {
                revert NotInWhitelist();
            }
        }
        _;
    }

    function burn(uint256 tokenId) public onlyOwner{
        super._burn(tokenId);
    }
}