// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import "../D4ASettings/D4ASettingsBaseStorage.sol";

library D4ACanvas {
    struct canvas_info {
        bytes32 project_id;
        uint256[] nft_tokens;
        uint256 nft_token_number;
        uint256 index;
        string canvas_uri;
        bool exist;
    }

    error D4AInsufficientEther(uint256 required);
    error D4ACanvasAlreadyExist(bytes32 canvas_id);

    event NewCanvas(bytes32 project_id, bytes32 canvas_id, string uri);

    function createCanvas(
        mapping(bytes32 => canvas_info) storage _allCanvases,
        address fee_pool,
        bytes32 _project_id,
        uint256 _project_start_drb,
        uint256 canvas_num,
        string memory _canvas_uri
    ) public returns (bytes32) {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();
        {
            ID4ADrb drb = l.drb;
            uint256 cur_round = drb.currentRound();
            require(cur_round >= _project_start_drb, "project not start yet");
        }

        {
            uint256 minimal = l.create_canvas_fee;
            require(minimal <= msg.value, "not enough ether to create canvas");
            if (msg.value < minimal) revert D4AInsufficientEther(minimal);

            SafeTransferLib.safeTransferETH(fee_pool, minimal);

            uint256 exchange = msg.value - minimal;
            if (exchange > 0) SafeTransferLib.safeTransferETH(msg.sender, exchange);
        }
        bytes32 canvas_id = keccak256(abi.encodePacked(block.number, msg.sender, msg.data, tx.origin));
        if (_allCanvases[canvas_id].exist) revert D4ACanvasAlreadyExist(canvas_id);

        {
            canvas_info storage ci = _allCanvases[canvas_id];
            ci.project_id = _project_id;
            ci.canvas_uri = _canvas_uri;
            ci.index = canvas_num + 1;
            l.owner_proxy.initOwnerOf(canvas_id, msg.sender);
            ci.exist = true;
        }
        emit NewCanvas(_project_id, canvas_id, _canvas_uri);
        return canvas_id;
    }

    function getCanvasNFTCount(mapping(bytes32 => canvas_info) storage _allCanvases, bytes32 _canvas_id)
        internal
        view
        returns (uint256)
    {
        canvas_info storage ci = _allCanvases[_canvas_id];
        return ci.nft_token_number;
    }

    function getTokenIDAt(mapping(bytes32 => canvas_info) storage _allCanvases, bytes32 _canvas_id, uint256 _index)
        internal
        view
        returns (uint256)
    {
        canvas_info storage ci = _allCanvases[_canvas_id];
        return ci.nft_tokens[_index];
    }

    function getCanvasURI(mapping(bytes32 => canvas_info) storage _allCanvases, bytes32 _canvas_id)
        internal
        view
        returns (string memory)
    {
        canvas_info storage ci = _allCanvases[_canvas_id];
        return ci.canvas_uri;
    }
}