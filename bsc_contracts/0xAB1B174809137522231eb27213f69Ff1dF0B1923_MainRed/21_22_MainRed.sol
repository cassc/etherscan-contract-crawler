// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @dev security contract
import "./secutiry/Administered.sol";

/// @dev Red contract
import "./helpers/Package.sol";
import "./helpers/Users.sol";
import "./helpers/Sales.sol";
import "./helpers/Oracle.sol";
import "./helpers/Utils.sol";

/// @dev interface contract
import "./Interfaces/IPropertyToken.sol";

/// @dev ERC20 contract
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @dev stardanrt contract
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MainRed is Package, Oracle, Users, Sales, Utils, ReentrancyGuard {
    /// @dev safe math
    using SafeMath for uint256;

    /// @dev event buy package
    event BuyPackage(
        address indexed _addr,
        address indexed _addrToken,
        uint256 _packageId,
        uint256 _amount,
        uint256 _price,
        uint256 _time
    );

    constructor(
        address _apocalypse,
        address _fundsWallet
    ) Utils(_apocalypse, _fundsWallet) {}

    /// @dev buy package
    function buyPackage(
        address _addrToken,
        uint256 _packageId,
        string memory _codeReferrer
    ) public payable nonReentrant {
        /// @dev is exist user
        require(isUserExist(_codeReferrer), "buyPackage: User is not exist");

        /// @dev get package
        PackageInfo memory _package = getPackage(_packageId);

        require(_package.active, "buyPackage: Package is not active");

        /// @dev check token
        require(isToken(_addrToken), "buyPackage: Token is not whitelisted");

        /// @dev get token info
        ERC20List memory tk = getTokenByAddr(_addrToken);
        require(tk.active, "buyPackage: Token is not whitelisted");

        /** Amount to Pay */
        uint256 _atp = parseUSDtoToken(_package.price, _addrToken, tk.isNative);

        if (!tk.isNative) {
            /// @dev check allowance
            require(
                IERC20(_addrToken).allowance(_msgSender(), address(this)) >=
                    _atp,
                "buyPackage: You don't have enough tokens to buy"
            );

            /// @dev check balance
            require(
                IERC20(_addrToken).balanceOf(_msgSender()) >= _atp,
                "buyPackage: You don't have enough tokens to buy"
            );

            /// @dev transfer token from user to vendor
            require(
                IERC20(_addrToken).transferFrom(
                    _msgSender(),
                    address(this),
                    _atp
                ),
                "buyPackage: Error transferring tokens from user to vendor"
            );

            require(
                IERC20(_addrToken).transfer(fundsWallet, _atp),
                "buyPackage: Error transferring tokens from vendor to funds wallet"
            );
        } else {
            /// @dev check balance
            require(
                msg.value >= _atp,
                "buyPackage: You don't have enough tokens to buy"
            );

            /// @dev transfer token from user to vendor
            require(
                payable(address(fundsWallet)).send(msg.value),
                "buyPackage:Error transferring tokens from vendor to funds wallet"
            );
        }

        /// @dev send nft token to user
        _sendNFTs(_package.NFTaddress, _msgSender(), 1);

        /// @dev add sales
        _addSale(_codeReferrer, _msgSender(), _package.price);

        /// @dev event buy package emit - backend
        emit BuyPackage(
            _msgSender(),
            _addrToken,
            _packageId,
            _atp,
            _package.price,
            block.timestamp
        );
    }

    /**
     * @dev Send NFTs to a user
     * @param _token Address of the NFT
     * @param _to Address of the user
     * @param _qty Amount of NFTs to send
     */
    function _sendNFTs(address _token, address _to, uint256 _qty) private {
        IPropertyToken(_token).mintReserved(_to, _qty);
    }
}