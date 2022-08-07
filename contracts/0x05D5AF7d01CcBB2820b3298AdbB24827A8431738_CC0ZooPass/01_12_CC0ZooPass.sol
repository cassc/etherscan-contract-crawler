// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
/*
                                    _.._                                               
                                 .-=-==+=.                                             
                                 =+**+====:                                            
                              :-***+=+=--==                                            
                             =++==-=+=-==--                                            
                                   :=====:                                             
                                  :#**+*=                                              
                                .+****++=:::==++-._                                        
                               +**###**********++=:;-.-._-:                                 
                              -###******++**+*+**+==++=.+-                              
                              -**##**#***++****+++++++=.+=                               
                               -+**##*#****+**++==++=.;                                 
                                 -+##**##+*++*+++=-.-                                  
                                   .:-==**-=*+:.-                                      
                                     .==  =+*                                         
                            |========================|                                
                            |::::::::::::::::::::::::|                                
                     /::::::::::::::::::::::::::::::::::::::\                         
                    /..====================================..\                       
                   |+ -+.:: :.  -.              .:   . .. -= +|                       
                    \-.:-:.-*. ==                :=  =- .:.-./                        
                     \_=--=:  -+                  ==  .---=_/                         
                             :*    _          _    =-                                 
                             +:   [=]        [=]   :+                                 
                             +.:       :+=-       :.+                                 
                              :-                  -:                                  
                              \=   ==        ==   =/                                  
                                --/ == ==.= == \--                                    
                                 == == ==.= == ==                                     
                                 == == ==.= == ==                                     
                                 == == ==.= == ==                                     
                                 == == ==.= == ==                                    
                                  |++++++++++++|                                      
                                 |++++++++++++++|                                     
                               |++++++++++++++++++|                                   
                             |++++++++++++++++++++++|                                  


         ▒     ▒             ▒            
  ███████▒  ███████▒  ████████▒     ▒███████▓  ▒██████    ████▓▓▒
░██▓█████▒ ████████▒ ███▓██████▒    ▒▓███████  ███████▓  ████████▒
▒███▒░  ░  ███▒▒   ▒ ███▒ ▓████      ▒   ▓██▒  ███▒▒███▒▒███▒ ▓██▒
░███░░  ░  ███▒      ███ █▓█▒██▒        ▓██ ▒  ███ ▒█▓█▒ ███ ▒███▒▒
▒███░      ███       ██████▒███▒      ▒███▒ ▒ ▒███ ▒███▓ ███▒▒███▒▒
▒███░      ███▒      █████  ███       ██▓▒    ▒███▒▒███▒▒███▒ ███ ▒
▒███       ███▒▒ ▒   ████ ▒▒██▓      ███▒  ▒   ███▒ ███ ▒███  ███
▒███████▓  ████████  ██████████▒    ▒██▓████▓▒ ███▓████▒ ████▓██▓▒
▒▓███████▒ ▒███▓██▓▓░▒██▓█████▒     ▒████████▒ ▒██████▒  ▒██████▒
 ▒▒▒▒▒▒░▒▒   ▒▒▒▒ ▒▒░░░  ░▓░░░ ▒    ▒▒ ▒▒▓▒▒ ▒  ▒▒ ▒ ▒    ▒  ▒▒▒
  ▒░▒░ ░░▒   ▒▒ ▓  ▒░ ░   ▒  ░ ▒       ▒  ▒  ▒  ▒    ▒        ▒▒
  ▒ ▒  ▒░▒   ▒  ▓   ░  ▒     ▒            ▒     ▒         ▒   ▒
  ▒    ░ ▒   ▒  ▒      ▒     ░            ▒        ▒      ▒
  ▒      ▒      ▒            ▒                     ▒           ▒
  ▒      
*/

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CC0ZooPass is ERC721A, Ownable{
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 2000;
    uint256 public constant MAX_PER_WALLET = 2;
    uint256 public constant MINT_PRICE = .05 ether;

    //events
    event Redeem(address owner, uint256 redeemedTokenId);

    string private baseURI;

    //deploy smart contract, toggle paused, set states
    bool public paused = true;
    bool public zooKeepersMinted = false;
    bool public sendOnRedeem = false;
    bool public redemptionPhase = false;
    address public redeemAddress;

    //funding properties
    address public team1Address;
    address public team2Address;
    address public team3Address;
    uint256 public teamPercentage = 15;

    mapping(address => uint256) public totalPublicMint;

    constructor() ERC721A("CC0 Zoo Pass", "CC0ZOO"){

    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "You must be a person to enter the Zoo");
        _;
    }
    /*
                                       ___-------___
                                   _-~~             ~~-_
                                _-~                    /~-_
             /^\__/^\         /~  \                   /    \
           /|  O|| O|        /      \_______________/        \
          | |___||__|      /       /                \          \
          |          \    /      /                    \          \
          |   (_______) /______/                        \_________ \
          |         / /         \                      /            \
           \         \^\         \                  /               \     /
             \         ||           \______________/      _-_       //\__//
               \       ||------_-~~-_ ------------- \ --/~   ~\    || __/
                 ~-----||====/~     |==================|       |/~~~~~
                  (_(__/  ./     /                    \_\      \.
                         (_(___/                         \_____)_)

    */

    function mint(uint256 _quantity) external payable callerIsUser{
        require( paused == false, "Sale is not active");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Guest Limit Reached! If we let you mint this many, it would be a fire hazard.");
        require((totalPublicMint[msg.sender] + _quantity) <= MAX_PER_WALLET, "Only 2 Passes per Guest!");
        require(msg.value >= (MINT_PRICE * _quantity), "Insufficient funds to enter the zoo"); //Price check

        totalPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }
    /*
                                        ,.
                                      ,_> `.   ,';
                                  ,-`'      `'   '`'._
                                ,,-) ---._   |   .---''`-),.
                              ,'      `.  \  ;  /   _,'     `,
                          ,--' ____       \   '  ,'    ___  `-,
                          _>   /--. `-.              .-'.--\   \__
                        '-,  (    `.  `.,`~ \~'-. ,' ,'    )    _\
                        _<    \     \ ,'  ') )   `. /     /    <,.
                      ,-'   _,  \    ,'    ( /      `.    /        `-,
                      `-.,-'     `.,'       `         `.,'  `\    ,-'
                      ,'       _  /   ,,,      ,,,     \     `-. `-._
                      /-,     ,'  ;   ' _ \    / _ `     ; `.     `(`-\
                      /-,        ;    (o)      (o)      ;          `'`,
                    ,~-'  ,-'    \     '        `      /     \      <_
                    /-. ,'        \                   /       \     ,-'
                      '`,     ,'   `-/             \-' `.      `-. <
                        /_    /      /   (_     _)   \    \          `,
                          `-._;  ,' |  .::.`-.-' :..  |       `-.    _\
                            _/       \  `:: ,^. :.:' / `.        \,-'
                          '`.   ,-'  /`-..-'-.-`-..-'\            `-.
                            >_ /     ;  (\/( ' )\/)  ;     `-.    _<
                            ,-'      `.  \`-^^^-'/  ,'        \ _<
                            `-,  ,'   `. `"""""' ,'   `-.   <`'
                              ')        `._.,,_.'        \ ,-'
                                '._        '`'`'   \       <
                                  >   ,'       ,   `-.   <`'
                                    `,/          \      ,-`
                                    `,   ,' |   /     /
                                      '; /   ;        (
                                      _)|   `       (
                                      `')         .-'
                                        <_   \   /    
                                          \   /\(
                                            `;/  `
    */
    
    /**
     * @notice Function to allow cc0zoo dev to mint 120 initial passes for promotion and rewards. This function may only be called once, then "zooKeepersMinted" is toggled, making this function impossible to call again.
     */
    function zooKeepersMint() external onlyOwner{
        require(!zooKeepersMinted, "Don't get greedy, kid!");
        _safeMint(msg.sender, 120);
        zooKeepersMinted = true;
    }

    /*
                                                          _  _
                                                         (\\( \
                                                          `.\-.)
                                      _...._            _,-'   `-.
        \                           ,'      `-._.---.,-'       .  \
         \`.                      ,'                               `.
          \ `-...__              /                           .   .:  y
           `._     ``--..__     /                           ,'`---._/
              `-._         ``--'                      |    /_
                  `.._                   _            ;   <_ \
                      `--.___             `.           `-._ \ \
                             `--<           `.     (\ _/)/ `.\/
                                 \            \     `<a \  /_/
                                  `.           ;      `._y
                                    `--.      /    _../
                                        \    /__..'
                                         ;  //
                                        <   \\
                                         `.  \\
                                           `. \\_ __
                                             `.`-'  \\
                                               `----'' 
    */

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @notice return uri for certain token
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 trueId = tokenId;

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, trueId.toString(), ".json")) : "";
    }
