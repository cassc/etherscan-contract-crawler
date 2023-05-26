// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "../utils/Bearable.sol";
import "../utils/TwoBitHoneyErrors.sol";

/// @title Honey Processor: Phase 1
contract TwoBitHoney is Bearable, ERC1155, Ownable {
    /*
                             .:..                                                     
                            .=++=-::-++=.                                                 
                          .*=          .+*                                                
                         :#.             :#                                               
                         %.               =+                                              
                         @                .#                                              
                 ==:     %.               -+  :=+===:                                     
                 +==#-   -#               %=++:     -*-                                   
             :+++=   %:   ++             ##-          *-                                  
             :+. :%: +*    =*          .#-            .#                                  
                  -% *=     :#:       =*.             =+                                  
                 .=%=*+=-     +*.   -*-             :*=                                   
                ++.     :*++*==%@*+#=         .:-=++-                                     
               =* .:     :@@#  #@@@[email protected]@@#+#@*=-:.                                         
               =*.-.:    [email protected]@=  @@@@  @@@+ [email protected]@#:                                           
                *=      [email protected]@%  *@@@= [email protected]@@- *@@+++                                          
                 :+=====#@*  [email protected]@@*  %@@% [email protected]@@[email protected]+                                         
                         +*-%@@@+  #@@@: %@@+ [email protected]@*-                                       
                          [email protected]@%: .#@@@: #@@* [email protected]#=--                                       
                             [email protected]@@%..#@@#=*+:    .-*#+:                                 
                                :-+*==**+=-.    :+*+-  .=**-                              
                                            .=**=.         -*#+:                          
                                         :+*+:                .=**:                       
                                         **                      +*                       
                                         *+                      +*                       
                                         *+                      +*                       
                                         *+                      +*                       
                                         *+                      +*                       
                                         *+                      +*                       
                                         *#                      **                       
                                          -**=:              .=**-.                       
                                     -+**#=: :=**-        -+*+:                           
                                 .=**-.   :+**-  -**+:.=**-.                              
                              -**+:           -**=. .=+:                                  
                           -#*-                  :+#=                                     
                           +*                      =#                                     
                           +*                      =#                                     
                           +*                      =#                                     
                           +*                      =#                                     
                           +*                      =#                                     
                           +*                      =#                                     
                           =%-.                   -#*                                     
                             -+*+:            .=**=. .:                                   
                                .=**=.     -+*+:  :+*+=**=.                               
                                    -*#+=#*=. .=*#=.     :*#+:                            
                                       :-  :+*+-            :+**-                         
                                         =#=.                   -#+                       
                                         *+                      +*                       
                                         *+                      +*                       
                                         *+                      +*                       
                                         *+                      +*                       
                                         *+                      +*                       
                                         *+                      +*                       
                                         -#+:                  :=#=                       
                                      .-+- .=**=.           -**=:                         
                                   :+*+-.=**=. :+#+:    :+**-                             
                               .=**=.       :+#+: .=****=.                                
                            -+*+:              .=**-                                      
                           +#.                     *#                                     
                           +*                      =#                                     
                           +*                      =#                                     
                           +*                      =#                                     
                           +*                      =#                                     
                           +*                      =#                                     
                           +*                      =#                                     
                           :+*+:                .=**-                                     
                              .=**=.         -+*+:                                        
                                  :+*+:  .=**-.                                           
                                     .=**+:                                               
    */

    /// @dev Counter for total minted honey token
    uint256 private _totalSupply;

    /// @dev Address of the cubs contract, for burning
    address private _cubsContract;

    /// @dev Marks when drop of honey is complete (and there will be no more)
    bool private _honeyFrozen;

    /// Let's the world know whether the base URI has changed
    event SetBaseURI(string indexed _baseURI);

    /// Let OpenSea know that the uri is now frozen
    event PermanentURI(string _value, uint256 indexed _id);

    /// Creates a new instance of the TwoBitHoney contract, with the address of the TwoBitBears contract and a baseURI for metadata
    constructor(address twoBitBears, string memory baseURI) Bearable(twoBitBears) ERC1155(baseURI) {
        _totalSupply = 0;
        _honeyFrozen = false;
    }

    /// Sets the address of the TwoBitCubs contract, which will have rights to burn honey tokens
    function setCubsContractAddress(address cubsContract) external onlyOwner {
        _cubsContract = cubsContract;
    }

    /// Performs the burn of a single honey token on behalf of the TwoBitCubs contract
    /// @dev Throws if the msg.sender is not the configured TwoBitCubs contract
    function burnHoneyForAddress(address burnTokenAddress) external {
        if (msg.sender != _cubsContract) revert InvalidBurner();
        _burn(burnTokenAddress, 0, 1);
    }

    /// Calculate the honey drop count for the specified owner
    /// @dev external read-only function to reduce gas cost of delivering the drop
    function calculateDrop(address owner) external view onlyOwner returns (uint256 bearsOwned, uint256 honeyCount) {
        uint256 browns; uint256 blacks; uint256 polars; uint256 pandas;
        bearsOwned = _twoBitBears.balanceOf(owner);
        for (uint256 index = 0; index < bearsOwned; index++) {
            uint256 tokenId = _twoBitBears.tokenOfOwnerByIndex(owner, index);
            BearSpeciesType species = bearSpecies(tokenId);
            if (species == IBearable.BearSpeciesType.Brown) {
                browns += 1;
            } else if (species == IBearable.BearSpeciesType.Black) {
                blacks += 1;
            } else if (species == IBearable.BearSpeciesType.Polar) {
                polars += 1;
            } else if (species == IBearable.BearSpeciesType.Panda) {
                pandas += 1;
            }
        }
        honeyCount = (browns >> 1) + (blacks >> 1) + (polars >> 1) + (pandas >> 1);
    }

    /// Performs the drop to TwoBitBear holders
    function dropHoney(address[] memory accounts, uint256[] memory amounts) public onlyOwner {
        if (accounts.length != amounts.length) revert MismatchedArraySizes();
        if (_honeyFrozen) revert HoneyDropFrozen();
        
        uint256 additionalSupply = 0;
        for (uint256 index = 0; index < accounts.length; index++) {
            uint256 amount = amounts[index];
            _mint(accounts[index], 0, amount, "");
            additionalSupply += amount;
        }
        _totalSupply += additionalSupply;
    }

    /// Freezes the metadata and any additional honey drops
    function freezeHoney() public onlyOwner {
        if (_honeyFrozen) revert HoneyDropFrozen();
        _honeyFrozen = true;
        emit PermanentURI(uri(0), 0);
    }

    /// Returns the owner of the TwoBitBear specified by the bearTokenId
    function ownerOfBear(uint256 bearTokenId) external view onlyOwner returns (address owner) {
        owner = _twoBitBears.ownerOf(bearTokenId);
    }

    /// @dev Total amount of tokens in with a given id.
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        if (id != 0) {
            return 0;
        }
        return _totalSupply;
    }

    /// @dev Indicates weither any token exist with a given id, or not.
    function exists(uint256 id) public view virtual returns (bool) {
        return totalSupply(id) > 0;
    }

    /// Updates the baseURI
    function updateBaseUri(string memory newuri) external onlyOwner {
        if (_honeyFrozen) revert HoneyDropFrozen();
        _setURI(newuri);
        emit SetBaseURI(newuri);
    }

    /// @dev Reverts with `InvalidHoneyTypeId()` if the `typeId` is > 0
    function uri(uint256 typeId) public view override returns (string memory) {
        if (typeId > 0) revert InvalidHoneyTypeId();

        return super.uri(typeId);
    }
}