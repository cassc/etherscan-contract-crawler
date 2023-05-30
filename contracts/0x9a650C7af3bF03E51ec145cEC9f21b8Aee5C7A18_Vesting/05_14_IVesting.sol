pragma solidity 0.8.14;

interface IVesting {
    /// The different vesting groups
    enum Group {
        Invalid, // 0
        Seed, // 1
        PrivateSale, // 2
        Public, // 3
        MarketMaker, // 4
        Ecosystem, // 5
        Team, // 6
        Marketing // 7
    }

    //
    // Events
    //

    event Claim(address indexed claimer, uint256 amount);

    //
    // Structs
    //

    /// Rules for each vesting group
    struct Rules {
        uint256 total; // how much can be allocated for this group
        uint256 remaining; // how much is not yet allocated
        uint256 cliff; // duration (in seconds) of cliff period since start
        uint256 vesting; // duration (in seconds) of vesting period since start
    }

    /// Info for a single group/user allocation
    struct Allocation {
        uint256 total;
        uint256 claimed;
    }

    /**
     * Allows beneficiaries to claim allocated amounts, according to their vesting
     * rules, throughout all vesting groups
     *
     * @notice UI is responsible for deciding which groups to include in the
     * call. Possibly by calling {isUserAllocatedInGroup}
     *
     * @param _groups Vesting groups to check
     * @return amountOut amount claimed during
     * this call
     */
    function claim(Group[] calldata _groups)
        external
        returns (uint256 amountOut);

    /**
     * Retrieves the currently claimable amount of $UCO for the given groups
     *
     * @param _groups Vesting groups to check
     * @param _holder The account to check
     * @return amountOut claimable amount
     */
    function claimable(Group[] calldata _groups, address _holder)
        external
        view
        returns (uint256 amountOut);

    /**
     * Retrieves the amount of $UCO already claimed by a holder for the given groups
     *
     * @param _holder The account to check
     * @return amount The amount of $UCO claimed so far
     */
    function claimed(Group[] calldata _groups, address _holder)
        external
        view
        returns (uint256 amount);

    /**
     * Retrieves the amount of $UCO still left to claim by a holder for all groups
     *
     * @param _holder The account to check
     * @return amount The amount of $UCO left to claim
     */
    function leftToClaim(Group[] calldata _groups, address _holder)
        external
        view
        returns (uint256 amount);
}