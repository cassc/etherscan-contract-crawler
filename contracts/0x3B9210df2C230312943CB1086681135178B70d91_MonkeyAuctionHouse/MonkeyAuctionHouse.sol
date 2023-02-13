/**
 *Submitted for verification at Etherscan.io on 2023-02-12
*/

// SPDX-License-Identifier: MIT
// File: contracts/IMonkeySvgGen.sol



///@title MonkeySvgGen Interface


pragma solidity ^0.8.18;

interface IMonkeySvgGen {

    function min(uint256 a, uint256 b) external returns (uint256);

    function max(uint256 a, uint256 b) external returns (uint256);

    function colorDif(ITnmtLibrary.ColorDec memory _colorOne, ITnmtLibrary.ColorDec memory _colorTwo) external returns (uint256);

    function editColorsAreValid(uint256 minColorDifValue, uint8 _manyEdits, ITnmtLibrary.ColorDec[3] memory _colors, ITnmtLibrary.ColorDec[11] memory _tnmtColors) external returns(bool);

    function ColorDecToColorString(ITnmtLibrary.ColorDec memory color) external returns (bytes memory);

    function svgCode(ITnmtLibrary.Attributes memory attrbts, ITnmtLibrary.ColorDec[11] memory tokenColors, uint8[1024] memory pixls, ITnmtLibrary.Edit memory _edit ) external pure returns (bytes memory);

}
// File: contracts/IMonkeySplitter.sol



/// @title Interface for Splitter Contract

pragma solidity ^0.8.18;

interface IMonkeySplitter {

    function splitEditorSale(address _editor, uint _auctionId) external returns (bool);

    function splitSimpleSale() external returns (bool);

    function approveEditorPay(uint _auctionId, address _editor) external returns (bool);

    function denyEditorPay(uint _auctionId, address _editor) external returns (bool);

}
// File: contracts/ITnmtToken.sol



/// @title Interface for tnmt Auction House


pragma solidity ^0.8.18;

interface ITnmtToken {

    function ownerOf(uint256 a) external returns (address);

    function mint(address _to,
        uint256 _auctionId,
        uint256 _monkeyId,
        uint8 _rotations,
        address _editor,
        uint8 _manyEdits,
        ITnmtLibrary.ColorDec[3] memory editColors) external returns (uint256);

    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function getCurrentTnmtId() external returns (uint256);
    
}
// File: contracts/ITnmtAuctionHouse.sol



/// @title Interface for tnmt Auction House


pragma solidity ^0.8.18;

interface ItnmtAuctionHouse {


    struct Auction {

        // tnmt Auction Id
        uint256 auctionId;

        // tnmt Bidder bid for
        uint256 monkeyId;

        // edit Id for the bidded tnmt
        uint256 editId;

        // rotations for the bidded tnmt
        uint8 rotations;

        // The current highest bid amount
        uint256 amount;

        // The time that the auction started
        uint256 startTime;

        // The time that the auction is scheduled to end
        uint256 endTime;
        
        // The address of the current highest bid
        address payable bidder;

        // Whether or not the auction has been settled
        bool settled;
    }

    event AuctionCreated(uint256 indexed auctionId, uint256 startTime, uint256 endTime);

    event AuctionBid(uint256  monkeyId, address sender, uint256 value, bool extended);

    event AuctionExtended(uint256 indexed auctionId, uint256 endTime);

    event AuctionTimeBufferUpdated(uint256 _timeBuffer);

    event AuctionMinColorDiffUpdated(uint256 _colorDif);

    event AuctionSettled(uint256 indexed auctionId,uint256 monkeyId, address winner, uint256 amount);

    event AuctionMinBidIncrementPercentageUpdated(uint256 minBidIncrementPercentage);

    event SplitterUpdated(address splitter);

    event SvgGenUpdated(address svgGen);

    event SplitterLocked(address splitter);

    event SvgGenLocked(address svgGen);

    function pause() external;

    function unpause() external;

    function setTimeBuffer(uint256 timeBuffer) external;

    function setColorDif(uint256 colorDif) external;
        
    function setMinBidIncrementPercentage(uint8 minBidIncrementPercentage) external;

    function settleCurrentAndCreateNewAuction() external;

    function settleAuction() external;

    function createBid(uint256 monkeyId, uint8 rotations, uint256 editId) external payable;


}
// File: contracts/TnmtLibrary.sol



/// @title TNMT Structs

pragma solidity ^0.8.18;

