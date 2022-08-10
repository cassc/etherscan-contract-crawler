//SPDX-License-Identifier: Unlicense
//Author: Goldmember#0001
                                                                                
// Plots                                             ///                  
//                                            ,//////////////              
//                                           //////////////////            
//                                           ///////////////////           
//                                           ////////////////////          
//                                   %%      ////////////////////          
//                              #%%%%%%%      //////////////////           
//                               %%%%%%%%      ,///////////////            
//                            #, %%%%%%%%%        ///////////              
//                          #### %%%%%%%%%%                                
//                         #####  %%%%%%             ,,,                   
//                  %%%%  ///     %%   ((((  %%      ,,                    
//              %%%%%%%% ////////  ((((((((  %%%%%%  ,,                    
//         #%%%%%%%%%%%. //////// .(((((((( .%%%%%%% ,,                    
//      %%%%%%%%%%%%%%%  ////////  (((((((( %%%%%%%. ,, %%%                
//        %%%%%%%%%%%%%%   //////  (((((  %%%%%%%%%%%%%%%(                 
//     #####  %%%%%%%%%%%%%%%   /  (  %%%%%%%%%%%%%%%   ******             
//     #########  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  **********              
//     ############(  %%%%%%%%%%%%%%%%%%%%%%%  **************              
//     #################   %%%%%%%%%%%%%%%  *****************              
//     #####################   %%%%%%#  *********************              
//     #########################    *************************              
//     ##########################  **************************              
//    (########################## .**************************              
//      (######################## *************************                
//          *#################### *********************                    
//               ################ *****************                        
//                   ############ *************                            
//                        ####### **********                               
//                             ## ****** 
pragma solidity ^0.8.12;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import { IERC2981, IERC165 } from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract LykePlots is ERC721A, IERC2981, IERC721Receiver, Ownable {

    // collection details
    uint256 public constant COLLECTION_SIZE = 120;

    // compatibity with Inhabitants
    address public inhabitantsAddress;
    uint256 public wcToInhsPercentage = 50; // the max percent of wildcards to inhabitants (30 = 30%)

    // stores characteristics of each plot
    mapping(uint256 => uint256[]) private plotMap;
    uint256[] private wildcardIds;

    // functionalities
    address public royaltiesAddress;
    uint256 public royaltiesPercentage; // 50 = 5%
    bool private isChangingLocked;

    // errors
    error insufficientPaid();
    error notEnoughSupply();
    error nothingToWithdraw();
    error withdrawFailed();
    error tokenDoesNotExist();
    error plotDataInvalid();
    error plotIdsTooLarge();
    error notTokenOwner();
    error inhabitantsInvalid();
    error inhabitantsOwnershipFailed();
    error wildcardsInvalid();

    constructor(
        address _inhabitantsAddress,

        address _royaltiesAddress,
        uint256 _royaltiesPercentage
    ) 
    ERC721A("Lyke Inhabitant Plots", "LYKEINPLOTS") 
    {
        inhabitantsAddress = _inhabitantsAddress;

        royaltiesAddress = _royaltiesAddress;
        royaltiesPercentage = _royaltiesPercentage;
    }

    /*
    * @dev mints tokens in the collection
    */
    function mint(uint256 _quantity) public onlyOwner {
        if(_totalMinted() + _quantity > COLLECTION_SIZE) revert notEnoughSupply();
        _safeMint(address(this), _quantity);
        this.setApprovalForAll(owner(), true); //bit inefficient, but gas is non-material given the size
    }

    /*
    * @dev returns the inhabitants left to validate from the plot's token ids and returns a number of how many are
    * left without a valid match.
    * 0 is a perfect match.
    * It is implemented like this so we can reuse it for wildcards
    */
    function validateInhabitantsForPlot(uint256 _plotId, uint256[] memory  _inhabitantIds) 
        private view returns(uint256) {

        // initializes data to validate and counter for what is left to validate
        uint256 _unmatchedInhabs = plotMap[_plotId].length;

        // validates all inhabitants needed
        for (uint j = 0; j < plotMap[_plotId].length; j++) {
            for (uint i = 0; i < _inhabitantIds.length; i++) {
                if(_inhabitantIds[i] == plotMap[_plotId][j]) {
                    _unmatchedInhabs -= 1;
                    break;
                }
            }
        }

        return _unmatchedInhabs;
    }

    /*
    * @dev validates ownership of inhabitant tokens given an array of token ids and an address
    * if any are not owned by the address, the function returns false
    */
    function validateInhabitantOwnership(address _owner, uint256[] memory _tokenIds) 
        private view returns(bool) {
        for(uint i = 0; i < _tokenIds.length; i++) {
            if(IERC721A(inhabitantsAddress).ownerOf(_tokenIds[i]) != _owner) {
                return false;
            }
        }
        return true;
    }

    /*
    * @dev Claim a token based on a mapping for inhabitant tokens and the plot id.
    * Validates, based on the tokenId to claim, if the submitted tokens to claim are valid. 
    * Can receive a larger number of inhabitants than the required for the plot and still succeed. 
    * This does an exact match, doesn't allow wildcards
    */
    function claimPlot(uint256 _plotId, uint256[] calldata _inhabitantIds) public {
        // checks if all tokens belong to caller
        if(!validateInhabitantOwnership(msg.sender, _inhabitantIds)) revert inhabitantsOwnershipFailed();
        // checks if inhabitants passed are valid for plot
        uint256 _validationResults =  validateInhabitantsForPlot(_plotId, _inhabitantIds);
        if(_validationResults != 0) revert inhabitantsInvalid();

        // sends the plot to the claimer
        this.safeTransferFrom(address(this), msg.sender, _plotId);
    }

    /*
    * @dev validates if the number of wildcards is appropriate for the plot
    */
    function validateWildcardUsage(uint256 _plotId, uint256 _inhabsToFill, uint256[] memory _wildcards) 
        private view returns(bool) {

        if(_wildcards.length != _inhabsToFill) return false;
        if(_wildcards.length / getPlotInhabitants(_plotId).length >= wcToInhsPercentage) return false;

        uint256 _wcsToValidate = _wildcards.length;
        for(uint256 i = 0; i < _wildcards.length; i++) {
            for(uint256 j = 0; j < wildcardIds.length; j++) {
                if(_wildcards[i] == wildcardIds[j]) {
                    _wcsToValidate -= 1;
                    break;
                }
            }
        }

        if(_wcsToValidate == 0) return true;

        else return false;
    }

    /*
    * @dev Claim a token based on a mapping for inhabitant tokens and the plot id.
    * Validates, based on the tokenId to claim, if the submitted tokens to claim are valid.
    * Takes wildcards, validates them, and burns them. 
    */
    function claimPlot(uint256 _plotId, uint256[] memory _inhabitantIds, uint256[] memory _wildcards) public {
        // checks if all tokens (inhabs and wildcards) belong to caller
        if(!validateInhabitantOwnership(msg.sender, _inhabitantIds)) revert inhabitantsOwnershipFailed();
        if(!validateInhabitantOwnership(msg.sender, _wildcards)) revert inhabitantsOwnershipFailed();
        // calculates how many inhabitants need to be replaced by wildcards
        uint256 _validationResults =  validateInhabitantsForPlot(_plotId, _inhabitantIds);
        // checks if the wildcards are valid
        if(!validateWildcardUsage(_plotId, _validationResults, _wildcards)) revert wildcardsInvalid();
        
        // burns wildcards (sends to 0x0, no supply reduction)
        for(uint256 i = 0; i < _wildcards.length; i++) {
            IERC721A(inhabitantsAddress).safeTransferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), _wildcards[i]);
        }
        
        // sends the plot to the claimer
        this.safeTransferFrom(address(this), msg.sender, _plotId);

    }

    function setPlotMap(uint256 _plotId, uint256[] memory _inhabIds) public onlyOwner {
        plotMap[_plotId] = _inhabIds;
    }

    function setPlotMap(uint256[] memory _plotIds, uint256[][] memory _inhabIds) public onlyOwner {
        if(_plotIds.length > COLLECTION_SIZE) revert plotIdsTooLarge();
        if(_plotIds.length != _inhabIds.length) revert plotDataInvalid();
        for(uint i = 0; i < _plotIds.length; i++) {
            plotMap[_plotIds[i]] = _inhabIds[i];
        }
    }

    function lockChanges() public onlyOwner {
        isChangingLocked = true;
    }

    function setWildcardToInhabitantRatio(uint256 _newRatio) public onlyOwner {
        wcToInhsPercentage = _newRatio;
    }

    function setWildcardIds(uint256[] memory _wildcardIds) public onlyOwner {
        wildcardIds = _wildcardIds;
    } 
    
    // getters

    function getPlotInhabitants(uint256 _plotId) public view returns(uint256[] memory) {
        return plotMap[_plotId];
    }

    // overrides

    // ERC165

    function supportsInterface(bytes4 _interfaceId) 
        public view override(ERC721A, IERC165) returns (bool) 
    {
      return _interfaceId == type(IERC2981).interfaceId 
        || super.supportsInterface(_interfaceId);
    }

    function _startTokenId() internal view virtual override returns(uint256) {
        return 1;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256 royaltyAmount) {
      if(!_exists(_tokenId)) revert tokenDoesNotExist();
      royaltyAmount = (_salePrice / 1000) * royaltiesPercentage;
      return (royaltiesAddress, royaltyAmount);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) virtual override external returns (bytes4) {
        operator;from;tokenId;data; // to silence warning

        return this.onERC721Received.selector;

    }
    
}