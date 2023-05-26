// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract ASC is Ownable, ERC721, EIP712 {
    bytes32 public constant TYPEHASH =
        keccak256("PROOF(uint256 id,uint8 rarity,uint256 nonce)");
    address public signer;

    address public asacAddress;
    address public masacAddress;

    struct Masac {
        uint256 id;
        uint8 rarity;
        uint256 nonce;
        bytes signature;
    }

    struct RarityMatch {
        uint256 rarity;
        uint256 rarityIndex;
    }

    uint256 public constant TOTAL_MAX_QTY = 8000;
    uint256 public constant GIFT_MAX_QTY = 80;
    uint256 public constant TOTAL_MINT_MAX_QTY = TOTAL_MAX_QTY - GIFT_MAX_QTY;

    uint256 public price;
    uint256 public maxQtyPerWallet;
    string private _tokenBaseURI;
    uint256 public claimedQty;
    uint256 public mintedQty;
    uint256 public giftedQty;
    uint8 public status;
    mapping(address => uint256) public minterToTokenQty;
    mapping(uint256 => RarityMatch) public tokenToRarityMatch;
    mapping(uint256 => uint256) public rarityToRarityIndex;

    constructor() ERC721("Anatomy Science Club", "ASC") EIP712("ASC", "1") {}

    function setSigner(address _address) external onlyOwner {
        signer = _address;
    }

    function getSigner(
        uint256 _id,
        uint8 _rarity,
        uint256 _nonce,
        bytes calldata _signature
    ) public view returns (address) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(TYPEHASH, _id, _rarity, _nonce))
        );
        return ECDSA.recover(digest, _signature);
    }

    function totalSupply() public view returns (uint256) {
        return claimedQty + mintedQty + giftedQty;
    }

    function claim(
        uint256 asacId,
        Masac calldata masac1,
        Masac calldata masac2
    ) external {
        require(status == 1, "XSTAT");
        require(claimedQty + mintedQty < TOTAL_MINT_MAX_QTY, "MAXL");
        require(
            IERC721(asacAddress).ownerOf(asacId) == msg.sender &&
                IERC721(masacAddress).ownerOf(masac1.id) == msg.sender &&
                IERC721(masacAddress).ownerOf(masac2.id) == msg.sender,
            "XOWN"
        );
        require(masac1.rarity == masac2.rarity, "XSAME");
        require(
            getSigner(
                masac1.id,
                masac1.rarity,
                masac1.nonce,
                masac1.signature
            ) ==
                signer &&
                getSigner(
                    masac2.id,
                    masac2.rarity,
                    masac2.nonce,
                    masac2.signature
                ) ==
                signer,
            "XSIGN"
        );

        uint256 totalSupplyBefore = totalSupply();
        uint256 tokenId = totalSupplyBefore + 1;
        claimedQty += 1;
        rarityToRarityIndex[masac1.rarity] += 1;
        uint256 rarityIndex = rarityToRarityIndex[masac1.rarity];
        tokenToRarityMatch[tokenId] = RarityMatch(masac1.rarity,rarityIndex );

        _mint(msg.sender, tokenId);

        IERC721(masacAddress).transferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), masac1.id);
        IERC721(masacAddress).transferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), masac2.id);
    }

    function mint(uint256 _mintQty) external payable {
        require(status == 2, "XSTAT");
        require(
            claimedQty + mintedQty + _mintQty <= TOTAL_MINT_MAX_QTY,
            "MAXL"
        );
        require(
            minterToTokenQty[msg.sender] + _mintQty <= maxQtyPerWallet,
            "MAXP"
        );
        require(msg.value >= price * _mintQty, "SETH");

        uint256 totalSupplyBefore = totalSupply();
        mintedQty += _mintQty;
        minterToTokenQty[msg.sender] += _mintQty;
        for (uint256 i = 0; i < _mintQty; i++) {
            _mint(msg.sender, ++totalSupplyBefore);
        }
    }

    function gift(address[] calldata receivers) external onlyOwner {
        require(giftedQty + receivers.length <= GIFT_MAX_QTY, "MAXG");

        uint256 totalSupplyBefore = totalSupply();
        giftedQty += receivers.length;
        for (uint256 i = 0; i < receivers.length; i++) {
            _mint(receivers[i], ++totalSupplyBefore);
        }
    }

    function setStatus(uint8 _status) external onlyOwner {
        if (_status == 1) {
            require(signer != address(0), "XSIGN");
            require(asacAddress != address(0), "XAAD");
            require(masacAddress != address(0), "XMAAD");
        } else if (_status == 2) {
            require(price > 0, "XPRC");
            require(maxQtyPerWallet > 0, "XQTY");
        }
        status = _status;
    }

    function setAsacAddress(address _address) external onlyOwner {
        asacAddress = _address;
    }

    function setMasacAddress(address _address) external onlyOwner {
        masacAddress = _address;
    }

    function setPriceInWei(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setMaxQtyPerWallet(uint256 _qty) external onlyOwner {
        maxQtyPerWallet = _qty;
    }

    function withdrawAll() external onlyOwner {
        require(address(this).balance > 0, "ZERO");
        payable(msg.sender).transfer(address(this).balance);
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return _tokenBaseURI;
    }
}