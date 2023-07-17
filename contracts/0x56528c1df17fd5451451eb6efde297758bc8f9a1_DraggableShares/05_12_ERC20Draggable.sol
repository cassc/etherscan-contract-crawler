/**
 * SPDX-License-Identifier: LicenseRef-Aktionariat
 *
 * MIT License with Automated License Fee Payments
 *
 * Copyright (c) 2020 Aktionariat AG (aktionariat.com)
 *
 * Permission is hereby granted to any person obtaining a copy of this software
 * and associated documentation files (the "Software"), to deal in the Software
 * without restriction, including without limitation the rights to use, copy,
 * modify, merge, publish, distribute, sublicense, and/or sell copies of the
 * Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * - The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 * - All automated license fee payments integrated into this and related Software
 *   are preserved.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
pragma solidity ^0.8.0;

/**
 * @title ERC-20 tokens subject to a drag-along agreement
 * @author Luzius Meisser, [email protected]
 *
 * This is an ERC-20 token that is bound to a shareholder or other agreement that contains
 * a drag-along clause. The smart contract can help enforce this drag-along clause in case
 * an acquirer makes an offer using the provided functionality. If a large enough quorum of
 * token holders agree, the remaining token holders can be automatically "dragged along" or
 * squeezed out. For shares non-tokenized shares, the contract relies on an external Oracle
 * to provide the votes of those.
 *
 * Subclasses should provide a link to a human-readable form of the agreement.
 */

import "./IDraggable.sol";
import "../ERC20/ERC20Flaggable.sol";
import "../ERC20/IERC20.sol";
import "../ERC20/IERC677Receiver.sol";
import "./IOffer.sol";
import "./IOfferFactory.sol";
import "../shares/IShares.sol";

