/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!???!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~?GPG?~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~YPPPY~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~?PPPPP?~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~YPPPPPY~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!5PPPPP5!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~?Y55555PPPPPPP55555Y?~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~7PPPPPPPPPPPPPPPPPPPPP7~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^?PPPPPPPPPPPPPPPPPPPPP7~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~!7???YPPPPPPPPPPPPPPPPPPPPPYJ???7!~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~75PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP57~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!5PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPP5J?7?JYPPPPPPPPYJ?7?J5PPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPY^.      :?PPPP?:      .^YPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPJ    :~:    !PP!    :~:    JPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPP~   [email protected]#^   .PP.   ^#@G.   ^PPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPP?    ^!~    ~PP~    ~!^    ?PPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPYJJJJJJJJJYPPPPJJJJJJJJJJYPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPGBPPPPPPBGPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPBBBBBBBBPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPGGPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~5PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~75PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP57~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~!?Y5PPPPPPPPPPPPPPPPPPPPPPPPPPPP5Y?~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!7?JJJJYY555PGGGGG5YYYJ????7!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^.     . ^&B77G&^       .^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^          ^.   :..        ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.     :      .. :^^^ .     .~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^^:.:              :.:^^^^^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~5PPP?~!!!!.!!77!!:!!!!~?PPP5~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~5PPP?~~^^^.^^^^^^.^^^~~JPPP5~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~5PPPY~:              :~5PPP5~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~5PPPP?:      .:      :?PPPP5~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~5PP5!!:      ^^      :!!5PP5~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!777~~:      ^^      :~~777!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~:      ^^      ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~:      ^:      ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^::... ^: ....:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!77?Y#@&BBG!~~!GGG&@#Y?77~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^:~?JY55555YY!~~!Y555555YJ?~:^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^~~~~^^^^^^^^^^^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {ERC721A} from "@ERC721A/ERC721A.sol";
import {Ownable} from "@openzeppelin/access/Ownable.sol";

contract SGVMToken is ERC721A, Ownable {
    // private

    string private baseURI =
        "ipfs://QmQZpQQDPHf77GaoDPi2nuNpEGqLJQUvZVmtHTB3SfAFeX/";

    address private constant sGvmCorporate =
        0xD487291e9b1a37dF24dF39A240C3d3bf2653f361;

    address private constant sGvmFork =
        0xD70d67d06554f1Dc3c26482BFdDc720C3e79d386;

    // public

    uint256 public constant maxSupply = 1337;

    bool public corporateDidClaim = false;
    uint256 public constant forkClaimAmount = 47;
    uint256 public constant corporateClaimAmountA = 444;
    uint256 public constant corporateClaimAmountB = 846;

    constructor() ERC721A("Sudo Grindset Value Menu", "SGVM") {}

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function corporateClaim() external onlyOwner {
        require(
            !corporateDidClaim,
            "Corporate has already claimed their SGVMs"
        );

        _safeMint(sGvmCorporate, corporateClaimAmountA);
        _safeMint(sGvmFork, forkClaimAmount);
        _safeMint(sGvmCorporate, corporateClaimAmountB);

        corporateDidClaim = true;
    }
}