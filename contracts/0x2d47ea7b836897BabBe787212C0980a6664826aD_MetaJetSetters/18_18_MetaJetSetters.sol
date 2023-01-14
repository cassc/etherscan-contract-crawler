// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
/*
    Author(s): MJS
*/

contract MetaJetSetters is Ownable, ERC721Enumerable, ReentrancyGuard{
    address private signerAddress;

    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Strings for uint256;


    uint256 public MAX_ELEMENTS = 800;
    uint256 public PRICE = 1.27 ether;
    uint256 public constant START_AT = 1;

    bool private PAUSE = true;

    Counters.Counter private _tokenIdTracker;

    string public baseTokenURI;
    string public sampleTokenURI;
    
    bool public META_REVEAL = false;
    uint256 public HIDE_FROM = 1;
    uint256 public HIDE_TO = 800;

    address public constant creatorAddress = 0x2E8e633F698962c6ca86E4253ABb54AA5799d6eE;

    mapping(address => bool) internal admins;

    event PauseEvent(bool pause);
    event welcomeToMJS(uint256 indexed id, address wallet);
    event NewPriceEvent(uint256 price);
    event NewMaxElement(uint256 max);

    constructor (address _signatureAddress) ERC721("Meta Jet Setters", "MJS"){
        signerAddress = _signatureAddress;
        admins[msg.sender] = true;

    }

    modifier onlyAdmin(){
        require(admins[_msgSender()], "MJS: Caller is not Admin");
        _;
    }

    modifier saleIsOpen() {
        require(totalToken() <= MAX_ELEMENTS, "MJS: Soldout!");
        require(!PAUSE, "MJS: Sale is not open yet");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function totalToken() public view returns(uint256){
        return _tokenIdTracker.current();
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory){
        require(_exists(_tokenId), "MJS: URI Query for non-existent token");

        if(!META_REVEAL || (_tokenId >= HIDE_FROM && _tokenId < HIDE_TO)){
            return sampleTokenURI;
        }else{
            string memory baseURI = _baseURI();
            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString())) : "";
        }
    }

    function mint(uint256 _tokenAmount, uint256 _timestamp, bytes memory _signature) public payable saleIsOpen{
        uint256 total = totalToken();
        require(_tokenAmount <= 50, "MJS: Minting Too Many!");
        require(total + _tokenAmount <= MAX_ELEMENTS, "MJS: Max Limit!");
        require(msg.value >= price(_tokenAmount), "MJS: Value below Price");

        address wallet = _msgSender();

        address signerOwner = signatureWallet(wallet, _tokenAmount, _timestamp, _signature);
        require(signerOwner == signerAddress, "MJS: Signautre Invalid");

        require(block.timestamp >= _timestamp - 30, "MJS: Out of time");

        for(uint8 i = 1; i <= _tokenAmount; i++){
            _mintAnElement(wallet, total+i);
        }
    }

    function signatureWallet(address wallet, uint256 _tokenAmount, uint256 _timestamp, bytes memory _signature) public pure returns (address){
        return ECDSA.recover(keccak256(abi.encode(wallet, _tokenAmount, _timestamp)), _signature);
    }

    function _mintAnElement(address _to, uint256 _tokenId) private {
        _tokenIdTracker.increment();
        _safeMint(_to, _tokenId);
        emit welcomeToMJS(_tokenId, _to);
    }

    function price(uint256 _count) public view returns (uint256) {
        return PRICE.mul(_count);
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory){
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i = 0; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function withdrawAll() public onlyOwner{
        uint256 balance = address(this).balance;
        require(balance > 0, "MJS: Not Enough Balance");
        _withdraw(_msgSender(), address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private{
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "MJS: Transfer Failed");
    }

    function giftMint(address[] memory _addresses, uint[] memory _tokenAmounts) public onlyOwner{
        uint256 totalQuantity = 0;
        uint256 total = totalToken();
        for(uint i = 0; i < _addresses.length; i++){
            totalQuantity += _tokenAmounts[i];
        }

        require(total+totalQuantity <= MAX_ELEMENTS, "MJS: Max Limit!");
        for(uint i = 0; i < _addresses.length; i++){
            for(uint j = 0; j < _tokenAmounts[i]; j++){
                total ++;
                _mintAnElement(_addresses[i], total);
            }
        }
    }

    function mintUnsoldTokens(uint256[] memory _tokensId) public onlyOwner{
        require (PAUSE, "MJS: Mint isn't paused");

        for(uint256 i = 0; i < _tokensId.length; i++){
            if(rawOwnerOf(_tokensId[i]) == address(0)){
                _mintAnElement(owner(), _tokensId[i]);
            }
        }
    }

    function burn(uint256[] calldata tokenIds) external onlyAdmin{
        for (uint8 i = 0; i < tokenIds.length; i++){
            _burn(tokenIds[i]);
        }
    }

    function setBaseURI(string memory _baseURI) public onlyOwner{
        baseTokenURI = _baseURI;
    }

    function setSampleURI(string memory _sampleURI) public onlyOwner{
        sampleTokenURI = _sampleURI;
    }

    function setSignerAddress(address _signer) public onlyOwner{
        signerAddress = _signer;
    }

    function addAdminRole(address _address) external onlyOwner{
        admins[_address] = true;
    }

    function revokeAdminRole(address _address) external onlyOwner{
        admins[_address] = false;
    }

    function hasAdminRole(address _address) external view returns (bool){
        return admins[_address];
    }

    function setPause(bool _pause) public onlyOwner{
        PAUSE = _pause;
        emit PauseEvent(_pause);
    }

    function setPrice(uint256 _price) public onlyOwner{
        PRICE = _price;
        emit NewPriceEvent(PRICE);
    }

    function setMaxElement(uint256 _max) public onlyOwner{
        MAX_ELEMENTS = _max;
        emit NewMaxElement(MAX_ELEMENTS);
    }

    function setMetaReveal(bool _reveal, uint256 _from, uint256 _to) public onlyOwner{
        META_REVEAL = _reveal;
        HIDE_FROM = _from;
        HIDE_TO = _to;
    }
}