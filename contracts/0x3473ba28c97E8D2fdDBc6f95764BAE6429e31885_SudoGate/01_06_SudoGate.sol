// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.16;


import {IERC165} from "IERC165.sol";

import {IERC721} from "IERC721.sol";

import {IERC721Enumerable} from "IERC721Enumerable.sol";

import {ILSSVMPairFactoryLike} from "ILSSVMPairFactoryLike.sol";
import {LSSVMPair, CurveErrorCodes} from "LSSVMPair.sol";

contract SudoGate {
    address private SUDO_PAIR_FACTORY_ADDRESS = 0xb16c1342E617A5B6E4b631EB114483FDB289c0A4;
    address public owner; 

    uint256 public minBalanceForTransfer = 0.1 ether;
    uint256 public contributorFeePerThousand = 2;
    uint256 public protocolFeePerThousand = 1;
    uint256 public defaultSlippagePerThousand = 20;

    address payable public protocolFeeAddress;

    /* 
    to avoid transferring eth on every small fee, 
    keep track of balances in this mapping and then 
    send eth in larger batches 
    */
    mapping (address => uint256) public balances;
    uint256 public totalBalance = 0;


    // mapping from NFT addresses to array of known pools
    mapping (address => address[]) public pools;

    mapping (address => bool) public knownPool;

    // who contributed each pool
    mapping (address => address) public poolContributors;

    constructor() { 
        owner = msg.sender; 
        protocolFeeAddress = payable(msg.sender);
    }
    
    function setPairFactoryAddress(address addr) public {
        require(msg.sender == owner, "Only owner allowed to call setPairFactoryAddress");
        SUDO_PAIR_FACTORY_ADDRESS = addr;
    }

    function setProtocolFeeAddress(address payable addr) public {
        require(msg.sender == owner, "Only owner allowed to call setProtocolFeeAddress");
        protocolFeeAddress = addr;
    }
    
    function setProtocolFee(uint256 fee) public {
        /* 
            set fee (in 1/10th of a percent) which gets sent to protocol
            for every transaction
        */
        require(msg.sender == owner, "Only owner allowed to call setProtocolFee");
        protocolFeePerThousand = fee;
    }

    function setContributorFee(uint256 fee) public {
        /* 
            set fee (in 1/10th of a percent) which gets sent to whoever 
            contributed the pool address to SudoGate
        */
        require(msg.sender == owner, "Only owner allowed to call setContributorFee");
        contributorFeePerThousand = fee;
    }

    function setMinBalanceForTransfer(uint256 minVal) public {
        /* 
            set fee (in 1/10th of a percent) which gets sent to whoever 
            contributed the pool address to SudoGate
        */
        require(msg.sender == owner, "Only owner allowed to call setMinBalanceForTransfer");
        minBalanceForTransfer = minVal;
    }

    function setDefaultSlippage(uint256 slippagePerThousand) public {
        /* 
        controls the price fudge factor used to make sure we send enough ETH to sudoswap 
        even if our price computation doesn't quite agree with theirs
        */ 
        require(msg.sender == owner, "Only owner allowed to call setDefaultSlippage");
        defaultSlippagePerThousand = slippagePerThousand;
    }
    

    function totalFeesPerThousand() public view returns (uint256) {
        return protocolFeePerThousand + contributorFeePerThousand;
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

    function calcFeesAndSlippage(uint256 price, uint256 slippagePerThousand) internal view returns (
            uint256 protocolFee, 
            uint256 contributorFee,
            uint256 slippage) {
        require(contributorFeePerThousand <= 1000, "contributorFeePerThousand must be between 0 and 1000");
        require(protocolFeePerThousand <= 1000, "protocolFeePerThousand must be between 0 and 1000");
        require(slippagePerThousand <= 1000, "slippagePerThousand must be between 0 and 1000");
        
        // first scale everything up by a thousand so we get a little more fixed point precision
        uint256 priceX1000 = price * 1000; 
        require(priceX1000 > price, "Overflow in rescaled price");

        // if price is 1000x bigger and fees are per-thousand 
        // then need to divide by 1M to get something proportional to original price
        uint256 denom = 10 ** 6; 

        contributorFee = priceX1000 * contributorFeePerThousand / denom;
        require(contributorFee < price, "Contributor fee should be less than price");

        protocolFee = priceX1000 * protocolFeePerThousand / denom; 
        require(protocolFee < price, "Protocol fee should be less than price");
       
        if (slippagePerThousand > 0) {
            slippage = priceX1000 * slippagePerThousand / denom;
            require (slippage < price, "Slippage cannot be greater than 100%");
        } else {
            slippage = 0;
        }
        
    }

    function calcFees(uint256 price) internal view returns (
            uint256 protocolFee, 
            uint256 contributorFee) {
        (protocolFee, contributorFee, ) = calcFeesAndSlippage(price, 0);
    } 


    function adjustBuyPrice(uint256 price, uint256 slippagePerThousand) public view returns (uint256 adjustedPrice) {
        uint256 protocolFee;
        uint256 contributorFee;
        uint256 slippage;
        (protocolFee, contributorFee, slippage) = calcFeesAndSlippage(price, slippagePerThousand);
        uint256 combinedAdjustment = protocolFee + contributorFee + slippage; 
        require(combinedAdjustment < price, "Fees + slippage cannot exceed 100%");
        adjustedPrice =  price + combinedAdjustment; 
    }
    
    function adjustSellPrice(uint256 price, uint256 slippagePerThousand) public view returns (uint256 adjustedPrice) {
        uint256 protocolFee;
        uint256 contributorFee;
        uint256 slippage;
        (protocolFee, contributorFee, slippage) = calcFeesAndSlippage(price, slippagePerThousand);
        uint256 combinedAdjustment = protocolFee + contributorFee + slippage; 
        require(combinedAdjustment < price, "Fees + slippage cannot exceed 100%");
        adjustedPrice = price - combinedAdjustment; 
    }
    

    function addFee(address recipient, uint256 fee) internal {
        balances[recipient] += fee;
        totalBalance += fee;

        uint256 currentBalance = balances[recipient];
        if (currentBalance >= minBalanceForTransfer) {
            require(address(this).balance >= currentBalance, "Not enough ETH on contract");
            require(totalBalance >= currentBalance, "Don't lose track of how much ETH we have!");
            balances[recipient] = 0;
            totalBalance -= currentBalance;
            payable(recipient).transfer(currentBalance);
        }
    }

    function buyFromPool(address pool) public payable returns (uint256 tokenID) {
        /* returns token ID of purchased NFT */
        IERC721 nft = LSSVMPair(pool).nft();
        require(nft.balanceOf(pool) > 0, "Pool has no NFTs");
        uint256[] memory tokenIDs = LSSVMPair(pool).getAllHeldIds();
        tokenID = tokenIDs[tokenIDs.length - 1];
        uint256 startingValue = msg.value; 
        uint256 maxProtocolFee;
        uint256 maxContributorFee;
        
        (maxProtocolFee, maxContributorFee) = calcFees(startingValue);
        uint256 maxAllowedSpend = startingValue - (maxContributorFee + maxProtocolFee);

        uint256 usedAmt = LSSVMPair(pool).swapTokenForAnyNFTs{value: maxAllowedSpend}(
            1, 
            maxAllowedSpend, 
            msg.sender, 
            false, 
            address(0));
        require(usedAmt < startingValue, "Can't use more ETH than was originally sent");
        require(usedAmt > 0, "There ain't no such thing as a free lunch");
        
        // compute actual fees based on what got spent by sudoswap
        uint256 contributorFee; 
        uint256 protocolFee; 
        (protocolFee, contributorFee) = calcFees(usedAmt);
        uint256 amtWithFees = usedAmt + (protocolFee + contributorFee);
        require(amtWithFees <= startingValue, "Can't spend more than we were originally sent");
        
        addFee(poolContributors[pool], contributorFee);
        addFee(protocolFeeAddress, protocolFee);
        uint256 diff = startingValue - amtWithFees;
        // send back unused ETH
        if (diff > 0) { payable(msg.sender).transfer(diff); }
    }

    function buy(address nft) public payable returns (uint256 tokenID) {
        uint256 bestPrice;
        address bestPool;
        (bestPrice, bestPool) = buyQuote(nft);
        require(bestPool != address(0), "No pool found");
        require(bestPrice != type(uint256).max, "Invalid price");
        uint256 adjustedPrice = adjustBuyPrice(bestPrice, 5);
        require(adjustedPrice <= msg.value, "Not enough ETH for price of NFT");
        tokenID = buyFromPool(bestPool);
    }

    function buyQuote(address nft) public view returns (uint256 bestPrice, address bestPool) {
        /* 
        Returns best price for an NFT and the pool to buy it from. 
        Does not include SudoGate fees, see buyQuoteWithFees
        */
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


    function buyQuoteWithFees(address nft) public view returns (uint256 bestPrice, address bestPool) {
        /* 
        Returns best price for an NFT and the pool to buy it from. 
        Price is adjusted for SudoGate fees but assumes 0 slippage.
        */ 
        (bestPrice, bestPool) = buyQuote(nft);
        // add a small slippage factor 
        bestPrice = adjustBuyPrice(bestPrice, defaultSlippagePerThousand);
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
            payable(address(this)),
            false,
            address(0));

        require(outputAmount > 0, "Didn't get any ETH back");
        require(outputAmount > (bestPrice / 2), "Sale price slippage greater than 50%");

        // compute actual fees based on what got sent by sudoswap
        
        uint256 contributorFee; 
        uint256 protocolFee;
        
        (protocolFee, contributorFee) = calcFees(outputAmount);
        
        addFee(poolContributors[bestPool], contributorFee);
        addFee(protocolFeeAddress, protocolFee);
        
        uint256 combinedFees = protocolFee + contributorFee;
        require(combinedFees < outputAmount, "Fees can't exceed ETH received for selling");
        
        uint256 diff = outputAmount - combinedFees;
        
        // send back ETH after fees
        if (diff > 0) { payable(msg.sender).transfer(diff); }
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
            if (poolAddr.balance < bestPrice) {
                // check if pool actually has enough ETH to potentially give us a better price
                continue;
            } else {
                (err, , , outputAmount, ) = LSSVMPair(poolAddr).getSellNFTQuote(1);
                // make sure the pool has enough ETH to cover its own better offer
                if ((err == CurveErrorCodes.Error.OK) && 
                        (outputAmount > bestPrice) && 
                        (poolAddr.balance >= outputAmount)) { 
                    bestPool = poolAddr;
                    bestPrice = outputAmount;
                }
            }
        }
        require(bestPool != address(0), "Could not find a pool to buy from");
    }   

    
    function sellQuoteWithFees(address nft) public view returns (uint256 bestPrice, address bestPool) {
        /* 
        Returns best sell price for an NFT and the pool to sell it to. 
        Price is adjusted for SudoGate fees but assumes 0 slippage.
        */ 
        (bestPrice, bestPool) = sellQuote(nft);
        // include a small slippage factor  
        bestPrice = adjustSellPrice(bestPrice, defaultSlippagePerThousand);
    }

    
    // make it possible to receive ETH on this contract
    receive() external payable { }

    function rescueETH() public {
        // in case ETH gets trapped on this contract for some reason,
        // allow owner to manually withdraw it
        require(msg.sender == owner, "Only owner allowed to call rescueETH");
        require(address(this).balance >= totalBalance, "Not enough ETH on contract for balances");
        uint256 extraETH = address(this).balance - totalBalance;
        payable(owner).transfer(extraETH);
    }

    function withdraw() public {
        // let contributors withdraw ETH if they have any on the contract
        uint256 balance = balances[msg.sender];
        require(balance < address(this).balance, "Not enough ETH on contract");
        balances[msg.sender] = 0;
        totalBalance -= balance;
        payable(msg.sender).transfer(balance);
    }
}