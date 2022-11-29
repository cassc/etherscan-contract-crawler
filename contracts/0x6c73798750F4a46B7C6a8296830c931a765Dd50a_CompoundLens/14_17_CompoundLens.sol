pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

import "../BErc20.sol";
import "../Comptroller.sol";
import "../BToken.sol";
import "../PriceOracle/PriceOracle.sol";
import "../EIP20Interface.sol";
import "../Exponential.sol";

interface CSLPInterface {
    function claimSushi(address) external returns (uint256);
}

interface CBTokenInterface {
    function claimComp(address) external returns (uint256);
}

contract CompoundLens is Exponential {
    struct BTokenMetadata {
        address bToken;
        uint256 exchangeRateCurrent;
        uint256 supplyRatePerBlock;
        uint256 borrowRatePerBlock;
        uint256 reserveFactorMantissa;
        uint256 totalBorrows;
        uint256 totalReserves;
        uint256 totalSupply;
        uint256 totalCash;
        uint256 totalCollateralTokens;
        bool isListed;
        uint256 collateralFactorMantissa;
        address underlyingAssetAddress;
        uint256 bTokenDecimals;
        uint256 underlyingDecimals;
        ComptrollerV1Storage.Version version;
        uint256 collateralCap;
        uint256 underlyingPrice;
        bool supplyPaused;
        bool borrowPaused;
        uint256 supplyCap;
        uint256 borrowCap;
    }

    function bTokenMetadataInternal(
        BToken bToken,
        Comptroller comptroller,
        PriceOracle priceOracle
    ) internal returns (BTokenMetadata memory) {
        uint256 exchangeRateCurrent = bToken.exchangeRateCurrent();
        (
            bool isListed,
            uint256 collateralFactorMantissa,
            ComptrollerV1Storage.Version version
        ) = comptroller.markets(address(bToken));
        address underlyingAssetAddress;
        uint256 underlyingDecimals;
        uint256 collateralCap;
        uint256 totalCollateralTokens;

        if (compareStrings(bToken.symbol(), "crETH")) {
            underlyingAssetAddress = address(0);
            underlyingDecimals = 18;
        } else {
            BErc20 bErc20 = BErc20(address(bToken));
            underlyingAssetAddress = bErc20.underlying();
            underlyingDecimals = EIP20Interface(bErc20.underlying()).decimals();
        }

        if (version == ComptrollerV1Storage.Version.COLLATERALCAP) {
            collateralCap = BCollateralCapErc20Interface(address(bToken))
                .collateralCap();
            totalCollateralTokens = BCollateralCapErc20Interface(
                address(bToken)
            ).totalCollateralTokens();
        } else if (version == ComptrollerV1Storage.Version.WRAPPEDNATIVE) {
            collateralCap = BWrappedNativeInterface(address(bToken))
                .collateralCap();
            totalCollateralTokens = BWrappedNativeInterface(address(bToken))
                .totalCollateralTokens();
        }

        return
            BTokenMetadata({
                bToken: address(bToken),
                exchangeRateCurrent: exchangeRateCurrent,
                supplyRatePerBlock: bToken.supplyRatePerBlock(),
                borrowRatePerBlock: bToken.borrowRatePerBlock(),
                reserveFactorMantissa: bToken.reserveFactorMantissa(),
                totalBorrows: bToken.totalBorrows(),
                totalReserves: bToken.totalReserves(),
                totalSupply: bToken.totalSupply(),
                totalCash: bToken.getCash(),
                totalCollateralTokens: totalCollateralTokens,
                isListed: isListed,
                collateralFactorMantissa: collateralFactorMantissa,
                underlyingAssetAddress: underlyingAssetAddress,
                bTokenDecimals: bToken.decimals(),
                underlyingDecimals: underlyingDecimals,
                version: version,
                collateralCap: collateralCap,
                underlyingPrice: priceOracle.getUnderlyingPrice(bToken),
                supplyPaused: comptroller.mintGuardianPaused(address(bToken)),
                borrowPaused: comptroller.borrowGuardianPaused(address(bToken)),
                supplyCap: comptroller.supplyCaps(address(bToken)),
                borrowCap: comptroller.borrowCaps(address(bToken))
            });
    }

    function bTokenMetadata(BToken bToken)
        public
        returns (BTokenMetadata memory)
    {
        Comptroller comptroller = Comptroller(address(bToken.comptroller()));
        PriceOracle priceOracle = comptroller.oracle();
        return bTokenMetadataInternal(bToken, comptroller, priceOracle);
    }

    function bTokenMetadataAll(BToken[] calldata bTokens)
        external
        returns (BTokenMetadata[] memory)
    {
        uint256 bTokenCount = bTokens.length;
        require(bTokenCount > 0, "invalid input");
        BTokenMetadata[] memory res = new BTokenMetadata[](bTokenCount);
        Comptroller comptroller = Comptroller(
            address(bTokens[0].comptroller())
        );
        PriceOracle priceOracle = comptroller.oracle();
        for (uint256 i = 0; i < bTokenCount; i++) {
            require(
                address(comptroller) == address(bTokens[i].comptroller()),
                "mismatch comptroller"
            );
            res[i] = bTokenMetadataInternal(
                bTokens[i],
                comptroller,
                priceOracle
            );
        }
        return res;
    }

    struct BTokenBalances {
        address bToken;
        uint256 balanceOf;
        uint256 borrowBalanceCurrent;
        uint256 balanceOfUnderlying;
        uint256 tokenBalance;
        uint256 tokenAllowance;
        bool collateralEnabled;
        uint256 collateralBalance;
        uint256 nativeTokenBalance;
    }

    function bTokenBalances(BToken bToken, address payable account)
        public
        returns (BTokenBalances memory)
    {
        address comptroller = address(bToken.comptroller());
        bool collateralEnabled = Comptroller(comptroller).checkMembership(
            account,
            bToken
        );
        uint256 tokenBalance;
        uint256 tokenAllowance;
        uint256 collateralBalance;

        if (compareStrings(bToken.symbol(), "crETH")) {
            tokenBalance = account.balance;
            tokenAllowance = account.balance;
        } else {
            BErc20 bErc20 = BErc20(address(bToken));
            EIP20Interface underlying = EIP20Interface(bErc20.underlying());
            tokenBalance = underlying.balanceOf(account);
            tokenAllowance = underlying.allowance(account, address(bToken));
        }

        if (collateralEnabled) {
            (, collateralBalance, , ) = bToken.getAccountSnapshot(account);
        }

        return
            BTokenBalances({
                bToken: address(bToken),
                balanceOf: bToken.balanceOf(account),
                borrowBalanceCurrent: bToken.borrowBalanceCurrent(account),
                balanceOfUnderlying: bToken.balanceOfUnderlying(account),
                tokenBalance: tokenBalance,
                tokenAllowance: tokenAllowance,
                collateralEnabled: collateralEnabled,
                collateralBalance: collateralBalance,
                nativeTokenBalance: account.balance
            });
    }

    function bTokenBalancesAll(
        BToken[] calldata bTokens,
        address payable account
    ) external returns (BTokenBalances[] memory) {
        uint256 bTokenCount = bTokens.length;
        BTokenBalances[] memory res = new BTokenBalances[](bTokenCount);
        for (uint256 i = 0; i < bTokenCount; i++) {
            res[i] = bTokenBalances(bTokens[i], account);
        }
        return res;
    }

    struct AccountLimits {
        BToken[] markets;
        uint256 liquidity;
        uint256 shortfall;
    }

    function getAccountLimits(Comptroller comptroller, address account)
        public
        returns (AccountLimits memory)
    {
        (uint256 errorCode, uint256 liquidity, uint256 shortfall) = comptroller
            .getAccountLiquidity(account);
        require(errorCode == 0);

        return
            AccountLimits({
                markets: comptroller.getAssetsIn(account),
                liquidity: liquidity,
                shortfall: shortfall
            });
    }

    function getClaimableSushiRewards(
        CSLPInterface[] calldata bTokens,
        address sushi,
        address account
    ) external returns (uint256[] memory) {
        uint256 bTokenCount = bTokens.length;
        uint256[] memory rewards = new uint256[](bTokenCount);
        for (uint256 i = 0; i < bTokenCount; i++) {
            uint256 balanceBefore = EIP20Interface(sushi).balanceOf(account);
            bTokens[i].claimSushi(account);
            uint256 balanceAfter = EIP20Interface(sushi).balanceOf(account);
            rewards[i] = sub_(balanceAfter, balanceBefore);
        }
        return rewards;
    }

    function getClaimableCompRewards(
        CBTokenInterface[] calldata bTokens,
        address comp,
        address account
    ) external returns (uint256[] memory) {
        uint256 bTokenCount = bTokens.length;
        uint256[] memory rewards = new uint256[](bTokenCount);
        for (uint256 i = 0; i < bTokenCount; i++) {
            uint256 balanceBefore = EIP20Interface(comp).balanceOf(account);
            bTokens[i].claimComp(account);
            uint256 balanceAfter = EIP20Interface(comp).balanceOf(account);
            rewards[i] = sub_(balanceAfter, balanceBefore);
        }
        return rewards;
    }

    function compareStrings(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }
}