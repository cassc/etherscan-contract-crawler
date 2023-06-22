// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract BootyClaim is Initializable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    error InvalidSignature();
    error TokenNotSupported();
    error InvalidAmount();
    error ExceedMaxWithdrawlAmt();

    event Withdrawal(
        address indexed user, address indexed token, uint256 amount, uint256 userTotalWithdrawn, uint256 userMaxAmount
    );

    mapping(address => bool) public supportedTokens;
    mapping(address => mapping(address => uint256)) public totalWithdrawn;
    address public signer;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _signer) public initializer {
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        OwnableUpgradeable.__Ownable_init();
        signer = _signer;
    }

    function checkValidity(bytes calldata _signature, string memory _action) public view returns (bool) {
        if (
            ECDSA.recover(ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(msg.sender, _action))), _signature)
                != signer
        ) revert InvalidSignature();
        return true;
    }

    function withdraw(address _tokenAddress, uint256 _amount, uint256 _maxAmount, bytes calldata signature)
        external
        nonReentrant
    {
        if (!supportedTokens[_tokenAddress]) revert TokenNotSupported();
        if (_amount > _maxAmount) revert InvalidAmount();

        string memory action = string.concat(
            "booty-claim_", Strings.toHexString(uint160(_tokenAddress), 20), "_", Strings.toString(_maxAmount)
        );
        checkValidity(signature, action);

        if (totalWithdrawn[msg.sender][_tokenAddress] + _amount > _maxAmount) revert ExceedMaxWithdrawlAmt();

        totalWithdrawn[msg.sender][_tokenAddress] += _amount;
        IERC20(_tokenAddress).safeTransfer(msg.sender, _amount);

        emit Withdrawal(msg.sender, _tokenAddress, _amount, totalWithdrawn[msg.sender][_tokenAddress], _maxAmount);
    }

    function addSupportedToken(address _tokenAddress) external onlyOwner {
        supportedTokens[_tokenAddress] = true;
    }

    function removeSupportedToken(address _tokenAddress) external onlyOwner {
        supportedTokens[_tokenAddress] = false;
    }

    function setSigner(address _newSigner) external onlyOwner {
        signer = _newSigner;
    }

    function getTokensBalance(address[] calldata _tokens) external view returns (uint256[] memory) {
        uint256[] memory tokensBalance = new uint256[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length;) {
            tokensBalance[i] = IERC20(_tokens[i]).balanceOf(address(this));
            unchecked {
                ++i;
            }
        }
        return tokensBalance;
    }
}