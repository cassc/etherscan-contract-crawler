//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract WaifuClanCollection is ERC721A, ERC2981, Pausable, Ownable {
    using Strings for uint256;
    uint256 public  maxSupply = 1000;
    uint256 public constant FREE_MINT_LIMIT = 2;
    mapping(address => uint256) public freeMintedCount;
    mapping(address => bool) private _wlUserList;
    string public baseUri;
    string public revealUri;

    mapping(bytes4 => bool) private _supportedInterfaces;
    address private _treasuryAccount = 0x6f51f5715f72E9c2200Ec6A6fe9942023fBE7BC3;
    uint256 private _price;

    bool public revealState;
    bool public canUserMint;
    constructor() ERC721A("Waifu Clan Collection", "UwU"){
        _setDefaultRoyalty(_treasuryAccount, 1000);
        baseUri = "https://ipfs.io/ipfs/QmaUho6kP2QcZwi4vDNkUM6siezFXfaieotvYKWG75zxcW/";
        _supportedInterfaces[0x80ac58cd] = true;        // _INTERFACE_ID_ERC721
        _supportedInterfaces[0x2a55205a] = true;        // _INTERFACE_ID_ERC2981            Royalties interface
        _pause();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    modifier onlyPossibleMint(uint256 quantity) {
        require(quantity > 0, "Invalid amount");
        require(totalSupply() + quantity <= maxSupply, "Exceed amount");
        require(freeMintedCount[msg.sender] + quantity <= FREE_MINT_LIMIT, "Already Minted");
        require(canUserMint, "You can't mint now");
        _;
    }

    modifier onlyPossibleReveal() {
        require(!revealState, "You have already revealed");
        _;
    }

    modifier onlyPossibleAirdrop(address user, uint256 quantity) {
        require(freeMintedCount[user] + quantity <= FREE_MINT_LIMIT && quantity > 0, "Can't airdrop for user");
        _;
    }

    function changeMintingStatus() external onlyOwner {
        bool _canUserMint = canUserMint;
        _canUserMint ? _pause() : _unpause();
        canUserMint = !_canUserMint;
    }

    function _baseURI() internal view override returns(string memory) {
        return baseUri;
    }

    function getNextTokenId() public view returns(uint256) {
        return _nextTokenId();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns(bool) {
        return super.supportsInterface(interfaceId) || interfaceId == type(ERC2981).interfaceId || _supportedInterfaces[interfaceId];
    }

    function tokenURI(uint256 tokenId) public view override returns(string memory) {
        require(_exists(tokenId), "Token Does Not Exist");
        return revealState ? revealUri : baseUri;
    }

    function getPrice() public view returns(uint256) {
        return _price;
    }

    function isWhitelistAddress() public view returns(bool) {
        return _wlUserList[msg.sender];
    }

    function _noWaifuListMint(uint256 quantity) private {
        require(msg.value >= getPrice() * quantity, "insufficient funds");
        _mint(msg.sender, quantity);
    }

    function mint(uint256 quantity) external payable onlyPossibleMint(quantity) whenNotPaused {
        if ( !isWhitelistAddress()) {
            _noWaifuListMint(quantity);
        } else {
            _mint(msg.sender, quantity);
        }
        freeMintedCount[msg.sender] += quantity;
    }

    function mintForAdmin(uint256 quantity) external onlyOwner whenPaused{
        require(canUserMint, "Should change Mint status");
        _mint(msg.sender, quantity);
        freeMintedCount[msg.sender] += quantity;
    }

    function setPrice(uint256 _settingPrice) external onlyOwner {
        _price = _settingPrice;
    }

    function mintFor(address user, uint256 quantity) external onlyOwner onlyPossibleAirdrop(user, quantity) {
        _mint(user, quantity);
        freeMintedCount[user] += quantity;
    }

    function setBaseUri(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    function setRevealUri(string memory _baseUri) external onlyOwner {
        revealUri = _baseUri;
    }

    function reveal() external onlyOwner onlyPossibleReveal {
        revealState = true;
    }

    function setTotalSupply(uint256 quantity) external onlyOwner {
        maxSupply = quantity;
    }

    function setWlList(address[] memory wlList) external onlyOwner {
        for ( uint256 i = 0; i < wlList.length; i++ ) {
            _wlUserList[wlList[i]] = true;
        }
    }

    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setRoyaltiesWalletAddress(address _royaltyWallet) external onlyOwner {
        _setDefaultRoyalty(_royaltyWallet, 1000);
    }
}