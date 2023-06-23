// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// @author: olive

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
///                                                                                                       ///
///                                                                                                       ///
///      ___ _     _ _ _ _         ___ _                          _                        _____  ___     ///
///     / __\ |__ (_) | (_)_ __   / __\ |__   __ _ _ __ ___   ___| | ___  ___  _ __  ___  |___ / / _ \    ///
///    / /  | '_ \| | | | | '_ \ / /  | '_ \ / _` | '_ ` _ \ / _ \ |/ _ \/ _ \| '_ \/ __|   |_ \| | | |   ///
///   / /___| | | | | | | | | | / /___| | | | (_| | | | | | |  __/ |  __/ (_) | | | \__ \  ___) | |_| |   ///
///   \____/|_| |_|_|_|_|_|_| |_\____/|_| |_|\__,_|_| |_| |_|\___|_|\___|\___/|_| |_|___/ |____(_)___/    ///
///                                                                                                       ///
///                                                                                                       ///
///                                                                                                       ///
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract ChillinChameleons3 is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Strings for uint256;

    uint256 public MAX_ELEMENTS = 6999;
    uint256 public PRICE = 0.09 ether;
    uint256 public constant START_AT = 1;
    uint256 public TIME_LIMIT = 60;
    uint256 public LIMIT_PER_MINT = 20;
    
    uint256[] public wwTokensUsed;
    uint256[] public ccTokensUsed;
    uint256[] public stTokensUsed;

    bool private PAUSE = true;
    bool private PAUSE_FREEMINT = true;

    Counters.Counter private _tokenIdTracker;

    string public baseTokenURI;

    bool public META_REVEAL = false;
    uint256 public HIDE_FROM = 1;
    uint256 public HIDE_TO = 6999;
    string public sampleTokenURI;

    address public constant creator1Address = 0x9933cb6634AE84D068F2C26a493a0Be5A8FAD38B;
    address public constant creator2Address = 0x202C80c248705894f46722761A3c7faa3F40A9Ee;

    mapping(address => bool) internal admins;
    mapping(address => uint256) mintTokens;
    mapping(address => uint256) freemintTokens;
    mapping(address => uint256) lastCheckPoint;

    event PauseEvent(bool pause);
    event welcomeToCC3(uint256 indexed id);
    event NewPriceEvent(uint256 price);
    event NewMaxElement(uint256 max);

    constructor(string memory baseURI) ERC721("Chillin Chameleons 3.0", "CC3.0"){
        setBaseURI(baseURI);
    }

    modifier saleIsOpen {
        require(totalToken() <= MAX_ELEMENTS, "Soldout!");
        require(!PAUSE, "Sales not open");
        _;
    }

    modifier freemintIsOpen {
        require(totalToken() <= MAX_ELEMENTS, "Soldout!");
        require(!PAUSE_FREEMINT, "Sales not open");
        _;
    }

    modifier onlyAdmin() {
        require(admins[_msgSender()], 'Caller is not the admin');
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setSampleURI(string memory sampleURI) public onlyOwner {
        sampleTokenURI = sampleURI;
    }

    function totalToken() public view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function totalWWTokensUsed() public view returns (uint256 [] memory) {
        return wwTokensUsed;
    }

    function totalCCTokensUsed() public view returns (uint256 [] memory) {
        return ccTokensUsed;
    }

    function totalSTTokensUsed() public view returns (uint256 [] memory) {
        return stTokensUsed;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if(!META_REVEAL && tokenId >= HIDE_FROM && tokenId <= HIDE_TO) 
            return sampleTokenURI;
        
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function mintTokensOfWallet(address _wallet) public view returns (uint256) {
        return mintTokens[_wallet];
    }

    function freemintTokensOfWallet(address _wallet) public view returns (uint256) {
        return freemintTokens[_wallet];
    }

    function freemint(uint256 _tokenAmount, uint256 _timestamp, bytes memory _signature, uint[] memory _wwTokens, uint[] memory _ccTokens, uint[] memory _stTokens) public freemintIsOpen {

        uint256 total = totalToken();
        require(total + _tokenAmount <= MAX_ELEMENTS, "Max limit");

        address wallet = _msgSender();

        address signerOwner = signatureWalletForFreemint(wallet,_tokenAmount,_timestamp,_signature);
        require(signerOwner == owner(), "Not authorized to mint");

        require(block.timestamp >= _timestamp - TIME_LIMIT, "Out of time");
        require(_timestamp > lastCheckPoint[wallet], "Invalid timestamp");

        lastCheckPoint[wallet] = block.timestamp;
        freemintTokens[wallet] += _tokenAmount;

        for(uint8 i = 0; i < _wwTokens.length; i++) {
            wwTokensUsed.push(_wwTokens[i]);
        }
        for(uint8 i = 0; i < _ccTokens.length; i++) {
            ccTokensUsed.push(_ccTokens[i]);
        }
        for(uint8 i = 0; i < _stTokens.length; i++) {
            stTokensUsed.push(_stTokens[i]);
        }
        for(uint8 i = 1; i <= _tokenAmount; i++){
            _mintAnElement(wallet, total + i);
        }
    }

    function mint(uint256 _tokenAmount, uint256 _tokenPrice, uint256 _timestamp, bytes memory _signature) public payable saleIsOpen {

        uint256 total = totalToken();
        require(_tokenAmount <= LIMIT_PER_MINT, "Max limit per mint");
        require(total + _tokenAmount <= MAX_ELEMENTS, "Max limit");
        require(msg.value >= price(_tokenPrice, _tokenAmount), "Value below price");

        address wallet = _msgSender();

        address signerOwner = signatureWallet(wallet,_tokenAmount,_tokenPrice,_timestamp,_signature);
        require(signerOwner == owner(), "Not authorized to mint");

        require(block.timestamp >= _timestamp - TIME_LIMIT, "Out of time");
        require(_timestamp > lastCheckPoint[wallet], "Invalid timestamp");

        lastCheckPoint[wallet] = block.timestamp;

        mintTokens[wallet] += _tokenAmount;
        for(uint8 i = 1; i <= _tokenAmount; i++){
            _mintAnElement(wallet, total + i);
        }

    }

    function signatureWallet(address wallet, uint256 _tokenAmount, uint256 _tokenPrice, uint256 _timestamp, bytes memory _signature) public pure returns (address){

        return ECDSA.recover(keccak256(abi.encode(wallet, _tokenAmount, _tokenPrice, _timestamp)), _signature);

    }

    function signatureWalletForFreemint(address wallet, uint256 _tokenAmount, uint256 _timestamp, bytes memory _signature) public pure returns (address){

        return ECDSA.recover(keccak256(abi.encode(wallet, _tokenAmount, _timestamp)), _signature);

    }

    function setCheckPoint(address _minter, uint256 _point) public onlyOwner {
      require(_minter != address(0), "Unknown address");
      lastCheckPoint[_minter] = _point;
    }

    function getCheckPoint(address _minter) external view returns (uint256) {
      return lastCheckPoint[_minter];
    }

    function _mintAnElement(address _to, uint256 _tokenId) private {

        _tokenIdTracker.increment();
        _safeMint(_to, _tokenId);

        emit welcomeToCC3(_tokenId);
    }

    function price(uint256 _price, uint256 _count) public pure returns (uint256) {
        return _price.mul(_count);
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function setPause(bool _pause) public onlyOwner{
        PAUSE = _pause;
        emit PauseEvent(PAUSE);
    }

    function setFreemintPause(bool _pause) public onlyOwner{
        PAUSE_FREEMINT = _pause;
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

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(creator1Address, balance * 85 / 100);
        _widthdraw(creator2Address, balance * 15 / 100);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function giftMint(address[] memory _addrs, uint[] memory _tokenAmounts) public onlyOwner {
        uint totalQuantity = 0;
        uint256 total = totalToken();
        for(uint i = 0; i < _addrs.length; i ++) {
            totalQuantity += _tokenAmounts[i];
        }
        require( total + totalQuantity <= MAX_ELEMENTS, "Max limit" );
        for(uint i = 0; i < _addrs.length; i ++){
            for(uint j = 0; j < _tokenAmounts[i]; j ++){
                total ++;
                _mintAnElement(_addrs[i], total);
            }
        }
    }

    function mintUnsoldTokens(uint256[] memory _tokensId) public onlyOwner {

        require(PAUSE, "Pause is disable");

        for (uint256 i = 0; i < _tokensId.length; i++) {
            if(rawOwnerOf(_tokensId[i]) == address(0)){
                _mintAnElement(owner(), _tokensId[i]);
            }
        }
    }

    function addAdminRole(address _address) external onlyOwner {
        admins[_address] = true;
    }

    function revokeAdminRole(address _address) external onlyOwner {
        admins[_address] = false;
    }

    function hasAdminRole(address _address) external view returns (bool) {
        return admins[_address];
    }

    function burn(uint256 tokenId) external onlyAdmin {
        _burn(tokenId);
    }

    function updateTimeLimit(uint256 _timeLimit) public onlyOwner {
      TIME_LIMIT = _timeLimit;
    }
}