// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;


//                           @@##(//*/@                                          
//                                @@##(/*****@                                     
//                                 @@%%#//*******(                                 
//                                  @@%%(/******,**@                               
//                                  @@@%(//******,***.                             
//                                 @@@%#(//********,**@                            
//                              @@@@%%#(///*********,**@                           
//                           @@@@%##((///***********,,**@                          
//                         @@@%##(((///**************,,**@                         
//                        @@&%#(((///****************,,**@                         
//                       @@@%#(((//************/////*,,,**&                        
//                       @@%#(((///****/////////////,,,,/@&                        
//                       @@%#(((////////////////////,,,,/@                         
//                        @%##(((///////////////////////%@                         
//                        @@%##((((////////////////,,((@@                          
//                         @@@###(((((((////////(((((#@                            
//                           @@@%###(((((((((((((###@*                             
//                              %@@#############@@/                                
//                                    #@@@@@          
// 
// 
//                                 ´´´´¶¶¶¶¶¶´´´´´´¶¶¶¶¶¶
//                                 ´´¶¶¶¶¶¶¶¶¶¶´´¶¶¶¶¶¶¶¶¶¶
//                                 ´¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶´´´´¶¶¶¶
//                                 ¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶´´´´¶¶¶¶
//                                 ¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶´´¶¶¶¶¶
//                                 ¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶ ´¶¶¶¶¶´
//                                 ´´¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
//                                 ´´´´´¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
//                                 ´´´´´´´¶¶¶¶¶¶¶¶¶¶¶¶¶
//                                 ´´´´´´´´¶¶¶¶¶¶¶¶
//                                 ´´´´´´´´´´´¶¶¶¶
// 
//                                                                   %#########%   
//                        %#####%(        #%%##%%#(              *%##############% 
//           .%%%####%%%########%####  (###############%%#.  .%######.        %###%
//       %%########%#%%###%(. .(   %####,  /,  *%######%%########%.    /####/ .%###
//    ##########%   ,((*,*(#(((#   *%##,  #((((/ (###*     #####%.   ,(((((#  ####(
//  *######.      #((((#,        .%#####   #((((# *%.  .#((( *###    #((((,  %###  
//  %###%    #(((((((((   */(#%%%%%%%, /%    (((#, %    #(((# ###    ((((, *#%,    
// *####%    #(((((((((#/  /%%  (####(#   %.  .(# /##   .#((# (%     ,((#, *##     
//  %####%*       *(((((((   #(/(##(((#   #/   #* %(    ,#((#        #((*  ###*    
//   %########%   .#(((((((#             %,   /(#      #(((((#   .##((#  .%###     
//     %#####%    (((#.       .%%%#(/(%#%      (##     #(##(((((((((#.  %#%.       
//       %###/        #*   .#%##########%,        #((((#    #((((((#  /##%         
//        *####%%%,    #((( .%####    *%####%     /((((       (((((,  %#%.         
//         /######(    #(((#  %##       ####/     *#(#   %%.   .#(((  (##,         
//          %####%     /((((  .#%       %##%      .#(,  .%##.  .#((#  /###         
//           %####            ###(     %###%            (###/    ##   %###         
//           #####(         /%###*    %#####%         (######*      /####%         
//            %######%%%########      %#########%%#####%     %##%%%######/         
//             %##############/        %#############%         %#######%/          
//              ,%########%/             #%######%%.                         
// 
//       
// 
// 
//  ____    ____  ____  ____   ______          _____   ___  __    __   ___   __    __   ___   ____   _      ___   
// |    \  /    ||    ||    \ |      |        |     | /  _]|  |__|  | /   \ |  |__|  | /   \ |    \ | |    |   \  
// |  o  )|  o  | |  | |  _  ||      |        |   __|/  [_ |  |  |  ||     ||  |  |  ||     ||  D  )| |    |    \ 
// |   _/ |     | |  | |  |  ||_|  |_|        |  |_ |    _]|  |  |  ||  O  ||  |  |  ||  O  ||    / | |___ |  D  |
// |  |   |  _  | |  | |  |  |  |  |          |   _]|   [_ |  `  '  ||     ||  `  '  ||     ||    \ |     ||     |
// |  |   |  |  | |  | |  |  |  |  |          |  |  |     | \      / |     | \      / |     ||  .  \|     ||     |
// |__|   |__|__||____||__|__|  |__|     <3   |__|  |_____|  \_/\_/   \___/   \_/\_/   \___/ |__|\_||_____||_____|
                                                                                                               

                                                                                                                              
import "@niftygateway/nifty-contracts/contracts/interfaces/IERC2309.sol";
import "@niftygateway/nifty-contracts/contracts/tokens/ERC721Omnibus.sol";
import "@niftygateway/nifty-contracts/contracts/utils/Royalties.sol";
import "@niftygateway/nifty-contracts/contracts/utils/Signable.sol";
import "@niftygateway/nifty-contracts/contracts/utils/Withdrawable.sol";

