// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IQControl.sol";


//
//                             ...::^^~~~~~~~~^^::..
//                       .:^~7?JY5555PPPPPPPPPP555YJ?!~:.
//                    ..~J5PPPPPPP5555555555555555PPPPP5J!:.
//                    .:!5P5555555555555555555555555555PPPY7^..
//                    .:~?PP555555555555555555555555555555PPY!:.
//                     .:~?P555YYYYYJJJJJYY55555555555555555PY!:.
//                      .:^77777!~^^^::::^^~7?YPP5555555555555?~:.
//                        .......           .^!JPP555555555555J!:.
//                                           .^7PP555555555555J~:.
//                                          .:~JG555555555555Y7~:.
//                                         .:~JPP55555555555Y?~:.
//                                        .:75P555555555555J?~:.
//                                      .:!YPP55555555555YJ!^:.
//                                    .:7YPP55555555555YJ7~:.
//                                  .:!YPP55555555555YJ7~:.
//                                .:^JPP55555555555Y?7^:.
//                               .:~5P55555555555YJ7^:.
//                              .:~5P55555555555Y?~:.
//                              .^JG55555555555Y7~:.
//                             .:~YP55555555555?~:.
//                             .:~YP555555555557^.
//                             .:^?YYY555555YYJ!^.
//                              ..:^~!!!!!!!!~^:.
//                                .:^~!7777!^:..
//                             .:!J55PPPPPPP55J!:.
//                           .:~YPPP5555555555PPJ~:.
//                          .:~YG555555555555555PY~:.
//                          .^!PP5555555555555555Y7^.
//                          .:!YP5555555555555555J!^.
//                           .^!Y55555555555555YJ7^:.
//                            .:~7JY55555555YYJ7!^.
//                              .:^~!7?????7!~^:..
//                                  ...:::....
//

contract Q is ERC721, ERC721Enumerable, ERC721Burnable, ReentrancyGuard, Ownable {
    event MintedEvent(uint8 numOfTokens);
    event MintedReservedEvent(uint8 numOfTokens);

    IQControl qControl;

    constructor() ERC721(unicode"Question ❓ Everything", unicode"❓") {
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        return qControl.tokenURI(tokenId);

    }

    function setControl(address control) external onlyOwner {
        qControl = IQControl(control);
    }

    /**
    * @notice Cost is free! Tats are for life
    * @notice Once you mint this shit it's stuck in your wallet FOREVER (maybe). Pledge your allegiance ❓
    */
    function mintTattoo(uint8 numOfTokens) external nonReentrant {
        qControl.canMint(totalSupply(), numOfTokens);

        mint(msg.sender, numOfTokens);
        emit MintedEvent(numOfTokens);
    }

    /**
    * @notice Tip me if you like this project ❤️
    */
    function tipDeveloper() external payable {
    }

    function mintForVillian(address receiver, uint8 numOfTokens) external nonReentrant onlyOwner {
        require(qControl.getNumReserved() - numOfTokens >= 0, "Exceed reserved");

        mint(receiver, numOfTokens);

        qControl.setReserved(qControl.getNumReserved() - numOfTokens);
        emit MintedReservedEvent(numOfTokens);
    }

    function maxSupply() external returns (uint) {
        return qControl.maxSupply();
    }

    function maxMintsPerWallet() external returns (uint) {
        return qControl.maxMintsPerWallet();
    }

    function withdraw() public onlyOwner {
        uint256 _balance = address(this).balance;
        require(payable(msg.sender).send(_balance));
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        qControl.controlBeforeTokenTransfer(from, to, tokenId);
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function mint(address _receiver, uint8 num) private {
        for (uint8 i; i < num; i++) {
            uint tokenId = totalSupply();
            _safeMint(_receiver, tokenId);
            qControl.minted(_receiver, tokenId);
        }
    }

}