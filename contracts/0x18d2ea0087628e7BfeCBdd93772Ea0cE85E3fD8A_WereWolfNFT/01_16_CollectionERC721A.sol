// SPDX-License-Identifier: MIT
// Author: Luca Di Domenico twitter.com/luca_dd7
pragma solidity ^0.8.9;

import 'erc721a/contracts/ERC721A.sol';
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract WereWolfNFT is
    ERC721A,
    AccessControl,
    Pausable,
    Ownable
{
    bytes32 public constant DEVELOPER = keccak256("DEVELOPER");
    uint256 public MAX_SUPPLY;
    uint256 public presale_mint_price;
    uint256 public publicsale_mint_price;
    string public baseURI;
    bool public presale;
    bool public publicsale;
    address public royaltyReceiver;
    uint256 public royaltyPercent;
    bytes32 private _merkleRootWhitelisted;

    event NewWOLFNFTMinted(uint256 firstTokenId, uint8 quantity, uint256 totalMinted);

    constructor() ERC721A("WEREWOLF NFT", "WOLF") {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(DEVELOPER, _msgSender());
        // this will be the owner
        // _transferOwnership(0x4787b141bAbf5351395d272Ed9FFf43f742C4A34);
        MAX_SUPPLY = 5555;
        _merkleRootWhitelisted = 0xb2dce894fd614a90306f425a6e8a0fcbf0ec0ae0185788284f7c53fac3983724;
        presale_mint_price = 0.049 ether;
        publicsale_mint_price = 0.059 ether;
        _pause();
        presale = false;
        publicsale = false;
        baseURI = "ipfs://bafybeid75ktylzyh6rdsy7uiymfri5jchwwosem74ig6e6zntqtemv75by/";
        royaltyReceiver = 0x4787b141bAbf5351395d272Ed9FFf43f742C4A34;
        royaltyPercent = 1000;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function publicsalemint(address _to, uint256 _amount) public payable whenNotPaused {
        require(publicsale, "public sale not started");
        require(msg.value >= publicsale_mint_price * _amount, "Wrong price");
        mint(_to, _amount);
    }

    function presalemint(bytes32[] calldata _merkleProof, address _to, uint256 _amount) public payable whenNotPaused {
        require(presale, "presale not started");
        require(msg.value >= presale_mint_price * _amount, "Wrong price");
        bytes32 _leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, _merkleRootWhitelisted, _leaf), "You are not Whitelisted.");
        mint(_to, _amount);
    }

    function mint(address _to, uint256 _amount) private {
        require(_amount <= 5, "wrong amount");
        require(
            _totalMinted() + _amount < MAX_SUPPLY,
            "no supply remaining"
        );
        _safeMint(_to, _amount);
    }

    function freeMint(address _to, uint256 _amount) public onlyRole(DEVELOPER) whenNotPaused {
        require(
            _totalMinted() + _amount < MAX_SUPPLY,
            "no supply remaining"
        );
        _safeMint(_to, _amount);
    }

    function royaltyInfo(uint256, uint256 salePrice)
        public
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = royaltyReceiver;
        royaltyAmount = (royaltyPercent * salePrice) / 10000;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyRole(DEVELOPER) {
        baseURI = uri;
    }

    function setRoyaltyReceiver(address _addr) public onlyRole(DEVELOPER) {
        royaltyReceiver = _addr;
    }

    function setRoyaltyPercent(uint256 _bp) public onlyRole(DEVELOPER) {
        royaltyPercent = _bp;
    }

    function setMerkleRoot(bytes32 _root) public onlyRole(DEVELOPER) {
        _merkleRootWhitelisted = _root;
    }

    function setPublicSaleMintPrice(uint256 _price) public onlyOwner {
        publicsale_mint_price = _price;
    }

    function setPreSaleMintPrice(uint256 _price) public onlyOwner {
        presale_mint_price = _price;
    }

    function withdraw() public onlyOwner {
        (bool sent, ) = _msgSender().call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    function setMaxSupply(uint256 _n) public onlyRole(DEVELOPER) {
        MAX_SUPPLY = _n;
    }

    function setPresale(bool _b) public onlyRole(DEVELOPER) {
        presale = _b;
    }

    function setPublicSale(bool _b) public onlyRole(DEVELOPER) {
        publicsale = _b;
    }

    function pause() public onlyRole(DEVELOPER) {
        _pause();
    }

    function unpause() public onlyRole(DEVELOPER) {
        _unpause();
    }

    function getAmountMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity
    ) internal override {
        super._beforeTokenTransfers(from, to, tokenId, quantity);
        require(!paused(), "ERC721Pausable: token transfer while paused");
    }
}