// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../utils/Percentage.sol";
import "../tokens/Zogi.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

contract ConversionV4 is OwnableUpgradeable,PausableUpgradeable,ReentrancyGuardUpgradeable,Percentage{
    
    uint256 public minWrapAmount;
    uint256 public circulatingZogi;
    bool private initialized;

    IERC20 public bezoge;
    ZOGI public zogi;

    mapping(address => bool) private authorizedSigners;
    mapping(bytes => bool) public usedSignatures;

    using ECDSAUpgradeable for bytes32;

    uint256 public bezogeWithdrawn;

    event WrapBezoge(address indexed owner, uint256 amount, uint256 zogi);
    event UnwrapBezoge(address indexed owner, uint256 amount, uint256 bezoge);
    event adminWithDraw(address indexed owner);

    function init(address bezogeToken_, address zogiToken_, uint256 minWrapAmount_,
        uint256 percentageDecimals_) external initializer
    {
        require(!initialized);

        bezoge = IERC20(bezogeToken_);
        zogi = ZOGI(zogiToken_);
        minWrapAmount = minWrapAmount_;

        __Percentage_init(percentageDecimals_);
        __Ownable_init();
        __Pausable_init();

        initialized = true;
    }

    function wrapBezoge(uint256 amount_,bytes memory signature_) external whenNotPaused nonReentrant{
     
        require(amount_ >= minWrapAmount, "Can not convert less than min limit");
        require(usedSignatures[signature_] != true, "Signature is already being used");

        bytes32 msgHash = keccak256(abi.encodePacked(msg.sender, amount_));

        bytes32 prefixedHash = msgHash.toEthSignedMessageHash();
        address msgSigner = recover(prefixedHash, signature_);
        require(authorizedSigners[msgSigner], "Invalid Signer");
        
        usedSignatures[signature_] = true;
        _wrapBezoge(amount_);
    }

    function wrapBezogeAdmin(uint256 amount_) external nonReentrant onlyOwner{
         _wrapBezoge(amount_);
    }

    function _wrapBezoge(uint256 amount_) private{
        uint256 receivedBezoge = calculateValueOfPercentage(calculatePercentage(98, 100), amount_);
        uint256 zogiAmount = receivedBezoge;
        uint256 initialBezogeBalance = 17273297743223100000000000;
        initialBezogeBalance += 1456001298887175608825401 + 988598380440304798962556;

        if (circulatingZogi > 0 ){
            zogiAmount = receivedBezoge * (circulatingZogi) / (initialBezogeBalance + bezogeWithdrawn + bezoge.balanceOf(address(this)));
        }
 
        circulatingZogi += zogiAmount;

        bezoge.transferFrom(msg.sender, address(this), amount_);
        zogi.mint(msg.sender, zogiAmount);
        emit WrapBezoge(msg.sender, amount_, zogiAmount);
    }

    // admin function to withdraw all bezoge tokens
    function adminWithdraw(address withdrawAddr)external onlyOwner{
        bezogeWithdrawn += bezoge.balanceOf(address(this));
        require(bezoge.transfer(withdrawAddr, bezoge.balanceOf(address(this))), "Transfer failed");
        emit adminWithDraw(withdrawAddr);
    }

    function updateMinWrapAmount(uint256 minAmount_) external onlyOwner{
        minWrapAmount = minAmount_;
    }
    
    function renounceOwnership() public view override onlyOwner {
        revert("can't renounceOwnership here");
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function updateSignerStatus(address signer, bool status) external onlyOwner {
        authorizedSigners[signer] = status; 
    }

    function isSigner(address signer) external view returns (bool) {
        return authorizedSigners[signer];
    }

    function recover(bytes32 hash, bytes memory signature_) private pure returns(address) {
        return hash.recover(signature_);
    }
}