abstract contract ERC20Draggable is IERC677Receiver, IDraggable, ERC20Flaggable {
    
	// If flag is not present, one can be sure that the address did not vote. If the 
	// flag is present, the address might have voted and one needs to check with the
	// current offer (if any) when transferring tokens.
	uint8 private constant FLAG_VOTE_HINT = 1;

	IERC20 public wrapped; // The wrapped contract
	IOfferFactory public immutable factory;

	// If the wrapped tokens got replaced in an acquisition, unwrapping might yield many currency tokens
	uint256 public unwrapConversionFactor = 0;

	// The current acquisition attempt, if any. See initiateAcquisition to see the requirements to make a public offer.
	IOffer public offer;

	uint256 private constant QUORUM_MULTIPLIER = 10000;

	uint256 public immutable quorum; // BPS (out of 10'000)
	uint256 public immutable votePeriod; // In seconds

	address public override oracle;

	event MigrationSucceeded(address newContractAddress, uint256 yesVotes, uint256 oracleVotes, uint256 totalVotingPower);
	event ChangeOracle(address oracle);

    /**
	 * Note that the Brokerbot only supports tokens that revert on failure and where transfer never returns false.
     */
	constructor(
		IERC20 _wrappedToken,
		uint256 _quorum,
		uint256 _votePeriod,
		IOfferFactory _offerFactory,
		address _oracle
	) 
		ERC20Flaggable(0)
	{
		wrapped = _wrappedToken;
		quorum = _quorum;
		votePeriod = _votePeriod;
		factory = _offerFactory;
		oracle = _oracle;
	}

	function onTokenTransfer(
		address from, 
		uint256 amount, 
		bytes calldata
	) external override returns (bool) {
		require(msg.sender == address(wrapped), "sender");
		_mint(from, amount);
		return true;
	}

	/** Wraps additional tokens, thereby creating more ERC20Draggable tokens. */
	function wrap(address shareholder, uint256 amount) external {
		require(wrapped.transferFrom(msg.sender, address(this), amount), "transfer");
		_mint(shareholder, amount);
	}

	/**
	 * Indicates that the token holders are bound to the token terms and that:
	 * - Conversion back to the wrapped token (unwrap) is not allowed
	 * - A drag-along can be performed by making an according offer
	 * - They can be migrated to a new version of this contract in accordance with the terms
	 */
	function isBinding() public view returns (bool) {
		return unwrapConversionFactor == 0;
	}

    /**
	 * Current recommended naming convention is to add the postfix "SHA" to the plain shares
	 * in order to indicate that this token represents shares bound to a shareholder agreement.
	 */
	function name() public view override returns (string memory) {
		string memory wrappedName = wrapped.name();
		if (isBinding()) {
			return string(abi.encodePacked(wrappedName, " SHA"));
		} else {
			return string(abi.encodePacked(wrappedName, " (Wrapped)"));
		}
	}

	function symbol() public view override returns (string memory) {
		// ticker should be less dynamic than name
		return string(abi.encodePacked(wrapped.symbol(), "S"));
	}

	/**
	 * Deactivates the drag-along mechanism and enables the unwrap function.
	 */
	function deactivate(uint256 factor) internal {
		require(factor >= 1, "factor");
		unwrapConversionFactor = factor;
		emit NameChanged(name(), symbol());
	}

	/** Decrease the number of drag-along tokens. The user gets back their shares in return */
	function unwrap(uint256 amount) external {
		require(!isBinding(), "factor");
		unwrap(msg.sender, amount, unwrapConversionFactor);
	}

	function unwrap(address owner, uint256 amount, uint256 factor) internal {
		_burn(owner, amount);
		require(wrapped.transfer(owner, amount * factor), "transfer");
	}

	/**
	 * Burns both the token itself as well as the wrapped token!
	 * If you want to get out of the shareholder agreement, use unwrap after it has been
	 * deactivated by a majority vote or acquisition.
	 *
	 * Burning only works if wrapped token supports burning. Also, the exact meaning of this
	 * operation might depend on the circumstances. Burning and reussing the wrapped token
	 * does not free the sender from the legal obligations of the shareholder agreement.
	 */
	function burn(uint256 amount) external {
		_burn(msg.sender, amount);
		IShares(address(wrapped)).burn (isBinding() ? amount : amount * unwrapConversionFactor);
	}

	function makeAcquisitionOffer(
		bytes32 salt, 
		uint256 pricePerShare, 
		IERC20 currency
	) external payable {
		require(isBinding(), "factor");
		IOffer newOffer = factory.create{value: msg.value}(
			salt, msg.sender, pricePerShare, currency, quorum, votePeriod);

		if (offerExists()) {
			offer.makeCompetingOffer(newOffer);
		}
		offer = newOffer;
	}

	function drag(address buyer, IERC20 currency) external override offerOnly {
		unwrap(buyer, balanceOf(buyer), 1);
		replaceWrapped(currency, buyer);
	}

	function notifyOfferEnded() external override offerOnly {
		offer = IOffer(address(0));
	}

	function replaceWrapped(IERC20 newWrapped, address oldWrappedDestination) internal {
		require(isBinding(), "factor");
		// Free all old wrapped tokens we have
		require(wrapped.transfer(oldWrappedDestination, wrapped.balanceOf(address(this))), "transfer");
		// Count the new wrapped tokens
		wrapped = newWrapped;
		deactivate(newWrapped.balanceOf(address(this)) / totalSupply());
	}

	function setOracle(address newOracle) external {
		require(msg.sender == oracle, "not oracle");
		oracle = newOracle;
		emit ChangeOracle(oracle);
	}

	function migrateWithExternalApproval(address successor, uint256 additionalVotes) external {
		require(msg.sender == oracle, "not oracle");
		// Additional votes cannot be higher than the votes not represented by these tokens.
		// The assumption here is that more shareholders are bound to the shareholder agreement
		// that this contract helps enforce and a vote among all parties is necessary to change
		// it, with an oracle counting and reporting the votes of the others.
		require(totalSupply() + additionalVotes <= totalVotingTokens(), "votes");
		migrate(successor, additionalVotes);
	}

	function migrate() external {
		migrate(msg.sender, 0);
	}

	function migrate(address successor, uint256 additionalVotes) internal {
		uint256 yesVotes = additionalVotes + balanceOf(successor);
		uint256 totalVotes = totalVotingTokens();
		require(yesVotes <= totalVotes, "votes");
		require(!offerExists(), "no offer"); // if you have the quorum, you can cancel the offer first if necessary
		require(yesVotes * QUORUM_MULTIPLIER >= totalVotes * quorum, "quorum");
		replaceWrapped(IERC20(successor), successor);
		emit MigrationSucceeded(successor, yesVotes, additionalVotes, totalVotes);
	}

	function votingPower(address voter) external view override returns (uint256) {
		return balanceOf(voter);
	}

	function totalVotingTokens() public view override returns (uint256) {
		return IShares(address(wrapped)).totalShares();
	}

	function hasVoted(address voter) internal view returns (bool) {
		return hasFlagInternal(voter, FLAG_VOTE_HINT);
	}

	function notifyVoted(address voter) external override offerOnly {
		setFlag(voter, FLAG_VOTE_HINT, true);
	}

	modifier offerOnly(){
		require(msg.sender == address(offer), "sender");
		_;
	}

	function _beforeTokenTransfer(address from, address to,	uint256 amount) internal virtual override {
		if (hasVoted(from) || hasVoted(to)) {
			if (offerExists()) {
				offer.notifyMoved(from, to, amount);
			} else {
				setFlag(from, FLAG_VOTE_HINT, false);
				setFlag(to, FLAG_VOTE_HINT, false);
			}
		}
		super._beforeTokenTransfer(from, to, amount);
	}

	function offerExists() internal view returns (bool) {
		return address(offer) != address(0);
	}
}