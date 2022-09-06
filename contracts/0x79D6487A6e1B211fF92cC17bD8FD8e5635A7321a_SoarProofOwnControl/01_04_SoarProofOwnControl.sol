// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

/**                                                              
                                          .::::.                                          
                                      -+*########*+-                                      
                                   .=################=.                                   
                                 .=######*=-::-=++++++=:                                  
                      ......   .=######+.  .........................                      
                 .-+*#####+. .=######+. .=###########################*+-.                 
                =#######+. .=######+. .=#################################=                
               +*****+=. .=******+.  .-----------------------------=+*****+               
              -*****:  .=******+.                          :::::::.  :*****-              
              =*****  -******=.                            .=******=. .+***=              
              :*****-                                        .=******=. .+*:              
               =******+++++++++++==-:.              .:-==+++=. .=******=. .               
                :*********************+:          :+**********=. .=******=.               
             .=-  :-+*******************-        -**************=. .=******=.             
           .=****=:                =*****        *****=              .=******=.           
         .=******=.                .*****.      .*****.                .=******=.         
        =******=.                  .*****.      .*****.                  .=******=        
      :******=.                    .*****.      .*****.                    .=******:      
     :*****+.                      .*****.      .*****.                      .+*****:     
     +****=                        .*****.      .*****.                        =****+     
    .*****.                        .*****.      .*****.                        .*****.    
    .*****:                        .*****.      .*****.                        :*****.    
     =****+.                       .*****.      .*****.                       .+****=     
      +****+-                      .*****.      .*****.                      -+****+      
       =*****+-                    .*****.      .*****.                    -+*****=       
        .=*****+-                  .*****.      .*****.                  -+*****=.        
          .=*****+-                .*****.      .*****.                -+*****=.          
            .=++++++-              .+++++.      .+++++.              -++++++=.            
              .=++++++-            .+++++.      .+++++.            -++++++=.              
                .=++++++-          .+++++.      .+++++.          -++++++=.                
                  .=++++++-        .+++++.      .+++++.        -++++++=.                  
                    .=++++++-      .+++++.      .+++++.      -++++++=.                    
                      .=++++++-     +++++=      =+++++     -++++++=.                      
                        .=++++++-   :+++++-    -+++++:   -++++++=.                        
                          .=++++++-  .::::.  :++++++-  -++++++=.                          
                            .=++++++=-::::-=+++++++:  =+++++=.                            
                              .=+++++++++++++++++:  :+++++=.                              
                                 :=++++++++++=-.  :++++=:                                 
                                     ......      ....
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/IERC721A.sol";

interface SoarProofNftInterface is IERC721A {
    function tokenToLevel(uint16 _tokenId) external view returns(uint8);
}

error error();

contract SoarProofOwnControl is Ownable {

    uint16 constant MAX_STAGE_ID = 10;
    uint256 constant public batch1startTime = 1658577600; // 2022-07-23 12:00:00 (UTC)
    uint256 constant public batch2startTime = 1659711600; // 2022-08-05 15:00:00 (UTC)
    uint256 constant public stagePerPeriod = 60 * 60 * 24 * 10; // 60 (sec) * 60 (min/hr) * 24 (hr/day) * 10  = 10 Days

    SoarProofNftInterface SoarProof;

    struct ClaimStageInfo {
      uint16 startToken;
      uint16 endToken;
      uint256 claimStartTime;
    }

    ClaimStageInfo[] public tokenToClaimStageInfo;

    event SetClaimStageInfo(uint16 indexed startToken, uint16 indexed endToken, uint256 claimStartTime);

    constructor() {
        setSoarProof(0xF2A9E0A3729cd09B6E2B23dcBB1192dBaAB06E15);
        addClaimStageInfo(0, 41, batch1startTime);
        addClaimStageInfo(42, 66, batch2startTime);
    }

    function getClaimStageStartTimeByToken(uint16 _tokenId) public view returns (uint256) {
      for(uint idx = 0; idx < tokenToClaimStageInfo.length; idx++) {
        ClaimStageInfo memory info = tokenToClaimStageInfo[idx];
        if(_tokenId >= info.startToken && _tokenId <= info.endToken) {
          return info.claimStartTime;
        }
      }
      revert error();
    }

    function calculateRewardTime(uint256 _startTime, uint16 _stageId) public pure returns(uint256) {
        return _startTime + (_stageId * stagePerPeriod);
    }

    function latestStageId(uint16 _tokenId) public view returns(uint16) {
      uint256 startTime = getClaimStageStartTimeByToken(_tokenId);

      for(uint16 stageId = MAX_STAGE_ID; stageId > 0; stageId--) {
          if(block.timestamp > calculateRewardTime(startTime, stageId)) {
              return stageId;
          }
      }
      return 0;
    }

    function tokenToLevel(uint16 _tokenId) external view returns(uint8) {
      uint16 currentStageId = latestStageId(_tokenId);
      if(currentStageId == 0) {
        revert error();
      }
      return SoarProof.tokenToLevel(_tokenId);
    }

    function ownerOf(uint256 _tokenId) external view returns(address) {
      uint16 currentStageId = latestStageId(uint16(_tokenId));
      if(currentStageId == 0) {
        revert error();
      }
      return SoarProof.ownerOf(_tokenId);
    }

    function addClaimStageInfo(uint16 startToken, uint16 endToken, uint256 claimStartTime) public onlyOwner {
      tokenToClaimStageInfo.push(ClaimStageInfo(startToken, endToken, claimStartTime));
      emit SetClaimStageInfo(startToken, endToken, claimStartTime);
    }

    function setClaimStageInfo(uint256 idx, uint16 startToken, uint16 endToken, uint256 claimStartTime) external onlyOwner {
      tokenToClaimStageInfo[idx] = ClaimStageInfo(startToken, endToken, claimStartTime);
      emit SetClaimStageInfo(startToken, endToken, claimStartTime);
    }

    function setSoarProof(address _addr) public onlyOwner {
        SoarProof = SoarProofNftInterface(_addr);
    }
}