// File: contracts/Planes.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "base64-sol/base64.sol";
import "./IPlaneMetadata.sol";



// ................................................. .:^:...::^:.. ................
// ..................................................!.        .:^:................
// .................i...............................?             .:^^:............
// .................................................~^                :^^:.........
// ....................................n.............^?.                 ^~........
// ...............:::::::...........................^~.                   !^.......
// ............^~^:.....::^^:.....................^~.                    .7:.......
// ..........^~.            :^~^:...............^~.             ::.    .^~:........
// .........!^                 .^~^:.........:^!.             :!^:^^^^^^:....l.....
// :::::::::?                     .^~~::.:.:~!:             :!^:.:......:::::::::::
// :::::::::?                        .^~~^~!:             :!^::::::::::::::::::::::
// ::o::::::^7.                         .::             :!~:::::v::::::::::::::::::
// :::::::::::!~:                                     :!~::::::::::::::::::::::::::
// ::::::::::i:^~!~:                                :!~:::::::::::::::::n::::::::::
// :::::::::::::::^~!~^.                           :?~^::::::::::::::::::::::::::::
// ^^^^^^^^^^^^^^^^^:^~!!^.                          .^!!~^:^^^^^^^^^^^^^^^^^^^^^^^
// ^^^^^g^^^^^^^^^^^^^^^^^~!!^.                          .:~!~^^^^^^m^^^^^^^^^^^^e^
// ^^^^^^^^^^^^^^^^^^^^^^^^^!J:                             :~!!~^^^^^^^^^^^^^^^^^^
// ^^^m^^^^^^^^^^^^^^^^^^^~7^                                  .~!!~^^^^o^^^^^^^^^^
// ^^^^^^^^^^^^^^^^^^^^^~7~                                       .!7^^^^^^^^^^^^^^
// ~~~~~~~~~~~~~r~~~~^!7~             .!7^.                         :J~~~~~~~~~~~~~
// ~~~~~~~~~~~~~~~~~~?~             .!7~~!77~.                       ~7~~~~~~y~~~~~
// ~~~~~~~~~~~~~~~~77              ~?!~~~~~~!77~:                    ?!~~~~~~~~~~~~
// ~~~~~s~~~~~~~~~~Y             ~?!~~~~~~~~~~~!77!:                77~~~~~~~~~~~~~
// !!!!!!!!!!!!!!!~?~          ~?7~~!!!!!!!!e!!!~~!777^.         .~?!~!!!!!!!!!!!!!
// !!!!!!!!!!!!!!!!~7?~:.  .:~?7!!!!!!!!!!!!!!!!!!!!!!777!~^^^~!77!!!!!!!!!t!!!!!!!
// !!!!!h!!!!!!!!!!!!!7777777!!!!!!!!!!!!!!!!1!!!!!!!!!!!!!777!!!!!!!!!!!!!!!9!!!!!
// !!!!!!!!!!!!9!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// 777787777777777777777777777777777777777777r7777777777777777777777777777777777777
// 777777777777777777i7777777777777777777777777777777777777777777777777p77777777777


