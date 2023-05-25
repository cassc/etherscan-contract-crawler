// SPDX-License-Identifier: UNLICENSED
/**
           :=*#%%@@@@@@@%%#*=-.         
        =#@@#+==--=+*@@@@@@@@@@@#-      
      :@@%-           :*@@@@@@@@@@@-    
      @@%                [email protected]@@@@@@@@@    
     [email protected]@%                  [email protected]@@@@@@%    
      #@@*                   -+##*=     
       *@@@+:                           
        :#@@@%=.                        
          :#@@@@%=.                     
            [email protected]@@@@%+.                  
               =%@@@@@%+:               
                 :#@@@@@@%+.            
                   -%@@@@@@@%=          
            .-+#%@@@@%#@@@@@@@@*:       
         -*%@@@@#=:    .*@@@@@@@@#:     
      [email protected]@@@@%-          .%@@@@@@@@*    
    .#@@@@@@-              [email protected]@@@@@@@%.  
   [email protected]@@@@@%.                [email protected]@@@@@@@@. 
  #@@@@@@@.                  [email protected]@@@@@@@% 
 #@@@@@@@+                    #@@@@@@@@+
[email protected]@@@@@@@.     %        #.    [email protected]@@@@@@@%
#@@@@@@@@      @*-....:[email protected]     %@@@@@@@@
@@@@@@@@%      @@@@@@@@@@.     *@@@@@@@@
@@@@@@@@%      @@%#**##@@.     *@@@@@@@#
%@@@@@@@@      @.       %.     #@@@@@@@-
[email protected]@@@@@@@-     =        -      @@@@@@@* 
 %@@@@@@@%                    [email protected]@@@@@#  
 .%@@@@@@@#                  :@@@@@@=   
  .#@@@@@@@#.               [email protected]@@@@#.    
    -%@@@@@@@+            .*@@@@#:      
      -#@@@@@@@*=:    .:=#@@@%+.        
         -*%@@@@@@@@@@@@@%*=. 
              &@@@@@@@@%
 */
pragma solidity 0.8.19;

import "../OpenZeppelin/IERC20.sol";

interface IAoriSeats {

    function setMinter(address _minter) external returns (address);

    function setAORITOKEN(IERC20 newAORITOKEN) external returns (IERC20);

    function setBaseURI(string memory baseURI) external returns(string memory);

    function mintSeat() external returns (uint256);

    function combineSeats(uint256 seatIdOne, uint256 seatIdTwo) external returns(uint256);

    function separateSeats(uint256 seatId) external;

    function addPoints(uint256 pointsToAdd, address userAdd) external;

    function addTakerPoints(uint256 pointsToAdd, address userAdd, address Orderbook_) external;

    function addTakerVolume(uint256 volumeToAdd, uint256 seatId, address Orderbook_) external;

    function claimAORI(address claimer) external;

    function setMaxSeats(uint256 newMaxSeats) external  returns (uint256);
 
    function setFeeMultiplier(uint256 newFeeMultiplier) external  returns (uint256);

    function setMaxSeatScore(uint256 newMaxScore) external  returns(uint256);

    function setMinFee(uint256 newMintFee) external  returns (uint256);

    function getOptionMintingFee() external view returns (uint256);

    function confirmExists(uint256 seatId) external view returns (bool);

    function getTotalPoints(address user) external view returns (uint256);
    
    function getClaimablePoints(address user) external view returns (uint256);

    function getSeatScore(uint256 seatId) external view returns (uint256);

    function getmaxSeatScore() external view returns (uint256);
    
    function getFeeMultiplier() external view returns (uint256);

    function getSeatVolume(uint256 seatId) external view returns (uint256);
}