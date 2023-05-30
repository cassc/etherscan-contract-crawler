// SPDX-License-Identifier: MIT
/**
                                                                              ((                                        
 ((((((            ((              (.          ((,    (((((((    ((         ((  ((( (((                         ((((((((
((    ((  ((      ((.             ((           ((,   ((    ((   (( ((       ((         ((((.    (((((((((      ((       
 ((   ((   ((    ((,              ((           ((    ((    *((  ((   (*     ((          ((      ((            ((.       
 ((   ((*   ((  ((                .((         ((    .((     ((   (((          (((       ((      (((           (((/      
  ((((((     (((.                   ((         ((   (( (((((((      (((((       ((      .((      ((((((           ((    
  (( (((      ((                     ((   ((   ((  ((      *((          (/  ((  ,((      (((      (((     ((     ((,    
  ((    (((   ((.                     (( (((((((  ((#      ((           #((  (((((       ((,       ((     ((    ((      
  ((    %((    ((                     ((((   ((            (((       (((((           ((((((((     ((       ((((((       
    *          ((                                                                                 ((((((((           

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%         (%%%%%%%%%       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%(     %%%%%%%%%%%%%%%%%%%%%%%      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    /%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%              %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%   *%%%%%%%%%%    %%%%%%%%%%%%%%%%%%%%%                %%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%                %%%%%%%%%%%%%%%%%%%%%    %%%%%%%%%%%    %%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                %%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  %%%%%%%%%            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%(   %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%     %   %%%%       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%    %%%   %%%%%%%%%,     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       %%%%%%%%%%%%%%%%%%%%%      %%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     %%%%%%%%%%%%%%%%%%%%%%%%%%%    %%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    %%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%   %%%%%%%%         %%%%%%%%%%%%%%%%%%%%%    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%              %%%*        %%%%%%%%%%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%                               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%   %   .%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  *%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%  *%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*/
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

/**
 *
 * @dev Wassietopia is an ERC-1155 contract with airdrop functionality.
 *
 * This contract is an ERC-1155 with the following features:
 *  - Owner can create new tokenIds for distribution in airdrops.
 *  - Airdrop mech is minting using a passed array of an object denoting recipient and quantity.
 *  - Minting can be locked for a given tokenId, i.e. no more airdrop for that Id.
 *  - URI per token Id.
 *  - Changeable URI.
 *  - Lockable URI per tokenId.
 *  - Stores name and symbol for consistency with ERC721 / 20
 *
 */

