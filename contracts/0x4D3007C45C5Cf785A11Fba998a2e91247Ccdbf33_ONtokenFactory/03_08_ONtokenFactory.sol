// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { ONtokenSpawner } from "./ONtokenSpawner.sol";
import { AddressBookInterface } from "../interfaces/AddressBookInterface.sol";
import { ONtokenInterface } from "../interfaces/ONtokenInterface.sol";
import { WhitelistInterface } from "../interfaces/WhitelistInterface.sol";

/**
 * @title A factory to create onTokens
 * @notice Create new onTokens and keep track of all created tokens
 * @dev Calculate contract address before each creation with CREATE2
 * and deploy eip-1167 minimal proxies for onToken logic contract
 */
contract ONtokenFactory is ONtokenSpawner {
    using SafeMath for uint256;
    /// @notice AddressBook contract that records the address of the Whitelist module and the ONtoken impl address. */
    address public addressBook;

    /// @notice array of all created onTokens */
    address[] public onTokens;

    /// @dev mapping from parameters hash to its deployed address
    mapping(bytes32 => address) private idToAddress;

    /// @dev max expiry that BokkyPooBahsDateTimeLibrary can handle. (2345/12/31)
    uint256 private constant MAX_EXPIRY = 11865398400;

    constructor(address _addressBook) {
        addressBook = _addressBook;
    }

    /// @notice emitted when the factory creates a new Option
    event ONtokenCreated(
        address tokenAddress,
        address creator,
        address indexed underlying,
        address indexed strike,
        address[] indexed collateral,
        uint256 strikePrice,
        uint256 expiry,
        bool isPut
    );

    struct ONtokenParams {
        // "Stack too deep, try removing local variables" workaround
        bytes32 id;
        address whitelist;
        address onTokenImpl;
        address newONtoken;
    }

    /**
     * @notice create new onTokens
     * @dev deploy an eip-1167 minimal proxy with CREATE2 and register it to the whitelist module
     * @param _underlyingAsset asset that the option references
     * @param _strikeAsset asset that the strike price is denominated in
     * @param _collateralAssets assets that is held as collateral against short/written options
     * @param _collateralConstraints limits the maximum number of untrusted collateral tokens (0 - no limit)
     * @param _strikePrice strike price with decimals = 18
     * @param _expiry expiration timestamp as a unix timestamp
     * @param _isPut True if a put option, False if a call option
     * @return newONtoken address of the newly created option
     */
    function createONtoken(
        address _underlyingAsset,
        address _strikeAsset,
        address[] calldata _collateralAssets,
        uint256[] calldata _collateralConstraints,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external returns (address) {
        ONtokenParams memory p;
        require(_expiry > block.timestamp, "ONtokenFactory: Can't create expired option");
        require(_expiry < MAX_EXPIRY, "ONtokenFactory: Can't create option with expiry > 2345/12/31");
        // 8 hours = 3600 * 8 = 28800 seconds
        require(_expiry.sub(28800).mod(86400) == 0, "ONtokenFactory: Option has to expire 08:00 UTC");
        p.id = _getOptionId(
            _underlyingAsset,
            _strikeAsset,
            _collateralAssets,
            _collateralConstraints,
            _strikePrice,
            _expiry,
            _isPut
        );

        require(idToAddress[p.id] == address(0), "ONtokenFactory: Option already created");

        p.whitelist = AddressBookInterface(addressBook).getWhitelist();
        require(
            WhitelistInterface(p.whitelist).isWhitelistedProduct(
                _underlyingAsset,
                _strikeAsset,
                _collateralAssets,
                _isPut
            ),
            "ONtokenFactory: Unsupported Product"
        );

        require(_strikePrice > 0, "ONtokenFactory: Can't create a $0 strike option");

        p.onTokenImpl = AddressBookInterface(addressBook).getONtokenImpl();
        bytes memory initializationCalldata;

        initializationCalldata = abi.encodeWithSelector(
            ONtokenInterface(p.onTokenImpl).init.selector,
            addressBook,
            _underlyingAsset,
            _strikeAsset,
            _collateralAssets,
            _collateralConstraints,
            _strikePrice,
            _expiry,
            _isPut
        );

        p.newONtoken = _spawn(p.onTokenImpl, initializationCalldata);
        idToAddress[p.id] = p.newONtoken;
        onTokens.push(p.newONtoken);
        WhitelistInterface(p.whitelist).whitelistONtoken(p.newONtoken);

        emit ONtokenCreated(
            p.newONtoken,
            msg.sender,
            _underlyingAsset,
            _strikeAsset,
            _collateralAssets,
            _strikePrice,
            _expiry,
            _isPut
        );
        return p.newONtoken;
    }

    /**
     * @notice get the total onTokens created by the factory
     * @return length of the onTokens array
     */
    function getONtokensLength() external view returns (uint256) {
        return onTokens.length;
    }

    /**
     * @notice get the onToken address for an already created onToken, if no onToken has been created with these parameters, it will return address(0)
     * @param _underlyingAsset asset that the option references
     * @param _strikeAsset asset that the strike price is denominated in
     * @param _collateralAssets asset that is held as collateral against short/written options
     * @param _strikePrice strike price with decimals = 18
     * @param _expiry expiration timestamp as a unix timestamp
     * @param _isPut True if a put option, False if a call option
     * @return the address of target onToken.
     */
    function getONtoken(
        address _underlyingAsset,
        address _strikeAsset,
        address[] calldata _collateralAssets,
        uint256[] calldata _collateralConstraints,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external view returns (address) {
        bytes32 id = _getOptionId(
            _underlyingAsset,
            _strikeAsset,
            _collateralAssets,
            _collateralConstraints,
            _strikePrice,
            _expiry,
            _isPut
        );
        return idToAddress[id];
    }

    /**
     * @notice get the address at which a new onToken with these parameters would be deployed
     * @dev return the exact address that will be deployed at with _computeAddress
     * @param _underlyingAsset asset that the option references
     * @param _strikeAsset asset that the strike price is denominated in
     * @param _collateralAssets asset that is held as collateral against short/written options
     * @param _collateralConstraints limits the maximum number of untrusted collateral tokens (0 - no limit)
     * @param _strikePrice strike price with decimals = 18
     * @param _expiry expiration timestamp as a unix timestamp
     * @param _isPut True if a put option, False if a call option
     * @return targetAddress the address this onToken would be deployed at
     */
    function getTargetONtokenAddress(
        address _underlyingAsset,
        address _strikeAsset,
        address[] calldata _collateralAssets,
        uint256[] calldata _collateralConstraints,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external view returns (address) {
        address onTokenImpl = AddressBookInterface(addressBook).getONtokenImpl();

        bytes memory initializationCalldata = abi.encodeWithSelector(
            ONtokenInterface(onTokenImpl).init.selector,
            addressBook,
            _underlyingAsset,
            _strikeAsset,
            _collateralAssets,
            _collateralConstraints,
            _strikePrice,
            _expiry,
            _isPut
        );
        return _computeAddress(onTokenImpl, initializationCalldata);
    }

    /**
     * @dev hash onToken parameters and return a unique option id
     * @param _underlyingAsset asset that the option references
     * @param _strikeAsset asset that the strike price is denominated in
     * @param _collateralAssets asset that is held as collateral against short/written options
     * @param _strikePrice strike price with decimals = 18
     * @param _expiry expiration timestamp as a unix timestamp
     * @param _isPut True if a put option, False if a call option
     * @return id the unique id of an onToken
     */
    function _getOptionId(
        address _underlyingAsset,
        address _strikeAsset,
        address[] calldata _collateralAssets,
        uint256[] calldata _collateralConstraints,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _underlyingAsset,
                    _strikeAsset,
                    _collateralAssets,
                    _collateralConstraints,
                    _strikePrice,
                    _expiry,
                    _isPut
                )
            );
    }
}