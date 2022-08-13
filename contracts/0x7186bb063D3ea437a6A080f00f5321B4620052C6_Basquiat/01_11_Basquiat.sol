// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/Strings.sol';
import "./ERC721A.sol";


/*
                                The day you came to us

@@&##&&##&#B#&&#####BBBBBB#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGGBBBBBBBBBBBBBBBB##########&&#######&#
##&##############BB#BBBBBBBBBBGGPPPPPPPP5555YYYYJ?JJ55PPPG#BBBBBBBGBBBGBBBBBBBBBBB####B##########&&&
##B########B###B#######BGYJ??7777!!7!!!!!~~~~~~~~~~!~~!!~7YYYYJ5GGGGGGBBBBBBBBBBBBBB####&####&&&&&&&
########&###BBBBGGPP5Y??777777777!!!~!~GG!~5G!~~~~7&J~~~~~~~~~!!!77!777?JY5PPGGBGB##########&&&#&&&&
BB#[email protected]!&[email protected]^~~?J!~7Y7~!!!!!!!!!!!!!777?5BBBBB######&&#&&&&
BB#BBBBBBB#[email protected][email protected][email protected][email protected]#[email protected]!J&@7!#@?~~~~!!~!!!!!!!!!~~!GBBB#######&&#B#&&
BBB####[email protected]&[email protected]##@@[email protected]@@&#@@&@@@[email protected]~~~~~~~!!!!!!!!!!~~~JBBBBB######&#B#&&
#BBB#BBBBBBPGGBGY!777!!!!!!!J5J!!GG#@@@@@@@@@&5&@@@@@@@@@&@@B5!~~^^7G&J~!!!!!~~!!~!?5PGBBBBB########
#BBBBBGBBGGPPGGY7!777!!!!!!!?5##[email protected]@@@@@@@@@@@@&@@@@@@@@@@@@@@@BY!?G&B?~~~~~~~~~~~~~~~!YBBBBBBB#BBB##
#BBGGGGGGGGGPGP7!^!!7!!!~~!!~Y&@@@@@@@@@@@@@@@@&&&@@@@@@@@@@@@@@&#5!^^~^^^^~~~~~~~~~~~JBBBBBBB##B###
BBGBBGGGGGGGPG57!^[email protected]@@@@@@@##BPYYYJ?777?JPPGGGG&@@@@@@#B~~~~~~!!!!~~~~~~~~!YGGGBBBB##BBB#
GBBBBGGGGGGGPP57!!!!77!~!!!~~?#@@@@@G?!!!~~~7~^^~JJ5GGY7?J5#@@@@@@&555555555J~~~~~~~~!5GGGGBGB#BBBB#
[email protected]@@@@#~~!!~~~7!~^!GGGGGP????Y#@@@@@&?^^^^^^^^^~~~~~~~~!5PPPGBGGBBBBB#
[email protected]@@@@&[email protected]@@@@#~:^::^^^^^^~~~!~~~!YP5PPGGPGGBB##
[email protected]@@@@#[email protected]@@@&PYJJJYYYYY!~~^~~~~!YP55PPGGGGBBB#
GGGBGPPP55555577!!!!!!!!!!!~~~7#@@@&B5PPY5J?!~~~~!7777!!!!!7JP#&@@@J!777????J~^~~^~~!!Y55555PGGBBGB#
[email protected]@@@#Y?JYJJ??!!!~~~!?5PPGG5JJ5B#@@#^::::^^^~^^~~~^~!!!J5P55PPGPGBBB#
GGGGPPPP5Y5PPP?!~^~!!!!~~~~~~~^[email protected]@#BGGPGBBGPY?777?YGBBB#B5Y55P#@@G^^^:::^^^^^~~~^!~~!JY555PPPPGBB##
GGGGPP55YY55GP7!~^[email protected]@&GPBB5#&&PPP?~7?Y5JY#&55J5Y?G#5BG5PP55YJ??7~~^~!~~!J555P555GGB#B#
[email protected]&&GJ5G5GBY7Y5~^~!?7^^!???7!!?PY5P5~~!7?JY5G5~~~~~~!!J55P55Y5PGGBGB
GPPPP555YY55557~~~~!!~~~~~~!!7?J5&BBGJ?77777JY?~~~~!??7~~!!7J?JGY7PP!^^:^^^^^^^^~~~~~!75555Y55GPGBGB
GPPPPPP5YY5555!~~~~~!~~?5PPP555J?#BGGPPYJ!77JPY7!7?JJJY7~!5PGYJG5YPP~^^^^^^^^^^^~~~~~~!J55YY55GPGBGG
PPPP5555YYY555!~!~~!!~~7?7!~~~~~^PBGGBBBG?77YBGGG#B555J!!?55G55B#BB7^^^^^^^^^~^^~~~~!!!JY5YY55PPGGPG
PP5555555YYY5Y!~~~~!!~~~~~~~~~~~^!B&###BBY77!7!!!77!!~~~!?PYG5PB#J?PG57!^^^^^~^~~~~~!!!Y55Y555PPGGPG
PP5555555Y5Y5J!~~~~!!~~~~~~~!!7J5G&&P##BBP??J5PGP5PPPYY??J5YPYYGBGBJ7?YPG5?!^~^~!~~~~!!YYYY555PPGGGG
GP5PP55Y555Y5J~~~~~!~~~~~~~YBGG5??#&&YP#BBGPP555YY5555YYYPP55J5BJ.7BB?^^!JYJ^^^~!~~~~!?YYYY555PPGGBB
GPPPP55555555Y~~~~~~~~~~~!~!!~~75GY&Y^7BBBBGGGBBBBBBG5Y5555PGBGB?::^?#G7~~~^^~~~!~^~~!?YY5555PPPGGBB
GPPPPP55555555!~~~~~^~~~~~~~~?BBJ~?&~^^5#BBBG5JJ??JYJJY5PG#&&BPB~.^^^!PP~~~~~~~~~^^~~!J55P555PPPGBB#
P55PPP55555P557~~~~~~~~~~~~~!PY!^^BB~^^!#BB##BPYJJJY5PG#&&#BGPG#^.:^^^^~~~~~~~~~~~~~~!JJY5555PPGGBGB
P5PPPP555555557~~!!~~~~!!!~~~^~~~~7!~~~^Y&BBB#&&####&&##GGGPPPG#7.:~^^^~~~~~~~~~~~~~!7JJ5555PGPGBGB#
PPPPPP5555555P7!~~~~~~~!!!~~^~~~!!~~~~~~^5&#GGG##BGGGGPGGGGGPGGY7Y!^^^^~~~~~~~~~~~~~7?JJY55PPGGGGGB#
GGP5PP555555PP?!~~~~~~~!~!!~~~~~!7!!~!~~!?5##GPGGP5PPPPY55PPGBY: ~BP?!~~~~~~~~^~~~~7?JJY55PPGBGGGGB#
BBG5PP555555P5777!^~77J7!!!!~^~~!!!~~!7YB? 7GGGGGGPY?!^^:^^!?~... ~&@&BJ^~~~~~^~~~!7JJJY5555GGGGGBBB
[email protected]@@P  :Y5G57^:::::::^~:.... [email protected]@@@&5~^^~^~~~~!7JJJY555PGGGGBB#B
##[email protected]@@@@@&Y5GGGPG5^!?7?!~~^:.. . :#@@&@@&B?^^^~~~~!7JJJY555GBBBBB###
#BBGGGGPPPG5P55Y?Y????JPPPJ?Y5PBB&@@@@&&&@@@@#&&&[email protected]&&&&@&&&5^^~~~~!?JJJY55PGGGGBB###
BBBGPGGPPPP5GPJ?PY!JP!Y#&#B&@@@&&&@@@#&@@@&[email protected]##PJ???~^^~~!5#@&#&&@@@@&&&G?!?JJ??JJJY5PPGBGGB##&#
#BBBGGBGGGGPBB?JBP~5#[email protected]@B&@@@@@&@@@&B&@&Y!^::!##B&@@&@@J^^~~?#@@BB#@@@@@@@&&&5PBBBG5YJ5PPGGBBBB&&&&
&###BBBBBGGPG#7J#B!5&[email protected]&[email protected]@@@@&&@@&##&@G!^~^~^#&###@@@#J~^^[email protected]@@#B#@&&@@@@@@&@#BB###G5YPGGBBBBB##&&#
####BBBGBBBGG&[email protected]#!B&[email protected]&#@@@@&#@@@&##&&#!^^:^:[email protected]@&#&&@5^:::#@@@BG&@&@@@@@@@&@@#BG##B55GGGGBBB#&&&&&
###&#BBGBBBGG#[email protected]&!##[email protected]@#@@@&&&@@@&##&#?!~^::.!&@@#&@@5^::~&@@&[email protected]@@@@@@@@&&@@&&B##&55PGGG####&&&&@
&&&&&#BBBBBGG&B?&#7##[email protected]&[email protected]@@@@@@@@###&B^^~!^::~&@@#@@#?:::[email protected]@@#G&@&@@@@@@@&&@@B#&#&&PPGG#B#&#&&&&&@
&&&&&###BBBBB#B!&#[email protected]#G&@@@@@@@@####B^::~!^:[email protected]@&#@@P^.^7J#@@[email protected]@@@@@@@@@&@@@BB##&#BGBGB##&&&#B#&@
##&&&&#####BGP575G7PG7J5JP&@@@@&@@@&###B:^^:^^[email protected]@&#@&7.^[email protected]&[email protected]@GB&&@@@@@@@@&@@@#G##&&BG#B##&@@@&##@@
###&&&&&####B#@G7??7?775#&&@@@@&@@@&#&#&YJPBP?P&@@#B&P:^[email protected]@@&&@GG&&&###########BB&#&&BG#B&#&@@@&#&&@
&&&&&&&&#&###&&@[email protected]@&@@@@&@@@&#&B&@@&@@@@@@@#[email protected]@@@#&&PB&@@@&&&&@&@&&&#BG&BBBG##&&&@@@@@&&&
&&&&########&&&&&[email protected]@#@@@@@@@@&#&#&@@@@@@@@@@BP!^[email protected]@@@@#@&GBB###&&###&&#G##G#&BG#G#&&&&&@@@@@&@


                                        R.I.P.                                                                                                                                             
*/
contract Basquiat is ERC721A, Ownable {
    using Strings for uint256;

    address private constant TEAM_ADDRESS = 0x7077Cb152B1cef11EDa2899A69DEACd81C3c0EC3;

    uint256 public constant TOTAL_MAX_SUPPLY = 1222;
    uint256 public constant TEAM_CLAIM_AMOUNT = 22;


    uint256 public  MAX_PUBLIC_PER_TX = 2;
    uint256 public  MAX_PUBLIC_MINT_PER_WALLET = 2;

    bool claimed = false;

    uint256 public token_price = 0.002444 ether;
    bool public ripStart;


    string private _baseTokenURI;


    constructor() ERC721A("The day you came to us", "RIP") {
        _safeMint(msg.sender, 12);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier underMaxSupply(uint256 _quantity) {
        require(
            _totalMinted() + _quantity <= TOTAL_MAX_SUPPLY,
            "RIPs would exceed max supply"
        );

        _;
    }

    modifier validatePublicStatus(uint256 _quantity) {
        require(ripStart, "RIP hasn't started");
        require(msg.value >= token_price * _quantity, "Need to send more ETH.");
        require(_quantity > 0 && _quantity <= MAX_PUBLIC_PER_TX, "Invalid mint amount.");
        require(
            _numberMinted(msg.sender) + _quantity <= MAX_PUBLIC_MINT_PER_WALLET,
            "This purchase would exceed maximum allocation for public mints for this wallet"
        );

        _;
    }

    /**
     * @dev override ERC721A _startTokenId()
     */
    function _startTokenId() 
        internal 
        view 
        virtual
        override 
        returns (uint256) {
        return 1;
    }

    function rip(uint256 _quantity)
        external
        payable
        callerIsUser
        validatePublicStatus(_quantity)
        underMaxSupply(_quantity)
    {
        _mint(msg.sender, _quantity, "", false);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : '';
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

      function teamClaim() external onlyOwner {
        require(!claimed, "Team already claimed");
        // claim
        _safeMint(TEAM_ADDRESS, TEAM_CLAIM_AMOUNT);
        claimed = true;
  }

    
    function setMaxPerTxn(uint256 _num) external onlyOwner {
        require(_num >= 0, "Num must be greater than zero");
        MAX_PUBLIC_PER_TX = _num;
    } 

    function setMaxPerWallet(uint256 _num) external onlyOwner {
        require(_num >= 0, "Num must be greater than zero");
        MAX_PUBLIC_MINT_PER_WALLET = _num;
    } 

    function setTokenPrice(uint256 newPrice) external onlyOwner {
        require(newPrice >= 0, "Token price must be greater than zero");
        token_price = newPrice;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawFunds() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function withdrawFundsToAddress(address _address, uint256 amount) external onlyOwner {
        (bool success, ) =_address.call{value: amount}("");
        require(success, "Transfer failed.");
    }

    function flipRipState() external onlyOwner {
        ripStart = !ripStart;
    }

}