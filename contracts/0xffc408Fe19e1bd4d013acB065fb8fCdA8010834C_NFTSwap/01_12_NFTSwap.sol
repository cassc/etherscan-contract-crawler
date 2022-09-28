// SPDX-License-Identifier: bsl-1.1
/**
 * Copyright 2022 Raise protocol ([email protected])
 */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./INFTFull.sol";

contract NFTSwap is ReentrancyGuard, IERC721Receiver {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    // 1 = 100% = 10000 basis points
    uint16 public constant SHARES_100_PERCENT_IN_BP = 100 * 100;
    uint MAX_TOKENS_FOR_REWARDS = 5;

    mapping (INFTFull => EnumerableSet.AddressSet) private rewardsTokensInternal;
    mapping (IERC20 => mapping (INFTFull => uint)) public rewardsTokensBalances;

    event Swap(INFTFull indexed nftContract, address indexed user, uint indexed tokenId, IERC20 rewardToken, uint rewardTokenAmount);

    /**
     * @dev Throws if called by any account other than the owner of nft.
     * @dev Works only with NFTFactory NFT
     */
    modifier onlyNftContractOwner(INFTFull _nftContract) {
        try _nftContract.isNFTFactoryNFT{gas:20000}() returns (bytes32 _result) {
            require(_result == keccak256("NFTFactoryNFT"), "NFTSwap: NFT_IS_NOT_SUPPORTED");
        } catch {
            revert("NFTSwap: NFT_IS_NOT_SUPPORTED");
        }

        require(_nftContract.owner() == msg.sender, "NFTSwap: AUTH_FAILED");
        _;
    }

    modifier nonZeroAddress(address _address) {
        require(_address != address(0), "NFTSwap: ZERO_ADDRESS");
        _;
    }

    modifier nonZeroAmount(uint _amount) {
        require(_amount != 0, "NFTSwap: ZERO_AMOUNT");
        _;
    }

    function addReward(INFTFull _nftContract, IERC20 _rewardToken, uint _amount)
        public
        nonReentrant
        nonZeroAddress(address(_nftContract))
        nonZeroAddress(address(_rewardToken))
        onlyNftContractOwner(_nftContract)
        nonZeroAmount(_amount)
    {
        rewardsTokensInternal[_nftContract].add(address(_rewardToken)); // don't check if existed before, just add more rewards
        require(rewardsTokensInternal[_nftContract].length() <= MAX_TOKENS_FOR_REWARDS, 'NFTSwap: TOO_MANY_TOKENS');

        rewardsTokensBalances[_rewardToken][_nftContract] += _amount;
        _rewardToken.safeTransferFrom(msg.sender, address(this), _amount);
    }

    function withdrawReward(INFTFull _nftContract, IERC20 _rewardToken, uint _amount)
        public
        nonReentrant
        nonZeroAddress(address(_nftContract))
        nonZeroAddress(address(_rewardToken))
        onlyNftContractOwner(_nftContract)
        nonZeroAmount(_amount)
    {
        require(rewardsTokensInternal[_nftContract].contains(address(_rewardToken)), "NFTSwap: TOKEN_NOT_ADDED");
        require(rewardsTokensBalances[_rewardToken][_nftContract] >= _amount, "NFTSwap: INSUFFICIENT_BALANCE");

        rewardsTokensBalances[_rewardToken][_nftContract] -= _amount;
        _rewardToken.safeTransfer(msg.sender, _amount);
    }

    function swap(INFTFull _nftContract, IERC20[] memory _rewardTokens, uint[] memory _tokensIds) public nonReentrant {
        require(_rewardTokens.length != 0 && _tokensIds.length != 0, 'NFTSwap: EMPTY_ARRAY');

        for (uint j=0; j<_tokensIds.length; j++) {
            uint tokenId = _tokensIds[j];
            INFT.TokenInfo memory NFTInfo = _nftContract.getTokenInfo(tokenId);

            _nftContract.safeTransferFrom(msg.sender, address(this), tokenId);
            _nftContract.burn(tokenId);

            for (uint i=0; i<_rewardTokens.length; i++) {
                require(rewardsTokensInternal[_nftContract].contains(address(_rewardTokens[i])), "NFTSwap: TOKEN_NOT_ADDED");

                uint amountToSwap = _rewardTokens[i].totalSupply() * NFTInfo.shareBasisPoints / SHARES_100_PERCENT_IN_BP;
                require(rewardsTokensBalances[_rewardTokens[i]][_nftContract] >= amountToSwap, "NFTSwap: INSUFFICIENT_BALANCE");

                rewardsTokensBalances[_rewardTokens[i]][_nftContract] -= amountToSwap;
                _rewardTokens[i].safeTransfer(msg.sender, amountToSwap);

                emit Swap(_nftContract, msg.sender, tokenId, _rewardTokens[i], amountToSwap);
            }
        }
    }

    function onERC721Received(
        address operator,
        address /* from */,
        uint256 /* tokenId */,
        bytes calldata /* data */
    ) external view returns (bytes4) {
        require(operator == address(this), "NFTSwap: TRANSFER_NOT_ALLOWED");

        return IERC721Receiver.onERC721Received.selector;
    }

    function rewardsTokensForNFT(INFTFull _nftContract) public view returns(address[] memory) {
        return rewardsTokensInternal[_nftContract].values();
    }
}