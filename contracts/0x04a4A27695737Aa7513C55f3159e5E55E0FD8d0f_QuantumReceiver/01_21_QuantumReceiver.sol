// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";


contract QuantumReceiver is Initializable, ContextUpgradeable, AccessControlUpgradeable, OwnableUpgradeable, UUPSUpgradeable {

    mapping(bytes => bool) public usedSignatures;
    address public signer;
    address public withdrawAddress;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    event ClaimReceived(uint256 awrd_id, uint256 badge_id, uint256 request_id);


    // constructor() {
    //     _disableInitializers();
    // }
    function initialize() public initializer{
        __Ownable_init();
        __UUPSUpgradeable_init();
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, 0x0a3C1bA258c0E899CF3fdD2505875e6Cc65928a8);
        _setupRole(ADMIN_ROLE, 0xE42E4F21A750C1cC1ba839E5B1e4EfC3eD1fe454);
        _setupRole(ADMIN_ROLE, 0x0a3C1bA258c0E899CF3fdD2505875e6Cc65928a8);
        signer = 0xC5036638e53064CEa6d6508e7006c483d9F1Ce2C;
        withdrawAddress = 0x72B1202c820e4B2F8ac9573188B638866C7D9274;


    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(ADMIN_ROLE) {}

    function claim(
        uint256 awrd_id,
        uint256 badge_id,
        address seller,
        uint256 price,
        address token_address,
        uint256 request_id,
        uint256 platform_fee,
        bytes memory signature
    ) public {
        bool isValid = isValidSignature(
            awrd_id,
            badge_id,
            seller,
            price,
            token_address,
            request_id,
            platform_fee,
            signature
        );

        require(isValid, "Invalid signature");
        require(!usedSignatures[signature], "Signature already used");

        usedSignatures[signature] = true;

        bool success = IERC20(token_address).transferFrom(msg.sender, seller, price);
        require(success, "Transfer failed");
        if(platform_fee > 0){
            bool feeSuccess = IERC20(token_address).transferFrom(msg.sender, withdrawAddress, platform_fee);
            require(feeSuccess, "Fee transfer failed");
        }

        emit ClaimReceived(awrd_id, badge_id, request_id);
    }


    function getMessageHash(
        uint256 awrd_id,
        uint256 badge_id,
        address seller,
        uint256 price,
        address token_address,
        uint256 request_id,
        uint256 platform_fee
    ) public view returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                awrd_id,
                badge_id,
                seller,
                price,
                token_address,
                block.chainid,
                request_id,
                platform_fee
            )
        );
    }

    function isValidSignature(
        uint256 awrd_id,
        uint256 badge_id,
        address seller,
        uint256 price,
        address token_address,
        uint256 request_id,
        uint256 platform_fee,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 message = getMessageHash(
        awrd_id,
        badge_id,
        seller,
        price,
        token_address,
        request_id,
        platform_fee
        );
        bytes32 messageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", message)
        );
        return SignatureChecker.isValidSignatureNow(signer, messageHash, signature);
    }

    function recoverERC20(address tokenAddress) public onlyRole(ADMIN_ROLE) {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        bool success = token.transfer(withdrawAddress, balance);
        require(success, "Transfer failed");
    }

    function recoverETH() public {
        uint256 balance = address(this).balance;
        (bool success, ) = withdrawAddress.call{value: balance}("");
        require(success, "Transfer failed");
    }    

    function setSigner(address _signer) public onlyRole(ADMIN_ROLE) {
        signer = _signer;
    }

    function setWithdrawAddress(address _withdrawAddress) public onlyRole(ADMIN_ROLE) {
        withdrawAddress = _withdrawAddress;
    }
}