// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
/*                                                                                       #&@@@@(
                                                                                    (@@@%((((((#@#
                                                                                 %@@%(((&((((((((@%
                                                                              &@&(##((((((((((((((&%      /&/
                                                                           &@&####(((((((((((((%#(%@/  /#&&@/
                                                                         @@%####((((((((((((((((##%@(/&&(%@%
                                                     //(//            #@@#####((((((((((((((((((((#@&((%%%@/
                                                  /%@@%(((@(       (@@&#%####((((((((((((((((((&@@%@##&#(&(
                                                 #@&###(((#@/   /%@@%&#%####((((((((((((((((@@#(#@@(%%((%%
                                               (@&#&###((((&&/#@@&%&%#%####(((((((((((((((%@#%###%%%###&@/
                                               %&#&%###(###%@@@@&&%&%#####((((((((((((((((@%#%###%%#%&@(
                           (%@@@@@@@@@@@@@%(   @%%%%##(((((#%@%%%&%&#%###((((((((((((((((&@##%##%##&@&//((((/
                        #@@@@@&%%@@@@@@@@@@@@@#@%&#%%#####((##&&%%@&&########(##((((((((#@&##%%%%@&#&@@&#(((@&
                      (@@@, .. (@@@@@@@#&@@%@@@@@&&%%%######(###@&%&%%&&#####(((((((((((%@%#%&@@%&@@#(((((((&@@@@@@@@@@@#/
                     #@@#........../@@@@@@@@&&@@@@%@%&%#######((((#@&@&################%&@&@@@%#((((((%%(%%@@%@@@@@@#%@@@@@#
                     %@,............. ,&@@@#@@@&@@@@%%%&%####(####(((((((#%&&&&&&&&&&%##((((((((((((##%&@@@@@@@@@@@%&@@@@@@%@(
                     %@,.................#@@@@@&@&(%@@&#%%%%#####(((((((((((((((((((((((((((((##&&@@@@@%@@@@@@@@@@#%@@@#,.../@@/
                     #@( ................*@@#/  ,%@@@#@@@&%%%%%%######(((((((((((((##%&@@@@@&##((&@@#&@@@@&%&@@@@@&/ ........%@#
                      %@&,............(@@&,.   #@#%@@@@@@@@@@@@@&%%%%%%%&@@@@@@@@@@@#  ../&@@@@@@@@@@&@@@%&@@%, .............#@&
                        %@@*........%@@%/,.   .*@@&@@@@@@@@@&#@@@@@(,..  ,/////&@@@#./@@@@&@@@@%@@@&&@%%#&../@@(.............%@(
                          %@@@(/.,(@@%////. ....*&@@@@@@@@@@@@@&@@&&%.....///,.....(@%%&@@@@@@@@@@@@@&&@@* .**(@@# ........,(@&
                              #%&@@#///////...*(///,(&@@@@@@@@@@@@@@(   ../,......,@&@@@%&@@@@@&@@@@&/....//////(&@(......,@@%
                               @@#///////@@@(       /(&@(,,#&@@@@&/.  . ,/,. ......&@@@@@@@@@@@@&%%&@@&&&%(///////(@@*..*@@%
                             &@#///////@%                ,&@,     ...,////,.. . ....*&&&&%%%@@%,    ....  ,%@@%/////#@@@%/
                          (@@(///////&@.    .#@@@@@@@@@//. .&@/////////////,,..  ......./@@(      ......  .   *@&/////@@#
                        &@%/////////@&    ,@@@@@&%%@@@@@@@/. %@%/////////////,,,,,,,***&@*     *@@@@%##@@@&,   .&@(/////@@
                     (@@#//////////#@(   /@@@@@@@@@@@%@@@@@*  #@#/////////(///////////@@*   [email protected]@@&%&@@@@@@@@@%   [email protected]@(/////%@&
                  (%@@(//////#/////@&.   (@@&%@&@@@@@@@@@&@*  ,@%//(/////%(((//(/////%@(    %@&@@&@@@@@@@@@@@,   (@#///////%@%
            %@@@@@@@%//////////////@@.   ,@@@@@%&@&@@@@@&@&.  ,@%//(#/%//%((((((((///%@(   [email protected]@(@&@@@@#&@@&&@@(   *@(////#////%@&
          (@@@@%@@@@@@@%(///////////&@*   .&@&@@@@@@@@@@&(    (@&#((((#((((((#(##(%//#@#    /&(@@@@@@@@@@@@@%    %@(///////////&@@(
          #@@@@@@&&@@@@@@%@@#////////#@%.     ,#@@@@@@&/    ,@&/&((((((((((((((((((/%(%@,    ,@%&%@@@@@@@@@*   [email protected]@#//////////////%@@%##(
          %@@@&@@@@@@@@@#&@@@@@@@#/////#@@&,             ,&@@(/&%####(((((((((((##((/&(#@#      ./#%&&#*     .%@@#///////////(%@@@@@&@@@@@(
          (@@@@&&@&@@@@@%%@@@@@@@@@@%//////(&@@&#%%##@@@@@%///#@#####(#(((((((#((#(((#@//@@@#.           ./&@@#//////(#%@@@@@@@@@@@@&@@%%@%
           #@@@@@@@@&@@@@#&@@%&@@@&(&@%/////////#######//////(@%#############(((((((((#&///#@@@@@@@@@@@@&#/////(@@@@@@@@@@@@@@@@@@@@@@@@@@(
       (%&@@&@&*(&@@@@&@@@@@@@@@&&@@&&@(/////////////////////@@&&&&&@@@@@@@@&&&&@@@@@&@@///////(%&%%%#///////@@&&&@@@@@@%@@@@@@@@@@@@@@@@
       (@@@&@@@@@@&#//(%&&@@@@@@@@@%//////////////(#((/,,,,,*,#@((((((((((((((((((//#@%/////////////////////&@@@@@@@&&@@@@@@@@&@@@@@@@@&#
        &@#%&@@@@@@@@@@%&@@@@@@&&&@&&%#(((/////&@@&#//(%@@#.....%@#(((((((((((((((@@/,,*,,,/////////////////(@@@&@@@@@&&@@@@@@@@@&&@#&&&@(
         &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/%@&%%#***,,,,/@@/...,%@@#((((((((#@@/ ..,(&@&(////#&@@(////////////#%&@@@&&&%#(/#%@@&@@@@@@&
           @@@&%@@@@@@@@@@@@@@%@@@@@@@@@&#&@%@&###%%#/,,,,,,*%@@/.   ,%@@&%&@%, . ./@@#,,,,,,*(%%#%@@///////////(#%&@@@@@@%@@@@@@@&@@@@
             #@@@@@@@@@@@@@@@@@@@@@@@@@@&#//&@####%#%%%#,,..,,,*%@@@&/.  &&.  ./%@@(,,,.,,,/#%%%%%%%@@//%@@@@&&%&@@@@@@@@@@@@@@@&@@@&
                (&@@@@@@@@@@@@@&&%#(////////&@######%%%%*,,,,#%(*,,,,/(%&@@@@@&%*,///.,.,,/%&%%%%%%#@@(#@@@@@@@@&%&&&@@@&@@@@&&@@@@&
                   %@&//////////////////////#@%####%%%%%&/,,#&&&&&&&&&&&%##%%%&&&&&&&%//,/%&&%%%%%%%@@///#@@@@&@@@@@&&@@@&@@@&#(&@&
                    #@@%(//////(//###%%%#////#@####%%%%%%%&&&&&&&&&&&&@@@@@@@&&&&&&&&&&&&&&&%%%%%%%%@#//////////(#%%%%%%///(#@@@#
                      #@@@@@@@@@@@@@@@@@@&////&@##%#%%%&&&&&&@@@@@@@@@@@@@@@&&&&&&&&&&&&&&&&%%%%%%&@(/////////(%%@@@@@@&#&@@@%
                         &@@@@@&&@@@@##@@(/////(@%#%%%&&&&&&%#((((((#%%###((((((((#&&&&&&&&&&%%%%@@///////////@&(&&@@@&@@@@@@#
                            @@@@@@@@&%///%*****,,%@&%%&&&%#((((((/((((((((((((((*,/(#&&&&&%%%%%@@/.,,////////////(&@@@@&(%%@
                                  @@#/////%***%**,,.(@@&&%(((((,,,,*((((((((((((*.,,*((%&%%%%@@(...,,///////////#&@@@&#(*%%
                                    ##%&&#/%******,.../&@%(**,,,.,.,//////////,......*(&@@%*....,,/////////(%@@@&@@@#&@
                                        #%%&@@&#////,,,...*%@@@#/...        ..,*(%@@@%/,......,,////(%@@@@&@(
                                                #%&@@@&%#/,,.....,*(##%&&&&&%%#/.........,,/(#&@@@&%%@%/%(#(
                                                      #&&&&%%&%%%%&#((////.,,,****((#%@@@&&%%&@&&@@@@&
                                                              #%&&@&&&%%%%&%%%&&@&&%#*/
