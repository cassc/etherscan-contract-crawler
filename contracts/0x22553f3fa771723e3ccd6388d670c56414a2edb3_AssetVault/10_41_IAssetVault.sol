// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IAssetVault {
    // ============= Enums ==============

    enum TokenType { ERC721, ERC1155 }

    // ============= Events ==============

    event WithdrawEnabled(address operator);
    event WithdrawERC20(address indexed operator, address indexed token, address recipient, uint256 amount);
    event WithdrawERC721(address indexed operator, address indexed token, address recipient, uint256 tokenId);
    event WithdrawPunk(address indexed operator, address indexed token, address recipient, uint256 tokenId);
    event WithdrawSuperRareV1(address indexed operator, address indexed token, address recipient, uint256 tokenId);

    event WithdrawERC1155(
        address indexed operator,
        address indexed token,
        address recipient,
        uint256 tokenId,
        uint256 amount
    );

    event WithdrawETH(address indexed operator, address indexed recipient, uint256 amount);
    event Call(address indexed operator, address indexed to, bytes data);
    event Approve(address indexed operator, address indexed token, address indexed spender, uint256 amount);
    event IncreaseAllowance(address indexed operator, address indexed token, address indexed spender, uint256 amount);
    event DecreaseAllowance(address indexed operator, address indexed token, address indexed spender, uint256 amount);
    event DelegateContract(address indexed operator, address indexed token, address indexed target, bool enabled);
    event DelegateToken(address indexed operator, address indexed token, address indexed target, uint256 tokenId, bool enabled);
    event DelegateRevoke(address indexed operator);

    // ================= Initializer ==================

    function initialize(address _whitelist) external;

    // ================ View Functions ================

    function withdrawEnabled() external view returns (bool);

    function whitelist() external view returns (address);

    // ================ Withdrawal Operations ================

    function enableWithdraw() external;

    function withdrawERC20(address token, address to) external;

    function withdrawERC721(
        address token,
        uint256 tokenId,
        address to
    ) external;

    function withdrawERC1155(
        address token,
        uint256 tokenId,
        address to
    ) external;

    function withdrawBatch(
        address[] calldata tokens,
        uint256[] calldata tokenIds,
        TokenType[] calldata tokenTypes,
        address to
    ) external;

    function withdrawETH(address to) external;

    function withdrawPunk(
        address punks,
        uint256 punkIndex,
        address to
    ) external;

    function withdrawSuperRareV1(
        address superRareV1,
        uint256 tokenId,
        address to
    ) external;

    // ================ Utility Operations ================

    function call(address to, bytes memory data) external;

    function callApprove(address token, address spender, uint256 amount) external;

    function callIncreaseAllowance(address token, address spender, uint256 amount) external;

    function callDecreaseAllowance(address token, address spender, uint256 amount) external;

    function callDelegateForContract(address token, address target, bool enable) external;

    function callDelegateForToken(address token, address target, uint256 tokenId, bool enable) external;

    function callRevokeAllDelegates() external;
}