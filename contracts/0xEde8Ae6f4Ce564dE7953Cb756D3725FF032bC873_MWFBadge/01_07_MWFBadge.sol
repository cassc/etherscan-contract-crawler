// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.4;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";

contract MWFBadge is ERC721A, Pausable, Ownable {

    struct Coupon {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }
    enum CouponType {
        FreeMint,
        PublicMint
    }
    using Strings for uint256;
    uint256 public maxSupply = 10000;
    uint256 public maxMint = 1;
    uint256 public maxFreeMint = 1;
    uint256 public mintPrice = 0 ether;
    address private _adminSigner = 0x0c5bf296aad5E1BC631469a4fD5d16A26Bc75430;
    string private metadataBaseURI = "https://api.metaverserifleassociation.com/api/metadata/";
    string private collectionBaseURI = "https://api.metaverserifleassociation.com/api/collection/";

    mapping(address => uint256) public mintCount;
    mapping(address => uint256) public freeMintCount;


    event NewURI(string newURI, address updatedBy);
    event WithdrawnPayment(uint256 balance, address updatedBy);
    event UpdateAdminSigner(address adminSigner, address updatedBy);
    event UpdateMaxSupply(uint256 maxSupply, address updatedBy);
    event UpdateMintPrice(uint256 mintPrice, address updatedBy);
    event UpdateMaxMint(uint256 mintPrice, address updatedBy);
    event UpdateMaxFreeMint(uint256 mintPrice, address updatedBy);

    

    constructor() ERC721A("MWFBadge", "MWFBadge") {
    }

    function setMetadataBaseURI(string memory _metadataBaseURI)
    external
    onlyOwner {
        metadataBaseURI = _metadataBaseURI;
        emit NewURI(_metadataBaseURI, msg.sender);
    }

    function setCollectionBaseURI(string memory _collectionBaseURI)
    external
    onlyOwner {
        collectionBaseURI = _collectionBaseURI;
        emit NewURI(_collectionBaseURI, msg.sender);
    }

    function mint(
        uint256 amount,
        Coupon memory coupon,
        CouponType couponType
    )
    external
    payable
    whenNotPaused
    verifyCoupon(coupon, couponType)
    {
        uint256 nextTokenId = _nextTokenId();
        require(maxSupply > nextTokenId + amount - 2, "Max supply limit reached");

        if (couponType == CouponType.PublicMint) {
            require(mintCount[msg.sender] + amount <= maxMint, "Max mint limit per address reached");
            require(msg.value >= amount * mintPrice, "Invalid amount");
            mintCount[msg.sender]++;
        }
        if (couponType == CouponType.FreeMint) {
            require(freeMintCount[msg.sender] + amount <= maxFreeMint, "Max mint limit per address reached");
            freeMintCount[msg.sender]++;
        }
        _mint(msg.sender, amount);
    }

    function batchFreeMint(address[] memory _winnerAddresses, uint64 amount)
    external
    onlyOwner {
        uint256 nextTokenId = _nextTokenId();
        require(
            nextTokenId + (_winnerAddresses.length * amount) - 2 < maxSupply,
            "Max supply limit reached"
        );
        for (uint i = 0; i < _winnerAddresses.length; i++) {
            _mint(_winnerAddresses[i], amount);
        }
    }

    function getAdminSigner() public view returns (address) {
        return _adminSigner;
    }

    function getbaseURI() public view returns (string memory) {
        return metadataBaseURI;
    }

    function contractURI() public view returns (string memory) {
        return collectionBaseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory) {
        require(_exists(tokenId), "ERC721A: Query for non-existent token");
        return bytes(metadataBaseURI).length > 0 ?
        string(abi.encodePacked(metadataBaseURI, tokenId.toString())) :
        "";
    }

    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner() returns (uint256) {
        require(totalSupply() <= _maxSupply, "error");
        maxSupply = _maxSupply;
        emit UpdateMaxSupply(_maxSupply, msg.sender);
        return _maxSupply;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner() returns (uint256) {
        mintPrice = _mintPrice;
        emit UpdateMintPrice(_mintPrice, msg.sender);
        return _mintPrice;
    }


    function setMaxMint(uint256 _maxMint) public onlyOwner() returns (uint256) {
        maxMint = _maxMint;
        emit UpdateMaxMint(_maxMint, msg.sender);
        return _maxMint;
    }

    function setMaxFreeMint(uint256 _maxFreeMint) public onlyOwner() returns (uint256) {
        maxFreeMint = _maxFreeMint;
        emit UpdateMaxFreeMint(_maxFreeMint, msg.sender);
        return _maxFreeMint;
    }

    function setAdminSigner(address _newAdminSigner) public onlyOwner() returns (address) {
        _adminSigner = _newAdminSigner;
        emit UpdateAdminSigner(_newAdminSigner, msg.sender);
        return _adminSigner;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
        emit WithdrawnPayment(balance, msg.sender);
    }

    function isVerifiedCoupon(bytes32 digest, Coupon memory coupon)
    internal
    view
    returns (bool) {
        address signer = ecrecover(digest, coupon.v, coupon.r, coupon.s);
        require(signer != address(0), "invalid address");
        // Added check for zero address
        return signer == _adminSigner;
    }

    modifier verifyCoupon(Coupon memory coupon, CouponType couponType) {
        if (couponType == CouponType.FreeMint) {
            bytes32 digest = keccak256(
                abi.encode(couponType, msg.sender)
            );
            require(isVerifiedCoupon(digest, coupon), "invalid coupon");
        }
        _;
    }
}