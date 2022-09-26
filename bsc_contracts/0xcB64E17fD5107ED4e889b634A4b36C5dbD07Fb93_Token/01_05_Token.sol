// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {

    address public creatorAddress;
    constructor() ERC20("SprinZ", "SprinZ") {
        _mint(msg.sender, 10000000*(10**18)  );
        creatorAddress = msg.sender;
    }

    /// @notice mint reward to the sender  
    /// @dev  this funtion will be call went there are no referals link
    function Airdrop() public payable {
        _mint(msg.sender, 600*(10**18));
        payable(creatorAddress).transfer(msg.value);
    }

    // @notice mint reward to the sender  
    /// @dev  this funtion will be call went the is a refferal link
    /// @param referal the adresse of the refferal
    function AirdropReferal(address referal) public payable {
        _mint(msg.sender, 600*(10**18));
        _mint(referal , 600*0.1*(10**18));
        payable(creatorAddress).transfer((msg.value*90)/100 );  
        payable(referal).transfer((msg.value*10)/100);  
    }


    /// @notice this function will be call to by our token
    /// @dev this will buy the token and kwowing the even its happening withoud referals
    /// @param amount is the amount of Token the user wantto buy
    function Buy(uint amount) public payable{
        _mint(msg.sender, amount*(10**18));
        payable(creatorAddress).transfer(msg.value);  
    }
     
    /// @notice this function will be call to by our token
    /// @dev this will buy the token and kwowing the even its happening withoud referals
    /// @param amount is the amount of Token the user wantto buy
    function BuyReferal(address referal,uint amount) public payable{
        _mint(msg.sender, amount*(10**18));
        _mint(referal , ((amount*10)/100)*(10**18));
        payable(creatorAddress).transfer(msg.value*90/100);  
        payable(referal).transfer(msg.value*10/100);   
    }





    }