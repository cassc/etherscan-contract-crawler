// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;
pragma abicoder v2;
import "./interfaces/IBTSPeriphery.sol";
import "./interfaces/IBTSCore.sol";
import "./interfaces/IBMCPeriphery.sol";
import "./libraries/Types.sol";
import "./libraries/RLPEncodeStruct.sol";
import "./libraries/RLPDecodeStruct.sol";
import "./libraries/ParseAddress.sol";
import "./libraries/String.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
   @title BTSPeriphery contract
   @dev This contract is used to handle communications among BMCService and BTSCore contract
   @dev OwnerUpgradeable has been removed. This contract does not have its own Owners
        Instead, BTSCore manages ownership roles.
        Thus, BTSPeriphery should call btsCore.isOwner() and pass an address for verification
        in case of implementing restrictions, if needed, in the future. 
*/
contract BTSPeriphery is Initializable, IBTSPeriphery {
    using RLPEncodeStruct for Types.TransferCoin;
    using RLPEncodeStruct for Types.ServiceMessage;
    using RLPEncodeStruct for Types.Response;
    using RLPDecodeStruct for bytes;
    using SafeMathUpgradeable for uint256;
    using ParseAddress for address;
    using ParseAddress for string;
    using String for string;
    using String for uint256;

    /**   @notice Sends a receipt to user
        The `_from` sender
        The `_to` receiver.
        The `_sn` sequence number of service message.
        The `_assetDetails` a list of `_coinName` and `_value`  
    */
    event TransferStart(
        address indexed _from,
        string _to,
        uint256 _sn,
        Types.AssetTransferDetail[] _assetDetails
    );

    /**   @notice Sends a final notification to a user
        The `_from` sender
        The `_sn` sequence number of service message.
        The `_code` response code, i.e. RC_OK = 0, RC_ERR = 1
        The `_response` message of response if error  
    */
    event TransferEnd(
        address indexed _from,
        uint256 _sn,
        uint256 _code,
        string _response
    );

    /**
        Used to log the state of successful incoming transaction
    */
    event TransferReceived(
        string indexed _from,
        address indexed _to,
        uint256 _sn,
        Types.Asset[] _assetDetails
    );

    /**   @notice Notify that BSH contract has received unknown response
        The `_from` sender
        The `_sn` sequence number of service message
    */
    event UnknownResponse(string _from, uint256 _sn);

    IBMCPeriphery private bmc;
    IBTSCore internal btsCore;
    mapping(uint256 => Types.PendingTransferCoin) public requests; // a list of transferring requests
    string public constant serviceName = "bts"; //    BSH Service Name

    uint256 private constant RC_OK = 0;
    uint256 private constant RC_ERR = 1;
    uint256 private serialNo; //  a counter of sequence number of service message
    uint256 private numOfPendingRequests;

    mapping(address => bool) public blacklist;
    mapping(string => uint) public tokenLimit;
    uint256 private constant MAX_BATCH_SIZE = 15;

    modifier onlyBMC() {
        require(msg.sender == address(bmc), "Unauthorized");
        _;
    }

    modifier onlyBTSCore() {
        require(msg.sender == address(btsCore), "Unauthorized");
        _;
    }

    function initialize(address _bmc, address _btsCore) public initializer {
        bmc = IBMCPeriphery(_bmc);
        btsCore = IBTSCore(_btsCore);
        tokenLimit[btsCore.getNativeCoinName()] = type(uint256).max;
    }

    /**
     @notice Check whether BTSPeriphery has any pending transferring requests
     @return true or false
    */
    function hasPendingRequest() external view override returns (bool) {
        return numOfPendingRequests != 0;
    }

    /**
        @notice Add users to blacklist
        @param _address Address to blacklist
    */
    function addToBlacklist(string[] memory _address) external {
        require(msg.sender == address(this), "Unauthorized");
        require(_address.length <= MAX_BATCH_SIZE, "BatchMaxSizeExceed");
        for (uint i = 0; i < _address.length; i++) {
            try this.checkParseAddress(_address[i]) {
                blacklist[_address[i].parseAddress()] = true;
            } catch {
                revert("InvalidAddress");
            }
        }
    }

    /**
        @notice Remove users from blacklist
        @param _address Address to blacklist
    */
    function removeFromBlacklist(string[] memory _address) external {
        require(msg.sender == address(this), "Unauthorized");
        require(_address.length <= MAX_BATCH_SIZE, "BatchMaxSizeExceed");
        for (uint i = 0; i < _address.length; i++) {
            try this.checkParseAddress(_address[i]) {
                address addr = _address[i].parseAddress();
                require(blacklist[addr], "UserNotBlacklisted");
                delete blacklist[addr];
            } catch {
                revert("InvalidAddress");
            }
        }
    }

    /**
        @notice Set token limit
        @param _coinNames    Array of names of the coin
        @param _tokenLimits  Token limit for coins
    */
    function setTokenLimit(
        string[] memory _coinNames,
        uint256[] memory _tokenLimits
    ) external override {
        require(msg.sender == address(this) || msg.sender == address(btsCore), "Unauthorized");
        require(_coinNames.length == _tokenLimits.length,"InvalidParams");
        require(_coinNames.length <= MAX_BATCH_SIZE, "BatchMaxSizeExceed");
        for(uint i = 0; i < _coinNames.length; i++) {
            tokenLimit[_coinNames[i]] = _tokenLimits[i];
        }
    }

    function sendServiceMessage(
        address _from,
        string memory _to,
        string[] memory _coinNames,
        uint256[] memory _values,
        uint256[] memory _fees
    ) external override onlyBTSCore {
        //  Send Service Message to BMC
        //  If '_to' address is an invalid BTP Address format
        //  VM throws an error and revert(). Thus, it does not need
        //  a try_catch at this point
        (string memory _toNetwork, string memory _toAddress) = _to
            .splitBTPAddress();
        Types.Asset[] memory _assets = new Types.Asset[](_coinNames.length);
        Types.AssetTransferDetail[]
            memory _assetDetails = new Types.AssetTransferDetail[](
                _coinNames.length
            );
        for (uint256 i = 0; i < _coinNames.length; i++) {
            _assets[i] = Types.Asset(_coinNames[i], _values[i]);
            _assetDetails[i] = Types.AssetTransferDetail(
                _coinNames[i],
                _values[i],
                _fees[i]
            );
        }

        serialNo++;

        //  Because `stack is too deep`, must create `_strFrom` to waive this error
        //  `_strFrom` is a string type of an address `_from`
        string memory _strFrom = _from.toString();
        bmc.sendMessage(
            _toNetwork,
            serviceName,
            serialNo,
            Types
                .ServiceMessage(
                    Types.ServiceType.REQUEST_COIN_TRANSFER,
                    Types
                        .TransferCoin(_strFrom, _toAddress, _assets)
                        .encodeTransferCoinMsg()
                )
                .encodeServiceMessage()
        );
        //  Push pending tx into Record list
        requests[serialNo] = Types.PendingTransferCoin(
            _strFrom,
            _to,
            _coinNames,
            _values,
            _fees
        );
        numOfPendingRequests++;
        emit TransferStart(_from, _to, serialNo, _assetDetails);
    }

    /**
     @notice BSH handle BTP Message from BMC contract
     @dev Caller must be BMC contract only
     @param _from    An originated network address of a request
     @param _svc     A service name of BSH contract     
     @param _sn      A serial number of a service request 
     @param _msg     An RLP message of a service request/service response
    */
    function handleBTPMessage(
        string calldata _from,
        string calldata _svc,
        uint256 _sn,
        bytes calldata _msg
    ) external override onlyBMC {
        require(_svc.compareTo(serviceName) == true, "InvalidSvc");
        Types.ServiceMessage memory _sm = _msg.decodeServiceMessage();
        string memory errMsg;

        if (_sm.serviceType == Types.ServiceType.REQUEST_COIN_TRANSFER) {
            Types.TransferCoin memory _tc = _sm.data.decodeTransferCoinMsg();
            //  checking receiving address whether is a valid address
            //  revert() if not a valid one
            try this.checkParseAddress(_tc.to) {
                try this.handleRequestService(_tc.to, _tc.assets) {
                    sendResponseMessage(
                        Types.ServiceType.REPONSE_HANDLE_SERVICE,
                        _from,
                        _sn,
                        "",
                        RC_OK
                    );
                    emit TransferReceived(
                        _from,
                        _tc.to.parseAddress(),
                        _sn,
                        _tc.assets
                    );
                    return;
                } catch Error(string memory _err) {
                    errMsg = _err;
                }
            } catch {
                errMsg = "InvalidAddress";
            }
            sendResponseMessage(
                Types.ServiceType.REPONSE_HANDLE_SERVICE,
                _from,
                _sn,
                errMsg,
                RC_ERR
            );
        } else if (_sm.serviceType == Types.ServiceType.BLACKLIST_MESSAGE) {
            Types.BlacklistMessage memory _bm = _sm.data.decodeBlackListMsg();
            string[] memory addresses = _bm.addrs;

            if (_bm.serviceType == Types.BlacklistService.ADD_TO_BLACKLIST ) {
                try this.addToBlacklist(addresses) {
                    // send message to bmc
                    sendResponseMessage(
                        Types.ServiceType.BLACKLIST_MESSAGE,
                        _from,
                        _sn,
                        "AddedToBlacklist",
                        RC_OK
                    );
                    return;
                } catch {
                    errMsg = "ErrorAddToBlackList";
                }
            } else if (_bm.serviceType == Types.BlacklistService.REMOVE_FROM_BLACKLIST) {
                try this.removeFromBlacklist(addresses) {
                    // send message to bmc
                    sendResponseMessage(
                        Types.ServiceType.BLACKLIST_MESSAGE,
                        _from,
                        _sn,
                        "RemovedFromBlacklist",
                        RC_OK
                    );
                    return;
                } catch {
                    errMsg = "ErrorRemoveFromBlackList";
                }
            } else {
                errMsg = "BlacklistServiceTypeErr";
            }

            sendResponseMessage(
                Types.ServiceType.BLACKLIST_MESSAGE,
                _from,
                _sn,
                errMsg,
                RC_ERR
            );

        } else if (_sm.serviceType == Types.ServiceType.CHANGE_TOKEN_LIMIT) {
            Types.TokenLimitMessage memory _tl = _sm.data.decodeTokenLimitMsg();
            string[] memory coinNames = _tl.coinName;
            uint256[] memory tokenLimits = _tl.tokenLimit;

            try this.setTokenLimit(coinNames, tokenLimits) {
                sendResponseMessage(
                    Types.ServiceType.CHANGE_TOKEN_LIMIT,
                    _from,
                    _sn,
                    "ChangeTokenLimit",
                    RC_OK
                );
                return;
            } catch {
                errMsg = "ErrorChangeTokenLimit";
                sendResponseMessage(
                    Types.ServiceType.CHANGE_TOKEN_LIMIT,
                    _from,
                    _sn,
                    errMsg,
                    RC_ERR
                );
            }

        } else if (
            _sm.serviceType == Types.ServiceType.REPONSE_HANDLE_SERVICE
        ) {
            //  Check whether '_sn' is pending state
            require(bytes(requests[_sn].from).length != 0, "InvalidSN");
            Types.Response memory response = _sm.data.decodeResponse();
            //  @dev Not implement try_catch at this point
            //  + If RESPONSE_REQUEST_SERVICE:
            //      If RC_ERR, BTSCore proceeds a refund. If a refund is failed, BTSCore issues refundable Balance
            //      If RC_OK:
            //      - requested coin = native -> update aggregation fee (likely no issue)
            //      - requested coin = wrapped coin -> BTSCore calls itself to burn its tokens and update aggregation fee (likely no issue)
            //  The only issue, which might happen, is BTSCore's token balance lower than burning amount
            //  If so, there might be something went wrong before
            //  + If RESPONSE_FEE_GATHERING
            //      If RC_ERR, BTSCore saves charged fees back to `aggregationFee` state mapping variable
            //      If RC_OK: do nothing
            handleResponseService(_sn, response.code, response.message);
        } else if (_sm.serviceType == Types.ServiceType.UNKNOWN_TYPE) {
            emit UnknownResponse(_from, _sn);
        } else {
            //  If none of those types above, BSH responds a message of RES_UNKNOWN_TYPE
            sendResponseMessage(
                Types.ServiceType.UNKNOWN_TYPE,
                _from,
                _sn,
                "Unknown",
                RC_ERR
            );
        }
    }

    /**
     @notice BSH handle BTP Error from BMC contract
     @dev Caller must be BMC contract only 
     @param _svc     A service name of BSH contract     
     @param _sn      A serial number of a service request 
     @param _code    A response code of a message (RC_OK / RC_ERR)
     @param _msg     A response message
    */
    function handleBTPError(
        string calldata, /* _src */
        string calldata _svc,
        uint256 _sn,
        uint256 _code,
        string calldata _msg
    ) external override onlyBMC {
        require(_svc.compareTo(serviceName) == true, "InvalidSvc");
        require(bytes(requests[_sn].from).length != 0, "InvalidSN");
        string memory _emitMsg = string("errCode: ")
            .concat(", errMsg: ")
            .concat(_code.toString())
            .concat(_msg);
        handleResponseService(_sn, RC_ERR, _emitMsg);
    }

    function handleResponseService(
        uint256 _sn,
        uint256 _code,
        string memory _msg
    ) private {
        address _caller = requests[_sn].from.parseAddress();
        uint256 loop = requests[_sn].coinNames.length;
        require(loop <= MAX_BATCH_SIZE, "BatchNaxSizeExceed");
        for (uint256 i = 0; i < loop; i++) {
            btsCore.handleResponseService(
                _caller,
                requests[_sn].coinNames[i],
                requests[_sn].amounts[i],
                requests[_sn].fees[i],
                _code
            );
        }
        delete requests[_sn];
        numOfPendingRequests--;
        emit TransferEnd(_caller, _sn, _code, _msg);
    }

    /**
     @notice Handle a list of minting/transferring coins/tokens
     @dev Caller must be BMC contract only 
     @param _to          An address to receive coins/tokens    
     @param _assets      A list of requested coin respectively with an amount
    */
    function handleRequestService(
        string memory _to,
        Types.Asset[] memory _assets
    ) external {
        require(msg.sender == address(this), "Unauthorized");
        require(_assets.length <= MAX_BATCH_SIZE, "BatchMaxSizeExceed");
        for (uint256 i = 0; i < _assets.length; i++) {
            require(
                btsCore.isValidCoin(_assets[i].coinName) == true,
                "UnregisteredCoin"
            );
            checkTransferRestrictions(
                    _assets[i].coinName,
                    _to.parseAddress(),
                    _assets[i].value)
            ;
            //  @dev There might be many errors generating by BTSCore contract
            //  which includes also low-level error
            //  Thus, must use try_catch at this point so that it can return an expected response
            try
                btsCore.mint(
                    _to.parseAddress(),
                    _assets[i].coinName,
                    _assets[i].value
                )
            {} catch {
                revert("TransferFailed");
            }
        }
    }

    function sendResponseMessage(
        Types.ServiceType _serviceType,
        string memory _to,
        uint256 _sn,
        string memory _msg,
        uint256 _code
    ) private {
        bmc.sendMessage(
            _to,
            serviceName,
            _sn,
            Types
                .ServiceMessage(
                    _serviceType,
                    Types.Response(_code, _msg).encodeResponse()
                )
                .encodeServiceMessage()
        );
    }

    /**
     @notice BSH handle Gather Fee Message request from BMC contract
     @dev Caller must be BMC contract only
     @param _fa     A BTP address of fee aggregator
     @param _svc    A name of the service
    */
    function handleFeeGathering(string calldata _fa, string calldata _svc)
        external
        override
        onlyBMC
    {
        require(_svc.compareTo(serviceName) == true, "InvalidSvc");
        //  If adress of Fee Aggregator (_fa) is invalid BTP address format
        //  revert(). Then, BMC will catch this error
        //  @dev this part simply check whether `_fa` is splittable (`prefix` + `_net` + `dstAddr`)
        //  checking validity of `_net` and `dstAddr` does not belong to BTSPeriphery's scope
        _fa.splitBTPAddress();
        btsCore.transferFees(_fa);
    }

    //  @dev Solidity does not allow to use try_catch with internal function
    //  Thus, this is a work-around solution
    //  Since this function is basically checking whether a string address
    //  can be parsed to address type. Hence, it would not have any restrictions
    function checkParseAddress(string calldata _to) external pure {
        _to.parseAddress();
    }

    function checkTransferRestrictions(
        string memory _coinName,
        address _user,
        uint256 _value
    ) public view override {
        require(!blacklist[_user],"Blacklisted");
        require(tokenLimit[_coinName] >= _value ,"LimitExceed");
    }
}