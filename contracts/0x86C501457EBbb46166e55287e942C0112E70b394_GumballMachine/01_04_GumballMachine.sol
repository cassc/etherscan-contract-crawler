// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/*
kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk
kkkkkkkkkkkkkkkkkkkxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxkkkkkkkkkkkkkkkkkkkkkk
kkkxxkkkkkkkkkkkxxxkkkxkkkkkkkkkkOOOOOOOkOOOkkkkkkkkxxkxxxkkxkkkkkkkkkkkkkkkxxkk
kkxkkxxkkkkkkkkxkkkkxxxkkkkOkkdlc:;,,,,,,,;:cloxkOkkkxxxxxkkkkkkkkkkkkkxxxkkkxkk
kkkkkkxxkkkkkkkkkkkkkkkkkxo:,..  ..'',,'''.    .';ldkkkkkkkkkkkkkkkkkkkkkxkxxkkk
kkkkkkkkkkkkkkkkkkkkkkxl;.  .;lddkXNWWWWNNx..co:'. .'cdkOkkkkxkkkkxxkkkkkkkkkkkk
kkkkkkkkkxkkkkkkkkkkxc.  'lxxxKNxkWMMMMMMK; 'oONN0d;. .;dkkkkkxxxxxxxkOkkkkkkkkk
kkkkkkxxxxxkkkkkkkkl.  ;xOd:,c0MMMMMMMMMMXkd,'kWMMMW0l. .;dkkkkxxxkxxkOkkkkkkkkk
kkkkkkxxkxxkkkxkkd,  ,k0l,;xXWMMMMMMMMMMMMWOdKMMMMMMMWKl. .ckOkkkkkkkkkkkkkkkkkk
kkkkkkkxkxxxkkkko. .oXk';kNMMMMMMMMMMMMMMMN0NMMMMMMMMMMWO,  :xkkkkkkxxkkkkkkkkkk
kkkkkkkkkkkkkkko. .xWWKONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK:  :kOkkxkxxkkkkkkkkkk
kkkkkkkkkkkkkOd. .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;  ckkxxxkkxxkkkkkkkk
kkkxkkxxkkkkOk;  cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO. .dOkxxxkxxkkkkkkkk
kkxkkxxxkkxkOd. .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc  :kkkkkkkkkkkkkkkk
kkkkxxkkxxxkOl. ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx. ,kOkkkkkkkkkkxkkk
kkkkkkkkxkkkkc  cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXXKK00XWk. 'xOkkkkkkkkkxxxkk
kkkkkkkkkkkkOl. :NMMMMMMMMMMMMMMMMMMMMMMMMMMWX0kxooolcc:::xNx. 'xOkkkkkkxxxkkxkk
kkkkkkkkkkkkOo. '0MMMMMMMMMMMMWWNNNNNNNXXKOxoc'...,::::::l0No  ;kkkkkkkkkkkkkkkk
kkkkkkxkkkkkkk;  oWMMMWNXKOxxdodoooocoolcc:::,....;::::::lK0' .oOkkkkkkkkkkkkkkk
kkkkkkxxkkkxkOo. .kWXkdlc;....,:::::::lO0Odc:' ..':::::::l0o  ;kOkkxxkkkkkkkkkkk
kkkxkkkkxkkxkkkc. 'OXxc::' ..':::::::cOWWMNkl' ..':::::::dXd  'dOkkkkxkxxkxkkkkk
kkkkxkkkxkkkkkkkc. .xN0o:. ..':::::::oKX0kx0Kd;'.':::cldONMNl  ,xkxxkkkkkxkkkkkk
kkkkkkkkkkkkkkkkko. .c0Oc. ..,::::::l0Nl   .xNX0OkOO0KXWMMMMK, .oOkkkxxkkkkkkkkk
kkkkkkkkkkkkkkkkkkx;. 'kO:...,:::coxKW0'    .oNMMMMMMMMMMMMM0' .oOkkkkkkkkkkkkkk
kkkkkkkkkkxxkkkkxkOk:  lWXOxxxkO0KNWMMO.     ;KMMMMMMMMMMMW0;  :kkkkkkkkkkkkkkkk
kkkkkkkkkkxxxkxxxkkk:  oWMMMMMMMMMMMMMWOoc;:o0WMMMMMMMN0xo:. .cxkkkkkkxxxkxxxkkk
kkkkkkkkkkxxxxxkkkkOl. ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;     ,dkkkkkkkkxxxxxkkkkk
kkkkkkkkkkkkkxkkkkkkk:  ,xXMMMMMMMMMMMMMMMMMMMMMMMMMMx. ;c  cOkkkkkOkkkxxxkkkkkk
kkkkkxxkkkkkkkkkkkkkOkl.  .;cc:;:xNMMMMMMMMMMMMMWX0xc. .kO. ;kOkkkkkkkkkkkkkkkkk
kkxkkxxkkkxkOkkkkkkkkkkxo:,.  ..  c0XDGAPX0Oxdl:,.. .,lKWK, 'xOkkkkkxxxkkkkkkkkk
kkkxkxxkkkkkkkkxkkkxxkkkkkOx, .do. ........  ..';cokKWMMMWc .oOkkkkkxxkxxkkkkkkk
kkkkkkkkkkkOkkkxxkkkkxkkkkkOo. :X0ooloooddxkO0XNWMMMMMMMMWl  cOkkkkxxkkxkkkkkkkk
kkkkkkkkkkOkkkkkkkxxkkkkkkkkk: .dOdNVTQSWDHMMMMMMMMMMMMNk;. 'okkkkkkkkkkkOkkkkkk
kkkkkkkkkkkkkkkkkkxxkkkkkkkkOx' '0WOccoxkOKWMMMMMMMMWKd, .,okkkkkkkkkkkkkkkkkkkk
kkkkkkkkxxkkkkkkkkkkkkkkkkkkkOl. 'clcccc::dXMMMMMN0d:. .:dkkkkkkkkkkkkkxkkkxxkkk
kkOkxxkkkxxxkkkkkkkkkkkkkxxxkkkl;'.....,;:cooool:'. .,lxkkkkkxxkkkkkkkxxxkkkkkkk
kkkkxxxxxxkkxkkkkkkkkkkkxxxxxkkkOkkdoc:;,,'.....';coxkkkkkxxkxxxkkxkkkkxkkkkkkkk
kkkkkkxxxkkkkkkkkkkOkkkxxkkxxkkkkkkkkkOOOkkkkxkkkOOkkkkkkkxxxkxxxkkkkkkkkkkkkkkk
kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOkkkkkkkkkkkkkkkkklancexwasxherextookkkk
kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk
*/

/**
 * @title Gumball Machine
 * @author Swag Golf
 */
contract GumballMachine is Ownable, Pausable {

    uint256 public _totalGumballs = 888;
    uint256 public _gumballPrice;
    uint256 public _maxBatchHandleTurns = 10;

    address public _withdrawalAddress;

    uint256 public _nextToDispense = 1;

    event DispenseGumball( address indexed to, uint256 startIndex, uint256 quantity );

    function setGumballPrice(
        uint256 gumballPrice
    )
        external
        onlyOwner 
    {
        _gumballPrice = gumballPrice;
    }

    function setMaxBatchHandleTurns(
        uint256 maxBatchHandleTurns
    )
        external
        onlyOwner 
    {
        _maxBatchHandleTurns = maxBatchHandleTurns;
    }

    constructor( 
        uint256 gumballPrice, 
        uint256 maxBatchHandleTurns,
        address withdrawalAddress )
    {
        _gumballPrice = gumballPrice;
        _maxBatchHandleTurns = maxBatchHandleTurns;
        _withdrawalAddress = withdrawalAddress;

        _pause();
    }

    function turnHandle(
        uint256 turns) 
        external 
        whenNotPaused
        payable
    {
        require( ( _nextToDispense + turns ) <= _totalGumballs, "Turns would exceed gumball supply" );
        require( turns <= _maxBatchHandleTurns, "Attempt to turn handle more than maximum allowed" );
        require( msg.value >= ( turns * _gumballPrice ), "Invalid payment amount" );
        
        emit DispenseGumball( msg.sender, _nextToDispense, turns );

        _nextToDispense += turns;
        
    } 

    function pause() 
        external
        onlyOwner
    {
        _pause();
    }

    function unPause()
        external
        onlyOwner 
    {
        _unpause();
    }

    function setWithdrawalAddress( address newAddress ) 
        external 
        onlyOwner 
    {
        _withdrawalAddress = newAddress;
    }

    function withdraw() 
        external 
        onlyOwner 
    {
        (bool success, ) = _withdrawalAddress.call{value: address(this).balance}("");
        require(success);
    }
}