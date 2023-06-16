// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";


contract Zalien is ERC721A, Ownable, ERC2981 {

    enum EPublicMintStatus {
        NOTACTIVE,
        BLUECHIP_MINT,
        ALLOWLIST_MINT,
        PUBLIC_MINT,
        CLOSED
    }

    EPublicMintStatus public publicMintStatus;

    string  public baseTokenURI;
    string  public defaultTokenURI = 'ipfs://bafkreif2mn2ijjtekvu2mzfuxnoo4754rkhcigt4jhticokvnss27fvmay';
    uint256 public maxSupply = 4200;
    uint256 public publicSalePrice = 0.096 ether;
    uint256 public allowListSalePrice = 0.069 ether;

    address payable public payMent;
    mapping(address => uint256) public usermint;
    mapping(address => uint256) public allowlistmint;
    mapping(address => uint256) public blurchipmint;

    address[] public BlurChipAddress;

    bytes32 private _merkleRoot;

    constructor() ERC721A ("Zalien", "Zalien") {
        payMent = payable(msg.sender);
        _safeMint(msg.sender, 333);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Must from real wallet address");
        _;
    }

    function mint(uint256 _quantity) external payable {
        require(publicMintStatus == EPublicMintStatus.PUBLIC_MINT, "Public sale closed");
        require(_quantity <= 3, "Invalid quantity");
        require(totalSupply() + _quantity <= maxSupply, "Exceed supply");
        require(msg.value >= _quantity * publicSalePrice, "Ether is not enough");
        require(usermint[msg.sender] + _quantity <= 3, "The address has reached the limit");
        usermint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function allowListMint(bytes32[] calldata _merkleProof, uint256 _quantity) external payable {
        require(publicMintStatus == EPublicMintStatus.ALLOWLIST_MINT, "Allowlist sale closed");
        require(_quantity <= 3, "Invalid quantity");
        require(totalSupply() + _quantity <= maxSupply, "Exceed supply");
        require(msg.value >= _quantity * allowListSalePrice, "Ether is not enough");
        require(isWhitelistAddress(msg.sender, _merkleProof), "Caller is not in whitelist or invalid signature");
        require(allowlistmint[msg.sender] + _quantity <= 3, "The address has reached the limit");
        allowlistmint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function blueChipMint(uint256 _quantity) external payable {
        require(publicMintStatus == EPublicMintStatus.BLUECHIP_MINT, "Community sale closed");
        require(_quantity <= 3, "Invalid quantity");
        require(totalSupply() + _quantity <= maxSupply, "Exceed supply");
        require(msg.value >= _quantity * allowListSalePrice, "Ether is not enough");
        require(checkBlueHolder(msg.sender), "Caller is not in community Holder");
        require(blurchipmint[msg.sender] + _quantity <= 3, "The address has reached the limit");
        blurchipmint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function checkBlueHolder(address walletaddress) internal view returns (bool) {
        for (uint i = 0; i < BlurChipAddress.length; i++) {
            if (IERC721(address(BlurChipAddress[i])).balanceOf(walletaddress) > 0) {
                return true;
            }
        }
        return false;
    }

    function isWhitelistAddress(address _address, bytes32[] calldata _signature) public view returns (bool) {
        return MerkleProof.verify(_signature, _merkleRoot, keccak256(abi.encodePacked(_address)));
    }

    function airdrop(address[] memory mintaddress, uint256[] memory mintquantity) public payable onlyOwner {
        for (uint256 i = 0; i < mintaddress.length; i++) {
            require(totalSupply() + mintquantity[i] <= maxSupply, "Exceed supply");
            _safeMint(mintaddress[i], mintquantity[i]);
        }
    }

    function withdraw() external onlyOwner {
        (bool success,) = payMent.call{value : address(this).balance}("");
        require(success, "Transfer failed.");
    }


    function getHoldTokenIdsByOwner(address _owner) public view returns (uint256[] memory) {
        uint256 index = 0;
        uint256 hasMinted = _totalMinted();
        uint256 tokenIdsLen = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](tokenIdsLen);
        for (uint256 tokenId = 1; index < tokenIdsLen && tokenId <= hasMinted; tokenId++) {
            if (_owner == ownerOf(tokenId)) {
                tokenIds[index] = tokenId;
                index++;
            }
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : defaultTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBlurChipAddress(address[] calldata _BlurChipAddress) external onlyOwner {
        BlurChipAddress = _BlurChipAddress;
    }

    function setBaseURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setDefaultURI(string calldata _defaultURI) external onlyOwner {
        defaultTokenURI = _defaultURI;
    }


    function setPublicPrice(uint256 mintprice) external onlyOwner {
        publicSalePrice = mintprice;
    }

    function setAllowlistPrice(uint256 mintprice) external onlyOwner {
        allowListSalePrice = mintprice;
    }

    function setPublicMintStatus(uint256 status) external onlyOwner {
        publicMintStatus = EPublicMintStatus(status);
    }

    function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        _merkleRoot = merkleRoot;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function setRoyaltyInfo(address payable receiver, uint96 numerator) public onlyOwner {
        _setDefaultRoyalty(receiver, numerator);
    }

    function setPayMent(address _payMent) external onlyOwner {
        payMent = payable(_payMent);
    }

    function DeleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }
}