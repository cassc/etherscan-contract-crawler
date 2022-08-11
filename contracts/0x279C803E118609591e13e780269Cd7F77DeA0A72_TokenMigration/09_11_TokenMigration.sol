// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IMigrationNFT.sol";
import "./interfaces/IMYCToken.sol";

/**
 * @title A TCR token to MYC token migration contract.
 * @author raymogg
 * @notice Allows users to call the `migrate` function, exchanging TCR for MYC at a 1:1 ratio.
 * @dev All burned TCR will be held in the contract.
 */
contract TokenMigration is AccessControl {
    address public immutable myc;
    IERC20 public immutable tcr;
    IMigrationNFT public nft;
    mapping(address => bool) public mintedNFT;
    // total amount of TCR successfully burned
    uint256 public burnedTCR;

    /**
     * @notice Emits when some TCR tokens are migrated to MYC tokens.
     * @param from The sender of the TCR tokens.
     * @param to The recipient of the MYC tokens.
     * @param amount The amount of TCR or MYC tokens.
     * @dev `amount` will be the same for TCR and MYC tokens as migration is done at a 1:1 ratio.
     */
    event Migrated(address indexed from, address indexed to, uint256 amount);

    /**
     * @notice Sets up the `DEFAULT_ADMIN_ROLE` role and assigns values for the MYC and TCR tokens.
     * @param admin The address to whom the `DEFAULT_ADMIN_ROLE` role will be assigned.
     * @param _myc The MYC token address.
     * @param _tcr The TCR token address.
     */
    constructor(
        address admin,
        address _myc,
        address _tcr
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        myc = _myc;
        tcr = IERC20(_tcr);
    }

    /**
     * @notice Set the migration NFT contract address.
     * @param _nft Address to be used to mint the NFTs.
     * @custom:requirements The contract at address `_nft` must implement the IMigrationNFT interface.
     * @custom:requirements `msg.sender` is a member of the `DEFAULT_ADMIN_ROLE` role.
     */
    function setNFTContract(address _nft) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "NOT_ADMIN");
        nft = IMigrationNFT(_nft);
    }

    /**
     * @notice Safety function to allow an admin to withdraw any tokens accidently sent to this contract.
     * @param token The ERC20 token address to transfer out of this contract address.
     * @dev Does not check if tokens were sent by mistake or properly migrated.
     * @custom:requirements `msg.sender` is a member of the `DEFAULT_ADMIN_ROLE` role.
     */
    function withdrawTokens(address token) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "NOT_ADMIN");
        IERC20(token).transfer(
            msg.sender,
            IERC20(token).balanceOf(address(this))
        );
    }

    /**
     * @notice Migrate `amount` TCR tokens to `amount` MYC tokens, and transfer to a specified address.
     * @param amount The amount of TCR to be burnt, and thus MYC to be minted.
     * @param to The recipient address of the minted MYC tokens.
     */
    function migrateTo(uint256 amount, address to) external {
        require(to != address(0), "Migrating to 0 address");
        _migrate(amount, to, msg.sender);
    }

    /**
     * @notice Migrate `amount` TCR tokens to `amount` MYC tokens, and transfer to a the calling address.
     * @param amount The amount of TCR to be burnt, and thus MYC to be minted.
     */
    function migrate(uint256 amount) external {
        _migrate(amount, msg.sender, msg.sender);
    }

    /**
     * @notice Allows the exchange of TCR for MYC at a 1:1 ratio.
     * @param amount The amount of TCR that is being migrated to MYC.
     * @param to The recipient address of MYC tokens.
     * @param from The address burning their TCR.
     * @dev This contract holds migrated TCR and mints fresh MYC to the `to` address.
     * @dev Emits a `Migrated` event.
     * @custom:requirement `mintingPaused == false`.
     * @custom:requirement `amount > 0`.
     */
    function _migrate(
        uint256 amount,
        address to,
        address from
    ) private {
        require(amount > 0, "INVALID_AMOUNT");
        // todo: add counter for amount of tokens "burned" via migration
        bool success = tcr.transferFrom(from, address(this), amount);
        require(success, "XFER_ERROR");
        burnedTCR += amount;

        // will revert if minting is paused
        IMYCToken(myc).mint(to, amount);

        // issue NFT if this account has not yet migrated before
        if (!mintedNFT[to]) {
            mintedNFT[to] = true;
            nft.mint(to);
        }
        emit Migrated(from, to, amount);
    }
}