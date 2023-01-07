// SPDX-License-Identifier: MIT

/**
* Author: Goku153

*/
pragma solidity ^0.8.0;
import "erc721a/contracts/IERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Staking is Ownable {
    /**
     * @dev A structure representing the data being stored for a staking pass.
     * It contains several pieces of information:
     * - owner            : The address of the owner who staked the pass
     * - beneficiary      : The beneficiary address that the owner want to use to access the platform from
     */
    struct StakeData {
        address owner;
        address beneficiary;
    }

    /**
     * @dev A structure representing the data being required  as a paramter for  staking a pass.
     * It contains several pieces of information:
     * - owner            : The address of the owner who staked the pass
     * - beneficiary      : The beneficiary address that the owner want to use to access the platform from
     */
    struct StakeParam {
        uint256 tokenId;
        address beneficiary;
    }

    IERC721A public collection;
    uint public totalStakedTokens;

    // Mapping of benefits balance for  addresses
    mapping(address => uint256) public benefitBalance;

    // Mapping of tokens staked by an owner address
    mapping(address => uint256[]) public tokensOwned;

    // Mapping of data stored for a token
    mapping(uint256 => StakeData) public tokenStaked;

    constructor(address collectionAddress_) {
        collection = IERC721A(collectionAddress_);
    }

    /**
     * @dev Set the collection that will be used for staking
     *
     * @param collectionAddress_ : the address of the contract you want to use for staking
     */
    function setCollection(address collectionAddress_) public onlyOwner {
        collection = IERC721A(collectionAddress_);
    }

    /**
     * @dev Internal function that stakes a pass
     *
     * @param tokenId_ : the tokenId of the pass being staked
     * @param beneficiary_ : the beneficiary address that would reap the benefits
     */
    function _stakeToken(uint256 tokenId_, address beneficiary_) internal {
        tokensOwned[msg.sender].push(tokenId_);
        tokenStaked[tokenId_] = StakeData(msg.sender, beneficiary_);
        if (beneficiary_ != address(0) && beneficiary_ != msg.sender) {
            benefitBalance[beneficiary_]++;
        }

        try collection.transferFrom(msg.sender, address(this), tokenId_) {
            totalStakedTokens++;
        } catch Error(string memory _err_) {
            revert(_err_);
        }
    }

    /**
     * @dev Stakes a single pass and verify the ownership
     *
     * @param tokenId_ : the tokenId of the pass being staked
     * @param beneficiary_ : the beneficiary address that would reap the benefits
     */
    function stakeToken(uint256 tokenId_, address beneficiary_) external {
        // revert conditions
        try collection.ownerOf(tokenId_) returns (address _owner_) {
            require(_owner_ == msg.sender, "Token is not owned by sender");
            _stakeToken(tokenId_, beneficiary_);
        } catch Error(string memory _err_) {
            revert(_err_);
        }
    }

    /**
     * @dev Stakes a batch of passes and verify the ownership
     *
     * @param stakeParams_ : the stake data for the list of tokens containing beneficiary and tokenId
     */
    function batchStakeTokens(StakeParam[] calldata stakeParams_) external {
        unchecked {
            uint _len_ = stakeParams_.length;
            uint _index_ = 0;
            while (_index_ < _len_) {
                uint256 _tokenId_ = stakeParams_[_index_].tokenId;
                try collection.ownerOf(_tokenId_) returns (address _owner_) {
                    if (_owner_ == msg.sender) {
                        address beneficiary = stakeParams_[_index_].beneficiary;
                        _stakeToken(_tokenId_, beneficiary);
                            _index_++;
                    }
                } catch {}
            }
        }
    }

    /**
     * @dev return the list of tokenId's of staked passes by an address
     *
     * @param tokenOwner_ : the owner of the list of passes
     */
    function getStakedTokens(
        address tokenOwner_
    ) external view returns (uint[] memory) {
        return tokensOwned[tokenOwner_];
    }

    /**
     * @dev Internal function that unstakes a pass
     *
     * @param tokenId_ : the tokenId of the pass being unstaked
     */
    function _unstakeToken(uint256 tokenId_) internal {
        address _beneficiary_ = tokenStaked[tokenId_].beneficiary;
        if (_beneficiary_ != address(0) && _beneficiary_ != msg.sender) {
            benefitBalance[_beneficiary_]--;
        }
        delete tokenStaked[tokenId_];
        uint256 _len_ = tokensOwned[msg.sender].length;
        uint256 _index_ = _len_;

        while (_index_ > 0) {
            _index_--;
            if (tokensOwned[msg.sender][_index_] == tokenId_) {
                if (_index_ + 1 != _len_) {
                    tokensOwned[msg.sender][_index_] = tokensOwned[msg.sender][
                        _len_ - 1
                    ];
                }
                tokensOwned[msg.sender].pop();
                break;
            }
        }
        try collection.transferFrom(address(this), msg.sender, tokenId_) {
            totalStakedTokens--;
        } catch Error(string memory _err_) {
            revert(_err_);
        }
    }

    /**
     * @dev unstakes a single pass and verify the ownership
     *
     * @param tokenId_ : the tokenId of the pass being unstaked
     */
    function unstakeToken(uint256 tokenId_) external {
        // revert conditions
        require(
            tokenStaked[tokenId_].owner == msg.sender,
            "Token is not owned by sender"
        );
        _unstakeToken(tokenId_);
    }

    /**
     * @dev unstakes a batch of passes and verify the ownership
     *
     * @param tokenList_ : the list of tokenId of the passes being unstaked
     */
    function batchUnstakeTokens(uint256[] calldata tokenList_) external {
        unchecked {
            uint _len_ = tokenList_.length;
            uint _index_ = 0;
            while (_index_ < _len_) {
                uint _tokenId_ = tokenList_[_index_];
                if (tokenStaked[_tokenId_].owner == msg.sender) {
                    _unstakeToken(_tokenId_);
                }
                    _index_++;
            }
        }
    }

    /**
     * @dev returns the benefit balance of an address
     *
     * @param wallet_ : the address for whom the user wants to check benefit balance
     */
    function balanceOf(address wallet_) external view returns (uint256) {
        return tokensOwned[wallet_].length + benefitBalance[wallet_];
    }

    /**
     * @dev returns the status of an address whether it is beneficiary or not
     *
     * @param wallet_ : the address for whom the user wants to check
     */
    function isBeneficiary(address wallet_) external view returns (bool) {
        if (benefitBalance[wallet_] != 0) {
            return true;
        }
        uint _length_ = tokensOwned[wallet_].length;
        uint _index_ = 0;
        while (_index_ < _length_) {
            uint _tokenId_ = tokensOwned[wallet_][_index_];
            if (
                tokenStaked[_tokenId_].beneficiary == msg.sender ||
                tokenStaked[_tokenId_].beneficiary == address(0)
            ) {
                return true;
            }
            unchecked {
                _index_++;
            }
        }
        return false;
    }

    /**
     * @dev updates the beneficiary address of a staked token
     *
     * @param tokenId_ : the tokenId of the staked pass
     * @param beneficiaryAddress_: the address that would be used as a beneficiary
     */
    function updateBeneficiary(
        uint256 tokenId_,
        address beneficiaryAddress_
    ) external {
        require(
            tokenStaked[tokenId_].owner == msg.sender,
            "Token is not staked by sender"
        );
        address _oldBeneficiaryAddress_ = tokenStaked[tokenId_].beneficiary;
        if (_oldBeneficiaryAddress_ == beneficiaryAddress_) {
            return;
        }
        if (
            _oldBeneficiaryAddress_ != address(0) &&
            _oldBeneficiaryAddress_ != msg.sender
        ) {
            unchecked {
                benefitBalance[_oldBeneficiaryAddress_]--;
            }
        }
        if (
            beneficiaryAddress_ != address(0) &&
            beneficiaryAddress_ != msg.sender
        ) {
            unchecked {
                benefitBalance[beneficiaryAddress_]++;
            }
        }

        tokenStaked[tokenId_].beneficiary = beneficiaryAddress_;
    }
}