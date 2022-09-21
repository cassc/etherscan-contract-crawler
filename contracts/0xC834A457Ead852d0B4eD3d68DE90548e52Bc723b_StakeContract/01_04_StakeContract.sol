// SPDX-License-Identifier: MIT
                                                                                                                                       
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////                                                                  :-                                                                            
//                                                                                                                                                          //
//                                                                                                                                                          //
//                                                                            /\                                                                            //
//                                                                           /=*\                                                                           //
//                                                                          -+  -#.\                                                                        //
//                                                                          #.  =#*=\                                                                       //
//                                                                     /\ -+      @ //                                                                      //
//                                                                    /*  .#       *:./.                                                                    //
//                                                                 :# .+==+.       *-=%\                                                                    //
//                                                                 +=  +=+         =*#.//                                                                   //
//                                                                 :#                . +-\                                                                  //
//                                                              :.  %.    ::@@@@@@::    .# \                                                                //
//       [email protected]@@@@@@@@@@@%#.                           ::::        %*-=* :+%@@@@@@@@@@@%+. -**%.          [email protected]@@@@@@@@@@@%*   :::.              @@:              //
//        [email protected]@@@####%@@@@-                          [email protected]@@+       -+ . :#@@@@@@@@@@@@@@@@@#:  -*           [email protected]@@@####%@@@@. [email protected]@@=              @@:              //
//        %@@@=    [email protected]@@%                           %@@@        ==  [email protected]@@@@@@@@@@@@@@@@@@@@*. %.         [email protected]@@@-    #@@@#  @@@%              [email protected]@@.             //
//       [email protected]@@%     :+#@:                          [email protected]@@=        :* *@@@ COOL SKULL CLUB @@@%.*         *@@@#     -+%@. [email protected]@@=               @@@%              //
//       %@@@=           :#######:   .####### :  [email protected]@@@          #[email protected]@@@@@@@@@@@@@@@@@@@@@@@@#%.        [email protected]@@@:          [email protected]@@% :###:   :###: *@@@+####:        //
//      [email protected]@@%          [email protected]@@@@@@@@@# *@@@@@@@@@@+ [email protected]@@-          [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@=         *@@@*           *@@@- %@@@   :@@@*[email protected]@@@@@@@@@@:       //
//     [email protected]@@@-         [email protected]@@%[email protected]@@=:@@@*...%@@@:[email protected]@@#            @@@@@%@@@@@@@@@@@@@@@@@@@@%         [email protected]@@@.          [email protected]@@# [email protected]@@=   %@@@.*@@@[email protected]@@%        //
//     [email protected]@@%       := *@@@-   @@@@ %@@@.  :@@@# *@@@:            *@@@@=-----#@@@#-----%@@@@*         #@@@*       :-  *@@@: %@@@   [email protected]@@*[email protected]@@#   *@@@=        //
//    [email protected]@@@:    +#@@*[email protected]@@#   [email protected]@@[email protected]@@+   #@@@:[email protected]@@#             .*@@=      :@@@   \,/  *@@*.       [email protected]@@@.    +#@@+ :@@@# [email protected]@@=   %@@@ *@@@.  :@@@%         //
//    [email protected]@@*    [email protected]@@@:*@@@:  [email protected]@@% %@@@   [email protected]@@* #@@@:               @@+     .*@@@-  /'\  #@@         #@@@+    [email protected]@@@. #@@@: @@@@   [email protected]@@=:@@@*   #@@@:         //
//    @@@@@%%%%@@@@+ @@@@###%@@@:[email protected]@@@###@@@@.:@@@@.              [email protected]@@#**[email protected]@-#[email protected]@%***%@@@=        [email protected]@@@@%%%%@@@@= [email protected]@@@[email protected]@@@%%%@@@@ #@@@%##%@@@+          //
//    -*#########*-  +########*: .*########+. +####*:              *@@@@@@@@. * :@@@@@@@@*          =*#########+:  +####*=*###**%@@%-:########*=.           //
//                                                                  .=+:[email protected]@@@@@%@@@@=-+=.                                                                   //
//                                                                       @@@@@@@@@@@                                                                        //
//                                                                       *@@@@@@@@@*                                                                        //
//                                                                         /SKULL/                                                                          //
//                                                                                                                                                          //
//                                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// @title : CoolSkullClubStaking
// @version: 1.0
// @description: Cool Skull Club Staking for the Ethereum Ecosystem
// @license: MIT
// @developer: @0xKayaoglu - kayaoglu.eth                                                                                                                                
// @artist: @0xRuhsten - ruhsten.eth
// @advisor: @cipekci - canipekci.eth
// @community: @thepunktum - punktum

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract StakeContract is ReentrancyGuard {

    address private CONTRACT_WALLET = address(this);

    struct StakedToken {
        address staker;
        uint256 tokenId;
    }
    
    struct Staker {
        uint256 amountStaked;
        StakedToken[] stakedTokens;
    }

    mapping(address => Staker) public stakers;
    mapping(uint256 => address) public stakerAddress;

    function _stake( address _owner, address _contract, uint256 _tokenId ) public {
        
        require(
            IERC721(_contract).ownerOf(_tokenId) == _owner,
            "You don't own this token!"
        );
        
        IERC721(_contract).transferFrom( _owner, CONTRACT_WALLET, _tokenId );
        
        StakedToken memory stakedToken = StakedToken(_owner, _tokenId);
        stakers[_owner].stakedTokens.push(stakedToken);
        stakers[_owner].amountStaked++;
        stakerAddress[_tokenId] = _owner;

    }

    function _unstake( address _owner, address _contract, uint256 _tokenId ) public {
        
        require(
            stakers[_owner].amountStaked > 0,
            "You have no tokens staked"
        );

        require(stakerAddress[_tokenId] == _owner, "You don't own this token!");

        uint256 index = 0;
        for (uint256 i = 0; i < stakers[_owner].stakedTokens.length; i++) {
            if (
                stakers[_owner].stakedTokens[i].tokenId == _tokenId 
                && 
                stakers[_owner].stakedTokens[i].staker != address(0)
            ) {
                index = i;
                break;
            }
        }

        stakers[_owner].stakedTokens[index].staker = address(0);
        stakers[_owner].amountStaked--;
        stakerAddress[_tokenId] = address(0);

        IERC721(_contract).transferFrom( CONTRACT_WALLET, _owner, _tokenId );

    }

    function Stake( address _contract, uint256[] memory _tokenIds ) external nonReentrant {
        
        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            _stake(msg.sender, _contract, _tokenIds[i]);
        }

    }

    function UnStake( address _contract, uint256[] memory _tokenIds ) external nonReentrant {
       
        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            _unstake(msg.sender, _contract, _tokenIds[i]);
        }

    }

    function getStakedTokens(address _user) public view returns (StakedToken[] memory) {
        if (stakers[_user].amountStaked > 0) {
            
            StakedToken[] memory _stakedTokens = new StakedToken[](stakers[_user].amountStaked);
            uint256 _index = 0;

            for (uint256 j = 0; j < stakers[_user].stakedTokens.length; j++) {
                if (stakers[_user].stakedTokens[j].staker != (address(0))) {
                    _stakedTokens[_index] = stakers[_user].stakedTokens[j];
                    _index++;
                }
            }

            return _stakedTokens;
        }
        
        else {
            return new StakedToken[](0);
        }
    }

}