// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
 * @title Implementation of IERC721Enumerable, meant to be used as staked version of a NFT. 
 *
 * @dev Reduces gas cost for minting and burning by using staked tokens enumerator for {tokenByIndex} and {totalSupply} 
 * and making {tokenOfOwnerByIndex} and {tokensOfOwner} very inefficient.
 * Only use {tokenOfOwnerByIndex} and {tokensOfOwner} these methods in view methods!
 *
 * @author Fab
 */
contract StakedToken is ERC721, IERC721Enumerable {
    using Strings for uint256;

    IERC721Enumerable public immutable stakedToken;
    address public immutable stakingContract;
    string private baseURI;

    modifier onlyStakingContract() {
        require(msg.sender == stakingContract, "Only staking contract");
        _;
    }

    constructor(address _stakedToken)
        ERC721(
            string(abi.encodePacked(IERC721Metadata(_stakedToken).name(), " Staked")), 
            string(abi.encodePacked(IERC721Metadata(_stakedToken).symbol(), "-S"))
        )
    {
        stakedToken = IERC721Enumerable(_stakedToken);
        stakingContract = msg.sender;
    }


    /**
     * @notice Allows the owner to set the base URI to be used for all not revealed token IDs
     * @param _uri: base URI
     * @dev Callable by owner
     */
    function setBaseURI(string memory _uri) external onlyStakingContract {
        baseURI = _uri;
    }

    
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() public view override returns (uint256) {
        return stakedToken.balanceOf(stakingContract);
    }

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     * @dev Warning: This function is very inefficient and is meant to be accessed in view read methods only.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256 tokenId) {
        require(index < balanceOf(owner));

        uint256 indexOfOwner;
        uint256 _totalSupply = totalSupply();
        unchecked {
            for (uint256 i = 0; i < _totalSupply; ++i) {
                tokenId = stakedToken.tokenOfOwnerByIndex(stakingContract, i);
                if (ownerOf(tokenId) == owner) {
                    if (indexOfOwner == index) return tokenId;
                    indexOfOwner++;
                }
            }
        }
    }

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        return stakedToken.tokenOfOwnerByIndex(stakingContract, index);
    }

    /**
     * @notice Returns all tokenIds owned by `_owner`
     * @param _owner: owner
     * @dev Warning: This function is very inefficient and is meant to be accessed in view read methods only.
     */
    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory result = new uint256[](tokenCount);
        uint256 index;

        uint256 _totalSupply = totalSupply();
        unchecked {
            for (uint256 i = 0; i < _totalSupply && index < tokenCount; ++i) {
                uint256 tokenId = stakedToken.tokenOfOwnerByIndex(stakingContract, i);
                if (ownerOf(tokenId) == _owner) {
                    result[index++] = tokenId;
                }
            }
        }
        return result;
    }

    function mint(address to, uint256 tokenId) external onlyStakingContract {
        super._safeMint(to, tokenId);
    }

    function burn(uint256 tokenId) external onlyStakingContract {
        super._burn(tokenId);
    }

    /**
     * @dev See {ERC721-_baseURI}
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId));

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : IERC721Metadata(address(stakedToken)).tokenURI(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        require(
            from == address(0) || to == address(0),
            "Staking Receipt not transferable"
        );
    }
}