// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IFireCatNFTUpgradeStorage} from "./interfaces/IFireCatNFTUpgradeStorage.sol";

/**
 * @title FireCat's FireCatNFTUpgradeProxy contract
 * @notice main: isQualified
 * @author FireCat Finance
 */
contract FireCatNFTUpgradeProxy {
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    address private _owner; // Ownable
    
    address public fireCatProxy;
    address public upgradeProxy;
    address public upgradeStorage;
    string public baseURI;
    uint256 public currentTokenId;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    uint256 private _totalSupply;
    mapping(uint256 => uint256) private _tokenLevel;
    mapping(address => uint256) private _ownerTokenId;
    mapping(address => bool) private _hasMinted;
    uint256 private _highestLevel;
    uint256 private _supplyLimit;

    /**
    * @notice check user's upgrade qualified.
    * @dev access total from upgradeStorage
    * @param tokenId address.
    * @return bool
    */
    function isQualified(uint256 tokenId) external returns (bool) {
        if (IFireCatNFTUpgradeStorage(upgradeStorage).isStakeQualified(tokenId, _tokenLevel[tokenId])) {
            address levelUpPayToken = IFireCatNFTUpgradeStorage(upgradeStorage).levelUpPayToken();
            uint256 payNum = IFireCatNFTUpgradeStorage(upgradeStorage).levelUpRequirePay(_tokenLevel[tokenId]);

            uint balanceBefore = IERC20(levelUpPayToken).balanceOf(address(msg.sender));
            IERC20(levelUpPayToken).transferFrom(msg.sender, address(1), payNum);
            bool success;
            assembly {
                switch returndatasize()
                    case 0 {                       // This is a non-standard ERC-20
                        success := not(0)          // set success to true
                    }
                    case 32 {                      // This is a compliant ERC-20
                        returndatacopy(0, 0, 32)
                        success := mload(0)        // Set `success = returndata` of external call
                    }
                    default {                      // This is an excessively non-compliant ERC-20, revert.
                        revert(0, 0)
                    }
            }
            require(success, "TOKEN_TRANSFER_IN_FAILED");
            uint balanceAfter = IERC20(levelUpPayToken).balanceOf(address(msg.sender));
            require(balanceAfter <= balanceBefore, "TOKEN_TRANSFER_IN_OVERFLOW");
            return true;
        }

        return false;
    }
}