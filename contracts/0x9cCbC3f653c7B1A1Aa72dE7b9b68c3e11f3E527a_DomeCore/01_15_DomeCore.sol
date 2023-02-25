//SPDX-License-Identifier: MIT

 pragma solidity ^0.8.17;

/// Openzeppelin imports
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/interfaces/IERC4626.sol";

/// Local imports
import "./Interfaces/ImAssetSaveWrapper.sol";
import "./Interfaces/ImUSDToken.sol";
import "./Interfaces/ImUSDSavingsContract.sol";

contract DomeCore is ERC4626, Ownable {
    using SafeERC20 for IERC20;

    struct BeneficiaryInfo {
        string beneficiaryCID;
        address wallet;
        uint256 percentage;
    }

    /// contracts
    IERC20 public stakingCoin;
    ImUSDSavingsContract public mUSDSavingsContract;
    ImUSDToken public mUSDToken;
    ImAssetSaveWrapper public mAssetSaveWrapper;
    address public mUSDSavingsVault;

    address public _systemOwner;
    uint256 public _systemOwnerPercentage;

    //Amount Of Underlying assets owned by depositor, interested + principal
    uint256 public underlyingAssetsOwnedByDepositor;

    string public _domeCID;

    BeneficiaryInfo[] public beneficiaries;

    event Staked(address indexed staker, uint256 amount, uint256 timestamp);
    event Unstaked(address indexed unstaker, uint256 unstakedAmount, uint256 timestamp);
    event Claimed(address indexed claimer, uint256 amount, uint256 timestamp);

    /// Constructor
    constructor(
        string[] memory domeInfo,
        address stakingCoinAddress,
        address mUSDSavingsContractAddress,
        address mUSDTokenAddress,
        address mAssetSaveWrapperAddress,
        address mUSDSavingsVaultAddress,
        address owner,
        address systemOwner,
        uint256 systemOwnerPercentage,
        BeneficiaryInfo[] memory beneficiariesInfo
    )
        ERC20(domeInfo[1], domeInfo[2])
        ERC4626(IERC20Metadata(stakingCoinAddress))
    {
        stakingCoin = IERC20(stakingCoinAddress);
        mUSDSavingsContract = ImUSDSavingsContract(mUSDSavingsContractAddress);
        mUSDToken = ImUSDToken(mUSDTokenAddress);
        mAssetSaveWrapper = ImAssetSaveWrapper(mAssetSaveWrapperAddress);
        mUSDSavingsVault = mUSDSavingsVaultAddress;
        _domeCID = domeInfo[0];
        for (uint256 i; i < beneficiariesInfo.length; i++) {
            beneficiaries.push(beneficiariesInfo[i]);
        }
        transferOwnership(owner);
        stakingCoin.approve(mAssetSaveWrapperAddress, 2**256 - 1);
        _systemOwner = systemOwner;
        _systemOwnerPercentage = systemOwnerPercentage;
    }

    function decimals()
        public
        pure
        override(ERC20, IERC20Metadata)
        returns (uint8)
    {
        return 6;
    }

    function getBeneficiariesInfo()
        public
        view
        returns (BeneficiaryInfo[] memory)
    {
        return beneficiaries;
    }

    function totalBalance() public view returns (uint256) {
        uint256 mUSD = mUSDSavingsContract.balanceOfUnderlying(address(this));
        uint256 asset = mUSDToken.getRedeemOutput(address(stakingCoin), mUSD);
        return asset;
    }

    function setApproveForDome(uint256 amount) public onlyOwner {
        stakingCoin.approve(address(mAssetSaveWrapper), amount);
    }

    function deposit(uint256 assets, address receiver)
        public
        override
        returns (uint256)
    {
        uint256 shares = previewDeposit(assets);
        _deposit(msg.sender, receiver, assets, shares);
        return shares;
    }

    function mint(uint256 shares, address receiver)
        public
        virtual
        override
        returns (uint256)
    {
        uint256 assets = previewMint(shares);
        _deposit(msg.sender, receiver, assets, shares);
        return assets;
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override returns (uint256) {
        uint256 shares = previewWithdraw(assets);
        _withdraw(msg.sender, receiver, owner, assets, shares);
        return shares;
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual override returns (uint256) {
        uint256 assets = previewRedeem(shares);
        _withdraw(msg.sender, receiver, owner, assets, shares);
        return assets;
    }

    function claimInterests() public {
        uint256 reward;
        uint256 balanceINmStable = totalBalance();
        if (balanceINmStable >= underlyingAssetsOwnedByDepositor) {
            reward = balanceINmStable - underlyingAssetsOwnedByDepositor;
        } else {
            return;
        }

        uint256 systemFee = (reward * _systemOwnerPercentage) / 100;
        uint256 beneficiariesReward = ((reward - systemFee) *
            beneficiariesPercentage()) / 100;
        uint256 shares;
        uint256 mAssets;
        (shares, mAssets) = estimateSharesForWithdraw(
            beneficiariesReward + systemFee
        );
        uint256 minAmountOut = mUSDToken.getRedeemOutput(
            address(stakingCoin),
            mAssets
        );
        mUSDSavingsContract.redeemAndUnwrap(
            shares,
            true,
            minAmountOut,
            address(stakingCoin),
            address(this),
            address(mUSDToken),
            true
        );
        stakingCoin.safeTransfer(_systemOwner, systemFee);
        uint256 totalTransfered = systemFee;
        uint256 toTransfer;
        for (uint256 i; i < beneficiaries.length; i++) {
            if (i == beneficiaries.length - 1) {
                toTransfer = minAmountOut - totalTransfered; 
                stakingCoin.safeTransfer(beneficiaries[i].wallet, toTransfer);
                totalTransfered += toTransfer;
            } else {
                toTransfer =
                    ((reward - systemFee) * beneficiaries[i].percentage) /
                    100;
                stakingCoin.safeTransfer(beneficiaries[i].wallet, toTransfer);
                totalTransfered += toTransfer;
            }
        }
        underlyingAssetsOwnedByDepositor += (reward - totalTransfered);
        emit Claimed(msg.sender, totalTransfered, block.timestamp);
    }

    function beneficiariesPercentage()
        public
        view
        returns (uint256 totalPercentage)
    {
        for (uint256 i; i < beneficiaries.length; i++) {
            totalPercentage += beneficiaries[i].percentage;
        }
    }

    function balanceOfUnderlying(address user) public view returns (uint256) {
        if (balanceOf(user) == 0) {
            return 0;
        } else {
            return (balanceOf(user) * estimateReward()) / totalSupply();
        }
    }

    function convertToAssets(uint256 shares)
        public
        view
        virtual
        override
        returns (uint256 assets)
    {
        if (totalSupply() == 0) {
            return shares;
        } else {
            return (shares * estimateReward()) / totalSupply();
        }
    }

    function convertToShares(uint256 assets)
        public
        view
        virtual
        override
        returns (uint256 shares)
    {
        if (totalSupply() == 0) {
            return assets;
        } else {
            return (assets * totalSupply()) / estimateReward();
        }
    }

    function maxWithdraw(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return balanceOfUnderlying(owner);
    }

    function previewDeposit(uint256 assets)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return convertToAssets(shares);
    }

    function previewWithdraw(uint256 assets)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return convertToShares(assets);
    }

    function previewRedeem(uint256 shares)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return convertToAssets(shares);
    }

    function estimateReward() internal view returns (uint256) {
        uint256 totalReward = totalBalance();
        uint256 reward;
        if (totalReward > underlyingAssetsOwnedByDepositor) {
            uint256 newReward = totalReward - underlyingAssetsOwnedByDepositor;
            uint256 systemFee = (newReward * _systemOwnerPercentage) / 100;
            uint256 beneficiariesInterest = ((newReward - systemFee) *
                beneficiariesPercentage()) / 100;
            reward = totalReward - systemFee - beneficiariesInterest;
        } else {
            reward = totalReward;
        }
        return reward;
    }

    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal virtual override {
        require(assets > 0, "The assets must be greater than 0");
        require(
            assets <= stakingCoin.allowance(caller, address(this)),
            "There is no as much allowance for staking coin"
        );
        require(
            assets <= stakingCoin.balanceOf(caller),
            "There is no as much balance for staking coin"
        );

        stakingCoin.safeTransferFrom(caller, address(this), assets);

        uint256 minOut = mUSDToken.getMintOutput(address(stakingCoin), assets);

        mAssetSaveWrapper.saveViaMint(
            address(mUSDToken),
            address(mUSDSavingsContract),
            mUSDSavingsVault,
            address(stakingCoin),
            assets,
            minOut,
            false
        );

        underlyingAssetsOwnedByDepositor += assets;

        _mint(receiver, shares);

        emit Staked(receiver, assets, block.timestamp);
    }

    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal virtual override {
        require(owner == caller, "Caller is not an owner");
        require(0 < assets, "The amount must be greater than 0");
        uint256 liquidityAmount = balanceOf(owner);
        require(shares <= liquidityAmount, "You don't have enough balance");

        claimInterests();

        uint256 sharesInMstable;
        uint256 mAssets;
        (sharesInMstable, mAssets) = estimateSharesForWithdraw(assets);
        uint256 minAmountOut = mUSDToken.getRedeemOutput(
            address(stakingCoin),
            mAssets
        );
        mUSDSavingsContract.redeemAndUnwrap(
            sharesInMstable,
            true,
            minAmountOut,
            address(stakingCoin),
            receiver,
            address(mUSDToken),
            true
        );

        underlyingAssetsOwnedByDepositor -= assets;

        _burn(owner, shares);

        emit Unstaked(owner, assets, block.timestamp);
    }

    function estimateSharesForWithdraw(uint256 asset)
        public
        view
        returns (uint256 shares, uint256 mAsset)
    {
        uint256 coefficient = mUSDToken.getRedeemOutput(
            address(stakingCoin),
            10**18
        );
        
        mAsset = (asset * 10**18) / (coefficient + 1);
        shares = mUSDSavingsContract.convertToShares(mAsset);
    }
}