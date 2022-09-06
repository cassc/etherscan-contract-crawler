// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Decanraland_A3{
    
    //"CollectionManager ": "0x9D32AaC179153A991e832550d9F96441Ea27763A"
    //"CollectionStore": "0x214ffC0f0103735728dc66b61A22e4F163e275ae"
    //"MANAToken": "0xA1c57f48F0Deb89f569dFbE6E2B7f46D33606fD4"
    //"FoundationEOACreator1": "0x6ADf75e49bAC21abab9AdB9266d2cC6d90AbD31a"


    //0x395b338bfA1D30A40Dedf4719d5437c0d9aDa347==>allowed
    //0x2CE6fBCe2D940725AF795Bf843f3D08d38801471==>allowed
    //0x08cacBeD8383e77D9B687f5ec089a72B1e03e9d0==>allowed
    //0x6D003fB76f5361C78b5015E0a2972Ba5D0e72C6b==>allowed
    

    //ethereum decentraland contracts
// "ERC721Bid": "0xe479dfd9664c693b2e2992300930b00bfde08233",
// "LANDAuction": "0x54b7a124b44054da3692dbc56b116a35c6a3e561"
// "LegacyMarketplace": "0xb3bca6f5052c7e24726b44da7403b56a8a1b98f8",
// "Marketplace": "0x19a8ed4860007a66805782ed7e0bed4e44fc6717",
// "MarketplaceProxy": "0x8e5660b4ab70168b5a6feea0e0315cb49c8cd539"


//   bool isInitialized = false;
//   function initialize( address[] memory _restricted) public {
//     require(!isInitialized, 'Contract is already initialized!');
//     isInitialized = true;
//     for (uint i; i < _restricted.length; i++) {
//             address restriced = _restricted[i];
//             require(restriced != address(0), "invalid address");
//             require(!isRestriced[restriced], "address is not unique");
//             isRestriced[restriced] = true;
//     }

//   }  
//   mapping(address => bool) public isRestriced;
    //address[] public owners;
    //mapping(address => bool) public isRestriced;
    
    fallback() external payable{

        bytes calldata data = msg.data;
        // bytes calldata lendId =bytes(data[msg.data.length-32:]); //last parameter must be lendingId
        bytes calldata target = bytes(data[msg.data.length-52:msg.data.length-32]);
       // bytes calldata sign = bytes(data[0:4]);
        address targ= address(uint160(bytes20(target)));
        //check restrictions
        if(targ==address(0xE479DfD9664c693b2e2992300930B00bFde08233) || targ==address(0x54B7a124B44054dA3692dBc56B116a35C6a3e561) || targ==address(0xB3BCa6F5052c7e24726b44da7403b56A8A1b98f8) || targ == address(0x19A8Ed4860007A66805782Ed7E0BeD4E44fC6717) ||targ == address(0x8e5660b4Ab70168b5a6fEeA0e0315cb49c8Cd539)){
            
            revert("Invalid contract call");

        }

        else{
           assembly {
            let ptr := mload(0x40) //safe memory pointer created of any data
            let res := sub(calldatasize(),0x40) //subtracting 64bytes from calldata
            calldatacopy(ptr, 0, res) //0 - rest data will be copied to ptr 
            let result := call(gas(), targ, 0, ptr, res, 0, 0)

            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
            }
        }
  
    }


    
    function claimYeildToken(address _token, address _to, uint256 _amount) external{

        IERC20(_token).transfer(_to, _amount);
    }

    receive() external payable {}

}