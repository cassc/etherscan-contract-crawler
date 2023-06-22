// SPDX-License-Identifier: MIT

    //                                 ██▓▓████████████████████                                        
    //                           ██████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░▒▒██████                                  
    //                         ██░░▒▒▒▒▒▒▒▒▒▒░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒████                              
    //                       ██░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░▒▒▒▒▒▒▒▒████                          
    //                     ██░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒████                      
    //                   ██░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░▒▒▒▒▒▒██                    
    //                 ██░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██                  
    //                 ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░██                
    //             ████▒▒████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░██                
    //           ██▒▒░░▒▒▒▒▒▒██████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░██              
    //         ▓▓░░░░░░░░▒▒▒▒▒▒▒▒▒▒████▓▓██▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██              
    //         ████▒▒▒▒▒▒░░░░▒▒▒▒░░▒▒▒▒▒▒▒▒▒▒██████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██              
    //             ██▒▒░░░░▒▒▒▒▒▒░░░░▒▒▒▒▒▒▒▒▒▒░░▒▒▒▒▒▒████████░░░░░░░░░░░░░░░░░░░░░░░░██              
    //           ▓▓▒▒░░░░░░▒▒▒▒░░░░░░▒▒▒▒░░░░░░░░▒▒▒▒░░▒▒▒▒▒▒▒▒██▓▓██▓▓░░░░░░░░░░░░░░░░██▒▒▓▓▓▓        
    //           ██▒▒░░▒▒▒▒▒▒░░░░▒▒▒▒▒▒▒▒░░░░░░▒▒▒▒▒▒░░░░░░▒▒▒▒▒▒░░▒▒▒▒████░░░░░░░░░░██░░░░░░░░██      
    //             ████████████████▒▒▒▒██████▒▒▒▒▒▒▒▒░░░░░░▒▒▒▒▒▒░░░░▒▒▒▒▒▒██████████▒▒▒▒▒▒░░░░██      
    //               ████▒▒▓▓▓▓▓▓▓▓████▓▓▓▓██▒▒▒▒▒▒▒▒████████▒▒▒▒░░░░██▒▒▒▒▒▒░░░░▒▒▒▒░░░░▒▒▒▒██        
    //             ██▒▒██▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓████████▓▓▓▓▓▓▓▓██▒▒░░██▓▓██▒▒▒▒░░░░▒▒▒▒▒▒░░░░██          
    //           ██▒▒▒▒▒▒████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓██▒▒██▒▒▒▒▓▓▓▓████▓▓▓▓██▒▒▒▒░░░░████▒▒░░░░░░██        
    //           ██▒▒▒▒▒▒▒▒▒▒██▓▓▓▓██▒▒▒▒▒▒▒▒████▒▒▒▒▒▒▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓██▒▒░░▓▓▒▒▒▒████▒▒▓▓██        
    //         ██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒████████▒▒▒▒▒▒▒▒▒▒▒▒██████████▒▒▒▒▒▒▒▒████▒▒▒▒▒▒▒▒▒▒██▒▒▒▒██      
    //     ██████▒▒▒▒██████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒████  
    //   ██▒▒▒▒▒▒████▒▒▒▒▒▒██▒▒▒▒▒▒▒▒▒▒██████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██
    // ██▒▒▒▒▒▒▒▒▓▓▒▒▒▒▒▒▒▒▒▒██▒▒▒▒████▓▓▓▓▓▓████▒▒▒▒▒▒██████▓▓▓▓██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██████▓▓▒▒▒▒▒▒▒▒██
    // ████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒████▓▓▓▓▓▓▒▒▓▓▓▓▓▓██████▓▓▓▓▓▓▒▒▒▒▓▓██▒▒▒▒▒▒▒▒▒▒██████▓▓▓▓██  ██████▒▒██
    //     ████▓▓██▒▒▒▒▒▒▒▒▒▒████▓▓▓▓▓▓▓▓▒▒▓▓▓▓▓▓▓▓▓▓▓▓▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓████████▓▓▓▓▓▓████░░██      ██  
    //           ██▒▒▒▒▒▒████░░░░████████▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▓▓▓▓▓▓▓▓▒▒▓▓████░░░░██          
    //           ████████▓▓██░░░░░░░░░░░░████████████████████████▓▓▓▓██████▓▓▓▓▓▓██░░██░░░░██          
    //               ██▓▓▓▓▓▓██░░░░░░░░░░░░░░░░░░░░░░░░██▓▓▓▓▓▓▓▓████▓▓▓▓▓▓██████░░░░██░░░░██          
    //               ██▓▓▒▒▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██░░░░▒▒▒▒██░░██          
    //                 ████████████░░░░░░░░░░░░████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████████░░░░▒▒▒▒▒▒████            
    //               ██▒▒▒▒▒▒░░░░░░██░░░░░░████░░░░██████████████████░░░░██░░░░▒▒▒▒▒▒▒▒██              
    //               ██▒▒▒▒▒▒▒▒▒▒░░▒▒▓▓░░██░░░░░░░░░░░░░░████░░░░░░░░░░▓▓░░▒▒▒▒▒▒▒▒▒▒██                
    //               ██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██▓▓░░░░██▒▒▒▒▒▒▒▒▒▒▒▒▒▒██                
    //                 ██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒████▒▒▒▒▒▒▒▒▒▒▒▒▒▒██                  
    //                 ░░▓▓██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓██░░                  
    //                       ████▓▓██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██████▓▓                        
    //                               ██████████████████████████████████                  

