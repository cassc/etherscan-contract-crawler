// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TournamentEntryV1 is Ownable {
    IERC20 private _token;
    IERC721 private _nft;

    uint256 public startsAt;
    uint256 public endsAt;
    uint256 public registerFee;

    address[] public participants;
    mapping(address => bool) public isRegistered;

    constructor(address _tokenAddress, address _nftAddress) {
        // 2022년 5월 7일 토요일 오후 3:00:00 GMT+09:00
        startsAt = 1651903200000;
        // 2022년 5월 8일 일요일 오후 3:00:00 GMT+09:00
        endsAt = 1651989600000;
        registerFee = 3 * 1e18;
        _token = IERC20(_tokenAddress);
        _nft = IERC721(_nftAddress);
    }

    function register() external {
        require(isRegistered[msg.sender] == false, "TournamentEntryV1: Already registered.");
        require(block.timestamp >= startsAt && block.timestamp < endsAt, "TournamentEntryV1: Invalid tournament registration period.");
        require(_token.balanceOf(msg.sender) >= 50 * 1e18, "TournamentEntryV1: Not enough ERC20 token.");
        require(_nft.balanceOf(msg.sender) >= 1, "TournamentEntryV1: Not enough ERC721 token.");

        _token.transferFrom(msg.sender, address(this), registerFee);
        participants.push(msg.sender);
        isRegistered[msg.sender] = true;
    }

    function length() public view returns(uint256) {
        return participants.length;
    }

    function withdraw() external onlyOwner {
        _token.transfer(owner(), _token.balanceOf(address(this)));
    }

    function setStartsAt(uint256 _startsAt) external onlyOwner {
        startsAt = _startsAt;
    }

    function setEndsAt(uint256 _endsAt) external onlyOwner {
        endsAt = _endsAt;
    }

    function setRegisterFee(uint256 _registerFee) external onlyOwner {
        registerFee = _registerFee;
    }
}