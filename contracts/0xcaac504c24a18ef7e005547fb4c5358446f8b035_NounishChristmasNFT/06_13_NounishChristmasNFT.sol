// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {WhiteElephantNFT, ERC721} from "./base/WhiteElephantNFT.sol";
import {WhiteElephant} from "./base/WhiteElephant.sol";

import {NounishChristmasMetadata} from "./NounishChristmasMetadata.sol";

contract NounishChristmasNFT is WhiteElephantNFT {
    uint256 private _nonce;
    WhiteElephant public whiteElephant;
    NounishChristmasMetadata public metadata;

    constructor(NounishChristmasMetadata _metadata) ERC721("Nounish White Elephant Christmas", "NWEC") {
        whiteElephant = WhiteElephant(msg.sender);
        metadata = _metadata;
    }

    function mint(address to) external override returns (uint256 id) {
        require(msg.sender == address(whiteElephant), "FORBIDDEN");

        _mint(to, (id = _nonce++));
        require(id < 1 << 64, "MAX_MINT");

        bytes32 h = keccak256(abi.encode(id, to, block.timestamp));
        _nftInfo[id].character = uint8(h[0]) % 32 + 1;
        _nftInfo[id].tint = uint8(h[1]) % 12 + 1;
        _nftInfo[id].backgroundColor = uint8(h[2]) % 4 + 1;
        _nftInfo[id].noggleType = uint8(h[3]) % 3 + 1;
        _nftInfo[id].noggleColor = uint8(h[4]) % 4 + 1;
    }

    /// @dev steal should be guarded as an owner/admin function
    function steal(address from, address to, uint256 id) external override {
        require(msg.sender == address(whiteElephant), "FORBIDDEN");

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _nftInfo[id].owner = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function transferFrom(address from, address to, uint256 id) public override {
        require(whiteElephant.state(whiteElephant.tokenGameID(id)).gameOver, "GAME_IN_PROGRESS");
        super.transferFrom(from, to, id);
    }

    function updateMetadata(NounishChristmasMetadata _metadata) external {
        require(msg.sender == address(whiteElephant), "FORBIDDEN");

        metadata = _metadata;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return metadata.tokenURI(id, whiteElephant.tokenGameID(id), _nftInfo[id]);
    }

    function nftInfo(uint256 id) public view returns (Info memory) {
        return _nftInfo[id];
    }
}