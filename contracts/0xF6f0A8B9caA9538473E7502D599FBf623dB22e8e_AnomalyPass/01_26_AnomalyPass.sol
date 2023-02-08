///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                           //
//                                                                                                                           //
//                .----:     :--:     :--:    :------:    :----.     :----:     :----.     :--:   .---:     :---.            //
//                #@@@@%     *@@@-    [email protected]@#  :%@@@@@@@@%-  *@@@@#     %@@@@+    [email protected]@@@@#     #@@*    #@@%.   [email protected]@@#             //
//               :@@@%@@=    *@@@@-   [email protected]@#  %@@%=--=#@@%  *@@@@@-   [email protected]@@@@+    [email protected]@%@@@:    #@@*    .%@@#   #@@%.             //
//               *@@*[email protected]@%    *@@@@@:  [email protected]@#  @@@=    [email protected]@@. *@@*%@#   %@##@@+    %@@=*@@*    #@@*     :@@@= [email protected]@@:              //
//              [email protected]@@:[email protected]@@-   *@@%@@%: [email protected]@#  @@@=    [email protected]@@. *@@*[email protected]@- [email protected]@-#@@+   [email protected]@% :@@@.   #@@*      [email protected]@@[email protected]@@-               //
//              *@@#  [email protected]@#   *@@#:@@%[email protected]@#  @@@=    [email protected]@@. *@@* %@%.%@# #@@+   #@@+  #@@+   #@@*       [email protected]@@@@=                //
//             [email protected]@@-  [email protected]@@:  *@@# [email protected]@%*@@#  @@@=    [email protected]@@. *@@* [email protected]@#@@: #@@+  [email protected]@@.  [email protected]@@.  #@@*        #@@@*                 //
//             [email protected]@@%#  #@@*  *@@#  [email protected]@@@@#  @@@=    [email protected]@@. *@@*  #@@@*  #@@+  #@@@%+  %@@=  #@@*        :@@@:                 //
//             %@@#**. [email protected]@@: *@@#   [email protected]@@@#  @@@*    [email protected]@@. *@@*  :+++.  #@@+ :@@@##*  [email protected]@%  #@@*        :@@@:                 //
//            [email protected]@@.     %@@* *@@#    [email protected]@@#  [email protected]@@@@@@@@@*  *@@*         #@@+ *@@%     [email protected]@@= #@@@@@@@@@: :@@@:                 //
//            *##+      -### =##+     +##*   :+######*-   +##+         +##= ###-      +##* *#########: :###.                 //
//                                                                                                                           //
//                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "./ERC1155MultiSupplies.sol";
import "./MultiMint.sol";
import "./Withdraw.sol";
import "./ExternalContracts.sol";
import "./Collection.sol";

// @author: miinded.com

contract AnomalyPass is ERC1155Multi, MultiMint, ExternalContracts, Collection, Withdraw {
    using BitMaps for BitMaps.BitMap;

    mapping(uint256 => BitMaps.BitMap) private tokensFlagged;

    constructor(string memory baseURI, address _collectionAddress, Part[] memory _parts) ERC1155(baseURI) {
        Collection.setCollection(_collectionAddress);

        ERC1155Multi.setSupply(1, Supply(1127, 0, 0, false, true));

        MultiMint.setMint("HOLDERS", Mint(1675810800, 1675897200, 0, 100, 0, false, true));
        MultiMint.setMint("PUBLIC", Mint(1675897200, 2654875480, 3, 3, 0.01 ether, false, true));

        for(uint256 i = 0; i < _parts.length; i++){
            Withdraw.withdrawAdd(_parts[i]);
        }
    }

    function MintPassHolders(uint256 _id, uint256[] memory _tokenIds) public payable notSoldOut(_id, uint64(_tokenIds.length)) canMint("HOLDERS", _tokenIds.length) nonReentrant {
        require(_tokenIds.length > 0, "Missing _tokenIds");

        for(uint256 i = 0; i < _tokenIds.length; i++){
            require(isTokenClaimed(_id, _tokenIds[i]) == false, "tokenId already flagged");
            tokensFlagged[_id].set(_tokenIds[i]);

            require(IERC721(Collection.contractAddress).ownerOf(_tokenIds[i]) == _msgSender(), "Bad owner of the tokenId");
        }

        _mintTokens(_msgSender(), _id, uint64(_tokenIds.length));
    }

    function MintPassPublic(uint256 _id, uint64 _count) public payable notSoldOut(_id, _count) canMint("PUBLIC", uint256(_count)) nonReentrant {
        _mintTokens(_msgSender(), _id, _count);
    }

    function ExternalBurn(address _to, uint256 _id, uint64 _count) public externalContract {
        _burnInternal(_to, _id, _count);
    }

    function isTokenClaimed(uint256 _id, uint256 _tokenId) public view returns(bool){
        return tokensFlagged[_id].get(_tokenId);
    }
    function isTokensClaimed(uint256 _id, uint256[] memory _tokenIds) public view returns(bool[] memory){
        bool[] memory claimed = new bool[](_tokenIds.length);
        for(uint256 i = 0; i < _tokenIds.length; i++){
            claimed[i] = isTokenClaimed(_id, _tokenIds[i]);
        }
        return claimed;
    }
}