contract TreasureTracker is ERC721Enumerable, Ownable {

    using Strings for uint256;

    enum SaleState { CLOSED, WHITELIST, ACTIVE }

    uint256 public constant MAX_SINGLE_MINT = 10;
    uint256 public constant MAX_TOTAL_SUPPLY = 10000;
    uint256 public constant MAX_AIRDROP_COUNT = 200;
    uint256 public constant PRICE_PER_TOKEN = 0.1 ether;

    SaleState private saleState = SaleState.CLOSED;

    string private trackingURI;
    string private trainingURI = "https://www.treasuretrackers.io/nft/";

    bytes32 private whitelistHash;
    mapping(address => uint) private whitelistClaimHash;

    uint256 private airdropCount;

    constructor() ERC721("TreasureTracker", "treasure") {}

    function joinGuild(uint numTokens) external payable {
        require(saleState == SaleState.ACTIVE, "Sale not currently active");
        require(numTokens <= MAX_SINGLE_MINT, "Can not purchase this many tokens");
        require(PRICE_PER_TOKEN * numTokens <= msg.value, "Incorrect Ether Value sent");

        uint256 currentSupply = totalSupply();
        require(currentSupply - airdropCount + numTokens <= MAX_TOTAL_SUPPLY - MAX_AIRDROP_COUNT, "Minting limit reached");

        for(uint256 i = 0; i<numTokens; ++i) {
            _safeMint(msg.sender, currentSupply + i);
        }
    }

    function whitelistJoinGuild(bytes32[] calldata proof, uint numTokens) external payable
    {
        require(saleState == SaleState.WHITELIST, "Whitelist not currently active");
        require(isOnWhitelist(msg.sender, proof), "Not on the Whitelist");
        require(numTokens <= MAX_SINGLE_MINT, "Can not purchase this many tokens");
        require(PRICE_PER_TOKEN * numTokens <= msg.value, "Incorrect Ether Value sent");
        require(whitelistClaimHash[msg.sender] + numTokens <= MAX_SINGLE_MINT, "Whitelist limit reached");

        uint256 currentSupply = totalSupply();
        require(currentSupply - airdropCount + numTokens <= MAX_TOTAL_SUPPLY - MAX_AIRDROP_COUNT, "Minting limit reached");

        for(uint256 i = 0; i<numTokens; ++i) {
            _safeMint(msg.sender, currentSupply + i);
        }

        whitelistClaimHash[msg.sender] += numTokens;
    }

    function airdrop(address winner, uint numTokens) external onlyOwner {
        require(airdropCount + numTokens <= MAX_AIRDROP_COUNT);
        require(numTokens <= MAX_SINGLE_MINT, "Can airdrop this many tokens");

        uint256 currentSupply = totalSupply();
        for(uint256 i = 0; i<numTokens; ++i) {
            _safeMint(winner, currentSupply + i);
        }

        airdropCount += numTokens;
    }

    function isOnWhitelist(address addressToCheck, bytes32[] calldata proof) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(addressToCheck));
        return MerkleProof.verify(proof, whitelistHash, leaf);
    }

    function sendTracking(string memory uri) external onlyOwner {
        require(!isTracking(), "Once set, the tracking URI can not change");

        trackingURI = uri;
    }

    function _baseURI() internal view virtual override returns (string memory){
        if(isTracking())
            return trackingURI;
        return trainingURI;
    }

    function isTracking() internal view returns (bool){
        return keccak256(abi.encodePacked(trackingURI)) != keccak256(abi.encodePacked(""));
    }

    function mintRemaining() external view returns(uint256){
        uint256 currentSupply = totalSupply();
        return (MAX_TOTAL_SUPPLY - currentSupply - MAX_AIRDROP_COUNT);
    }

    function getSaleState() external view returns (SaleState){
        return saleState;
    }
    function setSaleStateClosed() external onlyOwner {
        saleState = SaleState.CLOSED;
    }
    function setSaleStateWhitelist(bytes32 hash) external onlyOwner {
        saleState = SaleState.WHITELIST;
        whitelistHash = hash;
    }
    function setSaleStateActive() external onlyOwner {
        saleState = SaleState.ACTIVE;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    
}