// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "openzeppelin-contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

/**
 * @title DZooToken
 * @author thomgabriel & canokaue
 * @dev {ERC20} token, including:
 *
 *  - DZooNFT contract can burn (destroy) and mint user tokens
 *  - Holders can sign permits and save gas via one less tx on external token transfers through {ERC20Permit}
 *
 * The account that deploys the contract will specify main parameters via constructor,
 * paying close attention to "admin" address who will receive 100% of initial supply and
 * should then distribute tokens according to tokenomics & planning.
 * inherited from {ERC20} and {ERC20Permit}
 */
contract DZooToken is ERC20Permit {
    /// @notice DZooNFT contract identifier for mint/burn
    address public dZooNFT;

    /// @notice DZooNFT contract modifier for mint/burn
    modifier onlyDZoo() {
        require(
            _msgSender() == dZooNFT,
            "DZooToken: Only DZooNFT can call this function"
        );
        _;
    }

    /**
     * @dev Mints `initialSupply` amount of token and transfers them to `admin`.
     * Also sets domain separator under same token name for EIP712 in ERC20Permit,
     * and sets NFT contract  for mint and burn.
     *
     * See {ERC20-constructor} and {ERC20Permit-constructor}.
     * @param initialSupply total supply of the token
     * @param admin address of the admin
     * @param dZooNFT_ address of the DZooNFT contract
     */
    constructor(
        uint256 initialSupply,
        address admin,
        address dZooNFT_
    )
        ERC20("DegenZoo", "DZOO")
        ERC20Permit("DegenZoo")
    {
        require(admin != address(0), "DZooToken: admin is the zero address");
        require(
            dZooNFT_ != address(0),
            "DZooToken: dZooNFT is the zero address"
        );
        require(initialSupply != 0, "DZooToken: initial supply can't be zero");
        _mint(admin, initialSupply);
        dZooNFT = dZooNFT_;
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must be the DZooNFT contract.
     * @param to address of the recipient
     * @param amount amount of tokens to mint
     */
    function mint(address to, uint256 amount) external onlyDZoo {
        _mint(to, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * See {ERC20-_burn}.
     *
     * Requirements:
     *
     * - the caller must be the DZooNFT contract.
     * @param to address of the recipient
     * @param amount amount of tokens to burn
     */
    function burn(address to, uint256 amount) external onlyDZoo {
        _burn(to, amount);
    }
}