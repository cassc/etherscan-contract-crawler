// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @title IERC721Lockable
 * @dev トークンのtransfer抑止機能付きコントラクトのインターフェース
 * @author Lavulite
 */
interface IERC721Lockable {

   enum LockStatus {
      UnSet,
      UnLock,
      Lock
   }

    /**
     * @dev 個別ロックが指定された場合のイベント
     */
    event TokenLock(address indexed holder, address indexed operator, LockStatus lockStatus, uint256 indexed tokenId);
    
    /**
     * @dev ウォレットロックが指定された場合のイベント
     */
    event WalletLock(address indexed holder, address indexed operator, LockStatus lockStatus);

    /**
     * @dev 該当トークンIDのロックステータスを変更する。
     */
    function setTokenLock(uint256[] calldata tokenIds, LockStatus lockStatus) external;

    /**
     * @dev 該当ウォレットのロックステータスを変更する。
     */
    function setWalletLock(address to, LockStatus lockStatus) external;

    /**
     * @dev コントラクトのロックステータスを変更する。
     */
    function setContractLock(LockStatus lockStatus) external;

    /**
     * @dev 該当トークンIDがロックされているかを返す
     */
    function isLocked(uint256 tokenId) external view returns (bool);
    
    /**
     * @dev ウォレットロックを行っているかを返す
     */
    function isLocked(address holder) external view returns (bool);

    /**
     * @dev 転送が拒否されているトークンを全て返す
     */
    function getTokensUnderLock() external view returns (uint256[] memory);

    /**
     * @dev 転送が拒否されているstartからstopまでのトークンIDを返す
     */
    function getTokensUnderLock(uint256 start, uint256 end) external view returns (uint256[] memory);

}