contract FewoWorldPaint is ERC721Omnibus, Royalties, Signable, Withdrawable, IERC2309 {    
    
    uint256 constant private BITS_PER_VALUE = 16;
    uint256 constant private MAX_UINT_16 = 0xffff;

    uint256 _nextIndex = 0;
    uint256[] public packedPaintValues;

    constructor(address niftyRegistryContract, address defaultOwner) {
        initializeERC721("FewoWorld Paint", "Paint", "https://api.niftygateway.com/paint/");
        initializeNiftyEntity(niftyRegistryContract);
        initializeDefaultOwner(defaultOwner);        
    }       

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Omnibus, Royalties, NiftyPermissions) returns (bool) {
        return          
        interfaceId == type(IERC2309).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }    

    function getPaintValue(uint256 tokenId) public view returns (uint16) {        
        if(!exists(tokenId)) {
            return 0;
        } else {
            uint256 bin = 0;
            uint256 index = 0;
            uint256 packedWord = 0;

            unchecked {
                bin = (tokenId - 1) / BITS_PER_VALUE;
                index = (tokenId - 1) % BITS_PER_VALUE;
                packedWord = packedPaintValues[bin];
            }
        
            return uint16(MAX_UINT_16 & (packedWord >> (BITS_PER_VALUE * index)));
        }        
    }

    function finalizeContract() external {
        _requireOnlyValidSender();
        collectionStatus.isContractFinalized = true;
    }

    function setBaseURI(string calldata uri) external {
        _requireOnlyValidSender();
        _setBaseURI(uri);        
    }    

    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }              

    function mint(uint256[] calldata paintValues) external {
        _requireOnlyValidSender();

        uint256 numValues = paintValues.length;
        require(numValues > 0, ERROR_INPUT_ARRAY_EMPTY);        

        address to = collectionStatus.defaultOwner;                
        require(to != address(0), ERROR_TRANSFER_TO_ZERO_ADDRESS);                
        require(!collectionStatus.isContractFinalized, ERROR_CONTRACT_IS_FINALIZED);                        

        uint256 index = _nextIndex;
        uint256 valueIx = 0;
        uint256 firstNewTokenId = index + 1;

        uint256 packedWord = 0;
        if(index % BITS_PER_VALUE != 0) {
           packedWord = packedPaintValues[packedPaintValues.length - 1];
           packedPaintValues.pop();
        }

        while(valueIx < numValues) {
           uint256 value = paintValues[valueIx];
           require(value > 0 && value <= MAX_UINT_16, "Requires paint of 1 to 65535");

           uint256 mod16 = index % BITS_PER_VALUE;
           if(mod16 == 0 && packedWord > 0) {
               packedPaintValues.push(packedWord);
               packedWord = 0;
           }

           packedWord |= value << (mod16 * BITS_PER_VALUE);

           valueIx++;
           index++;
        }

        _nextIndex = index;      

        if(packedWord > 0) {
           packedPaintValues.push(packedWord);
        }

        balances[to] += numValues;
        collectionStatus.amountCreated += uint88(numValues);

        emit ConsecutiveTransfer(firstNewTokenId, firstNewTokenId + numValues - 1, address(0), to);
    }    

    function _isValidTokenId(uint256 tokenId) internal virtual view override returns (bool) {        
        return tokenId > 0 && tokenId <= collectionStatus.amountCreated;
    }   

    function _getNiftyType(uint256 /*tokenId*/) internal virtual view override returns (uint256) {        
        return 1;
    } 
    
}