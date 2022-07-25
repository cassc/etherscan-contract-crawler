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

// @author: miinded.com

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IStocking.sol";
import "../libs/MerkleProof.sol";
import "../libs/Pause.sol";

contract SneakerHeadsSkins is ERC1155, MerkleProofVerify, Pause, ReentrancyGuard{

    IStocking public sneakerHeads;

    struct Limit {
        uint256 timestamp;
        uint256 maxIds;
        bool valid;
    }

    bool public canBeListed = false;
    // tokenId => level => rewarded
    mapping(uint256 => mapping(uint256 => bool)) rewarded;
    // level => Limit
    mapping(uint256 => Limit) public limits;

    constructor(string memory baseURI, address _sneakerHeads) ERC1155(baseURI){
        setSneakerHeads(_sneakerHeads);
        reserve();
    }

    function reward(
        bytes32[] memory _proof,
        uint256 _tokenId,
        uint256 _level,
        uint256 _id
    ) public merkleVerify(_proof, keccak256(abi.encodePacked(_tokenId, _level, _id))) notPaused nonReentrant {

        uint256 level = uint256(sneakerHeads.stockingLevel(_tokenId));

        require(_msgSender() == sneakerHeads.ownerOf(_tokenId), "Not owner of the Token");
        require(_level <= level && _level > 0, "Token level too low");
        require(isRewarded(_tokenId, _level) == false, "Token already rewarded for this level");
        require(limits[_level].valid, "Reward not available");

        rewarded[_tokenId][_level] = true;

        uint256 id = block.timestamp > limits[_level].timestamp ? _id + limits[_level].maxIds : _id;

        _mint(_msgSender(), id, 1, "");
    }

    function burn(uint256 _tokenId, uint256 _count) public {
        require(balanceOf(_msgSender(), _tokenId) >= _count, "Not enough tokens");

        _burn(_msgSender(), _tokenId, _count);
    }

    function reserve() internal {
        _mint(_msgSender(), 1, 1, "");
        burn(1,1);
    }

    function walletOfOwner(address _wallet, uint256 _maxId) public view returns(uint256[] memory){
        uint256[] memory ids = new uint256[](_maxId + 1);
        for(uint256 id = 0; id < _maxId; id++){
            ids[id] = balanceOf(_wallet, id);
        }
        return ids;
    }

    function isRewarded(uint256 _tokenId, uint256 _level) public view returns(bool){
        return rewarded[_tokenId][_level];
    }

    function setBaseUri(string memory baseURI) public onlyOwnerOrAdmins{
        _setURI(baseURI);
    }
    function setSneakerHeads(address _sneakerHeads) public onlyOwnerOrAdmins{
        sneakerHeads = IStocking(_sneakerHeads);
    }
    function setCanBeListed(bool _toggle) public onlyOwnerOrAdmins{
        canBeListed = _toggle;
    }
    function setLimit(uint256 _level, Limit memory _limit) public onlyOwnerOrAdmins{
        limits[_level] = _limit;
    }

    function setApprovalForAll(address operator, bool approved) public override {
        require(canBeListed == true, "This collection can't be listed");
        super.setApprovalForAll(operator, approved);
    }
    function isApprovedForAll(address account, address operator) public view override returns (bool) {
        return canBeListed && super.isApprovedForAll(account, operator);
    }

}