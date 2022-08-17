// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract ArtDistilled is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string _baseTokenURI;

    bool public paused = false;
    bool public onlyWhitelisted = false;
    mapping(address => bool) public whitelistedAddresses;
    mapping(address => uint) public mintedAddress;
    uint256 public price = 0.52 ether;

    uint256 private __phaseLimit = 1000;
    uint256 private __reserved = 100;
    address private __vault = 0x9F4b24f9AC3E32c15973471238B64e378f0eadfb;

    event WithdrawAll(uint256 _amt, address _to);
    event PhaseLimit(uint _limit);
    event SetURI(string _uri);
    event SetPrice(uint256 _newPrice);
    event WhitelistStatus(bool _state);
    event WhitelistUsers(address[] _wallets, bool _state);
    event PartnerMint(address _wallet, uint _num, uint _partnerID);

    constructor(string memory baseURI) ERC721("ArtHouse Spirits", "AHSD")  {
        setBaseURI(baseURI);
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    function getURI() external view returns (string memory){
        return _baseTokenURI;
    }
    function mint(uint _num) public payable {
        uint256 supply = totalSupply() + 1;
        require(!paused,                                 "Sale paused" );
        require(_num <= 3,                                "You can mint a maximum of 3 NFTs" );
        require(mintedAddress[msg.sender] + _num <= 3,    "Wallet cant mint only 3 NFTs" );
        require(supply + _num <= 20000 - __reserved,        "Exceeds maximum NFT supply" );
        require(supply + _num <= __phaseLimit,              "Can't mint more NFTs in this phase" );
        require(msg.value == price * _num,               "Ether sent is not correct" );

        if(onlyWhitelisted) {
            require(whitelistedAddresses[msg.sender],    "Wallet is not whitelisted");
        }

        for(uint256 i; i < _num; i++){
            _safeMint(msg.sender, supply + i );
            mintedAddress[msg.sender] += 1;
        }
        (bool success, ) = payable(__vault).call{value: msg.value}("");
        require(success,                                 "Can't transfer" );
    }
    function partnerMint(uint _num, uint _partnerID) external payable {
        mint(_num);
        emit PartnerMint(msg.sender, _num, _partnerID);
    }
    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }


    //@dev Owner setting set up
    function giveAway(address _to, uint256 _amount) external onlyOwner() {
        require( _amount <= __reserved, "Exceeds reserved NFT supply" );
        __reserved -= _amount;
        uint256 supply = totalSupply()+1;
        for(uint256 i; i < _amount; i++){
            _safeMint( _to, supply + i );
        }
    }
    function setVaultAddress(address _newAddress) external onlyOwner() {
        require( _newAddress != address(0), "Vault can not be set to the zero address" );
        __vault = _newAddress;
    }
    function withdrawAll() external onlyOwner() {
        (bool success, ) = payable(__vault).call{value: address(this).balance}("");
        require(success, "Can't transfer" );
        emit WithdrawAll(address(this).balance, __vault);
    }
    function setPhaseLimit(uint _limit) external onlyOwner() {
        __phaseLimit = _limit;
        emit PhaseLimit(_limit);
    }
    function setBaseURI(string memory baseURI) public onlyOwner() {
        _baseTokenURI = baseURI;
        emit SetURI(baseURI);
    }
    function setPrice(uint256 _newPrice) external onlyOwner() {
        price = _newPrice;
        emit SetPrice(_newPrice);

    }
    function setPause(bool _newState) external onlyOwner() {
        paused = _newState;
    }
    function setOnlyWhitelisted(bool _state) external onlyOwner() {
        onlyWhitelisted = _state;
        emit WhitelistStatus(_state);

    }
    function whitelistUsers(address[] calldata _wallets, bool _state) external onlyOwner() {
        for(uint256 i; i < _wallets.length; i++){
            whitelistedAddresses[_wallets[i]] = _state;
        }
        emit WhitelistUsers(_wallets, _state);

    }

}