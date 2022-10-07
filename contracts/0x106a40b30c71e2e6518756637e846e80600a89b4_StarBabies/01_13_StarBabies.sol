// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./erc721a/contracts/ERC721A.sol";
import "./erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StarBabies is ERC721AQueryable, AccessControl {

	bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
	bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
	bytes32 public constant BULK_MINTER_ROLE = keccak256("BULK_MINTER_ROLE");
    bytes32 public constant WHITELIST_MINTER_ROLE = keccak256("WHITELIST_MINTER_ROLE");

    uint256 public maxSupply = 3333;
    uint256 public maxCap = 3000;
    uint256 public unitPrice = .18 ether;
    uint256 public maxPerUser = 50;

    string public _baseTokenURI;


    constructor() ERC721A(
    	"STARBabies",
    	"STAR"){
        _baseTokenURI = "https://starbabies-api.communitynftproject.io/";

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    	_setupRole(MINTER_ROLE, msg.sender);
    	_setupRole(ADMIN_ROLE, msg.sender);
    }

    function mintByRole(address _to, uint256 quantity) external onlyRole(MINTER_ROLE) {
        require(totalSupply() + quantity < maxSupply, '> maxSupply');
        _mint(_to, quantity);
    }

    // will be used by Muon
    function mint(address to, uint256 id) external onlyRole(MINTER_ROLE){
    	// tokens will be minted on one chain
        // on other chains ERC721 will be used.
        // when a token bridge to other chains,
        // the burn function transfers it to the token contract
        // and when it bridge back to the first chain, 
        // the token will be transferred from the smart contract.
    	require(ownerOf(id) == address(this), "Not found");
        _tokenApprovals[id].value = to;
        transferFrom(address(this), to, id);
    }

    function burn(uint256 tokenId) external{
    	transferFrom(_msgSenderERC721A(), address(this), tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, AccessControl) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function whitelistMint(address _to, uint8 _count) public payable onlyRole(WHITELIST_MINTER_ROLE) {
        require(_count <= maxPerUser, '> maxPerUser');
        require(_count + totalSupply() <= maxCap, "> maxCap");
        require(msg.value >= price(_count), "!value");
        // for (uint8 i = 0; i < _count; i++) {
        //     _mint(_to, totalSupply());
        // }
        _mint(_to, _count);
    }

    function bulkMint(address _to, uint _count) public onlyRole(BULK_MINTER_ROLE) payable{
        require(_count + totalSupply() <= maxCap, "> maxCap");
        require(msg.value >= price(_count), "!value");
        // for (uint i = 0; i < _count; i++) {
        //     _mint(_to, totalSupply());
        // }
        _mint(_to, _count);   
    }

    function price(uint _count) public view returns (uint256) {
        return _count * unitPrice;
    }

    function updateMaxPerUser(uint256 _value) public onlyRole(ADMIN_ROLE) {
        maxPerUser = _value;
    }

    function setBaseUrl(string memory _newUri) public onlyRole(ADMIN_ROLE) {
        _baseTokenURI = _newUri;
    }

    function setMaxCap(uint256 _cap) public onlyRole(ADMIN_ROLE) {
        maxCap = _cap;
    }

    function setUnitPrice(uint256 _price) public onlyRole(ADMIN_ROLE) {
        unitPrice = _price;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyRole(ADMIN_ROLE) {
        maxSupply = _maxSupply;
    }

    // lets the owner withdraw ETH and ERC20 tokens
    function ownerWT(uint256 amount, address _to,
            address _tokenAddr) public onlyRole(ADMIN_ROLE){
        require(_to != address(0));
        if(_tokenAddr == address(0)){
            payable(_to).transfer(amount);
        }else{
            IERC20(_tokenAddr).transfer(_to, amount);
        }
    }
}