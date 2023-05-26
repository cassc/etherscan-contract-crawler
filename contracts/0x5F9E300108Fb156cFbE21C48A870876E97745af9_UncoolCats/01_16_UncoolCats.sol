// SPDX-License-Identifier: MIT
/*
* ##  ###  ###  ##   ## ##    ## ##    ## ##   ####               ## ##     ##     #### ##   ## ##   
* ##   ##    ## ##  ##   ##  ##   ##  ##   ##   ##               ##   ##     ##    # ## ##  ##   ##  
* ##   ##   # ## #  ##       ##   ##  ##   ##   ##               ##        ## ##     ##     ####     
* ##   ##   ## ##   ##       ##   ##  ##   ##   ##               ##        ##  ##    ##      #####   
* ##   ##   ##  ##  ##       ##   ##  ##   ##   ##               ##        ## ###    ##         ###  
* ##   ##   ##  ##  ##   ##  ##   ##  ##   ##   ##  ##           ##   ##   ##  ##    ##     ##   ##  
*  ## ##   ###  ##   ## ##    ## ##    ## ##   ### ###            ## ##   ###  ##   ####     ## ##   
*                                                                                                    
*                                    :=*%%%*:                                               
*                                  :#%%%%%%%%:                                              
*                                  *%%%%%%#%%#                                              
*                                   *%%%-==%%%                                              
*                         .::.       *%%+=-%%%.                .-=+*+=-.                    
*                     =*%%%%%%%#*=. :+%%%=-%%%+             :+#%%%#*#%%%*-                  
*                    #%%#=:::-+*%%%#%%%+:::-*%%%+:         +%%%*-.....:*%%%-                
*                  .#%%-........:+%%%*:--::=-:=#%%%+-     +%%*:.........=%%%*               
*                 .%%#:..........:%%+:::::::==::=+#%%-  :#%%-............-#%%#:             
*                 #%%=...........+%#:::::::::%-:::-%%+ :%%%=...............*%%%.            
*                -%%%:...........%%=:::::::::++::::%%%%%%%#................:#%%=            
*                #%%%...........:%%-:::-+::::-%-:::#%%%%%#:.................:#%%            
*               .%%%+...........:%%=:::-%-::::-+:::::*%%%:...................:%%*           
*               .%%%=........-=*#%%-:::=%#=::::=-::::%%%=.....................+%%:          
*               -%%%-...:-+*%%%%%*=::::=%%#+:::::::::%%%+=:...................:%%*          
*               -%%%-.=#%%#*+=-:::::::-#%%%%#+-::::-:-+*#%%%*+=-:..............#%%.         
*                *#*::%%%---::::::::=#%%##%%%%%+:::::::--::=*%%%%*-............-+=          
*                 ...:%%%:-::::::-+%%%%+:.-+#%%%#*+-::::-:=+-:-+#%%:.............           
*               .-=-.:%%%:::-=+*#%#+=:..=#=.=+++**#%%%#**++==++=:*%+............-#%*.       
*              :%%%#.:%%%:-*%%%#+-......*=%::*%*:...:=+**#%%%*==##%%............:%%%*       
*             .%%%#:.:%%%*%%#=:........:*+#...*#-.........:+%%%#+#%#.............+%%%       
*             +%%+...:%%%%*-............:-...................-+#%%%=.............-%%%:      
*             %%#.....:-:.......................................=#*..............:%%%-      
*            -%%-.....=***=...........................-*%%%*:.....................%%%-      
*      .###**#%%:....*%#+#%*.........................+%%+-=%%=........:-======-..:%%%-      
*       -==++#%%:...-%%.  %%-........................#%=   =%%-......:%%%%%%%#+..-%%%:      
*            -%%-...=%%   +%+........................%%-   =%%=.......::::.......+%%%       
*       =**##%%%#:..-%%.  #%=........................*%*.  +%%:.......=***+===:.-%%%+       
*       +*+=--+%%*...*%%+#%#.........................-%%%**%%-........:++*#%%%%:%%%#        
*             :%%%+..:*%%%#-..........................:+*%%+:...............::.=%%%.        
*              =%%%+....::....................................................:%%%:         
*               :#%%#-...............::::::::...............................-+%%+.          
*                 =%%%=........:=+#%%%%%%%%%%%%*+-........................-*%%%=            
*                  .*%%#=......=%%#**+++++++++*%%%%-....................-#%%%#:             
*                    :*%%%*-....::..............=**-................:=+#%%*=.               
*                      .=#%%%*-:................................:-+%%%%%+                   
*                         :*%%%%#+-.......................::=+*#%%%%#+:                     
*                           .:=+#%%%#****+++++++++****###%%%%##*+=:                         
*                                 :=+**#%%%%%%%%%%%##**+=--.                                
* 
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract UncoolCats is ERC721, ERC721Enumerable, Ownable {
    bool public publicMintActive = false;
    string private _baseURIextended;

    mapping(address => uint8) private _whiteList;
    bool public isWhitelistActive = false;

    // Supply and pricing params
    uint256 public constant MAX_SUPPLY = 6969;
    uint8 public constant MAX_PUBLIC_MINT = 5;
    uint8 public constant MAX_WHITELIST_MINT = 2;
    uint256 private _mintPrice = 0.042 ether;

    // team withdraw address
    address teamAddress = 0x7E21b9ADE9F0D9b1Def313995f25c8Bd0DC9119e;

    constructor( string memory _initBaseURI) ERC721("Uncool Cats", "UNCOOL") {
        setBaseURI(_initBaseURI);
        // preallocate 30 cats for team and later giveaway
        for (uint256 i = 1; i <= 30; i++) {
            _mint( teamAddress, i);
        }
    }

    function setWhitelistActive(bool _isWhitelistActive) external onlyOwner {
        isWhitelistActive = _isWhitelistActive;
    }

    /**
     * @notice Setup the whitelist
     * @param addresses array of whitelisted addresses
     * @dev whitelist count should not exceed 2000, max whitelist mint per wallet dictated by MAX_WHITELIST_MINT
     */
    function setWhitelist(address[] calldata addresses) external onlyOwner {
        require(addresses.length <= 2000);
        for (uint256 i = 0; i < addresses.length; i++) {
            _whiteList[addresses[i]] = MAX_WHITELIST_MINT;
        }
    }

    function numAvailableToMint(address addr) external view returns (uint8) {
        return _whiteList[addr];
    }

    /**
     * @notice Mint a new uncoolcat (whitelist)
     * @param numberOfTokens number of uncoolcats to mint
     * @dev mint limit is determined via MAX_WHITELIST_MINT
     */
    function mintWhitelist(uint8 numberOfTokens) external payable {
        uint256 ts = totalSupply();
        require(isWhitelistActive, "Whitelist inactive");
        require(numberOfTokens <= _whiteList[msg.sender], "exceeds max tokens");
        require(ts + numberOfTokens <= MAX_SUPPLY, "exceeds supply");
        require(_mintPrice * numberOfTokens <= msg.value, "wrong value");

        _whiteList[msg.sender] -= numberOfTokens;
        // i = 1 because tokenId starts at 1
        for (uint8 i = 1; i <= numberOfTokens; i++) {
            _mint(msg.sender, ts + i);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) public onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    /**
     * @notice Start/Stop public mint
     * @param newState set to true to start public mint
     */
    function setPublicMintActive(bool newState) public onlyOwner {
        publicMintActive = newState;
    }

    /**
     * @notice Mint a new uncoolcat (public)
     * @param numberOfTokens number of uncoolcats to mint
     */
    function mint(uint8 numberOfTokens) public payable {
        uint256 ts = totalSupply();
        require(publicMintActive, "mint not active");
        require(numberOfTokens <= MAX_PUBLIC_MINT, "exceed max tokens");
        require(ts + numberOfTokens <= MAX_SUPPLY, "exceeds supply");
        require(_mintPrice * numberOfTokens <= msg.value, "wrong value");

        // i = 1 because tokenId starts at 1
        for (uint8 i = 1; i <= numberOfTokens; i++) {
            _mint(msg.sender, ts + i); 
        }
    }

    /**
     * @notice Manually override mint price if ETH experiences extreme volatility
     * @param newPrice new mint price
     */
    function setMintPrice(uint256 newPrice) external onlyOwner {
        _mintPrice = newPrice;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

}