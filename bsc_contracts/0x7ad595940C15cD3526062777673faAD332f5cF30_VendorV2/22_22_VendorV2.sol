// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @dev open source tokenity vendor contract
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @dev security
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./security/Administered.sol";

/// @dev stardanrt contract
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @dev factory
import "./factories/CollectionV2.sol";
import "./factories/ClaimFactory.sol";

/// @dev helpers
import "./helpers/OracleV2.sol";
import "./helpers/WithdrawV2.sol";
import "./Interfaces/INFTCollection.sol";

contract VendorV2 is
    Administered,
    WithdrawV2,
    ReentrancyGuard,
    CollectionV2,
    OracleV2,
    ClaimFactory
{
    /// @notice Transfer token reserved
    /// @dev Transfer a token to a user only if the user is in the user role
    /// @param _idx                              Id of the pair
    /// @param _addr                              Address of the wallet destination
    /// @param _qty                             Id of the token to transfer
    function transferReserved(
        uint256 _idx,
        address _addr,
        uint256 _qty
    ) external onlyUser nonReentrant {
        CollectionStruct storage c = collections[_idx];
        require(c.active, "Collection is not active");
        _sendNFTs(c.addr, _addr, _qty);
    }

    /// @notice Buy token
    /// @dev Buy NFT and pay with custom token
    /// @param _cIdx                              Id of the Collection
    /// @param _token                               Address of the token to pay
    /// @param _amount                        Amount of tokens to buy
    function buyWithToken(
        address _token,
        uint256 _cIdx,
        uint256 _amount
    ) external nonReentrant {
        require(_amount > 0, "Amount of token greater than zero");

        CollectionStruct storage c = collections[_cIdx];

        require(c.active, "Collection is not active");

        require(isToken(_token), "Invalid token");

        ERC20List memory tk = getTokenByAddr(_token);

        require(tk.active && !tk.isNative, "Token is not available");

        /** Amount to Pay */
        uint256 _atp = parseUSDtoToken((c.price * _amount), _token, false);

        require(
            IERC20(_token).allowance(_msgSender(), address(this)) >= _atp,
            "Token approval is required to continue"
        );

        require(
            IERC20(_token).balanceOf(_msgSender()) >= _atp,
            "You don't have enough tokens to buy"
        );

        require(
            IERC20(_token).transferFrom(_msgSender(), address(this), _atp),
            "Error transferring tokens from user to vendor"
        );

        _sendNFTs(c.addr, _msgSender(), _amount);
    }

    /**
     * @dev Buy NFT and pay with native token
     * @param _cIdx                              Id of the Collection
     * @param _token                              Address of the token to pay
     * @param _amount                        Amount of tokens to buy
     */
    function buyNative(
        uint256 _cIdx,
        address _token,
        uint256 _amount
    ) external payable nonReentrant {
        require(_amount > 0, "Amount of token greater than zero");

        require(msg.value > 0, "No amount sended");

        CollectionStruct storage c = collections[_cIdx];

        require(c.active, "Collection is not active");

        require(isToken(_token), "Invalid token");

        ERC20List memory tk = getTokenByAddr(_token);

        require(tk.active && tk.isNative, "Token is not available");

        /** Amount to Pay */
        uint256 _atp = parseUSDtoToken((c.price * _amount), _token, true);

        require(msg.value >= _atp, "You don't have enough tokens to buy");

        _sendNFTs(c.addr, _msgSender(), _amount);
    }

    /**
     * @dev Claim NFTs
     */
    function claimNft(string memory _code) external {
        /// @dev check if the NFTs is already created
        StructClaim memory clain = _claim[_code];

        /// @dev check if the NFTs is already created
        require(clain.withdrawal, "Mint NFTs already removed");

        /// @dev send the NFTs to the user
        _sendNFTs(clain.addrNft, _msgSender(), clain.amountNft);

        /// @dev update the status of the NFTs
        _claim[_code] = StructClaim(
            _msgSender(),
            clain.addrNft,
            clain.amountNft,
            block.timestamp,
            false
        );
    }

    /**
     * @dev Send NFTs to a user
     * @param _token Address of the NFT
     * @param _to Address of the user
     * @param _qty Amount of NFTs to send
     */
    function _sendNFTs(address _token, address _to, uint256 _qty) private {
        INFTCollection(_token).mintReserved(_to, _qty);
    }
}