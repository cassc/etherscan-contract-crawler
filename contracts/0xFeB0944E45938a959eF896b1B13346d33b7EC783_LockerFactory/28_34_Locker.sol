// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

//         .-""-.
//        / .--. \
//       / /    \ \
//       | |    | |
//       | |.-""-.|
//      ///`.::::.`\
//     ||| ::/  \:: ;
//     ||; ::\__/:: ;
//      \\\ '::::' /
//       `=':-..-'`
//    https://duo.cash

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";


contract Locker is ERC1155Holder, ERC721Holder{

    // Accept ETH deposits 
    receive() payable external {}

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC721Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}