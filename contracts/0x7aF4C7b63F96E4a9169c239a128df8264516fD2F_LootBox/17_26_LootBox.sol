// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {ERC721Burnable} from "@esportsplus/erc721/contracts/extensions/ERC721Burnable.sol";
import {ERC721ConfigurableMint} from "@esportsplus/erc721/contracts/extensions/ERC721ConfigurableMint.sol";
import {CallerNotOwner, ERC721Membership} from "@esportsplus/erc721/contracts/extensions/ERC721Membership.sol";
import {ERC721Metadata} from "@esportsplus/erc721/contracts/extensions/ERC721Metadata.sol";
import {Referable} from "@esportsplus/erc721/contracts/utilities/Referable.sol";
import {ERC721, ERC721A, IERC721A, Ownable} from "@esportsplus/erc721/contracts/ERC721.sol";
import {UpdatableOperatorFilterer} from "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import {RevokableDefaultOperatorFilterer} from "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";
import {ILoot} from './ILoot.sol';
import {LOOT_MAX_MINT, LOOTBOX_MAX_SUPPLY} from './Constants.sol';

error InvalidTokenAddress();
error ZeroRewards();

contract LootBox is ERC721Burnable, ERC721ConfigurableMint, ERC721Membership, ERC721Metadata, Referable, RevokableDefaultOperatorFilterer {

    ILoot public _ERC20;


    constructor() ERC721ConfigurableMint(0, LOOTBOX_MAX_SUPPLY, 'LootBox', 'LOOT') ERC721Membership( uint64(LOOT_MAX_MINT) ) {
        setBaseURI('https://lootgame.io/metadata/json/');
        setMembership(Membership({
            fusible: true,
            rewardsPerWeek: 5000,
            upgradeFee: 10000
        }));
        setMultipliers(Multipliers({
            level: 1000,
            max: 100000,
            month: 2000
        }));
        setSale(0, Sale({
            endsAt: 0,
            maxMint: 10,
            maxSupply: uint32(LOOTBOX_MAX_SUPPLY),
            price: 0.1 ether,
            startsAt: 0
        }));
        setReferralBIPS(BIPS({
            initial: 500,
            max: 2000,
            step: 100
        }));
    }


    function _baseURI() internal override(ERC721, ERC721Metadata) view virtual returns (string memory) {
        return ERC721Metadata._baseURI();
    }

    function approve(address operator, uint256 tokenId) public payable override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function mint(uint256 key, uint256 quantity, address referrer) payable public {
        uint256 value = mint(key, new bytes32[](0), quantity);

        if (_msgSender() != referrer) {
            _referral(referrer, quantity, value);
        }
    }

    function mint(uint256 key, bytes32[] memory proof, uint256 quantity, address referrer) payable public whenNotPaused {
        uint256 value = mint(key, proof, quantity);

        if (_msgSender() != referrer) {
            _referral(referrer, quantity, value);
        }
    }

    function open(uint256 tokenId) external {
        uint64 reward = rewardOf(tokenId);
        address sender = _msgSender();

        if (ownerOf(tokenId) != _msgSender()) {
            revert CallerNotOwner({ method: 'open' });
        }

        if (reward == 0) {
            revert ZeroRewards();
        }

        _burn(tokenId, false);
        _ERC20.mint(sender, uint256(reward));
    }

    function owner() override(Ownable, UpdatableOperatorFilterer) public view returns (address) {
        return Ownable.owner();
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) onlyAllowedOperator(from) override(IERC721A, ERC721A) payable public {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) onlyAllowedOperator(from) override(IERC721A, ERC721A) payable public {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setERC20(ILoot ERC20) public onlyOwner {
        if (address(ERC20) == address(0)) {
            revert InvalidTokenAddress();
        }

        _ERC20 = ERC20;
    }

    function setApprovalForAll(address operator, bool approved) override(IERC721A, ERC721A) public onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function setReferralBIPS(BIPS memory bips) onlyOwner public {
        _setReferralBIPS(bips);
    }

    function tokenURI(uint256 tokenId) override(ERC721, ERC721Metadata) public view virtual returns(string memory) {
        return ERC721Metadata.tokenURI(tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) onlyAllowedOperator(from) override(IERC721A, ERC721A) payable public {
        super.transferFrom(from, to, tokenId);
    }

    function withdraw() external {
        address account = _msgSender();
        uint256 balance = 0;

        if (account == owner()) {
            balance = address(this).balance - _totalReferralBalance;
        }
        else {
            balance = _withdrawReferralBalance(account);
        }

        _withdraw(account, balance);
    }
}