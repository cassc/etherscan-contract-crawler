// SPDX-License-Identifier: MIT

// AUDIT: LCL-06 | UNLOCKED COMPILER VERSION
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";


/**
 * @title Intermediator Contract
 * @author Harry Liu.
 */
contract TokenIntermediator is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable{
 
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;


    event Transfer(
        address user, 
        address recipient,
        uint256 amount
    );

    event Claim(
        address user, 
        uint256 amount
    );

    /// @notice Information about user's vest option.
    struct Term {
        address user;
        string types;
        uint256 amount;
    }

    /// @notice Mapping for terms for user.
    mapping(address => Term[]) private claims;

    mapping(address => Term[]) private transfers;

    mapping(address => uint256) public claimable;

    mapping(address => uint256) public claimIndex;

    /// @notice ERC20 based yielding token.
    IERC20Upgradeable private _daoToken;

    function initialize(
        address daoToken_
    ) external initializer {
         __Ownable_init();
         __ReentrancyGuard_init();
         _daoToken = IERC20Upgradeable(daoToken_);
    }

    function getTransfers(address _user) external view returns(Term[] memory) {
        return transfers[_user];
    }
    
    function getClaims(address _user) external view returns(Term[] memory) {
        return claims[_user];
    }

    function transfer(
        address _recipient,
        uint256 _amount
    ) external nonReentrant {
        require(!_recipient.isContract(), "Invalid recipient");
        require(tx.origin == msg.sender, "Caller is SC");
        
        transfers[msg.sender].push(Term(
            _recipient,
            "transfer",
            _amount
        ));

        claims[_recipient].push(Term(
            msg.sender,
            "claim",
            _amount
        ));

        claimable[_recipient] += _amount;

        _daoToken.safeTransferFrom(msg.sender, address(this), _amount);

        emit Transfer(msg.sender, _recipient, _amount);
    }

    function claim() external nonReentrant {
        require(tx.origin == msg.sender, "Caller is SC");
        require(claimable[msg.sender] > 0, "No token to claim");

        uint256 amount = claimable[msg.sender];
        
        claimable[msg.sender] = 0;

        claimIndex[msg.sender] = claims[msg.sender].length;
        
        _daoToken.safeTransfer(msg.sender, amount);

        emit Claim(msg.sender, amount);
    }

}