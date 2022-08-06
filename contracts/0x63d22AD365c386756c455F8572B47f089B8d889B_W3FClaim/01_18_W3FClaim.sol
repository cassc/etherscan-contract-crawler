//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./W3F.sol";

contract W3FClaim is Ownable {
    using SafeMath for uint256;

    uint256 private constant MAX_SUPPLY_RAINBOW = 11;
    uint256 private constant MAX_SUPPLY_GOLD = 102;
    uint256 private constant MAX_SUPPLY_SILVER = 499;
    uint256 private constant MAX_SUPPLY_BRONZE = 888;
    uint256 private constant SHARE_PCT_RAINBOW = 25 * 2;
    uint256 private constant SHARE_PCT_GOLD = 12 * 2;
    uint256 private constant SHARE_PCT_SILVER = 8 * 2;
    uint256 private constant SHARE_PCT_BRONZE = 5 * 2;
    uint256 public totalClaimed = 0;
    W3F private w3fPass;
    mapping(uint256 => uint256) private claimedForPass;

    event AddedReserves(address indexed adder, uint256 added);
    event Claim(address indexed claimedBy, uint256 indexed tokenId, uint256 amount);

    constructor(W3F _w3fPass) {
        w3fPass = _w3fPass;
    }

    // Returns the amount that is/was claimable for a given pass,
    // regardless of wheter or not the claim already took place
    function claimableFor(uint256 _tokenId) public view returns(uint256 _claimable) {
        require(_tokenId <= MAX_SUPPLY_RAINBOW + MAX_SUPPLY_GOLD + MAX_SUPPLY_SILVER + MAX_SUPPLY_BRONZE, "Invalid token ID");
        uint256 totalClaimable = address(this).balance.add(totalClaimed);
        uint256 percentage = 0;
        uint256 totalPasses = 0;

        if(_tokenId == 0) {
          // Correct for missing token 1500
          percentage = SHARE_PCT_BRONZE;
          totalPasses = MAX_SUPPLY_BRONZE;
        } else if (_tokenId <= MAX_SUPPLY_RAINBOW) {
            percentage = SHARE_PCT_RAINBOW;
            totalPasses = MAX_SUPPLY_RAINBOW;
        } else if (_tokenId <= MAX_SUPPLY_RAINBOW + MAX_SUPPLY_GOLD) {
            percentage = SHARE_PCT_GOLD;
            totalPasses = MAX_SUPPLY_GOLD;
        } else if (_tokenId <= MAX_SUPPLY_RAINBOW + MAX_SUPPLY_GOLD + MAX_SUPPLY_SILVER) {
            percentage = SHARE_PCT_SILVER;
            totalPasses = MAX_SUPPLY_SILVER;
        } else {
            percentage = SHARE_PCT_BRONZE;
            totalPasses = MAX_SUPPLY_BRONZE;
        }

        uint256 claimableByLevel = totalClaimable.div(100).mul(percentage);

        _claimable = claimableByLevel.div(100000000000).div(totalPasses).mul(100000000000);
    }

    // Returns the amount that is currently available to claim for the pass
    function unclaimedFor(uint256 _tokenId) public view returns(uint256 _unclaimed) {
        uint256 claimable = claimableFor(_tokenId);
        uint256 claimed = claimedFor(_tokenId);
        _unclaimed = claimable.sub(claimed);
    }

    // Returns the amount that has already been claimed for the pass
    function claimedFor(uint256 _tokenId) public view returns(uint256 _claimed) {
        _claimed = claimedForPass[_tokenId];
    }

    // Allows the owner to claim the share of one W3F pass
    function claim(uint256 _tokenId) public {
        require(w3fPass.ownerOf(_tokenId) == msg.sender, "W3FClaim: Invalid pass owner");

        uint claimable = claimableFor(_tokenId);
        uint claimed = claimedFor(_tokenId);
        require(claimed < claimable, "W3FClaim: Nothing left to claim for pass");

        uint unclaimed = claimable.sub(claimed);
        require(address(this).balance >= unclaimed, "W3FClaim: Insufficient reserves");

        claimedForPass[_tokenId] = claimed.add(unclaimed);
        totalClaimed = totalClaimed.add(unclaimed);
        emit Claim(msg.sender, _tokenId, unclaimed);

        (bool sent,) = payable(msg.sender).call{value: unclaimed}("");
        require(sent, "W3FClaim: Recipient could not receive");
    }

    function withdraw() public onlyOwner {
        (bool sent, ) = payable(owner()).call{value: address(this).balance}("");
        require(sent);
    }

    function withdrawToken(ERC20 token) public onlyOwner {
        uint256 tokenBalance = token.balanceOf(address(this));
        token.transfer(owner(), tokenBalance);
    }

    receive() external payable {}
}