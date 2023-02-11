// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./LOVE.sol";
import "./Mallowland.sol";

contract Babymallows is ERC721A, Ownable {
    using Strings for uint256; 

    bool mintState = false;
    string public baseURI;

    uint256 public mintCost = 100 ether;    
    uint256 public maxSupply;
    
    LOVE loveContract;
    Mallowland mallowlandContract;
    constructor (
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        uint256 _maxSupply
    ) ERC721A(_name, _symbol){  
        setBaseURI(_initBaseURI);
        maxSupply = _maxSupply;
    }

    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }

    function tokenURI(uint256 token_id) public view override returns (string memory) {
        require(_exists(token_id), "nonexistent token");
        return bytes(baseURI).length > 0 ? 
        string(abi.encodePacked(baseURI, token_id.toString())) : "";
    }

    function mint(uint256 _mintAmount) external{ 
        require(mintState, "CLOSED"); 
        require(_mintAmount > 0, "Amount invalid");
        uint256 metamallowBalance = mallowlandContract.balanceOf(msg.sender);
        require(metamallowBalance > 0 &&
        metamallowBalance >= (numberMinted(msg.sender) + _mintAmount), "Mints exceeded");
        require((totalSupply() + _mintAmount) <= maxSupply, "Sold out"); 
        loveContract.burn(msg.sender, _mintAmount * mintCost);
        _safeMint(msg.sender, _mintAmount); 
    }

    function numberMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }

    function airdropsBulk(address[] calldata _airdropWallets, uint256[] calldata _mintAmounts) external onlyOwner(){
        require(_airdropWallets.length == _mintAmounts.length, "Missing parameters");
        require((totalSupply() + _airdropWallets.length) <= maxSupply, "Cannot mint more");
        for (uint i =0; i < _airdropWallets.length; i++) {
            _safeMint(_airdropWallets[i], _mintAmounts[i]);
        }
    }

    function airdrop(address _airdropWallet, uint256 quantity) external onlyOwner(){
        require((totalSupply() + quantity) <= maxSupply, "Cannot mint more");
        _safeMint(_airdropWallet, quantity);
    }

    function setSupply(uint256 _newMaxSupply) external onlyOwner(){
        maxSupply = _newMaxSupply;
    }

    function setDependencies(address _loveAddress, address _mallowLandAddress) external onlyOwner{
        loveContract = LOVE(_loveAddress);
        mallowlandContract = Mallowland(_mallowLandAddress);
    }

    function setSale(bool _saleState) external onlyOwner(){
        mintState = _saleState;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner(){
        baseURI = _newBaseURI;
    }
}