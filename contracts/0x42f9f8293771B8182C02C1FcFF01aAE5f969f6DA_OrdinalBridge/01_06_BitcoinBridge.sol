// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC721A} from "erc721a/contracts/IERC721A.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract OrdinalBridge is Ownable, ReentrancyGuard {

    address public onTheEdgeOfOblivion = 0x48E934457D3082CD4068d10C80DaacE98378409f;
    mapping(uint256 => string) internal tokenToBTC;
    mapping(uint256 => string) internal tokenToOrdinalInscription;

    bool public locked;
    bool public bridgeIsEnabled;
    uint256 bridgeFee;


    // BRIDGE

    function burnForOrdinal(uint256 _tokenId, string memory _bitcoinAddress) payable public nonReentrant {
        require(bridgeIsEnabled, "Bridge is closed.");
        require(msg.value == bridgeFee, "Must send correct amount of Ether for the bridging fee.");
        require(tx.origin == msg.sender, "EOAs only.");
        require(msg.sender == IERC721A(onTheEdgeOfOblivion).ownerOf(_tokenId), "You must own the token you are trying to bridge.");
        tokenToBTC[_tokenId] = _bitcoinAddress;
        IERC721A(onTheEdgeOfOblivion).transferFrom(msg.sender, address(this), _tokenId);
    }


    // OWNER FUNCTIONS

    function withdrawTokens(uint256[] memory _tokenIds, address[] memory _addresses) public onlyOwner {
        require(!locked);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            IERC721A(onTheEdgeOfOblivion).transferFrom(address(this), _addresses[i] , _tokenIds[i]);
        }
    }

    function setInscription(uint256[] memory _tokenIds, string[] memory _inscriptions) public onlyOwner {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            tokenToOrdinalInscription[_tokenIds[i]] = _inscriptions[i];
        }
    }

    function lockTokensForever() public onlyOwner {
        locked = true;
    }

    function updateBridgeFee(uint256 _fee) public onlyOwner {
        bridgeFee = _fee;
    }

    function withdraw() public onlyOwner {
        uint256 b = address(this).balance;
        Address.sendValue(payable(owner()), b);
    }

    function setBridgeStatus(bool _bool) public onlyOwner {
        bridgeIsEnabled = _bool;
    }


    // READ FUNCTIONS

    function bitcoinAddressRequest(uint256 _tokenId) public view returns(string memory) {
        return tokenToBTC[_tokenId];
    }

    function tokenToInscription(uint256 _tokenId) public view returns(string memory) {
        return tokenToOrdinalInscription[_tokenId];
    }

    

}