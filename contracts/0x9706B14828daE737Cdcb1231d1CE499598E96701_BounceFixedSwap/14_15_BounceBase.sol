// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract BounceBase is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using ECDSAUpgradeable for bytes32;
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    enum PoolType {
        FixedSwap,
        DutchAuction,
        SealedBid,
        Lottery,
        FixedSwapNFT,
        EnglishAuctionNFT,
        LotteryNFT
    }

    uint256 public constant TX_FEE_DENOMINATOR = 1e18;

    uint256 public txFeeRatio;
    address public stakeContract;
    address public signer;
    // pool index => whitelist merkle root
    mapping(uint256 => bytes32) public whitelistRootP;
    // address => pool message => pool message used or not
    mapping(address => mapping(bytes32 => bool)) public poolMessages;

    // solhint-disable-next-line func-name-mixedcase
    function __BounceBase_init(uint256 _txFeeRatio, address _stakeContract, address _signer) internal onlyInitializing {
        super.__Ownable_init();
        super.__ReentrancyGuard_init();

        _setTxFeeRatio(_txFeeRatio);
        _setStakeContract(_stakeContract);
        _setSigner(_signer);
    }

    function transferAndCheck(address token0, address from, uint256 amount) internal {
        IERC20Upgradeable _token0 = IERC20Upgradeable(token0);
        uint256 token0BalanceBefore = _token0.balanceOf(address(this));
        _token0.safeTransferFrom(from, address(this), amount);
        require(_token0.balanceOf(address(this)).sub(token0BalanceBefore) == amount, "not support deflationary token");
    }

    function checkWhitelist(uint256 index, bytes32[] memory proof) internal view {
        if (whitelistRootP[index] != bytes32(0)) {
            bytes32 leaf = keccak256(abi.encode(msg.sender));
            require(MerkleProofUpgradeable.verify(proof, whitelistRootP[index], leaf), "not whitelisted");
        }
    }

    function checkCreator(bytes32 hash, uint256 expireAt, bytes memory signature) internal {
        require(block.timestamp < expireAt, "signature expired");
        bytes32 message = keccak256(abi.encode(msg.sender, hash, block.chainid, expireAt));
        bytes32 hashMessage = message.toEthSignedMessageHash();
        require(signer == hashMessage.recover(signature), "invalid signature");
        require(!poolMessages[msg.sender][message], "pool message used");
        poolMessages[msg.sender][message] = true;
    }

    function setTxFeeRatio(uint256 _txFeeRatio) external onlyOwner {
        _setTxFeeRatio(_txFeeRatio);
    }

    function setStakeContract(address _stakeContract) external onlyOwner {
        _setStakeContract(_stakeContract);
    }

    function setSigner(address _signer) external onlyOwner {
        _setSigner(_signer);
    }

    function _setTxFeeRatio(uint256 _txFeeRatio) private {
        require(_txFeeRatio <= TX_FEE_DENOMINATOR, "invalid txFeeRatio");
        txFeeRatio = _txFeeRatio;
    }

    function _setStakeContract(address _stakeContract) private {
        require(_stakeContract != address(0), "invalid stakeContract");
        stakeContract = _stakeContract;
    }

    function _setSigner(address _signer) private {
        require(_signer != address(0), "invalid signer");
        signer = _signer;
    }

    uint256[45] private __gap;
}