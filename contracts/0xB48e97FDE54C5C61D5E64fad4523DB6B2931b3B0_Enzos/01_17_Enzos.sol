// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// !!!!!!!!!!!!!!!!!!!!!!!!!!!&!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// !!!!!!!!!!!!!!!!!!!!!!!!!&BY5B!&!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// !!!!!!!!!!!!!!!!!!!!&G5!BJ:  .~!7P!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// !!!!!!!!!!!!!!!!!!&B??5?:?:!J: !PB!&BB!!&BB&!!!!&BB&!!!!!!&BB&&!!!!!&BB!&!!!!!!!!!!!!!!!!!!!!!!!!
// !!!!!!!!!!!!!!!!!!5^J&J .!^?P:.^^?GY^:PBJ::JB!!BY  JB!!!!PJ::75G!!!BJ:.~JP57Y!!!!!!!!!!!!!!!!!!!!
// !!!!!!!!!!!!!!!!!5 .B&? .B^^!!!!P!P:  :?Y~  ~!BJ5Y^ ^G&J: ~J~. .7&J..5J!. ^JB!!!!!!!!!!!!!!!!!!!!
// !!!!!!!!!!!!!!!!&? .B&? .B^?&&&&!!&J  !!&5  ^!!!&G! G&&!  J&&J  ~&?  YB5^:YB!!!!!!!!!!!!!!!!!!!!!
// !!!!!!!!!!!!!!!!&J  !!?.?!^?&!!!!!&?  !&&5  ^!!G!.  ^J!!  J&&J  !&P?~ !5P^ ^!!!!!!!!!!!!!!!!!!!!!
// !!!!!!!!!!!!!!!!!B!  :^Y!&^J&&&!GJGJ  !&&5  ^!!BGBP~  G!  7B&J  ~&&G7!P!&7 :!!!!!!!!!!!!!!!!!!!!!
// !!!!!!!!!!!!!!!!!!!J:   :!.^??!^7P!7  ~!&5  .Y!!&!G  Y!Y^. .~~.^YG!  :.:!:.?!!!!!!!!!!!!!!!!!!!!!
// !!!!!!!!!!!!!!!!!!!&BY7~~~~~^~?P!!!5!~Y!!!Y~JB!!YJJ !&!!!G577YG!&!^?5GY7:?B!!!!!!!!!!!!!!!!!!!!!!
// !!!!!!!!!!!!!!!!!!!!!&!!!!!!!!&!!!!!!!!!!!&!&!!G~P!!!!!!!!&&&&!!!B!&!!&!B&!!!!!!!!!!!!!!!!!!!!!!!
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!GJG!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!77777?????????JJJJJJJ???JJJJ?7777!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!??JYYYYYYJJJJJJJJJYY5PGGP5JYY5PGPPPP5YJ?7!!!!!!!!!!!!!!!!!!!!!!!!!!!
// !!!!!!!!!!!!!!!!!!!!!!!!!!!7YYJ5PGPPPPGGGGGGGPP5YJJJYYPP5JJ5PGGGGGGPPP5J7!!!!!!!!!!!!!!!!!!!!!!!!
// !!!!!!!!!!!!!!!!!!!!!!!!!7J5PYJPGGGGGGGGGGGGGGGGGGGP5YJYPP5JJY5GGGGGGGPP5J7!!!!!!!!!!!!!!!!!!!!!!
// !!!!!!!!!!!!!!!!!!!!!!!7JYYJY5Y55PPPP5YJJJJJJY5PPPPGGGG5YYPG5JJY5PGGGGGGPP5J7!!!!!!!!!!!!!!!!!!!!
// !!!!!!!!!!!!!!!!!!!!!7JYYJ?????JJJJY55P555YYJJ?JJJJY55PGG5JPBPJJ5YYY5PGGGGPP5J7!!!!!!!!!!!!!!!!!!
// !!!!!!!!!!!!!!!!!!!7JP5YJYYYYYYYYJJJJJY5PGGGPP5YJJJ??JJ5GG5JPGPJYPP55YYPGGGGP55Y?!!!!!!!!!!!!!!!!
// !!!!!!!!!!!!!!!!!7YPGGGGGGGGGGGGGGGGPPPPPPGGGGGGPP5YJJ?J5GPJJPBPJ5PPPP5JYPGGGG5YYY?!!!!!!!!!!!!!!
// !!!!!!!!!!!!!!!?5PGPPPPPP5555555Y5PPPPGGGGGGGGGGGGGGGP5YYGPYJYPG5J5PPPPY?JYPGGGP5YYY?!!!!!!!!!!!!
// !!!!!!!!!!!!!7YPPP55YJJJJJ???????JJJJJYYY555PPPGGGGGGGGGPPG5JJYGGYJ5PP5JJJ?JYPGGGG5JYY?!!!!!!!!!!
// !!!!!!!!!!!!!YPPPYJJJJJYYYYYYYYYYYJJJJJJJJ?JJYY55PPPGGGGGGGGYJJ5GGJJ55JYP5YJ?J5GGGGPYJ5J!!!!!!!!!
// !!!!!!!!!!!!!75PPPPPPPP55555555555PPPPPPP5YYJJJJJJJYY55PPGGGPY?JPGPJ?JJ5PPPPY?JPGGPGPJJY!!!!!!!!!
// !!!!!!!!!!!!!!!YBB!G?!~^^^:::::^^^~!!?G!BBBGGGPP55YYJJJJYY5PGY??YGG5J?YPPPPPPY?YPGPPGPYY!!!!!!!!!
// !!!!!!!!!!!!!!!Y!!P!^:::::::::::::..:^~YB!!!!BBBBGGGPP55YYJYGY?JJPGPY?YPPPPPPPJJPGGPGPYY!!!!!!!!!
// !!!!!!!!!!!!!!?B!G!^:::::::::::::::^~!7?J5B!!!!!!!!BBBBBGGPPG5YJJ5GGPJJ5PPPPPP5JYGGPPPYY7!!!!!!!!
// !!!!!!!!!!!!!!?!!?~^^:::~~:::^^:::^^~7JYYY5GB!!!!!!!!!!!!BBBGG5JJJPGGYJJ5PPPPPPJJGGPPGYYY!!!!!!!!
// !!!!!!!!!!!!!!?B!P555JJ777:!7~~~7Y55YPP5PPP5G!!!!!!!!!!!!!!!BPPY?J5GGPJJ5PPPYPPJJPGGPGPY5?!!!!!!!
// !!!!!!!!!!!!!!?B!!P?J5PG57!J7?Y5P55YJJ?JJJY55GB!!!!!!!!!!!!!BGP5?JJPGPJJ5PPPJYP5JYGGPPG5YJ!!!!!!!
// !!!!!!!!!!!!!!?B!!BGG5G?JY^?Y55GBYJP!!PJ:7JY?JP!!!!!!!!!!!!!!BP5?JJGGG5?JPP5JYGPJYGGGPG5YP7!!!!!!
// !!!!!!!!!!!!!!?B!!!PJJ??J^^~Y555YJ77JJ?!7?Y?~~?G!!!!!!!!!!!!!BP5?JJGGG5?JPPY?YGPJJPGGPGPY57!!!!!!
// !!!!!!!!!!!!!!?B!!!5!~~?J:~?7!J55J?7~^~7J?!^^^!YB!!!!!!!!!!!!BP5?JJGGG5?JPPY?YGG5?5GGPPGYY?!!!!!!
// !!!!!!!!!!!!!!?B!!!G!^~7~:^~~7YPP?^:^7?7~^:^~!?J5B!!!!!!!!!!!BP5?JJGGG5?JPPY?YGG5?5GGPPGPY57!!!!!
// !!!!!!!!!!!!!!?!!!!!5~~!^^^7Y57!?5Y!^~~^^^~!?JJYYB!!!!!!!!!!!BP5?JJGGG5?JPG5JYGG5?5GGP5PGJYY!!!!!
// !!!!!!!!!!!!!!?B!!!!B?^::^~!?77?!?BY~^::^7?JYYYYYB!!!!!!!!!!!BP5?JJGGG5?JPGPYPGG5?5GGPYPGJJJ!!!!!
// !!!!!!!!!!!!!!!Y!!!!BJ~~~!?YPGGP5PGY7~^:~?JJYYYYYB!!!!!!!!!!!BP5?JJGGG5?JPGPYPGPJYPGGPYPGJJY!!!!!
// !!!!!!!!!!!!!!!J!!!!!BY?Y55Y5P55P5J7!7!^^!??JJYYYP!!!!!!!!!!!BP5?JJGGG5?JPGGPGGPJYGGP5JPPJJ5?!!!!
// !!!!!!!!!!!!!!!JB!!!!!P!??7!7777!!!!777!~!7?JJYY55G!!!!!!!!!!BP5JJJ5GG5J?YGGGGPJJ5GGPYJPPY?Y?!!!!
// !!!!!!!!!!!!!!!JGB!!!!P7YJYYJJJJ5555P57~!7??JYY5555B!!!!!!!!!BPPYJ?YPGG5JJ5GGG5J5GGP5JJPPJ?Y?!!!!
// !!!!!!!!!!!!!!75GPGGGBBPJ!~~^^^~!7!777~!7?JYYY555YYYPGB!!!!!!!BPY?JJ5GGP5JJPGG55GGGPYJ5PYJ?Y?!!!!
// !!!!!!!!!!!!!!7JPGPPGGGGP?77777???7!~^^7?JY5555YYJYY5YYPPPPPPPPPY?JJJPGPPJ?5GGGGGGP5?YP5JJ?Y?!!!!
// !!!!!!!!!!!!!!?5YGGGGGGPGP7^^~~~~~^^^~7JY5PGG5YJY55YYJ?JJJJJJY5PY?JJJY5PPYJJPGGGGGPYJ5PYJJ?Y?!!!!
// !!!!!!!!!!!!!!5PYPGGGGGPPGY7~^::::^~7JY5PGG5YYY55YYJ??77?????55PY?JJJ?YPP5?JPGGGGGPJYPYJJJ?Y?!!!!
// !!!!!!!!!!!!!7PG5YGGGGGPPGY77?????JJ5PGBGP55555YYJ??77777777J55PY?JJJJJ5P5JJYPGGGPYJ55JJJJJ5?!!!!
// !!!!!!!!!!!!!7PGPYGGGGGPPP7!!!7777!?PJ??777?JJYJ?7777777777?555PY?JJJJ?YPPY?JPGGGPY55J????JY7!!!!
// !!!!!!!!!!!!!YGGPYGGGGGGG57!!!!!!7YYJJ~:.::^~!7????777777JY555YPY?JJJJJYPPY?JPGGPP5P5555555Y!!!!!
// !!!!!!!!!!!!!YGGGYYGGGGGGGGYYY555PB5^?J7~:..::^^~!!777?JYYJ777JPY?JJJJJJ5PPJ?YGGPGGGGGGGGGGY!!!!!
// !!!!!!!!!!!!!YPGGP5PGP5PGGGGP5PPPPGB57~7J7!!!!!!!!!77?77~!7JYGBPY?JJJJJJJPPY?JPGGGGGPPPP5Y?!!!!!!
// !!!!!!!!!!!!!YPPGGGPYJ?Y55YY55GGGBBG5PP?!^::::::::::^!?JPPPP5GBP5JJJJJJJJYPPY?JPGGG5J??7!!!!!!!!7
// !!!!!!!!!!!!!YPGG5YJ??JY5PPGGGBBBGGGGPPBP555555555555PP55PPGGBBPPJ?JJJJJ?JPP5?JPGGGG5?!!!!7??YJYY
// !!!!!!!!!!!!?PG5YJ??JYPGGGPPGBBGPP5PGGPG55P5YYYYYYYY55PGGGGPPPBGPY?JJ?JJ?YPPPY5GGGGGGGP55YYYJYJYY
// !!!!!!!!!7JPG5JJ??JYPGGGGGGBBGPP5YY5PGBGPPPPPPPPPPPGGGPP55YY5PBBPP555YY55PPGPGGGGPPP55YJJJY55PPPP
// !!!!!!!7JPG5JJ?JJ5PGGPPGBBBBPP5YYYYPPGG55PPPPPPPPPPP55YYYYYYYYPBBBBGGPPGGPPPGGGPP5YJJYY55PPGGPPGG
// !!!!!!JPP5JJ?JJ5PGGPPGGBBBPP5YYYY5PPGG5Y5PP5YYYYYYYYYYYYYYYYYY5GBBG5JY55PPGGGPP5YY55PPPPPGGGGGGBB
// !!!!!YGPJ??JY5PGGPPPGBBBBPP5YYYY5PPGG55PPP5YYYYYY555YYYYY555PGGBP5JJ5PPPPGPPP5YY5PPP5PPGGGGBGGGGP
// !!!!YGPYJJY5PGGPPPPGBBBBPP5YYYYYPPPBPY5PPPP555PPPPP55PPGGGGPP5YYJJ5PPPPPPPP5YY5PPPPPPGGGBBBGP55YY

