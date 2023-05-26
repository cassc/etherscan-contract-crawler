// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// ███╗   ██╗███████╗██████╗ ██╗   ██╗ ██████╗ ██╗   ██╗███████╗                 
// ████╗  ██║██╔════╝██╔══██╗██║   ██║██╔═══██╗██║   ██║██╔════╝                 
// ██╔██╗ ██║█████╗  ██████╔╝██║   ██║██║   ██║██║   ██║███████╗                 
// ██║╚██╗██║██╔══╝  ██╔══██╗╚██╗ ██╔╝██║   ██║██║   ██║╚════██║                 
// ██║ ╚████║███████╗██║  ██║ ╚████╔╝ ╚██████╔╝╚██████╔╝███████║                 
// ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝  ╚═══╝   ╚═════╝  ╚═════╝ ╚══════╝                 
// work with us: nervous.net // [email protected] // [email protected]                                                                            
// ██╗  ██╗                                                                      
// ╚██╗██╔╝                                                                      
//  ╚███╔╝                                                                       
//  ██╔██╗                                                                       
// ██╔╝ ██╗                                                                      
// ╚═╝  ╚═╝                                                                      
//                                                                               
//__/\\\______________/\\\__/\\\________/\\\____/\\\\\\\\\______/\\\\\\\\\\\\\_______/\\\\\\\\\\\___        
// _\/\\\_____________\/\\\_\/\\\_______\/\\\__/\\\///////\\\___\/\\\/////////\\\___/\\\/////////\\\_       
//  _\/\\\_____________\/\\\_\//\\\______/\\\__\/\\\_____\/\\\___\/\\\_______\/\\\__\//\\\______\///__      
//   _\//\\\____/\\\____/\\\___\//\\\____/\\\___\/\\\\\\\\\\\/____\/\\\\\\\\\\\\\/____\////\\\_________     
//    __\//\\\__/\\\\\__/\\\_____\//\\\__/\\\____\/\\\//////\\\____\/\\\/////////_________\////\\\______    
//     ___\//\\\/\\\/\\\/\\\_______\//\\\/\\\_____\/\\\____\//\\\___\/\\\_____________________\////\\\___   
//      ____\//\\\\\\//\\\\\_________\//\\\\\______\/\\\_____\//\\\__\/\\\______________/\\\______\//\\\__  
//       _____\//\\\__\//\\\___________\//\\\_______\/\\\______\//\\\_\/\\\_____________\///\\\\\\\\\\\/___ 
//        ______\///____\///_____________\///________\///________\///__\///________________\///////////_____
//          __                  __      __                           ____                                __     
//         /\ \                /\ \  __/\ \                         /\  _`\                             /\ \    
//         \ \ \____  __  __   \ \ \/\ \ \ \     __     _ __   _____\ \,\L\_\    ___   __  __    ___    \_\ \   
//          \ \ '__`\/\ \/\ \   \ \ \ \ \ \ \  /'__`\  /\`'__\/\ '__`\/_\__ \   / __`\/\ \/\ \ /' _ `\  /'_` \  
//           \ \ \L\ \ \ \_\ \   \ \ \_/ \_\ \/\ \L\.\_\ \ \/ \ \ \L\ \/\ \L\ \/\ \L\ \ \ \_\ \/\ \/\ \/\ \L\ \ 
//            \ \_,__/\/`____ \   \ `\___x___/\ \__/.\_\\ \_\  \ \ ,__/\ `\____\ \____/\ \____/\ \_\ \_\ \___,_\
//             \/___/  `/___/> \   '\/__//__/  \/__/\/_/ \/_/   \ \ \/  \/_____/\/___/  \/___/  \/_/\/_/\/__,_ /
//                        /\___/                                 \ \_\                                          
//                        \/__/                                   \/_/                                                                                                                  
//
//
//
// -----------------------------------------------------------------------------
//
//
//
// This is Nervous NFT V3. Gas Friendly, Feature Rich, ERC721 future compatible.
//
//                                                 .|\        .-:.
//                                                / / '._____/ /  '.     :          .
//                    .   .              ________/ /    '.__/ /     '.  :         .:'
//                 .-'-.  |  -----/_/_/_/        /'-.     ',='--.     ':        .:'
//        _ .----""""""-^-^--' ()  __     =     /    '-._   '.==='-.  :====.__.:'
//      .'_/  = _ = .-. =  /""/   /_/   /""/   /"'---._  '--u_:.===="|  __:  :'\
//    .'.'/    / / /  /   /__/       = /__/   /_/'.-.' '.  .  . -.-.:|<:::::'   \
//   ..' /     ""  '"'=        //  =         /  """----'  .  (. ' ./#|######'\   \
//  ..--/   =     =        =     =    =     /            .  __ ' /##.'#######\\   \
//  || (-----N-E-R-V-O-U-S---v3------------(--------.___._ (    ;###|#########)---->-"""" ascii art by mga
//  ''  \  _--.-..   __    =          =     \    __    ___'"""-(---"\########//   /
//   ''.-\ \ \ \  \  '\'   .-------._____.   '         \  "\\"" \\###\######//   /
//    '.'.\ \ \ \  \  '\'  \ \   \   \   \\   '   .-    ""''  "" \\.-.\---='/   /
//      '._\ \ \ \  \  '\'  \ \   \   \   \\ = '         \""'-\".-7-. "\"" /-._/
//          '-^-\_\__\  '\'  \ \   \   \   \\   '   .' .---"""""(__  "-_\__---""--.
//                    """"""""--^---^___\___\\   :._____------""""""""  "-_        "
//                                           """""
//
// Thanks to Galactic and 0x420 for their gas friendly ERC721S implementation.
//
//
//
// -----------------------------------------------------------------------------
//

