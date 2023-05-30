pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface PixelMap {

    event TileUpdated(uint location);
   
    function getTile(uint location) external view returns (address, string memory, string memory, uint);
    function buyTile(uint location) external payable;
   
    // setTile does not set Owner!
    function setTile(uint location, string memory image, string memory url, uint price) external payable;
}

contract PixelMapWrapper is Ownable, ERC721 {

    receive() external payable
    {
        // Only accept from pixelmap contract
        require(_msgSender() == _pixelmapAddress, "PixelMapWrapper: Sender isn't pixelmap contract");
    }
    
    event Wrapped(address indexed owner, uint indexed _locationID);
    event Unwrapped(address indexed owner, uint indexed _locationID);

    address public _pixelmapAddress;
    PixelMap public _pixelmap;
   
    // BaseTokenURI + BaseContractURI
    string public _baseTokenURI;
    string public _baseContractURI;
    string private _baseTokenExtension;

    constructor() payable ERC721("Wrapped PixelMap", "WPXM") {
		_pixelmapAddress = 0x015A06a433353f8db634dF4eDdF0C109882A15AB;
		_pixelmap = PixelMap(_pixelmapAddress);
		_baseTokenExtension = '';
    }
    
     struct saleStorage {
        address seller;
        uint amount;
     }

    mapping (uint => saleStorage) public pendingLocationSales;
		
    /**
     * Wrapping is only possible when there is already a listing, you are buying your own listing and therefore getting your eth back in your wallet.
     * Only Owner can do a mint of a wrapper, or 0x0 (unowned tiles)
     */
    function wrap(uint _locationID) external payable {
        require(!_exists(_locationID), "PixelMapWrapper: You cannot mint the same locationID");
        require(getwithdrawableETHforLocation(_locationID) == 0, "PixelMapWrapper: There is still ETH to be withdrawn");
       
        // get Tile from contract
        (address _owner,,,uint _price) = _pixelmap.getTile(_locationID);
        // check owner
        require(_owner == _msgSender() || _owner == address(0), "PixelMapWrapper: You are not the owner or it");
        require(_price == msg.value, "PixelMapWrapper: Price not identical");

        // Buy Offering with this contract
        _pixelmap.buyTile{value: msg.value}(_locationID);
		
        // Check Tile if correct transfered
        (address _newowner,,, uint _newprice) = _pixelmap.getTile(_locationID);
        require(_newprice == 0 && _newowner == address(this), "PixelMapWrapper: Price or Owner not Updated");
       
	    // Mint ERC721 NFT
        _mint(msg.sender, _locationID);
        emit Wrapped(msg.sender, _locationID);
    }
    
    /**
     * Unwrapping would only be possible to set it for Sale, making an array for balances to withdraw funds from wrapper contract
     **/
    function unwrap(uint _locationID, uint _salePrice) external {     
        require(_exists(_locationID), "PixelMapWrapper: operator query for nonexistent token");
       
        // Unwrapping = selling from this contract to owner (msg.sender)
        // Check if Owner
        address owner = ERC721.ownerOf(_locationID);
        require(owner == _msgSender(), "PixelMapWrapper: You are not the owner");
               
        // Set Tile to Sale via contract
        (address _owner, string memory _image, string memory _url,) = _pixelmap.getTile(_locationID);
        
        // Check if Tile is owned by this contract
        require(_owner == address(this), "PixelMapWrapper: Tile Owner is not this contract");
        
        // Create Offering for _salePrice, if price is set
        // set URL to msgSender, used in fallback function to attribute incoming eth
        _pixelmap.setTile(_locationID, _image, _url, _salePrice);
        
        // burn ERC721
        _burn(_locationID);
        require(!_exists(_locationID), "PixelMapWrapper: ERC721 Location has not been burned");
        
        // Add after burn into sale struct, it will get overwritten if you don't withdraw your eth with withdrawETH after a successfull sale
        pendingLocationSales[_locationID] = saleStorage({
            seller: _msgSender(),
            amount: uint(_salePrice)
        });
       
        emit Unwrapped(msg.sender, _locationID);
    }
   
    function setTileData(uint _locationID, string memory _image, string memory _url) external {
        require(_exists(_locationID), "PixelMapWrapper: Location has not been wrapped");
        // Check if Owner
        address owner = ERC721.ownerOf(_locationID);
        require(owner == _msgSender(), "PixelMapWrapper: You are not the owner");
        // set 0 as price
        require(setTileDataUnderlying(_locationID,_image,_url),"PixelMapWrapper: Couldn't set Tile Data");
    }
    
    function setTileDataUnderlying(uint _locationID, string memory _image, string memory _url) internal returns (bool){
        (address _owner,,,) = _pixelmap.getTile(_locationID);
        // Check if Tile is owned by this contract
        require(_owner == address(this), "PixelMapWrapper: Tile Owner is not this contract");
        // Update Tile Data, don't set it for sale, hardcode it
        _pixelmap.setTile(_locationID, _image, _url, 0);
        return true;
    }
    
    function withdrawETH(uint _locationID) external {
        saleStorage storage pendingSale = pendingLocationSales[_locationID];
        uint amount = pendingLocationSales[_locationID].amount;
        // Check for msg Sender == seller
        require(pendingSale.seller == _msgSender(),"PixelMapWrapper: you are not the receiver of this eth");
        
        // Check if Tile is sold (owner of Tile is *not* this contract)
        (address _owner,,,) = _pixelmap.getTile(_locationID);
        require(_owner != address(this), "PixelMapWrapper: Tile Owner is this contract, not successfull re-sell");
        
        // Set Withdrawable Funds to 0 against reentrancy
        pendingLocationSales[_locationID].seller = address(0);
        pendingLocationSales[_locationID].amount = 0;
        
        // Send eth
        payable(_msgSender()).transfer(amount);
    }
    
    function getwithdrawableETHforLocation(uint _locationID) public view returns(uint) {
        saleStorage storage pendingSale = pendingLocationSales[_locationID];
        
        // Check if Tile is sold (owner of Tile is *not* this contract)
        (address _owner,,,) = _pixelmap.getTile(_locationID);
        if (_owner == address(this)) {
            return 0;
        } else {
            return pendingSale.amount;
        }
    }
  
    /**
     * @dev sets the extension for tokens (.json) as example
     */
    function setTokenExtension(string memory extension) public onlyOwner {
        _baseTokenExtension = extension;
    }    
  
    /**
     * @dev Returns a URI for a given token ID's metadata
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId), _baseTokenExtension));
    }

    function setBaseTokenURI(string memory __baseTokenURI) public onlyOwner {
        _baseTokenURI = __baseTokenURI;
    }
        
    /**
     * @dev Returns a URI for a given token ID's metadata
     */
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(_baseContractURI));
    }

    function setBasecontractURI(string memory __baseContractURI) public onlyOwner {
        _baseContractURI = __baseContractURI;
    }
}