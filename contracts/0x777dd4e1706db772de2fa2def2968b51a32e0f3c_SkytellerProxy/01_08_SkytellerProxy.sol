// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 *
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
 * Skyteller Proxy
 *
 * Thoughts? Questions? https://skyteller.xyz/
 */

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/// @notice Proxy that forwards all calls to the implementation
///   Minor change from the original OZ ERC1967Proxy implementation:
///   We override the receive function at the proxy level
///   to emit an event within the gas budget.
contract SkytellerProxy is ERC1967Proxy {
    /// @notice ETH received by the proxy
    event ReceiveValue(address indexed sender, uint256 amount);

    /// @notice Create a new proxy
    /// @param _logic The address of the implementation
    /// @param _data The calldata to initialize the implementation
    // solhint-disable-next-line no-empty-blocks
    constructor(address _logic, bytes memory _data) payable ERC1967Proxy(_logic, _data) {}

    /// @dev Unlike typical proxy pattern, implementation receive()
    /// will not be called.
    receive() external payable virtual override {
        emit ReceiveValue(msg.sender, msg.value);
    }
}