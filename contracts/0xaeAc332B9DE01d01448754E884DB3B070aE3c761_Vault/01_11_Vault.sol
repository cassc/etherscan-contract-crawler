import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

import "./interfaces/IVault.sol";

/// @title Vault
/// @dev This contract will be used to hold fee revenue, it also provides some helper function to top-up registered HOT_WALLETS
contract Vault is AccessControlEnumerable, IVault {
    // The role used for HOT_WALLETs
    bytes32 public constant HOT_WALLET = keccak256("HOT_WALLET");
    bytes32 public constant HOT_WALLET_ADMIN = keccak256("HOT_WALLET_ADMIN");

    uint256 public walletBalanceLimit;

    constructor(address _admin) {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);

        _setupRole(HOT_WALLET_ADMIN, _admin);
        _setRoleAdmin(HOT_WALLET, HOT_WALLET_ADMIN);
    }

    receive() external payable override {
        emit Received(msg.sender, msg.value);
    }

    function claimFees() external override onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 thisBalance = address(this).balance;
        payable(msg.sender).transfer(thisBalance);

        emit FeesClaimed(msg.sender, thisBalance);
    }

    function paidFees(address _sender, uint256 _amount)
        external
        payable
        override
    {
        require(msg.value >= _amount, "Not enough ETH sent");

        emit PaidFees(_sender, _amount);
    }

    function setWalletBalanceLimit(uint256 _walletBalanceLimit)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        walletBalanceLimit = _walletBalanceLimit;
    }

    function ethRequiredForHotWalletTopup()
        external
        view
        override
        returns (uint256 totalETH)
    {
        uint256 numHotWallets = getRoleMemberCount(HOT_WALLET);

        // Iterate over the hot wallets
        for (uint256 i = 0; i < numHotWallets; i++) {
            address payable hotWalletMember = payable(
                getRoleMember(HOT_WALLET, i)
            );

            uint256 hotWalletBalance = hotWalletMember.balance;

            // If the given wallet needs a top-up
            if (hotWalletBalance < walletBalanceLimit) {
                uint256 balanceDiff = walletBalanceLimit - hotWalletBalance;

                totalETH += balanceDiff;
            }
        }
    }

    function topUpHotWallets()
        external
        payable
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 numHotWallets = getRoleMemberCount(HOT_WALLET);

        require(numHotWallets > 0, "No Hot Wallets to fund");

        // Iterate over the hot wallets
        for (uint256 i = 0; i < numHotWallets; i++) {
            address payable hotWalletMember = payable(
                getRoleMember(HOT_WALLET, i)
            );

            uint256 hotWalletBalance = hotWalletMember.balance;

            // If the given wallet needs a top-up
            if (hotWalletBalance < walletBalanceLimit) {
                uint256 balanceDiff = walletBalanceLimit - hotWalletBalance;

                // Revert if not enough ETH, this will allow us to more easily gauge the required amount of ETH to top-up hot wallets
                require(
                    address(this).balance >= balanceDiff,
                    "Not enough ETH to top-up wallets"
                );

                hotWalletMember.transfer(balanceDiff);
            }
        }
    }
}