// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { ERC20 }       from "../modules/erc20/contracts/ERC20.sol";
import { ERC20Helper } from "../modules/erc20-helper/src/ERC20Helper.sol";

import { IPoolManagerLike } from "./interfaces/Interfaces.sol";
import { IERC20, IPool }    from "./interfaces/IPool.sol";

/*

    ██████╗  ██████╗  ██████╗ ██╗
    ██╔══██╗██╔═══██╗██╔═══██╗██║
    ██████╔╝██║   ██║██║   ██║██║
    ██╔═══╝ ██║   ██║██║   ██║██║
    ██║     ╚██████╔╝╚██████╔╝███████╗
    ╚═╝      ╚═════╝  ╚═════╝ ╚══════╝

*/

contract Pool is IPool, ERC20 {

    uint256 public immutable override BOOTSTRAP_MINT;

    address public override asset;    // Underlying ERC-20 asset handled by the ERC-4626 contract.
    address public override manager;  // Address of the contract that manages administrative functionality.

    uint256 private _locked = 1;  // Used when checking for reentrancy.

    constructor(
        address manager_,
        address asset_,
        address destination_,
        uint256 bootstrapMint_,
        uint256 initialSupply_,
        string memory name_,
        string memory symbol_
    )
        ERC20(name_, symbol_, ERC20(asset_).decimals())
    {
        require((manager = manager_) != address(0), "P:C:ZERO_MANAGER");
        require((asset   = asset_)   != address(0), "P:C:ZERO_ASSET");

        if (initialSupply_ != 0) {
            _mint(destination_, initialSupply_);
        }

        BOOTSTRAP_MINT = bootstrapMint_;

        require(ERC20Helper.approve(asset_, manager_, type(uint256).max), "P:C:FAILED_APPROVE");
    }

    /******************************************************************************************************************************/
    /*** Modifiers                                                                                                              ***/
    /******************************************************************************************************************************/

    modifier checkCall(bytes32 functionId_) {
        ( bool success_, string memory errorMessage_ ) = IPoolManagerLike(manager).canCall(functionId_, msg.sender, msg.data[4:]);

        require(success_, errorMessage_);

        _;
    }

    modifier nonReentrant() {
        require(_locked == 1, "P:LOCKED");

        _locked = 2;

        _;

        _locked = 1;
    }

    /******************************************************************************************************************************/
    /*** LP Functions                                                                                                           ***/
    /******************************************************************************************************************************/

    function deposit(uint256 assets_, address receiver_) external override nonReentrant checkCall("P:deposit") returns (uint256 shares_) {
        _mint(shares_ = previewDeposit(assets_), assets_, receiver_, msg.sender);
    }

    function depositWithPermit(
        uint256 assets_,
        address receiver_,
        uint256 deadline_,
        uint8   v_,
        bytes32 r_,
        bytes32 s_
    )
        external override nonReentrant checkCall("P:depositWithPermit") returns (uint256 shares_)
    {
        ERC20(asset).permit(msg.sender, address(this), assets_, deadline_, v_, r_, s_);
        _mint(shares_ = previewDeposit(assets_), assets_, receiver_, msg.sender);
    }

    function mint(uint256 shares_, address receiver_) external override nonReentrant checkCall("P:mint") returns (uint256 assets_) {
        _mint(shares_, assets_ = previewMint(shares_), receiver_, msg.sender);
    }

    function mintWithPermit(
        uint256 shares_,
        address receiver_,
        uint256 maxAssets_,
        uint256 deadline_,
        uint8   v_,
        bytes32 r_,
        bytes32 s_
    )
        external override nonReentrant checkCall("P:mintWithPermit") returns (uint256 assets_)
    {
        require((assets_ = previewMint(shares_)) <= maxAssets_, "P:MWP:INSUFFICIENT_PERMIT");

        ERC20(asset).permit(msg.sender, address(this), maxAssets_, deadline_, v_, r_, s_);
        _mint(shares_, assets_, receiver_, msg.sender);
    }

    function redeem(uint256 shares_, address receiver_, address owner_) external override nonReentrant checkCall("P:redeem") returns (uint256 assets_) {
        uint256 redeemableShares_;
        ( redeemableShares_, assets_ ) = IPoolManagerLike(manager).processRedeem(shares_, owner_, msg.sender);
        _burn(redeemableShares_, assets_, receiver_, owner_, msg.sender);
    }

    function withdraw(uint256 assets_, address receiver_, address owner_) external override nonReentrant checkCall("P:withdraw") returns (uint256 shares_) {
        ( shares_, assets_ ) = IPoolManagerLike(manager).processWithdraw(assets_, owner_, msg.sender);
        _burn(shares_, assets_, receiver_, owner_, msg.sender);
    }

    /******************************************************************************************************************************/
    /*** ERC-20 Overridden Functions                                                                                            ***/
    /******************************************************************************************************************************/

    function transfer(
        address recipient_,
        uint256 amount_
    )
        public override(IERC20, ERC20) checkCall("P:transfer") returns (bool success_)
    {
        success_ = super.transfer(recipient_, amount_);
    }

    function transferFrom(
        address owner_,
        address recipient_,
        uint256 amount_
    )
        public override(IERC20, ERC20) checkCall("P:transferFrom") returns (bool success_)
    {
        success_ = super.transferFrom(owner_, recipient_, amount_);
    }

    /******************************************************************************************************************************/
    /*** Withdrawal Request Functions                                                                                           ***/
    /******************************************************************************************************************************/

    function removeShares(uint256 shares_, address owner_) external override nonReentrant checkCall("P:removeShares") returns (uint256 sharesReturned_) {
        if (msg.sender != owner_) _decreaseAllowance(owner_, msg.sender, shares_);

        emit SharesRemoved(
            owner_,
            sharesReturned_ = IPoolManagerLike(manager).removeShares(shares_, owner_)
        );
    }

    function requestRedeem(uint256 shares_, address owner_) external override nonReentrant checkCall("P:requestRedeem") returns (uint256 escrowedShares_) {
        emit RedemptionRequested(
            owner_,
            shares_,
            escrowedShares_ = _requestRedeem(shares_, owner_)
        );
    }

    function requestWithdraw(uint256 assets_, address owner_) external override nonReentrant checkCall("P:requestWithdraw") returns (uint256 escrowedShares_) {
        emit WithdrawRequested(
            owner_,
            assets_,
            escrowedShares_ = _requestWithdraw(assets_, owner_)
        );
    }

    /******************************************************************************************************************************/
    /*** Internal Functions                                                                                                     ***/
    /******************************************************************************************************************************/

    function _burn(uint256 shares_, uint256 assets_, address receiver_, address owner_, address caller_) internal {
        require(receiver_ != address(0), "P:B:ZERO_RECEIVER");

        if (shares_ == 0) return;

        if (caller_ != owner_) {
            _decreaseAllowance(owner_, caller_, shares_);
        }

        _burn(owner_, shares_);

        emit Withdraw(caller_, receiver_, owner_, assets_, shares_);

        require(ERC20Helper.transfer(asset, receiver_, assets_), "P:B:TRANSFER");
    }

    function _divRoundUp(uint256 numerator_, uint256 divisor_) internal pure returns (uint256 result_) {
        result_ = (numerator_ + divisor_ - 1) / divisor_;
    }

    function _mint(uint256 shares_, uint256 assets_, address receiver_, address caller_) internal {
        require(receiver_ != address(0), "P:M:ZERO_RECEIVER");
        require(shares_   != uint256(0), "P:M:ZERO_SHARES");
        require(assets_   != uint256(0), "P:M:ZERO_ASSETS");

        if (totalSupply == 0 && BOOTSTRAP_MINT != 0) {
            _mint(address(0), BOOTSTRAP_MINT);

            emit BootstrapMintPerformed(caller_, receiver_, assets_, shares_, BOOTSTRAP_MINT);

            shares_ -= BOOTSTRAP_MINT;
        }

        _mint(receiver_, shares_);

        emit Deposit(caller_, receiver_, assets_, shares_);

        require(ERC20Helper.transferFrom(asset, caller_, address(this), assets_), "P:M:TRANSFER_FROM");
    }

    function _requestRedeem(uint256 shares_, address owner_) internal returns (uint256 escrowShares_) {
        address destination_;

        ( escrowShares_, destination_ ) = IPoolManagerLike(manager).getEscrowParams(owner_, shares_);

        if (msg.sender != owner_) {
            _decreaseAllowance(owner_, msg.sender, escrowShares_);
        }

        if (escrowShares_ != 0 && destination_ != address(0)) {
            _transfer(owner_, destination_, escrowShares_);
        }

        IPoolManagerLike(manager).requestRedeem(escrowShares_, owner_, msg.sender);
    }

    function _requestWithdraw(uint256 assets_, address owner_) internal returns (uint256 escrowShares_) {
        address destination_;

        ( escrowShares_, destination_ ) = IPoolManagerLike(manager).getEscrowParams(owner_, convertToExitShares(assets_));

        if (msg.sender != owner_) {
            _decreaseAllowance(owner_, msg.sender, escrowShares_);
        }

        if (escrowShares_ != 0 && destination_ != address(0)) {
            _transfer(owner_, destination_, escrowShares_);
        }

        IPoolManagerLike(manager).requestWithdraw(escrowShares_, assets_, owner_, msg.sender);
    }

    /******************************************************************************************************************************/
    /*** External View Functions                                                                                                ***/
    /******************************************************************************************************************************/

    function balanceOfAssets(address account_) external view override returns (uint256 balanceOfAssets_) {
        balanceOfAssets_ = convertToAssets(balanceOf[account_]);
    }

    function maxDeposit(address receiver_) external view override returns (uint256 maxAssets_) {
        maxAssets_ = IPoolManagerLike(manager).maxDeposit(receiver_);
    }

    function maxMint(address receiver_) external view override returns (uint256 maxShares_) {
        maxShares_ = IPoolManagerLike(manager).maxMint(receiver_);
    }

    function maxRedeem(address owner_) external view override returns (uint256 maxShares_) {
        maxShares_ = IPoolManagerLike(manager).maxRedeem(owner_);
    }

    function maxWithdraw(address owner_) external view override returns (uint256 maxAssets_) {
        maxAssets_ = IPoolManagerLike(manager).maxWithdraw(owner_);
    }

    function previewRedeem(uint256 shares_) external view override returns (uint256 assets_) {
        assets_ = IPoolManagerLike(manager).previewRedeem(msg.sender, shares_);
    }

    function previewWithdraw(uint256 assets_) external view override returns (uint256 shares_) {
        shares_ = IPoolManagerLike(manager).previewWithdraw(msg.sender, assets_);
    }

    /******************************************************************************************************************************/
    /*** Public View Functions                                                                                                  ***/
    /******************************************************************************************************************************/

    function convertToAssets(uint256 shares_) public view override returns (uint256 assets_) {
        uint256 totalSupply_ = totalSupply;

        assets_ = totalSupply_ == 0 ? shares_ : (shares_ * totalAssets()) / totalSupply_;
    }

    function convertToExitAssets(uint256 shares_) public view override returns (uint256 assets_) {
        uint256 totalSupply_ = totalSupply;

        assets_ = totalSupply_ == 0 ? shares_ : shares_ * (totalAssets() - unrealizedLosses()) / totalSupply_;
    }

    function convertToShares(uint256 assets_) public view override returns (uint256 shares_) {
        uint256 totalSupply_ = totalSupply;

        shares_ = totalSupply_ == 0 ? assets_ : (assets_ * totalSupply_) / totalAssets();
    }

    function convertToExitShares(uint256 amount_) public view override returns (uint256 shares_) {
        shares_ = _divRoundUp(amount_ * totalSupply, totalAssets() - unrealizedLosses());
    }

    function previewDeposit(uint256 assets_) public view override returns (uint256 shares_) {
        // As per https://eips.ethereum.org/EIPS/eip-4626#security-considerations,
        // it should round DOWN if it’s calculating the amount of shares to issue to a user, given an amount of assets provided.
        shares_ = convertToShares(assets_);
    }

    function previewMint(uint256 shares_) public view override returns (uint256 assets_) {
        uint256 totalSupply_ = totalSupply;

        // As per https://eips.ethereum.org/EIPS/eip-4626#security-considerations,
        // it should round UP if it’s calculating the amount of assets a user must provide, to be issued a given amount of shares.
        assets_ = totalSupply_ == 0 ? shares_ : _divRoundUp(shares_ * totalAssets(), totalSupply_);
    }

    function totalAssets() public view override returns (uint256 totalAssets_) {
        totalAssets_ = IPoolManagerLike(manager).totalAssets();
    }

    function unrealizedLosses() public view override returns (uint256 unrealizedLosses_) {
        unrealizedLosses_ = IPoolManagerLike(manager).unrealizedLosses();
    }

}