contract Planes is ERC721, ERC721Enumerable, ERC721Burnable, ReentrancyGuard, Ownable {

    struct Coupon {
        bytes32 r;
        bytes32 s;
        uint8 v;
        uint8 max;
    }
    enum CouponType {
        Claim,
        Presale
    }
    enum SalePhase {
        Locked,
        Presale,
        Public
    }

    event MintedEvent(uint8 num);

    uint256 public maxSupply = 555;
    uint256 public reserved = 30;
    uint256 public numBurned = 0;
    uint256 public maxMintsPerWallet = 10;
    mapping (uint => bytes32) public fingerprints;
    mapping (address => uint8) public pubMintedByWallet;
    mapping (address => uint8) public alMintedByWallet;
    mapping (address => uint8) public claimedByWallet;
    uint256 public price = 0.02 ether;
    uint256 public presalePrice = 0.02 ether;
    address _metadataAddr;
    address _adminSigner;
    SalePhase phase = SalePhase.Locked;
    bool burnEnabled;
    string _contractURI = "https://skies.wtf/nft/contractURI.json";

    constructor() ERC721("Skies, BlockMachine", "SKIES") {}

    function getSeed(uint256 tokenId) public view returns (string memory) {
        return string(abi.encodePacked(address(this), fingerprints[tokenId]));
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        require(address(_metadataAddr) != address(0), "No metadata address");

        IPlaneMetadata metadata = IPlaneMetadata(_metadataAddr);
        string memory tokenSeed = getSeed(tokenId);
        return metadata.genMetadata(tokenSeed, tokenId);
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function mintTokens(uint8 num) external nonReentrant payable {
        require(phase >= SalePhase.Public, 'Not Public');
        require(pubMintedByWallet[msg.sender] + num <= maxMintsPerWallet, "Maxed per wallet");
        require(num * price <= msg.value, "Wrong price");
        require(!Address.isContract(msg.sender), "No contracts");

        pubMintedByWallet[msg.sender] += num;

        mintN(num, msg.sender);
    }

    function mintAllowlist(Coupon memory coupon, uint8 num) external nonReentrant payable {
        require(phase >= SalePhase.Presale, 'Not Presale');
        require(alMintedByWallet[msg.sender] + num <= coupon.max, 'max presale');
        require(num * presalePrice <= msg.value, "Wrong pprice");
        require( isVerified(CouponType.Presale, coupon, msg.sender), "invalid acoupon");

        alMintedByWallet[msg.sender] += num;

        mintN(num, msg.sender);
    }

    function mintClaim(Coupon memory coupon, uint8 num) external nonReentrant {
        require(phase >= SalePhase.Presale, 'Not Presale'); // 1
        require(claimedByWallet[msg.sender] + num <= coupon.max, 'max claim');
        require( isVerified(CouponType.Claim, coupon, msg.sender), "invalid ccoupon");

        claimedByWallet[msg.sender] += num;

        mintN(num, msg.sender);
    }

    function isVerified(CouponType couponType, Coupon memory coupon, address minter) internal view returns (bool) {
        bytes32 digest = keccak256( abi.encodePacked(couponType, minter, coupon.max) );
        digest = ECDSA.toEthSignedMessageHash(digest);

        address signer = ECDSA.recover(digest, coupon.v, coupon.r, coupon.s);

        require(signer != address(0), 'Invalid Sign');
        return signer == _adminSigner;
    }

    function mintN(uint8 num, address receiver) private {
        require(totalSupply() + numBurned + num <= maxSupply - reserved, "Sold out");

        for (uint256 i; i < num; i++) {
            uint tokenId = totalSupply() + numBurned;
            fingerprints[tokenId] = keccak256(abi.encodePacked(block.number, receiver, tokenId));
            _safeMint(receiver, tokenId);
        }

        emit MintedEvent(num);
    }

    function mintForOwner(uint8 num, address receiver) external nonReentrant onlyOwner {
        require(num <= reserved, "Exceed reserved");

        reserved = reserved - num;
        mintN(num, receiver);
    }

    function setContractURI(string memory uri) external onlyOwner {
        _contractURI = uri;
    }

    function setMetadata(address metadataAddr) external onlyOwner {
        _metadataAddr = metadataAddr;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function setPresalePrice(uint256 _newPrice) external onlyOwner {
        presalePrice = _newPrice;
    }

    function setNumReserved(uint256 n) external onlyOwner {
        reserved = n;
    }

    function setMaxSupply(uint256 max) external onlyOwner {
        maxSupply = max;
    }

    function setMaxMintsPerWallet(uint8 max) external onlyOwner {
        maxMintsPerWallet = max;
    }

    function setAdminSigner(address signer) external onlyOwner {
        _adminSigner = signer;
    }

    function setPhase(SalePhase newPhase) external onlyOwner {
        phase = newPhase;
    }

    function withdraw() public onlyOwner {
        uint256 _balance = address(this).balance;
        require(payable(msg.sender).send(_balance));
    }

    function enableBurn(bool state) external onlyOwner {
        burnEnabled = state;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        require(to != address(0) || burnEnabled, "burn disabled");
        super._beforeTokenTransfer(from, to, tokenId);
        if (to == address(0)) {
            numBurned ++;
        }
    }

}