// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "solmate/tokens/ERC20.sol";
import "solmate/tokens/ERC721.sol";
import "solmate/utils/MerkleProofLib.sol";
import "solmate/utils/SafeTransferLib.sol";
import "solmate/utils/FixedPointMathLib.sol";
import "openzeppelin/utils/math/Math.sol";
import "reservoir-oracle/ReservoirOracle.sol";

import "./LpToken.sol";
import "./Caviar.sol";
import "./StolenNftFilterOracle.sol";

/// @title Pair
/// @author out.eth (@outdoteth)
/// @notice A pair of an NFT and a base token that can be used to create and trade fractionalized NFTs.
contract Pair is ERC20, ERC721TokenReceiver {
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    uint256 public constant CLOSE_GRACE_PERIOD = 7 days;
    uint256 private constant ONE = 1e18;
    uint256 private constant MINIMUM_LIQUIDITY = 100_000;

    address public immutable nft;
    address public immutable baseToken; // address(0) for ETH
    bytes32 public immutable merkleRoot;
    LpToken public immutable lpToken;
    Caviar public immutable caviar;
    uint256 public closeTimestamp;

    event Add(uint256 indexed baseTokenAmount, uint256 indexed fractionalTokenAmount, uint256 indexed lpTokenAmount);
    event Remove(uint256 indexed baseTokenAmount, uint256 indexed fractionalTokenAmount, uint256 indexed lpTokenAmount);
    event Buy(uint256 indexed inputAmount, uint256 indexed outputAmount);
    event Sell(uint256 indexed inputAmount, uint256 indexed outputAmount);
    event Wrap(uint256[] indexed tokenIds);
    event Unwrap(uint256[] indexed tokenIds);
    event Close(uint256 indexed closeTimestamp);
    event Withdraw(uint256 indexed tokenId);

    constructor(
        address _nft,
        address _baseToken,
        bytes32 _merkleRoot,
        string memory pairSymbol,
        string memory nftName,
        string memory nftSymbol
    ) ERC20(string.concat(nftName, " fractional token"), string.concat("f", nftSymbol), 18) {
        nft = _nft;
        baseToken = _baseToken; // use address(0) for native ETH
        merkleRoot = _merkleRoot;
        lpToken = new LpToken(pairSymbol);
        caviar = Caviar(msg.sender);
    }

    // ************************ //
    //      Core AMM logic      //
    // ***********************  //

    /// @notice Adds liquidity to the pair.
    /// @param baseTokenAmount The amount of base tokens to add.
    /// @param fractionalTokenAmount The amount of fractional tokens to add.
    /// @param minLpTokenAmount The minimum amount of LP tokens to mint.
    /// @param minPrice The minimum price that the pool should currently be at.
    /// @param maxPrice The maximum price that the pool should currently be at.
    /// @param deadline The deadline before the trade expires.
    /// @return lpTokenAmount The amount of LP tokens minted.
    function add(
        uint256 baseTokenAmount,
        uint256 fractionalTokenAmount,
        uint256 minLpTokenAmount,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 deadline
    ) public payable returns (uint256 lpTokenAmount) {
        // *** Checks *** //

        // check that the trade has not expired
        require(deadline == 0 || deadline >= block.timestamp, "Expired");

        // check the token amount inputs are not zero
        require(baseTokenAmount > 0 && fractionalTokenAmount > 0, "Input token amount is zero");

        // check that correct eth input was sent - if the baseToken equals address(0) then native ETH is used
        require(baseToken == address(0) ? msg.value == baseTokenAmount : msg.value == 0, "Invalid ether input");

        uint256 lpTokenSupply = lpToken.totalSupply();

        // check that the price is within the bounds if there is liquidity in the pool
        if (lpTokenSupply != 0) {
            uint256 _price = price();
            require(_price >= minPrice && _price <= maxPrice, "Slippage: price out of bounds");
        }

        // calculate the lp token shares to mint
        lpTokenAmount = addQuote(baseTokenAmount, fractionalTokenAmount, lpTokenSupply);

        // check that the amount of lp tokens outputted is greater than the min amount
        require(lpTokenAmount >= minLpTokenAmount, "Slippage: lp token amount out");

        // *** Effects *** //

        // transfer fractional tokens in
        _transferFrom(msg.sender, address(this), fractionalTokenAmount);

        // *** Interactions *** //

        // mint lp tokens to sender
        lpToken.mint(msg.sender, lpTokenAmount);

        // transfer first MINIMUM_LIQUIDITY lp tokens to the owner
        if (lpTokenSupply == 0) {
            lpToken.mint(caviar.owner(), MINIMUM_LIQUIDITY);
        }

        // transfer base tokens in if the base token is not ETH
        if (baseToken != address(0)) {
            // transfer base tokens in
            ERC20(baseToken).safeTransferFrom(msg.sender, address(this), baseTokenAmount);
        }

        emit Add(baseTokenAmount, fractionalTokenAmount, lpTokenAmount);
    }

    /// @notice Removes liquidity from the pair.
    /// @param lpTokenAmount The amount of LP tokens to burn.
    /// @param minBaseTokenOutputAmount The minimum amount of base tokens to receive.
    /// @param minFractionalTokenOutputAmount The minimum amount of fractional tokens to receive.
    /// @param deadline The deadline before the trade expires.
    /// @return baseTokenOutputAmount The amount of base tokens received.
    /// @return fractionalTokenOutputAmount The amount of fractional tokens received.
    function remove(
        uint256 lpTokenAmount,
        uint256 minBaseTokenOutputAmount,
        uint256 minFractionalTokenOutputAmount,
        uint256 deadline
    ) public returns (uint256 baseTokenOutputAmount, uint256 fractionalTokenOutputAmount) {
        // *** Checks *** //

        // check that the trade has not expired
        require(deadline == 0 || deadline >= block.timestamp, "Expired");

        // calculate the output amounts
        (baseTokenOutputAmount, fractionalTokenOutputAmount) = removeQuote(lpTokenAmount);

        // check that the base token output amount is greater than the min amount
        require(baseTokenOutputAmount >= minBaseTokenOutputAmount, "Slippage: base token amount out");

        // check that the fractional token output amount is greater than the min amount
        require(fractionalTokenOutputAmount >= minFractionalTokenOutputAmount, "Slippage: fractional token out");

        // *** Effects *** //

        // transfer fractional tokens to sender
        _transferFrom(address(this), msg.sender, fractionalTokenOutputAmount);

        // *** Interactions *** //

        // burn lp tokens from sender
        lpToken.burn(msg.sender, lpTokenAmount);

        if (baseToken == address(0)) {
            // if base token is native ETH then send ether to sender
            msg.sender.safeTransferETH(baseTokenOutputAmount);
        } else {
            // transfer base tokens to sender
            ERC20(baseToken).safeTransfer(msg.sender, baseTokenOutputAmount);
        }

        emit Remove(baseTokenOutputAmount, fractionalTokenOutputAmount, lpTokenAmount);
    }

    /// @notice Buys fractional tokens from the pair.
    /// @param outputAmount The amount of fractional tokens to buy.
    /// @param maxInputAmount The maximum amount of base tokens to spend.
    /// @param deadline The deadline before the trade expires.
    /// @return inputAmount The amount of base tokens spent.
    function buy(uint256 outputAmount, uint256 maxInputAmount, uint256 deadline)
        public
        payable
        returns (uint256 inputAmount)
    {
        // *** Checks *** //

        // check that the trade has not expired
        require(deadline == 0 || deadline >= block.timestamp, "Expired");

        // check that correct eth input was sent - if the baseToken equals address(0) then native ETH is used
        require(baseToken == address(0) ? msg.value == maxInputAmount : msg.value == 0, "Invalid ether input");

        // calculate required input amount using xyk invariant
        inputAmount = buyQuote(outputAmount);

        // check that the required amount of base tokens is less than the max amount
        require(inputAmount <= maxInputAmount, "Slippage: amount in");

        // *** Effects *** //

        // transfer fractional tokens to sender
        _transferFrom(address(this), msg.sender, outputAmount);

        // *** Interactions *** //

        if (baseToken == address(0)) {
            // refund surplus eth
            uint256 refundAmount = maxInputAmount - inputAmount;
            if (refundAmount > 0) msg.sender.safeTransferETH(refundAmount);
        } else {
            // transfer base tokens in
            ERC20(baseToken).safeTransferFrom(msg.sender, address(this), inputAmount);
        }

        emit Buy(inputAmount, outputAmount);
    }

    /// @notice Sells fractional tokens to the pair.
    /// @param inputAmount The amount of fractional tokens to sell.
    /// @param deadline The deadline before the trade expires.
    /// @param minOutputAmount The minimum amount of base tokens to receive.
    /// @return outputAmount The amount of base tokens received.
    function sell(uint256 inputAmount, uint256 minOutputAmount, uint256 deadline)
        public
        returns (uint256 outputAmount)
    {
        // *** Checks *** //

        // check that the trade has not expired
        require(deadline == 0 || deadline >= block.timestamp, "Expired");

        // calculate output amount using xyk invariant
        outputAmount = sellQuote(inputAmount);

        // check that the outputted amount of fractional tokens is greater than the min amount
        require(outputAmount >= minOutputAmount, "Slippage: amount out");

        // *** Effects *** //

        // transfer fractional tokens from sender
        _transferFrom(msg.sender, address(this), inputAmount);

        // *** Interactions *** //

        if (baseToken == address(0)) {
            // transfer ether out
            msg.sender.safeTransferETH(outputAmount);
        } else {
            // transfer base tokens out
            ERC20(baseToken).safeTransfer(msg.sender, outputAmount);
        }

        emit Sell(inputAmount, outputAmount);
    }

    // ******************** //
    //      Wrap logic      //
    // ******************** //

    /// @notice Wraps NFTs into fractional tokens.
    /// @param tokenIds The ids of the NFTs to wrap.
    /// @param proofs The merkle proofs for the NFTs proving that they can be used in the pair.
    /// @return fractionalTokenAmount The amount of fractional tokens minted.
    function wrap(uint256[] calldata tokenIds, bytes32[][] calldata proofs, ReservoirOracle.Message[] calldata messages)
        public
        returns (uint256 fractionalTokenAmount)
    {
        // *** Checks *** //

        // check that wrapping is not closed
        require(closeTimestamp == 0, "Wrap: closed");

        // check the tokens exist in the merkle root
        _validateTokenIds(tokenIds, proofs);

        // check that the tokens are not stolen with reservoir oracle
        _validateTokensAreNotStolen(tokenIds, messages);

        // *** Effects *** //

        // mint fractional tokens to sender
        fractionalTokenAmount = tokenIds.length * ONE;
        _mint(msg.sender, fractionalTokenAmount);

        // *** Interactions *** //

        // transfer nfts from sender
        for (uint256 i = 0; i < tokenIds.length;) {
            ERC721(nft).safeTransferFrom(msg.sender, address(this), tokenIds[i]);

            unchecked {
                i++;
            }
        }

        emit Wrap(tokenIds);
    }

    /// @notice Unwraps fractional tokens into NFTs.
    /// @param tokenIds The ids of the NFTs to unwrap.
    /// @param withFee Whether to pay a fee for unwrapping or not.
    /// @return fractionalTokenAmount The amount of fractional tokens burned.
    function unwrap(uint256[] calldata tokenIds, bool withFee) public returns (uint256 fractionalTokenAmount) {
        // *** Effects *** //

        // burn fractional tokens from sender
        fractionalTokenAmount = tokenIds.length * ONE;
        _burn(msg.sender, fractionalTokenAmount);

        // Take the fee if withFee is true
        if (withFee) {
            // calculate fee
            uint256 fee = fractionalTokenAmount * 3 / 1000;

            // transfer fee from sender
            _transferFrom(msg.sender, address(this), fee);
            fractionalTokenAmount += fee;
        }

        // transfer nfts to sender
        for (uint256 i = 0; i < tokenIds.length;) {
            ERC721(nft).safeTransferFrom(address(this), msg.sender, tokenIds[i]);

            unchecked {
                i++;
            }
        }

        emit Unwrap(tokenIds);
    }

    // *********************** //
    //      NFT AMM logic      //
    // *********************** //

    /// @notice nftAdd Adds liquidity to the pair using NFTs.
    /// @param baseTokenAmount The amount of base tokens to add.
    /// @param tokenIds The ids of the NFTs to add.
    /// @param minLpTokenAmount The minimum amount of lp tokens to receive.
    /// @param minPrice The minimum price of the pair.
    /// @param maxPrice The maximum price of the pair.
    /// @param deadline The deadline for the transaction.
    /// @param proofs The merkle proofs for the NFTs.
    /// @return lpTokenAmount The amount of lp tokens minted.
    function nftAdd(
        uint256 baseTokenAmount,
        uint256[] calldata tokenIds,
        uint256 minLpTokenAmount,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 deadline,
        bytes32[][] calldata proofs,
        ReservoirOracle.Message[] calldata messages
    ) public payable returns (uint256 lpTokenAmount) {
        // wrap the incoming NFTs into fractional tokens
        uint256 fractionalTokenAmount = wrap(tokenIds, proofs, messages);

        // add liquidity using the fractional tokens and base tokens
        lpTokenAmount = add(baseTokenAmount, fractionalTokenAmount, minLpTokenAmount, minPrice, maxPrice, deadline);
    }

    /// @notice Removes liquidity from the pair using NFTs.
    /// @param lpTokenAmount The amount of lp tokens to remove.
    /// @param minBaseTokenOutputAmount The minimum amount of base tokens to receive.
    /// @param deadline The deadline before the trade expires.
    /// @param tokenIds The ids of the NFTs to remove.
    /// @param withFee Whether to pay a fee for unwrapping or not.
    /// @return baseTokenOutputAmount The amount of base tokens received.
    /// @return fractionalTokenOutputAmount The amount of fractional tokens received.
    function nftRemove(
        uint256 lpTokenAmount,
        uint256 minBaseTokenOutputAmount,
        uint256 deadline,
        uint256[] calldata tokenIds,
        bool withFee
    ) public returns (uint256 baseTokenOutputAmount, uint256 fractionalTokenOutputAmount) {
        // remove liquidity and send fractional tokens and base tokens to sender
        (baseTokenOutputAmount, fractionalTokenOutputAmount) =
            remove(lpTokenAmount, minBaseTokenOutputAmount, tokenIds.length * ONE, deadline);

        // unwrap the fractional tokens into NFTs and send to sender
        unwrap(tokenIds, withFee);
    }

    /// @notice Buys NFTs from the pair using base tokens.
    /// @param tokenIds The ids of the NFTs to buy.
    /// @param maxInputAmount The maximum amount of base tokens to spend.
    /// @param deadline The deadline before the trade expires.
    /// @return inputAmount The amount of base tokens spent.
    function nftBuy(uint256[] calldata tokenIds, uint256 maxInputAmount, uint256 deadline)
        public
        payable
        returns (uint256 inputAmount)
    {
        // buy fractional tokens using base tokens
        inputAmount = buy(tokenIds.length * ONE, maxInputAmount, deadline);

        // unwrap the fractional tokens into NFTs and send to sender
        unwrap(tokenIds, false);
    }

    /// @notice Sells NFTs to the pair for base tokens.
    /// @param tokenIds The ids of the NFTs to sell.
    /// @param minOutputAmount The minimum amount of base tokens to receive.
    /// @param deadline The deadline before the trade expires.
    /// @param proofs The merkle proofs for the NFTs.
    /// @return outputAmount The amount of base tokens received.
    function nftSell(
        uint256[] calldata tokenIds,
        uint256 minOutputAmount,
        uint256 deadline,
        bytes32[][] calldata proofs,
        ReservoirOracle.Message[] calldata messages
    ) public returns (uint256 outputAmount) {
        // wrap the incoming NFTs into fractional tokens
        uint256 inputAmount = wrap(tokenIds, proofs, messages);

        // sell fractional tokens for base tokens
        outputAmount = sell(inputAmount, minOutputAmount, deadline);
    }

    // ****************************** //
    //      Emergency exit logic      //
    // ****************************** //

    /// @notice Closes the pair to new wraps.
    /// @dev Can only be called by the caviar owner. This is used as an emergency exit in case
    ///      the caviar owner suspects that the pair has been compromised.
    function close() public {
        // check that the sender is the caviar owner
        require(caviar.owner() == msg.sender, "Close: not owner");

        // set the close timestamp with a grace period
        closeTimestamp = block.timestamp + CLOSE_GRACE_PERIOD;

        // remove the pair from the Caviar contract
        caviar.destroy(nft, baseToken, merkleRoot);

        emit Close(closeTimestamp);
    }

    /// @notice Withdraws a particular NFT from the pair.
    /// @dev Can only be called by the caviar owner after the close grace period has passed. This
    ///      is used to auction off the NFTs in the pair in case NFTs get stuck due to liquidity
    ///      imbalances. Proceeds from the auction should be distributed pro rata to fractional
    ///      token holders. See documentation for more details.
    function withdraw(uint256 tokenId) public {
        // check that the sender is the caviar owner
        require(caviar.owner() == msg.sender, "Withdraw: not owner");

        // check that the close period has been set
        require(closeTimestamp != 0, "Withdraw not initiated");

        // check that the close grace period has passed
        require(block.timestamp >= closeTimestamp, "Not withdrawable yet");

        // transfer the nft to the caviar owner
        ERC721(nft).safeTransferFrom(address(this), msg.sender, tokenId);

        emit Withdraw(tokenId);
    }

    // ***************** //
    //      Getters      //
    // ***************** //

    function baseTokenReserves() public view returns (uint256) {
        return _baseTokenReserves();
    }

    function fractionalTokenReserves() public view returns (uint256) {
        return balanceOf[address(this)];
    }

    /// @notice The current price of one fractional token in base tokens with 18 decimals of precision.
    /// @dev Calculated by dividing the base token reserves by the fractional token reserves.
    /// @return price The price of one fractional token in base tokens * 1e18.
    function price() public view returns (uint256) {
        uint256 exponent = baseToken == address(0) ? 18 : (36 - ERC20(baseToken).decimals());
        return (_baseTokenReserves() * 10 ** exponent) / fractionalTokenReserves();
    }

    /// @notice The amount of base tokens required to buy a given amount of fractional tokens.
    /// @dev Calculated using the xyk invariant and a 30bps fee.
    /// @param outputAmount The amount of fractional tokens to buy.
    /// @return inputAmount The amount of base tokens required.
    function buyQuote(uint256 outputAmount) public view returns (uint256) {
        return FixedPointMathLib.mulDivUp(
            outputAmount * 1000, baseTokenReserves(), (fractionalTokenReserves() - outputAmount) * 990
        );
    }

    /// @notice The amount of base tokens received for selling a given amount of fractional tokens.
    /// @dev Calculated using the xyk invariant and a 30bps fee.
    /// @param inputAmount The amount of fractional tokens to sell.
    /// @return outputAmount The amount of base tokens received.
    function sellQuote(uint256 inputAmount) public view returns (uint256) {
        uint256 inputAmountWithFee = inputAmount * 990;
        return (inputAmountWithFee * baseTokenReserves()) / ((fractionalTokenReserves() * 1000) + inputAmountWithFee);
    }

    /// @notice The amount of lp tokens received for adding a given amount of base tokens and fractional tokens.
    /// @dev Calculated as a share of existing deposits. If there are no existing deposits, then initializes to
    ///      sqrt(baseTokenAmount * fractionalTokenAmount).
    /// @param baseTokenAmount The amount of base tokens to add.
    /// @param fractionalTokenAmount The amount of fractional tokens to add.
    /// @return lpTokenAmount The amount of lp tokens received.
    function addQuote(uint256 baseTokenAmount, uint256 fractionalTokenAmount, uint256 lpTokenSupply)
        public
        view
        returns (uint256)
    {
        if (lpTokenSupply != 0) {
            // calculate amount of lp tokens as a fraction of existing reserves
            uint256 baseTokenShare = (baseTokenAmount * lpTokenSupply) / baseTokenReserves();
            uint256 fractionalTokenShare = (fractionalTokenAmount * lpTokenSupply) / fractionalTokenReserves();
            return Math.min(baseTokenShare, fractionalTokenShare);
        } else {
            // if there is no liquidity then init
            return Math.sqrt(baseTokenAmount * fractionalTokenAmount) - MINIMUM_LIQUIDITY;
        }
    }

    /// @notice The amount of base tokens and fractional tokens received for burning a given amount of lp tokens.
    /// @dev Calculated as a share of existing deposits.
    /// @param lpTokenAmount The amount of lp tokens to burn.
    /// @return baseTokenAmount The amount of base tokens received.
    /// @return fractionalTokenAmount The amount of fractional tokens received.
    function removeQuote(uint256 lpTokenAmount) public view returns (uint256, uint256) {
        uint256 lpTokenSupply = lpToken.totalSupply();
        uint256 baseTokenOutputAmount = (baseTokenReserves() * lpTokenAmount) / lpTokenSupply;
        uint256 fractionalTokenOutputAmount = (fractionalTokenReserves() * lpTokenAmount) / lpTokenSupply;
        uint256 upperFractionalTokenOutputAmount = (fractionalTokenReserves() * (lpTokenAmount + 1)) / lpTokenSupply;

        if (
            fractionalTokenOutputAmount % 1e18 != 0
                && upperFractionalTokenOutputAmount - fractionalTokenOutputAmount <= 1000 && lpTokenSupply > 1e15
        ) {
            fractionalTokenOutputAmount = upperFractionalTokenOutputAmount;
        }

        return (baseTokenOutputAmount, fractionalTokenOutputAmount);
    }

    // ************************ //
    //      Internal utils      //
    // ************************ //

    function _transferFrom(address from, address to, uint256 amount) internal returns (bool) {
        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    function _validateTokensAreNotStolen(uint256[] calldata tokenIds, ReservoirOracle.Message[] calldata messages)
        internal
        view
    {
        address stolenNftFilterAddress = caviar.stolenNftFilterOracle();

        // if filter address is not set then no need to check if nfts are stolen
        if (stolenNftFilterAddress == address(0)) return;

        // validate that nfts are not stolen
        StolenNftFilterOracle(stolenNftFilterAddress).validateTokensAreNotStolen(nft, tokenIds, messages);
    }

    /// @dev Validates that the given tokenIds are valid for the contract's merkle root. Reverts
    ///      if any of the tokenId proofs are invalid.
    function _validateTokenIds(uint256[] calldata tokenIds, bytes32[][] calldata proofs) internal view {
        // if merkle root is not set then all tokens are valid
        if (merkleRoot == bytes32(0)) return;

        // validate merkle proofs against merkle root
        for (uint256 i = 0; i < tokenIds.length;) {
            bool isValid = MerkleProofLib.verify(
                proofs[i],
                merkleRoot,
                // double hash to prevent second preimage attacks
                keccak256(bytes.concat(keccak256(abi.encode(tokenIds[i]))))
            );

            require(isValid, "Invalid merkle proof");

            unchecked {
                i++;
            }
        }
    }

    /// @dev Returns the current base token reserves. If the base token is ETH then it ignores
    ///      the msg.value that is being sent in the current call context - this is to ensure the
    ///      xyk math is correct in the buy() and add() functions.
    function _baseTokenReserves() internal view returns (uint256) {
        return baseToken == address(0)
            ? address(this).balance - msg.value // subtract the msg.value if the base token is ETH
            : ERC20(baseToken).balanceOf(address(this));
    }
}