//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

//                           STRAYLIGHT PROTOCOL v.01
//
//                                .         .
//                                  ., ... .,
//                                  \%%&%%&./
//                         ,,.      /@&&%&&&\     ,,
//                            *,   (##%&&%##)  .*.
//                              (,  (#%%%%.)   %,
//                               ,% (#(##(%.(/
//                                 %((#%%%##*
//                 ..**,*/***///*,..,#%%%%*..,*\\\***\*,**..
//                                   /%#%%
//                              /###(/%&%/(##%(,
//                           ,/    (%###%%&%,   **
//                         .#.    *@&%###%%&)     \\
//                        /       *&&%###%&@#       *.
//                      ,*         (%#%###%#?)       .*.
//                                 ./%%###%%#,
//                                  .,(((##,.
//
//

/// @title Minting
/// @notice Minting Contract for Straylight Protocoll
/// @author @brachlandberlin / plsdlr.net
/// @dev needs to be initalized after the main contract is deployed, uses Payment Splitter

interface interfaceStraylight {
    function publicmint(
        address mintTo,
        bytes12 rule,
        uint256 moves
    ) external;
}

contract Minting is Ownable {
    event Mint(address addr);

    //uint256 public constant mintPriceMainnet = 80000000000000000 wei;
    uint256 public mintPrice;
    bool initalized;
    interfaceStraylight public istraylight;
    bool paused = true;
    address private folia;
    address private ppp;
    uint256 private percentageFolia;

    constructor(
        address[] memory payees,
        uint256 _percentage,
        uint256 _MintPrice
    ) {
        mintPrice = _MintPrice;
        folia = payees[0];
        ppp = payees[1];
        percentageFolia = _percentage;
    }

    /// @dev public mint function
    /// @param mintTo the address the token should be minted to
    /// @param rule the 12 bytes rule defining the behavior of the turmite
    /// @param moves the number of inital moves
    function publicMint(
        address mintTo,
        bytes12 rule,
        uint256 moves
    ) external payable {
        require(paused != true, "MINTING PAUSED");
        require(initalized == true, "NOT INITALIZED");
        require(msg.value >= mintPrice, "INSUFFICIENT PAYMENT");

        uint256 foliaReceives = (msg.value * percentageFolia) / 100;
        uint256 artistReceives = msg.value - foliaReceives;

        (bool sent, ) = payable(folia).call{value: foliaReceives}("");
        require(sent, "Transfer failed.");

        (sent, ) = payable(ppp).call{value: artistReceives}("");
        require(sent, "Transfer failed.");

        istraylight.publicmint(mintTo, rule, moves);
        emit Mint(mintTo);
    }

    function pause() external onlyOwner {
        paused = true;
    }

    function unpause() external onlyOwner {
        paused = false;
    }

    /// @dev admin mint function - only callable from owner
    /// @param mintTo the address the token should be minted to
    /// @param rule the 12 bytes rule defining the behavior of the turmite
    /// @param moves the number of inital moves
    function adminMint(
        address mintTo,
        bytes12 rule,
        uint256 moves
    ) external onlyOwner {
        require(initalized == true, "NOT INITALIZED");
        istraylight.publicmint(mintTo, rule, moves);
        emit Mint(mintTo);
    }

    /// @dev set Staylight address
    /// @param _straylight address of the deployed contract
    function setStraylight(address _straylight) external onlyOwner {
        istraylight = interfaceStraylight(_straylight);
        initalized = true;
    }
}