// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./libs/Sales.sol";
import "./libs/RestrictedMinters.sol";

contract Wafuku is ERC721A, Ownable, Pausable {
    using Sales for Sales.Set;
    using RestrictedMinters for RestrictedMinters.Set;

    event Minted(uint256);
    event Burned(uint256);

    address public constant withdrawAddress = 0x96E5754c0F61F3b23bc63818A7b503F2a73bbdFb;
    uint8 public currentSaleId = 0;
    string public baseURI = "";
    string public baseExtension = ".json";

    Sales.Set private _sales;
    RestrictedMinters.Set private _minters;
    uint256 private _countAtSaleStart;

    modifier isNotOverMaxSupply(uint256 amount) {
        uint256 total;
        if (_isBurnMintSale()) {
            total = _totalBurned() - _countAtSaleStart;
        } else {
            total = totalSupply() - _countAtSaleStart;
        }
        require(
            amount + total <= _sales.get(currentSaleId).maxSupply,
            "claim is over the max supply"
        );
        _;
    }

    modifier isNotOverMaxAmount(uint256 amount) {
        require(
            amount <= _sales.get(currentSaleId).maxMintAmount,
            "claim is over max amount at once"
        );
        _;
    }

    modifier whenMintSale() {
        require(!_isBurnMintSale(), "current sale is not mint");
        _;
    }

    modifier whenBurnAndMintSale() {
        require(_isBurnMintSale(), "current sale is not burn and mint");
        _;
    }

    modifier enoughEth(uint256 amount) {
        require(
            msg.value >= _sales.get(currentSaleId).mintCost * amount,
            "not enough eth"
        );
        _;
    }

    modifier hasRightToMint(uint256 amount, uint256 allowedAmount, bytes32[] calldata merkleProof) {
        if (_isRestrictedSale(currentSaleId)) {
            bytes32 node = keccak256(abi.encodePacked(msg.sender, allowedAmount));
            require(MerkleProof.verify(merkleProof, _sales.get(currentSaleId).merkleRoot, node), "Invalid proof");
            require(_minters.getMintCount(msg.sender) + amount <= allowedAmount, "claim is over allowed amount");
        }
        _;
    }

    constructor() ERC721A("Wafuku", "WFK") {
        _safeMint(0x2aa011A011e2fC4139402F0D6BCd0E86E3741fE2, 600);
        _safeMint(0x40Af078ebE19F16d064D055881ee97E1c6D6be12, 600);
        _safeMint(0x0306a06fE4Da5a280f4A78BeCD37F30B352EbA4a, 600);
        _safeMint(0xf4895afF82ac25027D8fa5b292930746A497837E, 100);
        _safeMint(0xD253e45c1f48bEb7dfe4678cB6d831C842b9E8B2, 100);
        _safeMint(0x597B11F34edE259f459E25560c40e80D9a0dB53F, 50);
        _safeMint(0xBBA254699Bc6C8CDEeAAb5DB75BeE22E4E990AB8, 50);
        _safeMint(0x05C4e1D4445dEb2a1D7F1db4e33909fBb5C599b1, 50);
        _safeMint(0xb21D44ed67c495A4ABD644575c20c145cECB47e7, 50);
        _safeMint(0x924fCAceaE7187629F7974D2f570D5F6cDb20052, 50);
        _safeMint(0x76E5A6c87a912c382B767BDF4053f4A290d2b9B3, 50);
        _pause();
    }

    function addSale(Sales.Sale memory sale) external onlyOwner {
        _sales.add(sale);
    }

    function removeSale(uint8 id) external onlyOwner {
        require(currentSaleId != id, "can not remove current sale");
        _sales.remove(id);
    }

    function getSale(uint8 id) external view returns (uint8, uint16, uint64, uint64, uint8, uint8) {
        Sales.Sale memory sale = _sales.get(id);
        return (
            sale.id,
            sale.maxMintAmount,
            sale.mintCost,
            sale.maxSupply,
            sale.hasRestriction,
            sale.isBurnAndMint
        );
    }

    function getTotalBurned() external view returns (uint256) {
        return _totalBurned();
    }

    function getMintCount(address sender) public view returns (uint256) {
        return _minters.getMintCount(sender);
    }

    function mint(uint64 amount, uint256 allowedAmount, bytes32[] calldata merkleProof)
        external
        payable
        whenNotPaused
        isNotOverMaxSupply(amount)
        isNotOverMaxAmount(amount)
        enoughEth(amount)
        hasRightToMint(amount, allowedAmount, merkleProof)
        whenMintSale
    {
        _mintCore(amount);
    }

    function burnMint(uint256[] memory burnTokenIds, uint256 allowedAmount, bytes32[] calldata merkleProof)
        external
        payable
        whenNotPaused
        isNotOverMaxSupply(burnTokenIds.length)
        isNotOverMaxAmount(burnTokenIds.length)
        enoughEth(burnTokenIds.length)
        hasRightToMint(burnTokenIds.length, allowedAmount, merkleProof)
        whenBurnAndMintSale
    {
        for (uint256 i = 0; i < burnTokenIds.length; i++) {
            uint256 tokenId = burnTokenIds[i];
            require(_msgSender() == ownerOf(tokenId));
            _burn(tokenId);
            emit Burned(tokenId);
        }

        _mintCore(uint64(burnTokenIds.length));
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function changeCurrentSaleId(uint8 id) external onlyOwner {
        require(_sales.contains(id) || id == 0, "id is not exist");
        if (_isBurnMintSale(id)) {
            _countAtSaleStart = _totalBurned();
        } else {
            _countAtSaleStart = totalSupply();
        }
        currentSaleId = id;
        _minters.deleteAll();
    }

    function setBaseURI(string memory _value) external onlyOwner {
        baseURI = _value;
    }

    function setBaseExtension(string memory _value) external onlyOwner {
        baseExtension = _value;
    }

    function exists(uint256 tokenId) public view virtual returns (bool) {
        return _exists(tokenId);
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}("");
        require(os);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(ERC721A.tokenURI(tokenId), baseExtension));
    }

    function _mintCore(uint64 amount) private {
        _addMintCountWhenRestrictedSale(amount);
        _safeMint(msg.sender, amount);
        emit Minted(amount);
    }

    function _addMintCountWhenRestrictedSale(uint64 amount) private {
        if (_isRestrictedSale(currentSaleId)) {
            _minters.add(msg.sender, amount);
        }
    }

    function _isRestrictedSale(uint8 id) private view returns (bool) {
        return _sales.get(id).hasRestriction == 1;
    }

    function _isBurnMintSale() private view returns (bool) {
        return _isBurnMintSale(currentSaleId);
    }

    function _isBurnMintSale(uint8 id) private view returns (bool) {
        return _sales.get(id).isBurnAndMint == 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}