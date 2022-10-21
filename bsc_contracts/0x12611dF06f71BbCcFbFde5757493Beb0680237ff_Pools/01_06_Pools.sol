// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IERC721 {
    function tokenHash(uint) external returns(string memory);
    function totalSupply() external returns(uint256);
    function currentTokenId() external view returns(uint256);
    function mint(address _to, uint256 _tokenId, string memory _hashs) external;
    function burn(uint256 tokenId) external;
    function transferFrom(address from, address to, uint _tokenId) external;
}
contract Pools is Ownable {
    IERC20 public immutable tokenBuy;
    IERC721 public immutable items721;
    struct Pool {
        string name;
        uint totalReward;
        uint percent;
        uint status; // 0 => running; 1 => claimming
        mapping(string => bool) validHash;
        mapping(uint => bool) claimedId;
        uint totalSlot;

    }
    mapping(uint => Pool) public pools;
    uint skip;
    constructor(IERC20 _tokenBuy, IERC721 _items721) {
        tokenBuy = _tokenBuy;
        items721 = _items721;

        pools[0].name = 'Group Stage';
        pools[0].percent = 5;
        pools[1].name = 'Round Of 16';
        pools[1].percent = 10;
        pools[2].name = 'Quarterfinals';
        pools[2].percent = 20;
        pools[3].name = 'Semifinal';
        pools[3].percent = 35;
        pools[4].name = 'Final';
        pools[4].percent = 30;
    }
    function deposit(uint amount) external {
        for(uint i = 0; i < 5; i++) {
            uint poolAmount = pools[i].percent * amount / 100;
            if(poolAmount > 0) {
                if(pools[i].status == 1) skip += poolAmount;
                else {
                    pools[i].totalReward += poolAmount;
                }
            }

        }
    }
    function winnerClaim(uint _pid, uint[] memory tokenIds) external {
        uint length = tokenIds.length;
        require(length > 0, "Pools::winnerClaim: no token id");
        require(pools[_pid].status == 1, "Pools::winnerClaim: pool is running");
        Pool storage p = pools[_pid];

        uint claimAmount;
        for(uint i = 0; i < length; i++) {
            require(!p.claimedId[tokenIds[i]], "Pools::winnerClaim: token Id claimed");
            require(p.validHash[items721.tokenHash(tokenIds[i])], "Pools::winnerClaim: invalid hash");
            claimAmount += p.totalReward / p.totalSlot;
            p.claimedId[tokenIds[i]] = true;
        }
        tokenBuy.transfer(_msgSender(), claimAmount);
    }
    function claim() external onlyOwner {
        tokenBuy.transfer(_msgSender(), skip);
    }
    function setValidHash(uint _pid, string[] memory hashs, bool status, uint totalSlot) external onlyOwner {
        for(uint i = 0; i < hashs.length; i++) {
            pools[_pid].validHash[hashs[i]] = status;
        }
        pools[_pid].totalSlot = totalSlot;
    }
    function setPool(uint _pid, uint percent, uint status) external onlyOwner {
        pools[_pid].percent = percent;
        pools[_pid].status = status;
    }
    function inCaseTokensGetStuck(IERC20 _token) external onlyOwner {

        uint amount = _token.balanceOf(address(this));
        _token.transfer(msg.sender, amount);
    }
}