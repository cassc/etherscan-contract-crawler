// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import '../interfaces/IMintableERC721.sol';
import '../core/SafeOwnable.sol';
import '../core/Verifier.sol';

contract FreeMint is SafeOwnable, Verifier {

    IMintableERC721 public immutable nft;
    uint public immutable startAt;
    uint public immutable finishAt;

    mapping(address => uint) public userMintNum;
    uint public totalMintNum;

    constructor(IMintableERC721 _nft, uint _startAt, uint _finishAt, address _verifier) Verifier(_verifier) {
        require(address(_nft) != address(0), "illegal nft");
        nft = _nft;
        require(_startAt > block.timestamp && _finishAt > _startAt, "illegal time");
        startAt = _startAt;
        finishAt = _finishAt;
    }
    
    modifier AlreadyBegin() {
        require(block.timestamp >= startAt, "not begin");
        _;
    }
    
    modifier NotFinish() {
        require(block.timestamp <= finishAt, "already finish");
        _;
    }

    function mint(uint _num, uint _userNum, uint _totalNum, uint8 _v, bytes32 _r, bytes32 _s) external AlreadyBegin NotFinish {
        require(
            ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(address(this), msg.sender, _userNum, _totalNum)))), _v, _r, _s) == verifier,
            "verify failed"
        );
        require(_num + userMintNum[msg.sender] <= _userNum && totalMintNum + _num <= _totalNum, "free mint already full");
        nft.mint(msg.sender, _num);
        userMintNum[msg.sender] += _num;
        totalMintNum += _num;
    }
}