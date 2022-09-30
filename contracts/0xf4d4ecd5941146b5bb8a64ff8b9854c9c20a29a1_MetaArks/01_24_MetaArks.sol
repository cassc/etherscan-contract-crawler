// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

abstract contract ContextMixin {
    function msgSender() internal view returns (address payable sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

contract MetaArks is
    UUPSUpgradeable,
    ERC721EnumerableUpgradeable,
    ERC2981Upgradeable,
    OwnableUpgradeable,
    ContextMixin,
    ReentrancyGuardUpgradeable
{
    using StringsUpgradeable for uint256;

    string public baseURI;
    string public baseExtension;
    string public notRevealedUri;
    // costs for public, presale, and reserved mint
    uint256 public cost;
    uint256 public presaleCost;
    uint256 public reservedCost;

    uint256 public maxSupply;
    uint256 public maxMintAmount;
    uint256 public nftPerAddressLimit;
    // max mint amount forjpublic, presale, and reserved
    uint256 public currentPhasePublicMintMaxAmount;
    uint256 public currentPhasePresaleMintMaxAmount;
    uint256 public currentPhaseReservedMintMaxAmount;

    uint32 public publicSaleStart;
    uint32 public preSaleStart;

    bool public publicSalePaused;
    bool public preSalePaused;

    bool public revealed;
    bool public onlyWhitelisted;

    // for opensea royalties fee
    string public contractURI;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    mapping(address => uint256) addressMintedBalance;
    mapping(address => bool) public whiteList;

    address public safeTreasury;

    struct Coupon {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    address public couponSigner;

    uint public preSaleDuration;
    uint public publicSaleDuration;

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri,
        string memory _contractURI,
        address _safeTreasury
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __ERC721Enumerable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        __METAARKS_init(
            _initBaseURI,
            _initNotRevealedUri,
            _contractURI,
            _safeTreasury
        );
    }

    function __METAARKS_init(
        string memory _initBaseURI,
        string memory _initNotRevealedUri,
        string memory _contractURI,
        address _safeTreasury
    ) internal {
        baseURI = _initBaseURI;
        notRevealedUri = _initNotRevealedUri;
        _setDefaultRoyalty(_msgSender(), 1000);
        contractURI = _contractURI;

        baseExtension = ".json";
        notRevealedUri;
        // set costs
        cost = 0.1 ether;
        presaleCost = 0.07 ether;
        // set supply
        maxSupply = 9999;
        currentPhaseReservedMintMaxAmount = 1000;

        maxMintAmount = 10;
        nftPerAddressLimit = 10;

        publicSaleStart = 1647136800;
        preSaleStart = 1646964000;

        publicSalePaused = true;
        preSalePaused = false;

        revealed = false;
        onlyWhitelisted = true;

        safeTreasury = _safeTreasury;

        couponSigner = owner();
    }

    // for opensea meta transaction
    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _isVerifiedCoupon(bytes32 _digest, Coupon memory _coupon)
        internal
        view
        returns (bool)
    {
        address _signer = ecrecover(_digest, _coupon.v, _coupon.r, _coupon.s);
        require(_signer != address(0), "ECDSA: invalid signature");

        return _signer == couponSigner;
    }

    function _createMessageDigest(address _address)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    keccak256(abi.encodePacked(_address))
                )
            );
    }

    function preSaleMint(uint256 _mintAmount, Coupon memory _coupon)
        public
        payable
    {
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        uint _now = block.timestamp;
        require(
            (!preSalePaused) && (preSaleStart <= _now) && (_now <= preSaleStart + preSaleDuration),
            "Not Reach Pre Sale Time"
        );
        uint256 supply = totalSupply();
        require(
            _mintAmount <= maxMintAmount, // 10
            "max mint amount per session exceeded"
        );
        require(supply + _mintAmount <= getAvailableSupply(), "max NFT limit exceeded"); // 8999

        if (_msgSender() != owner()) {
            if (onlyWhitelisted == true) {
                require(
                    _isVerifiedCoupon(
                        _createMessageDigest(_msgSender()),
                        _coupon
                    ),
                    "coupon is not valid(user may not be whitelisted)."
                ); // require that each wallet can only mint one token
                uint256 ownerMintedCount = addressMintedBalance[_msgSender()];
                require(
                    ownerMintedCount + _mintAmount <= nftPerAddressLimit,
                    "max NFT per address exceeded"
                );
            }
            require(
                msg.value >= presaleCost * _mintAmount,
                "insufficient funds"
            );
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            addressMintedBalance[_msgSender()]++;
            _safeMint(_msgSender(), supply + i);
        }

        (bool success, ) = payable(safeTreasury).call{value: msg.value}("");

        require(success == true, "not be able to send fund to treasury wallet");
    }

    function publicSaleMint(uint256 _mintAmount) public payable {
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        uint _now = block.timestamp;
        require(
            (!publicSalePaused) && (publicSaleStart <= _now) && (_now <= publicSaleStart + publicSaleDuration),
            "Not Reach Public Sale Time"
        );
        uint256 supply = totalSupply();
        require(
            _mintAmount <= maxMintAmount, // 10
            "max mint amount per session exceeded"
        );
        require(supply + _mintAmount <= getAvailableSupply(), "max NFT limit exceeded"); // 8999
        uint256 ownerMintedCount = addressMintedBalance[_msgSender()];
        require(
            ownerMintedCount + _mintAmount <= nftPerAddressLimit,
            "max NFT per address exceeded"
        );
        require(msg.value >= cost * _mintAmount, "insufficient funds");

        for (uint256 i = 1; i <= _mintAmount; i++) {
            addressMintedBalance[_msgSender()]++;
            _safeMint(_msgSender(), supply + i);
        }

        (bool success, ) = payable(safeTreasury).call{value: msg.value}("");

        require(success == true, "not be able to send fund to treasury wallet");
    }

    function authorizedMint(address _addr, uint256 _mintAmount)
        public
        onlyOwner
    {
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        uint256 supply = totalSupply();
        require(
            _mintAmount <= maxMintAmount,
            "max mint amount per session exceeded"
        );
        require(
            supply + _mintAmount <= maxSupply, // 1000
            "reach current Phase NFT limit"
        );
        uint256 ownerMintedCount = addressMintedBalance[_addr];
        require(
            ownerMintedCount + _mintAmount <= nftPerAddressLimit,
            "max NFT per address exceeded"
        );

        for (uint256 i = 1; i <= _mintAmount; i++) {
            addressMintedBalance[_addr]++;
            _safeMint(_addr, supply + i);
        }
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

        if (revealed == false) {
            return notRevealedUri;
        }

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

    function setPreSalePause(bool _state) public onlyOwner {
        preSalePaused = _state;
    }

    function setPublicSalePause(bool _state) public onlyOwner {
        publicSalePaused = _state;
    }

    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setContractURI(string memory _newContractURI) public onlyOwner {
        contractURI = _newContractURI;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setPresaleCost(uint256 _newCost) public onlyOwner {
        presaleCost = _newCost;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function flipReveal(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
        nftPerAddressLimit = _limit;
    }

    function setPublicSaleStart(uint32 timestamp) public onlyOwner {
        publicSaleStart = timestamp;
    }

    function setPreSaleStart(uint32 timestamp) public onlyOwner {
        preSaleStart = timestamp;
    }

    function setCouponSigner(address _couponSigner) public onlyOwner {
        couponSigner = _couponSigner;
    }

    function setPreSaleDuration(uint _duration) public onlyOwner {
        preSaleDuration = _duration;
    }

    function setTreasuryWallet(address _safeTreasury) public onlyOwner {
        safeTreasury = _safeTreasury;
    }

    function setPublicSaleDuration(uint _duration) public onlyOwner {
        publicSaleDuration = _duration;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool success, ) = payable(_msgSender()).call{
            value: address(this).balance
        }("");
        require(success);
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

    function getContractURI() public view returns (string memory) {
        return contractURI;
    }

    function getAvailableSupply() public view returns (uint256) {
        return maxSupply - currentPhaseReservedMintMaxAmount;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721EnumerableUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }

        return super.supportsInterface(interfaceId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}