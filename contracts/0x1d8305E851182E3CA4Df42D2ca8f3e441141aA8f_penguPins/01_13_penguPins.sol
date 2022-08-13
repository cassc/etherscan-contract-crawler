// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./VerifySignature.sol";

error FunctionNotSupported();
error SignatureNotValid();
error SignatureAlreadyUsed();
error ClaimNotOpen();

/*
                         %@@@@*  @@@  *#####
                   &@@@@@@@@ ,@@@@@@@@@  #########
              ,@@@@@@@@  #                  %. @@@@@@@
           &@@@@@@@@@@ @@@@@@@@@@@ @@@@@@@@@@@@ [email protected]@@@@@@@
         @@@@@@@@@@@. @@@@@@@@@@@@ @@@@@@@@@@@@@  @@@@@@@@@@
       ####       @  @@@@@@@@@@@@@ @@@@@@@@@@@@@@.       .&@@@
     ########. @@@@@@@@@@ @@@@@%#///#%@@@@@@ @@@@@@@@@@@  @@@@@.
    ########  @@@@@@@@@@  @@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@. @@@@@@
   ######### @@@@@@@@@@@ &@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@  @@@@@@
  %@@(       ,@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@,      &@
  @@@# @@@@@@@@@@@@ ,#####*                 . ,@@@@  %@@@@@@@@@@@@@@/
  @@@  @@@@@@@@@@@@ ##############  @@@@@@@@@@@@ ,@@@@.   @@@&  @@@@@@..#
  @@@ &@@@@@@@@@@@@ ##############  @@@@@@@@@@ @@@@@@@@@@@&   @@@@@@@@ #####
  @@@ @@@@@@@@@@@@@ ##############  @@@@@@@@ *@@@@@@@@@@  @@@. @@@@@@ ########
  @@        %@@@@@@ ##############  @@@@@@@ @@@@@@@@@@@ @@@@@@@ @@@&@ ####### /
  &&@@@@@  @@@@@@@@@@&*                    @@@@@@@@@@# @@@@@@@  &&&&&&& ##  @@@
  &&&&&@@  @@@@@@@@@@@@* @@@@@@@@@@@@@@@@* @@@    [email protected]% @@@@@@ &&&&&&&&&&& @@@@@@
  @&&&&&&  @@@@@@@@@@@@* @@@@@@@@@@@@@@@@ @@@@@@@@@@ @@@    &&&&&&&&&&&&& @@@@@
      &&&  &@@@@@@@@@@@* @@@@@@@@@@@@@@@@ @@@@@@@@@ @@@@@@    . #&&&&&&&& @@@@/
   (((  &&       /@@@@@* @@@@@@@@@@@@@@@,[email protected]@@@@@@@@ @@@@@& &&&&& &&&&&&     @@@
   (((* &&&&&&&&&/ @@@@@@@@@@@@@@@ @@@@@ .   [email protected]@@@@ @@@@@  &&&&& &&&&&&&& @@@@@
   (((( &&&&&&&&&/ &&&@@@@@@@@@@@@ @@@@@  ######### %@@@@  &&&&& &&&&&&&& @@@@@
     (( &&&&&&&&&/ &&&&&&&@@@@@@@@ @@@@@% ######### @@@@@%          &&&&& @@@.
           .&&&&&/ &&&&&&&&&&&&&&@ @@@@@@ ######### @@@@@@
                                           ######## @@@@@@
 * @notice Implementation of a "Soulbound Token" to mark community members. 
 * This is an ERC1155 NFT with modification to remove transferability.
 */

contract penguPins is ERC1155, VerifySignature {
    using Strings for uint256;

    mapping(uint256 => bool) nonceUsed;

    bool public claimPaused = true;

    string private baseURI;
    string private baseURISuffix;
    
    constructor(string memory _base, string memory _suffix) 
        ERC1155("")
        VerifySignature("penguPins-v1", msg.sender)
    {
        baseURI = _base; 
        baseURISuffix = _suffix;
    }

    function airdropPenguPin(
        uint256 id,
        address [] calldata holders
    ) external onlyOwner {
        for(uint i = 0; i < holders.length; i++){
            _mint(holders[i], id, 1, "");
        }
    }

    function claimPenguPinToWallet(
        address receiverWallet,
        uint256 id,
        uint256 nonce,
        bytes memory signature
    ) external {
        if(claimPaused) revert ClaimNotOpen();
        if(!_verify(receiverWallet, id, nonce, signature)) revert SignatureNotValid();
        if(nonceUsed[nonce]) revert SignatureAlreadyUsed();

        nonceUsed[nonce] = true;
        _mint(receiverWallet, id, 1, "");
    }

    function burnTruePengu(uint256 id) external {
        _burn(msg.sender, id, 1);
    }

    function adminBurnPenguPin(address holder, uint256 id) external onlyOwner {
        _burn(holder, id, 1);
    }

    function uri(uint256 id) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, id.toString(), baseURISuffix));
    }

    function setURI(string calldata _base, string calldata _suffix) external onlyOwner {
        baseURI = _base;
        baseURISuffix = _suffix;
    }

    function pause() external onlyOwner {
        claimPaused = true;
    }

    function unpause() external onlyOwner {
        claimPaused = false;
    }

    /*
     * All functions having to do with the transfer of the NFT's have been overridden.
     * Although the approval functions don't need to be overridden, there is no use 
     * for them, so I am overriding to save users gas in case they try and execute them.
     */
    function setApprovalForAll(
        address,
        bool
    ) public pure override {
        revert FunctionNotSupported();
    }

    function safeTransferFrom(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public pure override {
        revert FunctionNotSupported();
    }

    function safeBatchTransferFrom(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public pure override {
        revert FunctionNotSupported();
    }
}