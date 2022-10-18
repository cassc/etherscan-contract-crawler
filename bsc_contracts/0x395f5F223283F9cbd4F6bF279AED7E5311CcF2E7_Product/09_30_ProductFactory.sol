// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IFactoryERC721.sol";
import "./Product.sol";
import "./ProductLootBox.sol";
import "./AccessControl.sol";

contract ProductFactory is FactoryERC721, Ownable ,AccessControl{
    using Strings for string;
    using SafeMath for uint;
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    bytes32 public constant WHITELISTED_ROLE = keccak256("WHITELISTED");
    address public proxyRegistryAddress;
    address public nftAddress;
    address public lootBoxNftAddress;
    string public baseURI = "";
    mapping(uint256 => address[]) internal _addressBook;
    mapping(address => bool) internal _addressEntry;
    /*
     * Enforce the existence of only 100 OpenSea creatures.
     */
    uint256 PRODUCT_SUPPLY = 10000000000000000;

    /*
     * Three different options for minting Creatures (basic, premium, and gold).
     */
    uint256 NUM_OPTIONS = 3;
    uint256 SINGLE_PRODUCT_OPTION = 0;
    uint256 MULTIPLE_PRODUCT_OPTION = 1;
    uint256 LOOTBOX_OPTION = 2;
    uint256 NUM_PRODUCT_IN_MULTIPLE_PRODUCT_OPTION = 1;
    uint256 public maxMintQuantity = 5;
    mapping(address => uint256) private totalLootboxMinted;
    mapping(address => uint256) private totalProductMinted;
    mapping(address => uint256) private eligibleLootboxMintQuantity;
    mapping(address => uint256) private eligibleProductMintQuantity;
    ProductLootBox lootbox ;
    constructor(address _nftAddress) {
        nftAddress = _nftAddress;
        lootbox = new ProductLootBox(address(this));
        lootBoxNftAddress = address(lootbox);
        lootbox.transferOwnership(msg.sender);
        //fireTransferEvents(address(0), owner());
        _setupRole(DEFAULT_ADMIN_ROLE,owner());
    }

    function name() override external pure returns (string memory) {
        return "GSMC Factory";
    }

    function symbol() override external pure returns (string memory) {
        return "GSMCFTY";
    }

    function supportsFactoryInterface() override public pure returns (bool) {
        return true;
    }

    function numOptions() override public view returns (uint256) {
        return NUM_OPTIONS;
    }

    function transferOwnership(address newOwner) override public onlyOwner {
        address _prevOwner = owner();
        super.transferOwnership(newOwner);
        fireTransferEvents(_prevOwner, newOwner);
    }

    function fireTransferEvents(address _from, address _to) private {
        for (uint256 i = 0; i < NUM_OPTIONS; i++) {
            emit Transfer(_from, _to, i);
        }
    }

    function whitelistAddresses(address[] memory _addresses,uint[] memory eligibleQuanties)  public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint lootboxMinted;
        for (uint i=0; i<_addresses.length; i++) {
            if ( !_addressEntry[_addresses[i]]) {
                _addressBook[0].push(_addresses[i]);
                _addressEntry[_addresses[i]] = true;
            }
            _grantRole(WHITELISTED_ROLE,_addresses[i]);
            lootboxMinted = totalLootboxMinted[_addresses[i]];
            if (eligibleLootboxMintQuantity[_addresses[i]].add(eligibleQuanties[i]) > maxMintQuantity ||
                lootboxMinted.add(eligibleQuanties[i]) > maxMintQuantity){
                continue;
            }
            eligibleLootboxMintQuantity[_addresses[i]] = eligibleLootboxMintQuantity[_addresses[i]].add(eligibleQuanties[i]);
            eligibleProductMintQuantity[_addresses[i]] = eligibleProductMintQuantity[_addresses[i]].add(eligibleQuanties[i]);

        }
    }

    function whitelistAddress(address  _address,uint _eligibleQuantity)  public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(WHITELISTED_ROLE,_address);
        if ( !_addressEntry[_address]) {
            _addressBook[0].push(_address);
            _addressEntry[_address] = true;
        }
        require(eligibleLootboxMintQuantity[_address].add(_eligibleQuantity) <= maxMintQuantity,"Exceeded max mint quantity");
        require(totalLootboxMinted[_address].add(_eligibleQuantity) <= maxMintQuantity,"Reached max mint quantity");
        eligibleLootboxMintQuantity[_address] =  eligibleLootboxMintQuantity[_address].add(_eligibleQuantity);
        eligibleProductMintQuantity[_address] = eligibleProductMintQuantity[_address].add(_eligibleQuantity);
    }

    function addAdmin(address account) public  onlyOwner{
        _grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    function isAdmin(address account) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    function removeAdmin(address account) public  onlyOwner {
        _revokeRole(DEFAULT_ADMIN_ROLE, account);
    }

    function batchMint(uint256 _optionId, address[] memory _toAddresses) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint i=0; i<_toAddresses.length; i++) {
            mint(_optionId,_toAddresses[i]);
        }
    }

    function batchMintLootbox(address[] memory _toAddresses,uint256[] memory _quantities) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint i=0; i<_toAddresses.length; i++) {
            mintLootbox(_toAddresses[i],_quantities[i]);
        }
    }

    function changeMaxMintQuantity(uint256 _quantiy) public onlyRole(DEFAULT_ADMIN_ROLE) {
        maxMintQuantity = _quantiy;
    }

    function getMaxMintQuantity()  public view returns (uint256) {
        return maxMintQuantity;
    }

    function lootboxMintedOf(address _address)  public view returns (uint256) {
        return totalLootboxMinted[_address];
    }

    function lootboxQuantityOf(address _address)  public view returns (uint256) {
        return eligibleLootboxMintQuantity[_address];
    }

    function productQuantityOf(address _address)  public view returns (uint256) {
        return eligibleProductMintQuantity[_address];
    }

    function mintLootbox(address _toAddress,uint quantity) public {
        _checkAllowMintLootBox(_toAddress,quantity);
        for (uint i=0; i<quantity; i++) {
            mint(LOOTBOX_OPTION,_toAddress);
        }
    }

    function mintAll() public {
        for (uint i =0 ;i<_addressBook[0].length;i++){
            if (eligibleLootboxMintQuantity[_addressBook[0][i]]> 0){
                mintLootbox(_addressBook[0][i],eligibleLootboxMintQuantity[_addressBook[0][i]]);
            }
        }
    }

    function mint(uint256 _optionId, address _toAddress) override public {
        // Must be sent from the owner proxy or owner.
        assert(
                owner() == _msgSender() ||
                _msgSender() == lootBoxNftAddress ||
                hasRole(DEFAULT_ADMIN_ROLE,_msgSender()) ||
                    _msgSender() == _toAddress
        );

        require(canMint(_optionId),"Minting option not allowed");
        Product product = Product(nftAddress);
        if (_optionId == SINGLE_PRODUCT_OPTION) {
            if (!_allowMintProduct(_toAddress,1)){
                return;
            }
            eligibleProductMintQuantity[_toAddress] = eligibleProductMintQuantity[_toAddress].sub(1);
            product.mintTo(_toAddress);
        } else if (_optionId == MULTIPLE_PRODUCT_OPTION) {
            for (
                uint256 i = 0;
                i < NUM_PRODUCT_IN_MULTIPLE_PRODUCT_OPTION;
                i++
            ) {
                if (!_allowMintProduct(_toAddress,1)){
                    return;
                }
                eligibleProductMintQuantity[_toAddress] = eligibleProductMintQuantity[_toAddress].sub(1);
                product.mintTo(_toAddress);
            }
        } else if (_optionId == LOOTBOX_OPTION) {
            if (!_allowMintLootBox(_toAddress,1)){
                return;
            }
            ProductLootBox productLootBox = ProductLootBox(
                lootBoxNftAddress
            );
            totalLootboxMinted[_toAddress] = totalLootboxMinted[_toAddress].add(1);
            eligibleLootboxMintQuantity[_toAddress] = eligibleLootboxMintQuantity[_toAddress].sub(1);
            productLootBox.mintTo(_toAddress);
        }
    }

    function canMint(uint256 _optionId) override public view returns (bool) {
        if (_optionId >= NUM_OPTIONS) {
            return false;
        }

        Product product = Product(nftAddress);
        uint256 productSupply = product.totalSupply();

        uint256 numItemsAllocated = 0;
        if (_optionId == SINGLE_PRODUCT_OPTION) {
            numItemsAllocated = 1;
        } else if (_optionId == MULTIPLE_PRODUCT_OPTION) {
            numItemsAllocated = NUM_PRODUCT_IN_MULTIPLE_PRODUCT_OPTION;
        } else if (_optionId == LOOTBOX_OPTION) {
            ProductLootBox productLootBox = ProductLootBox(
                lootBoxNftAddress
            );
            numItemsAllocated = productLootBox.productsPerLootbox();
        }
        return productSupply < (PRODUCT_SUPPLY - numItemsAllocated);
    }

    function tokenURI(uint256 _optionId) override external view returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(_optionId)));
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use transferFrom so the frontend doesn't have to worry about different method names.
     */
    function transferFrom(
        address,
        address _to,
        uint256 _tokenId
    ) public {
        mint(_tokenId, _to);
    }


    /**
     * Hack to get things to work automatically on OpenSea.
     * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
     */
    function ownerOf(uint256) public view returns (address _owner) {
        return owner();
    }

    function _checkAllowMintLootBox(address _toAddress,uint quantity) view internal {
        require(eligibleLootboxMintQuantity[_toAddress]  > 0,"Address is not eligible to mint lootbox");
        require(quantity <= eligibleLootboxMintQuantity[_toAddress],"Mint quantity exceeded eligible quantity");
        require(totalLootboxMinted[_toAddress].add(quantity) <= maxMintQuantity,"Exceeded max mint quantity");
    }

    function _allowMintLootBox(address _toAddress,uint quantity) view internal  returns (bool){

        if (!hasRole(WHITELISTED_ROLE,_toAddress)){
            return false;
        }

        if(!(eligibleLootboxMintQuantity[_toAddress]  > 0)){
            return false;
        }

        if (quantity > eligibleLootboxMintQuantity[_toAddress]){
            return false;
        }

        if (totalLootboxMinted[_toAddress].add(quantity) > maxMintQuantity){
            return false;
        }
        return true;
    }

    function _allowMintProduct(address _toAddress,uint quantity) view internal returns (bool){

        if(!(eligibleProductMintQuantity[_toAddress]  > 0)){
            return false;
        }

        if (quantity > eligibleProductMintQuantity[_toAddress]){
            return false;
        }

        if (productBalanceOf(_toAddress).add(quantity) > maxMintQuantity){
            return false;
        }
        return true;
    }

    function productBalanceOf(address _address) view internal returns (uint){
        Product product = Product(nftAddress);
        return product.balanceOf(_address);
    }

    function lootboxBalanceOf(address _address) view internal returns (uint){
        ProductLootBox productLootBox = ProductLootBox(lootBoxNftAddress);
        return productLootBox.balanceOf(_address);
    }

    function lootboxAddress() view public returns (address)  {
        return lootBoxNftAddress;
    }

    function allAddresses() public view returns (address[] memory){
        //require(productFactory.isAdmin(_msgSender()),"Unauthroized access");
        return _addressBook[0];
    }

    function removeWhitelistAddresses(address[] memory _addresses)  public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint i=0; i<_addresses.length; i++) {
            _revokeRole(WHITELISTED_ROLE,_addresses[i]);
            eligibleLootboxMintQuantity[_addresses[i]] = 0;
            eligibleProductMintQuantity[_addresses[i]] = 0;
        }
    }

    function removeAll() public onlyRole(DEFAULT_ADMIN_ROLE) {
        removeWhitelistAddresses(_addressBook[0]);
    }

    function updateProduct(address _nftAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        nftAddress = _nftAddress;
    }

}