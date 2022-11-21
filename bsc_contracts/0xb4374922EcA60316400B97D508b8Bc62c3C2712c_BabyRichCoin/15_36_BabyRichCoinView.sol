// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/proxy/Initializable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '../interfaces/IUniswapV2Router02.sol';
import '../interfaces/IUniswapV2Factory.sol';
import '../interfaces/IUniswapV2Pair.sol';

contract BabyRichCoinView {
    using SafeMath for uint256;

    IERC721 constant BWC_NFT = IERC721(0xb7F7c7D91Ede27b019e265F8ba04c63333991e02);
    uint immutable public BWC_VALUE;
    IERC721 constant BBF_NFT = IERC721(0x8c27103eeE75eed8801B808ff23eB02c9876Fa7C);
    uint immutable public BBF_VALUE;
    mapping(IERC721 => mapping(uint => uint)) public claimed;

    uint public constant _DECIMALS = 9;

    constructor () {
        BWC_VALUE = 30000000000 * 10 ** _DECIMALS;
        BBF_VALUE = 15000000000 * 10 ** _DECIMALS;
    }

    struct NftItem {
        IERC721 token;
        uint tokenId;
    }

    function available(address _user, NftItem[] memory items) external view returns (uint totalRemain) {
        for (uint i = 0; i < items.length; i ++) {
            if (items[i].token != BWC_NFT && items[i].token != BBF_NFT) {
                continue;
            }
            if (items[i].token.ownerOf(items[i].tokenId) != _user) {
                continue;
            }
            uint value = 0;
            if (items[i].token == BWC_NFT) {
                value = BWC_VALUE;
            } else if (items[i].token == BBF_NFT) {
                value = BBF_VALUE;
            }
            uint remain = value.sub(claimed[items[i].token][items[i].tokenId]);
            totalRemain = totalRemain.add(remain);
        }
        return totalRemain;
    }

    function totalSupply() public view returns (uint256) {
        return 1000000000000000 * 10 ** _DECIMALS;
    }

    function decimals() public view returns (uint256) {
        return _DECIMALS;
    }
}