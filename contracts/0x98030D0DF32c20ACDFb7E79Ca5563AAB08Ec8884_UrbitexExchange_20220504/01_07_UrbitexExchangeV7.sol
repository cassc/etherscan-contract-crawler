// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./interface/IAzimuth.sol";
import "./interface/IEcliptic.sol";
import "./interface/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract UrbitexExchange_20220504 is Context, Ownable {

    // updated 2022-05-04
    // urbitex.io 

    //  azimuth: points state data store
    //
    IAzimuth public azimuth;
    
    // fee: exchange transaction fee 
    // 
    uint32 public fee;

    // ListedAsset: struct which stores the seller's address, price, and token (currency) address for a point listed in the marketplace
    // 
    struct ListedAsset {
        address addr;
        uint96 price;
        address token;
    }

    // assets: registry which stores the ListedAsset entries
    //
    mapping(uint32 => ListedAsset) assets;

    // EVENTS

    event MarketPurchase(
        address indexed _from,
        address indexed _to,
        uint32 _point,
        uint96 _price,
        address token
    );

    event ListingRemoved(
        uint32 _point
    );

    event ListingAdded(
        uint32 _point,
        uint96 _price,
        address _token
    );

    // IMPLEMENTATION

    //  constructor(): configure the points data store and set exchange fee
    //
    constructor(IAzimuth _azimuth, uint32 _fee) 
        payable 
    {     
        azimuth = _azimuth;
        fee = _fee;
    }

    // setRegistryEntry(): utility function to add or remove entries in the registry
    function setRegistryEntry(uint32 _point, address _address, uint96 _price, address _token) internal
    {
        ListedAsset storage asset = assets[_point];

        asset.addr = _address;
        asset.price = _price;
        asset.token = _token;
    }

    //  purchase(): purchase and transfer point from the seller to the buyer
    //
    function purchase(uint32 _point, uint96 _amount, address _token)
        external
        payable
    {
        IEcliptic ecliptic = IEcliptic(azimuth.owner());
        
        // get the point's owner 
        address payable seller = payable(azimuth.getOwner(_point));

        // get the point's information from the registry
        ListedAsset storage asset = assets[_point];

        address addr = asset.addr;
        uint96 price = asset.price;
        address token = asset.token;
        
        // check that the seller's address in the registry matches the point's current owner
        require(addr == seller);

        // the price and token type must match with what has been set by the seller.
        // can be ETH or other erc-20 tokens.
        require((uint96(msg.value) == price && _amount == 0 && token == address(0)) || (_amount == price && msg.value == 0 && _token == token && token != address(0)));

        // off-chain:
        // check that the seller has approved the exchange as a transfer proxy.
        // if ERC-20 token then must also set allowance.

        // deduct exchange fee and transfer remaining amount to the seller  
        // 
        if (token == address(0)) {
            // currency is ether
            Address.sendValue(seller, msg.value/1000*(1000-fee));
        } else {
            // currency is ERC-20
            IERC20Partial ERC20 = IERC20Partial(_token);
            ERC20.transferFrom(_msgSender(), address(this), _amount);

            // send amount to seller
            ERC20.transfer(seller, _amount/1000*(1000-fee));
        }

        // when all conditions are met, transfer the point from the seller to the buyer
        ecliptic.transferFrom(seller, _msgSender(), _point); 

        // clear the values for that point in the registry
        delete assets[_point];

        emit MarketPurchase(seller, _msgSender(), _point, price, token);
    }

    //  safePurchase(): Exactly like the purchase() function except with validation checks
    //
    function safePurchase(uint32 _point, bool _unbooted, uint32 _spawnCount, bool _isProxyL2, uint96 _amount, address _token)
        external
        payable
    {

        // make sure the booted status matches the buyer's expectations
        require(_unbooted == (azimuth.getKeyRevisionNumber(_point) == 0));

        // make sure the buyer is aware of any L2 proxy set
        require(azimuth.isSpawnProxy(_point, 0x1111111111111111111111111111111111111111) == _isProxyL2);

        // make sure the number of spawned child points matches the buyer's expectations
        require(_spawnCount == azimuth.getSpawnCount(_point));

        // get the current ecliptic contract
        IEcliptic ecliptic = IEcliptic(azimuth.owner());        

        // get the point's owner 
        address payable seller = payable(azimuth.getOwner(_point));

        // get the point's information from the registry
        ListedAsset storage asset = assets[_point];

        address addr = asset.addr;
        uint96 price = asset.price;
        address token = asset.token;

        // check that the address in the registry matches the point's current owner
        require(addr == seller, "invalid listing");

        // the price and token type must match with what has been set by the seller.
        // can be ETH or other ERC-20 tokens.
    
        require((uint96(msg.value) == price && _amount == 0 && token == address(0)) || (_amount == price && msg.value == 0 && _token == token && token != address(0)));

        // off-chain:
        // check that the seller has approved the exchange as a transfer proxy.
        // if ERC-20 token then must also set allowance.

        // deduct exchange fee and transfer remaining amount to the seller  
        // 
        if (token == address(0)) {
            // currency is ether
            Address.sendValue(seller, msg.value/1000*(1000-fee));
        } else {
            // currency is ERC-20
            IERC20Partial ERC20 = IERC20Partial(_token);
            ERC20.transferFrom(_msgSender(), address(this), _amount);

            // send amount to seller
            ERC20.transfer(seller, _amount/1000*(1000-fee));
        }

        // when all conditions are met, transfer the point from the seller to the buyer
        ecliptic.transferFrom(seller, _msgSender(), _point); 

        // clear the values for that point in the registry
        delete assets[_point];

        emit MarketPurchase(seller, _msgSender(), _point, price, token);
    }

    // addListing(): add a point to the registry
    //
    function addListing(uint32 _point, uint96 _price, address _token) external
    {
        // intentionally using isOwner() instead of canTransfer(), which excludes third-party proxy addresses.
        // the exchange owner also has no ability to list anyone else's assets, it can strictly only be the point owner.
        // 
        require(azimuth.isOwner(_point, _msgSender()), "not owner");

        // add the price of the point, the seller address, and the token (currency) to the registry
        // can be ERC-20 token or ether
        //         
        setRegistryEntry(_point, _msgSender(), _price, _token);        
        
        emit ListingAdded(_point, _price, _token);

    }

    // removeListing(): clear the information for this point in the registry. This function has also been made available
    // to the exchange owner to remove stale listings.
    //
    function removeListing(uint32 _point) external 
    {   
        require(azimuth.isOwner(_point, _msgSender()) || _msgSender() == owner(), "not owner");
        
        delete assets[_point];

        emit ListingRemoved(_point);
    }

    // getAssetInfo(): check the listed price and seller address of a point 
    // 
    function getAssetInfo(uint32 _point) external view returns (address, uint96, address) {
        return (assets[_point].addr, assets[_point].price, assets[_point].token);
    }

    // EXCHANGE OWNER OPERATIONS
             
    function withdraw(address payable _target) external onlyOwner  {
        require(address(0) != _target);
        Address.sendValue(_target, address(this).balance);
    }

    function withdrawERC20(address payable _target, address _token, uint256 _amount) external onlyOwner  {
        require(address(0) != _target);        
        IERC20Partial ERC20 = IERC20Partial(_token);
        ERC20.transfer(_target, _amount);        
    }

    function close(address payable _target) external onlyOwner  {
        require(address(0) != _target);
        selfdestruct(_target);
    }
}