contract Enzos is ERC721A, DefaultOperatorFilterer, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) public publicBalance;   // internal balance of public mints to enforce limits

    bool public mintingIsActive = false;           // control if mints can proceed
    uint256 public constant maxSupply = 4444;      // total supply
    uint256 public constant maxMint = 44;           // max per mint (non-holders)
    uint256 public constant maxWallet = 44;         // max per wallet (non-holders)
    string public baseURI;                         // base URI of hosted IPFS assets
    string public _contractURI;                    // contract URI for details
    uint256 public tokenPrice = 7777700000000000;  // price per token in wei (0.0077777 ether)

    constructor() ERC721A("Enzos", "Enzos") {}

    // Show contract URI
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    // Withdraw contract balance to creator (mnemonic seed address 0)
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // Flip the minting from active or paused
    function toggleMinting() external onlyOwner {
        mintingIsActive = !mintingIsActive;
    }

    // Specify a new IPFS URI for token metadata
    function setBaseURI(string memory URI) external onlyOwner {
        baseURI = URI;
    }

    // Specify a new contract URI
    function setContractURI(string memory URI) external onlyOwner {
        _contractURI = URI;
    }

    // Internal mint function
    function _mintTokens(uint256 numberOfTokens) private {
        require(numberOfTokens > 0, "Must mint at least 1 token.");
        require(totalSupply().add(numberOfTokens) <= maxSupply, "Minting would exceed max supply.");

        // Mint number of tokens requested
        _safeMint(msg.sender, numberOfTokens);

        // Disable minting if max supply of tokens is reached
        if (totalSupply() == maxSupply) {
            mintingIsActive = false;
        }
    }

    // Mint public
    function mintPublic(uint256 numberOfTokens) external payable {
        require(mintingIsActive, "Minting is not active.");
        require(msg.sender == tx.origin, "Cannot mint from external contract.");
        require(numberOfTokens <= maxMint, "Cannot mint more than 44 during mint.");
        require(publicBalance[msg.sender].add(numberOfTokens) <= maxWallet, "Cannot mint more than 44 per wallet.");
        require(msg.value >= tokenPrice.mul(numberOfTokens), "Ether value sent is not correct.");

        _mintTokens(numberOfTokens);
        publicBalance[msg.sender] = publicBalance[msg.sender].add(numberOfTokens);
    }

    /*
     * Override the below functions from parent contracts
     */

    // Always return tokenURI, even if token doesn't exist yet
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    function transferFrom(address from, address to, uint256 tokenId) 
        public 
        override 
        onlyAllowedOperator(from) 
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) 
        public 
        override 
        onlyAllowedOperator(from) 
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}