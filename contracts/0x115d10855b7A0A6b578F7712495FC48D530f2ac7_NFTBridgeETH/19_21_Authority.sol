// SPDX-License-Identifier: none
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract AccessControlled is Initializable {  
    using SafeERC20Upgradeable for IERC20Upgradeable;  
    IAuthority public authority;
    
    function __AccessControlled_init(IAuthority _authority) internal onlyInitializing {
        __AccessControlled_init_unchained(_authority);
    }

    function __AccessControlled_init_unchained(IAuthority _authority) internal onlyInitializing {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }
   
    modifier onlyOperator() {
        require(msg.sender == authority.operator(), "Operator!");
        _;
    }

    modifier onlyMinter() {
        require(authority.minters(msg.sender), "Minter!");
        _;
    }

    modifier onlyNftMinter() {
        require(authority.nftMinters(msg.sender), "NftMinter!");
        _;
    }

    function setAuthority(IAuthority _newAuthority) external onlyOperator {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }

    function recover(
		address token_,
		uint256 amount_,
		address recipient_,
        bool nft
	) external onlyOperator {
        if (nft) {
            IERC721Upgradeable(token_).safeTransferFrom(address(this), recipient_, amount_);
        } else if (token_ != address(0)) {
			IERC20Upgradeable(token_).safeTransfer(recipient_, amount_);
		} else {
			(bool success, ) = recipient_.call{ value: amount_ }("");
			require(success, "Can't send ETH");
		}
		emit Recover(token_, amount_, recipient_, nft);		
	}

    event AuthorityUpdated(IAuthority indexed authority);
    event Recover(address token, uint256 amount, address recipient, bool nft);
}

interface IAuthority {
    function operator() external view returns (address);
    function minters(address account) external view returns (bool);
    function nftMinters(address account) external view returns (bool);
    
    event OperatorSet(address indexed from, address indexed to);  
    event MinterSet(address indexed account, bool state);  
    event NftMinterSet(address indexed account, bool state);  
}

contract Authority is Initializable, IAuthority, AccessControlled {
	address public override operator;
    mapping(address => bool) public override minters; 
    address[] public mintersList;

    mapping(address => bool) public override nftMinters; 
    address[] public nftMintersList;

    function initialize(
        address operator_
    ) public initializer {
        __AccessControlled_init(IAuthority(address(this)));
        emit OperatorSet(operator, operator_);
		operator = operator_;
    }
	
	function setOperator(address operator_) public onlyOperator {		
		operator = operator_;
        emit OperatorSet(operator, operator_);
	}	

    function setMinter(address minter_, bool state_) public onlyOperator {		
		minters[minter_] = state_;
        if (state_) {
            mintersList.push(minter_);
        } else {
            for (uint256 i = 0; i < mintersList.length; i++) {
                if (mintersList[i] == minter_) {
                    mintersList[i] = mintersList[mintersList.length - 1];
                    mintersList.pop();
                    break;
                }
            }            
        }
        emit MinterSet(minter_, state_);
	}

    function mintersCount() public view returns (uint256) {
        return mintersList.length;
    }

    function setNftMinter(address minter_, bool state_) public onlyOperator {		
		nftMinters[minter_] = state_;
        if (state_) {
            nftMintersList.push(minter_);
        } else {
            for (uint256 i = 0; i < nftMintersList.length; i++) {
                if (nftMintersList[i] == minter_) {
                    nftMintersList[i] = nftMintersList[nftMintersList.length - 1];
                    nftMintersList.pop();
                    break;
                }
            }            
        }
        emit NftMinterSet(minter_, state_);
	}

    function nftMintersCount() public view returns (uint256) {
        return nftMintersList.length;
    }
}