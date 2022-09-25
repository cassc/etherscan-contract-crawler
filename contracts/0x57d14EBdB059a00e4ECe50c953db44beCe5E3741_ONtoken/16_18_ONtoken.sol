// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ERC20PermitUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";

import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { BokkyPooBahsDateTimeLibrary } from "../packages/BokkyPooBahsDateTimeLibrary.sol";
import { AddressBookInterface } from "../interfaces/AddressBookInterface.sol";
import { Constants } from "./Constants.sol";

/**
 * @title ONtoken
 * @notice ONtoken is the ERC20 token for an option
 * @dev The ONtoken inherits ERC20Upgradeable thats' why we need to use the init instead of constructor
 */
contract ONtoken is ERC20PermitUpgradeable {
    using SafeMath for uint256;

    /// @notice total amount of minted onTokens, does not decrease on burn when onToken is redeemed
    // but decreases when burnONToken is called by vault owner for correct calculations in MarginCalculator
    // used for calculating redeems and settles
    uint256 public collaterizedTotalAmount;

    /// @notice address of the Controller module
    address public controller;

    /// @notice asset that the option references
    address public underlyingAsset;

    /// @notice asset that the strike price is denominated in
    address public strikeAsset;

    /// @notice assets that is held as collateral against short/written options
    address[] public collateralAssets;

    /// @notice amounts of collateralAssets used for collaterization of collaterizedTotalAmount of this onToken
    /// updated upon every mint and burn by vaults owners
    uint256[] public collateralsAmounts;

    /// @notice value of collateral assets denominated in strike asset, used for mint collaterizedTotalAmount of this onToken
    /// updated upon every mint and burn by vaults owners
    uint256[] public collateralsValues;

    /// @notice amounts of collateralConstraints used to limit the maximum number of untrusted collateral tokens (0 - no limit)
    uint256[] internal collateralConstraints;

    /// @notice strike price with decimals = 8
    uint256 public strikePrice;

    /// @notice expiration timestamp of the option, represented as a unix timestamp
    uint256 public expiryTimestamp;

    /// @notice True if a put option, False if a call option
    bool public isPut;

    uint256 private constant STRIKE_PRICE_SCALE = 1e8;
    uint256 private constant STRIKE_PRICE_DIGITS = 8;

    /**
     * @notice initialize the onToken
     * @param _addressBook addressbook module
     * @param _underlyingAsset asset that the option references
     * @param _strikeAsset asset that the strike price is denominated in
     * @param _collateralAssets asset that is held as collateral against short/written options
     * @param _collateralConstraints limits the maximum number of untrusted collateral tokens (0 - no limit)
     * @param _strikePrice strike price with decimals = 8
     * @param _expiryTimestamp expiration timestamp of the option, represented as a unix timestamp
     * @param _isPut True if a put option, False if a call option
     */
    function init(
        address _addressBook,
        address _underlyingAsset,
        address _strikeAsset,
        address[] calldata _collateralAssets,
        uint256[] calldata _collateralConstraints,
        uint256 _strikePrice,
        uint256 _expiryTimestamp,
        bool _isPut
    ) external initializer {
        require(_collateralAssets.length > 0, "collateralAssets must be non-empty");
        require(
            _collateralAssets.length <= Constants.MAX_COLLATERAL_ASSETS,
            "collateralAssets must be less than or equal to MAX_COLLATERAL_ASSETS"
        );
        require(
            _collateralAssets.length == _collateralConstraints.length,
            "_collateralConstraints and _collateralAssets must have same length"
        );
        controller = AddressBookInterface(_addressBook).getController();
        underlyingAsset = _underlyingAsset;
        strikeAsset = _strikeAsset;
        collateralAssets = _collateralAssets;
        collateralConstraints = _collateralConstraints;
        collateralsAmounts = new uint256[](collateralAssets.length);
        collateralsValues = new uint256[](collateralAssets.length);
        strikePrice = _strikePrice;
        expiryTimestamp = _expiryTimestamp;
        isPut = _isPut;
        (string memory tokenName, string memory tokenSymbol) = _getNameAndSymbol();
        __ERC20_init_unchained(tokenName, tokenSymbol);
        __ERC20Permit_init(tokenName);
    }

    function decimals() public view virtual override returns (uint8) {
        return 8;
    }

    function getONtokenDetails()
        external
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            address,
            address,
            uint256,
            uint256,
            bool,
            uint256
        )
    {
        uint256 collateralAssetsLength = collateralAssets.length;
        uint256[] memory collateralsDecimals = new uint256[](collateralAssetsLength);

        for (uint256 i = 0; i < collateralAssetsLength; i++) {
            collateralsDecimals[i] = ERC20Upgradeable(collateralAssets[i]).decimals();
        }

        return (
            collateralAssets,
            collateralsAmounts,
            collateralsValues,
            collateralsDecimals,
            underlyingAsset,
            strikeAsset,
            strikePrice,
            expiryTimestamp,
            isPut,
            collaterizedTotalAmount
        );
    }

    /**
     * @dev helper function to get full array of collateral assets
     */
    function getCollateralAssets() external view returns (address[] memory) {
        return collateralAssets;
    }

    /**
     * @dev helper function to get full array of collateral constraints
     */
    function getCollateralConstraints() external view returns (uint256[] memory) {
        return collateralConstraints;
    }

    /**
     * @dev helper function to get full array of collateral amounts
     */
    function getCollateralsAmounts() external view returns (uint256[] memory) {
        return collateralsAmounts;
    }

    /**
     * @dev helper function to get full array of collateral values
     */
    function getCollateralsValues() external view returns (uint256[] memory) {
        return collateralsValues;
    }

    /**
     * @notice mint onToken for an account
     * @dev Controller only method where access control is taken care of by _beforeTokenTransfer hook
     * @param account account to mint token to
     * @param amount amount to mint
     * @param collateralsAmountsForMint amounts of colateral assets to mint with
     * @param collateralsValuesForMint value of collateral assets in strike asset tokens used for this mint
     */
    function mintONtoken(
        address account,
        uint256 amount,
        uint256[] calldata collateralsAmountsForMint,
        uint256[] calldata collateralsValuesForMint
    ) external {
        require(msg.sender == controller, "ONtoken: Only Controller can mint ONtokens");

        uint256 collateralAssetsLength = collateralAssets.length;

        require(
            collateralAssetsLength == collateralsAmountsForMint.length,
            "ONtoken: collateralAmountsForMint must have same length as collateralAssets"
        );
        require(
            collateralAssetsLength == collateralsValuesForMint.length,
            "ONtoken: collateralAssets and collateralsValuesForMint must be of same length"
        );
        uint256[] memory _collateralsAmounts = collateralsAmounts;
        uint256[] memory _collateralsValues = collateralsValues;
        uint256[] memory _collateralConstraints = collateralConstraints;

        for (uint256 i = 0; i < collateralAssetsLength; i++) {
            _collateralsValues[i] = collateralsValuesForMint[i].add(_collateralsValues[i]);
            _collateralsAmounts[i] = _collateralsAmounts[i].add(collateralsAmountsForMint[i]);
            if (_collateralConstraints[i] > 0) {
                require(
                    _collateralConstraints[i] >= _collateralsAmounts[i],
                    "ONtoken: collateral token constraint exceeded"
                );
            }
        }
        collateralsValues = _collateralsValues;
        collateralsAmounts = _collateralsAmounts;
        collaterizedTotalAmount = collaterizedTotalAmount.add(amount);
        _mint(account, amount);
    }

    /**
     * @notice burn onToken from an account.
     * @dev Controller only method where access control is taken care of by _beforeTokenTransfer hook
     * @param account account to burn token from
     * @param amount amount to burn
     */
    function burnONtoken(address account, uint256 amount) external {
        require(msg.sender == controller, "ONtoken: Only Controller can burn ONtokens");
        _burn(account, amount);
    }

    /**
     * @notice reduces collaterization amounts and values of onToken, used when onToken is burned by vault's owner
     * @dev Controller only method where access control is taken care of by _beforeTokenTransfer hook
     */
    function reduceCollaterization(
        uint256[] calldata collateralsAmountsForReduce,
        uint256[] calldata collateralsValuesForReduce,
        uint256 onTokenAmountBurnt
    ) external {
        require(msg.sender == controller, "ONtoken: Only Controller can burn ONtokens");

        uint256 collateralAssetsLength = collateralAssets.length;

        require(
            collateralAssetsLength == collateralsValuesForReduce.length,
            "ONtoken: collateralAssets and collateralsValuesForReduce must be of same length"
        );
        require(
            collateralAssetsLength == collateralsAmountsForReduce.length,
            "ONtoken: collateralAssets and collateralsAmountsForReduce must be of same length"
        );
        for (uint256 i = 0; i < collateralAssetsLength; i++) {
            collateralsValues[i] = collateralsValues[i].sub(collateralsValuesForReduce[i]);
            collateralsAmounts[i] = collateralsAmounts[i].sub(collateralsAmountsForReduce[i]);
        }
        collaterizedTotalAmount = collaterizedTotalAmount.sub(onTokenAmountBurnt);
    }

    /**
     * @notice generates the name and symbol for an option
     * @dev this function uses a named return variable to avoid the stack-too-deep error
     * @return tokenName (ex: ETHUSDC 05-September-2020 200 Put USDC Collateral)
     * @return tokenSymbol (ex: oETHUSDC-05SEP20-200P)
     */
    function _getNameAndSymbol() internal view returns (string memory tokenName, string memory tokenSymbol) {
        string memory underlying = ERC20Upgradeable(underlyingAsset).symbol();
        string memory strike = ERC20Upgradeable(strikeAsset).symbol();
        string memory collateral = collateralAssets.length > 1
            ? string(abi.encodePacked("MULTI", _uintTo2Chars(collateralAssets.length)))
            : ERC20Upgradeable(collateralAssets[0]).symbol();
        string memory displayStrikePrice = _getDisplayedStrikePrice(strikePrice);

        // convert expiry to a readable string
        (uint256 year, uint256 month, uint256 day) = BokkyPooBahsDateTimeLibrary.timestampToDate(expiryTimestamp);

        // get option type string
        (string memory typeSymbol, string memory typeFull) = _getOptionType(isPut);

        //get option month string
        (string memory monthSymbol, string memory monthFull) = _getMonth(month);

        // concatenated name string: ETHUSDC 05-September-2020 200 Put USDC Collateral
        tokenName = string(
            abi.encodePacked(
                underlying,
                strike,
                " ",
                _uintTo2Chars(day),
                "-",
                monthFull,
                "-",
                Strings.toString(year),
                " ",
                displayStrikePrice,
                typeFull,
                " ",
                collateral,
                " Collateral"
            )
        );

        // concatenated symbol string: onETHUSDC/USDC-05SEP20-200P
        tokenSymbol = string(
            abi.encodePacked(
                "on",
                underlying,
                strike,
                "/",
                collateral,
                "-",
                _uintTo2Chars(day),
                monthSymbol,
                _uintTo2Chars(year),
                "-",
                displayStrikePrice,
                typeSymbol
            )
        );
    }

    /**
     * @dev convert strike price scaled by 1e8 to human readable number string
     * @param _strikePrice strike price scaled by 1e8
     * @return strike price string
     */
    function _getDisplayedStrikePrice(uint256 _strikePrice) internal pure returns (string memory) {
        uint256 remainder = _strikePrice.mod(STRIKE_PRICE_SCALE);
        uint256 quotient = _strikePrice.div(STRIKE_PRICE_SCALE);
        string memory quotientStr = Strings.toString(quotient);

        if (remainder == 0) return quotientStr;

        uint256 trailingZeroes;
        while (remainder.mod(10) == 0) {
            remainder = remainder / 10;
            trailingZeroes += 1;
        }

        // pad the number with "1 + starting zeroes"
        remainder += 10**(STRIKE_PRICE_DIGITS - trailingZeroes);

        string memory tmpStr = Strings.toString(remainder);
        tmpStr = _slice(tmpStr, 1, 1 + STRIKE_PRICE_DIGITS - trailingZeroes);

        string memory completeStr = string(abi.encodePacked(quotientStr, ".", tmpStr));
        return completeStr;
    }

    /**
     * @dev return a representation of a number using 2 characters, adds a leading 0 if one digit, uses two trailing digits if a 3 digit number
     * @return 2 characters that corresponds to a number
     */
    function _uintTo2Chars(uint256 number) internal pure returns (string memory) {
        if (number > 99) number = number % 100;
        string memory str = Strings.toString(number);
        if (number < 10) {
            return string(abi.encodePacked("0", str));
        }
        return str;
    }

    /**
     * @dev return string representation of option type
     * @return shortString a 1 character representation of option type (P or C)
     * @return longString a full length string of option type (Put or Call)
     */
    function _getOptionType(bool _isPut) internal pure returns (string memory shortString, string memory longString) {
        if (_isPut) {
            return ("P", "Put");
        } else {
            return ("C", "Call");
        }
    }

    /**
     * @dev cut string s into s[start:end]
     * @param _s the string to cut
     * @param _start the starting index
     * @param _end the ending index (excluded in the substring)
     */
    function _slice(
        string memory _s,
        uint256 _start,
        uint256 _end
    ) internal pure returns (string memory) {
        bytes memory a = new bytes(_end - _start);
        for (uint256 i = 0; i < _end - _start; i++) {
            a[i] = bytes(_s)[_start + i];
        }
        return string(a);
    }

    /**
     * @dev return string representation of a month
     * @return shortString a 3 character representation of a month (ex: SEP, DEC, etc)
     * @return longString a full length string of a month (ex: September, December, etc)
     */
    function _getMonth(uint256 _month) internal pure returns (string memory shortString, string memory longString) {
        if (_month == 1) {
            return ("JAN", "January");
        } else if (_month == 2) {
            return ("FEB", "February");
        } else if (_month == 3) {
            return ("MAR", "March");
        } else if (_month == 4) {
            return ("APR", "April");
        } else if (_month == 5) {
            return ("MAY", "May");
        } else if (_month == 6) {
            return ("JUN", "June");
        } else if (_month == 7) {
            return ("JUL", "July");
        } else if (_month == 8) {
            return ("AUG", "August");
        } else if (_month == 9) {
            return ("SEP", "September");
        } else if (_month == 10) {
            return ("OCT", "October");
        } else if (_month == 11) {
            return ("NOV", "November");
        } else {
            return ("DEC", "December");
        }
    }
}