// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ERC721SeaDrop } from "./ERC721SeaDrop.sol";

contract MoonieMooGenesis is ERC721SeaDrop {
  address[] allowedSeaDrop = [0x00005EA00Ac477B1030CE78506496e8C2dE24bf5];
  
  constructor() ERC721SeaDrop("Moonie Moo Genesis", "MMGEN", allowedSeaDrop) {}

    function _batchedMint(address _to, uint256 _numberOfTokens) internal {
        uint256 batchSize = 25;
        uint256 batches = _numberOfTokens / batchSize;
        if (batches > 0) {
            for (uint256 i; i < batches; ) {
                _safeMint(_to, batchSize);
                unchecked {
                    ++i;
                }
            }
            if (_numberOfTokens % batchSize > 0) {
                _safeMint(_to, _numberOfTokens % batchSize);
            }
        } else {
            _safeMint(_to, _numberOfTokens);
        }
    }

    function ownerMint(address _to, uint256 _numberOfTokens)
        external
        onlyOwner
    {
        _batchedMint(_to, _numberOfTokens);
    }

    struct Airdrop {
        address wallet;
        uint256 numberOfTokens;
    }

    function airdrop(Airdrop[] calldata _airdropRecipients)
        external
        onlyOwner
    {
        uint256 totalAirdropNumberOfTokens = 0;
        for (uint256 i; i < _airdropRecipients.length; ) {
            totalAirdropNumberOfTokens += _airdropRecipients[i].numberOfTokens;
            _batchedMint(
                _airdropRecipients[i].wallet,
                _airdropRecipients[i].numberOfTokens
            );
            unchecked {
                ++i;
            }
        }
    }
}