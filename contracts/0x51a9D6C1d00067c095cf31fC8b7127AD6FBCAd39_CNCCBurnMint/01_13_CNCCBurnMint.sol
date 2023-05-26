// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./interface/ICryptNinjaChildrenCoin.sol";
import 'openzeppelin-contracts/contracts/security/ReentrancyGuard.sol';
import "./AdminAccessControl.sol";

contract CNCCBurnMint is ReentrancyGuard, AdminAccessControl {
    event exchangeCoinToMakimonoEvent(address indexed user, uint256 afterTokenId, uint256 amount);

    ICryptNinjaChildrenCoin public immutable cncc;

    uint256 public constant COIN_TOKEN_ID = 1;
    uint256 public constant MAKIMONO_TEN_TOKEN_ID = 2;

    bool public isPause = true;

    constructor(ICryptNinjaChildrenCoin _cncc) {
        _grantRole(ADMIN, msg.sender);
        cncc = _cncc;
    }

    function exchangeCoinToMakimono(uint256 _amount) external nonReentrant {
        require(!isPause, 'is not active.');
        require(0 < _amount, 'amount cannot be zero');
        require(_amount <= cncc.balanceOf(msg.sender, 1), 'not have enouth amount');
        require((_amount % 2) == 0, 'amount must be even number');

        cncc.burn(msg.sender, COIN_TOKEN_ID, _amount);

        uint256 mintAmount = _amount / 2;
        uint256[] memory randCounts = new uint256[](3);
        for (uint256 i = 0; i < mintAmount; i++) {
            uint256 rand = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), i))) % 3; // 0,1,2
            randCounts[rand] += 1;
        }
        uint256[] memory tokenIds;
        uint256[] memory amounts;
        (tokenIds, amounts) = _forBatchMint(randCounts);
        cncc.mintBatch(msg.sender, tokenIds, amounts, "");
    }

    function _forBatchMint(uint256[] memory _randCounts) private returns (uint256[] memory tokenIds, uint256[] memory amounts) {
        tokenIds = new uint256[](_randCounts.length);
        amounts = new uint256[](_randCounts.length);
        uint256 tokenAmountIndex = 0;
        for(uint256 i = 0; i < 3; i++) {
            if (_randCounts[i] > 0) {
                tokenIds[tokenAmountIndex] = MAKIMONO_TEN_TOKEN_ID + i;
                amounts[tokenAmountIndex] = _randCounts[i];
                emit exchangeCoinToMakimonoEvent(msg.sender, tokenIds[tokenAmountIndex], amounts[tokenAmountIndex]);

                tokenAmountIndex += 1;
            }
        }

        return (tokenIds, amounts);
    }

    function setPause(bool _isPause) external onlyAdmin {
        isPause = _isPause;
    }
}