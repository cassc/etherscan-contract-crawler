// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/*
* https://twitter.com/HackoorsNFT
*
*                                             ..?!~~~?..
*                                          :GPY^..   ^~#BP:
*                                        ^[email protected]@@P     .^#@@#&B^
*                                      .B&&&B~      :B&@@@@@&B.
*                                     !5?~!:  .    ::^^#@@#7^J5!
*                                   :&@@&PY!.:^.   ::::#@B!.~P&@&:
*                                  ^&G5P7:::^:.    ..::J7:..:^~7B&^
*                                  5G^::.:.                   :5&@5
*                                 [email protected]^..    :??????????????:     [email protected]
*                                 [email protected]!. ~B&&@@@@@@@@@@@@@@@@&&#?^^[email protected]?
*                                 [email protected]&&&@@@@@@@@@@@@@@@@@@@@@@@@@&&@?
*                                 [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@?
*                                 [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@?
*                                 [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@?
*                                 ^#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#^
*                            :.7::~5&@@@@@@@@@@@@@@@@@@@@@@@@@@@@&5~::7.:
*                          :??.     :Y&@@@@@@@@@@@@@@@@@@@@@@@@&Y:     .??:
*                        ^?^          :^^[email protected]@@@@@@@@@@@@@@@@@@#J:          ^?^
*                       ~?   ..   ...   .:[email protected]@@@@@@@@@@@@@@@#7:   ...  ..7.  ?~
*                      !5.  [email protected]&Y:   :::.75P#@@@&&&&&&&&@@@@#Y7.:::   :#&@7  ~#!
*                     !J:::[email protected]@@&5^..^:::[email protected]@@&~^^^^^^~&@@@B?:::^..^5&@@G~:...?!
*                    7!  .:[email protected]@@@&&&&5YYJYB&@&#JJJJJJ#&@&BYJYY5&&&&@@@@PY!^:  !7
*                   ~?.!YJG&==============================================&&&B!.?~
*                  :&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@P~!~!B&:
*                  JGP&@@&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&@@&PGJ
*                 [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@57P5GB77?
*                ~J~^^:::[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@5.:.:!P~J~
*                JG&P~^:::[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B!::^[email protected]&GJ
*                [email protected]@@&&G57:[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Y:7B&@@@@@J
*                ~&@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@&~
*                  ?BB#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#BB?
*                      ^:::[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@J:::^
*                           [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@~
*                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
*/

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Puzzle1 {

    bytes32 constant ANSWERHASH = 0x5a179a9544e458d768dc16529d9d04e538d7aa4f3c8398c66aa09db48fe216e6;
    IERC721 constant HACKOORS = IERC721(0x72f7DBe108257e47370869cDb73D18680E4CFA83);
    IERC721 constant HMDT = IERC721(0xdf0F0A5508Aa4f506e5bDC8C45C8879E6E80d3e4);

    constructor() payable {}

    error NoEligibleNFTsOwned();
    error WrongAnswer();

    function claim(string calldata answer) external {

        _checkNFTHoldings();

        if (keccak256(abi.encode(answer)) != ANSWERHASH) revert WrongAnswer();
        payable(msg.sender).transfer(address(this).balance);
    }

    function _checkNFTHoldings() internal view {
        if (HACKOORS.balanceOf(msg.sender) == 0 && HMDT.balanceOf(msg.sender) == 0) revert NoEligibleNFTsOwned();
    }

    receive() external payable {}
}