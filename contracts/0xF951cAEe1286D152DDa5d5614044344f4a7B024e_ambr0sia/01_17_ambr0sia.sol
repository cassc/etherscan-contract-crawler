// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: yungwknd
/// @artist: ambr0sia

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "@0xsequence/sstore2/contracts/SSTORE2Map.sol";

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//                                                                          //
//        .                  .-.    .  _   *     _   .                      //
//               *          /   \     ((       _/ \       *    .            //
//             _    .   .--'\/\_ \     `      /    \  *    ___              //
//         *  / \_    _/ ^      \/\'__        /\/\  /\  __/   \ *           //
//           /    \  /    .'   _/  /  \  *' /    \/  \/ .`'\_/\   .         //
//      .   /\/\  /\/ :' __  ^/  ^/    `--./.'  ^  `-.\ _    _:\ _          //
//         /    \/  \  _/  \-' __/.' ^ _   \_   .'\   _/ \ .  __/ \         //
//       /\  .-   `. \/     \ / -.   _/ \ -. `_/   \ /    `._/  ^  \        //
//      /  `-.__ ^   / .-'.--'    . /    `--./ .-'  `-.  `-. `.  -  `.      //
//    @/        `.  / /      `-.   /  .-'   / .   .'   \    \  \  .-  \@    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~._=-_ambr0sia_-=_.~~~~~~~~~~~~~~~~~~~~~~~~    //
//                                                                          //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////
contract ambr0sia is AdminControl, ICreatorExtensionTokenURI {
    using Strings for uint;
    address private _creator;
    mapping(uint => uint) public sizes;
    struct Trait {
        string trait;
        string value;
    }

    struct TokenData {
        string name;
        string artist;
        string description;
        Trait[] traits;
    }
    mapping(uint => TokenData) public tokenDatas;
    mapping(uint => uint[]) public parts;
    function configure(address core) public adminRequired {
      _creator = core;
    }
    function configureToken(
        uint tokenId,
        string memory name,
        string memory artist,
        string memory description,
        string[] memory traits,
        string[] memory values
    ) public adminRequired {
        require(traits.length == values.length, "Invalid traits");
        tokenDatas[tokenId].name = name;
        tokenDatas[tokenId].artist = artist;
        tokenDatas[tokenId].description = description;
        for (uint i = 0; i < traits.length; i++) {
            tokenDatas[tokenId].traits.push(Trait(traits[i], values[i]));
        }
    }

    function reconfigureArt(uint tokenId, uint[] memory newParts) public adminRequired {
        delete parts[tokenId];
        for (uint i = 0; i < newParts.length; i++) {
            parts[tokenId].push(newParts[i]);
        }
    }

    function makeArt(uint tokenId, string calldata data, uint index) public adminRequired {
        SSTORE2Map.write(
            string(abi.encodePacked(
                tokenId.toString(),
                "/",
                index.toString()
            )),
            bytes(data)
        );
        parts[tokenId].push(index);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || AdminControl.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
    }

    function mint(address to) public adminRequired {
      IERC721CreatorCore(_creator).mintExtension(to);
    }

    function generateImage(uint tokenId) public view returns (string memory) {
        string memory image = "";

        for (uint i = 0; i < parts[tokenId].length; i++) {
            image = string(
                abi.encodePacked(
                    image,
                    SSTORE2Map.read(
                        string(abi.encodePacked(
                            tokenId.toString(),
                            "/",
                            parts[tokenId][i].toString()
                        ))
                    )
                )
            );
        }

        return image;
    }

    function generateAttributes(uint tokenId) public view returns (string memory) {
        string memory attributes = "";

        for (uint i = 0; i < tokenDatas[tokenId].traits.length; i++) {
            attributes = string(
                abi.encodePacked(
                    attributes,
                    _wrapTrait(
                        tokenDatas[tokenId].traits[i].trait,
                        tokenDatas[tokenId].traits[i].value
                    ),
                    i == tokenDatas[tokenId].traits.length-1 ? "" : ","
                )
            );
        }

        return attributes;
    }

    function _wrapTrait(string memory trait, string memory value) internal pure returns(string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"',
            trait,
            '","value":"',
            value,
            '"}'
        ));
    }

    function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
        require(creator == _creator, "Invalid token");
        TokenData memory tokenData = tokenDatas[tokenId];
        return string(abi.encodePacked('data:application/json;utf8,',
          '{"name":"',
            tokenData.name,
            '","created_by":"',
            tokenData.artist,
            '","description":"',
            tokenData.description,
            '","image":"',
            generateImage(tokenId),
            '","image_url":"',
            generateImage(tokenId),
            '","attributes":[',
            generateAttributes(tokenId),
            ']}'));
    }
}