/*                                                                                        
                         ,
                   (`.  : \               __..----..__
                    `.`.| |:          _,-':::''' '  `:`-._
                      `.:\||       _,':::::'         `::::`-.
                        \\`|    _,':::::::'     `:.     `':::`.
                         ;` `-''  `::::::.                  `::\
                      ,-'      .::'  `:::::.         `::..    `:\
                    ,' /_) -.            `::.           `:.     |
                  ,'.:     `    `:.        `:.     .::.          \
             __,-'   ___,..-''-.  `:.        `.   /::::.         |
            |):'_,--'           `.    `::..       |::::::.      ::\
             `-'                 |`--.:_::::|_____\::::::::.__  ::|
                                 |   _/|::::|      \::::::|::/\  :|
                                 /:./  |:::/        \__:::):/  \  :\
                               ,'::'  /:::|        ,'::::/_/    `. ``-.__
                              ''''   (//|/\      ,';':,-'         `-.__  `'--..__
                                                                       `''---::::'
*/

    /**
     * @dev walletOf() function shouldn't be called on-chain due to gas consumption
     */
    function walletOf() external view returns(uint256[] memory) {
        address _owner = msg.sender;
        uint256 numberOfOwnedNFT = balanceOf(_owner);
        uint256[] memory ownerIds = new uint256[](numberOfOwnedNFT);

        for(uint256 index = 0; index < numberOfOwnedNFT; index++) {
            ownerIds[index] = tokenOfOwnerByIndex(_owner, index);
        }

        return ownerIds;
    }

    /*
                       _
                      ( \                ..-----..__
                       \.'.        _.--'`  [   '  ' ```'-._
                        `. `'-..-'' `    '  ' '   .  ;   ; `-'''-.,__/|/_
                          `'-.;..-''`|'  `.  '.    ;     '  `    '   `'  `,
                                     \ '   .    ' .     '   ;   .`   . ' 7 \
                                      '.' . '- . \    .`   .`  .   .\     `Y
                                        '-.' .   ].  '   ,    '    /'`""';:'
                                          /Y   '.] '-._ /    ' _.-'
                                          \'\_   ; (`'.'.'  ."/
                                           ' )` /  `.'   .-'.'
                                            '\  \).'  .-'--"
                                              `. `,_'`
                                                `.__) 
    */

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    /*
                               ,-.             __
                             ,'   `---.___.---'  `.
                           ,'   ,-                 `-._
                         ,'    /                       \
                      ,\/     /                        \\
                  )`._)>)     |                         \\
                  `>,'    _   \                  /       |\
                    )      \   |   |            |        |\\
           .   ,   /        \  |    `.          |        | ))
           \`. \`-'          )-|      `.        |        /((
            \ `-`   a`     _/ ;\ _     )`-.___.--\      /  `'
             `._         ,'    \`j`.__/        \  `.    \
               / ,    ,'       _)\   /`        _) ( \   /
               \__   /        /nn_) (         /nn__\_) (
                 `--'           /nn__\             /nn__\
    */

    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function setRedemptionPhase(bool _redemptionPhase) public onlyOwner {
        redemptionPhase = _redemptionPhase;
    }

    /*
                                             _
                                          .' `'.__
                                         /      \ `'"-,
                        .-''''--...__..-/ .     |      \
                      .'               ; :'     '.  a   |
                     /                 | :.       \     =\
                    ;                   \':.      /  ,-.__;.-;`
                   /|     .              '--._   /-.7`._..-;`
                  ; |       '                |`-'      \  =|
                  |/\        .   -' /     /  ;         |  =/
                  (( ;.       ,_  .:|     | /     /\   | =|
                   ) / `\     | `""`;     / |    | /   / =/
                     | ::|    |      \    \ \    \ `--' =/
                    /  '/\    /       )    |/     `-...-`
                   /    | |  `\    /-'    /;
                   \  ,,/ |    \   D    .'  \
                    `""`   \  nnh  D_.-'L__nnh
                            `"""`
    */

    /**
     * @notice Allows a member to redeem their Zoo Pass for a reward. Stick around!
     */
    function redeem(uint256 _tokenID) external {
        require (redemptionPhase == true, "It is not your time.");
        if (sendOnRedeem) {
            transferFrom(msg.sender, redeemAddress, _tokenID);
        }
        emit Redeem(msg.sender, _tokenID);
    }

    /*
⠀⠀⠀⠈⠁⠀⠀⠀⠀⠀⠰⠀⠀⠀⠂⠀⠀⠀⠀⠀⠀⠀⠈⠐⠉⠱⠢⠀⢤⣄⢲⣄⠀⠀⠀⠄⠀⠙⢠⠀⠀⠀⠀⠀⠀⣨⣷⡞⠉⠀⠀⠀⠀⠀⠀⠀
⠈⠁⠈⠃⠀⠀⠀⠀⠀⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠁⠉⠁⠀⠀⠀⠠⠶⠯⣤⢤⣄⣀⣤⢾⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀
⠀⡦⠀⠀⠀⠀⠀⠀⠀⡤⢁⡀⠀⣴⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡀⠀⠠⢶⣆⠀⠀⠀⢀⣤⣶⢟⠉⠀⣠⣾⣿⡋⠀⠀⠀⠀⠀⠀⠀⠀
⠀⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⠁⢰⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⠹⢧⣀⡀⠻⣷⣤⡴⢟⣡⡿⢇⣴⣿⣯⡾⡟⠂⠀⠀⠀⠀⠀⠀⠀⠀
⢰⡇⠀⠀⠀⡀⡀⠀⠀⠀⢸⣿⡇⢰⡟⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⣠⠤⠤⠄⠠⠄⠤⣈⣛⢷⣿⣿⣿⡟⢭⣷⣿⣿⠿⠋⢐⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀
⡈⠁⠀⠀⢘⣧⣾⣷⣶⡌⠀⣾⡀⢺⣴⠃⡀⠀⠀⢀⣤⠞⠛⢉⣭⡥⠀⠀⠀⠀⠀⠀⠀⠈⠳⣿⣯⣿⣿⣾⣿⠟⠉⠀⠀⢸⡿⡓⠀⠀⠀⠀⠀⠀⠀⠀
⡇⠀⠀⠀⣸⣯⣟⣿⣬⣿⣆⢻⣧⢸⡟⣴⠏⣼⠇⠀⢠⣞⣷⡿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣽⣿⣿⣿⡿⠋⠀⠀⠀⠀⠀⡏⢻⡀⠀⠀⠀⠀⠀⠀⠀
⡇⠀⢸⡆⣿⣿⣿⡿⣿⣿⣻⣿⠛⣯⣿⢹⡄⢀⡄⣰⠏⠿⣿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⡟⠀⠀⠀⠀⠀⠀⢰⣿⡈⠿⢦⠀⠀⠀⠀⠀⠀
⣧⣶⠿⢡⣿⣷⢿⣿⣿⣿⣿⡿⠀⢸⣧⡟⠁⠎⡰⠏⠀⠰⢧⠀⠀⠀⡀⠀⠀⠀⠀⠀⠀⠀⢻⣿⡟⣽⡇⠀⠀⠀⠀⠀⠀⢸⡟⠁⠀⠈⠀⠀⠀⠀⠀⠀
⣿⠉⠀⣾⣿⣿⣮⣿⣿⣿⣽⣷⣠⣼⢾⣇⠀⣴⠃⠀⢠⠀⢸⣶⡄⠈⢻⣿⣿⣿⣿⣿⣶⣶⣿⡿⣿⣿⣷⣶⣶⣶⣶⣶⣶⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀
⣿⠨⠀⠹⣿⣿⣿⣿⣿⣿⣯⣿⣿⡗⢠⣿⠀⣿⢀⠀⠈⢷⡄⠻⣿⣦⣠⣿⣿⣿⣿⠟⠁⣹⣯⠻⣏⢿⣿⣿⣿⣿⡟⣻⡟⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⣿⡸⣇⣠⣏⣿⢿⣿⢹⣿⣿⣿⣿⣶⣌⣿⣧⣻⡆⣾⣿⣦⠻⢦⡈⠛⢿⡿⢿⣿⠝⣀⠴⠛⣷⡅⠙⣷⡻⣿⡿⠁⢀⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⢹⡇⢿⣿⢿⣿⣼⣿⣾⣿⣿⣿⣿⣿⣿⣻⣿⣿⣧⡛⠿⣿⣿⣶⠿⠶⠶⠾⢋⣡⠾⠁⣴⠀⠈⠳⣄⣈⢙⢻⡶⠤⣸⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠁⠀⣿⣽⣿⣿⣷⣿⠛⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣾⢷⣾⣷⣶⡶⠿⠛⠁⢀⣼⡟⠁⠀⠀⠀⠙⠿⣿⣻⣶⣿⣷⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠂⣠⠀⢸⣿⣿⣿⣯⣿⣦⠈⣿⣿⣿⣿⣧⣻⣿⣿⣿⣿⣿⣭⡉⠁⠠⢤⢀⡠⠖⠿⢻⡾⠁⠀⠀⠀⠀⠀⠈⡟⢿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠛⡀⠸⢇⢻⣿⣿⣿⣟⠒⣿⣿⣿⣿⣿⣿⣷⣾⣿⣿⣿⣿⣿⣗⣂⣠⣞⡥⠖⠀⢸⡇⠰⣶⣿⣷⡄⠀⠂⢸⠀⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠰⡆⢁⠀⠺⣿⣿⣿⣿⣿⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⢿⣿⢾⣭⡛⠿⢥⣀⠀⠀⠀⠀⠙⠆⠿⣿⣿⣿⣷⡶⠊⠃⠸⣿⣆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠴⣠⣘⣿⣶⣹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢷⡹⠿⠿⠿⠳⢤⣝⣆⠀⠀⠀⠀⠀⠀⠈⠛⠛⠃⠀⠀⠀⠀⠹⣿⣶⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀
⣶⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣏⡃⠀⠀⠀⠈⠑⢿⠛⠳⣤⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠻⣿⣧⡄⠀⠀⠀⠀⠀⠀⠀⠀
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣯⣿⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⣛⢦⣤⠀⠀⣄⠀⠀⠀⠀⠀⠀⠀⠙⣿⣧⣤⣤⣤⣀⡀⠀⠀⠀
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠒⢷⣿⡽⢦⠈⢧⠀⠀⠀⠀⠀⠀⡀⠀⠀⠀⠀⡀⠈⠹⣦⡀⠀
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠀⠑⢬⡓⠶⣆⡀⠘⠂⢀⣠⢶⣾⡿⠿⢿⣆⢸⣿⠀
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠤⠀⠀⠉⠁⠀⠀⢀⣤⣞⣽⣿⡇⠀⠒⢸⡟⣸⣿⠃
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠶⣶⣤⣀⣀⡀⢀⣠⡴⣾⣿⣿⣿⣿⣿⠏⣠⣠⠾⣡⣿⠟⠀
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡧⠀⠁⠀⠀⠀⠀⠀⣠⣤⣤⣀⣀⠐⠀⠀⠀⠉⠉⠛⠻⠿⢿⣿⣿⣿⣿⣿⣿⣿⣿⡟⢿⡾⠋⠀⠀⠀
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⡄⠠⠀⠀⠀⠀⠀⣀⡀⢉⣉⣭⣭⣍⣛⣀⣀⣀⣀⡀⠀⠀⠉⠻⢿⣿⣿⡿⠿⠉⠙⠀⢿⣦⠀⠀⠀
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣇⡈⠒⢁⣀⠉⠁⢀⣴⢛⡉⠀⠀⠀⢉⣉⣹⣿⣝⣻⠿⢦⡰⢄⠀⠀⠀⠀⠀⠀⠀⠀⠈⣿⣆⠀⠀
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⣠⣾⠿⠟⡏⠸⠀⠀⢲⣌⣭⣿⣽⣿⣿⣷⣤⣹⣀⠹⣄⠀⠀⠀⠀⠀⠀⠀⣿⣷⡀⠀
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣉⣿⣿⣿⣿⣿⣿⣿⣿⣥⣤⣤⣵⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣯⣿⣅⣜⠒⠂⠀⠀⠀⠀⢠⣿⠄⠀⠀
⢹⠿⢛⣽⣿⣿⣿⣿⣿⣿⣿⣿⣽⠿⣭⣿⣿⢛⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⣿⣿⡟⢴⣿⡿⠿⣿⣿⣷⣆⠀⡀⣠⣾⡇⠀⠀⠀
⡈⠞⢘⠛⡽⢿⣿⣿⡿⢭⣿⣿⣿⣾⣿⣿⣿⣬⣥⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢿⣿⡾⣿⠉⠀⠾⣿⡻⣿⢿⣿⠛⠂⠀⠀⠀⠀
⠀⠀⠀⠀⢂⡟⣻⣿⠃⠘⣏⠹⣾⣿⣷⠛⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣸⡟⢁⠀⠻⣦⡀⠈⣷⡸⣶⣄⠀⠀⠀⠀⠀⠀
⠀⠀⠀⢀⠘⣡⠟⠷⠀⠄⠈⠀⠒⠶⢶⢟⣶⣞⣻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠻⠇⠀⠀⠘⠀⠈⠷⠀⠈⠿⠸⣿⣧⠀⠀⠀⠀⠀
    */
    
    /**
     * @notice Change the redemption settings
     */
    function redeemSettings(address _redeemAddress, bool _sendOnRedeem) external onlyOwner {
        redeemAddress = _redeemAddress;
        sendOnRedeem = _sendOnRedeem;
    }

    /**
     * @notice Initial withdrawal function to fund the team and enable us to continue to build the cc0zoo.
     */
    function teamWithdraw() external onlyOwner{
        //25% each to 3 team wallets, and the remaining 25% to the cc0zoo fund.
        uint256 withdraw_25 = address(this).balance * 25/100;
        payable(team1Address).transfer(withdraw_25);
        payable(team2Address).transfer(withdraw_25);
        payable(team3Address).transfer(withdraw_25);
        payable(msg.sender).transfer(address(this).balance);
    }

    /*
                                                      ___.-----.______
                                            ___.-----'::::::::::::::::`---.___
                         _.--._            (:::;,-----'~~~~~`----::::::::::.. `-.
            _          .'_---. `--.__       `~~'                 `~`--.:::::`..  `..
           ; `-.____.-' ' {0} ` `--._`---.____                         `:::::::: : ::
          :_^              ~   `--.___ `----.__`----.____                ~::::::.`;':
           :`--.__,-----.___(         `---.___ `---.___  `----.___         ~|;:,' : |
            `-.___,---.____     _,        ._  `----.____ `----.__ `-----.___;--'  ; :
                           `---' `.  `._    `))  ,  , , `----.____.----.____   --' :|
                                 / `,--.\    `.` `  ` ` ,   ,  ,     _.--   `-----'|'
                            __./'_/'     :   .:----.___ ` ` ` ``  .-'      , ,  :::'
                          ///--\;  ____  :   :'    ____`---.___.--::     , ` ` ::'
                          `'           _.'   (    /______     (   `-._   `-._,-'
                                    .-' __.-//     /_______---'       `-._   `.
                                   /////    `'                      ______;   ::.
                                   `'`'                            /_______   _.'
                                                                     /___.---'  
    */

    /**
     * @notice After initial team funding, withdrawal percentages will be changed to allow for 
     * more funds to go straight back into the cc0zoo fund. By default the team percentages
     * are set at 15% for each of the 3 team members, with the remaining 55% to be allocated
     * to the cc0zoo funding wallet
     */
    function zooWithdraw() external onlyOwner{
        uint256 teamAmount = address(this).balance * teamPercentage/100;
        payable(team1Address).transfer(teamAmount);
        payable(team2Address).transfer(teamAmount);
        payable(team3Address).transfer(teamAmount);
        payable(msg.sender).transfer(address(this).balance);
    }

    function setTeamPercentage(uint256 _teamPercentage) public onlyOwner{
        teamPercentage = _teamPercentage;
    }

    function setAddresses(address _team1Address, address _team2Address, address _team3Address) public onlyOwner {
        team1Address = _team1Address;
        team2Address = _team2Address;
        team3Address = _team3Address;
    }

