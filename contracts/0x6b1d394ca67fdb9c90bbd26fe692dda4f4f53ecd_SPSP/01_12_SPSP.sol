pragma solidity 0.8.6;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/security/Pausable.sol";

contract SPSP is ERC20Permit, Ownable, Pausable {

    enum WITHDRAW_STATUS { UNUSED, LOCKED, RELEASED, REENTERED }

    IERC20 public immutable psp;

    uint256 public timeLockBlocks;

    uint256 public immutable maxTimeLockBlocks;

    uint256 public pspsLocked;

    struct WithdrawalRequest {
        uint256 amountPSP;
        uint256 releaseBlockNumber;
        WITHDRAW_STATUS status;
    }

    mapping(address => mapping(int256 => WithdrawalRequest)) public userVsWithdrawals;

    mapping(address => int256) public userVsNextID;

    event TimeLockChanged(uint256 oldTimeLock, uint256 newTimeLock);

    event Unstaked(int256 indexed id, address indexed user, uint256 amount);

    event Withdraw(int256 indexed id, address indexed user, uint256 amount);

    event Entered(address indexed user, uint256 amount);

    event Reentered(int256 indexed id, address indexed user, uint256 amount);

    constructor(
        string memory name,
        string memory symbol,
        IERC20 _psp,
        uint256 _timeLockBlocks,
        uint256 _maxTimeLockBlocks
    )
        ERC20Permit(name)
        ERC20(name, symbol)
        public
    {
        require(_timeLockBlocks <= _maxTimeLockBlocks, "Invalid timelock");
        psp = _psp;
        timeLockBlocks = _timeLockBlocks;
        maxTimeLockBlocks = _maxTimeLockBlocks;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function changeTimeLock(uint256 newTimeLockBlocks) external onlyOwner {
        require(newTimeLockBlocks <= maxTimeLockBlocks, "Invalid timelock");

        emit TimeLockChanged(timeLockBlocks, newTimeLockBlocks);

        timeLockBlocks = newTimeLockBlocks;
    }

    function enterWithPermit(uint256 _pspAmount, bytes calldata permit) external {
        _permit(permit);
        enter(_pspAmount);
    }

    // Unstake PSP. PSP tokens will be locked for the timeLockBlocks amount of time.
    function leave(uint256 _sPSPAmount) external {
        int256 id = userVsNextID[msg.sender]++;

        uint256 totalSPSP = totalSupply();
        uint256 pspBalanceAvailable = psp.balanceOf(address(this)) - pspsLocked;
        uint256 pspAmount = (_sPSPAmount * pspBalanceAvailable) / totalSPSP;
        _burn(msg.sender, _sPSPAmount);

        WithdrawalRequest storage request = userVsWithdrawals[msg.sender][id];

        request.amountPSP = pspAmount;
        request.releaseBlockNumber = block.number + timeLockBlocks;
        request.status = WITHDRAW_STATUS.LOCKED;

        pspsLocked += pspAmount;

        emit Unstaked(id, msg.sender, pspAmount);
    }

    // returns the total amount of PSP an address has in the contract including rewards earned
    function PSPBalance(address _account) external view returns (uint256 pspAmount_) {
        uint256 sPSPAmount = balanceOf(_account);
        if (sPSPAmount == 0) {
            return 0;
        }
        uint256 totalSPSP = totalSupply();
        uint256 pspBalanceAvailable = psp.balanceOf(address(this)) - pspsLocked;
        pspAmount_ = sPSPAmount * pspBalanceAvailable / totalSPSP;
    }

    //returns how much PSP someone gets for burning sPSP
    function PSPForSPSP(uint256 _sPSPAmount) external view returns (uint256 pspAmount_) {
        uint256 totalSPSP = totalSupply();
        if (totalSPSP == 0) {
            return 0;
        }
        uint256 pspBalanceAvailable = psp.balanceOf(address(this))- pspsLocked;
        pspAmount_ = (_sPSPAmount * pspBalanceAvailable) / totalSPSP;
    }

    //returns how much sPSP someone gets for depositing PSP
    function sPSPForPSP(uint256 _pspAmount) external view returns (uint256 sPSPAmount_) {
        uint256 totalPSPAvailable = psp.balanceOf(address(this)) - pspsLocked;
        uint256 totalSPSP = totalSupply();
        if (totalSPSP == 0 || totalPSPAvailable == 0) {
            sPSPAmount_ = _pspAmount;
        }
        else {
            sPSPAmount_ = (_pspAmount * totalSPSP) / totalPSPAvailable;
        }
    }

    function withdrawMultiple(int256[] calldata ids) external {
        for (uint256 i = 0; i < ids.length; i++) {
            withdraw(ids[i]);
        }
    }

    function reenterMultiple(int256[] calldata ids) external {
        for (uint256 i = 0; i < ids.length; i++) {
            reenter(ids[i]);
        }
    }

    // Stake PSP. Earn some Staked PSP.
    function enter(uint256 _pspAmount) public whenNotPaused {
        uint256 pspBalanceAvailable = psp.balanceOf(address(this)) - pspsLocked;
        uint256 totalSPSP = totalSupply();
        if (totalSPSP == 0 || pspBalanceAvailable == 0) {
            _mint(msg.sender, _pspAmount);
        } else {
            uint256 sPSPAmount = (_pspAmount * totalSPSP) / pspBalanceAvailable;
            _mint(msg.sender, sPSPAmount);
        }
        psp.transferFrom(msg.sender, address(this), _pspAmount);

        emit Entered(msg.sender, _pspAmount);
    }

    //Withdraw unstaked PSP tokens in previous step which are unlocked as well after time lock has expired
    function withdraw(int256 id) public {
        require(id >= 0, "Invalid id");

        WithdrawalRequest storage request = userVsWithdrawals[msg.sender][id];
        require(
            request.status == WITHDRAW_STATUS.LOCKED &&
            request.releaseBlockNumber <= block.number,
            "Cannot withdraw"
        );

        request.status = WITHDRAW_STATUS.RELEASED;

        uint256 _pspAmount = request.amountPSP;

        pspsLocked -= _pspAmount;
        psp.transfer(msg.sender, _pspAmount);

        emit Withdraw(id, msg.sender, _pspAmount);
    }

    function reenter(int256 id) public whenNotPaused {
        require(id >= 0, "Invalid id");

        WithdrawalRequest storage request = userVsWithdrawals[msg.sender][id];
        require(
            request.status == WITHDRAW_STATUS.LOCKED,
            "Cannot reenter"
        );

        request.status = WITHDRAW_STATUS.REENTERED;

        uint256 _pspAmount = request.amountPSP;

        uint256 pspBalanceAvailable = psp.balanceOf(address(this)) - pspsLocked;
        uint256 totalSPSP = totalSupply();

        if (totalSPSP == 0 || pspBalanceAvailable == 0) {
            _mint(msg.sender, _pspAmount);
        } else {
            uint256 sPSPAmount = (_pspAmount * totalSPSP) / pspBalanceAvailable;
            _mint(msg.sender, sPSPAmount);
        }

        pspsLocked -= _pspAmount;

        emit Reentered(id, msg.sender, _pspAmount);
    }

    // This is for use off chain, it finds any locked IDs in the specified range
    // If start is negative, starts looking that many entries back from the end
    function findLockedIDs(address user, int256 start, uint16 countToCheck)
        external view returns (int256[] memory ids)
    {
        int256 nextID = userVsNextID[user];

        if (start >= nextID) return ids;
        if (start < 0) start += nextID;
        int256 end = start + int256(uint256(countToCheck));
        if (end <= 0) return ids;
        if (end > nextID) end = nextID;
        if (start < 0) start = 0;

        mapping(int256 => WithdrawalRequest) storage withdrawals = userVsWithdrawals[user];

        // Don't want to allocate anything in memory after this point
        // (or the touched memory will grow very large!)
        ids = new int256[](type(uint16).max);
        uint256 length = 0;

        // Nothing in here can overflow so disable the checks for the loop
        unchecked {
            for (int256 id = start; id < end; ++id) {
                if (withdrawals[id].status == WITHDRAW_STATUS.LOCKED) {
                    ids[length++] = id;
                }
            }
        }

        // Need to force the array length to the correct value using assembly
        assembly { mstore(ids, length) }
    }

    function _permit(
        bytes memory permit
    )
        private
    {
        (bool success,) = address(psp).call(abi.encodePacked(IERC20Permit.permit.selector, permit));
        require(success, "Permit failed");

    }

}