// SPDX-License-Identifier: MIT

//   _   _  ____  _   _   _                            _                     _   _____
//  | \ | |/ __ \| \ | | | |                          | |                   | | |  __ \
//  |  \| | |  | |  \| | | |     __ _ _   _ _ __   ___| |__  _ __   __ _  __| | | |__) | __ _____  ___   _
//  | . ` | |  | | . ` | | |    / _` | | | | '_ \ / __| '_ \| '_ \ / _` |/ _` | |  ___/ '__/ _ \ \/ / | | |
//  | |\  | |__| | |\  | | |___| (_| | |_| | | | | (__| | | | |_) | (_| | (_| | | |   | | | (_) >  <| |_| |
//  |_| \_|\____/|_| \_| |______\__,_|\__,_|_| |_|\___|_| |_| .__/ \__,_|\__,_| |_|   |_|  \___/_/\_\\__, |
//                                                          | |                                       __/ |
//                                                          |_|                                      |___/

pragma solidity ^0.8.16;

import "./data/DataType.sol";
import "./tools/LaunchpadBuy.sol";
import "./enum/LaunchpadProxyEnums.sol";
import "./interface/ILaunchpadProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// NON Launchpad Proxy
contract NONLaunchpadProxy is ILaunchpadProxy, Ownable, ReentrancyGuard {
    // example: proxy id, bytes4(keccak256("NONLaunchpadProxyV1"));V2 V3 V4 V5 ...
    bytes4 internal constant PROXY_ID =
        bytes4(keccak256("NONLaunchpadProxyV3"));
    // authority address to call this contract, (buy must call from external)
    mapping(address => bool) authorities;
    // default
    bool checkAuthority = true;
    // numLaunchpads
    uint256 public numLaunchpads;
    // launchpads
    mapping(bytes4 => DataType.Launchpad) launchpads;
    // launchpad dynamic vars
    mapping(bytes4 => DataType.LaunchpadVar) launchpadVars;
    event ReceiptChange(
        bytes4 indexed launchpadId,
        address feeReceipts,
        address operator
    );
    event RoundsBuyTokenPriceChange(
        bytes4 indexed launchpadId,
        uint256 roundsIdx,
        address token,
        uint256 price
    );
    event ChangeAuthorizedAddress(address indexed target, bool addOrRemove);
    event SetLaunchpadController(address controllerAdmin);
    event AddLaunchpadData(
        bytes4 indexed launchpadId,
        bytes4 proxyId,
        address nftAddress,
        uint256 roundsIdx,
        address receipts,
        uint8 nftType,
        address sourceAddress
    );
    event AddLaunchpadRoundData(DataType.LaunchpadRounds round);
    event SetLaunchpadERC20AssetProxy(
        bytes4 proxyId,
        bytes4 indexed launchpadId,
        address erc20AssetProxy
    );
    event WhiteListAdd(
        bytes4 indexed launchpadId,
        address[] whitelist,
        uint8[] buyNum
    );
    event ChangeRoundsStartIdAndSaleQty(
        bytes4 proxyId,
        bytes4 indexed launchpadId,
        uint256 roundsIdx,
        uint256 startId,
        uint256 saleQty
    );
    event LaunchpadBuyEvt(
        bytes4 indexed proxyId,
        bytes4 launchpadId,
        uint256 roundsIdx,
        uint256 quantity,
        uint256 perIdQuantity,
        address from,
        address to,
        address buyToken,
        address nftAddress,
        uint256 payValue
    );

    /**
     * LaunchpadBuy - main method
     */
    function launchpadBuy(
        address sender,
        bytes4 launchpadId,
        uint256 roundsIdx,
        uint256 quantity
    ) external payable override nonReentrant returns (uint256) {
        if (checkAuthority) {
            require(
                authorities[_msgSender()],
                LaunchpadProxyEnums.LPD_ONLY_AUTHORITIES_ADDRESS
            );
        } else {
            require(
                sender == _msgSender(),
                LaunchpadProxyEnums.SENDER_MUST_TX_CALLER
            );
        }
        uint256 paymentValue = LaunchpadBuy.processBuy(
            launchpads[launchpadId],
            launchpadVars[launchpadId].accountRoundsStats[
                genRoundsAddressKey(sender, roundsIdx)
            ],
            roundsIdx,
            sender,
            quantity
        );
        emit LaunchpadBuyEvt(
            PROXY_ID,
            launchpadId,
            roundsIdx,
            quantity,
            launchpads[launchpadId].roundss[roundsIdx].perIdQuantity,
            launchpads[launchpadId].sourceAddress,
            sender,
            launchpads[launchpadId].roundss[roundsIdx].buyToken,
            launchpads[launchpadId].targetContract,
            paymentValue
        );
        return paymentValue;
    }

    /**
     * LaunchpadSetBaseURI
     */
    function launchpadSetBaseURI(
        address sender,
        bytes4 launchpadId,
        string memory baseURI
    ) external override nonReentrant {
        if (checkAuthority) {
            require(
                authorities[_msgSender()],
                LaunchpadProxyEnums.LPD_ONLY_AUTHORITIES_ADDRESS
            );
        } else {
            require(
                sender == _msgSender(),
                LaunchpadProxyEnums.SENDER_MUST_TX_CALLER
            );
        }
        bytes4 paramTable = launchpads[launchpadId].abiSelectorAndParam[
            DataType.ABI_IDX_BASEURI_PARAM_TABLE
        ];
        bytes4 selector = launchpads[launchpadId].abiSelectorAndParam[
            DataType.ABI_IDX_BASEURI_SELECTOR
        ];
        bytes memory proxyCallData;
        if (paramTable == bytes4(0x00000000)) {
            proxyCallData = abi.encodeWithSelector(selector, baseURI);
        }
        (bool didSucceed, bytes memory returnData) = launchpads[launchpadId]
            .targetContract
            .call(proxyCallData);
        if (!didSucceed) {
            revert(
                string(
                    abi.encodePacked(
                        LaunchpadProxyEnums
                            .LPD_ROUNDS_CALL_OPEN_CONTRACT_FAILED,
                        LaunchpadProxyEnums.LPD_SEPARATOR,
                        returnData
                    )
                )
            );
        }
    }

    /**
     * OnlyLPADController
     */
    function onlyLPADController(address msgSender, address controllerAdmin)
        internal
        view
    {
        require(
            owner() == msgSender || msgSender == controllerAdmin,
            LaunchpadProxyEnums.LPD_ONLY_CONTROLLER_COLLABORATOR_OWNER
        );
    }

    /**
     * ChangeAuthorizedAddress
     */
    function changeAuthorizedAddress(address target, bool opt)
        external
        onlyOwner
    {
        authorities[target] = opt;
        emit ChangeAuthorizedAddress(target, opt);
    }

    /**
     * SetCheckAuthority
     */
    function setCheckAuthority(bool checkAuth) external onlyOwner {
        checkAuthority = checkAuth;
    }

    /**
     * AddLaunchpadAndRounds, onlyOwner can call this (Only the platform has the core functions)
     */
    function addLaunchpadAndRounds(
        string memory name,
        address controllerAdmin,
        address targetContract,
        address receipts,
        bytes4[4] memory abiSelectorAndParam,
        DataType.LaunchpadRounds[] memory roundss,
        bool lockParam,
        bool enable,
        uint8 nftType,
        address sourceAddress
    ) external onlyOwner returns (bytes4) {
        numLaunchpads += 1;
        bytes4 launchpadId = bytes4(keccak256(bytes(name)));
        require(
            launchpads[launchpadId].id == 0,
            LaunchpadProxyEnums.LPD_ID_EXISTS
        );
        launchpads[launchpadId].enable = enable;
        launchpads[launchpadId].id = launchpadId;
        launchpads[launchpadId].nftType = nftType;
        launchpads[launchpadId].receipts = receipts;
        launchpads[launchpadId].lockParam = lockParam;
        launchpads[launchpadId].sourceAddress = sourceAddress;
        launchpads[launchpadId].targetContract = targetContract;
        launchpads[launchpadId].controllerAdmin = controllerAdmin;
        launchpads[launchpadId].abiSelectorAndParam = abiSelectorAndParam;
        require(roundss.length > 0, LaunchpadProxyEnums.LPD_ROUNDS_HAVE_NO);
        for (uint256 i = 0; i < roundss.length; i++) {
            checkAddLaunchpadRounds(roundss[i]);
            launchpads[launchpadId].roundss.push(roundss[i]);
            emit AddLaunchpadRoundData(roundss[i]);
        }
        uint256 idx = roundss.length - 1;
        emit AddLaunchpadData(
            launchpadId,
            PROXY_ID,
            targetContract,
            idx,
            receipts,
            nftType,
            sourceAddress
        );
        return launchpadId;
    }

    /**
     * UpdateLaunchpadController
     */
    function updateLaunchpadController(bytes4 launchpadId, address controller)
        external
        onlyOwner
    {
        launchpads[launchpadId].controllerAdmin = controller;
        emit SetLaunchpadController(controller);
    }

    /**
     * UpdateLaunchpadReceiptsParam
     */
    function updateLaunchpadReceiptsParam(bytes4 launchpadId, address receipts)
        external
    {
        onlyLPADController(
            _msgSender(),
            launchpads[launchpadId].controllerAdmin
        );
        require(
            !launchpads[launchpadId].lockParam,
            LaunchpadProxyEnums.LPD_PARAM_LOCKED
        );
        require(
            launchpads[launchpadId].id > 0,
            LaunchpadProxyEnums.LPD_INVALID_ID
        );
        launchpads[launchpadId].receipts = receipts;
        emit ReceiptChange(launchpads[launchpadId].id, receipts, msg.sender);
    }

    /**
     * UpdateLaunchpadEnableAndLocked enable-means can buy; lock-means can't change param by controller address;
     */
    function updateLaunchpadEnableAndLocked(
        bytes4 launchpadId,
        bool enable,
        bool lock
    ) external {
        onlyLPADController(
            _msgSender(),
            launchpads[launchpadId].controllerAdmin
        );
        if (!lock) {
            require(
                _msgSender() != launchpads[launchpadId].controllerAdmin,
                LaunchpadProxyEnums.LPD_ONLY_COLLABORATOR_OWNER
            );
        }
        launchpads[launchpadId].lockParam = lock;
        launchpads[launchpadId].enable = enable;
    }

    /**
     * AddLaunchpadRounds
     */
    function addLaunchpadRounds(
        bytes4 launchpadId,
        DataType.LaunchpadRounds memory rounds
    ) external {
        onlyLPADController(
            _msgSender(),
            launchpads[launchpadId].controllerAdmin
        );
        checkAddLaunchpadRounds(rounds);
        launchpads[launchpadId].roundss.push(rounds);
    }

    /**
     * UpdateRoundsStartTimeAndFlags
     */
    function updateRoundsStartTimeAndFlags(
        bytes4 launchpadId,
        uint256 roundsIdx,
        uint256 saleStart,
        uint256 saleEnd,
        uint256 whitelistStart
    ) external {
        onlyLPADController(
            _msgSender(),
            launchpads[launchpadId].controllerAdmin
        );
        launchpads[launchpadId].roundss[roundsIdx].saleStart = uint32(
            saleStart
        );
        launchpads[launchpadId].roundss[roundsIdx].saleEnd = uint32(saleEnd);
        launchpads[launchpadId].roundss[roundsIdx].whiteListSaleStart = uint32(
            whitelistStart
        );
    }

    /**
     * UpdateRoundsSupplyParam
     */
    function updateRoundsSupplyParam(
        bytes4 launchpadId,
        uint256 roundsIdx,
        uint256 maxSupply,
        uint256 maxBuyQtyPerAccount,
        uint256 maxBuyNumOnce,
        uint256 buyIntervalBlock,
        uint256 perIdQuantity
    ) external {
        onlyLPADController(
            _msgSender(),
            launchpads[launchpadId].controllerAdmin
        );

        launchpads[launchpadId].roundss[roundsIdx].perIdQuantity = uint32(
            perIdQuantity
        );
        launchpads[launchpadId].roundss[roundsIdx].maxSupply = uint32(
            maxSupply
        );
        launchpads[launchpadId].roundss[roundsIdx].maxBuyQtyPerAccount = uint32(
            maxBuyQtyPerAccount
        );
        launchpads[launchpadId].roundss[roundsIdx].buyInterval = uint32(
            buyIntervalBlock
        );
        launchpads[launchpadId].roundss[roundsIdx].maxBuyNumOnce = uint32(
            maxBuyNumOnce
        );
    }

    /**
     * UpdateBuyTokenAndPrice
     */
    function updateBuyTokenAndPrice(
        bytes4 launchpadId,
        uint256 roundsIdx,
        address buyToken,
        uint256 buyPrice
    ) external {
        onlyLPADController(
            _msgSender(),
            launchpads[launchpadId].controllerAdmin
        );
        require(
            !launchpads[launchpadId].lockParam,
            LaunchpadProxyEnums.LPD_PARAM_LOCKED
        );
        require(
            launchpads[launchpadId].id > 0,
            LaunchpadProxyEnums.LPD_INVALID_ID
        );
        launchpads[launchpadId].roundss[roundsIdx].buyToken = buyToken;
        launchpads[launchpadId].roundss[roundsIdx].price = uint128(buyPrice);
        emit RoundsBuyTokenPriceChange(
            launchpads[launchpadId].id,
            roundsIdx,
            buyToken,
            buyPrice
        );
    }

    /**
     * UpdateTargetContractAndABIAndType
     */
    function updateTargetContractAndABIAndType(
        bytes4 launchpadId,
        address target,
        uint256 nftType,
        address sourceAddress,
        bytes4[] memory abiSelector
    ) external {
        onlyLPADController(
            _msgSender(),
            launchpads[launchpadId].controllerAdmin
        );
        require(
            abiSelector.length == DataType.ABI_IDX_MAX,
            LaunchpadProxyEnums.LPD_ROUNDS_ABI_ARRAY_LEN
        );
        require(
            isValidAddress(target),
            LaunchpadProxyEnums.LPD_ROUNDS_TARGET_CONTRACT_INVALID
        );
        require(
            abiSelector.length == DataType.ABI_IDX_MAX,
            LaunchpadProxyEnums.LPD_ROUNDS_ABI_ARRAY_LEN
        );
        require(
            abiSelector[DataType.ABI_IDX_BUY_SELECTOR] != bytes4(0),
            LaunchpadProxyEnums.LPD_ROUNDS_ABI_BUY_SELECTOR_INVALID
        );
        launchpads[launchpadId].targetContract = target;
        launchpads[launchpadId].nftType = nftType;
        launchpads[launchpadId].sourceAddress = sourceAddress;
        for (uint256 i = 0; i < DataType.ABI_IDX_MAX; i++) {
            launchpads[launchpadId].abiSelectorAndParam[i] = abiSelector[i];
        }
    }

    /**
     * UpdateStartTokenIdAndSaleQuantity, be careful to set startTokenId & SaleQuantity in the running launchpad
     */
    function updateStartTokenIdAndSaleQuantity(
        bytes4 launchpadId,
        uint256 roundsIdx,
        uint256 startTokenId,
        uint256 saleQuantity
    ) external {
        onlyLPADController(
            _msgSender(),
            launchpads[launchpadId].controllerAdmin
        );
        require(
            !launchpads[launchpadId].lockParam,
            LaunchpadProxyEnums.LPD_PARAM_LOCKED
        );
        launchpads[launchpadId].roundss[roundsIdx].startTokenId = uint128(
            startTokenId
        );
        launchpads[launchpadId].roundss[roundsIdx].saleQuantity = uint32(
            saleQuantity
        );
        emit ChangeRoundsStartIdAndSaleQty(
            PROXY_ID,
            launchpadId,
            roundsIdx,
            startTokenId,
            saleQuantity
        );
    }

    /**
     * AddRoundsWhiteLists
     */
    function addRoundsWhiteLists(
        bytes4 launchpadId,
        uint256 roundsIdx,
        DataType.WhiteListModel model,
        address[] memory wls,
        uint8[] memory wln
    ) external {
        DataType.Launchpad storage launchpad = launchpads[launchpadId];
        onlyLPADController(_msgSender(), launchpad.controllerAdmin);
        require(launchpad.id > 0, LaunchpadProxyEnums.LPD_INVALID_ID);
        require(
            wls.length == wln.length,
            LaunchpadProxyEnums.LPD_INPUT_ARRAY_LEN_NOT_MATCH
        );
        for (uint256 i = 0; i < wls.length; i++) {
            require(
                launchpad.roundss[roundsIdx].maxBuyQtyPerAccount >= wln[i],
                LaunchpadProxyEnums.LPD_ROUNDS_ACCOUNT_MAX_BUY_LIMIT
            );
            // use address + roundsIdx make a uint256 unique key
            launchpadVars[launchpadId]
                .accountRoundsStats[genRoundsAddressKey(wls[i], roundsIdx)]
                .whiteListBuyNum = wln[i];
        }
        launchpads[launchpadId].roundss[roundsIdx].whiteListModel = model;

        emit WhiteListAdd(launchpadId, wls, wln);
    }

    /**
     * IsInWhiteList, is account in whitelist?  0 - not in whitelist;  > 0 means buy number,
     */
    function isInWhiteList(
        bytes4 launchpadId,
        uint256 roundsIdx,
        address[] calldata wls
    ) external view override returns (uint8[] memory wln) {
        wln = new uint8[](wls.length);
        for (uint256 i = 0; i < wls.length; i++) {
            // use address + roundsIdx make a uint256 unique key
            wln[i] = launchpadVars[launchpadId]
                .accountRoundsStats[genRoundsAddressKey(wls[i], roundsIdx)]
                .whiteListBuyNum;
        }
    }

    /**
     * CheckAddLaunchpadRounds
     */
    function checkAddLaunchpadRounds(DataType.LaunchpadRounds memory rounds)
        internal
        pure
    {
        require(
            rounds.maxSupply > 0,
            LaunchpadProxyEnums.LPD_ROUNDS_MAX_SUPPLY_INVALID
        );
        require(
            rounds.saleQuantity == 0,
            LaunchpadProxyEnums.LPD_ROUNDS_SALE_QUANTITY
        );
        require(
            (rounds.maxBuyQtyPerAccount > 0) &&
                (rounds.maxBuyQtyPerAccount <= rounds.maxSupply),
            LaunchpadProxyEnums.LPD_ROUNDS_MAX_BUY_QTY_INVALID
        );
        require(
            rounds.saleStart > 0,
            LaunchpadProxyEnums.LPD_ROUNDS_SALE_START_TIME_INVALID
        );
        require(
            rounds.saleEnd == 0 || rounds.saleEnd > rounds.saleStart,
            LaunchpadProxyEnums.LPD_ROUNDS_SALE_END_TIME_INVALID
        );
        require(
            rounds.price >= 0,
            LaunchpadProxyEnums.LPD_ROUNDS_PRICE_INVALID
        );
        require(
            rounds.perIdQuantity > 0,
            LaunchpadProxyEnums.LPD_ROUNDS_PER_ID_QUANTITY_INVALID
        );
    }

    /**
     * GetLaunchpadInfo
     */
    function getLaunchpadInfo(bytes4 launchpadId)
        external
        view
        returns (
            bool[] memory boolData,
            uint256[] memory intData,
            address[] memory addressData,
            bytes[] memory bytesData
        )
    {
        DataType.Launchpad memory lpad = launchpads[launchpadId];
        boolData = new bool[](2);
        boolData[0] = lpad.enable;
        boolData[1] = lpad.lockParam;

        bytesData = new bytes[](1);
        bytesData[0] = abi.encodePacked(lpad.id);

        addressData = new address[](5);
        addressData[0] = lpad.controllerAdmin;
        addressData[1] = address(this);
        addressData[2] = lpad.receipts;
        addressData[3] = lpad.targetContract;
        addressData[4] = lpad.sourceAddress;

        intData = new uint256[](2);
        intData[0] = lpad.roundss.length;
        intData[1] = lpad.nftType;
    }

    /**
     * GetLaunchpadRoundsInfo
     */
    function getLaunchpadRoundsInfo(bytes4 launchpadId, uint256 roundsIdx)
        external
        view
        returns (
            bool[] memory boolData,
            uint256[] memory intData,
            address[] memory addressData
        )
    {
        DataType.Launchpad memory lpad = launchpads[launchpadId];
        if (lpad.id == 0 || roundsIdx >= lpad.roundss.length) {
            return (boolData, intData, addressData);
        }

        DataType.LaunchpadRounds memory lpadRounds = lpad.roundss[roundsIdx];

        boolData = new bool[](1);
        boolData[0] = lpad.enable;

        intData = new uint256[](10);
        intData[0] = lpadRounds.saleStart;
        intData[1] = uint256(lpadRounds.whiteListModel);
        intData[2] = lpadRounds.maxSupply;
        intData[3] = lpadRounds.saleQuantity;
        intData[4] = lpadRounds.maxBuyQtyPerAccount;
        intData[5] = lpadRounds.price;
        intData[6] = lpadRounds.startTokenId;
        intData[7] = lpadRounds.saleEnd;
        intData[8] = lpadRounds.whiteListSaleStart;
        intData[9] = lpadRounds.perIdQuantity;

        addressData = new address[](2);
        addressData[0] = lpadRounds.buyToken;
        addressData[1] = address(this);
    }

    /**
     * GetAccountInfoInLaunchpad
     */
    function getAccountInfoInLaunchpad(
        address sender,
        bytes4 launchpadId,
        uint256 roundsIdx
    ) external view returns (bool[] memory boolData, uint256[] memory intData) {
        DataType.Launchpad memory lpad = launchpads[launchpadId];
        DataType.AccountRoundsStats memory accountStats = launchpadVars[
            launchpadId
        ].accountRoundsStats[genRoundsAddressKey(sender, roundsIdx)];
        if (lpad.id == 0 || roundsIdx >= lpad.roundss.length) {
            return (boolData, intData);
        }

        DataType.LaunchpadRounds memory lpadRounds = lpad.roundss[roundsIdx];

        boolData = new bool[](2);
        boolData[0] = lpadRounds.whiteListModel != DataType.WhiteListModel.NONE;
        boolData[1] = isWhiteListModel(
            lpadRounds.whiteListModel,
            lpadRounds.whiteListSaleStart,
            lpadRounds.saleStart
        );

        intData = new uint256[](3);
        intData[0] = accountStats.totalBuyQty;
        // next buy time of this address
        intData[1] = accountStats.lastBuyTime + lpadRounds.buyInterval;
        // this whitelist user max can buy quantity
        intData[2] = accountStats.whiteListBuyNum;
    }

    /**
     * IsWhiteListModel
     */
    function isWhiteListModel(
        DataType.WhiteListModel whiteListModel,
        uint32 whiteListSaleStart,
        uint32 saleStart
    ) internal view returns (bool) {
        if (whiteListModel == DataType.WhiteListModel.NONE) {
            return false;
        }
        if (whiteListSaleStart != 0) {
            if (block.timestamp >= saleStart) {
                return false;
            }
        }
        return true;
    }

    /**
     * GetProxyId
     */
    function getProxyId() external pure override returns (bytes4) {
        return PROXY_ID;
    }

    /**
     * IsValidAddress
     */
    function isValidAddress(address addr) public pure returns (bool) {
        return address(addr) == addr && address(addr) != address(0);
    }

    /**
     * GenRoundsAddressKey, convert roundsIdx(96) + address(160) to a uint256 key
     */
    function genRoundsAddressKey(address account, uint256 roundsIdx)
        public
        pure
        returns (uint256)
    {
        return
            (uint256(uint160(account)) &
                0x000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) |
            (roundsIdx << 160);
    }
}