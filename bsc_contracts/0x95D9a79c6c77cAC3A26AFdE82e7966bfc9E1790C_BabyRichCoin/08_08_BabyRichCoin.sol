// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/token/ERC20/ERC20Capped.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract BabyRichCoin is ERC20Capped {
    using SafeMath for uint256;
    uint8 constant private DECIMAL = 18;
    uint constant public MAX_SUPPLY = 1000000000000000 * 10 ** DECIMAL;

    address constant public BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    uint constant public BURN_AMOUNT = MAX_SUPPLY * 40 / 100;

    uint constant public BWC_MAX_AMOUNT = MAX_SUPPLY * 30 / 100;
    uint public bwcClaimedAmount;

    uint constant public BBF_MAX_AMOUNT = MAX_SUPPLY * 15 / 100;
    uint public bbfClaimedAmount;

    address immutable public LIQUIDITY_ADDRESS;
    uint constant public LIQUIDITY_AMOUNT = MAX_SUPPLY * 10 / 100;

    address immutable public FUND_ADDRESS;
    uint constant public FUND_AMOUNT = MAX_SUPPLY * 5 / 100;

    IERC721 constant BWC_NFT = IERC721(0xb7F7c7D91Ede27b019e265F8ba04c63333991e02);
    uint constant BWC_VALUE = 30000000000 * 10 ** DECIMAL;
    IERC721 constant BBF_NFT = IERC721(0x8c27103eeE75eed8801B808ff23eB02c9876Fa7C);
    uint constant BBF_VALUE = 15000000000 * 10 ** DECIMAL;


    event Claim(address user, IERC721 token, uint tokenId, uint amount);

    mapping(IERC721 => mapping(uint => uint)) public claimed;

    constructor(string memory _name, string memory _symbol, address _liquidityAddress, address _fundAddress) ERC20Capped(MAX_SUPPLY) ERC20(_name, _symbol) {
        LIQUIDITY_ADDRESS = _liquidityAddress;
        FUND_ADDRESS = _fundAddress;

        _setupDecimals(DECIMAL);
        _mint(BURN_ADDRESS, BURN_AMOUNT);
        _mint(_liquidityAddress, LIQUIDITY_AMOUNT);
        _mint(_fundAddress, FUND_AMOUNT);
    }

    function claim(IERC721 _token, uint _tokenId) external {
        require(_token == BWC_NFT || _token == BBF_NFT, "illegal token");
        require(_token.ownerOf(_tokenId) == msg.sender, "illegal owner");
        uint value = 0;
        if (_token == BWC_NFT) {
            value = BWC_VALUE;
        } else if (_token == BBF_NFT) {
            value = BBF_VALUE;
        }
        uint remain = value.sub(claimed[_token][_tokenId]);
        require(remain > 0, "already claimed");
        if (_token == BWC_NFT) {
            bwcClaimedAmount = bwcClaimedAmount.add(remain);
        } else if(_token == BBF_NFT) {
            bbfClaimedAmount = bbfClaimedAmount.add(remain);
        }
        _mint(msg.sender, remain);
        claimed[_token][_tokenId] = claimed[_token][_tokenId].add(remain);
        require(bwcClaimedAmount <= BBF_MAX_AMOUNT && bbfClaimedAmount <= BBF_MAX_AMOUNT, "execute amount");
        emit Claim(msg.sender, _token, _tokenId, remain);
    }

    struct NftItem {
        IERC721 token;
        uint tokenId;
    }

    function avaliable(address _user, NftItem[] memory items) external view returns (uint totalRemain) {
        for (uint i = 0; i < items.length; i ++) {
            if (items[i].token != BWC_NFT && items[i].token == BBF_NFT) {
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

    function claimAll(NftItem[] memory items) external {
        require(items.length > 0, "illegal item");
        uint totalRemain = 0;
        for (uint i = 0; i < items.length; i ++) {
            require(items[i].token == BWC_NFT || items[i].token == BBF_NFT, "illegal token");
            require(items[i].token.ownerOf(items[i].tokenId) == msg.sender, "illegal owner");
            uint value = 0;
            if (items[i].token == BWC_NFT) {
                value = BWC_VALUE;
            } else if(items[i].token == BBF_NFT) {
                value = BBF_VALUE;
            }
            uint remain = value.sub(claimed[items[i].token][items[i].tokenId]);
            if (remain > 0) {
                if (items[i].token == BWC_NFT) {
                    bwcClaimedAmount = bwcClaimedAmount.add(remain);
                } else if(items[i].token == BBF_NFT) {
                    bbfClaimedAmount = bbfClaimedAmount.add(remain);
                }
                totalRemain = totalRemain.add(remain);
                claimed[items[i].token][items[i].tokenId] = claimed[items[i].token][items[i].tokenId].add(remain);
                emit Claim(msg.sender, items[i].token, items[i].tokenId, remain);
            }
        }
        require(totalRemain > 0, "already claimed");
        _mint(msg.sender, totalRemain);
        require(bwcClaimedAmount <= BBF_MAX_AMOUNT && bbfClaimedAmount <= BBF_MAX_AMOUNT, "execute amount");
    }
}