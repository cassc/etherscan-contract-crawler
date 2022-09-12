// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.4;

import "./ETHWalkersMiami.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

abstract contract ETHWalkersMintPass is IERC721A {}

contract FreeAndFriendsMintV2 is Ownable, Pausable {
    using SafeMath for uint256;
    using Address for address;
    using Strings for uint256;
    mapping(address => uint8) public numberMinted;
    mapping(address => uint16) public originAddressNumberMinted;
    bool public friendsMintLive = false;
    ETHWalkersMiami private ewalksMiami;
    ETHWalkersMintPass private ewalksMintPass;

    constructor() {
        address EwalksMiamiAddress = 0xD56814B97396c658373A8032C5572957D123a49e;
        address ETHWalkersMintPassAddress = 0x7eCa22913103e4a9D92b1FfD892b86d1906093E5;
        ewalksMiami = ETHWalkersMiami(EwalksMiamiAddress);
        ewalksMintPass = ETHWalkersMintPass(ETHWalkersMintPassAddress);
    }

    function friendsAndFreeETHWalkersMiamiMint(uint8 numberOfTokens, address originAddressRedeemed) external whenNotPaused {
        require(friendsMintLive, "Free mint must be started");
        require(originAddressNumberMinted[originAddressRedeemed] + numberOfTokens < ((ewalksMiami.balanceOf(originAddressRedeemed) * 4) + (ewalksMintPass.balanceOf(originAddressRedeemed) * 12))+1, "Not enough left to claim");
        require(numberMinted[_msgSender()] + numberOfTokens <= 4, "Exceeds maximum per wallet");
        require(!isContract(_msgSender()), "I fight for the user! No contracts");
        require(ewalksMiami.totalSupply().add(numberOfTokens) <= ewalksMiami.totalSupplyMiami(), "Purchase exceeds max supply of ETH Walkers");

        ewalksMiami.controllerMint(_msgSender(), numberOfTokens);
        numberMinted[_msgSender()] += numberOfTokens;
        originAddressNumberMinted[originAddressRedeemed] += numberOfTokens;
    }

    function flipContractSaleState() public onlyOwner {
        friendsMintLive = !friendsMintLive;
    }

    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    function isContract(address _addr) private view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

}