// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./IUSDT.sol";

contract TONBridgeV2 is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    // ---------------------------------------------------

    IERC20 public _token;

    uint256 public _minlimit;

    // limited by "VarUInteger 16" (2**120 - 1)
    uint256 public constant _maxlimit = 1329227995784915872903807060280344575;

    uint256 public _feePercentage;
    uint256 public _feeAmount;
    uint256 public _feeBalance;

    mapping(address => SignerParams) public _signers;
    mapping(bytes32 => bool) public _hashes;

    IUSDT public _token_usdt;

    // ---------------------------------------------------

    struct ERCParams {
        address destination;
        bytes32 accountTON;
        bytes32 salt;
        bytes32 txhashTON;
        uint64 ltimeTON;
        uint256 amount;
        uint256 signts;
    }

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct SignerParams {
        bool exists;
        uint256 revokedFrom;
    }

    // ---------------------------------------------------

    event SwapToTONReq(
        address indexed from,
        bytes32 indexed accountTON,
        uint256 amount,
        uint256 mustCollectedFee
    );

    event SwappedToERC(
        bytes32 indexed hash,
        bytes32 indexed accountTON,
        address indexed destination,
        bytes32 salt,
        bytes32 txhashTON,
        uint64 ltimeTON,
        uint256 amount,
        uint256 signts,
        uint256 collectedFee
    );

    event NewSigner(address signer);
    event SignerRevoked(address signer);

    // ---------------------------------------------------

    modifier limitCheck(uint256 amount) {
        require(amount >= _minlimit, "amount must be >= _minlimit");
        require(amount <= _maxlimit, "amount must be >= _maxlimit");
        _;
    }

    function checkAllowed(ERCParams calldata req, Signature calldata sign)
        public
        view
        returns (bytes32)
    {
        bytes32 msghash = keccak256(
            abi.encodePacked(
                req.destination,
                req.accountTON,
                req.salt,
                req.txhashTON,
                req.ltimeTON,
                req.amount,
                req.signts
            )
        );

        require(_hashes[msghash] == false, "sign already executed");

        SignerParams memory signer = _signers[
            ECDSA.recover(ECDSA.toEthSignedMessageHash(msghash), sign.v, sign.r, sign.s)
        ];

        require(signer.exists == true, "invalid signer");
        require(req.signts < signer.revokedFrom || signer.revokedFrom == 0, "signed after revoke");

        return msghash;
    }

    function swapToERC(ERCParams calldata req, Signature calldata sign)
        external
        limitCheck(req.amount)
    {
        bytes32 msghash = checkAllowed(req, sign);
        require(_token_usdt.balanceOf(address(this)) >= req.amount, "insufficient token balance");

        uint256 fee = calculateFee(req.amount);
        _token_usdt.transfer(req.destination, req.amount - fee);
        _feeBalance += fee;

        _hashes[msghash] = true;

        emit SwappedToERC(
            msghash,
            req.accountTON,
            req.destination,
            req.salt,
            req.txhashTON,
            req.ltimeTON,
            req.amount,
            req.signts,
            fee
        );
    }

    function swapToTON(bytes32 accountTON, uint256 amount) external limitCheck(amount) {
        require(_token_usdt.balanceOf(msg.sender) >= amount, "insufficient token balance");

        require(
            _token_usdt.allowance(msg.sender, address(this)) >= amount,
            "allowance must be >= amount"
        );

        _token_usdt.transferFrom(msg.sender, address(this), amount);

        uint256 fee = calculateFee(amount);
        _feeBalance += fee;

        emit SwapToTONReq(msg.sender, accountTON, amount, fee);
    }

    function addSigner(address signer) external onlyOwner {
        require(_signers[signer].exists == false, "signer already exists");

        _signers[signer].exists = true;
        emit NewSigner(signer);
    }

    function revokeSigner(address signer) external onlyOwner {
        require(_signers[signer].exists == true, "signer not exists");

        _signers[signer].revokedFrom = block.timestamp;
        emit SignerRevoked(signer);
    }

    function setTokenAddress(address token_usdt) external onlyOwner {
        _token_usdt = IUSDT(token_usdt);
    }

    function _validateSettings(
        uint256 minlimit,
        uint256 feePercentage,
        uint256 feeAmount
    ) internal pure {
        uint256 fee = feeAmount + ((minlimit * feePercentage) / 10000);
        require(minlimit >= fee, "invalid settings");
    }

    function changeSettings(
        uint256 minlimit,
        uint256 feePercentage,
        uint256 feeAmount
    ) external onlyOwner {
        _validateSettings(minlimit, feePercentage, feeAmount);

        _minlimit = minlimit;
        _feePercentage = feePercentage;
        _feeAmount = feeAmount;
    }

    function withdrawFeesTo(address to, uint256 amount) external onlyOwner {
        require(_feeBalance >= amount, "insufficient fee balance");
        require(_token_usdt.balanceOf(address(this)) >= amount, "insufficient token balance");

        _token_usdt.transfer(to, amount);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function calculateFee(uint256 amount) public view returns (uint256) {
        return _feeAmount + ((amount * _feePercentage) / 10000);
    }
}