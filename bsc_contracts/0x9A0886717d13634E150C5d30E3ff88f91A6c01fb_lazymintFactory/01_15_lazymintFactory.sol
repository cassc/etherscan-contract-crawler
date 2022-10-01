// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./AccessControl.sol";
import "./Lazymint.sol";

contract lazymintFactory is AccessControl {
    error nottheadmin();
    error collectionexists();

    ///@notice Mapping that stores the contracts created
    ///@dev You can search with the name of the collection.
    mapping(string => address) public collections;

    address public market;
    address public admin = 0x9B6029a309bC0A1B6ab9ACf962AfD90A8270900e;

    event contractcreated(address collectioncontract, address creator);

    constructor(address _market) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(DEFAULT_ADMIN_ROLE, 0x30268390218B20226FC101cD5651A51b12C07470);
        market = _market;
    }

    ///@dev Applicable configuration parameters for the creation of a new lazymint ERC721 contract:
    ///@dev --> The maximum supply that the nft collection will have : _maxsupply
    ///@dev --> The name of the collection : name_
    ///@dev --> The symbol of the collection : symbol_
    ///@dev --> The address of the marketplace contract: market
    function create(
        uint256 _maxsupply,
        string memory name_,
        string memory symbol_
    ) public {
        address _name = collections[name_];
        if (_name != address(0)) {
            revert collectionexists();
        }
        LazyNFT lazynft = new LazyNFT(market, _maxsupply, name_, symbol_);
        collections[name_] = address(lazynft);
        emit contractcreated(address(lazynft), msg.sender);
    }

    ///@dev Allow to update the marketplace address.
    ///@dev Only the wallet with administrator role can make the change.
    function updateMarket(address _market) public {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert nottheadmin();
        }
        market = _market;
    }
}