import "./ERC721S.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract NervousNFT is
    ERC721Sequential,
    ReentrancyGuard,
    PaymentSplitter,
    Ownable
{
    using Strings for uint256;
    using ECDSA for bytes32;
    mapping(bytes => uint256) private usedTickets;

    uint256 public immutable maxSupply;

    uint256 public constant MINT_PRICE = 0.08 ether;
    uint256 public constant MAX_MINTS = 9;

    string public baseURI;

    bool public mintingEnabled = true;

    uint256 public startPresaleDate = 1642438800; // January 17, 9 am PST

    uint256 public startPresaleAct2Date = 1642449600; // January 17, 12 pm PST
    uint256 public startPresaleAct3Date = 1642460400; // January 17, 3 pm PST
    uint256 public startPresaleAct4Date = 1642482000; // January 17, 9 pm PST

    uint256 public endPresaleDate = 1642525199; // January 18, 8:59:59 am PST

    uint256 public startPublicMintDate = 1642525200; // January 18, 9 am PST

    uint256 public constant MAX_ACT1_PRESALE_MINTS = 3;
    uint256 public constant MAX_ACT2_PRESALE_MINTS = 2;
    uint256 public constant MAX_ACT3_PRESALE_MINTS = 1;
    uint256 public constant MAX_ACT4_PRESALE_MINTS = 1;

    address public act1PresaleSigner;
    address public act2PresaleSigner;
    address public act3PresaleSigner;
    address public act4PresaleSigner;

    string public constant R =
        "We are Nervous. Are you? Let us help you with your next NFT Project -> [email protected]";

    constructor(
        string memory name,
        string memory symbol,
        string memory _initBaseURI,
        uint256 _maxSupply,
        address _act1PresaleSigner,
        address _act2PresaleSigner,
        address _act3PresaleSigner,
        address _act4PresaleSigner,
        address[] memory payees,
        uint256[] memory shares
    ) ERC721Sequential(name, symbol) PaymentSplitter(payees, shares) {
        baseURI = _initBaseURI;
        maxSupply = _maxSupply;
        act1PresaleSigner = _act1PresaleSigner;
        act2PresaleSigner = _act2PresaleSigner;
        act3PresaleSigner = _act3PresaleSigner;
        act4PresaleSigner = _act4PresaleSigner;
    }

    /* Minting */

    function toggleMinting() public onlyOwner {
        mintingEnabled = !mintingEnabled;
    }

    function mint(uint256 numTokens, bytes memory pass)
        public
        payable
        nonReentrant
    {
        require(mintingEnabled, "Minting isn't enabled");
        require(totalMinted() + numTokens <= maxSupply, "Sold Out");
        require(
            numTokens > 0 && numTokens <= MAX_MINTS,
            "Machine can dispense a minimum of 1, maximum of 9 tokens"
        );
        require(
            msg.value >= numTokens * MINT_PRICE,
            "Insufficient Payment: Amount of Ether sent is not correct."
        );

        if (hasPreSaleStarted()) {
            uint256 presaleActForTicket = firstEligibleActForTicket(pass);
            require(
                presaleActForTicket <= currentPresaleAct(),
                "Invalid ticket for current presale act"
            );
            uint256 mintablePresale = calculateMintablePresale(
                presaleActForTicket,
                pass
            );
            require(numTokens <= mintablePresale, "Minting Too Many Presale");
            useTicket(pass, numTokens);
        } else {
            require(hasPublicSaleStarted(), "Sale hasn't started");
        }

        for (uint256 i = 0; i < numTokens; i++) {
            _safeMint(msg.sender);
        }
    }

    function calculateMintablePresale(
        uint256 _presaleActForTicket,
        bytes memory _pass
    ) internal view returns (uint256) {
        uint256 maxMintForPresale;
        if (_presaleActForTicket == 1) {
            maxMintForPresale = MAX_ACT1_PRESALE_MINTS;
        } else if (_presaleActForTicket == 2) {
            maxMintForPresale = MAX_ACT2_PRESALE_MINTS;
        } else if (_presaleActForTicket == 3) {
            maxMintForPresale = MAX_ACT3_PRESALE_MINTS;
        } else if (_presaleActForTicket == 4) {
            maxMintForPresale = MAX_ACT4_PRESALE_MINTS;
        } else {
            revert("Invalid Presale Act");
        }
        require(usedTickets[_pass] < maxMintForPresale, "Ticket already used");
        return maxMintForPresale - usedTickets[_pass];
    }

    /* Ticket Handling */

    // Thanks for 0x420 and their solid implementation of tickets in the OG:DG drop.

    function getHash() internal view returns (bytes32) {
        return keccak256(abi.encodePacked("NERVOUS", msg.sender));
    }

    function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        return hash.toEthSignedMessageHash().recover(signature);
    }

    function firstEligibleActForTicket(bytes memory pass)
        internal
        view
        returns (uint256)
    {
        bytes32 hash = getHash();
        address signer = recover(hash, pass);

        if (signer == act1PresaleSigner) {
            return 1;
        } else if (signer == act2PresaleSigner) {
            return 2;
        } else if (signer == act3PresaleSigner) {
            return 3;
        } else if (signer == act4PresaleSigner) {
            return 4;
        } else {
            revert("Invalid Ticket");
        }
    }

    function currentPresaleAct() public view returns (uint256) {
        if (hasPreSaleStarted()) {
            if (block.timestamp >= startPresaleAct4Date) {
                return 4;
            } else if (block.timestamp >= startPresaleAct3Date) {
                return 3;
            } else if (block.timestamp >= startPresaleAct2Date) {
                return 2;
            } else {
                return 1;
            }
        } else {
            return 0;
        }
    }

    function useTicket(bytes memory pass, uint256 quantity) internal {
        usedTickets[pass] += quantity;
    }

    /* Sale state */

    function hasPublicSaleStarted() public view returns (bool) {
        if (startPublicMintDate <= block.timestamp) {
            return true;
        } else {
            return false;
        }
    }

    function hasPreSaleStarted() public view returns (bool) {
        if (
            startPresaleDate <= block.timestamp &&
            endPresaleDate >= block.timestamp
        ) {
            return true;
        } else {
            return false;
        }
    }

    /* set the dates */
    function setPresaleDate(uint256 _startPresaleDate, uint256 _endPresaleDate)
        external
        onlyOwner
    {
        startPresaleDate = _startPresaleDate;
        endPresaleDate = _endPresaleDate;
    }

    function setPresaleAct2Date(uint256 _startPresaleAct2Date)
        external
        onlyOwner
    {
        startPresaleAct2Date = _startPresaleAct2Date;
    }

    function setPresaleAct3Date(uint256 _startPresaleAct3Date)
        external
        onlyOwner
    {
        startPresaleAct3Date = _startPresaleAct3Date;
    }

    function setPresaleAct4Date(uint256 _startPresaleAct4Date)
        external
        onlyOwner
    {
        startPresaleAct4Date = _startPresaleAct4Date;
    }

    function setPublicSaleDate(uint256 _startPublicMintDate)
        external
        onlyOwner
    {
        startPublicMintDate = _startPublicMintDate;
    }

    /* set signers */
    function setAct1PresaleSigner(address _presaleSigner) external onlyOwner {
        act1PresaleSigner = _presaleSigner;
    }

    function setAct2PresaleSigner(address _preSaleSigner) external onlyOwner {
        act2PresaleSigner = _preSaleSigner;
    }

    function setAct3PresaleSigner(address _preSaleSigner) external onlyOwner {
        act3PresaleSigner = _preSaleSigner;
    }

    function setAct4PresaleSigner(address _preSaleSigner) external onlyOwner {
        act4PresaleSigner = _preSaleSigner;
    }

    // /* Magic */
    function magicMint(uint256 numTokens) external onlyOwner {
        require(
            totalMinted() + numTokens <= maxSupply,
            "Exceeds maximum token supply."
        );

        require(
            numTokens > 0 && numTokens <= 100,
            "Machine can dispense a minimum of 1, maximum of 100 tokens"
        );

        for (uint256 i = 0; i < numTokens; i++) {
            _safeMint(msg.sender);
        }
    }

    function magicGift(address[] calldata receivers) external onlyOwner {
        uint256 numTokens = receivers.length;
        require(
            totalMinted() + numTokens <= maxSupply,
            "Exceeds maximum token supply."
        );

        for (uint256 i = 0; i < numTokens; i++) {
            _safeMint(receivers[i]);
        }
    }

    /* Utility */

    /* URL Utility */

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseURI = _baseTokenURI;
    }

    /* eth handlers */

    function withdraw(address payable account) public virtual {
        release(account);
    }

    function withdrawERC20(IERC20 token, address to) external onlyOwner {
        token.transfer(to, token.balanceOf(address(this)));
    }
}

                                                                                                                                                                                                        
//                                                                                                                                                                                                        
//                                                                                                 /&@@@@@@@@@@@@/                                                                                        
//                                                                                              &&@@@@@@@@@@@@@@@@@@@@                                                                                    
//                                                                                            @@@@@@@@@@@@@@@@@@@@@@@@@@@%                                                                                
//                                                                                            @@@@@@@@&%%%@@@@@@@@@@@@@@@@@@                                                                              
//                                                                                             @@@@&&&&&&&&&&&&&&%@@@@@@@@@@@@.                                                                           
//                                                                                               @@&&&&##########&&%%%@@@@@@@@@@                                                                          
//                                                                                                %#&&&##############%%%%@@@@#@@@@                                                                        
//                                                                                                  %%&#################%%%%@@@##(@                                                                       
//                                                                                                   (#&%################@%%#%######                                                                      
//                                                                                                     #&&#################%%%%#####,                                                                     
//                                                                                                      %%&#################%%%%#####                                                                     
//                                                                                                        #&%########/#######%(%#####                                                                     
//                                                                                                         #&&#######////#####%#%####                                                                     
//                                              /(/(#####(/.                                                %&&#######/////###&%#####%                                                                    
//                                     &&&@@@%@@#@#################                                          #&&#######/////###%%####@                                                                    
//                                /&&@@@@@@%@@#@@#@######################                                     %&&######//////##%%####&                                                                    
//                             &&&@@@@@@@@@@@@&%%%%%%%%%%%%%%%%%%############                                  %&&######/////(#&%%###(                                                                    
//                           &&@@@@@@@@@&%%%%&@&(###########%&%%%%%%&&###########                               #&@#####//////#@%%###                                                                     
//                         &@@@@@@@@&&&@@###########################@&&&&&##########                             &&######/////#@%####                                                                     
//                        @@@@@@@@@&&&####################################&&&&(########                           &&#####/////#@%###@                                                                     
//                        @@@@@@@@@&&&&&&@@&,,&@@@@&&&########################&&&&########                        %&@###(/////#&%###                                                                      
//                                                         [email protected]@@&#########///(#####&&&#######                       &&####/////@%###@                                                                      
//                                                                  @@&%#######////##@&&(#####                     &&&/##/////@%##@                                                                       
//                                                                        *@&@#####////#%&&#####      *########(,  &&@#(/////@&###                                                                        
//                                                                              #&&####///#&#&&##########################///@&%#(%                                                                        
//                                                                                  ##&#&%%#################################&##%(                                                                         
//                                                                                #(&(##%####################///////////////*/*#####                                                                      
//                                                                            %%##&#(%%################//////////////////////****//**                                                                     
//                                                                          /&#%&&#&&%&############////#/////////////////////***/*//*                                                                     
//                                                                        %%%%&&(&&&%&%%#######%@@@@@@@@@@@///////////////////***/**/*                                                                    
//                                                                      #@@@&&&&&@&&&%%%@%%%%/@**///////////////////////////////**/**/                                                                    
//                                                                     /*####@&&&&&&&&&&%%&#(//////////////////////////////////////*/*                                                                    
//                                                                    /*######&&&&&&&&&&&&//((((/////////////////////////////////////#                                                                    
//                                                                   .*(######%&&&&&&&&&&##(#/((((/@@@  /////////////////////////////*                                                                    
//                                                                   **###&&@ @&&&&&&&&&##/##((((((&&&@@@///////////////////////////(                                                                     
//                                                                  **####%&&%#&&&&&&&&#######((((((////////////////////////////////%                                                                     
//                                                                  **########&%&#####       /@#((((/////////////////%@/////////////,                                                                     
//                                                        &%       **######( [email protected]@,           */@&@@&(/////////////////////////@////@                                                                      
//                                                 (,             @%*##### ......          *@ [email protected]    #///////////@#/////////////////                                                                       
//                                                         #.      **#### [email protected]@@@@@@,%&%*    ....     .//////////////////@//////////.                                                                       
//                                                     &           */#### [email protected]@...          [email protected]     (///////////////////////((/((%                                                                        
//                                                 *               **#####*[email protected]@            ...      /////////////////////(//(/(@                                                                          
//                                                                  */#####/*,...          ./     @//////////////((((((((/((/@@                                                                           
//                                                                    /######**..&.     ((% .. @((((((((((((((((((((((((/@@                                                                               
//                                                                       #######@&***,,,&@@%#######################@@@                                                                                    
//                                                                            %#############################@@@@@@@#                                                                                      
//                                                                           &&@          #&@@@@@@@@@@@@@@@@@@@@@@@@@@                                                                                    
//                                                    @          @         @@&&@           @@@@@@@@#%@@@@@@@@@@@@@@@@@@@                                                                                  
//                                                    &@        &&        @@@@@#         @@@@@@@@@@&&&@@@@@@@@@@@@@@@@@@@@                                                                                
//                                                   @&@       &&&      @@@@@@@      %@&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@%&@@@@@@@@@@@@@@@@@@@@@@@%#////,                                                     
//                                                  ,@@@*     &&&@    @@@@@@@@ @&&&@@&&@@@@@@@@@@@@@@@@@@@@@@@@@#@@@@*//////////////////////*@@@@@@&&@/////                                               
//                                                  @@@@&   @@&&@@  @@@@@@@&&&&&&&&@@@@@@@@@&&&&&&&&&&@@@@@@@@%@@@///////////*******/***/****////*@@@&%&&(////                                            
//                                        &,       @@@@@% @@&&&@@(@@@@@&&&&&&&&@@@@@@@&&&&&@@@@@@@@@@@@@@@ &%@ //////***/***////******/***//******//@@@&&&&&////,                                         
//                                      .&@@      @@@@@@@@@@@@@@@@@@@@@&&&&&@@@@@@@@@@@@@@@@@@@@@@@@&&&&&%# ////////*****(/***////**////////////////*@@@@&&&&&////                                        
//                                      &&@@     @@@@@@////@@@@@@@@@@@@&&@@@@@@@@@@@@@@&@@@&&&&&&&&&&&@@  (/////////*/***/#(/////////////////////////#@@@@&&&&&&////                                      
//                                     @@@@#/  @@(((*/////////@@@@@@@@@@@@@@@@@@@@@(@&&&&&&&&&&&@@@@@@ ////%%//////////%////*//////////(/////#////////@@@@@&&&&&%////                                     
//                                  , @@@##//(((/////////////////@@@@@@@@@@@@@@@&&@&@@@@@&&@@@@@@@@@ ///%%%%#//*////////(/////*///////@////**/////*///@@@@@@&&&&&&////                                    
//                                @#* @@##/////////////////////////@@@@@@@@@@@@&&&&@@&&@@@@@@@@@@@ ///%*%%%*.///@///////@(@/////#///////&&@@///////%**@@@@@@&&&&&&&///                                    
//                              @##/##&###//////////////////////*////@@@@@@@@@@@@&&@@@@@@@@@@@@@@ //%/%%%%....//@.///#//*&@/@@/////#//////&&&&&&&&&&&@@@@@@@&&&&&&&///                                    
//                         /  .###/////@//////////////////////****/////@@@@@@@@@@@@@@@@@@@@@@@@@ ///%%%%%....../@@..&////&&@&/@@@@////*/////&&&&&&&&&@&&&&@@&&&&&&&///                                    
//                       @#/#####(/%/////////%(/(((((///////////***//////@@@@@@@@@@@@@@@@@@@@@@@ //%%%%%[email protected]&&&../[email protected]@@@@#/@@@&@&&&&@@@@////*///%&&&&@&&&&&%&@@@@@@////                                    
//                  ######(/////////////%*/@.......... #(/////////////////&@@@@@@@@@@@@@@@@@@@@.*/%%(/%@//(/,[email protected]@@@@@@&&&&&@&&&&&&%&&&@@@@@&&@@@@@&&&&&&&&&&&%///                                    
//               ////##&###///////////@/&...            . ##//////////////(/@@@@@@@@@@@@@@@@@@( //% //%%@@@ &%[email protected]@@@@@@@@@@%&# %&%@@&&&&&&&&@@@@@@&&&&&&&&&&&&%//.                                    
//              //###(///**//////////#/......    .&&&&&&&.  #/*/*////####/((/@@@@@@@@@@@@@@@@@@@/%@ //%%%@*(#@@#[email protected]@@@@@@@@@@@%,#,#@&&&&&&&&&@@@@@&&&&&&@@@@@&&&&&// /                                  
//             ,###(/////**///////////.......  .&&@@@@@@@&&. ////########(/((%@@@@@@@@@@@@@@@@@@,@@.#/%%%%/@((/*[email protected]@@@@@@@@@&&&&&&@&&&&&&&@@@@@@&&&&@@@&@@@&&&&&///                                   
//           &###((////&&&&&&//////(@/........          @@%&.#######(@&&&&&&&&&&@@@@@@@@@@@@@@@@@@@% /%% /////   [email protected]@@@@@@@@&&&&&&&&&&&@@@@@@&&&&@@&&@&@&&&@&&*///                                  
//         @@&&#(/(&&&&&&@@@&&@////(#*,........ &%@@@@@@@@& [email protected]###@&&&&&&@&&&&&@&@@@@@@@@@@@@@@@@@@@%@// /// [email protected]&@&&&&&&&&&&&&&&@@@@@@@&&&@@&&@&@@&@&&&&////////.                             
//        @@@@@#&&&&@@@@&&&/&&&&**/#(((,,.,,,,,,,#&&%%%&&&[email protected]##@&&&&&&&(((((((//@@@@@@@@@@@@@@@@@@@@@@/.//*@/////@@@///[email protected]@@&&&&&&&&@@@@@@@@@&&&&@@&@&&@&@&@&&///////                                
//       @@@@@@#&&&@@#&&&//%&&&&/*/##//#,,,,,,,,,,,,,,,,,,.&##@&&&&@#(((((((&@@&&@@@@@@@@@@@@@@@@@&&%@ *//////////[email protected]@@@@@@@@@@@@@@@&&&&@@&@&@&&&&&&@////////                               
//      @@#@@@@&&&&@##@&&&&&&&@#//@&&@#####,,,,,,,,,,,,,@//#&@&&&&(#(((@&&&&&&&&&@@@@@@@@@@@@@@@@@@@&&@ //////*.....................,,*@@@@@@@&&@@@&&&&@@&&&&&@&&&//////////                              
//      @@@@@@@@@@@@@@&&&&&&&&&&&&&&&&&&&&####/(#########/#@@&&&&#((@&&&&&&&&@/@@@@@@@@@@@@@@@@@@@@@@@@ ////*......................,,,,,,@@&&&&&&@@@&&&&&&&&&&&&/////////////                             
//       @@@@@&&@&&@&&&&&&&&&&&&@@@@@&&&@&&&&############@@&&&&%((@&&&&&@((((((@@@@@@@@@@@@@@@@@@&&&&&&, ///@%%%%%%####((((@%.....,,,,@@&&&&&&&&@@@@@@@@@@@@&&///////////%///                             
//         ,,,,,,,,,,,*,......... @@@@@@@&&&&&&#######@@&&&&&@(((@&&&&&(////((@@@@@@@@@@@@@@@@@@@@@&&& // //%%&((**(((((/*,[email protected]@&&&&&&&&*******@%%%%%%%%/////%////(%%(/                              
//         .,,,,,,,/,, ....,*...  @@@@@@@@@&&&&@&&&&&&&&&&&(((((@@&&&&((/(/((/@@@@@@@@@@@@@@@@@@@@@#//////.//////*/////**[email protected]@&&&&&*****/////@&%%%%%%%%%///%%////%%%*/                              
//          ,,,,,,,@,,**,,[email protected]&@@@@@@@@@@@&&&&&&&&&&@(((((((@@&&&@(((((((/@@@@@@@@@@@@@@@@@@@& /////////,//%...../*...........,,,,,******/////@@@%%%%%%%%%#/#%%%//%%%% /                               
//           ,@,,,,,@,,,..&@%,[email protected]@@@@@@@@@@@@@@@@@@@&####(((((((@&&&&@(((////@@@@@@@@@@@@@@@@@#//#/////////%%//...................,.,,*****@@@@@&&##%%%%%%%%%%/%%%%%%%%%%                                  
//                           @@@@@@@@@@@@@@@@@@@&&&&&##(((((((@@&&&&//////@%#####@@@@@@@@@@@///%%%%%%%%%%%%% /[email protected]@@@@@@*/@&&&&%%%%%%%%%%%%%%%%%%%%%%                                    
//                          @@@@@@@@@@%%%%%%%%%@@&&&&@#((((((@@&&&@@/////@######&@@@@@@@@@@@@@@@@@@@@&&/&%%%%%@****,,....(@%%%@@@@@*(///***@&&&#%%%%%%#%  %%%%%%%%  %                                     
//                          @@@@@@,%%%%%%%%%%//@@&&&&&#((((((@@@@@@////@@######%@@@@@@&@@##/#/(@@@@@@@@&&%%%%%%%%%%%%%%%%%%%%%@/////***.,.,@&&&&%#%##### %%%%%%.   /                                      
//            *@,@@@#       @@@,,/,...  %%%%%%%@%%%%%%@((((#@@@@@#((@@@########@@@@&&@@@###/#/(////@@@@%%%%%#%%%%%%%%%%%/%%%%% //**.*,,.,..#&&&&%%%%&&##%%%%                                              
//             ,,,,,,.  @@@@@@@#,,*,,.. .*%%%%%%%%%%%((,#@@@@@@@@@@@#######**@@@&&&@@&&&@####/(////***@@@@@&&        #%%%(     @**,,,......&&&&&%%%%%%####                                                
//             ,,,,,,,,[email protected]@@@@@@,,,**......%%%%%%%(%%#////@@###############@@@&&&&&&&&&@&@###((////////**@@@@&                  [email protected]&&&&&%%%%%%%##                                                
//              ,,*,,....,....*,/,,,,[email protected]@&&&@@%%/(#%//,#@@@@##########@@@&&&&@&&&&&&@@%##(((////////***//@@@#                &[email protected]&&&&&%%%%%%###%                                               
//             @@,,*&,,,,,,,,,,,,,,,,[email protected]@&&&&&&@@&%///#//,@@@@@(#@(##@@@@@&&&&&&&&&&&@####(((((///////////// @@@                [email protected]&&&&&%%%%%#%####                                              
//             @@@@@@@@@@&&&@@@@@@@&&&&&&&&&&&&@&&&&#///(/.,@@@@@@@@@@@@@&&&&&&&&&&&&&&@####((((((////////////* &@               ...........&&&&&&%%%%%%%##@@@@@@@@                                       
//              @@@@@@@@@@@@@@&@@&&&&&&&&&&&&@&&&&&&##//(((,,@@@@@@@@@@&&&&&&&&&&&&&&&&@@#@@((@(((((///////////.  @            (@@..........&&&&&&%%%%%%@@@@&@@@@@@@@@@@@@                                
//                ,@@@@@@@@@@@@@@@&@&&&@@@@@@&&&&&@ #%//////,,@@@@@@@@&&&&&&&&&&&&&&&&&@@@@(##(#(#(&((((((((((((      /@@@@@@@@//%............&@@&&%%&@@@@@@@@@@@@@@@@@@@@@@@@@@@%                        
//                         @@@@@@@@@@@@@@@@&@&@&&,  (%%//////(,@@@@@@@@&&&&&&&&&&&&&&&&&&&&&@(%#(#((##(#(((&@@@@@@@@@@@@@@@@@@///@[email protected]@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                 
//                           @@@@@@@@@@@@@@&@&&@     /%/////////@@@@@@@@@&&&&&&&&&&&&&&&&&&&@@@%#%#@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@(           
//                            @@@@@@@@@@@@@&@@        %%/////%////(@@@@@@@@&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         
//                            ,@@@@@@@@@@@@@          %#%///%##%&@@@@@@@@@@@@@@&&&&&&&&&&&&&@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        
//                             @@@@@@@@@@             &#%#%//%%%%%%@@@@@@@@@@@@@@@&&@@@@@&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@       
//                             ,@@@@@@@               &%&&&&%&&&&&&&  @@@@@@@@@@@@@@@@@@&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       
//                              @@@@                  &&&&&&&@@@@@@&  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%      
//                                                    &&&&@@@@@@@@@    @@@@@&@&&&&&@&@@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@.%. @@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      
//                                                    @@@@@@@@@@@@@*   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&,@@.,(@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      
//                                                  @@@@@@@@@@@@@@@%   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@... @@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      
//                                                @@@@@@@@@@@@@@@@@         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      
//                                              @@@@@@@@&&&@@@@@@@@         ######@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@