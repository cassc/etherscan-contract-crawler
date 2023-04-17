// File contracts/AqurisFishContainer.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

/// @title NFT game from Aquaris.io
/// @author Nikita Volkov - <[email protected]>

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AquarisFishContainer is Ownable, ERC1155Supply, ERC1155URIStorage {
    /*
     * Using
     */
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    /*
     * Events
     */
    event SetStableERC20(address indexed stableERC20);
    event PoolWithdrawed(address indexed to);


    /*
     * Constants
     */
    uint256 public constant FISH = 0;
    uint256 public constant PROMO_FISH = 1;

    string public constant name = "AquarisFishContainer";
    string public constant symbol = "AQSFish";

    uint256 public constant limitMintNFTTotal = 2000;


    /*
     * Storage
     */
    mapping(bytes32 => bool) private _hashMap;

    bool public stakingIsOver;    

    IERC20 public stableERC20;

    /*
     * Constructor
     */ 
    constructor() ERC1155("") {
    }


    /*
     * Public Functions
     */ 
    /// @dev Returns the URI for the passed tokenId.
    /// @param tokenId Token Id.
    /// @return string URI to metadata.
    function uri(uint256 tokenId)
        public
        view
        override(ERC1155, ERC1155URIStorage)
        returns (string memory)
    {
        return ERC1155URIStorage.uri(tokenId);
    }
    
    /// @dev Returns total supply.
    /// @return supply Total supply.
    function totalSupply() external view returns (uint256 supply) {
        uint256 _totalSupply;
        for (uint256 id = 0; id <= 1; ) {
            _totalSupply += totalSupply(id);
            unchecked {
                ++id;
            }
            return _totalSupply;
        }
    }

    /// @dev The "main" token of the collection is minted. 
    /// To do this, 100 * 10**18 tokens are debited from the requesting wallet, 
    /// usually stable tokens, like $USDT.
    /// @param amount Amount tokens to mint.
    function mint(uint256 amount) public {
        require(totalSupply(0).add(amount) <= limitMintNFTTotal, "AquarisFishContainer: NFT mint limit is exceeded");

        uint256 allowance = stableERC20.allowance(msg.sender, address(this));
        require(allowance >= amount.mul(100).mul(10**18),  "AquarisFishContainer: check the token allowance");
        stableERC20.transferFrom(msg.sender, address(this), amount.mul(100).mul(10**18));

        _mint(msg.sender, 0, amount, "0x");
    }


    /*
     * Owner Functions
     */

    /// @dev Sets URI to metadata for tokenId.
    /// @param tokenId Token Id.
    /// @param tokenURI URI to metadata.
    function setURI(uint256 tokenId, string memory tokenURI) public onlyOwner {
        _setURI(tokenId, tokenURI);
    }

    /// @dev Sets the address of the stable erc20 token used.
    /// @param erc20Address Smart contract address.
    function setStableERC20(address erc20Address) public onlyOwner {
        stableERC20 = IERC20(erc20Address);
        emit SetStableERC20(erc20Address);
    }

    /// @dev Minting coins with tokenId = 1, used for various social promotions. 
    /// In the realities of business processes, 
    /// it has different characteristics from the main token.
    /// @param account The address to which the tokens are minted.
    /// @param amount Amount tokens to mint.
    function mintForDrop(
        address account,
        uint256 amount
    ) public onlyOwner {
        _mint(account, 1, amount, "0x");
    }

    /// @dev Token Burning. Tokens are burned from the calling address. 
    /// In this interpretation, only the owner can summon the function,
    /// so only the owner can burn his tokens.
    /// @param tokenId Token Id.
    /// @param amount Amount tokens to burn.
    function burn(
        uint256 tokenId,
        uint256 amount
    ) external onlyOwner {
        _burn(msg.sender, tokenId, amount);
    }

    /// @dev Withdrawal of funds for business use.
    function withdrawPool() external onlyOwner {
        uint256 balance = stableERC20.balanceOf(address(this));
        address owner = owner();
        stableERC20.transfer(owner, balance);
        emit PoolWithdrawed(owner);
    }


    /*
     * Overridden functions
     */

    /// @dev The following function are overrides required by Solidity.
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        ERC1155Supply._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}