//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";
import "./ISlayToEarnItems.sol";
import "./SlayToEarnAccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

// Immutable, unowned contract. In case of update requirements, the KMS key needs to be switched so that all previous
// signatures become invalid and we do not need to transfer the _claimedSeeds field to guard against replay attacks.
contract SlayToEarnClaimRewards is Ownable {
    using Math for uint256;

    mapping(uint256 => bool) private _claimedSeeds;
    mapping(address => address) private _linkOrigins;
    address private _signerAddress;
    ISlayToEarnItems private _itemCollection;
    IERC20 private _slayToEarn;
    uint256[] private _itemRewardsForAffiliateLink;
    uint256 private _tokensAwardedForAffiliateLink;
    uint256 private _nftPercentageForLinkOrigin;
    uint256 private _tokenPercentageForLinkOrigin;
    bool private _isTestDeployment;

    constructor(ISlayToEarnItems itemCollection, address signerAddress, uint256 isTestDeployment) {
        itemCollection.ping();

        _isTestDeployment = isTestDeployment > 0;
        _itemCollection = itemCollection;
        setSigner(signerAddress);
    }

    event ClaimRewards(address claimant, uint256 seed, uint256[] itemsRequired, uint256[] itemsBurned, uint256[] itemsMinted, uint256 tokensAwarded, uint256 tokensSpent);

    function mintBullions() public {
        require(_isTestDeployment, "This operation is only allowed on testnet.");

        uint256[] memory bullion = new uint256[](1);
        uint256[] memory amount = new uint256[](1);

        bullion[0] = 53;
        amount[0] = 999;

        bytes memory data;
        _itemCollection.mintBatch(msg.sender, bullion, amount, data);
    }

    function isTestDeployment() public view returns (bool) {
        return _isTestDeployment;
    }

    function setSigner(address signerAddress) public onlyOwner {
        _signerAddress = signerAddress;
    }

    function getSigner() public view returns (address) {
        return _signerAddress;
    }

    function getItemCollection() public view returns (ISlayToEarnItems) {
        return _itemCollection;
    }

    function setItemCollection(ISlayToEarnItems itemCollection) public onlyOwner {
        _itemCollection = itemCollection;
    }

    function recoverTokens() public onlyOwner {
        if (_slayToEarn != IERC20(address(0))) {
            _slayToEarn.transfer(msg.sender, _slayToEarn.balanceOf(address(this)));
        }
    }

    function setSlayToEarnToken(IERC20 tokenContract) public onlyOwner {
        _slayToEarn = tokenContract;
        _slayToEarn.balanceOf(address(this));
    }

    function getSlayToEarnToken() public view returns (IERC20) {
        return _slayToEarn;
    }

    function setRewardsForLinkOrigin(uint256 nftPercentage, uint256 tokenPercentage) public onlyOwner {
        require(nftPercentage <= 100, "A maximum of 100% of NFTs can be awarded to link providers.");
        require(tokenPercentage <= 100, "A maximum of 100% of tokens can be awarded to link providers.");

        _nftPercentageForLinkOrigin = nftPercentage;
        _tokenPercentageForLinkOrigin = tokenPercentage;
    }

    function getAffiliateLink(address wallet) public view returns (string memory) {
        return string(abi.encodePacked(
                "https://game.slaytoearn.io/?campaign=",
                Strings.toHexString(uint256(uint160(wallet)), 20)
            ));
    }

    function getLinkOriginForPlayer(address player) public view returns (address) {
        return _linkOrigins[player];
    }

    function getItemRewardPercentageForLinkOrigin() public view returns (uint256) {
        return _nftPercentageForLinkOrigin;
    }

    function getTokenRewardPercentageForLinkOrigin() public view returns (uint256) {
        return _tokenPercentageForLinkOrigin;
    }

    function claimRewards(
        uint256 seed,
        uint256[] memory itemsRequired,
        uint256[] memory itemsBurned,
        uint256[] memory itemsMinted,
        uint256 tokensAwarded,
        uint256 tokensSpent,
        address linkOrigin,
        bytes memory signature
    ) public {

        require(signature.length == 64, "Signature must be 64 bytes in length.");
        require(!_claimedSeeds[seed], "Rewards have already been claimed for this seed.");

        _claimedSeeds[seed] = true;

        bytes memory message = abi.encodePacked(
            uint256(uint160(msg.sender)), // claimant
            seed, // game seed
            uint256(itemsRequired.length),
            itemsRequired,
            uint256(itemsBurned.length),
            itemsBurned,
            uint256(itemsMinted.length),
            itemsMinted,
            tokensAwarded,
            tokensSpent,
            uint256(uint160(linkOrigin))
        );
        bytes32 messageHash = keccak256(message);
        bytes32 r;
        bytes32 s;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
        }

        require(
            ecrecover(messageHash, 27, r, s) == _signerAddress
            || ecrecover(messageHash, 28, r, s) == _signerAddress,
            "The given signature is not valid for the provided parameters."
        );

        _requireItemsForPlayer(itemsRequired);
        _burnItemsForPlayer(itemsBurned);
        _mintItemsForPlayer(itemsMinted);

        if (tokensSpent > 0) {
            require(_slayToEarn != IERC20(address(0)), "If spending tokens is required, SLAY2EARN must be defined.");

            _slayToEarn.transferFrom(msg.sender, address(this), tokensSpent * (1 ether));
        }

        if (_slayToEarn != IERC20(address(0))) {
            tokensAwarded = getEstimatedTokenRewards(tokensAwarded);

            if (tokensAwarded > 1_000) {
                _slayToEarn.transfer(msg.sender, tokensAwarded * (1 ether));
            } else {
                tokensAwarded = 0;
            }
        } else {
            tokensAwarded = 0;
        }

        emit ClaimRewards(msg.sender, seed, itemsRequired, itemsBurned, itemsMinted, tokensAwarded, tokensSpent);

        _rewardLinkOrigin(seed, itemsMinted, tokensAwarded);

        if (linkOrigin != address(0)) {
            require(_linkOrigins[msg.sender] == address(0), "This wallet already claimed affiliate rewards.");
            require(msg.sender != linkOrigin, "You can't claim affiliate rewards for yourself.");

            _linkOrigins[msg.sender] = linkOrigin;
        }
    }

    function getEstimatedTokenRewards(uint256 tokensAwarded) public view returns (uint256){
        return tokensAwarded
        .min(_slayToEarn.balanceOf(address(this)) / (1 ether))
        .min(100_000_000);
    }

    function _rewardLinkOrigin(
        uint256 seed,
        uint256[] memory itemsMinted,
        uint256 tokensAwarded
    ) private {
        address linkOrigin = getLinkOriginForPlayer(msg.sender);

        if (linkOrigin == address(0)) {
            return;
        }

        if (_nftPercentageForLinkOrigin > 0 && itemsMinted.length > 0) {
            uint256[] memory originItemsMinted = new uint256[](itemsMinted.length);
            uint256 originItemsMintedCount = 0;

            for (uint i = 0; i < itemsMinted.length; i++) {
                if (_randomNumber(seed, i) % 100 <= _nftPercentageForLinkOrigin) {
                    originItemsMinted[i] = itemsMinted[i];
                    originItemsMintedCount++;
                }
            }

            uint256[] memory actualOriginItemsMinted = new uint256[](originItemsMintedCount);
            uint j = 0;
            for (uint i = 0; i < itemsMinted.length; i++) {
                if (originItemsMinted[i] != 0) {
                    actualOriginItemsMinted[j++] = originItemsMinted[i];
                }
            }

            (uint256[] memory mintedItems, uint256[] memory amounts) = _unpackItemStacks(actualOriginItemsMinted);

            bytes memory data;
            _itemCollection.mintBatch(linkOrigin, mintedItems, amounts, data);
        }

        if (_tokenPercentageForLinkOrigin > 0 && tokensAwarded > 0 && _slayToEarn != IERC20(address(0))) {
            uint256 originTokensAwarded = ((tokensAwarded * _tokenPercentageForLinkOrigin * (1 ether)) / 100).min(_slayToEarn.balanceOf(address(this)));

            _slayToEarn.transfer(linkOrigin, originTokensAwarded);
        }
    }

    function _randomNumber(uint256 seed, uint256 index) private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, seed, msg.sender, index)));
    }

    function _requireItemsForPlayer(uint256[] memory requiredItemStacks) private {
        (uint256[] memory requiredItems, uint256[] memory amounts) = _unpackItemStacks(requiredItemStacks);

        _itemCollection.requireBatch(msg.sender, requiredItems, amounts);
    }

    function _burnItemsForPlayer(uint256[] memory burnedItemStacks) private {
        (uint256[] memory burnedItems, uint256[] memory amounts) = _unpackItemStacks(burnedItemStacks);

        _itemCollection.burnBatch(msg.sender, burnedItems, amounts);
    }

    function _mintItemsForPlayer(uint256[] memory mintedItemStacks) private {
        (uint256[] memory mintedItems, uint256[] memory amounts) = _unpackItemStacks(mintedItemStacks);

        bytes memory data;
        _itemCollection.mintBatch(msg.sender, mintedItems, amounts, data);
    }

    function _unpackItemStacks(uint256[] memory itemStacks) private view returns (uint256[] memory, uint256[] memory) {
        uint256[] memory items = new uint256[](itemStacks.length);
        uint256[] memory amounts = new uint256[](itemStacks.length);

        for (uint i = 0; i < itemStacks.length; i++) {
            items[i] = (itemStacks[i] << 32) >> 32;
            amounts[i] = itemStacks[i] >> 224;
        }

        return (items, amounts);
    }
}