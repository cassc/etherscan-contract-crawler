// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * /@@@@@@@@@@@@@@@@@@@@&&################&&@@@@@@@@@@@@@@@@@@@@/
 * /@@@@@@@@@@@@@@@@&##&&@@@@@@@@@@@@@@@@@@&&##&@@@@@@@@@@@@@@@@/
 * /@@@@@@@@@@@@&##&@@@@@@@@@@@@@@@@@@@@@@@@@@@@&##&@@@@@@@@@@@@/
 * /@@@@@@@@@@##&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&##@@@@@@@@@@/
 * /@@@@@@@@##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##@@@@@@@@/
 * /@@@@@@#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B#@@@@@@/
 * /@@@@&G&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&G&@@@@/
 * /@@@&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G&@@@/
 * /@@#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G#@@/
 * /@&[email protected]@@@@@@@@@@[email protected][email protected]@@@@@@[email protected]@@@&!&@7!????Y&@@@@@@@@@P&@/
 * /@P&@@@@@@@@@@Y!#@&[email protected][email protected]@@@@@@[email protected]@@@#^#@[email protected]@@&[email protected]@@@@@@@@&[email protected]/
 * /&[email protected]@@@@@@@@@[email protected]@@@@@@[email protected]@@@@@@[email protected]@@@&J&@Y5&&&#[email protected]@@@@@@@@@G&/
 * /G#@@@@@@@@@@[email protected]@@@@@@[email protected]@@@@@@[email protected]@@@#^#@[email protected]@@@@@@@@@#G/
 * /5&@@@@@@@@@@&[email protected]@@#&@J^@@@@@[email protected]^&@@@G:#@^[email protected]@@@[email protected]@@@@@@@@@&5/
 * /5&@@@@@@@@@@@&[email protected]&&[email protected]@YYGGGP5&@@@@@@@@@@&5/
 * /G#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#G/
 * /&[email protected]@@@@@@@#GBB&G#@BBG&#PG##@&&@@@@BBB#&G&@#@#&GBG&@@@@@@@@G&/
 * /@P&@@@@@@@[email protected]@G&B&PBG&@B#@@B#@#[email protected]@@G&G#[email protected]&[email protected]@@@@@@@&[email protected]/
 * /@&[email protected]@@@@@@&&@@&[email protected]@#&@&&@@&&@@@@@#@@@###@B&[email protected]@#@@@@@@@@P&@/
 * /@@#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G#@@/
 * /@@@&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G&@@@/
 * /@@@@&G&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&G&@@@@/
 * /@@@@@@#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B#@@@@@@/
 * /@@@@@@@@##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##@@@@@@@@/
 * /@@@@@@@@@@##&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&##@@@@@@@@@@/
 * /@@@@@@@@@@@@&##&@@@@@@@@@@@@@@@@@@@@@@@@@@@@&##&@@@@@@@@@@@@/
 * /@@@@@@@@@@@@@@@@&##&&@@@@@@@@@@@@@@@@@@&&##&@@@@@@@@@@@@@@@@/
 * /@@@@@@@@@@@@@@@@@@@@&&################&&@@@@@@@@@@@@@@@@@@@@/
 * 
 * 
 * Developed By: @wurdig_mich

 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./ERC721Enumerable.sol";


contract Club44 is ERC721Enumerable, ERC2981, Ownable {
    string public baseURI;
    address public simonoFromAccounting;
    uint256 public MAX_SUPPLY;
    uint256 public constant RESERVES = 144;
    uint256 public mintPrice = 0.5 ether;
    uint256 public secondarySaleDate;
    mapping(address => bool) public projectProxy;

    constructor(
        string memory _baseURI,
        address _openSeaCounduit,
        address _simonoFromAccounting,
        uint256 _secondarySaleDate

    ) ERC721("Club44", "Club44") {
        baseURI = _baseURI;
        flipProxyState(_openSeaCounduit);
        simonoFromAccounting = _simonoFromAccounting;
        secondarySaleDate = _secondarySaleDate;
        _setDefaultRoyalty(_simonoFromAccounting, 750);
        _mint(address(0),0);
    }

    // update/set royalty info for the collection
    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints) external onlyOwner {
        
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    // update set base URI for the collection
    function setBaseURI(string memory _baseURI) public onlyOwner {
        
        baseURI = _baseURI;
    }

    // get the token URI for a specific tokenId of collection
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        
        require(_exists(_tokenId), "Token does not exist.");
       
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json"));
    }

    // flip proxy address preApproval
    function flipProxyState(address proxyAddress) public onlyOwner {
        
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    // collect reserves
    function collectReserves() external onlyOwner {
        
        require(_owners.length == 1, "Reserves already taken.");
        
        for (uint256 i; i < RESERVES; i++) _safeMint(simonoFromAccounting, i+1);
    }

    // collect unSold
    function collectUnsold() external onlyOwner {
        
        require(_owners.length != 0 && MAX_SUPPLY!=0, "Mint hasnt even started yet");
        
        uint256 _totalSupply = _owners.length;
        
        for (uint256 i = _totalSupply; i < MAX_SUPPLY+1; i++) _safeMint(_msgSender(), i);
    }
    // set mint price
    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        
        mintPrice = _mintPrice;
    }

    // toggle public sale by modifying MAX_SUPPY
    function setMaxSupply(uint256 _MAX_SUPPLY) external onlyOwner {
        
        MAX_SUPPLY = _MAX_SUPPLY;
    }

    //publicMint with the _amount parameter to support nftpay
    function publicMint(uint256 _amount) public payable {
        
        require(mintPrice * _amount == msg.value, "Invalid funds provided.");

        uint256 _totalSupply = _owners.length;

        require(_totalSupply + _amount - 1 < MAX_SUPPLY+1, "Excedes max supply.");

        for(uint i; i < _amount; i++) { 
            _mint(_msgSender(), _totalSupply);
            _totalSupply+=1;
        }
    }
    
    //mint function to support crossmint
    function crossMint(address _to, uint256 _amount) public payable {
        
        require(
            _msgSender() == 0xdAb1a1854214684acE522439684a145E62505233,
            "This function is for Crossmint only."
        );
        require(mintPrice * _amount == msg.value, "Invalid funds provided.");

        uint256 _totalSupply = _owners.length;

        require(_totalSupply + _amount - 1 < MAX_SUPPLY+1, "Excedes max supply.");

        for(uint i; i < _amount; i++) { 
            _mint(_to, _totalSupply);
            _totalSupply+=1;
        }
    }

    //burn...
    function burn(uint256 tokenId) public {
        
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved to burn.");
        
        _burn(tokenId);
    }

    //callable by anyone as the address is hardcoded
    function withdraw() public {
        
        (bool success, ) = simonoFromAccounting.call{value: address(this).balance}("");
        require(success, "Failed to send to Simono.");
    }

    //supporting preapproval for opensea proxies and other proxies that we might add
    function isApprovedForAll(address _owner, address operator)
        public
        view
        override
        returns (bool)
    {
        if (projectProxy[operator])
            return true;
        return super.isApprovedForAll(_owner, operator);
    }

    //modified mint functionality to maintain an array rather than mapping
    function _mint(address to, uint256 tokenId) internal virtual override {
        _owners.push(to);
        emit Transfer(address(0), to, tokenId);
    }
    
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override{
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not owned"
        );
        require(block.timestamp > secondarySaleDate || from == owner(), "ERC721: secondary sales not permitted yet");

        require(to != address(0), "ERC721: transfer to the zero address");
        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC2981, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenByIndex(uint256 index) external override pure returns (uint256) {
        return index;
    }
}