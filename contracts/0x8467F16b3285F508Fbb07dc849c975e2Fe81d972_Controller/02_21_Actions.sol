// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

/**
 * @title Actions
 * @notice A library that provides a ActionArgs struct, sub types of Action structs, and functions to parse ActionArgs into specific Actions.
 * errorCode
 * A1 can only parse arguments for open vault actions
 * A2 cannot open vault for an invalid account
 * A3 cannot open vault with an invalid type
 * A4 can only parse arguments for mint actions
 * A5 cannot mint from an invalid account
 * A6 can only parse arguments for burn actions
 * A7 cannot burn from an invalid account
 * A8 can only parse arguments for deposit collateral action
 * A9 cannot deposit to an invalid account
 * A10 can only parse arguments for withdraw actions
 * A11 cannot withdraw from an invalid account
 * A12 cannot withdraw to an invalid account
 * A13 can only parse arguments for redeem actions
 * A14 cannot redeem to an invalid account
 * A15 can only parse arguments for settle vault actions
 * A16 cannot settle vault for an invalid account
 * A17 cannot withdraw payout to an invalid account
 * A18 can only parse arguments for liquidate action
 * A19 cannot liquidate vault for an invalid account owner
 * A20 cannot send collateral to an invalid account
 * A21 cannot parse liquidate action with no round id
 * A22 can only parse arguments for call actions
 * A23 target address cannot be address(0)
 * A24 amounts for minting onToken should be array with 1 element
 * A26 param "assets" should have 1 element for redeem action
 * A27 param "assets" first element should not be zero address for redeem action
 * A28 param "amounts" should have 1 element for redeem action
 * A29 param "amounts" first element should not be zero, cant redeem zero amount
 * A30 param "amounts" should be same length as param "assets"
 * A31 param "assets" should have 1 element for depositLong action
 * A32 param "amounts" should have 1 element for depositLong action
 * A33 param "amounts" should have 1 element for withdrawLong action
 * A34 param "amounts" should have 1 element for burnShort action
 * A35 param "assets" should have 1 element for burnShort action
 */
