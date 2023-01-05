// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CampaignGoFuckYourself is Ownable {
    // ========================================
    //     EVENT & ERROR DEFINITIONS
    // ========================================

    error TransferFailed();
    error InvalidSignature();
    error NoPermissionToExecute();
    error NotEnoughCollateral();
    error NotEnoughSupplyToBorrow();
    error ExpiredPrice();
    error ExpiredTime();
    error ContractsNotAllowed();

    // ========================================
    //     VARIABLE DEFINITIONS
    // ========================================

    struct SignatureContent {
        uint256 nonce;
        uint256 amount;
        uint256 price;
        uint40 timestamp;
        address token;
    }

    address public SIGNER;
    bytes32 internal constant SIG_TYPEHASH =
        keccak256(
            "SignatureContent(uint256 nonce,uint256 amount,uint256 price,uint40 timestamp,address token)"
        );
    mapping(address => address) public supportedTokens;
    mapping(bytes32 => bool) public revokedSignatures;

    // ========================================
    //    CONSTRUCTOR AND CORE FUNCTIONS
    // ========================================

    constructor(
        address _token,
        address _tokenOwner,
        address _signer
    ) {
        supportedTokens[_token] = _tokenOwner;
        SIGNER = _signer;
    }

    function burnToken(
        SignatureContent calldata _content,
        bytes calldata _signature
    ) external payable {
        require(supportedTokens[_content.token] != address(0), "Invalid Token");
        require(
            IERC20(_content.token).balanceOf(address(this)) >=
                _content.amount &&
                _content.amount > 0,
            "Not enough balance"
        );
        signatureCheck(_content, _signature);
        require(msg.value >= _content.price, "Invalid Amount");

        IERC20(_content.token).transfer(
            0x000000000000000000000000000000000000dEaD,
            _content.amount
        );
    }

    // ========================================
    //     SIGNATURE FUNCTIONS
    // ========================================

    function revokeSignature(bytes32 _hash) internal {
        if (revokedSignatures[_hash] == true) revert InvalidSignature();
        revokedSignatures[_hash] = true;
    }

    function _eip712DomainSeparator() private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,address verifyingContract)"
                    ),
                    keccak256(bytes("CampaignGoFuckYourself")),
                    keccak256(bytes("1.0")),
                    address(this)
                )
            );
    }

    function getMessageHash(SignatureContent memory _content)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    SIG_TYPEHASH,
                    _content.nonce,
                    _content.amount,
                    _content.price,
                    _content.timestamp,
                    _content.token
                )
            );
    }

    function getEthSignedMessageHash(SignatureContent calldata _content)
        public
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    _eip712DomainSeparator(),
                    getMessageHash(_content)
                )
            );
    }

    function validateSignature(uint40 _expiration, bytes32 _hash) public view {
        if (block.timestamp >= _expiration) revert ExpiredTime();
        if (revokedSignatures[_hash] != false) revert InvalidSignature();
    }

    function signatureCheck(
        SignatureContent calldata _content,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(_content);
        validateSignature(_content.timestamp, ethSignedMessageHash);
        return recoverSigner(ethSignedMessageHash, signature) == SIGNER;
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
    }

    // ========================================
    //     ADMIN FUNCTIONS
    // ========================================

    function addOrRemoveToken(address _token, address _tokenOwner)
        public
        onlyOwner
    {
        supportedTokens[_token] = _tokenOwner;
    }

    function withdrawETH() external onlyOwner {
        bool success;
        (success, ) = address(msg.sender).call{value: address(this).balance}(
            ""
        );
    }

    function withdrawTokens(address _token) external {
        require(_token != address(this), "Cannot withdraw this token");
        require(supportedTokens[_token] == msg.sender, "Not Token Owner");
        require(IERC20(_token).balanceOf(address(this)) > 0, "No tokens");
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(msg.sender, amount);
    }

    function setSigner(address _signer) external onlyOwner {
        SIGNER = _signer;
    }
}