// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

interface IComposedSoccerStarNft {

    enum ComposeMode{
        COMPOSE_NORMAL,
        COMPOSE_FAST
    }

    enum PayMethod{
        PAY_BIB,
        PAY_BUSD
    }

    // Event when composed success
    event Composed(
    address sender,
    uint[] tokenIds, 
    uint  extraToken,
    uint composedToken,
    ComposeMode mode,
    PayMethod payMethod,
    uint payAmount
    );

    // Compse a higher leve nft token
    function compose(uint[] memory tokenIds, ComposeMode mode, uint extralToken, PayMethod payMethod) external;
}