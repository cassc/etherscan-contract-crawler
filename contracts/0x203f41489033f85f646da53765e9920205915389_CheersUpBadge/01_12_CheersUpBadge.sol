// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/*
 ____                   _           _         
|  _ \                 | |         | |        
| |_) | __ _ ___  ___  | |     __ _| |__  ___ 
|  _ < / _` / __|/ _ \ | |    / _` | '_ \/ __|
| |_) | (_| \__ \  __/ | |___| (_| | |_) \__ \
|____/ \__,_|___/\___| |______\__,_|_.__/|___/
                                              
*/

pragma solidity ^0.8.7;

/**
 * @title CheersUpBadge
 * @author BaseLabs
 */
contract CheersUpBadge is ERC1155Burnable, Ownable, Pausable {
    string public name = "CheersUpBadge";
    string public symbol = "CUPB";
    mapping(uint256 => string) private _uris;
    mapping(uint256 => uint256) private _totalSupply;

    constructor() ERC1155("") {}

    /***********************************|
    |               Core                |
    |__________________________________*/

    /**
     * @notice giveaway is used for airdropping to specific addresses.
     * This process is under the supervision of the community.
     * @param accounts_ the target address of airdrop
     * @param nums_ the number of airdrop
     * @param nums_ the tokenId of airdrop
     */
    function giveaway(address[] calldata accounts_, uint256[] calldata nums_, uint256 tokenId_) external onlyOwner {
        require(accounts_.length == nums_.length, "accounts_ and nums_ length mismatch");
        require(accounts_.length > 0, "no account");
        unchecked {
            for (uint256 i = 0; i < accounts_.length; i++) {
                _mint(accounts_[i], tokenId_, nums_[i], "");
            }
        }
    }

    /**
     * @notice setURI is used to set the URI corresponding to the tokenId
     * @param tokenId_ token id
     * @param uri_ metadata uri corresponding to the token
     */
    function setURI(uint256 tokenId_, string calldata uri_) external onlyOwner {
        _uris[tokenId_] = uri_;
        emit URI(uri_, tokenId_);
    }

    /**
     * @notice uri is used to obtain the URI address corresponding to the tokenId
     * @param tokenId_ token id
     * @return URI address corresponding to the tokenId
     */
    function uri(uint256 tokenId_) public view virtual override returns (string memory) {
        return _uris[tokenId_];
    }

    /***********************************|
    |               Pause               |
    |__________________________________*/

    /**
     * @notice for the purpose of protecting user assets, under extreme conditions, 
     * the circulation of all tokens in the contract needs to be frozen.
     * This process is under the supervision of the community.
     */
    function emergencyPause() external onlyOwner {
        _pause();
    }

    /**
     * @notice unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /***********************************|
    |              Supply               |
    |__________________________________*/

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return totalSupply(id) > 0;
    }


    /***********************************|
    |               Hooks               |
    |__________________________________*/

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        require(!paused(), "token transfer paused");
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] -= amounts[i];
            }
        }
    }
}