library ITnmtLibrary {

    struct Tnmt {
        uint256 auctionId;
        uint256 monkeyId;
        uint8 noColors;
        ColorDec[11] colors;
        string evento;
        uint8 rotations;
        bool hFlip;
        bool vFlip;
        bool updated;
    }

    struct Attributes {
        uint256 auctionId;
        uint256 monkeyId;
        uint8 noColors;
        uint8 rotations;
        bool hFlip;
        bool vFlip;
        string evento;
    }

    struct Edit {
        uint256 auctionId;
        uint256 monkeyId;
        uint8 manyEdits;
        uint8 rotations;
        ColorDec[3] colors;
        address editor;
    }

    struct Bid {
        address bidder;
        uint256 amount;
    }

    struct ColorDec {
        uint8 colorId;
        uint8 color_R;
        uint8 color_G;
        uint8 color_B;
        uint8 color_A;
    }

}


// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: contracts/monkeyAuctionHouse.sol



/// @title tnmt auction House

pragma solidity ^0.8.18;










contract MonkeyAuctionHouse is
    ItnmtAuctionHouse,
    Ownable,
    Pausable,
    ReentrancyGuard
{

    // Tnmt Auction Id tracker
    uint256 public currentTnmtAuctionId;

    // Bid tracker, resets each auction
    uint256 public bidTracker;

    // Bids memory
    mapping(uint256 => ITnmtLibrary.Bid) public bids;

    // Edit ID tracker, resets each auction
    uint256 public currentEdit = 0;

    // Tracking edit ID's to edit data, resets each auction
    mapping(uint256 => ITnmtLibrary.Edit) edits;

    // Bids refunds balances
    mapping(address => uint) refunds;
    
    // The tnmt ERC721 contract
    address public tnmt;

    // Address of SvgGen contract
    address public svgGen;

    // Address of splitter contract
    address payable public splitter;

    // Can the splitter be updated
    bool public isSplitterLocked;

    // Can the svgGen be updated
    bool public isSvgGenLocked;

    // Can the tnmt be updated
    bool public istnmtLocked;

    // Minimum accepted color value difference, euclidean distance min value.
    uint256 public minColorDifValue;

    // Minimum Time after last bid
    uint256 public timeBuffer;

    // The minimum percentage difference between the last bid amount and the current bid
    uint8 public minBidIncrementPercentage;

    // The duration of an auction
    uint256 public duration;

    ItnmtAuctionHouse.Auction public auction;

    constructor(address _svgGen, address _tnmtToken, address payable _splitter, uint256 _timeBuffer, uint8 _minBidIncrementPercentage, uint256 _duration, uint256 _lastauctionId, uint256 _minColorDifValue) {

        duration = _duration;
        minBidIncrementPercentage = _minBidIncrementPercentage;
        timeBuffer = _timeBuffer;
        tnmt = _tnmtToken;
        svgGen = _svgGen;
        splitter = _splitter;
        currentTnmtAuctionId = _lastauctionId;
        minColorDifValue = _minColorDifValue;
        _pause();

    }

    /**
     *   Current Edits Viewer function
     */
    function editsView(uint _editId) public view returns(ITnmtLibrary.Edit memory) {
        return edits[_editId];
    }

    /**
     * Sets the Splitter address.
     */
    function setSplitter(address payable _splitter) external onlyOwner {
        require(!isSplitterLocked,"Splitter is locked");
        splitter = _splitter;
        emit SplitterUpdated(_splitter);
    }

    /**
     * Locks the splitter address.
     */
    function lockSplitter() external onlyOwner {
        isSplitterLocked = true;
        emit SplitterLocked(splitter);
    }  


    /**
     * Sets the svgGen address.
     */
    function setSvgGen(address _svgGen) external onlyOwner {
        require(!isSvgGenLocked,"SvgGen is locked");
        svgGen = _svgGen;
        emit SvgGenUpdated(_svgGen);
    }

    /**
     * Locks the svgGen address.
     */
    function lockSvgGen() external onlyOwner {
        isSvgGenLocked = true;
        emit SvgGenLocked(svgGen);
    }

    /**
     * Set the tnmt address
     */
    function setTnmtAddress(address _tnmtToken) external onlyOwner {
        tnmt = _tnmtToken;
    }

    /**
     *   Pause the contract
     */
    function pause() external override onlyOwner {
        _pause();
    }

    /**
     *   Unpause the tnmt auction House, Initializes new auction if none is live
     */
    function unpause() external override onlyOwner {
        _unpause();
        if (auction.startTime == 0 || auction.settled) {
            _createAuction();
        }
    }

    /**
     * Set the auction time buffer.
     */
    function setTimeBuffer(uint256 _timeBuffer) external override onlyOwner {
        timeBuffer = _timeBuffer;

        emit AuctionTimeBufferUpdated(_timeBuffer);
    }

    /**
     * Set the min diff value between colors for edits.
     */
    function setColorDif(uint256 _colorDif) external override onlyOwner {
        minColorDifValue = _colorDif;

        emit AuctionMinColorDiffUpdated(_colorDif);
    }

    /**
     * Set the auction min bid increment percentage.
     */
    function setMinBidIncrementPercentage(uint8 _minBidIncrementPercentage) external override onlyOwner {
        minBidIncrementPercentage = _minBidIncrementPercentage;

        emit AuctionMinBidIncrementPercentageUpdated(
            _minBidIncrementPercentage
        );
    }

    /**
     * Settle de currrent auction and create new one
     */
    function settleCurrentAndCreateNewAuction() external override nonReentrant whenNotPaused {
        _settleAuction();
        _createAuction();
    }

    /**
     *   Settle de currrent auction, can only be called when the contract is paused
     */
    function settleAuction() external override nonReentrant whenPaused {
        _settleAuction();
    }


    /**
     * Settle an auction, finalizing the bid and paying out to the splitter contract.
     * If there are no bids no minting is done
     */
    function _settleAuction() internal {
        ItnmtAuctionHouse.Auction memory _auction = auction;

        require(_auction.startTime != 0, "Auction has not begun");
        require(!_auction.settled, "Auction has already been settled");
        require(
            block.timestamp >= _auction.endTime,
            "Auction hasn't completed"
        );

        auction.settled = true;

        if (_auction.bidder != address(0)) {
            uint256 token = 0;
            if(_auction.editId != 0) {
                token = ITnmtToken(tnmt).mint(_auction.bidder, currentTnmtAuctionId, _auction.monkeyId, _auction.rotations, edits[_auction.editId].editor, edits[_auction.editId].manyEdits,edits[_auction.editId].colors);
            } else {
                ITnmtLibrary.ColorDec[3] memory emptyColors;
                token = ITnmtToken(tnmt).mint(_auction.bidder, currentTnmtAuctionId, _auction.monkeyId, _auction.rotations, address(0),0,emptyColors);
            }
            require(token > 0, "Could not Mint");
        }

        if (_auction.amount > 0 ) {
            
            
            bool succes = _safeTransferETH(splitter, _auction.amount);
            require(succes,"Error forwarding ETH to splitter contract");
            if(_auction.editId != 0) {
                succes = IMonkeySplitter(splitter).splitEditorSale(edits[_auction.editId].editor, currentTnmtAuctionId);
            } else {
                succes = IMonkeySplitter(splitter).splitSimpleSale();
            }
            require(succes,"Error splitting ETH");
        }

        
        emit AuctionSettled(
            _auction.auctionId,
            _auction.monkeyId,
            _auction.bidder,
            _auction.amount
        );
    }

    /**
     * Create a new auction.
     */
    function _createAuction() internal {
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + duration;

        currentTnmtAuctionId++;
        edits[0].editor = payable(0);

        for (uint256 i = 1; i < currentEdit; i++) {
            delete edits[i];
        }

        currentEdit = 0;


        for (uint256 i = 1; i <= bidTracker ; i++) {
            delete bids[i];
        }

        bidTracker = 0;

        auction = Auction({
            auctionId: currentTnmtAuctionId,
            monkeyId: 2000,
            editId: 0,
            rotations: 0,
            amount: 0,
            startTime: startTime,
            endTime: endTime,
            bidder: payable(0),
            settled: false
        });

        emit AuctionCreated(
            auction.auctionId,
            auction.startTime,
            auction.endTime
        );

    }


    /**
     * Transfer ETH and return the success status.
     * This function only forwards 30,000 gas to the callee.
     */
    function _safeTransferETH(address to, uint value) internal returns (bool) {
        (bool success, ) = to.call{value: value, gas: 30_000}(new bytes(0));
        return success;
    }

    /**
     * Transfer ETH and return the success status.
     */
    function withdrawRefund() external nonReentrant {
        require(refunds[msg.sender] > 0, "No ETH to be refunded");
        uint amount = refunds[msg.sender];
        refunds[msg.sender] = 0;
        bool success = _safeTransferETH(msg.sender, amount);
        require(success);
    }

    /**
     * Checks callers refunds balance
     */
    function myBalance() public view returns (uint256) {
        return refunds[msg.sender];
    }

    /**
     *   Creates a bid for a tnmt or edit
     */
    function createBid(uint256 _monkeyId, uint8 _rotations, uint256 _editId) external payable override nonReentrant whenNotPaused {
        ItnmtAuctionHouse.Auction memory _auction = auction;

        require(_monkeyId <= 1999, "monkeyId must be less than or equal to 1999");
        require(block.timestamp < _auction.endTime, "Auction has already ended");
        require(auction.startTime != 0, "No auction taking place");
        require(!auction.settled, "Auction has already been settled");
        require(msg.value >= _auction.amount + ((_auction.amount * minBidIncrementPercentage) / 100),
            "Must send more than last bid by minBidIncrementPercentage amount"
        );
        require(_editId <= currentEdit,
            "Bidded for non Existant EditId"
        );

        if(_editId > 0){
            require(_monkeyId == edits[_editId].monkeyId, "Bid MonkeyId and Edit MonkeyId do not match");
        }
        
        require(_rotations < 4, "Rotations must be between 1 and 3");

        address payable lastBidder = _auction.bidder;

        if (lastBidder != address(0)) {
            uint256 refundAmount = _auction.amount;
            auction.amount = 0;
            refunds[lastBidder] += refundAmount;
        }

        auction.monkeyId = _monkeyId;
        auction.amount = msg.value;
        auction.bidder = payable(msg.sender);
        auction.rotations = _rotations;
        auction.editId = _editId;

        bidTracker += 1;
        bids[bidTracker].bidder = msg.sender;
        bids[bidTracker].amount = msg.value;

        bool extended = _auction.endTime - block.timestamp < timeBuffer;
        if (extended) {
            auction.endTime = _auction.endTime = block.timestamp + timeBuffer;
        }

        emit AuctionBid(_auction.monkeyId, msg.sender, msg.value, extended);

        if (extended) {
            emit AuctionExtended(_auction.auctionId, _auction.endTime);
        }
    }

    /**
     *   Checkes wether the color scheme is valid in the current auction or not for a given MonkeyID
     **/
    function editColorsAreValid(uint256 _monkeyId, uint8 _manyEdits, ITnmtLibrary.ColorDec[3] memory _colors) internal returns(bool) {

        bool valid = false;

        for (uint j = 0; j < currentEdit + 1; j++) {
            if (
                edits[j].monkeyId == _monkeyId &&
                edits[j].manyEdits == _manyEdits
            ) {
                valid = false;
                for (uint c = 0; c < _manyEdits; c++) {
                    require(edits[j].colors[c].colorId < 10, "ColorId must be < 10");
                    if (
                        edits[j].colors[c].colorId !=
                        _colors[c].colorId
                    ) {
                        valid = true;
                    } else if (
                        IMonkeySvgGen(svgGen).colorDif(edits[j].colors[c], _colors[c]) >= minColorDifValue
                    ) {
                        valid = true;
                    }
                }

                if(!valid) {
                    return false;
                }
            }
        }

        return true;
    }

    /**
     *   Creates a new biddable edit.
     **/
    function proposeEdit(uint256 _monkeyId, uint8 _manyEdits, uint8 _rotations, ITnmtLibrary.ColorDec[3] memory _colors) public whenNotPaused returns(uint256) {
        
        require(_monkeyId < 2000, "MonkeyId must be between 0 and 1999");
        require(_manyEdits < 4, "Edit lenght must be between 1 and 3");
        require(_rotations < 4, "Rotations must be between 1 and 3");
        require(_colors[0].colorId < _colors[1].colorId && _colors[1].colorId < _colors[2].colorId, "Color Indexes must be in ascending order");
        require(block.timestamp < auction.endTime, "Auction ended");
        require(auction.startTime != 0, "Auction has not begun");
        require(!auction.settled, "Auction has already been settled");

        
        for (uint i = 0; i < _manyEdits; i++) {
            require(
                _colors[i].colorId >= 0 && _colors[i].colorId < 10 ,
                "Color Indexes must be between 0 and 9"
            );

            if (_colors[i].color_A > 100) {
                _colors[i].color_A = 100;
            }
        }

        require(editColorsAreValid(_monkeyId, _manyEdits, _colors), "Proposed color scheme is too similar to another existing Edit");

        currentEdit++;

        edits[currentEdit].auctionId = currentTnmtAuctionId;
        edits[currentEdit].monkeyId = _monkeyId;
        edits[currentEdit].rotations = _rotations;
        edits[currentEdit].manyEdits = _manyEdits;
        edits[currentEdit].editor = msg.sender;

        for (uint256 c = 0; c < _manyEdits; c++) {
            edits[currentEdit].colors[c].colorId = _colors[c].colorId;
            edits[currentEdit].colors[c].color_R = _colors[c].color_R;
            edits[currentEdit].colors[c].color_G = _colors[c].color_G;
            edits[currentEdit].colors[c].color_B = _colors[c].color_B;
            edits[currentEdit].colors[c].color_A = _colors[c].color_A;
        }
        
        return currentEdit;
    }
}