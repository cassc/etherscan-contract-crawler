// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "./interfaces.sol";

contract Resolver {
    struct VaultData {
        bool isToken;
        string name;
        string symbol;
        uint256 decimals;
        address asset;
        uint256 totalAssets;
        uint256 totalSupply;
        uint256 convertToShares;
        uint256 convertToAssets;
    }

    struct UserPosition {
        uint256 underlyingBalance;
        uint256 vaultBalance;
    }

    struct VaultPreview {
        uint256 previewDeposit;
        uint256 previewMint;
        uint256 previewWithdraw;
        uint256 previewRedeem;
    }

    function getVaultDetails(address[] memory vaultAddresses) public view returns (VaultData[] memory) {
        VaultData[] memory _vaultData = new VaultData[](vaultAddresses.length);
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            VaultInterface vaultToken = VaultInterface(vaultAddresses[i]);
            bool isToken = true;

            try vaultToken.symbol() {} catch {
                isToken = false;
                continue;
            }

            try vaultToken.name() {} catch {
                isToken = false;
                continue;
            }

            try vaultToken.decimals() {} catch {
                isToken = false;
                continue;
            }

            try vaultToken.asset() {} catch {
                isToken = false;
                continue;
            }

            _vaultData[i] = VaultData(
                isToken,
                vaultToken.name(),
                vaultToken.symbol(),
                vaultToken.decimals(),
                vaultToken.asset(),
                vaultToken.totalAssets(),
                vaultToken.totalSupply(),
                vaultToken.convertToShares(10**vaultToken.decimals()), // example convertToShares for 10 ** decimal
                vaultToken.convertToAssets(10**vaultToken.decimals()) // example convertToAssets for 10 ** decimal
            );
        }

        return _vaultData;
    }

    function getPositions(address owner, address[] memory vaultAddress) public view returns (UserPosition[] memory) {
        UserPosition[] memory _userPosition = new UserPosition[](vaultAddress.length);
        for (uint256 i = 0; i < vaultAddress.length; i++) {
            VaultInterface vaultToken = VaultInterface(vaultAddress[i]);

            address _underlyingAddress = vaultToken.asset();
            TokenInterface underlyingToken = TokenInterface(_underlyingAddress);

            _userPosition[i].underlyingBalance = underlyingToken.balanceOf(owner);
            _userPosition[i].vaultBalance = vaultToken.balanceOf(owner);
        }

        return _userPosition;
    }

    function getAllowances(address owner, address[] memory vaultAddresses) public view returns (uint256[] memory) {
        uint256[] memory _tokenAllowance = new uint256[](vaultAddresses.length);

        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            VaultInterface vaultToken = VaultInterface(vaultAddresses[i]);
            _tokenAllowance[i] = vaultToken.allowance(owner, vaultAddresses[i]);
        }

        return _tokenAllowance;
    }

    function getVaultPreview(uint256 amount, address[] memory vaultAddresses)
        public
        view
        returns (VaultPreview[] memory)
    {
        VaultPreview[] memory _vaultPreview = new VaultPreview[](vaultAddresses.length);

        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            VaultInterface vaultToken = VaultInterface(vaultAddresses[i]);

            _vaultPreview[i].previewDeposit = vaultToken.previewDeposit(amount);
            _vaultPreview[i].previewMint = vaultToken.previewMint(amount);
            _vaultPreview[i].previewWithdraw = vaultToken.previewWithdraw(amount);
            _vaultPreview[i].previewRedeem = vaultToken.previewRedeem(amount);
        }

        return _vaultPreview;
    }
}

contract InstaERC4626Resolver is Resolver {
    string public constant name = "ERC4626-Resolver-v1";
}