// NhhdNNNNNNNNNNNNNNNMNhhNMMMMMMMMmhhhhdMMMMMMMMMddMMMMMMMMMMMMMMMMMMMMNdhhhhhdMmdddddddddddddddddNNhN
// moyo/:::::::::::::::+doy::::::::m....h+-------/dm:-------------------:oy/..ss:-.................-+hN
// Mo..................-moo........N....h:.......:dm-.....................-d-/h....................../M
// M...................-moo........N....h:.......:dd-......................y++s......................-M
// N.........----------:dos........m....h/.......:dd-.......-:::::-........yo+s........:+++++-.......-M
// N......../y+++++++++o/os........m....h/.......:dd-......./h++++h........so+s........d/:::h/.......-M
// N........oo...........os........m....h/.......:dd-......./h....m........so+y........d-...y/.......-M
// M........+h:::::::-...os........m....h/.......-dd-......./h....m........so+y........d-...y+.......-M
// M........-///////+os/.os........m....h/.......-dd-......./h....m........so+y........d-...y+.......-M
// M..................-y+os........m....h/.......-dd-......./h....m........so+y........d-...y+.......-M
// M/..................:dos........m....h/.......-dd:......./h....m........so+y........d-...y+.......-M
// Ny/--------..........mos........m....h/.......-dd:......./h....m........so+y........d-...y+.......-M
// m-+ooooooooy-........moy........m-...h/.......-dd:......./h....m........so+y........d-...y+.......-M
// m..........h+........Noy........d:...h+.......-md:.......:h....N........oo+y........d-...y+........M
// m----------h+........N+y........d/---h/.......-Nd:.......:h---:m........oo+y........h:---y+........M
// Msoooooooooo-........N/y........:oooo+-.......-Nd:.......-oooo+:........oo+h......../ooooo-........M
// M-...................N/y......................-Nd:......................oo+h.......................M
// M-..................:d:d......................:dd:.........SUDOSIX2k22..oo+h......................-M
// M-................./h/.ss-..................-/h:d:....................:ss..ss-...................:hN
// Nsoooooooooooooooos+-...:osooooooooosoooooooo+-.+soooosssssssssssssosso:----/ssooooossssssssssssso:m
// Nsssssssssssssss+hsssssh:./hsssssdsssssssssooooos+-ossssssssssssssoysooooooooooooomhooooooooooooossm
// N.............-:dh.....y+.oo.....d-.............-ydo-............-sM-.............do............../M
// N...............sh.....y+.os.....d-..............+M:......--......+M:.....--------do.....----......M
// N.....wagmb.....sh.....y+.os.....d-....:wsup.....+M:....-2018...../M:....-d+++++++ho.....ho+h:.....M
// N.....+y:+d.....sh.....y+.os.....d-....:d..m...../M:....-m..d/////oM:....-m/////..so.....m-.y/.....M
// N.....:o++/.....hh.....y+.os.....d:....-hooy.....+M:....-m:/+oossssm:....-/////h/.so.....ysss-....-M
// N............-/yhh.....y+.os.....d:.....---...--/hm:....-mm///::::oM:..........y+.so............-/yN
// N.....-----..-:+dh.....y+.os.....d:...........-:shd:....-mm::...../M:.....:::::y/.ss............:/yN
// M...../y+oy.....sh.....s+.os.....d:....-ayyy.....+M:....-m/+m-..../M:....-m++++/-.ss.....ssoy:....-M
// M...../h/+h.....oh.....ss/ss.....h:....-m..m-..../M/....-d++m-..../M:....-m+++++++hs.....d-.y+.....N
// M.....-///:.....od.....-///-.....h:....-m..m-..../M/.....-::-...../M:.....-:------hs.....d-.y+.....N
// M...............ym-.............-m:....-m..m-..../Mo..............+M/.............hs.....d/.y+.....N
///////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