library Actions {
    // possible actions that can be performed
    enum ActionType {
        OpenVault,
        MintShortOption,
        BurnShortOption,
        DepositLongOption,
        WithdrawLongOption,
        DepositCollateral,
        WithdrawCollateral,
        SettleVault,
        Redeem,
        Call
    }

    struct ActionArgs {
        // type of action that is being performed on the system
        ActionType actionType;
        // address of the account owner
        address owner;
        // address which we move assets from or to (depending on the action type)
        address secondAddress;
        // asset that is to be transfered
        address[] assets;
        // index of the vault that is to be modified (if any)
        uint256 vaultId;
        // amount of asset that is to be transfered
        uint256[] amounts;
    }

    struct MintArgs {
        // address of the account owner
        address owner;
        // index of the vault from which the asset will be minted
        uint256 vaultId;
        // address to which we transfer the minted onTokens
        address to;
        // amount of onTokens that is to be minted
        uint256 amount;
    }

    struct BurnArgs {
        // address of the account owner
        address owner;
        // index of the vault from which the onToken will be burned
        uint256 vaultId;
        // amount of onTokens that is to be burned
        uint256 amount;
    }

    struct OpenVaultArgs {
        // address of the account owner
        address owner;
        // We restrict vault to be specific for existing onToken so it's collaterals assets will be the same as onToken's
        address shortONtoken;
        // vault id to create
        uint256 vaultId;
    }

    struct DepositCollateralArgs {
        // address of the account owner
        address owner;
        // index of the vault to which the asset will be added
        uint256 vaultId;
        // address from which we transfer the asset
        address from;
        // amount of asset that is to be deposited
        uint256[] amounts;
    }

    struct DepositLongArgs {
        // address of the account owner
        address owner;
        // index of the vault to which the asset will be added
        uint256 vaultId;
        // address from which we transfer the asset
        address from;
        // asset that is to be deposited
        address longONtoken;
        // amount of asset that is to be deposited
        uint256 amount;
    }

    struct RedeemArgs {
        // address to which we pay out the onToken proceeds
        address receiver;
        // onToken that is to be redeemed
        address onToken;
        // amount of onTokens that is to be redeemed
        uint256 amount;
    }

    struct WithdrawLongArgs {
        // address of the account owner
        address owner;
        // index of the vault from which the asset will be withdrawn
        uint256 vaultId;
        // address to which we transfer the asset
        address to;
        // amounts of long that is to be withdrawn
        uint256 amount;
    }

    struct WithdrawCollateralArgs {
        // address of the account owner
        address owner;
        // index of the vault from which the asset will be withdrawn
        uint256 vaultId;
        // address to which we transfer the asset
        address to;
        // amounts of collateral assets that is to be withdrawn
        uint256[] amounts;
    }

    struct SettleVaultArgs {
        // address of the account owner
        address owner;
        // index of the vault to which is to be settled
        uint256 vaultId;
        // address to which we transfer the remaining collateral
        address to;
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for an open vault action
     * @param _args general action arguments structure
     * @return arguments for a open vault action
     */
    function _parseOpenVaultArgs(ActionArgs memory _args) internal pure returns (OpenVaultArgs memory) {
        require(_args.actionType == ActionType.OpenVault, "A1");
        require(_args.owner != address(0), "A2");

        return OpenVaultArgs({ shortONtoken: _args.secondAddress, owner: _args.owner, vaultId: _args.vaultId });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a mint action
     * @param _args general action arguments structure
     * @return arguments for a mint action
     */
    function _parseMintArgs(ActionArgs memory _args) internal pure returns (MintArgs memory) {
        require(_args.actionType == ActionType.MintShortOption, "A4");
        require(_args.owner != address(0), "A5");
        require(_args.amounts.length == 1, "A24");

        return
            MintArgs({ owner: _args.owner, vaultId: _args.vaultId, to: _args.secondAddress, amount: _args.amounts[0] });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a burn action
     * @param _args general action arguments structure
     * @return arguments for a burn action
     */
    function _parseBurnArgs(ActionArgs memory _args) internal pure returns (BurnArgs memory) {
        require(_args.actionType == ActionType.BurnShortOption, "A6");
        require(_args.owner != address(0), "A7");
        require(_args.amounts.length == 1, "A34");

        return BurnArgs({ owner: _args.owner, vaultId: _args.vaultId, amount: _args.amounts[0] });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a deposit action
     * @param _args general action arguments structure
     * @return arguments for a deposit action
     */
    function _parseDepositCollateralArgs(ActionArgs memory _args) internal pure returns (DepositCollateralArgs memory) {
        require(_args.actionType == ActionType.DepositCollateral, "A8");
        require(_args.owner != address(0), "A9");

        return
            DepositCollateralArgs({
                owner: _args.owner,
                vaultId: _args.vaultId,
                from: _args.secondAddress,
                amounts: _args.amounts
            });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a deposit action
     * @param _args general action arguments structure
     * @return arguments for a deposit action
     */
    function _parseDepositLongArgs(ActionArgs memory _args) internal pure returns (DepositLongArgs memory) {
        require(_args.actionType == ActionType.DepositLongOption, "A35");
        require(_args.owner != address(0), "A9");
        require(_args.assets.length == 1, "A31");
        require(_args.amounts.length == 1, "A32");

        return
            DepositLongArgs({
                owner: _args.owner,
                vaultId: _args.vaultId,
                from: _args.secondAddress,
                longONtoken: _args.assets[0],
                amount: _args.amounts[0]
            });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a withdraw action
     * @param _args general action arguments structure
     * @return arguments for a withdraw action
     */
    function _parseWithdrawLongArgs(ActionArgs memory _args) internal pure returns (WithdrawLongArgs memory) {
        require((_args.actionType == ActionType.WithdrawLongOption), "A10");
        require(_args.owner != address(0), "A11");
        require(_args.secondAddress != address(0), "A12");
        require(_args.amounts.length == 1, "A33");

        return
            WithdrawLongArgs({
                owner: _args.owner,
                vaultId: _args.vaultId,
                to: _args.secondAddress,
                amount: _args.amounts[0]
            });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a withdraw action
     * @param _args general action arguments structure
     * @return arguments for a withdraw action
     */
    function _parseWithdrawCollateralArgs(ActionArgs memory _args)
        internal
        pure
        returns (WithdrawCollateralArgs memory)
    {
        require((_args.actionType == ActionType.WithdrawCollateral), "A10");
        require(_args.owner != address(0), "A11");
        require(_args.secondAddress != address(0), "A12");

        return
            WithdrawCollateralArgs({
                owner: _args.owner,
                vaultId: _args.vaultId,
                to: _args.secondAddress,
                amounts: _args.amounts
            });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for an redeem action
     * @param _args general action arguments structure
     * @return arguments for a redeem action
     */
    function _parseRedeemArgs(ActionArgs memory _args) internal pure returns (RedeemArgs memory) {
        require(_args.actionType == ActionType.Redeem, "A13");
        require(_args.secondAddress != address(0), "A14");
        require(_args.assets.length == 1, "A26");
        require(_args.assets[0] != address(0), "A27");
        require(_args.amounts.length == 1, "A28");
        require(_args.amounts[0] != 0, "A29");

        return RedeemArgs({ receiver: _args.secondAddress, onToken: _args.assets[0], amount: _args.amounts[0] });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a settle vault action
     * @param _args general action arguments structure
     * @return arguments for a settle vault action
     */
    function _parseSettleVaultArgs(ActionArgs memory _args) internal pure returns (SettleVaultArgs memory) {
        require(_args.actionType == ActionType.SettleVault, "A15");
        require(_args.owner != address(0), "A16");
        require(_args.secondAddress != address(0), "A17");

        return SettleVaultArgs({ owner: _args.owner, vaultId: _args.vaultId, to: _args.secondAddress });
    }
}