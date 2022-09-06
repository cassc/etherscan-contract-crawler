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

interface SoarProofInterface {
    function ownerOf(uint256 _tokenId) external view returns(address);
    function tokenToLevel(uint16 _tokenId) external view returns(uint8);
}

contract SoarProofOwnControl is SoarProofInterface, Ownable {

    uint16 constant MAX_STAGE_ID = 10;
    uint256 constant public startTime = 1658577600; // 2022-07-23 12:00:00 (UTC)
    uint256 constant public stagePerPeriod = 60 * 60 * 24 * 10; // 60 (sec) * 60 (min/hr) * 24 (hr/day) * 10  = 10 Days

    SoarProofInterface SoarProof;

    uint16[10] eachStageSaledAmount = [0, 42, 0, 0, 0, 
                                        0,  0,  0, 0, 0];

    event StageMaxTokenId(uint8 indexed stageId, uint16 maxTokenId);

    constructor() {
        setSoarProof(0xF2A9E0A3729cd09B6E2B23dcBB1192dBaAB06E15);
    }

    function calculateRewardTime(uint16 _stageId) public pure returns(uint256) {
        return startTime + (_stageId * stagePerPeriod);
    }

    function latestStageId() public view returns(uint16) {
        for(uint16 stageId = MAX_STAGE_ID; stageId > 0; stageId--) {
            if(block.timestamp > calculateRewardTime(stageId)) {
                return stageId;
            }
        }
        return 0;
    }

    function tokenToLevel(uint16 _tokenId) external view returns(uint8) {
      uint16 currentStageId = latestStageId();
      uint16 stageMaxTokenId = eachStageSaledAmount[currentStageId] - 1; // tokenId start from 0, then maxTokenId minus 1.
      if(_tokenId > stageMaxTokenId) {
        return 0;
      }
      return SoarProof.tokenToLevel(_tokenId);
    }

    function ownerOf(uint256 _tokenId) external view returns(address) {
      uint16 currentStageId = latestStageId();
      uint16 stageMaxTokenId = eachStageSaledAmount[currentStageId] - 1; // tokenId start from 0, then maxTokenId minus 1.
      if(_tokenId > stageMaxTokenId) {
        return address(0);
      }
      return SoarProof.ownerOf(_tokenId);
    }

    function setStageSaledAmount(uint8 _stageId, uint16 _maxTokenId) external onlyOwner {
      eachStageSaledAmount[_stageId] = _maxTokenId;
      emit StageMaxTokenId(_stageId, _maxTokenId);
    }

    function setSoarProof(address _addr) public onlyOwner {
        SoarProof = SoarProofInterface(_addr);
    }
}