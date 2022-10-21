// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import '../interfaces/IBurnableERC721.sol';
import '../interfaces/IGenesisNFT.sol';
import '../core/SafeOwnable.sol';
import '../core/Verifier.sol';

contract Halloween is SafeOwnable, Verifier {
    
    event Draw(address user, IBurnableERC721 burnNFT, uint burnNftId, uint newNftId);
    event Reserve(address to, uint nftId);

    uint public constant MAX_MINT_NUM = 2200;
    uint public constant MAX_RESERVE_NUM = 300;

    IBurnableERC721 public immutable ticketNFT;
    IGenesisNFT public immutable genesisNFT;
    uint public immutable MAX_NUM = 300;
    uint public totalMintNum;
    uint public immutable startAt;
    uint public immutable finishAt;

    constructor(
        IBurnableERC721 _ticketNFT,
        IGenesisNFT _genesisNFT,
        address _verifier,
        uint _startAt,
        uint _finishAt
    ) Verifier(_verifier) {
        require(address(_ticketNFT) != address(0), "illegal ticketNft");
        ticketNFT = _ticketNFT;
        require(address(_genesisNFT) != address(0), "illegal genesisNft");
        genesisNFT = _genesisNFT;
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

    function draw(uint _luckyNftId, uint _totalNum, uint8 _v, bytes32 _r, bytes32 _s) external AlreadyBegin NotFinish {
        require(
            ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(address(this), msg.sender, _luckyNftId, _totalNum)))), _v, _r, _s) == verifier,
            "verify failed"
        );
        require(totalMintNum <= _totalNum && _totalNum <= MAX_NUM, "already full");
        ticketNFT.transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, _luckyNftId);
        genesisNFT.reserve(msg.sender, genesisNFT.userReserved(msg.sender) + 1, 0, 0, 0);
        totalMintNum += 1;
        emit Draw(msg.sender, ticketNFT, _luckyNftId, genesisNFT.totalSupply());
    }
}