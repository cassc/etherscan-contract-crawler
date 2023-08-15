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

import "../ERC20/IERC20.sol";
import "./IDraggable.sol";
import "./IOffer.sol";
/**
 * @title A public offer to acquire all tokens
 * @author Luzius Meisser, [email protected]
 */

contract Offer is IOffer {

    address private constant LICENSE_FEE_ADDRESS = 0x29Fe8914e76da5cE2d90De98a64d0055f199d06D;

    uint256 private constant AQUISITION_GRACE_PERIOD = 30 days;     // buyer has thirty days to complete acquisition after voting ends
    
    uint256 private constant BPS_MUL = 10000;           // basis point multiplier to be used with quorum

    uint256 public immutable quorum;                    // Percentage of votes needed to start drag-along process in BPS, i.e. 10'000 = 100%

    IDraggable public immutable token;
    address public immutable buyer;                     // who made the offer
    
    IERC20 override public immutable currency;
    uint256 override public immutable price;            // the price offered per share

    enum Vote { NONE, YES, NO }                         // Used internally, represents not voted yet or yes/no vote.
    mapping (address => Vote) private votes;            // Who votes what
    uint256 public yesVotes;                            // total number of yes votes, including external votes
    uint256 public noVotes;                             // total number of no votes, including external votes
    uint256 public noExternal;                          // number of external no votes reported by oracle
    uint256 public yesExternal;                         // number of external yes votes reported by oracle

    uint256 public immutable voteEnd;                   // end of vote period in block time (seconds after 1.1.1970)

    event VotesChanged(uint256 yesVotes, uint256 noVotes);
    event OfferCreated(address indexed buyer, IDraggable indexed token, uint256 pricePerShare, IERC20 indexed currency);
    event OfferEnded(address indexed buyer, bool success, string message); // not sure if it makes sense to index success here

    // Not checked here, but buyer should make sure it is well funded from the beginning
    constructor(
        address _buyer,
        IDraggable _token,
        uint256 _price,
        IERC20 _currency,
        uint256 _quorum,
        uint256 _votePeriod
    ) 
        payable 
    {
        buyer = _buyer;
        token = _token;
        currency = _currency;
        price = _price;
        quorum = _quorum;
        // rely on time stamp is ok, no exact time stamp needed
        // solhint-disable-next-line not-rely-on-time
        voteEnd = block.timestamp + _votePeriod;
        emit OfferCreated(_buyer, _token, _price, _currency);
        // License Fee to Aktionariat AG, also ensures that offer is serious.
        // Any circumvention of this license fee payment is a violation of the copyright terms.
        payable(LICENSE_FEE_ADDRESS).transfer(3 ether);
    }

    function makeCompetingOffer(IOffer betterOffer) external override {
        require(msg.sender == address(token), "invalid caller");
        require(!isAccepted(), "old already accepted");
        require(currency == betterOffer.currency() && betterOffer.price() > price, "old offer better");
        require(betterOffer.isWellFunded(), "not funded");
        kill(false, "replaced");
    }

    function hasExpired() internal view returns (bool) {
        // rely on time stamp is ok, no exact time stamp needed
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp > voteEnd + AQUISITION_GRACE_PERIOD; 
    }

    function contest() external {
        if (hasExpired()) {
            kill(false, "expired");
        } else if (isDeclined()) {
            kill(false, "declined");
        } else if (!isWellFunded()) {
            kill(false, "lack of funds");
        }
    }

    function cancel() external {
        require(msg.sender == buyer, "invalid caller");
        kill(false, "cancelled");
    }

    function execute() external {
        require(msg.sender == buyer, "not buyer");
        require(isAccepted(), "not accepted");
        uint256 totalPrice = getTotalPrice();
        require(currency.transferFrom(buyer, address(token), totalPrice), "transfer failed");
        token.drag(buyer, currency);
        kill(true, "success");
    }

    function getTotalPrice() internal view returns (uint256) {
        IERC20 tok = IERC20(address(token));
        return (tok.totalSupply() - tok.balanceOf(buyer)) * price;
    }

    function isWellFunded() public view override returns (bool) {
        uint256 buyerBalance = currency.balanceOf(buyer);
        uint256 totalPrice = getTotalPrice();
        return totalPrice <= buyerBalance;
    }

    function isAccepted() public view returns (bool) {
        if (isVotingOpen()) {
            // is it already clear that more than the quorum requiered will vote yes even though the vote is not over yet?
            return yesVotes * BPS_MUL  >= quorum * token.totalVotingTokens();
        } else {
            // did more than the quorum requiered votes say 'yes'?
            return yesVotes * BPS_MUL >= quorum * (yesVotes + noVotes);
        }
    }

    function isDeclined() public view returns (bool) {
        if (isVotingOpen()) {
            // is it already clear that 25% will vote no even though the vote is not over yet?
            uint256 supply = token.totalVotingTokens();
            return (supply - noVotes) * BPS_MUL < quorum * supply;
        } else {
            // did quorum% of all cast votes say 'no'?
            return BPS_MUL * yesVotes < quorum * (yesVotes + noVotes);
        }
    }

    function notifyMoved(address from, address to, uint256 value) external override {
        require(msg.sender == address(token), "invalid caller");
        if (isVotingOpen()) {
            Vote fromVoting = votes[from];
            Vote toVoting = votes[to];
            update(fromVoting, toVoting, value);
        }
    }

    function update(Vote previousVote, Vote newVote, uint256 votes_) internal {
        if (previousVote != newVote) {
            if (previousVote == Vote.NO) {
                noVotes -= votes_;
            } else if (previousVote == Vote.YES) {
                yesVotes -= votes_;
            }
            if (newVote == Vote.NO) {
                noVotes += votes_;
            } else if (newVote == Vote.YES) {
                yesVotes += votes_;
            }
            emit VotesChanged(yesVotes, noVotes);
        }
    }

    function isVotingOpen() public view returns (bool) {
        // rely on time stamp is ok, no exact time stamp needed
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp <= voteEnd;
    }

    modifier votingOpen() {
        require(isVotingOpen(), "vote ended");
        _;
    }

    /**
     * Function to allow the oracle to report the votes of external votes (e.g. shares tokenized on other blockchains).
     * This functions is idempotent and sets the number of external yes and no votes. So when more votes come in, the
     * oracle should always report the total number of yes and no votes. Abstentions are not counted.
     */
    function reportExternalVotes(uint256 yes, uint256 no) external {
        require(msg.sender == token.oracle(), "not oracle");
        require(yes + no + IERC20(address(token)).totalSupply() <= token.totalVotingTokens(), "too many votes");
        // adjust total votes taking into account that the oralce might have reported different counts before
        yesVotes = yesVotes - yesExternal + yes;
        noVotes = noVotes - noExternal + no;
        // remember how the oracle voted in case the oracle later reports updated numbers
        yesExternal = yes;
        noExternal = no;
    }

    function voteYes() external override{
        vote(Vote.YES);
    }

    function voteNo() external override{ 
        vote(Vote.NO);
    }

    function vote(Vote newVote) internal votingOpen() {
        Vote previousVote = votes[msg.sender];
        votes[msg.sender] = newVote;
        if(previousVote == Vote.NONE){
            token.notifyVoted(msg.sender);
        }
        update(previousVote, newVote, token.votingPower(msg.sender));
    }

    function hasVotedYes(address voter) external view returns (bool) {
        return votes[voter] == Vote.YES;
    }

    function hasVotedNo(address voter) external view returns (bool) {
        return votes[voter] == Vote.NO;
    }

    function kill(bool success, string memory message) internal {
        emit OfferEnded(buyer, success, message);
        token.notifyOfferEnded();
        selfdestruct(payable(buyer));
    }

}