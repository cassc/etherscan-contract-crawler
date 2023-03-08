// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 *
 *                                                 @######N
 *                                              ,##########
 *                                             @###@########p
 *                                           ,###" ###7##[email protected]##Q
 *                                          @###  @##b @## 7###
 *                                        ;###b   @##~ 8##b "@##p
 *                                      [email protected]###    ]##b   @##   @##Q
 *                                     ;###C     @##`   @##b   7###
 *                                   ,###b       ###    '@##    |@##p
 *                                  s###`       @##b     @##b     @##Q
 *                                ,###"         @##      ^##Q      [email protected]##
 *                               @###`         j##b       @##       ^@##p
 *                             ;###"           @##~       [email protected]#Q        @##Q
 *                            @###            ,@##mmmmssp, @##         "###
 *                          ;###b        ,s#W"@##b       '"[email protected]#b         ^@##p
 *                        [email protected]##b       ,#W^    @##             "[email protected]        @##Q
 *                       ;###^      ;#"      j##b                ^%Q       "###
 *                     ,###b      s#`        @##~       .#p         %#,     ^@##p
 *                    @###\    ,#b`         ]@#b ,sm#mms#[email protected]          "@p     @##Q
 *                  ,###b    ,#b            @#########bb*[email protected]#M         "@p    7###
 *                 @###`   ;#"              @###########[email protected]#b             '@m   ^@##p
 *               ;###"    #"               @#################               '@b   @##Q
 *              @###      @p               @#################               ,#b    [email protected]##
 *            ;###b        ^@m            ]#################b             ,#"       ^@##p
 *          .####            '%Q          @##^@############"            ;#"           @##Q
 *         s###|         ,,,ssm###,       ###  '78######b^            s###mp           "###
 *       ,####N#################[email protected]    @##b                      .##`'"%#####p        ^@##p
 *       @#######5TT7||``           "@p  @##                     ,#b`      '77#####p      @##Q
 *        ^%@###p                     "%###b                  ,s#\              7%#####p,  "###
 *           '%####p                    @##W#mp,         ,s##""                     ^%@####[email protected]##p
 *              '7####p                ;##b    ^"77""77"|^                              ^[email protected]######Q
 *                 |%####p             @##b                                              ,,[email protected]@#####
 *                    '7####p         ]@##                                   ,,;sm#############b77^
 *                       |7####p      @##b                       ,,,ps#############WW"7|^
 *                          |7####p   @##             ,,ss#############5TT7`|`
 *                             |%#######b ,,psN############WW77^^`
 *                                `7############WT*|"^
 *                                   '7"|"
 *
 *
 *
 *           ]##b                                @##U###                                      @##
 *           ]##b                '@##            @##[email protected]##                               j##b   @##
 *   ,#####m ]##b  ]###@##    ######### ,#####N, @##[email protected]##  s#####p ;##Q###p    s#####p @#####M @##s####N
 *  ]##b  7W`]##b ;##b '@#Q  @##b|@##` @##b  @##[email protected]##[email protected]##]###^ ^@######b77`  [email protected]##" `@## [email protected]#b   @##"" 8##b
 *   [email protected]####p ]######b   [email protected]#Q]##b '@## '@########[email protected]##[email protected]##@#########G##b      @######### [email protected]#b   @##   j##b
 *   s,  "@##j##b [email protected]##   %####b  '@##  @##p  ,sp @##[email protected]##!##Q   ,m,j##b  ,sp [email protected]#Q   ,m, [email protected]#b   @##   j##b
 *  "@######"]##b  '@##p  @###    %####[email protected]#####" @##[email protected]## ^@######"@##b  @##b |@######\  @####[email protected]##   j##b
 *                     ,,,###`
 *                     %###b
 *
 * Skyteller Proxy Factory
 *
 * Thoughts? Questions? https://skyteller.xyz/
 */

import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {SkytellerProxy} from "./SkytellerProxy.sol";
import "./SkytellerErrors.sol";

/// @notice Factory for creating new proxies
/// Offers both standard create and CREATE2-based create
contract SkytellerProxyFactory {
    /// @notice New proxy created
    event Create(address indexed proxy);

    /// @notice Create a new proxy
    /// @param implementation The address of the implementation
    /// @param data The calldata to initialize the implementation
    /// @return proxy The address of the new proxy
    function create(address implementation, bytes memory data)
        external
        payable
        returns (address proxy)
    {
        proxy = address(new SkytellerProxy{value: msg.value}(implementation, data));
        emit Create(proxy);
    }

    /// @notice Create a new proxy via CREATE2
    /// @param salt The salt to use for the CREATE2 address
    /// @param implementation The address of the implementation
    /// @param data The calldata for initialization
    /// @return proxy The address of the new proxy
    function create(bytes32 salt, address implementation, bytes memory data)
        external
        payable
        returns (address proxy)
    {
        proxy = Create2.deploy(
            msg.value,
            salt,
            abi.encodePacked(
                type(SkytellerProxy).creationCode, abi.encode(implementation, bytes(""))
            )
        );
        // solhint-disable-next-line avoid-low-level-calls
        (bool ok,) = proxy.call(data);
        if (!ok) {
            revert Skyteller_ProxyFactoryCallFailed();
        }
        emit Create(proxy);
    }

    /// @notice Predict the address of a new proxy
    /// @param salt The salt to use for the CREATE2 address
    /// @param implementation The address of the implementation
    /// @return predicted The predicted address
    function predictAddress(bytes32 salt, address implementation)
        external
        view
        returns (address predicted)
    {
        return Create2.computeAddress(
            salt,
            keccak256(
                abi.encodePacked(
                    type(SkytellerProxy).creationCode, abi.encode(implementation, bytes(""))
                )
            )
        );
    }
}