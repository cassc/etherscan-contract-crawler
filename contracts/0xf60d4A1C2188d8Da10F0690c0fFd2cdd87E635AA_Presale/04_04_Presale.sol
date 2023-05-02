// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC721 {
    function tokensOfOwner(
        address owner
    ) external view returns (uint256[] memory);
}

contract Presale is Ownable {
    IERC20 public BURNS;
    IERC20 public XBURNS;
    IERC721 public NFT;

    address payable public TREASURY;

    bool public contributeActive = false;
    bool public redeemActive = false;
    bool public refundActive = false;

    uint256 public minContribution;
    uint256 public rate;
    uint256 public precision;

    uint256 public totalContributions = 0;
    uint256 public totalBonus = 0;

    mapping(address => uint256) public contributions;
    mapping(address => uint256) public bonus;
    mapping(uint256 => bool) public redeemedNfts;
    mapping(address => bool) public redeemedTokens;
    mapping(address => bool) public refunded;

    constructor(
        address burns,
        address xburns,
        address nft,
        address payable treasury,
        uint256 minContribution_,
        uint256 rate_,
        uint256 precision_
    ) {
        BURNS = IERC20(burns);
        XBURNS = IERC20(xburns);
        NFT = IERC721(nft);

        TREASURY = treasury;

        minContribution = minContribution_;
        rate = rate_;
        precision = precision_;
    }

    function updateBurns(address value) public onlyOwner {
        BURNS = IERC20(value);
    }

    function updateXburns(address value) public onlyOwner {
        XBURNS = IERC20(value);
    }

    function updateNtf(address value) public onlyOwner {
        NFT = IERC721(value);
    }

    function updateTreasury(address payable value) public onlyOwner {
        TREASURY = value;
    }

    function updateContributeActive(bool value) public onlyOwner {
        contributeActive = value;
    }

    function updateRedeemActive(bool value) public onlyOwner {
        redeemActive = value;
    }

    function updateRefundActive(bool value) public onlyOwner {
        redeemActive = value;
    }

    function updateMinContribution(uint256 value) public onlyOwner {
        minContribution = value;
    }

    function updateRate(uint256 value) public onlyOwner {
        rate = value;
    }

    function updatePrecision(uint256 value) public onlyOwner {
        precision = value;
    }

    function withdrawErc20(address _token) external onlyOwner {
        if (IERC20(_token).balanceOf(address(this)) > 0) {
            IERC20(_token).transfer(
                TREASURY,
                IERC20(_token).balanceOf(address(this))
            );
        }
    }

    function withdrawEth() external onlyOwner {
        (bool sent, bytes memory data) = payable(TREASURY).call{
            value: address(this).balance
        }("");
        require(sent, "Failed to send Ether");
    }

    function userBoosterCount(address user) public view returns (uint256) {
        uint256[] memory nfts = NFT.tokensOfOwner(user);
        uint256 boosters = 0;
        for (uint256 i = 0; i < nfts.length; i++) {
            if (!redeemedNfts[nfts[i]]) {
                boosters++;
            }
        }
        return boosters;
    }

    function contribute() public payable {
        require(contributeActive, "CONT: Can't contribute yet.");
        uint256 amount = msg.value;
        require(amount >= minContribution, "CONT: Amount too low.");

        (bool sent, bytes memory data) = payable(TREASURY).call{value: amount}(
            ""
        );
        require(sent, "Failed to send Ether");

        contributions[_msgSender()] += amount;
        totalContributions += amount;

        uint256[] memory nfts = NFT.tokensOfOwner(_msgSender());
        uint256 boosters = 0;
        for (uint256 i = 0; i < nfts.length; i++) {
            if (!redeemedNfts[nfts[i]]) {
                redeemedNfts[nfts[i]] = true;
                boosters++;
            }
        }

        if (boosters > 0) {
            amount = (5 * boosters * amount) / 100;
            bonus[_msgSender()] += amount;
            totalBonus += amount;
        }
    }

    function redeem() public {
        require(redeemActive, "REDEEM: Can't redeem yet.");
        uint256 contribution = contributions[_msgSender()];
        require(contribution > 0, "REDEEM: No contribution.");
        require(!redeemedTokens[_msgSender()], "REDEEM: Already redeemed.");

        redeemedTokens[_msgSender()] = true;

        BURNS.transferFrom(
            TREASURY,
            _msgSender(),
            (contribution * rate) / precision
        );

        uint256 bonusContribution = bonus[_msgSender()];
        if (bonusContribution > 0)
            XBURNS.transferFrom(
                TREASURY,
                _msgSender(),
                (bonusContribution * rate) / precision
            );
    }
}