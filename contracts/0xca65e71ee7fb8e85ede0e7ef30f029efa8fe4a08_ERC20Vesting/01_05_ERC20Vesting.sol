// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./IERC20Vesting.sol";

contract ERC20Vesting is IERC20Vesting {
    using SafeERC20 for IERC20;

    address public immutable override wallet;
    IERC20 public immutable override token;
    mapping(address => VestingTerms) private vestingTerms;

    modifier onlyWallet() {
        require(msg.sender == wallet, "Only wallet is allowed to proceed");
        _;
    }

    /// @param _token Address of ERC20 token associated with this vesting contract
    /// @param _wallet Address of account that starts and stops vesting for different parties
    constructor(IERC20 _token, address _wallet) {
        require(address(_token) != address(0), "Token cannot be 0.");
        require(address(_wallet) != address(0), "Wallet cannot be 0.");

        token = _token;
        wallet = _wallet;
    }

    function getVestingTerms(address receiver) external view override returns (VestingTerms memory) {
        return vestingTerms[receiver];
    }

    function startVesting(address receiver, VestingTerms calldata terms) public override onlyWallet {
        require(receiver != address(0), "Receiver cannot be 0.");
        require(terms.amount > 0, "Amount must be > 0.");
        require(terms.startTime != 0, "Start time must be set.");
        require(terms.period > 0, "Period must be set.");
        require(terms.claimed == 0, "Can not start vesting with already claimed tokens.");
        assert(isScheduleValid(terms));
        require(!isScheduleValid(vestingTerms[receiver]), "Vesting already started for account.");

        vestingTerms[receiver] = terms;
        token.safeTransferFrom(wallet, address(this), terms.amount);

        emit VestingAdded(receiver, terms);
    }

    function startVestingBatch(address[] calldata receivers, VestingTerms[] calldata terms)
        external
        override
        onlyWallet
    {
        require(receivers.length > 0, "Zero receivers.");
        require(receivers.length == terms.length, "Terms and receivers must have same length.");

        for (uint256 i = 0; i < receivers.length; i++) {
            startVesting(receivers[i], terms[i]);
        }
    }

    function claim() external override {
        claim(type(uint256).max);
    }

    function claim(uint256 value) public override {
        require(value > 0, "Claiming 0 tokens.");
        VestingTerms memory terms = vestingTerms[msg.sender];
        require(isScheduleValid(terms), "No vesting data for sender.");

        uint256 claimableTokens = _claimable(terms);
        if (value == type(uint256).max) {
            value = claimableTokens;
        } else {
            require(value <= claimableTokens, "Claiming amount exceeds allowed tokens.");
        }

        vestingTerms[msg.sender].claimed += value;
        token.safeTransfer(msg.sender, value);

        emit VestingClaimed(msg.sender, value);
    }

    function transferVesting(address oldAddress, address newAddress) external override onlyWallet {
        require(newAddress != address(0), "Receiver cannot be 0.");
        require(!isScheduleValid(vestingTerms[newAddress]), "Vesting already started for receiver.");
        vestingTerms[newAddress] = vestingTerms[oldAddress];
        delete vestingTerms[oldAddress];

        emit VestingTransferred(oldAddress, newAddress);
    }

    function stopVesting(address receiver) external override onlyWallet {
        require(receiver != address(0), "Receiver cannot be 0.");

        VestingTerms storage terms = vestingTerms[receiver];
        require(isScheduleValid(terms), "No vesting data for receiver.");

        uint256 claimableTokens = _claimable(terms);
        uint256 revokedTokens = terms.amount - terms.claimed - claimableTokens;
        assert(terms.amount == (terms.claimed + claimableTokens + revokedTokens));

        // Update schedule to allow claiming the reminder.
        terms.period = 0;
        terms.amount = terms.claimed + claimableTokens;

        // Transfer the unclaimable (revoked) part.
        if (revokedTokens > 0) {
            token.safeTransfer(wallet, revokedTokens);
        }

        emit VestingRemoved(receiver);
    }

    function claimable(address receiver) external view override returns (uint256) {
        VestingTerms memory terms = vestingTerms[receiver];
        require(isScheduleValid(terms), "No vesting data for receiver.");
        return _claimable(terms);
    }

    function _claimable(VestingTerms memory terms) private view returns (uint256 claimableTokens) {
        if (terms.startTime < block.timestamp) {
            uint256 maxTokens = (block.timestamp >= terms.startTime + terms.period)
                ? (terms.amount)
                : (terms.amount * (block.timestamp - terms.startTime)) / terms.period;

            if (terms.claimed < maxTokens) {
                claimableTokens = maxTokens - terms.claimed;
            }
        }
    }

    function isScheduleValid(VestingTerms memory terms) private pure returns (bool) {
        return terms.startTime != 0;
    }
}