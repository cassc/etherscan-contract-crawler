// SPDX-License-Identifier: MIT
//  @@@@@@@@@@@@@@@@@@@@@@@@@        &   &@@@@@@@@@@@@@@@@@@@@@@@@@@    #@@@@     #@@@@@@@,       &@@@@@@@@@@@@@@@@@@@@@@@@@@/       /@@@@@@@/             &
//  %%%%%%%%%%%%%%%%%%%%%%&@@@&    @@@   #%%%%%%%%%&@@@%%%%%%%%%%%    &@@@@    &@@@@@&&@@@@@@.    #%%%%%%%%%%%%%%%%%%%%%%%%%%*    /@@@@@@%@@@@@@(          &@@.
//                         @@@@   #@@@             ,@@@             &@@@&    @@@@%        (@@@/                                  %@@@,        @@@@#        &@@#
//  %@@@@@@@@@@@@@@@@@@@@@@@@@    #@@@             ,@@@           @@@@%   [email protected]@@@#           %@@&   *@@@@@@@@@@@@@@@@@@@@@@@@@@/  [email protected]@@*           @@@@%      &@@#
//  @@@*                   /@@@   #@@@             ,@@@         @@@@#   [email protected]@@@(             %@@&   &@@&                          [email protected]@@*             &@@@&    &@@#
//   @@,  [email protected]@@@@@@@@@@@@@@@@@@&   #@@@             ,@@@      [email protected]@@@#   ,@@@@/               %@@&   #@@@@@@@@@@@@@@@@@@@@@@@@@@/  [email protected]@@*               %@@@@  &@@#
//     ,  [email protected]@@@@@@@@@@@@@@@@,     #@@@             ,@@@    [email protected]@@@(   *@@@@*                 %@@&     #@@@@@@@@@@@@@@@@@@@@@@@@/  [email protected]@@*                 #@@@@&@@#
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "erc721a/contracts/ERC721A.sol";

contract AVATAR is
    ERC721A,
    ERC721AQueryable,
    ERC721ABurnable,
    Ownable,
    ReentrancyGuard
{
    string private _baseURIextended;
    uint256 public constant MAX_SUPPLY = 501;
    uint256 public teamMintedAmount;

    address evoAddress;

    constructor() ERC721A("BITMEN", "BITMEN") {}

    // ============ PUBLIC FUNCTIONS FOR MINTING ============
    function mintTransfer(address to) public returns (uint256) {
        require(msg.sender == evoAddress, "Not authorized");
        _safeMint(to, 1);
        return 0;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    // ============ OWNER-ONLY ADMIN FUNCTIONS ============
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTokens(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    function setEvoAddress(address newAddress) public onlyOwner {
        evoAddress = newAddress;
    }
}