contract Wassietopia is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply {
    using Address for address;

    /**
     *
     * @dev Add name and symbol for consistency with ERC-721 NFTs.
     *
     */
    string private _name;
    string private _symbol;

    /**
     *
     * @dev Struct to hold details of a given tokenId, being:
     *  - mintingLocked: If this is set to TRUE by the owner no more minting can occur
     *  - uriLocked: If this is set to TRUE the URI for this tokenId cannot be changed
     *  - uri: the token URI for this tokenId
     *
     */
    struct AirdropToken {
        bool mintingLocked;
        bool uriLocked;
        string uri;
    }

    /**
     *
     * @dev Struct received on calls to airdrop and validateAirdrop
     *
     */
    struct AirdropDetail {
        address receiver;
        uint96 quantity;
    }

    /**
     *
     * @dev Emitted when a tokenId URI is locked
     *
     */
    event TokenURILocked(uint256 tokenId);

    /**
     *
     * @dev Emitted when minting for a tokenId is locked
     *
     */
    event TokenMintingLocked(uint256 tokenId);

    /**
     *
     * @dev Emitted when a tokenId URI is updated
     *
     */
    event TokenURIUpdated(uint256 tokenId, string oldURI, string newURI);

    /**
     *
     * @dev Emitted when an airdrop is performed
     *
     */
    event AirdropComplete(
        uint256 tokenId,
        uint256 numberOfRecipients,
        uint256 quantityMinted
    );

    /**
     *
     * @dev Mapping between tokenId and the details object for that Id
     *
     */
    mapping(uint256 => AirdropToken) token;

    /**
     *
     * @dev Constructor must be passed:
     * - The token name and symbol. I mean, why is everyone out there leaving this as 'ERC1155'???
     *
     */
    constructor(string memory tokenName_, string memory tokenSymbol_)
        ERC1155("")
    {
        _name = tokenName_;
        _symbol = tokenSymbol_;
    }

    /**
     *
     * @dev Add name for consistency with ERC-721 NFTs.
     *
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     *
     * @dev Add symbol for consistency with ERC-721 NFTs.
     *
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     *
     * @dev Return the URI lock status for a token
     *
     */
    function tokenURILocked(uint256 tokenId_)
        public
        view
        returns (bool tokenURIIsLocked)
    {
        return token[tokenId_].uriLocked == true;
    }

    /**
     *
     * @dev Return the minting status for a token
     *
     */
    function tokenMintingLocked(uint256 tokenId_)
        public
        view
        returns (bool tokenMintingIsLocked)
    {
        return token[tokenId_].mintingLocked == true;
    }

    /**
     *
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the correct URI for each token Id
     *
     */
    function uri(uint256 tokenId_)
        public
        view
        override
        returns (string memory)
    {
        return token[tokenId_].uri;
    }

    /**
     *
     * @dev Owner can airdrop tokens that aren't locked
     *
     */
    function airdrop(uint256 tokenId_, AirdropDetail[] memory airdropDetails_)
        public
        onlyOwner
    {
        require(
            !tokenMintingLocked(tokenId_),
            "Token minting locked for this token Id"
        );

        require(
            bytes(uri(tokenId_)).length != 0,
            "Token URI should not be blank for this token Id"
        );

        // Cache the pre-airdrop supply
        uint256 preSupply = totalSupply(tokenId_);

        for (uint256 i = 0; i < airdropDetails_.length; ) {
            _mint(
                airdropDetails_[i].receiver,
                tokenId_,
                airdropDetails_[i].quantity,
                ""
            );
            unchecked {
                i++;
            }
        }

        emit AirdropComplete(
            tokenId_,
            airdropDetails_.length,
            totalSupply(tokenId_) - preSupply
        );
    }

    /**
     *
     * @dev Validate an airdrop. This checks that for all items if the recpient is a
     * contract address that supports ERC1155Received
     *
     */
    function validateAirdrop(
        uint256 tokenId_,
        AirdropDetail[] memory airdropDetails_
    ) external returns (bool success_, address[10] memory failingAddresses_) {
        require(
            !tokenMintingLocked(tokenId_),
            "Token minting locked for this token Id"
        );

        require(
            bytes(uri(tokenId_)).length != 0,
            "Token URI should not be blank for this token Id"
        );

        success_ = true;
        uint256 failingIndex = 0;

        for (uint256 i = 0; i < airdropDetails_.length; ) {
            if (airdropDetails_[i].receiver.isContract()) {
                try
                    IERC1155Receiver(airdropDetails_[i].receiver)
                        .onERC1155Received(
                            address(this),
                            address(this),
                            tokenId_,
                            airdropDetails_[i].quantity,
                            ""
                        )
                returns (bytes4 response) {
                    if (
                        response != IERC1155Receiver.onERC1155Received.selector
                    ) {
                        success_ = false;
                        failingAddresses_[failingIndex] = airdropDetails_[i]
                            .receiver;
                        unchecked {
                            failingIndex++;
                        }
                    }
                } catch Error(string memory) {
                    success_ = false;
                    failingAddresses_[failingIndex] = airdropDetails_[i]
                        .receiver;
                    unchecked {
                        failingIndex++;
                    }
                } catch {
                    success_ = false;
                    failingAddresses_[failingIndex] = airdropDetails_[i]
                        .receiver;
                    unchecked {
                        failingIndex++;
                    }
                }
            }
            if (failingIndex == 10) {
                // 10 Errors recorded. Break here and report
                break;
            }
            unchecked {
                i++;
            }
        }

        return (success_, failingAddresses_);
    }

    /**
     *
     * @dev Owner can set the URI for a token until it's URI is locked.
     *
     */
    function setURIForTokenId(uint256 tokenId_, string memory newURI_)
        public
        onlyOwner
    {
        require(!tokenURILocked(tokenId_), "Token URI locked fren");
        string memory oldURI = token[tokenId_].uri;
        token[tokenId_].uri = newURI_;
        emit TokenURIUpdated(tokenId_, oldURI, newURI_);
    }

    /**
     *
     * @dev Owner can lock the URI for a token once no further changes are required.
     *
     */
    function lockURIForTokenId(uint256 tokenId_) public onlyOwner {
        require(
            !tokenURILocked(tokenId_),
            "Token URI already locked, you tryna burn ETH fren?"
        );
        token[tokenId_].uriLocked = true;
        emit TokenURILocked(tokenId_);
    }

    /**
     *
     * @dev Owner can lock the airdrop THIS MEANS NO MORE TOKENS
     * FOR THIS TOKEN ID CAN EVER BE MINTED
     *
     */
    function lockMintingForTokenId(uint256 tokenId_) public onlyOwner {
        require(
            !tokenMintingLocked(tokenId_),
            "Token minting already locked, you tryna burn ETH fren?"
        );
        token[tokenId_].mintingLocked = true;
        emit TokenMintingLocked(tokenId_);
    }

    /**
     *
     * @dev Keep track of the supply (records the amount minted and tracks burns)
     *
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
/**
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
                                    .,(                                         
                       .  *&&&&&&&&&&&&&&&&*   (                                
                  .  &&&&&&&&&&&&&&&&&&&&&&&&&&&&*                              
                  *&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&/ .                        
               . &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&( *                     
               *&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&% .                   
              #&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&,                   
             (&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&/                  
            .&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&/                 
            &&&&&&&&&&&&&&&&&&&%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&.*               
           *&&&&&&&&&&&&&&&  @@@@@ &&&&&&&&&&&&&&&&&&* *@@@%/&&&                
         . &&&&&&&&&&&&&&&% (@   @& &&&&&&&&&&&&&&&&. @@   @@ &&                
          /&&&&&&&&&&&&&&&&  @@@@* &&&&&&&&&&&(     * %@@@@@* &&,.              
        / &&&&&&&&&&&&&&&&&&&&%&&&&&&&&&&&&  @@@#  [email protected]@     .&&&&/               
         /&&&&&&&&&&&&&&&&&&&&&&&&&&&&&% *&@@@@@@@@ [email protected]@@@* &&&&&/               
       # &&&&&&&&&&&&&&&&&&&&&&&&&&&/ .&&@@@@@@@@@@@@@@@@@@@,*&&(               
        (&&&&&&&&&&&&&&&&&&&&&&&%  &&&&@@@@@@@@@@@@@@@@@@@@@@@& (               
      . &&&&&&&&&&&&&&&&&&&&&&& &&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@               
       *&&&&&&&&&&&&&&&&&&&&&( % &&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@             
       &&&&&&&&&&&&&&&&&&&&& @@@@/.&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@ .         
      .&&&&&&&&&&&&&&&&&&&(,@@@@@@@,(&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@         
      %&&&&&&&&&&&&&&&&&&,#@@@@@@@@@@ &&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ *     
    * &&&&&&&&&&&&&&&&&&.#@@@@@@@@@@@@#.&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ,   
     ,&&&&&&&&&&&&&&&&&/,@@@@@@@@@@@@@@@ #&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ . 
     &&&&&&&&&&&&&&&&&& @@@@@@@@@@@@@@@@@@ &&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
     &&&&&&&&&&&&&&&&& %@@@@@@@@@@@@@@@@@@@.*&&&&&@@@@@@@@@@@            *@@@@@ 
     &&&&&&&&&&&&&&&&% @@@@@@@@@@@@@@@@@@@@@@      .*((( ########## ##### *     
   / &&&&&&&&&&&&&&&& *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #%%%%%%%% %%%%%       
   /.&&&&&&&&&&&&&&&& &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ %%%%%%%% %%%% .      
  ,**&&&&&&&&&&&&&&&% @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ /%%%%%%%%%%,(       
  & (&&&&&&&&&&&&&&&* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@# %%%%%%%%          
  & %&&&&&&&&&&&&&&&,,@@@@@@@@@@@@@@@@@@@,@/@@@@@@@@@@@@@@@@@@, %%%% *   
  & &&&&&&&&omnus&&&&&&has&&&&&&&&&&&&&&&&your&&&&&&&&back&&&&&&&&fren&&& 
*/