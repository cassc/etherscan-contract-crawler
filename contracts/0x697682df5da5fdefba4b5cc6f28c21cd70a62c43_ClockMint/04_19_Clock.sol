// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.13;

import "./ERC721.sol";
import "./IERC20.sol";
import "./IEIP2981.sol";
import "./AdminControl.sol";
import "./Strings.sol";
import './base64.sol';
import "./ClockURI.sol";


contract Clock is ERC721, AdminControl {
    
    uint256 private _royaltyAmount; //in % 
    uint256 public _tokenId;
    uint256 public _maxSupply = 200;

    mapping(uint => string) _modes;
    mapping(uint => string) _wallColors;
    mapping(uint => uint) _chronos;
    mapping(uint => uint) _timers;
    mapping(uint => uint) _alarms;
    mapping(uint => string) _opacities;
    mapping(uint => string) _clockFills;
    mapping(uint => string) _clockFrames;
    mapping(uint => string) _clockScreen;
    mapping(uint => string) _ledColors;
    mapping(uint => string) _shadows;

    address payable private _royalties_recipient;
    address _clockURIAddress;

    string[] public _colorOptions;
    string[] public _opacitiesOptions;
    string[] public _clockOutlinesOptions;
    string[] public _clockFillsOptions;
    string[] public _screenColorsOptions;
    string[] public _ledColorsOptions;
    string[] public _shadowsOptions;

    bool _clocksHacked;
    bool _publicMintOpened;
    
    struct Hack{
        string value;
        string mode;
        uint256 chrono;
        uint256 timer;
        uint256 alarm;
    }

    Hack _hack;

    constructor () ERC721("ETH Clock", "ETH Clock") {
        _royalties_recipient = payable(msg.sender);
        _royaltyAmount = 10;
        _tokenId = 0;
        _clockURIAddress = 0xeEAb674E788cC7Da0624bc555bC5aEfEf9F2881B;
        _colorOptions = ['ffd097', 'f8a7a7', 'c3d5fc', 'a0e3a1', 'f0eb5b', 'a3a3a3'];
        _opacitiesOptions = ['0', '3', '6'];
        _clockOutlinesOptions = ['fff', '000'];
        _clockFillsOptions = ['752125', 'c90000', '00a331', '7202b3'];
        _screenColorsOptions = ['cccccc', 'fff', '1e1e1e'];
        _ledColorsOptions = ['ff000c', '008700', '0074b8','ffa200'];
        _shadowsOptions = ['0','1','2','3'];
    } 

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AdminControl)
        returns (bool)
    {
        return
        AdminControl.supportsInterface(interfaceId) ||
        ERC721.supportsInterface(interfaceId) ||
        interfaceId == type(IEIP2981).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function adminMint(
        address account
    ) external adminRequired{
        require(_tokenId + 1 < _maxSupply);
        _mint(account, _tokenId);
        _modes[_tokenId] = 'Clock';
        _wallColors[_tokenId] = _colorOptions[getPseudoRndNum(_colorOptions.length, account)];
        _opacities[_tokenId] = _opacitiesOptions[getPseudoRndNum(_opacitiesOptions.length, account)];
        _clockFills[_tokenId] = _clockFillsOptions[getPseudoRndNum(_clockFillsOptions.length, account)];
        _clockFrames[_tokenId] = _clockOutlinesOptions[getPseudoRndNum(_clockOutlinesOptions.length, account)];
        _clockScreen[_tokenId] = _screenColorsOptions[getPseudoRndNum(_screenColorsOptions.length, account)];
        _ledColors[_tokenId] = _ledColorsOptions[getPseudoRndNum(_ledColorsOptions.length, account)];
        _shadows[_tokenId] = _shadowsOptions[getPseudoRndNum(_shadowsOptions.length, account)];
        _tokenId += 1;
    }

    function getPseudoRndNum(uint256 length, address account) public view returns (uint256){    
        uint256 rnd = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _tokenId, length, msg.sender, account))) % length;
        return rnd;   
    }

    function setTimer(uint256 tokenId, uint256 blocks) external {
        require(msg.sender == ownerOf(tokenId));
        require(blocks > 0, "The block number needs to be positive");
        _modes[tokenId] = 'Timer';
        _timers[tokenId] = block.number + blocks;
    }

    function setAlarm(uint256 tokenId, uint256 targetBlock) external {
        require(msg.sender == ownerOf(tokenId));
        require(targetBlock > block.number, "An alarm needs to be in the future");
        _modes[tokenId] = 'Alarm';
        _alarms[tokenId] = targetBlock;
    }

    function setChrono(uint256 tokenId) external {
        require(msg.sender == ownerOf(tokenId));
        _modes[tokenId] = 'Chrono';
        _chronos[tokenId] = block.number;
    }

    function resetClock(uint256 tokenId) external {
        require(msg.sender == ownerOf(tokenId));
        _modes[tokenId] ='Clock';
    }

    function setClockURIAddress(address clockURIAddress) external adminRequired{
        _clockURIAddress = clockURIAddress;
    }

    function hackClocks(
        string calldata value,
        string calldata mode,
        uint256 timer,
        uint256 alarm
    )external adminRequired{
        require(alarm > block.number);
        require(timer > 0);
        _clocksHacked = true;
        _hack.value = value;
        _hack.mode = mode;
        _hack.chrono = block.number;
        _hack.timer =  block.number + timer;
        _hack.alarm = alarm;
    }

    function restoreClocks()external adminRequired{
        _clocksHacked = false;
    }
    
    function getClockValue(uint256 tokenId) internal view returns(string memory value){
        string memory clockValue = Strings.toString(block.number);
        string memory mode = _clocksHacked ? _hack.mode : _modes[tokenId];
        if(keccak256(bytes(mode)) == keccak256("Timer")){
            uint256 timer = _clocksHacked ? _hack.timer : _timers[tokenId];
            if(block.number >= timer){
                clockValue =  _clocksHacked ? _hack.value : "0000000000";
            }else{
                clockValue = Strings.toString(timer - block.number);
            }
        }else if(keccak256(bytes(mode)) == keccak256('Chrono')) {
            uint256 chrono = _clocksHacked ? _hack.chrono : _chronos[tokenId];
            clockValue = Strings.toString(block.number - chrono);
        }

        uint256 clockValueLength = bytes(clockValue).length;
        if(clockValueLength<10 && keccak256(bytes(clockValue)) != keccak256(bytes(_hack.value))){
            for(uint256 i=0;i<(10-clockValueLength); i++){
                clockValue = string.concat("0", clockValue) ;
            }
        }
        return clockValue;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId));
        string memory clockValue = getClockValue(tokenId);
        string memory wallColor = _clocksHacked ? '000' : _wallColors[tokenId];
        string memory mode = _clocksHacked ? _hack.mode : _modes[tokenId];
        uint256 timer = _clocksHacked ? _hack.timer : _timers[tokenId];
        uint256 alarm = _clocksHacked ? _hack.alarm : _alarms[tokenId];
        string[9] memory clockCustomization = [
            clockValue, 
            mode,
            wallColor, 
            _opacities[tokenId], 
            _clockFills[tokenId], 
            _clockFrames[tokenId], 
            _clockScreen[tokenId], 
            _ledColors[tokenId],
            _shadows[tokenId]];

        string memory uri = ClockURI(_clockURIAddress).buildURI(
            clockCustomization,
            timer,
            alarm
        );
        return uri;
    }

    function burn(uint256 tokenId) public {
        require(ownerOf(tokenId)== msg.sender, "You can only burn your own tokens");
        _burn(tokenId);
    }

    function setRoyalties(address payable _recipient, uint256 _royaltyPerCent) external adminRequired {
        _royalties_recipient = _recipient;
        _royaltyAmount = _royaltyPerCent;
    }

    function royaltyInfo(uint256 salePrice) external view returns (address, uint256) {
        if(_royalties_recipient != address(0)){
            return (_royalties_recipient, (salePrice * _royaltyAmount) / 100 );
        }
        return (address(0), 0);
    }

    function withdraw(address recipient) external adminRequired {
        payable(recipient).transfer(address(this).balance);
    }

}   