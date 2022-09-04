//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract ToastyDroneCollection is ERC721A, ERC2981, Pausable, Ownable {
    using Strings for uint256;
    uint256 public  maxSupply = 4000;

    mapping(address => uint256) public freeMintedCount;
    string public baseUri;
    string public revealUri;
    bool public revealState;
    bool public canUserMint;

    mapping(bytes4 => bool) private _supportedInterfaces;
    address private _panAmDrones = 0x7C36fbFf9F9B3362175752a5675330D1Dc8c4085;
    address private _engineer = 0x6f51f5715f72E9c2200Ec6A6fe9942023fBE7BC3;
    uint256 private _price;

    constructor() ERC721A("Toasty Drone Collection", "TDC") {
        _setDefaultRoyalty(_panAmDrones, 750);
        baseUri = "https://gateway.pinata.cloud/ipfs/QmWxSanqt2XekjRF2sjbTf3WkzScS2GP44enghfXxqmNyA";
        _supportedInterfaces[0x80ac58cd] = true; // _INTERFACE_ID_ERC721
        _supportedInterfaces[0x2a55205a] = true; // _INTERFACE_ID_ERC2981 - Royalties interface
        _pause();
    }

    function _withdrawFromMint() private  {
        uint256 balance = address(this).balance;
        payable(_engineer).transfer(balance / 100 * 25);
        payable(_panAmDrones).transfer(balance / 100 * 75);
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
        require(canUserMint, "You can't mint now");
        _;
    }

    modifier onlyPossibleWithdraw() {
        require(address(this).balance > 0, "Insufficient Amount to withdraw");
        _;
    }

    modifier onlyPossibleReveal() {
        require(!revealState, "You have already revealed");
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

    function mint(uint256 quantity) external payable onlyPossibleMint(quantity) whenNotPaused {
        require(msg.value >= getPrice() * quantity, "insufficient funds");
        _mint(msg.sender, quantity);
        freeMintedCount[msg.sender] += quantity;
        _withdrawFromMint();
    }

    function setPrice(uint256 _settingPrice) external onlyOwner {
        _price = _settingPrice;
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

    function setRoyaltiesWalletAddress(address _royaltyWallet) external onlyOwner {
        _setDefaultRoyalty(_royaltyWallet, 750);
    }

    function withdrawFromMint() external onlyOwner onlyPossibleWithdraw {
        _withdrawFromMint();
    }

    function updatePanAmAddress(address _address) external onlyOwner {
        _panAmDrones = _address;
    }

    function updateEngineer(address _address) external onlyOwner {
        _engineer = _address;
    }
}