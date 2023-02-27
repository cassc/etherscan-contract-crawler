// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./Frankencoin.sol";
import "./IERC677Receiver.sol";
import "./ERC20PermitLight.sol";
import "./MathUtil.sol";
import "./IReserve.sol";

/** 
 * @title Reserve pool for the Frankencoin
 */
contract Equity is ERC20PermitLight, MathUtil, IReserve {

    uint32 public constant VALUATION_FACTOR = 3;
    uint32 private constant QUORUM = 300;

    uint8 private constant BLOCK_TIME_RESOLUTION_BITS = 24;
    uint256 public constant MIN_HOLDING_DURATION = 90*7200 << BLOCK_TIME_RESOLUTION_BITS; // in blocks, about 90 days, set to 5 blocks for testing

    Frankencoin immutable public zchf;

    // should hopefully be grouped into one storage slot
    uint64 private totalVotesAnchorTime; // 40 Bit for the block number, 24 Bit sub-block time resolution
    uint192 private totalVotesAtAnchor;

    mapping (address => address) public delegates;
    mapping (address => uint64) private voteAnchor; // 40 Bit for the block number, 24 Bit sub-block time resolution

    event Delegation(address indexed from, address indexed to);
    event Trade(address who, int amount, uint totPrice, uint newprice); // amount pos or neg for mint or redemption

    constructor(Frankencoin zchf_) ERC20(18) {
        zchf = zchf_;
    }

    function name() override external pure returns (string memory) {
        return "Frankencoin Pool Share";
    }

    function symbol() override external pure returns (string memory) {
        return "FPS";
    }

    function price() public view returns (uint256){
        return VALUATION_FACTOR * zchf.equity() * ONE_DEC18 / totalSupply();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) override internal {
        super._beforeTokenTransfer(from, to, amount);
        if (amount > 0){
            uint256 roundingLoss = adjustRecipientVoteAnchor(to, amount);
            adjustTotalVotes(from, amount, roundingLoss);
        }
    }

    function canRedeem() external view returns (bool){
        return canRedeem(msg.sender);
    }

    function canRedeem(address owner) public view returns (bool) {
        return anchorTime() - voteAnchor[owner] >= MIN_HOLDING_DURATION;
    }

     /**
     * @notice Decrease the total votes anchor when tokens lose their voting power due to being moved
     * @param from      sender
     * @param amount    amount to be sent
     */
    function adjustTotalVotes(address from, uint256 amount, uint256 roundingLoss) internal {
        uint256 lostVotes = from == address(0x0) ? 0 : (anchorTime() - voteAnchor[from]) * amount;
        totalVotesAtAnchor = uint192(totalVotes() - roundingLoss - lostVotes);
        totalVotesAnchorTime = anchorTime();
    }

    /**
     * @notice the vote anchor of the recipient is moved forward such that the number of calculated
     * votes does not change despite the higher balance.
     * @param to        receiver address
     * @param amount    amount to be received
     * @return the number of votes lost due to rounding errors
     */
    function adjustRecipientVoteAnchor(address to, uint256 amount) internal returns (uint256){
        if (to != address(0x0)) {
            uint256 recipientVotes = votes(to); // for example 21 if 7 shares were held for 3 blocks
            uint256 newbalance = balanceOf(to) + amount; // for example 11 if 4 shares are added
            voteAnchor[to] = uint64(anchorTime() - recipientVotes / newbalance); // new example anchor is only 21 / 11 = 1 block in the past
            return recipientVotes % newbalance; // we have lost 21 % 11 = 10 votes
        } else {
            // optimization for burn, vote anchor of null address does not matter
            return 0;
        }
    }

    function anchorTime() internal view returns (uint64){
        return uint64(block.number << BLOCK_TIME_RESOLUTION_BITS);
    }

    function votes(address holder) public view returns (uint256) {
        return balanceOf(holder) * (anchorTime() - voteAnchor[holder]);
    }

    function totalVotes() public view returns (uint256) {
        return totalVotesAtAnchor + totalSupply() * (anchorTime() - totalVotesAnchorTime);
    }

    function isQualified(address sender, address[] calldata helpers) external override view returns (bool) {
        uint256 _votes = votes(sender);
        for (uint i=0; i<helpers.length; i++){
            address current = helpers[i];
            require(current != sender);
            require(canVoteFor(sender, current));
            for (uint j=i+1; j<helpers.length; j++){
                require(current != helpers[j]); // ensure helper unique
            }
            _votes += votes(current);
        }
        return _votes * 10000 >= QUORUM * totalVotes();
    }

    function delegateVoteTo(address delegate) external {
        delegates[msg.sender] = delegate;
        emit Delegation(msg.sender, delegate);
    }

    function canVoteFor(address delegate, address owner) public view returns (bool) {
        if (owner == delegate){
            return true;
        } else if (owner == address(0x0)){
            return false;
        } else {
            return canVoteFor(delegate, delegates[owner]);
        }
    }

    function onTokenTransfer(address from, uint256 amount, bytes calldata) external returns (bool) {
        require(msg.sender == address(zchf), "caller must be zchf");
        if (totalSupply() == 0){
            require(amount >= ONE_DEC18, "initial deposit must >= 1");
            // initialize with 1000 shares for 1 ZCHF
            uint256 initialAmount = 1000 * ONE_DEC18;
            _mint(from, initialAmount);
            amount -= ONE_DEC18;
            emit Trade(msg.sender, int(initialAmount), ONE_DEC18, price());
        }
        uint256 shares = calculateSharesInternal(zchf.equity() - amount, amount);
        _mint(from, shares);
        require(totalSupply() < 2**90, "total supply exceeded"); // to guard against overflows with price and vote calculations
        emit Trade(msg.sender, int(shares), amount, price());
        return true;
    }

    /**
     * @notice Calculate shares received when depositing ZCHF
     * @dev this function is called after the transfer of ZCHF happens
     * @param investment ZCHF invested, in dec18 format
     * @return amount of shares received for the ZCHF invested
     */
    function calculateShares(uint256 investment) public view returns (uint256) {
        return calculateSharesInternal(zchf.equity(), investment);
    }

    function calculateSharesInternal(uint256 capitalBefore, uint256 investment) internal view returns (uint256) {
        uint256 totalShares = totalSupply();
        uint256 newTotalShares = _mulD18(totalShares, _cubicRoot(_divD18(capitalBefore + investment, capitalBefore)));
        return newTotalShares - totalShares;
    }

    function redeem(address target, uint256 shares) public returns (uint256) {
        require(canRedeem(msg.sender));
        uint256 proceeds = calculateProceeds(shares);
        _burn(msg.sender, shares);
        zchf.transfer(target, proceeds);
        emit Trade(msg.sender, -int(shares), proceeds, price());
        return proceeds;
    }

    /**
     * @notice Calculate ZCHF received when depositing shares
     * @dev this function is called before any transfer happens
     * @param shares number of shares we want to exchange for ZCHF,
     *               in dec18 format
     * @return amount of ZCHF received for the shares
     */
    function calculateProceeds(uint256 shares) public view returns (uint256) {
        uint256 totalShares = totalSupply();
        uint256 capital = zchf.equity();
        require(shares + ONE_DEC18 < totalShares, "too many shares"); // make sure there is always at least one share
        uint256 newTotalShares = totalShares - shares;
        uint256 newCapital = _mulD18(capital, _power3(_divD18(newTotalShares, totalShares)));
        return capital - newCapital;
    }

}