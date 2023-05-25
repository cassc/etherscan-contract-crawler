// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                            //
//                                                                                                                                            //
//                                                                                                                                            //
//                 -+**+-   +++: :+++.+++++++  ++++++  =+++ .+++==++++++-+++++-       :+++: +++=:++++++= .+++++=  +++++-     -+**+-           //
//               [email protected]@@@@@@# [email protected]@@: @@@**@@@@@@= *@@@@@+ [email protected]@@+:%@@%[email protected]@@@@@%#@@@@@@@:    [email protected]@@# [email protected]@@[email protected]@@@@@@. %@@@@@: [email protected]@@@@@%. -%@@@@@@#          //
//              [email protected]@@# [email protected]@@[email protected]@@@ *@@%[email protected]@@*... [email protected]@@@@@ [email protected]@@#[email protected]@@*.%@@%:[email protected]@@[email protected]@@#    #@@@.:@@@+#@@@-... %@@@@@# [email protected]@@+.%@@=:@@@# [email protected]@@          //
//              %@@@[email protected]@@*@@@@*[email protected]@@[email protected]@@%    [email protected]@%%@@= %@@@*@@@= #@@@:  [email protected]@@# [email protected]@@=   [email protected]@@- @@@#[email protected]@@+    #@@#@@@[email protected]@@# :@@@-*@@@[email protected]@@=          //
//              #@@@#    %@@@@[email protected]@@+#@@@-:. [email protected]@%[email protected]@@ [email protected]@@@@@@: [email protected]@@*:: #@@@[email protected]@@#   [email protected]@@#:#@@@[email protected]@@@::  *@@*#@@* #@@@  @@@% *@@@#               //
//              [email protected]@@@:  [email protected]@@@@#@@#[email protected]@@@@@::@@@.%@@=:@@@@@@%. :@@@@@@[email protected]@@*=%@@*    %@@@@@@@@=%@@@@@% *@@#:@@@[email protected]@@: #@@@- :@@@@:              //
//               %@@@# [email protected]@@[email protected]@@@@[email protected]@@#[email protected]@@[email protected]@@[email protected]@@@@@@.  %@@@[email protected]@@@@@@*:    *@@@+#@@@#*@@@[email protected]@@-#@@+:@@@+ [email protected]@@*   #@@@*              //
//           [email protected]@@@[email protected]@@=*@@@@[email protected]@@%   [email protected]@@@@@@@=*@@@%@@@  *@@@-  [email protected]@@#%@@#     [email protected]@@= %@@@[email protected]@@+   [email protected]@@@@@@@[email protected]@@% :@@@%+==::@@@%              //
//          *@@% :@@@%*@@# @@@@+#@@@:  .%@@#[email protected]@@%[email protected]@@=%@@% [email protected]@@*   #@@@:@@@+    [email protected]@@# *@@@[email protected]@@%   [email protected]@@+*@@@=#@@@:.%@@#[email protected]@@ [email protected]@@#              //
//          %@@#=%@@@[email protected]@@.:@@@#[email protected]@@@##=%@@# [email protected]@@[email protected]@@# @@@*:@@@@##*[email protected]@@[email protected]@@-    %@@@[email protected]@@+#@@@%##[email protected]@@- #@@%[email protected]@@%#@@@+ *@@%=%@@@.              //
//          .#@@@@%=:@@@= [email protected]@@[email protected]@@@@@%%@@%  @@@%#@@@ [email protected]@@+%@@@@@@[email protected]@@# #@@@    *@@@- @@@#[email protected]@@@@@%@@@= [email protected]@@*@@@@@%*-   .*@@@@%+                //
//                                                                                                                                            //
//                                                                                                                                            //
//                                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

import "../libs/Withdraw.sol";
import "../libs/MerkleProof.sol";
import "../libs/SingleMint.sol";
import "./Stocking.sol";
import "../libs/ERC721Mint.sol";

contract SneakerHeads is ERC721Mint, Stocking, SingleMint, MerkleProofVerify, Withdraw {

    /**
    @notice Mint struct for manage the waiting list, only the sales dates are used.
    */
    Mint public waiting;

    /**
    @notice Set default value au the collection.
    */
    constructor(
        string memory baseURI
    )
        ERC721("SneakerHeads", "SNKH")
        Withdraw()
    {
        setMaxSupply(5_000);
        setReserve(50);
        setBaseUri(baseURI);
        setStartAt(1);

        setMint(Mint(1655575200, 2097439200, 2, 2, 0.25 ether, false));
        waiting = Mint(1655582400, 2097439200, 1, 1, 0.25 ether, false);

        withdrawAdd(Part(0xb224811F71c803af1762CC6AEfd995edbfAFBD42, 10));
        withdrawAdd(Part(0x025B188919DC10b42aE5bC85134300628F834E96, 90));
    }

    /**
    @notice Mint for all non-holder with MerkleTree validation
    @dev _type: 1 OG, 2 WL, 3 RAFFLE, 4 WAITING
         _type need to be same like in the MerkleTree.
         _count is used only for OG whitelisted, for all others it is 1
    */
    function mint(
        uint256 _type,
        bytes32[] memory _proof,
        uint16 _count
    ) public payable
        notSoldOut(_count)
        canMint(_count)
        merkleVerify(_proof, keccak256(abi.encodePacked(_msgSender(), _type)))
        nonReentrant
    {
        require(_type > 0 && _type <= 4, "Bad _type value");

        uint256 max = _type == 1 ? 2 : 1;

        if(_type == 4){
            require(waitingIsOpen(), "Waiting list not opened");
        }

        require(balance[_msgSender()] <= max, "Max per wallet limit");

        _mintTokens(_msgSender(), _count);
    }

    /**
    @dev Required override to select the correct baseTokenURI.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return getBaseTokenURI();
    }

    /**
    @notice Change the values of the global Mint struct waiting
    @dev Only sales dates are used.
     */
    function waitingIsOpen() public view returns(bool) {
        return waiting.start > 0 && uint64(block.timestamp) >= waiting.start && uint64(block.timestamp) <= waiting.end  && !waiting.paused;
    }

    /**
    @notice Change the values of the global Mint struct waiting
    @dev Only sales dates are used.
     */
    function setWaitingMint(Mint memory _waiting) public onlyOwnerOrAdmins {
        waiting = _waiting;
    }

    /**
    @notice Block transfers while stocking.
    @dev from and to are not used
     */
    function _beforeTokenTransfer(address, address, uint256 tokenId) internal view override {
        require(stocking[tokenId].started == 0 || stockingTransfer == true,"Token Stocking");
    }

}