// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@faircrypto/xen-crypto/contracts/XENCrypto.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libs/Strings.sol";

/*
    Sorting in Ethereum
    https://medium.com/bandprotocol/solidity-102-3-maintaining-sorted-list-1edd0a228d83 [*]
    https://stackoverflow.com/questions/64661313/descending-quicksort-in-solidity
    https://gist.github.com/fiveoutofnine/5140b17f6185aacb71fc74d3a315a9da

*/
contract XENKnights is IBurnRedeemable, Ownable, ERC165 {

    enum Status {
        Waiting,
        InProgress,
        Final,      // leaderboard loaded
        Ended,      // XEN burned for leaders
        Canceled    // in case shit happens
    }

    using Strings for uint256;

    // PUBLIC CONSTANTS
    string public constant AUTHORS = "@MrJackLevin @ackebom @lbelyaev faircrypto.org";
    uint256 public constant SECS_IN_DAY = 3_600 * 24;

    // common business logic
    uint256 public constant MAX_WINNERS = 100;

    // PUBLIC MUTABLE STATE
    uint256 public totalPlayers;
    uint256 public totalToBurn;
    Status public status;
    // taproot address => total bid amount
    mapping(bytes32 => uint256) public amounts;
    // user address => taproot address => total bid amount
    mapping(address => mapping(bytes32 => uint256)) public userAmounts;
    bytes32[] public leaders;

    // PUBLIC IMMUTABLE STATE

    uint256 public immutable startTs;
    uint256 public immutable endTs;
    // pointer to XEN Stake contract
    IERC20 public immutable xenCrypto;

    // CONSTRUCTOR

    constructor(address xenCrypto_, uint256 startTs_, uint256 durationDays_) {
        require(xenCrypto_ != address(0));
        require(startTs_ >= block.timestamp);
        require(durationDays_ > 0);

        xenCrypto = IERC20(xenCrypto_);
        startTs = startTs_;
        endTs = startTs_ + durationDays_ * SECS_IN_DAY;

        emit StatusChanged(Status.Waiting, block.timestamp);
    }

    // EVENTS

    event StatusChanged(Status status, uint256 ts);
    event Admitted(address indexed user, string taprootAddress, uint256 amount, uint256 totalAmount);
    event Withdrawn(address indexed user, string taprootAddress, uint256 amount);
    event Burned(uint256 amount);

    // IERC-165

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IBurnRedeemable).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    // PRIVATE HELPERS

    function _canEnter(uint256 amount, string calldata taprootAddress) private view {
        require(msg.sender == tx.origin, 'XenKnights: only EOAs allowed');
        require(block.timestamp > startTs, 'XenKnights: competition not yet started');
        require(block.timestamp < endTs, 'XenKnights: competition already finished');
        require(status < Status.Final, 'XenKnights: competition not in progress');
        require(amount > 0, 'XenKnights: illegal amount');
        require(bytes(taprootAddress).length == 62, 'XenKnights: illegal taprootAddress length');
        require(
            _compareStr(string(bytes(taprootAddress)[0:4]), 'bc1p'),
            'XenKnights: illegal taprootAddress signature'
        );
    }

    function _canWithdraw(string calldata taprootAddress, bytes32 hash) private view {
        require(msg.sender == tx.origin, 'XenKnights: only EOAs allowed');
        require(block.timestamp > endTs, 'XenKnights: competition not yet finished');
        require(status > Status.InProgress, 'XenKnights: competition still in progress');
        require(bytes(taprootAddress).length == 62, 'XenKnights: illegal taprootAddress length');
        require(
            _compareStr(string(bytes(taprootAddress)[0:4]), 'bc1p'),
            'XenKnights: illegal taprootAddress signature'
        );
        require(userAmounts[msg.sender][hash] > 0, 'XenKnights: nothing to withdraw');
        require(amounts[hash] > 0, 'XenKnights: winner cannot withdraw');
    }

    function _canBurn() private view {
        require(block.timestamp > endTs, 'XenKnights: competition still in progress');
        require(status > Status.InProgress, 'XenKnights: competition not yet final');
        require(status < Status.Ended, 'XenKnights: already burned');
        require(xenCrypto.balanceOf(address(this)) > 0, 'XenKnights: nothing to burn');
    }

    function _compareStr(string memory one, string memory two) private pure returns (bool) {
        return sha256(abi.encodePacked(one)) == sha256(abi.encodePacked(two));
    }

    function _compare(bytes32 one, bytes32 two) private pure returns (bool) {
        //return sha256(abi.encodePacked(one)) == sha256(abi.encodePacked(two));
        return one == two;
    }

    // PUBLIC READ INTERFACE

    /**
     * @dev Returns `count` first tokenIds by lowest amount
     */
    function leaderboard(uint256)
        external
        view
        returns (bytes32[] memory data)
    {
        data = leaders;
    }

    // ADMIN INTERFACE

    function loadLeaders(bytes32[] calldata taprootAddresses) external onlyOwner {
        require(block.timestamp > endTs, 'Admin: cannot load leaders before end');
        require(status == Status.InProgress, 'Admin: bad status');
        require(
            taprootAddresses.length > 0 && taprootAddresses.length < MAX_WINNERS + 1,
            'Admin: illegal list length'
        );

        uint256 prevAmount = amounts[taprootAddresses[0]];
        for (uint256 i = 0; i < taprootAddresses.length; i++) {
            require(amounts[taprootAddresses[i]] > 0, 'Admin: winner\'s amount cannot be zero');
            require(
                i == 0 || amounts[taprootAddresses[i]] >= prevAmount,
                'Admin: list not sorted'
            );
            prevAmount = amounts[taprootAddresses[i]];
            leaders.push(taprootAddresses[i]);
            totalToBurn += prevAmount;
            amounts[taprootAddresses[i]] = 0; // to mark winners from losers
        }
        status = Status.Final;

        emit StatusChanged(Status.Final, block.timestamp);
    }

    // PRIVATE HELPERS

    /**
     * @dev Attempt to enter competition based on eligible XEN Stake identified by `tokenId`
     * @dev Additionally, `taprootAddress` is supplied and stored along with tokenId
     */
    function enterCompetition(uint256 newAmount, string calldata taprootAddress_) external {
        _canEnter(newAmount, taprootAddress_);
        require(xenCrypto.transferFrom(msg.sender, address(this), newAmount), 'XenKnights: could not transfer XEN');

        bytes32 taprootAddress = keccak256(bytes(taprootAddress_));
        uint256 existingAmount = amounts[taprootAddress];
        uint256 totalAmount = existingAmount + newAmount;

        amounts[taprootAddress] = totalAmount;
        userAmounts[msg.sender][taprootAddress] += newAmount;
        if (status == Status.Waiting) {
            status = Status.InProgress;
            emit StatusChanged(Status.InProgress, block.timestamp);
        }
        emit Admitted(msg.sender, taprootAddress_, newAmount, totalAmount);
    }

    function withdraw(string calldata taprootAddress_) external {
        bytes32 taprootAddress = keccak256(bytes(taprootAddress_));
        _canWithdraw(taprootAddress_, taprootAddress);

        uint256 amount = userAmounts[msg.sender][taprootAddress];
        require(
            xenCrypto.transfer(msg.sender, amount),
            'XenKnights: error withdrawing'
        );
        delete userAmounts[msg.sender][taprootAddress];
        emit Withdrawn(msg.sender, taprootAddress_, amount);
    }

    function onTokenBurned(address user, uint256 amount) external {
        require(msg.sender == address(xenCrypto), "IBurnableRedeemable: illegal callback caller");
        require(user == address(this), 'IBurnableRedeemable: illegal burner');
        require(amount == totalToBurn, 'IBurnableRedeemable: illegal amount');
        require(status == Status.Final, 'IBurnableRedeemable: illegal status');

        status = Status.Ended;
        emit StatusChanged(Status.Ended, block.timestamp);
        emit Burned(amount);
    }

    function burn() external {
        _canBurn();

        xenCrypto.approve(address(this), totalToBurn);
        IBurnableToken(address(xenCrypto)).burn(address(this), totalToBurn);
    }
}