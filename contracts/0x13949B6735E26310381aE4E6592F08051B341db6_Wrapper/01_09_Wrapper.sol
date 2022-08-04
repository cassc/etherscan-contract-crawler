//                                 ▄,
//                       ▄        █▌█▌
//                     ╓██      ,█▀█▌
//                    ▄██▌    ▄█▀' █▌          ███
//                    ▓█ ╙███▀▀└    ╙█µ       ╓█▀█─
//                  █▌               ▀█▄╓,,▄█▀ ╫▌
//                 █▌                   ╙╙╙'   █▌
//                ▐█                           ╟█    ▓█
//               ┌███▀▀▀▀▀▀▀██▄▄,               █▄ ╓██⌐
//               █▀            '╙▀▀█▄▄           ╙▀▀█▌
//              ╔▌                   ╙▀█▄,         ▐█
//              █─                       ╙██,     ┌█⌐
//             ▐█                           ▀█▄   █▀
//             ╟█                             ▀█ █▀
//            ╓█▀                              ╙█
//            █─    ▄█▀▀▀▀▀██▌   ▐█▄▄▄▄▄       ▄█
//            █     ╙▀▀▀▀   ╙╓▄▄ └▀└  ╓└▀█▄    ╙█
//            █▌            █▀└└▀█    ╙▀▀▀└    ▐█
//             █▌           ╙   j█µ            █▌
//             ╟▌       ,███▄▄,╓,▐█          ,█▀
//             █▌      ╒█─ ▄▄▄╠▄╙▀'          █▌
//             █⌐      ███▀╙,╙╙╙▀█▄          █
//             █▌      └┌█▀▀▀██▀  ██        ╟█
//             ╙█        ▀█▄▄▄▄▄▄█▀`       ╓█
//              ╙█▄         '└└└         ,█▀
//                ╙▀█▄   ▀▀▀▀▀▀██     ,▄█▀
//        __      __ ╙▀█▄,         ▄▓█▀'
//       / /      \ \    └╙▀▀▀██▀▀▀▀╙
//      | |_      _| |_ __ __ _ _ __  _ __   ___ _ __ 
//      | \ \ /\ / / | '__/ _` | '_ \| '_ \ / _ \ '__|
//      | |\ V  V /| | | | (_| | |_) | |_) |  __/ |   
//      | | \_/\_/ | |_|  \__,_| .__/| .__/ \___|_|   
//       \_\      /_/          | |   | | ғɪᴠᴇ ʟɪɴᴇs             
//                             |_|   |_|              
//
//               SPDX-License-Identifier: MIT
//              Written by Buzzy @ buzzybee.eth
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

error Rejected721();

contract Wrapper is Ownable, IERC721Receiver, ERC1155Holder {
    address public openstore;
    address public fivelines;
    address private _devon = 0xfCdB35c1105cA8EA01Df3B81A4570FF621817Cb8;
    address private _buzz = 0x816ae721F90d9cd5190d0385E7224C6798DaD52B;

    mapping(uint256 => bool) public wrapped;
    mapping(uint256 => uint256) public tokenMapping;

    uint256[] private tokens;

    constructor(
        address _openstore,
        address _fivelines,
        uint256[] memory openseaTokenIds,
        uint256[] memory fivelinesTokenIds
    ) {
        openstore = _openstore;
        fivelines = _fivelines;

        for (uint256 i = 0; i < openseaTokenIds.length; i++) {
            tokenMapping[openseaTokenIds[i]] = fivelinesTokenIds[i];
        }
    }

    function setTokenMappings(
        uint256[] calldata openseaTokenIds,
        uint256[] calldata fivelinesTokenIds
    ) public onlyOwner {
        for (uint256 i = 0; i < openseaTokenIds.length; i++) {
            tokenMapping[openseaTokenIds[i]] = fivelinesTokenIds[i];
        }
    }

    function setFiveLinesContractAddress(address _fivelines) public onlyOwner {
        fivelines = _fivelines;
    }

    function setOpenstoreContractAddress(address _openstore) public onlyOwner {
        openstore = _openstore;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public view override returns (bytes4) {
        require(operator == fivelines || from == _buzz, "Token is not from the Five Lines collection");
        require(!wrapped[tokenId], "Token is already wrapped");
        return this.onERC721Received.selector;
    }

    function _transferWrapped(address to, uint id) private {
        require(!wrapped[id], "Token is already wrapped");

        (bool success,) = fivelines.call(
            abi.encodeWithSignature(
                "safeTransferFrom(address,address,uint256)",
                address(this),
                to,
                id
            )
        );

        require(success, "Transfer failed");

        wrapped[id] = true;
    }

    function _handleOpenstoreReceive(address operator, uint256 id) private {
        require(tokenMapping[id] != 0, "Token ID not in mapping, is this a valid Five Lines token?");
        tokens.push(id);

        _transferWrapped(operator, tokenMapping[id]);
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes memory data
    ) public override returns (bytes4) {
        require(msg.sender == openstore, "ERC1155 not from Opensea's shared contract");
        _handleOpenstoreReceive(operator, id);
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) public override returns(bytes4) {
        require(msg.sender == openstore, "ERC1155 batch not from Opensea's shared contract");
        for (uint256 i; i < ids.length; i++) {
            _handleOpenstoreReceive(operator, ids[i]);
        }
        return this.onERC1155BatchReceived.selector;
    }

    function withdraw() public onlyOwner {
        while (tokens.length > 0) {
            uint256 token = tokens[tokens.length - 1];
            (bool success,) = openstore.call(
                abi.encodeWithSignature(
                    "safeTransferFrom(address,address,uint256,uint256,bytes)",
                    address(this),
                    _devon,
                    token,
                    1,
                    ""
                )
            );

            require(success, "Token transfer failed");

            tokens.pop();
        }
    }
}