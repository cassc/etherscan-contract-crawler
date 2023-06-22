// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import '../interfaces/IMintableBurnableERC721.sol';
import '../core/SafeOwnable.sol';
import '../core/Mintable.sol';
import '../core/NFTCore.sol';

contract GenesisNFT is SafeOwnable, NFTCore, Mintable {
    
    event Draw(address user, IMintableBurnableERC721 burnNFT, uint burnNftId, uint newNftId);
    event Reserve(address to, uint nftId);

    uint public constant MAX_MINT_NUM = 2200;
    uint public constant MAX_RESERVE_NUM = 300;

    IMintableBurnableERC721 public immutable ticketNFT;

    uint public mintedNum;
    uint public reservedNum;
    mapping(address => uint) public userReserved;

    constructor(
        string memory _name, 
        string memory _symbol, 
        string memory _uri, 
        IMintableBurnableERC721 _ticketNFT
    ) NFTCore(_name, _symbol, _uri, MAX_MINT_NUM + MAX_RESERVE_NUM) Mintable(new address[](0), false) {
        require(address(_ticketNFT) != address(0), "illegal ticketNFT");
        ticketNFT = _ticketNFT;
    }

    function draw(uint _luckyNftId, uint _totalNum, uint8 _v, bytes32 _r, bytes32 _s) external onlyMinterOrMinterSignature(keccak256(abi.encodePacked(address(this), msg.sender, _luckyNftId, _totalNum)), _v, _r, _s) {
        ticketNFT.burn(msg.sender, _luckyNftId);
        unchecked {
            require(mintedNum < MAX_MINT_NUM && mintedNum < _totalNum && _totalNum <= MAX_MINT_NUM, "mint already full");
            mintInternal(msg.sender, 1);
            mintedNum += 1;
        }
        emit Draw(msg.sender, ticketNFT, _luckyNftId, totalSupply);
    }

    function reserve(address _to, uint _num, uint8 _v, bytes32 _r, bytes32 _s) external onlyMinterOrMinterSignature(keccak256(abi.encodePacked(address(this), _to, _num)), _v, _r, _s) {
        uint availableNum = _num - userReserved[_to];
        unchecked {
            require(availableNum > 0 && reservedNum + availableNum <= MAX_RESERVE_NUM, "reserve already full");
            for (uint i = 0; i < availableNum; i ++) {
                mintInternal(_to, 1);
                emit Reserve(_to, totalSupply);
            }
            reservedNum += availableNum;
            userReserved[_to] += availableNum;
        }
    }
}