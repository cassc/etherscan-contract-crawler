// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Yabumi is ERC721, Ownable {
    /**
     * @dev
     * - All functions of Counters are available for _tokenIds
     * - _tokenIdsはCountersの全関数が利用可能
     */
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    /// @dev Base URI where the json file is located
    /// jsonファイルの配置先のベースURI
    string private __baseURI;

    /// @dev Address to be signed on the backend
    /// バックエンドで署名するアドレス
    address public _signatureAddress;

    /// @dev Mapping to record jointedId(userID + SNSID) linked to tokenID
    /// tokenIDに対応するjointedID(userID + SNSID)を記録するMapping
    mapping(uint256 => string) private _tokenIdtoJointedId;

    /// @dev Mapping to record the tokenID corresponding to the minted jointID
    /// mint済みのjointedID(userID + SNSID)に対応するtokenIDを記録するMapping
    mapping(string => uint256) private _isJointedIdMinted;

    /// @dev Mapping to record the address corresponding to the tokenID minted
    /// mintしたtokenIDに対応するアドレスを記録するMapping
    mapping(uint256 => address) private _tokenIdtoMintedAddress;

    /**
     * @dev
     * - Record tokenId and jointedId at the time of mint
     * - mint時にtokenIdとjointedIdを記録する
     */
    event mintRecord(uint256 indexed tokenId, string jointedId);

    constructor(string memory baseURI, address signatureAddress)
        ERC721("Yabumi NFT", "YABUMI")
    {
        __baseURI = baseURI;
        _signatureAddress = signatureAddress;
    }

    /**
     * @dev
     * - Provides the ability to mint NFTs.
     * - Sign the backend and verify that the signed addresses match.
     * - TokenIDs are auto-numbered and minted so that they are sequentially numbered.
     * - NFTをmintする機能を提供します。
     * - バックエンドで署名を行い、署名されたアドレスが一致していることを確認します。
     * - TokenIDは自動採番して連番になるようにmintします。
     */
    function mint(
        string memory jointedId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        // バックエンドで署名をしたアドレスと一致しない場合はエラー
        require(
            _signatureAddress == verifySignatureAddress(jointedId, v, r, s),
            "signatures do not match"
        );

        // Check that it is not a signature that has been minted in the past. If the signature information has been minted in the past, an error occurs.
        // 過去にmintしている IDでないことを確認。過去にmintしたことがあるIDだった場合はエラー。
        require(_isJointedIdMinted[jointedId] == 0, "already minted");

        // The tokenID is numbered.
        // tokenIDを採番します。
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();

        // Stores minted information in Mapping
        // mintした情報をMappingに格納
        _isJointedIdMinted[jointedId] = tokenId;
        _tokenIdtoJointedId[tokenId] = jointedId;
        _tokenIdtoMintedAddress[tokenId] = msg.sender;

        // Execute mint with tokenID numbered to the mint execution address
        // mint実行アドレスに採番したtokenIDでmint実行
        _mint(msg.sender, tokenId);

        // Event firing of tokenID and signature information
        // tokenIDと 署名情報をイベント発火
        emit mintRecord(tokenId, jointedId);
    }

    /**
     * @dev
     * - Provides the ability to burn NFTs
     * - NFTをburnする機能を提供します。
     */
    function burn(uint256 tokenId) public virtual {
        require(
            _isApprovedOrOwner(msg.sender, tokenId) || _tokenIdtoMintedAddress[tokenId] == msg.sender,
            "ERC721: caller is not token owner or approved"
        );
        _isJointedIdMinted[_tokenIdtoJointedId[tokenId]] = 0;
        _tokenIdtoJointedId[tokenId] = "";
        _tokenIdtoMintedAddress[tokenId] = address(0);
        _burn(tokenId);
    }

    /// @dev Get message hash to sign
    /// 署名するメッセージのハッシュを取得します。
    function getMessageHash(
        string memory _jointedId
    ) private view returns (bytes32) {
        return keccak256(abi.encodePacked(msg.sender, _jointedId));
    }

    /// @dev Hash the ethereum signature message
    /// イーサリアム署名メッセージのハッシュ化を行います。
    function getEthSignedMessageHash(
        bytes32 _messageHash
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }

    /// @dev Returns the signature address
    /// 署名から署名されたアドレスを返します。
    function verifySignatureAddress(
        string memory _jointedId,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal view returns (address) {
        bytes32 messageHash = getMessageHash(_jointedId);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return ecrecover(ethSignedMessageHash, _v, _r, _s);
    }

    /**
     * @dev 
     * - Base URI for computing {tokenURI}. If set, the resulting URI for each
     * - Btoken will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * - Bby default, can be overridden in child contracts.
     * - tokenURIを計算するためのベースURI
     * - 各トークンのURIは`baseURI` と `tokenId` を連結したものになります。
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return __baseURI;
    }

    /**
     * @dev
     * - Only the contract owner can change the baseURI of the NFTURI
     * - NFTURIのbaseURIをコントラクトオーナーのみ変更可能です、
     */
    function setBaseURI(string calldata baseURI) external onlyOwner {
        __baseURI = baseURI;
    }

    /**
     * @dev
     * - get the baseURI of NFTURI
     * - NFTURIのbaseURIを取得できます。
     */
    function getBaseURI() external view returns (string memory) {
        return _baseURI();
    }

    /**
     * @dev
     * - Only the contract owner can change the address to be signed on the backend
     * - バックエンドで署名するアドレスはコントラクトオーナーのみ変更可能
     */
    function setSignatureAddress(address signatureAddress) external onlyOwner {
        _signatureAddress = signatureAddress;
    }

    /**
     * @dev
     * - You can get the minted address from tokenId.
     * - tokenIdからmintしたアドレスを取得できます。
     */
    function getMintedAddress(uint256 tokenId) external view returns (address) {
        return _tokenIdtoMintedAddress[tokenId];
    }

    /**
     * @dev
     * - It is possible to obtain whether jointedID(userID + SNSID) is minted or not.
     * - jointedID(userID + SNSID)がmintされているかどうか取得できます。
     */
    function isMintedJointedId(string calldata jointedId) public view returns (bool) {
        return _isJointedIdMinted[jointedId] != 0;
    }

    /**
     * @dev
     * - You can get tokenId from jointedID(userID + SNSID).
     * - jointedID(userID + SNSID)からtokenIdを取得できます。
     */
    function getMintedTokenId(string calldata jointedId) external view returns (uint256) {
        return _isJointedIdMinted[jointedId];
    }
}