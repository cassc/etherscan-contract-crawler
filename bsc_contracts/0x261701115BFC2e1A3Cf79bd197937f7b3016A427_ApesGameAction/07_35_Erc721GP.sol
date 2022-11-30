// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./interface/ILaunchpadNFT.sol";

contract Erc721GP is ERC721Upgradeable, OwnableUpgradeable, ILaunchpadNFT {
    using SafeMathUpgradeable for uint256;
    string private uri;
    mapping(address => bool) public admin;

    string private name_;
    string private symbol_;

    function initialize(string memory _name, string memory _symbol)
        public
        initializer
    {
        __ERC721_init(_name, _symbol);
        __Ownable_init();
        setNameSymbol(_name, _symbol);
    }

    function setNameSymbol(string memory _name, string memory _symbol)
        public
        onlyAdmin
    {
        name_ = _name;
        symbol_ = _symbol;
    }

    function name() public view virtual override returns (string memory) {
        return name_;
    }

    function symbol() public view virtual override returns (string memory) {
        return symbol_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uri;
    }

    function mint(uint256 tokenId) external onlyAdmin {
        _mint(msg.sender, tokenId);
    }

    function adminMintTo(address to, uint256 tokenId) external onlyAdmin {
        _mint(to, tokenId);
    }

    function burn(uint256 _id) external {
        require(
            _isApprovedOrOwner(msg.sender, _id),
            "ERC721: burn caller is not owner nor approved"
        );
        _burn(_id);
    }

    function atransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {
        transferFrom(from, to, tokenId);
    }

    function setBaseURI(string memory _uri) external onlyAdmin {
        uri = _uri;
    }

    function setAdmin(address user, bool _auth) external onlyOwner {
        admin[user] = _auth;
    }

    modifier onlyAdmin() {
        require(
            admin[msg.sender] || owner() == msg.sender,
            "Admin: caller is not the admin"
        );
        _;
    }

    function gameFallback(uint256 start, uint256 end) external onlyOwner {
        for (uint256 i = start; i < end; i++) {
            if (_exists(i)) {
                _burn(i);
            }
        }
    }


    uint256 private launchMaxSupply;    // max launch supply
    uint256 private launchSupply;        // current launch supply

    address public launchpad;
    uint256[] public launchpadTokenIds;

    modifier onlyLaunchpad() {
        require(launchpad != address(0), "launchpad address must set");
        require(msg.sender == launchpad, "must call by launchpad");
        _;
    }

    function setLaunchpad(address launchpad_) external onlyOwner {
        launchpad = launchpad_;
    }

    function addLaunchpadSupply(uint256[] memory tokenIds) external onlyAdmin {
        require(tokenIds.length > 0, "tokenids length must greter than zero");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(!_exists(tokenIds[i]), "tokenid minted");
            launchpadTokenIds.push(tokenIds[i]);
        }
        launchMaxSupply = launchMaxSupply.add(tokenIds.length);
    }
    
    function cleanLaunchpadSupply() external onlyAdmin {
        require(launchSupply.add(launchpadTokenIds.length) == launchMaxSupply, "Launchmaxsupply must be equal to launchsupply + launchpadTokenIds.length");
        launchMaxSupply = launchMaxSupply.sub(launchpadTokenIds.length);
        delete launchpadTokenIds;
    }

    function getMaxLaunchpadSupply() public view override returns (uint256) {
        return launchMaxSupply;
    }

    function getLaunchpadSupply() public view override returns (uint256) {
        return launchSupply;
    }

    function mintTo(address to, uint256 size) external override onlyLaunchpad {
        require(to != address(0), "can't mint to empty address");
        require(size > 0, "size must greater than zero");
        require(launchSupply + size <= launchMaxSupply, "max supply reached");

        for (uint256 i=1; i <= size; i++) {
            uint256 _num = randomNum(launchpadTokenIds.length);
            uint256 tokensLen = launchpadTokenIds.length.sub(1);
            uint256 tokenid = launchpadTokenIds[tokensLen];
            if(_num != tokensLen){
                tokenid = launchpadTokenIds[_num];
                launchpadTokenIds[_num] = launchpadTokenIds[tokensLen];
            }
            launchpadTokenIds.pop();
            _mint(to, tokenid);
            launchSupply++;
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(ILaunchpadNFT).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function randomNum(uint256 range) internal view returns(uint256){
      return uint256(keccak256(abi.encodePacked(launchSupply, block.difficulty, block.gaslimit, block.number, block.timestamp))).mod(range);
    }

    function adminMintsTo(address[] memory _tos, uint256[] memory _tokenIds) external onlyAdmin {
        require(_tos.length == _tokenIds.length, "length mismatch");
        for(uint256 i = 0; i<_tokenIds.length; i++){
            if(!_exists(_tokenIds[i])) {
                _mint(_tos[i], _tokenIds[i]);
            }
        }
    }

    mapping (address => bool) public bridgeAddrs;
    modifier onlyBridge() {
        require(bridgeAddrs[_msgSender()] || owner() == msg.sender, "Bridge: caller is not the bridge or owner");
        _;
    }

    function setBridge(address _bridge, bool _auth) external onlyOwner{
        bridgeAddrs[_bridge] = _auth;
    }

    function checkBridge(uint256) external view onlyBridge returns(bool pass) {
        return true;
    }
    function bridgeMint(address _to, uint256 _tokenID) external onlyBridge {
        _mint(_to, _tokenID);
    }
    function bridgeBurn(uint256 _tokenID) external onlyBridge{
        require(_isApprovedOrOwner(_msgSender(), _tokenID), "ERC721: burn caller is not owner nor approved");
        _burn(_tokenID);
    }
}