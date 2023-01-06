pragma experimental ABIEncoderV2;
pragma solidity ^0.4.24;

import "@aragon/os/contracts/apps/AragonApp.sol";
import "@aragon/os/contracts/common/EtherTokenConstant.sol";
import "@aragon/os/contracts/common/SafeERC20.sol";
import "@aragon/os/contracts/lib/token/ERC20.sol";
import "@aragon/apps-agent/contracts/Agent.sol";
import "@aragon/apps-token-request/contracts/TokenRequest.sol";
import "../../../core/IWeeziCore.sol";

/**
 * The expected use of this app requires the FINALISE_TOKEN_REQUEST_ROLE permission be given exclusively to a forwarder.
 * A user can then request tokens by calling createTokenRequest() to deposit funds and then calling finaliseTokenRequest()
 * which will be called via the forwarder if forwarding is successful, minting the user tokens.
 */
contract Depositor is AragonApp {
    using SafeERC20 for ERC20;
    using UintArrayLib for uint256[];
    using AddressArrayLib for address[];

    IWeeziCore public weeziCore;
    TokenRequest public tokenRequest;

    bytes32 public constant SET_TOKEN_REQUEST_ROLE =
        keccak256("SET_TOKEN_REQUEST_ROLE");
    bytes32 public constant SET_WEEZICORE_ROLE =
        keccak256("SET_WEEZICORE_ROLE");
    bytes32 public constant FINALISE_TOKEN_REQUEST_ROLE =
        keccak256("FINALISE_TOKEN_REQUEST_ROLE");
    string private constant ERROR_EXPIRED_CREATE_REQUEST_DATA =
        "EXPIRED_CREATE_REQUEST_DATA";
    string private constant ERROR_ADDRESS_NOT_CONTRACT =
        "TOKEN_REQUEST_ADDRESS_NOT_CONTRACT";
    string private constant ERROR_ETH_TRANSFER_FAILED =
        "SERVICE_FEE_ETH_TRANSFER_FAILED";
    string private constant ERROR_TOKEN_TRANSFER_REVERTED =
        "SERVICE_FEE_TOKEN_TRANSFER_REVERTED";
    string private constant ERROR_SERVICE_FEE_TOO_HIGH = "SERVICE_FEE_TOO_HIGH";
    string private constant ERROR_NO_REQUEST = "TOKEN_REQUEST_NO_REQUEST";

    struct FinaliseTokenRequestParams {
        uint256 _tokenRequestId;
        uint256 _serviceFee;
        uint256 _timestamp;
        bytes _signature;
    }

    event SetTokenRequest(address tokenRequest);
    event SetWeeziCore(address weeziCore);
    event TokenRequestFinalised(
        uint256 requestId,
        address requester,
        address depositToken,
        uint256 depositAmount,
        address requestToken,
        uint256 requestAmount,
        address serviceAddress,
        uint256 serviceFee
    );

    modifier withValidData(FinaliseTokenRequestParams params) {
        // Check that signature is not expired and is valid
        //
        require(
            weeziCore.isValidSignatureDate(params._timestamp),
            "EXPIRED_PRICE_DATA"
        );

        bytes32 dataHash = keccak256(
            abi.encodePacked(
                params._tokenRequestId,
                params._serviceFee,
                params._timestamp
            )
        );

        require(
            weeziCore.isValidSignature(dataHash, params._signature),
            "INVALID_SIGNATURE"
        );
        _;
    }

    /**
     * @notice Initialize Depositor app contract
     * @param _tokenRequest TokenRequest address
     * @param _weeziCore WeeziCore address
     */
    function initialize(address _tokenRequest, address _weeziCore)
        external
        onlyInit
    {
        require(isContract(_tokenRequest), ERROR_ADDRESS_NOT_CONTRACT);
        require(isContract(_weeziCore), ERROR_ADDRESS_NOT_CONTRACT);

        tokenRequest = TokenRequest(_tokenRequest);
        weeziCore = IWeeziCore(_weeziCore);

        initialized();
    }

    /**
     * @notice Set the Token Request to `_tokenRequest`.
     * @param _tokenRequest The new token request address
     */
    function setTokenRequest(address _tokenRequest)
        external
        auth(SET_TOKEN_REQUEST_ROLE)
    {
        require(isContract(_tokenRequest), ERROR_ADDRESS_NOT_CONTRACT);

        tokenRequest = TokenRequest(_tokenRequest);
        emit SetTokenRequest(_tokenRequest);
    }

    /**
     * @notice Set the WeeziCore to `_weeziCore`.
     * @param _weeziCore The new weeziCore address
     */
    function setWeeziCore(address _weeziCore)
        external
        auth(SET_WEEZICORE_ROLE)
    {
        require(isContract(_weeziCore), ERROR_ADDRESS_NOT_CONTRACT);

        weeziCore = IWeeziCore(_weeziCore);
        emit SetWeeziCore(_weeziCore);
    }

    /**
     * @notice Approve  `self.getTokenRequest(_tokenRequestId): address`'s request for `@tokenAmount(self.getToken(): address, self.getTokenRequest(_tokenRequestId): (address, address, uint, <uint>))` in exchange for `@tokenAmount(self.getTokenRequest(_tokenRequestId): (address, <address>), self.getTokenRequest(_tokenRequestId): (address, address, <uint>, uint))`
     * @dev This function's FINALISE_TOKEN_REQUEST_ROLE permission is typically given exclusively to a forwarder.
     *      This function requires the MINT_ROLE permission on the TokenManager specified.
     */
    function finaliseTokenRequest(FinaliseTokenRequestParams params)
        public
        withValidData(params)
        auth(FINALISE_TOKEN_REQUEST_ROLE)
        nonReentrant
    {
        require(
            params._tokenRequestId < tokenRequest.nextTokenRequestId(),
            ERROR_NO_REQUEST
        );
        (
            address requesterAddress,
            address depositToken,
            uint256 depositAmount,
            uint256 requestAmount
        ) = tokenRequest.getTokenRequest(params._tokenRequestId);

        tokenRequest.finaliseTokenRequest(params._tokenRequestId);

        if (weeziCore.getFeeWalletAddress() != address(0)) {
            if (depositAmount > 0) {
                require(
                    depositAmount > params._serviceFee,
                    ERROR_SERVICE_FEE_TOO_HIGH
                );

                if (params._serviceFee > 0) {
                    Vault(tokenRequest.vault()).transfer(
                        depositToken,
                        weeziCore.getFeeWalletAddress(),
                        params._serviceFee
                    );
                }
            }
        }

        emit TokenRequestFinalised(
            params._tokenRequestId,
            requesterAddress,
            depositToken,
            depositAmount,
            address(tokenRequest.tokenManager().token()),
            requestAmount,
            weeziCore.getFeeWalletAddress(),
            params._serviceFee
        );
    }
}