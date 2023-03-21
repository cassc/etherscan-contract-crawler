// SPDX-License-Identifier: MIT
// Sidus Cards
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract XennaItems is ERC1155Supply, Ownable {
    using Strings for uint256;
    using Strings for uint160;
    using ECDSA for bytes32;

    struct TokenReq {
        uint256 stopMintAfter; // for mint with erc20
        uint256 maxTotalSupply;
    }
    string public name;
    string public symbol;
    string public baseurl;
    address public externalWhiteList;
    address public beneficiary;
    address public externalShadow;

    mapping(uint256 => TokenReq) public tokenReq;
    mapping(address => mapping(uint256 => uint256)) public tokensForMint;
    mapping(address => uint) public nonce;
    mapping(address => bool) public trustedSigner;
    //Event for track mint channel:
    // 0 - With Shadow
    // 2 - With Ethere
    // 3 - External White List
    // 4 - With ERC20
    event MintSource(uint256 tokenId, uint256 amount, uint8 channel);

    constructor(
        string memory name_,
        string memory symbol_,
        string memory _baseurl
    ) ERC1155(_baseurl) {
        baseurl = string(
            abi.encodePacked(
                _baseurl,
                "/",
                uint160(address(this)).toHexString(),
                "/"
            )
        );
        _setURI(baseurl);
        name = name_;
        symbol = symbol_;
    }

    /// @param _tokenID id of token(array)
    /// @param _nftAmountForMint amount(array)
    /// @param _nonce nonce
    /// @param _msgForSign prepared data for sign
    /// @param _signature signatire
    function mintFromShadowBatch(
        uint256[] memory _tokenID,
        uint256[] memory _nftAmountForMint,
        uint _nonce,
        bytes32 _msgForSign,
        bytes memory _signature
    ) public {
        for (uint i = 0; i < _tokenID.length; i++) {
            require(
                tokenReq[_tokenID[i]].stopMintAfter >=
                    totalSupply(_tokenID[i]) + _nftAmountForMint[i],
                "Minting is paused"
            );
        }
        require(nonce[msg.sender] == _nonce, "nonce error");
        //1. Lets check signer
        address signedBy = _msgForSign.recover(_signature);
        require(trustedSigner[signedBy], "signature check failed");
        bytes32 actualMsg = getMsgForSignBatch(
            _tokenID,
            _nftAmountForMint,
            _nonce,
            msg.sender
        );
        require(
            actualMsg.toEthSignedMessageHash() == _msgForSign,
            "integrety check failed"
        );

        nonce[msg.sender]++;
        _mintBatch(msg.sender, _tokenID, _nftAmountForMint, bytes("0"));
    }

    /// @param _tokenID id of token
    /// @param _nftAmountForMint amount
    /// @param _nonce nonce
    /// @param _msgForSign prepared data for sign
    /// @param _signature signatire
    function mintFromShadow(
        uint256 _tokenID,
        uint256 _nftAmountForMint,
        uint _nonce,
        bytes32 _msgForSign,
        bytes memory _signature
    ) external {
        require(
            tokenReq[_tokenID].stopMintAfter >=
                totalSupply(_tokenID) + _nftAmountForMint,
            "Minting is paused"
        );
        //Double spend check
        require(nonce[msg.sender] == _nonce, "nonce error");

        address signedBy = _msgForSign.recover(_signature);
        require(trustedSigner[signedBy], "signature check failed");
        bytes32 actualMsg = getMsgForSign(
            _tokenID,
            _nftAmountForMint,
            _nonce,
            msg.sender
        );
        require(
            actualMsg.toEthSignedMessageHash() == _msgForSign,
            "integrety check failed"
        );

        nonce[msg.sender]++;
        _multiMint(msg.sender, _nftAmountForMint, _tokenID, 0);
    }

    /// @param _withToken address of token
    /// @param _tokenID id of token
    /// @param _nftAmountForMint amount of token
    function mintWithERC20(
        address _withToken,
        uint256 _tokenID,
        uint256 _nftAmountForMint
    ) external {
        require(totalSupply(_tokenID) > 0, "Only minted NFT");
        require(
            tokensForMint[_withToken][_tokenID] > 0,
            "No mint with this token"
        );
        require(
            tokenReq[_tokenID].stopMintAfter >=
                totalSupply(_tokenID) + _nftAmountForMint,
            "Minting is paused"
        );
        IERC20(_withToken).transferFrom(
            msg.sender,
            beneficiary,
            tokensForMint[_withToken][_tokenID] * _nftAmountForMint
        );
        _multiMint(msg.sender, _nftAmountForMint, _tokenID, 4);
    }

    /// @param account address of account
    /// @param _tokenID id of token
    /// @param amount amount for burn
    function burn(address account, uint256 _tokenID, uint256 amount) external {
        require(
            account == msg.sender || isApprovedForAll(account, msg.sender),
            "ERC1155: caller is not owner nor approved"
        );
        _burn(account, _tokenID, amount);
    }

    /// @param _id id of token
    function getTokenDetails(
        uint256 _id
    ) external view returns (TokenReq memory) {
        return tokenReq[_id];
    }

    /// @notice only owner can call this function
    /// @param _signer address of signer
    /// @param _signer true, if you want turn on signer
    function setTrustedSigner(
        address _signer,
        bool _isValid
    ) external onlyOwner {
        trustedSigner[_signer] = _isValid;
    }

    /// @notice only owner can call this function
    /// @param _wl address of contract, which has whitelist functionality
    function setWhiteList(address _wl) external onlyOwner {
        externalWhiteList = _wl;
    }

    /// @notice only owner can call this function
    /// @param id id of token
    /// @param _maxSupply max count of tokens
    function setMaxTotalSupply(
        uint256 id,
        uint256 _maxSupply
    ) external onlyOwner {
        tokenReq[id].maxTotalSupply = _maxSupply;
    }

    /// @notice only owner can call this function
    /// @param id id of token
    /// @param _stopMinter after this timestamp, users cant mint
    function setStopMinterAfter(
        uint256 id,
        uint256 _stopMinter
    ) external onlyOwner {
        tokenReq[id].stopMintAfter = _stopMinter;
    }

    /// @notice only owner can call this function
    /// @param _token address of token
    /// @param _tokenId id of token
    /// @param _pricePerMint price
    function setPriceInToken(
        address _token,
        uint256 _tokenId,
        uint256 _pricePerMint
    ) external onlyOwner {
        require(_token != address(0), "No zero");
        tokensForMint[_token][_tokenId] = _pricePerMint;
    }

    /// @notice only owner can call this function
    /// @param account address of account
    /// @param id id of token
    /// @param amount amount
    /// @param _stopMintAfter after this timestamp, user cant mint
    /// @param _maxTotalSupply max count of tokens
    function createNew(
        address account,
        uint256 id,
        uint256 amount,
        uint256 _stopMintAfter,
        uint256 _maxTotalSupply
    ) external onlyOwner {
        _mint(account, id, amount, bytes("0"));
        _editTokenReq(id, _stopMintAfter, _maxTotalSupply);
    }

    /// @notice only owner can call this function
    /// @param account address of account
    /// @param ids array of ids
    /// @param amounts array of amounts
    /// @param _stopMintAfter array of timestamps
    /// @param _maxTotalSupply array of max counts of tokens
    function createNewBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts,
        uint256[] memory _stopMintAfter,
        uint256[] memory _maxTotalSupply
    ) external onlyOwner {
        require(
            ids.length == _stopMintAfter.length,
            "stopMintAfter params must have equal length"
        );
        require(
            ids.length == _maxTotalSupply.length,
            "maxTotalSupply params must have equal length"
        );
        _mintBatch(account, ids, amounts, bytes("0"));

        for (uint256 i = 0; i < ids.length; i++) {
            _editTokenReq(ids[i], _stopMintAfter[i], _maxTotalSupply[i]);
        }
    }

    /// @notice only owner can call this function
    /// @param id id of token
    /// @param _stopMintAfter after this timestamp, users cant mint
    /// #param _maxTotalSupply max count of tokens
    function editTokenReq(
        uint256 id,
        uint256 _stopMintAfter,
        uint256 _maxTotalSupply
    ) external onlyOwner {
        _editTokenReq(id, _stopMintAfter, _maxTotalSupply);
    }

    /// @notice only owner can call this function
    /// @param _beneficiary address of beneficiary
    function setBeneficiary(address _beneficiary) external onlyOwner {
        require(_beneficiary != address(0), "No zero addess");
        beneficiary = _beneficiary;
    }

    ///////////////////////////////////////////////////////////////////
    /////  INTERNALS      /////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////

    function _editTokenReq(
        uint256 _id,
        uint256 _stopMintAfter,
        uint256 _maxTotalSupply
    ) internal {
        tokenReq[_id].stopMintAfter = _stopMintAfter;
        tokenReq[_id].maxTotalSupply = _maxTotalSupply;
    }

    function _multiMint(
        address to,
        uint256 amount,
        uint256 tokenID,
        uint8 channel
    ) internal {
        require(
            totalSupply(tokenID) + amount <= tokenReq[tokenID].maxTotalSupply,
            "No more this tokens"
        );
        _mint(to, tokenID, amount, bytes("0"));
        emit MintSource(tokenID, amount, channel);
    }

    function uri(
        uint256 _tokenID
    ) public view override returns (string memory _uri) {
        _uri = string(abi.encodePacked(ERC1155.uri(0), _tokenID.toString()));
    }

    function getMsgForSign(
        uint _tokenId,
        uint _amount,
        uint _nonce,
        address _sender
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(_tokenId, _amount, _nonce, _sender));
    }

    function getMsgForSignBatch(
        uint[] memory _tokenId,
        uint[] memory _amount,
        uint _nonce,
        address _sender
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(_tokenId, _amount, _nonce, _sender));
    }
}