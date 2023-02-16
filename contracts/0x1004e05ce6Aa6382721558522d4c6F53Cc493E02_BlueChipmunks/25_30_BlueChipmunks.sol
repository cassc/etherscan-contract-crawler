// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@minteeble/smart-contracts/contracts/token/ERC721/MinteebleERC721A.sol";
import "@minteeble/smart-contracts/contracts/token/misc/ReferralSystem.sol";
import {DefaultOperatorFilterer} from "../OperatorFilter/DefaultOperatorFilterer.sol";

contract BlueChipmunks is MinteebleERC721A, DefaultOperatorFilterer {
    ReferralSystem public referral;

    address public lotteryAddress;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _maxSupply,
        uint256 _mintPrice
    ) MinteebleERC721A(_tokenName, _tokenSymbol, _maxSupply, _mintPrice) {
        referral = new ReferralSystem();
        referral.addRank();
        referral.addLevel(0, 10);
        referral.addLevel(0, 0);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setLotteryAddress(address _lotteryAddress) public onlyOwner {
        lotteryAddress = _lotteryAddress;
    }

    function isFirstLevel(address _account) public view returns (bool) {
        return referral.inviterOf(_account) == owner();
    }

    function ownerMintForAddress(uint256 _mintAmount, address _receiver)
        public
        override
    {
        require(
            msg.sender == owner() || msg.sender == lotteryAddress,
            "Unauthorized"
        );
        require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceed!");
        _safeMint(_receiver, _mintAmount);
    }

    function addRefMember(address _account) public onlyOwner {
        require(!referral.hasInviter(_account), "Account was already invited");
        referral.setInvitation(msg.sender, _account);
    }

    function mintRef(uint256 _mintAmount, address _inviter)
        public
        payable
        canMint(_mintAmount)
        active
    {
        require(msg.sender != owner(), "Owner can not be invited");
        require(
            !referral.hasInviter(msg.sender),
            "Account was already invited"
        );
        referral.setInvitation(_inviter, msg.sender);
        uint256 totBalance = msg.value;

        require(_inviter == owner() || isFirstLevel(_inviter), "Not allowed");

        require(
            msg.value >= _mintAmount * (((mintPrice) / 100) * 90),
            "Insufficient funds!"
        );

        _safeMint(_msgSender(), _mintAmount);
        totalMintedByAddress[_msgSender()] += _mintAmount;

        ReferralSystem.RefInfo[] memory refInfo = referral.addAction(
            msg.sender
        );

        for (uint256 i = 0; i < refInfo.length; i++) {
            if (refInfo[i].account != owner()) {
                (bool success, ) = payable(refInfo[i].account).call{
                    value: (totBalance / 100) * refInfo[i].percentage
                }("");
                require(success);
            }
        }
    }
}