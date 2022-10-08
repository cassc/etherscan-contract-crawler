// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./pricefeed1.sol";
import "./ERC777.sol";

abstract contract Referral is Ownable, PriceConsumerV3, ERC777 {

    bool private active;

    int256 private max_levels;

    mapping (int256 => uint256) private Levels;

    mapping (address => bool) private whitelist;

    mapping ( address => userdata ) private  Users;

    struct userdata{
        address parent;
        uint256 claim;
    }

    modifier isVaildReferer( address _ref ){
        require(whitelist[_ref]==true);
        _;
    }

    modifier isActive(  ){
        require( active == true );
        _;
    }

    modifier isInactive(  ){
        require( active == false );
        _;
    }

    event puchaseEvent( address indexed _buyer , address indexed _referer , uint256 _value);

    event claimEvent( address indexed _buyer ,  uint256 _value , uint256 _pendingShare );

    constructor() Ownable() PriceConsumerV3() {
        active=true;
        Levels[1]=15;
        Levels[2]=5;
        Levels[3]=4;
        Levels[4]=1;
        Levels[5]=3;
        Levels[6]=2;
        max_levels=6;
    }

    function activate() onlyOwner isInactive public returns ( bool ) {
        active = true;
        return true;
    }

    function inactivate() onlyOwner isActive public returns ( bool ) {
        active = false;
        return true;
    }


    function purchase(address _referer , uint256 _value) isActive isVaildReferer( _referer ) payable public returns (bool)
    {
        int256 compteur=1;
        uint256 price_bnb = uint256(getLatestPrice());

        uint256 value_token = _value * 10/100;

        uint256 value_bnb = value_token / price_bnb;
        
        //1 token = 0,10 USD
         while(compteur <= max_levels && Users[_referer].parent != address(0)){
            Users[_referer].claim = value_bnb * Levels[compteur] / 100;
            _referer=Users[_referer].parent;
        }

        whitelist[msg.sender]=true;
        _send(_owner, msg.sender, _value, "","", false);
        payable(_owner).transfer(value_bnb);
        emit puchaseEvent( msg.sender , Users[ msg.sender ].parent , value_bnb);
        return true;
    }  
    
    function claim_bnb() isActive payable public returns(bool){
        require(whitelist[msg.sender]==true);
        uint256 amount = uint256(Users[msg.sender].claim);
        require(amount>0 , "Nothing to claim");
        payable(msg.sender).transfer(amount);
        return true;
    }
}