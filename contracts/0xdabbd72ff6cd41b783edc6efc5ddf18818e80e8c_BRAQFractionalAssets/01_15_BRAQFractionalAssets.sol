// SPDX-License-Identifier: MIT

pragma solidity 0.8.15; 

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 
import "@openzeppelin/contracts/access/Ownable.sol"; 
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


contract BRAQFractionalAssets is ERC1155, Ownable {
    using Strings for uint256; 

    struct InitialParameters {
        string name; 
        string symbol; 
        string uri; 
    }


uint16 public maxAllowed; 
uint256 public price;

string private baseURI; 
string public name; 
string public symbol;

bool public investingAssetsLocked = false;
bool public assetMint = false; 

address public BRAQHOLDERS;

mapping(uint256 => bool) public investedAsset;
mapping(address => uint256) public mintedBalance;

event SetBaseURI(string indexed _uri); 

constructor(
    address _owner, 
    InitialParameters memory initialParameters)
    ERC1155(initialParameters.uri) {
        name  = initialParameters.name;
        symbol = initialParameters.symbol;
        baseURI = initialParameters.uri; 
        emit SetBaseURI(baseURI); 
        transferOwnership(_owner); 
        setBRAQAddress(0xCE13a074896B3B3df12AD8a221e7FA9f11F59f4c);
    }
    //
    // @dev: locks the assets forever, you can not revert this.
    //

    function lockAssets() public onlyOwner {
        investingAssetsLocked = true; 
    }
    // 
    // @dev: creates new asset for airdropping / minting
    //

    function newAsset(uint256 _id) public onlyOwner {
        require(!investingAssetsLocked, "The assets are locked and no more can be created"); 
        require(investedAsset[_id] == false, "This ID already has an asset created under it, try another number"); 
        investedAsset[_id] = true; 
    }
    //
    // @dev: Mint function for only BRAQFRND holders.
    //
    function mint(uint256 _id, uint256 amount) public payable {
        require(!investingAssetsLocked, "The assets are locked and no more can be minted"); 
        require(assetMint, "Mint is not open for holders to mint more");
        IERC721 braqfrnds = IERC721(BRAQHOLDERS);
        uint256 amountBRAQ = braqfrnds.balanceOf(msg.sender);
        require(amountBRAQ >= 1, "You are not a holder"); 
        uint256 mintedCount = mintedBalance[msg.sender]; 
        require(mintedCount + amount <= maxAllowed, "Max Fractions minted"); 
        require(msg.value == price * amount, "Not enough ETH to complete tx"); 

        mintedBalance[msg.sender]++; 
        
        _mint(msg.sender, _id, amount, ""); 
    }
    //
    // @dev: Owner function to mint several assets at once for airdrop.
    //
    function mintBatch(uint256[] memory _ids, uint256[] memory _quantity) external onlyOwner {
        require(!investingAssetsLocked, "The assets are locked and no more can be minted"); 
        
        _mintBatch(owner(), _ids, _quantity, ""); 
    }
    //
    // @dev: Function to change the max allowed of mints for this round.
    //
    function changeMaxAllowed(uint16 _maxAllowed) public onlyOwner {
        maxAllowed = _maxAllowed; 
    }
    //
    // @dev: Function to allow holders to mint additional fractions.
    //
    function changeMintState() external onlyOwner {
        assetMint = !assetMint; 
    }
    //
    // @dev: Function to change the price of current asset to mint.
    //
    function setPrice(uint256 _price) public onlyOwner {
        price = _price; 
    }
    //
    // @dev: Function to set contract of BRAQ
    //
    function setBRAQAddress(address _newAddress) public onlyOwner {
        BRAQHOLDERS = _newAddress;
    }
    //
    // @dev: function to change the URI in the occurence of new assets being added. 
    //
    function setURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
        emit SetBaseURI(baseURI); 
    }
    //
    // @dev: concatenation of the URI to display on Opensea depending on token. 
    //
    function uri(uint256 _id) public view override returns (string memory) {
        require(investedAsset[_id], "URI requested for invalid asset."); 
        return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, _id.toString(), ".json"))
        : baseURI; 
    }
    function withdrawETH() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os); 
    }
}