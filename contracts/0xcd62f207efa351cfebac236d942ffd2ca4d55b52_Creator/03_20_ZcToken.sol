// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.16;

import 'src/tokens/ERC20.sol';
import 'src/interfaces/IERC5095.sol';
import 'src/interfaces/IRedeemer.sol';

contract ZcToken is ERC20, IERC5095 {
    /// @dev unix timestamp when the ERC5095 token can be redeemed
    uint256 public immutable override maturity;
    /// @dev address of the ERC20 token that is returned on ERC5095 redemption
    address public immutable override underlying;
    /// @dev uint8 associated with a given protocol in Swivel
    uint8 public immutable protocol;

    /////////////OPTIONAL///////////////// (Allows the calculation and distribution of yield post maturity)
    /// @dev address of a cToken
    address public immutable cToken;
    /// @dev address and interface for an external custody contract (necessary for some project's backwards compatability)
    address public immutable redeemer;

    error Maturity(uint256 timestamp);

    error Approvals(uint256 approved, uint256 amount);

    error Authorized(address owner);

    constructor(
        uint8 _protocol,
        address _underlying,
        uint256 _maturity,
        address _cToken,
        address _redeemer,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol, _decimals) {
        protocol = _protocol;
        underlying = _underlying;
        maturity = _maturity;
        cToken = _cToken;
        redeemer = _redeemer;
    }

    /// @notice Post maturity converts an amount of principal tokens to an amount of underlying that would be returned. Returns 0 pre-maturity.
    /// @param principalAmount The amount of principal tokens to convert
    /// @return The amount of underlying tokens returned by the conversion
    function convertToUnderlying(uint256 principalAmount)
        external
        view
        override
        returns (uint256)
    {
        if (block.timestamp < maturity) {
            return 0;
        }

        // note that maturity rate (mRate) == exchangeRate (xRate) if the mRate would have been 0 (see VaultTracker.rates)
        (uint256 mRate, uint256 xRate) = IRedeemer(redeemer).rates(
            protocol,
            underlying,
            maturity
        );

        return (principalAmount * xRate) / mRate;
    }

    /// @notice Post maturity converts a desired amount of underlying tokens returned to principal tokens needed. Returns 0 pre-maturity.
    /// @param underlyingAmount The amount of underlying tokens to convert
    /// @return The amount of principal tokens returned by the conversion
    function convertToPrincipal(uint256 underlyingAmount)
        external
        view
        override
        returns (uint256)
    {
        if (block.timestamp < maturity) {
            return 0;
        }

        // note that maturity rate (mRate) == exchangeRate (xRate) if the mRate would have been 0 (see VaultTracker.rates)
        (uint256 mRate, uint256 xRate) = IRedeemer(redeemer).rates(
            protocol,
            underlying,
            maturity
        );

        return (underlyingAmount * mRate) / xRate;
    }

    /// @notice Post maturity calculates the amount of principal tokens that `owner` can redeem. Returns 0 pre-maturity.
    /// @param owner The address of the owner for which redemption is calculated
    /// @return The maximum amount of principal tokens that `owner` can redeem.
    function maxRedeem(address owner) external view override returns (uint256) {
        if (block.timestamp < maturity) {
            return 0;
        }
        return balanceOf[owner];
    }

    /// @notice Post maturity simulates the effects of redeemption at the current block. Returns 0 pre-maturity.
    /// @param principalAmount the amount of principal tokens redeemed in the simulation
    /// @return The maximum amount of underlying returned by `principalAmount` of PT redemption
    function previewRedeem(uint256 principalAmount)
        external
        view
        override
        returns (uint256)
    {
        if (block.timestamp < maturity) {
            return 0;
        }

        // note that maturity rate (mRate) == exchangeRate (xRate) if the mRate would have been 0 (see VaultTracker.rates)
        (uint256 mRate, uint256 xRate) = IRedeemer(redeemer).rates(
            protocol,
            underlying,
            maturity
        );

        return (principalAmount * xRate) / mRate;
    }

    /// @notice Post maturity calculates the amount of underlying tokens that `owner` can withdraw. Returns 0 pre-maturity.
    /// @param  owner The address of the owner for which withdrawal is calculated
    /// @return The maximum amount of underlying tokens that `owner` can withdraw.
    function maxWithdraw(address owner)
        external
        view
        override
        returns (uint256)
    {
        if (block.timestamp < maturity) {
            return 0;
        }

        // note that maturity rate (mRate) == exchangeRate (xRate) if the mRate would have been 0 (see VaultTracker.rates)
        (uint256 mRate, uint256 xRate) = IRedeemer(redeemer).rates(
            protocol,
            underlying,
            maturity
        );

        return (balanceOf[owner] * xRate) / mRate;
    }

    /// @notice Post maturity simulates the effects of withdrawal at the current block. Returns 0 pre-maturity.
    /// @param underlyingAmount the amount of underlying tokens withdrawn in the simulation
    /// @return The amount of principal tokens required for the withdrawal of `underlyingAmount`
    function previewWithdraw(uint256 underlyingAmount)
        public
        view
        override
        returns (uint256)
    {
        if (block.timestamp < maturity) {
            return 0;
        }

        // note that maturity rate (mRate) == exchangeRate (xRate) if the mRate would have been 0 (see VaultTracker.rates)
        (uint256 mRate, uint256 xRate) = IRedeemer(redeemer).rates(
            protocol,
            underlying,
            maturity
        );

        return (underlyingAmount * mRate) / xRate;
    }

    /// @notice At or after maturity, Burns principalAmount from `owner` and sends exactly `underlyingAmount` of underlying tokens to `receiver`.
    /// @param underlyingAmount The amount of underlying tokens withdrawn
    /// @param receiver The receiver of the underlying tokens being withdrawn
    /// @return The amount of principal tokens burnt by the withdrawal
    function withdraw(
        uint256 underlyingAmount,
        address receiver,
        address holder
    ) external override returns (uint256) {
        // If maturity is not yet reached. TODO this is moved from underneath the previewAmount call - should have been here before? Discuss.
        if (block.timestamp < maturity) {
            revert Maturity(maturity);
        }

        // TODO removing both the `this.foo` and `external` bits of this pattern as it's simply an unnecessary misdirection. Discuss.
        uint256 previewAmount = previewWithdraw(underlyingAmount);

        // Transfer logic: If holder is msg.sender, skip approval check
        if (holder == msg.sender) {
            IRedeemer(redeemer).authRedeem(
                protocol,
                underlying,
                maturity,
                msg.sender,
                receiver,
                previewAmount
            );
        } else {
            uint256 allowed = allowance[holder][msg.sender];
            if (allowed < previewAmount) {
                revert Approvals(allowed, previewAmount);
            }
            allowance[holder][msg.sender] =
                allowance[holder][msg.sender] -
                previewAmount;
            IRedeemer(redeemer).authRedeem(
                protocol,
                underlying,
                maturity,
                holder,
                receiver,
                previewAmount
            );
        }

        return previewAmount;
    }

    /// @notice At or after maturity, burns exactly `principalAmount` of Principal Tokens from `owner` and sends underlyingAmount of underlying tokens to `receiver`.
    /// @param principalAmount The amount of principal tokens being redeemed
    /// @param receiver The receiver of the underlying tokens being withdrawn
    /// @return The amount of underlying tokens distributed by the redemption
    function redeem(
        uint256 principalAmount,
        address receiver,
        address holder
    ) external override returns (uint256) {
        // If maturity is not yet reached
        if (block.timestamp < maturity) {
            revert Maturity(maturity);
        }

        // some 5095 tokens may have custody of underlying and can can just burn PTs and transfer underlying out, while others rely on external custody
        if (holder == msg.sender) {
            return
                IRedeemer(redeemer).authRedeem(
                    protocol,
                    underlying,
                    maturity,
                    msg.sender,
                    receiver,
                    principalAmount
                );
        } else {
            uint256 allowed = allowance[holder][msg.sender];

            if (allowed < principalAmount) {
                revert Approvals(allowed, principalAmount);
            }

            allowance[holder][msg.sender] =
                allowance[holder][msg.sender] -
                principalAmount;
            return
                IRedeemer(redeemer).authRedeem(
                    protocol,
                    underlying,
                    maturity,
                    holder,
                    receiver,
                    principalAmount
                );
        }
    }

    /// @param f Address to burn from
    /// @param a Amount to burn
    function burn(address f, uint256 a)
        external
        onlyAdmin(address(redeemer))
        returns (bool)
    {
        _burn(f, a);
        return true;
    }

    /// @param t Address recieving the minted amount
    /// @param a The amount to mint
    function mint(address t, uint256 a)
        external
        onlyAdmin(address(redeemer))
        returns (bool)
    {
        // disallow minting post maturity
        if (block.timestamp > maturity) {
            revert Maturity(maturity);
        }
        _mint(t, a);
        return true;
    }

    modifier onlyAdmin(address a) {
        if (msg.sender != a) {
            revert Authorized(a);
        }
        _;
    }
}