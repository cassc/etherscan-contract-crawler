// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import "./NFTBond.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/**
 * @title ERC20NFTBond
 * @dev Contains functions related to buying and liquidating bonds,
 * and borrowing and returning funds when the principal is ERC20 token
 * @author Ethichub
 */
contract ERC20NFTBond is NFTBond {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IERC20Upgradeable private principalToken;
    IERC20Upgradeable private collateralToken;

    struct NFTParams {
        string name;
        string symbol;
        string baseUri;
    }

    function initialize(
        address _principalToken,
        address _collateralToken,
        NFTParams calldata _nftParams,
        address _accessManager,
        uint256[] calldata _interests,
        uint256[] calldata _maturities
    )
    external initializer {
        principalToken = IERC20Upgradeable(_principalToken);
        collateralToken = IERC20Upgradeable(_collateralToken);
        __NFTBond_init(_nftParams.name, _nftParams.symbol, _nftParams.baseUri);
        __CollateralizedBondGranter_init(_collateralToken);
        __InterestParameters_init(_interests, _maturities);
        __AccessManaged_init(_accessManager);
    }

    /**
     * @dev External function to buy a bond and returns the tokenId of the bond
     * when the contract is active
     * @param tokenUri string
     * @param beneficiary address
     * @param maturity uint256
     * @param principal uint256
     * @param nftHash bytes32
     * @param setApprove bool
     * @param nonce uint256
     * @param signature bytes
     */
    function buyBond(
        string calldata tokenUri,
        address beneficiary,
        uint256 maturity,
        uint256 principal,
        bytes32 nftHash,
        bool setApprove,
        uint256 nonce,
        bytes memory signature
    )
    external whenNotPaused returns (uint256) {
        return super._buyBond(tokenUri, beneficiary, maturity, principal, nftHash, setApprove, nonce, signature);
    }

    /**
     * @dev External function to redeem a bond and returns the amount of the bond
     */
    function redeemBond(uint256 tokenId) external returns (uint256) {
        return super._redeemBond(tokenId); 
    }

    function principalTokenAddress() external view returns (address) {
        return address(principalToken);
    }

    function pause() external onlyRole(PAUSER) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER) {
        _unpause();
    }

    /**
     * @dev Transfers from the buyer to this contract the principal token amount
     */
    function _beforeBondPurchased(
        string calldata tokenUri,
        address beneficiary,
        uint256 maturity,
        uint256 principal
    )
    internal override {
        super._beforeBondPurchased(tokenUri, beneficiary, maturity, principal);
        principalToken.safeTransferFrom(beneficiary, address(this), principal);
    }

    /**
     * @dev Transfers to the owner of the bond the amount of the bond when the contract has
     * liquidity, if not will send the correspondent amount of collateral
     */
    function _afterBondRedeemed(
        uint256 tokenId,
        uint256 amount,
        address beneficiary
    ) 
    internal override {
        Bond memory bond = bonds[tokenId];
        super._afterBondRedeemed(tokenId, amount, beneficiary);
        if (principalToken.balanceOf(address(this)) < amount) {
            uint256 porcentageOfCollateral = 100 - (principalToken.balanceOf(address(this)) * 100 / amount);
            uint256 amountOfCollateral = (bond.principal * porcentageOfCollateral / 100) * collateralMultiplier;
            principalToken.safeTransfer(beneficiary, principalToken.balanceOf(address(this)));
            if (collateralToken.balanceOf(address(this)) < amountOfCollateral) {
                collateralToken.safeTransfer(beneficiary, collateralToken.balanceOf(address(this)));
            } else {
                collateralToken.safeTransfer(beneficiary, amountOfCollateral);
            }
        } else {
            principalToken.safeTransfer(beneficiary, amount);
        }
    }

    /**
     * @dev Transfers to the recipient the amount of liquidity available in this contract
     */
    function _beforeRequestLiquidity(address destination, uint256 amount) internal override {
        principalToken.safeTransfer(destination, amount);
        super._beforeRequestLiquidity(destination, amount);
    }

    /**
     * @dev Transfers from the borrower the amount of liquidity borrowed
     */
    function _afterReturnLiquidity(uint256 amount) internal override {
        super._afterReturnLiquidity(amount);
        principalToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    function _pause() internal override {
        super._pause();
    }

    function _unpause() internal override {
        super._unpause();
    }

    uint256[49] private __gap;
}