abstract contract sudoburgerGrill {
    function grillIngredients(address to, uint256[] memory id) public virtual returns(uint256);
}
abstract contract ERC721 {
    function ownerOf(uint256 tokenId) public view virtual returns (address);
}
contract INGREDIENTS is ERC1155, Ownable, ERC1155Burnable {
    using SafeMath for uint256;
    string cURI = "https://us-central1-sudoburger-9b96e.cloudfunctions.net/app/api/ing/";
    uint256 tokenId = 0;
    uint256 dumpsterMax = 2018;
    uint256 private tokenPrice = 25000000000000000; // 0.025 ETH

    string name_ = "SUDOBURGER: INGREDIENTS";
    string symbol_ = "ING";

    address sudoburgerAddress;

    mapping (address => mapping (uint256 => bool)) usedToken;
    mapping (address => uint256) sudoContracts;
                                
    bool marketOpen = false;
    bool kitchenOpen = false;
    
    constructor() ERC1155("") {
        sudoContracts[0xeF2e3Cf741d34732227De1dAe38cdD86939fE073] = 721; // SUDOBURGER: FRYCOOKS
        sudoContracts[0x5394603d355482C126f7CF3603e419B67b31b76E] = 1155; // SUDOPASS
    }
 
    event ingMinted(uint256[] newIds, uint8[] mintType, uint256[] tokenId);

    // Returns contract name
    function name() external view returns(string memory) {
        return name_;
    }
    // Returns contract symbol
    function symbol() external view returns(string memory) {
        return symbol_;
    }

    // COOK REDEMPTION function
    function cookRedeem(address[] calldata contractIds, uint256[] calldata cookIds) public returns(uint256) {
        require(marketOpen == true, "Market aint open rn.");
        require(contractIds.length > 0, "Requires contract address.");
        require(cookIds.length == contractIds.length, "cookIds must match contractIds length.");
        uint256[] memory newIds = new uint256[](cookIds.length.mul(2));
        uint8[] memory mintType = new uint8[](cookIds.length);
        for(uint256 i = 0; i < contractIds.length; i++) {
            // Verify token ownership and if already redeemed
            if(sudoContracts[contractIds[i]] == 721) {
                // If token is ERC-721
                ERC721 contractAddress = ERC721(contractIds[i]);
                require(contractAddress.ownerOf(cookIds[i]) == msg.sender, "Doesn't own the COOK.");
                mintType[i] = 1;
            } else if(sudoContracts[contractIds[i]] == 1155) {
                // If token is ERC-1155
                ERC1155 contractAddress = ERC1155(contractIds[i]);
                require(contractAddress.balanceOf(msg.sender, cookIds[i]) > 0, "Doesn't own the PASS.");
                mintType[i] = 2;
            } else {
                revert("Token is  non-redeemable"); 
            }
            require(checkIfRedeemed(contractIds[i], cookIds[i]) == false, "Token already redeemed.");
            usedToken[contractIds[i]][cookIds[i]] = true;
        }
        uint256 prevTokenId = tokenId;
        uint256 toMint = cookIds.length.mul(2);
        
        for (uint256 i = 0; i < toMint ; i++) {
            tokenId++;
            _mint(msg.sender, tokenId, 1, "");
            newIds[i] = tokenId;
        }
        emit ingMinted(newIds, mintType, cookIds);
        return prevTokenId;
    }

    // No FRYCOOK? no problem! mint DUMPSTER INGREDIENTS with yr ETH -sd6
    function dumpsterDive(uint256 trashAmmt) public payable {
        require(trashAmmt <= 20, "Only 20 can be minted at a time");
        require(marketOpen == true, "Market aint open rn");
        require(tokenId + trashAmmt <= dumpsterMax, "Insufficient supply OR Dumpster is empty");
        require(msg.value >= tokenPrice.mul(trashAmmt), "Not enough eth");
        uint256[] memory newIds = new uint256[](trashAmmt);
        uint8[] memory mintType = new uint8[](1);
        uint256[] memory ids = new uint256[](1);
        // uint256 prevTokenId = tokenId;
        for(uint256 i = 0; i < trashAmmt; i++) {
            tokenId++;
            _mint(msg.sender, tokenId, 1, "dumpster");
            newIds[i] = tokenId;
        }
        mintType[0] = 3;
        emit ingMinted(newIds, mintType, ids);
    }

    // OwnerBalance - 721 style -sd6
    function ownerBalance(address _owner) public view returns(uint256){
        uint256 i;
        uint256 result = 0;
        for (i = 0; i < tokenId + 1 ; i++) {
            if (balanceOf(_owner, i) == 1) {
                result++;
            }
        }
        return result;
    }

    // Returns all SUDOBURGER INGREDIENT tokens of owner address -sd6
    function tokensOfOwner(address _owner) external view returns(uint256[] memory) {
        uint256 i;
        uint256 d = 0;
        uint256[] memory result = new uint256[](ownerBalance(_owner));
        for (i = 0; i <= tokenId ; i++) {
            if (balanceOf(_owner, i) == 1) {
                result[d] = i;
                d++;
            }
        }
        return result;
    }

    // Cook your SUDOBURGER INGREDIENTS into a custom SUDOBURGER! 
    function grillBurger(uint256[] calldata id) public returns(uint256){
        require(kitchenOpen == true, "The kitchen aint open rn.");
        require(id.length >= 3, "Minimum 3 ingredients.");
        require(id.length <= 32, "Maximum 32 ingredients.");
        require(balanceOf(msg.sender, id[0]) > 0, "Doesn't own the ingredient."); // Check if the user own one of the ERC-1155
        uint256 i;
        uint256[] memory ones = new uint256[](id.length);
        for (i = 0; i < id.length; i++) {ones[i] = 1;}
        burnBatch(msg.sender, id, ones); // Burn one the ERC-1155 token
        sudoburgerGrill sudoburgerContract = sudoburgerGrill(sudoburgerAddress);
        uint256 burgerId = sudoburgerContract.grillIngredients(msg.sender, id); // Mint your SUDOBURGER
        return burgerId;
    }
    
    // Check if token has been redeemed for an INGREDIENT -sd6
    function checkIfRedeemed(address _contractAddress, uint256 _tokenId) view public returns(bool) {
        return usedToken[_contractAddress][_tokenId];
    }
    function getPrice() view public returns(uint256) { 
        return tokenPrice;
    }
    function getMarket() view public returns(bool) { 
        return marketOpen;
    }
    function getKitchen() view public returns(bool) { 
        return kitchenOpen;
    }
    // Get amount of 1155 minted -sd6
    function totalSupply() view public returns(uint256) {
        return tokenId;
    }
    
    // Set dynamic URI root // will be changed to IPFS hash once all ingredients are minted -sd6
    function setcURI(string memory newuri) public onlyOwner {
        cURI = newuri;
    }
    // Dynamic uri return -sd6
    function uri(uint256 id) override public view returns (string memory) {
        string memory val = INGREDIENTS.cURI;
        return string(abi.encodePacked(val,Strings.toString(id)));
    }

    //ONLYOWNER FUNCTIONS

    // Specify contract address for SUDOBURGER: SUDOBURGERS
    function setSudoburgerAddr(address contractAddress) public onlyOwner {
        sudoburgerAddress = contractAddress;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        tokenPrice = newPrice;
    }

    // Toggle INGREDIENT minting -sd6
    function toggleMarket() public onlyOwner {
        marketOpen = !marketOpen;
    }

    // Toggle SUDOBURGER minting -sd6
    function toggleKitchen() public onlyOwner {
        kitchenOpen = !kitchenOpen;
    }
    
    // Transfer ETH out of contract -sd6
    function emptyRegister() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}
}