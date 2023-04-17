// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import '../interfaces/IERC721MintableV2.sol';
import '../core/SafeOwnable.sol';

contract LandFragmentSynthesis is SafeOwnable {
    using SafeMath for uint;

    event SupportNFTChanged(IERC721 nft, bool available);
    event MinterChanged(address minter, bool available);
    event NewRequiredNum(uint oldNum, uint newNum);
    event Convert(address user, IERC721 landFragments, uint256[] ids, uint256[] newIds);
    event MintPlots(address account, uint256 endTokenId, uint256 number);

    address constant public HOLE = 0x000000000000000000000000000000000000dEaD;
    IERC721 immutable public landFragments;
    IERC721MintableV2 immutable public babyWonderland;
    uint public MAX_SUPPLY = 500;
    uint public synthesisedNum = 0;

    mapping(IERC721 => bool) public supportNFTs;
    mapping(address => bool) public minters;
    uint public requiredNum;
    uint public startAt;
    uint public finishAt;

    constructor(IERC721 _landFragments, IERC721MintableV2 _babyWonderland, uint _startAt, uint _finishAt) {
        requiredNum = 20;
        emit NewRequiredNum(0, 20);
        require(address(_landFragments) != address(0), "illegal LandFragments address");
        landFragments = _landFragments;
        require(address(_babyWonderland) != address(0), "illegal babyWonderland address");
        babyWonderland = _babyWonderland;
        require(_finishAt > _startAt, "illegal time");
        startAt = _startAt;
        finishAt = _finishAt;
    }

    function setMaxSupply(uint _supply) external onlyOwner {
        MAX_SUPPLY = _supply;
    }

    function setTime(uint _startAt, uint _finishAt) external onlyOwner {
        require(_finishAt > _startAt, "illegal time");
        startAt = _startAt;
        finishAt = _finishAt;
    }

    function setRequiredNum(uint _newNum) external onlyOwner {
        require(_newNum > 0, "illegal num");
        emit NewRequiredNum(requiredNum, _newNum);
        requiredNum = _newNum;
    }

    function convert(uint[] memory _ids) external {
        require(block.timestamp >= startAt && block.timestamp <= finishAt, "not begin or already finish");
        require(_ids.length >= requiredNum && _ids.length % requiredNum == 0, "illegal length");
        for (uint i = 0; i < _ids.length; i ++) {
            landFragments.transferFrom(msg.sender, HOLE, _ids[i]);
        }
        uint num = _ids.length / requiredNum;
        require(synthesisedNum + num <= MAX_SUPPLY, "already full");
        synthesisedNum += num;
        
        uint currentTotalSupply = babyWonderland.totalSupply();
        uint[] memory tokenIds = new uint[](num);
        babyWonderland.batchMint(msg.sender, num);
        for (uint i = 1; i <= num; i ++) {
            emit MintPlots(
                msg.sender,
                currentTotalSupply + i + 1,
                1
            );
            tokenIds[i - 1] = currentTotalSupply + i;
        }
        emit Convert(msg.sender, landFragments, _ids, tokenIds);
    }
}