// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ERC721A } from 'ERC721A/ERC721A.sol';
import { ICentralBroCommittee } from './interfaces/ICentralBroCommittee.sol';

contract CBDC721 is ERC721A, ICentralBroCommittee {

    mapping(address => uint256) private _receivedBlock;

    constructor() ERC721A("NFT", "NFT") {
    }

    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual override {
        if (_receivedBlock[to] == 0) {
            _receivedBlock[to] = block.number;
        }

        if(from != address(0) && balanceOf(from) == 1) {
            _receivedBlock[from] = 0;
        }
        
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function getReceivedBlock(address account) external view returns(uint256) {
        return _receivedBlock[account];
    }

    function mint() external {
        _mint(msg.sender, 1);
    }
}