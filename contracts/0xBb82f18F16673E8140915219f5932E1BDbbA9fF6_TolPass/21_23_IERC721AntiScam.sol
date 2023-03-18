// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title IERC721AntiScam
/// @dev 詐欺防止機能付きコントラクトのインターフェース
/// @author hayatti.eth

interface IERC721AntiScam {

   enum LockStatus {
      UnSet,
      UnLock,
      CalLock,
      AllLock
   }

    /**
     * @dev 個別ロックが指定された場合のイベント
     */
    event TokenLock(address indexed owner, address indexed from, uint lockStatus, uint256 indexed tokenId);

    /**
     * @dev 該当トークンIDにおけるロックレベルを return で返す。
     */
    function getLockStatus(uint256 tokenId) external view returns (LockStatus);

    /**
     * @dev 該当トークンIDにおいて、該当コントラクトの転送が許可されているかを返す
     */
    function getTokenLocked(address to ,uint256 tokenId) external view returns (bool);
    
    /**
     * @dev 該当コントラクトの転送が拒否されているトークンを全て返す
     */
    function getTokensUnderLock(address to) external view returns (uint256[] memory);

    /**
     * @dev 該当コントラクトの転送が拒否されているstartからstopまでのトークンIDを返す
     */
    function getTokensUnderLock(address to, uint256 start, uint256 end) external view returns (uint256[] memory);

    
    /**
     * @dev holderが所有するトークンのうち、該当コントラクトの転送が拒否されているトークンを全て返す
     */
    function getTokensUnderLock(address holder, address to) external view returns (uint256[] memory);

    /**
     * @dev holderが所有するトークンのうち、該当コントラクトの転送が拒否されているstartからstopまでのトークンIDを返す
     */
    function getTokensUnderLock(address holder, address to, uint256 start, uint256 end) external view returns (uint256[] memory);

    /**
     * @dev 該当ウォレットアドレスにおいて、該当コントラクトの転送が許可されているかを返す
     */
    function getLocked(address to ,address holder) external view returns (bool);

    /**
     * @dev CALのリストに無い独自の許可アドレスを追加する場合、こちらにアドレスを記載する。
     */
    function addLocalContractAllowList(address _contract) external;

    /**
     * @dev CALのリストにある独自の許可アドレスを削除する場合、こちらにアドレスを記載する。
     */
    function removeLocalContractAllowList(address _contract) external;


    /**
     * @dev CALを利用する場合のCALのレベルを設定する。レベルが高いほど、許可されるコントラクトの範囲が狭い。
     */
    function setContractAllowListLevel(uint256 level) external;

    /**
     * @dev デフォルトでのロックレベルを指定する。
     */
    function setContractLockStatus(LockStatus status) external;

}