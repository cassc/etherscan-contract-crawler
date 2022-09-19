// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract UNBM is ERC721A, Ownable {
    using Strings for uint256;

    mapping(address => bool) _mintedAddresses;

    // Constants
    uint256 public TOTAL_SUPPLY = 4444;
    uint256 public MINT_PRICE = 0.005 ether;
    uint256 public FREE_ITEMS_COUNT = 0;
    uint256 public MAX_IN_TRX = 10;

    address payable withdrawD =
        payable(0xC7dACd7C479A1FCeF6ed420467CA22a918cBd783);
    address payable withdrawTo =
        payable(0x524A31804F586b3C0f78ceFa72a85731ce26201b);

    address _signer = address(0x18090cfACB9879B0d631eA6bF826D32A28d381EC);

    // Variables
    string public baseTokenURI;
    string public uriSuffix;
    bool public paused = false;
    bool public revealed = false;
    string public revealImage;

    struct Coupon {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    constructor(
        string memory _initBaseURI,
        string memory _revealImage,
        string memory _uriSuffix
    ) ERC721A("UnboredMonkeysNFT", "UNBM") {
        setBaseTokenURI(_initBaseURI);
        setRevealImage(_revealImage);
        setUriSuffix(_uriSuffix);
    }

    // Recover the original signer by using the message digest and
    // the passed in coupon, to then confirm that the original
    // signer is in fact the _couponSigner set on this contract.
    function _isVerifiedCoupon(bytes32 digest, Coupon memory coupon)
        internal
        view
        returns (bool)
    {
        address signer = ecrecover(digest, coupon.v, coupon.r, coupon.s);
        require(signer != address(0), "ECDSA: invalid signature");
        return signer == _signer;
    } // Create the same message digest that we know the coupon created

    // in our JavaScript code has created.
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

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setSigner(address __signer) public onlyOwner {
        _signer = __signer;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if (!revealed) {
            return revealImage;
        }

        return
            string(
                abi.encodePacked(
                    _baseURI(),
                    (tokenId + 10000).toString(),
                    uriSuffix
                )
            );
    }

    function mintItem(uint256 quantity) external payable {
        uint256 supply = totalSupply();
        require(!paused, "Minting is paused.");
        require(
            (quantity > 0) && (quantity <= MAX_IN_TRX),
            "Invalid quantity."
        );
        require(supply + quantity <= TOTAL_SUPPLY, "Exceeds maximum supply.");

        if (msg.sender != owner()) {
            require(
                (supply + quantity <= FREE_ITEMS_COUNT) ||
                    (msg.value >= MINT_PRICE * quantity),
                "Not enough supply."
            );
        }

        _safeMint(msg.sender, quantity);
    }

    function mintWL(Coupon memory coupon) external payable {
        require(
            _isVerifiedCoupon(_createMessageDigest(msg.sender), coupon),
            "Coupon is not valid."
        ); // require that each wallet can only mint one token
        require(!_mintedAddresses[msg.sender], "Wallet has already minted."); // Keep track of the fact that this wallet has minted a token
        _mintedAddresses[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }

    function mintTo(address to, uint256 quantity) external payable onlyOwner {
        uint256 supply = totalSupply();
        require(
            supply + quantity - 1 <= TOTAL_SUPPLY,
            "Exceeds maximum supply"
        );
        _safeMint(to, quantity);
    }

    function withdraw() public payable onlyOwner {
        (bool hs, ) = withdrawD.call{value: address(this).balance / 2}("");
        require(hs);

        (bool os, ) = withdrawTo.call{value: address(this).balance}("");
        require(os);
    }

    function setCost(uint256 _newCost) public onlyOwner {
        MINT_PRICE = _newCost;
    }

    function setFreeCount(uint256 _count) public onlyOwner {
        FREE_ITEMS_COUNT = _count;
    }

    function setMaxInTRX(uint256 _total) public onlyOwner {
        MAX_IN_TRX = _total;
    }

    function setmaxMintAmount(uint256 _count) public onlyOwner {
        TOTAL_SUPPLY = _count;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setRevealImage(string memory _revealImage) public onlyOwner {
        revealImage = _revealImage;
    }
}