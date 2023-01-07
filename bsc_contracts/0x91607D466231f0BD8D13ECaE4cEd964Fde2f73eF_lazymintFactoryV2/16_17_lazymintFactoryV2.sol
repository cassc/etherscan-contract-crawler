// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../AccessControl.sol";
import "./NFTWMisteryBox.sol";

contract lazymintFactoryV2 is AccessControl {
    ///@notice Mapping that stores the contracts created
    ///@dev You can search with the name of the collection.
    mapping(string => address) public collections;

    address public market;
    address public manager;
    address public admin = 0x9B6029a309bC0A1B6ab9ACf962AfD90A8270900e;

    event contractcreated(address collectioncontract, address creator);

    constructor(address _market, address _manager) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(DEFAULT_ADMIN_ROLE, 0x30268390218B20226FC101cD5651A51b12C07470);
        market = _market;
        manager = _manager;
    }

    ///@dev Applicable configuration parameters for the creation of a new lazymint ERC721 contract:
    ///@dev --> The maximum supply that the nft collection will have : _maxsupply
    ///@dev --> The name of the collection : name_
    ///@dev --> The symbol of the collection : symbol_
    ///@dev --> The address of the marketplace contract: market
    function create(
        uint256 _maxsupply,
        string memory name_,
        string memory symbol_,
        address _token,
        uint256 _amount,
        bool _mintBox,
        uint256 _date,
        address owner
    ) public returns (address){
        address _name = collections[name_];
        if (_name != address(0)) {
            revert ("collection exists");
        } 
        LazyNFT lazynft = new LazyNFT(manager, market, _maxsupply,name_,symbol_,_token,_amount,_mintBox,_date,owner);
        collections[name_] = address(lazynft);
        emit contractcreated(address(lazynft), msg.sender);
        return address(lazynft);
    }

    ///@dev Allow to update the marketplace address.
    ///@dev Only the wallet with administrator role can make the change.
    function updateMarket(address _market) public {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert ("not the admin");
        }
        market = _market;
    }

    function updateManager(address _manager) public {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert ("not the admin");
        }
        manager = _manager;
    }
}