/*
                                     .ed"""" """$$$$be.
                                   -"           ^""**$$$e.
                                 ."                   '$$$c
                                /                      "4$$b
                               d  3                      $$$$
                               $  *                   .$$$$$$
                              .$  ^c           $$$$$e$$$$$$$$.
                              d$L  4.         4$$$$$$$$$$$$$$b
                              $$$$b ^ceeeee.  4$$ECL.F*$$$$$$$
                  e$""=.      $$$$P d$$$$F $ $$$$$$$$$- $$$$$$
                 z$$b. ^c     3$$$F "$$$$b   $"$$$$$$$  $$$$*"      .=""$c
                4$$$$L        $$P"  "$$b   .$ $$$$$...e$$        .=  e$$$.
                ^*$$$$$c  %..   *c    ..    $$ 3$$$$$$$$$$eF     zP  d$$$$$
                  "**$$$ec   "   %ce""    $$$  $$$$$$$$$$*    .r" =$$$$P""
                        "*$b.  "c  *$e.    *** d$$$$$"L$$    .d"  e$$***"
                          ^*$$c ^$c $$$      4J$$$$$% $$$ .e*".eeP"
                             "$$$$$$"'$=e....$*$$**$cz$$" "..d$*"
                               "*$$$  *=%4.$ L L$ P3$$$F $$$P"
                                  "$   "%*ebJLzb$e$$$$$b $P"
                                    %..      4$$$$$$$$$$ "
                                     $$$e   z$$$$$$$$$$%
                                      "*$c  "$$$$$$$P"
                                       ."""*$$$$$$$$bc
                                    .-"    .$***$$$"""*e.
                                 .-"    .e$"     "*$c  ^*b.
                          .=*""""    .e$*"          "*bc  "*$e..
                        .$"        .z*"               ^*$e.   "*****e.
                        $$ee$c   .d"                     "*$.        3.
                        ^*$E")$..$"                         *   .ee==d%
                           $.d$$$*                           *  J$$$e*
                            """""                              "$$$"
*/
    

    receive() external payable {}
}