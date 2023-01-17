// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @dev security contract
import "./secutiry/Administered.sol";

/// @dev Red contract
import "./helpers/Package.sol";
import "./helpers/Withdraw.sol";
import "./helpers/Referred.sol";
import "./helpers/Oracle.sol";

/// @dev interface contract
import "./Interfaces/IPropertyToken.sol";

/// @dev ERC20 contract
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @dev stardanrt contract
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MainRed is Package, Oracle, Referred, Withdraw, ReentrancyGuard {
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

    /// @dev Slot machine
    struct Slot {
        uint256 packageId;
    }

    constructor() {}

    /// @dev buy package
    function buyPackege(
        address _addrToken,
        uint256 _packageId,
        string memory _codeReferrer,
        string memory _newCodeReferrer
    ) public payable nonReentrant {
        /// @dev slot machine
        Slot memory slot = Slot(_packageId);

        /// @dev get package
        PackageInfo memory _package = getPackage(slot.packageId);

        require(_package.active, "Package is not active");

        /// @dev check token
        require(isToken(_addrToken), "Token is not whitelisted");

        /// @dev get token info
        ERC20List memory tk = getTokenByAddr(_addrToken);
        require(tk.active, "Token is not whitelisted");

        /** Amount to Pay */
        uint256 _atp = parseUSDtoToken(_package.price, _addrToken, tk.isNative);

        require(_atp >= _package.price, "Amount is not enough");

        /// @dev calcule bonification // get user referrer
        uint256 percent = _atp / 100;
        uint256 amountBonus = percent * bonusDirect;

        /// @dev get referrer
        Referrals memory ref = getReferral(_codeReferrer);

        /// @dev check referrer
        require(ref._addrs != address(0), "Referrer is not exist");

        if (!tk.isNative) {
            require(
                IERC20(_addrToken).allowance(_msgSender(), address(this)) >=
                    _atp,
                "You don't have enough tokens to buy"
            );

            require(
                IERC20(_addrToken).balanceOf(_msgSender()) >= _atp,
                "You don't have enough tokens to buy"
            );

            require(
                IERC20(_addrToken).transferFrom(
                    _msgSender(),
                    address(this),
                    _atp
                ),
                "Error transferring tokens from user to vendor"
            );

            /// @dev send bunus direct
            require(
                IERC20(_addrToken).transfer(ref._addrs, amountBonus),
                "Error transferring tokens from user to vendor"
            );
        } else {
            /// @dev send bunus direct
            payable(ref._addrs).transfer(amountBonus);
        }

        /// @dev get referrer
        User memory userNew = getUser(_newCodeReferrer);
        Referrals memory ReferralsNew = getReferral(_newCodeReferrer);

        /// @dev is user new
        if (userNew._addr == address(0) && ReferralsNew._addrs == address(0)) {
            /// @dev save in list user
            _addUser(_newCodeReferrer, _msgSender(), ref._addrs);

            /// @dev sabe un list referrer
            _addReferral(
                _newCodeReferrer,
                _msgSender(),
                ref._addrs,
                amountBonus,
                block.timestamp,
                true
            );
        } else {
            /// @dev update list user
            ListUsers[_codeReferrer].totalReferrals.add(1);
            ListUsers[_codeReferrer].totalReferralEarnings.add(amountBonus);

            /// @dev update list referrer
            ListReferrals[_codeReferrer].amount.add(_package.price);
        }

        /// @dev send nft token to user
        _sendNFTs(_package._addrsNft, _msgSender(), 1);

        emit BuyPackage(
            _msgSender(),
            _addrToken,
            slot.packageId,
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