// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../common/MasterCopy.sol";
import "../token/ERC20Detailed.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../token/ERC1155Receiver.sol";
import "../interfaces/IAPContract.sol";
import "../interfaces/IHexUtils.sol";
import "../interfaces/IWhitelist.sol";
import "./TokenBalanceStorage.sol";
import "../interfaces/IExchangeRegistry.sol";
import "../interfaces/IExchange.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/INAVUtils.sol";

contract VaultStorage is
    MasterCopy,
    ERC20Detailed,
    ERC1155Receiver,
    Pausable,
    ReentrancyGuard
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 constant arrSize = 200;
    uint8 public emergencyConditions;
    bool internal vaultSetupCompleted;
    bool internal vaultRegistrationCompleted;
    address public APContract;
    address public owner;
    address public vaultAdmin;
    uint256[] internal whiteListGroups;
    mapping(uint256 => bool) isWhiteListGroupPresent;
    address[] public assetList;
    mapping(address => bool) internal isAssetPresent;
    address public strategyBeneficiary; // Performance Fee beneficiary
    uint256 public strategyPercentage; // Performance Fee percentage
    uint256 public threshold;
    address public eth;
    mapping(address => uint256) userEtherBalance;
    address[] public etherDepositors;
    address public emergencyVault;
    TokenBalanceStorage tokenBalances;

    bool public isTimeLocked;
    mapping(address => uint256) public vaultTokensUnlockedForUser;
    uint256 public lockedDuration;
    mapping(address => uint256) public latestDeposit;

    uint256 public platformFeeInterest;
    uint256 public managementFeeInterest;
    uint256 public performanceFeeInterest;

    address public managementBeneficiary; // Management Fee beneficiary
    uint256 public managementPercentage; // Management Fee percentage

    //TODO verify if this code has to be used for this fn
    /// @dev Function to revert in case of low level call fail.
    /// @param _delegateStatus Boolean indicating the status of low level call.
    function revertDelegate(bool _delegateStatus) internal pure {
        if (!_delegateStatus) {
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }
    }

    /// @dev Function to get the balance of token from tokenBalances.
    /// @param _tokenAddress Address of the token.
    function getTokenBalance(address _tokenAddress)
        external
        view
        returns (uint256)
    {
        return tokenBalances.getTokenBalance(_tokenAddress);
    }

    /// @dev Function to add a token to assetList.
    /// @param _asset Address of the asset.
    function addToAssetList(address _asset) internal {
        require(_asset != address(0), "invalid asset address");
        if (!isAssetPresent[_asset]) {
            require(assetList.length + 1 <= arrSize, "Exceed length");
            assetList.push(_asset);
            isAssetPresent[_asset] = true;
        }
    }

    /// @dev Function to return the NAV of the Vault.
    function getVaultNAV() public view returns (uint256) {
        uint256 nav = 0;
        address wEth = IAPContract(APContract).getWETH();
        uint256 convexRes;
        for (uint256 i = 0; i < assetList.length; i++) {
            if (tokenBalances.getTokenBalance(assetList[i]) > 0) {
                uint256 tokenUSD = IAPContract(APContract).getUSDPrice(
                    assetList[i]
                );
                if (assetList[i] == eth) {
                    nav += IHexUtils(IAPContract(APContract).stringUtils())
                        .toDecimals(
                            wEth,
                            tokenBalances.getTokenBalance(assetList[i])
                        )
                        .mul(tokenUSD);
                } else {
                    nav += IHexUtils(IAPContract(APContract).stringUtils())
                        .toDecimals(
                            assetList[i],
                            tokenBalances.getTokenBalance(assetList[i])
                        )
                        .mul(tokenUSD);
                }
            }
            convexRes =
                convexRes +
                INAVUtils(IAPContract(APContract).getNavCalculator())
                    .getConvexNAV(assetList[i]);
        }
        nav = nav.div(1e18);
        uint256 accruedFees = platformFeeInterest +
            managementFeeInterest +
            performanceFeeInterest;
        // nav =
        //     nav -
        //     platformFeeInterest -
        //     managementFeeInterest -
        //     performanceFeeInterest +
        //     convexRes;
        // return nav;
        if ((nav + convexRes) > accruedFees) {
            nav = nav + convexRes - accruedFees;
            return nav;
        } else {
            nav = nav + convexRes;
            return nav;
        }
    }

    /// @dev Function to approve ERC20 token to the spendor.
    /// @param _token Address of the Token.
    /// @param _spender Address of the Spendor.
    /// @param _amount Amount of the tokens.
    function _approveToken(
        address _token,
        address _spender,
        uint256 _amount
    ) internal {
        if (IERC20(_token).allowance(address(this), _spender) > 0) {
            IERC20(_token).safeApprove(_spender, 0);
            IERC20(_token).safeApprove(_spender, _amount);
        } else IERC20(_token).safeApprove(_spender, _amount);
    }

    /// @dev Function to return NAV for Deposit token and amount.
    /// @param _tokenAddress Address of the deposit Token.
    /// @param _amount Amount of the Deposit tokens.
    function getDepositNAV(address _tokenAddress, uint256 _amount)
        internal
        view
        returns (uint256)
    {
        uint256 tokenUSD = IAPContract(APContract).getUSDPrice(_tokenAddress);
        address tokenAddress = _tokenAddress;
        if (tokenAddress == eth)
            tokenAddress = IAPContract(APContract).getWETH();
        return
            (
                IHexUtils(IAPContract(APContract).stringUtils())
                    .toDecimals(tokenAddress, _amount)
                    .mul(tokenUSD)
            ).div(1e18);
    }

    /// @dev Function to get the amount of Vault Tokens to be minted for the deposit NAV.
    /// @param depositNAV NAV of the Deposit Amount.
    function getMintValue(uint256 depositNAV) internal view returns (uint256) {
        return (depositNAV.mul(totalSupply())).div(getVaultNAV());
    }

    /// @dev Function to return Value of the Vault Token.
    function tokenValueInUSD() public view returns (uint256) {
        if (getVaultNAV() == 0 || totalSupply() == 0) {
            return 0;
        } else {
            return (getVaultNAV().mul(1e18)).div(totalSupply());
        }
    }

    /// @dev Function to update token balance in tokenBalances.
    /// @param tokenAddress Address of the Token.
    /// @param tokenAmount Amount of the tokens.
    /// @param isAddition Boolean indicating if token addition or substraction.
    function updateTokenBalance(
        address tokenAddress,
        uint256 tokenAmount,
        bool isAddition
    ) internal {
        if (isAddition) {
            tokenBalances.setTokenBalance(
                tokenAddress,
                tokenBalances.getTokenBalance(tokenAddress).add(tokenAmount)
            );
        } else {
            tokenBalances.setTokenBalance(
                tokenAddress,
                tokenBalances.getTokenBalance(tokenAddress).sub(tokenAmount)
            );
        }
    }

    /// @dev Function to return mapping details of ether depositors
    /// @param _address address to be queried
    function getEtherDepositor(address _address)
        external
        view
        returns (uint256)
    {
        return userEtherBalance[_address];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount); // Call parent hook
        if (isTimeLocked == true) {
            if (from == address(0)) {
                latestDeposit[to] = block.number;
            } else {
                if (amount > vaultTokensUnlockedForUser[from]) revert("LKD");
                vaultTokensUnlockedForUser[from] =
                    vaultTokensUnlockedForUser[from] -
                    amount;
                vaultTokensUnlockedForUser[to] = amount;
            }
        }
    }

    function setWithdrawLockPeriod(uint256 _lockDuration, bool _isTimeLocked)
        external
    {
        require(msg.sender == vaultAdmin, "!va");
        lockedDuration = _lockDuration;
        isTimeLocked = _isTimeLocked;
    }

    function unlockWithdraw() external {
        if (latestDeposit[msg.sender] + lockedDuration > block.number)
            revert("TLK Active");
        vaultTokensUnlockedForUser[msg.sender] = this.balanceOf(msg.sender);
    }

    function unlockWithdrawableAllowance(address _user, uint256 _unlocked)
        external
    {
        require(
            IAPContract(APContract).checkWalletAddress(msg.sender),
            "Unauthorized"
        );
        vaultTokensUnlockedForUser[_user] = _unlocked;
    }


    /// @dev Function to set Beneficiary Address and Percentage for performance fee.
    /// @param _beneficiary strategy beneficiary to which profit fee is given.
    /// @param _percentage percentage of profit fee to be given.
    function setBeneficiaryAndPercentage(
        address _beneficiary,
        uint256 _percentage
    ) external {
        require(msg.sender == vaultAdmin, "!va");
        strategyBeneficiary = _beneficiary;
        strategyPercentage = _percentage;
    }

    /// @dev Function to set Beneficiary Address and Percentage.
    /// @param _beneficiary strategy beneficiary to which profit fee is given.
    /// @param _percentage percentage of profit fee to be given.
    function setManagementFeeBeneficiaryAndPercentage(
        address _beneficiary,
        uint256 _percentage
    ) external {
        require(msg.sender == vaultAdmin, "!va");
        managementBeneficiary = _beneficiary;
        managementPercentage = _percentage;
    }
}