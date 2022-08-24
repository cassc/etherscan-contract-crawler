// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.16;


import {IERC165} from "IERC165.sol";

import {IERC721} from "IERC721.sol";

import {IERC721Enumerable} from "IERC721Enumerable.sol";

import {ILSSVMPairFactoryLike} from "ILSSVMPairFactoryLike.sol";
import {LSSVMPair, CurveErrorCodes} from "LSSVMPair.sol";

contract SudoGate {
    address private SUDO_PAIR_FACTORY_ADDRESS = 0xb16c1342E617A5B6E4b631EB114483FDB289c0A4;
    address private constant BASED_GHOULS_CONTRACT_ADDRESS = 0xeF1a89cbfAbE59397FfdA11Fc5DF293E9bC5Db90;
    address private owner; 
    uint256 private contributorFeePerThousand = 1;
    
    // mapping from NFT addresses to array of known pools
    mapping (address => address[]) public pools;

    mapping (address => bool) public knownPool;

    // who contributed each pool
    mapping (address => address) public poolContributors;

    constructor() { owner = msg.sender; }
    
    function setPairFactoryAddress(address addr) public {
        require(msg.sender == owner, "Only owner allowed to call setPairFactoryAddress");
        SUDO_PAIR_FACTORY_ADDRESS = addr;
    }


    function registerPool(address sudoswapPool) public returns (bool) {
        require(!knownPool[sudoswapPool], "Pool already known");
        if (!ILSSVMPairFactoryLike(SUDO_PAIR_FACTORY_ADDRESS).isPair(sudoswapPool, ILSSVMPairFactoryLike.PairVariant.ENUMERABLE_ETH)) {
            require(ILSSVMPairFactoryLike(SUDO_PAIR_FACTORY_ADDRESS).isPair(sudoswapPool, ILSSVMPairFactoryLike.PairVariant.MISSING_ENUMERABLE_ETH), "Not a sudoswap ETH pool");
        }
        knownPool[sudoswapPool] = true;
        poolContributors[sudoswapPool] = msg.sender;
        address nft = address(LSSVMPair(sudoswapPool).nft());
        pools[nft].push(sudoswapPool); 
    }
    
    function buyFromPoolAtPrice(address pool, uint256 priceInWei, uint256 slippagePercent) public payable {
        IERC721 nft = LSSVMPair(pool).nft();
        require(nft.balanceOf(pool) > 0, "Pool has no NFTs");
        require(priceInWei <= msg.value, "Not enough ETH for price of NFT");
        uint256 priceWithSlippage = priceInWei * (100 + slippagePercent) / 100;
        require(priceWithSlippage <= msg.value, "Not enough ETH for price with slippage");
        uint256 priceWithContributorFee = priceWithSlippage * (1000 + contributorFeePerThousand) / 1000; 
        require(priceWithContributorFee <= msg.value, "Not enough ETH for both slippage and contributor fee");
        uint256 usedAmt = LSSVMPair(pool).swapTokenForAnyNFTs{value: msg.value}(
            1, 
            priceWithSlippage, 
            msg.sender, 
            false, 
            address(0));
        require(usedAmt < msg.value, "Can't use more ETH than was originally sent");
        require(usedAmt > 0, "There ain't no such thing as a free lunch");
        uint256 contributorFee = usedAmt * contributorFeePerThousand / 1000; 
        // send 0.1% to whoever added the pool to this contract
        require(usedAmt + contributorFee <= msg.value, "Can't spend more than we were originally sent");
        payable(poolContributors[pool]).transfer(contributorFee);
        uint256 diff = msg.value - (usedAmt + contributorFee);
        // send back unused ETH
        if (diff > 0) { payable(msg.sender).transfer(diff); }
    }

    function buyFromPool(address pool, uint256 slippagePercent) public payable {
        CurveErrorCodes.Error err;
        uint256 inputAmount;
        (err, , , inputAmount, ) = LSSVMPair(pool).getBuyNFTQuote(1);
        require(err == CurveErrorCodes.Error.OK, "Unable to get price quote from pool");
        buyFromPoolAtPrice(pool, inputAmount, slippagePercent);
    }

    function tryToBuy(address nft) public payable  {
        /* 
            Try to buy NFT without knowing the price ahead of time, 
            likely to fail! 
        */
        uint256 bestPrice;
        address bestPool;
        (bestPrice, bestPool) = buyQuote(nft);
        require(bestPool != address(0), "No pool found");
        require(bestPrice != type(uint256).max, "Invalid price");
        buyFromPoolAtPrice(bestPool, bestPrice, 0);
    }

    function buyQuote(address nft) public view returns (uint256 bestPrice, address bestPool) {
        address[] storage nftPools = pools[nft];
        uint256 numPools = nftPools.length;
        require(numPools > 0, "No pools registered for given NFT");

        CurveErrorCodes.Error err;
        uint256 inputAmount;
        bestPrice = type(uint256).max;
        bestPool = address(0);

        address poolAddr;
        uint256 i = 0;
        for (; i < numPools; ++i) {
            poolAddr = nftPools[i];
            if (IERC721(nft).balanceOf(poolAddr) == 0) {
                // check if pool actually has any NFTs
                continue;
            } else {
                (err, , , inputAmount, ) = LSSVMPair(poolAddr).getBuyNFTQuote(1);
                if (err == CurveErrorCodes.Error.OK) {
                    if (inputAmount < bestPrice) {
                        bestPool = poolAddr;
                        bestPrice = inputAmount;
                    }
                }
            }
        }
        require(bestPool != address(0), "Could not find a pool to buy from");
    }

    function sell(address nft, uint256 tokenId) public {
        uint256 bestPrice;
        address bestPool;
        (bestPrice, bestPool) = sellQuote(nft);
        
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = tokenId;

        uint256 outputAmount = LSSVMPair(bestPool).swapNFTsForToken(
            nftIds,
            bestPrice,
            payable(msg.sender),
            false,
            address(0));
        require(outputAmount > 0, "Didn't get any ETH back");
    }

    function sellQuote(address nft) public view returns (uint256 bestPrice, address bestPool) {
        address[] storage nftPools = pools[nft];
        uint256 numPools = nftPools.length;
        require(numPools > 0, "No pools registered for given NFT");

        CurveErrorCodes.Error err;
        uint256 outputAmount;
        bestPrice = 0;
        bestPool = address(0);

        address poolAddr;
        uint256 i = 0;
        for (; i < numPools; ++i) {
            poolAddr = nftPools[i];
            if (poolAddr.balance == 0) {
                // check if pool actually has any ETH
                continue;
            } else {
                (err, , , outputAmount, ) = LSSVMPair(poolAddr).getSellNFTQuote(1);
                if (err == CurveErrorCodes.Error.OK) {
                    if (outputAmount > bestPrice) {
                        bestPool = poolAddr;
                        bestPrice = outputAmount;
                    }
                }
            }
        }
        require(bestPool != address(0), "Could not find a pool to buy from");
    }

    
    // make it possible to receive ETH on this contract
    receive() external payable { }

    function rescueETH() public {
        // in case ETH gets trapped on this contract for some reason,
        // allow owner to manually withdraw it
        require(msg.sender == owner, "Only owner allowed to call rescueETH");
        payable(owner).transfer(address(this).balance);
    }
}