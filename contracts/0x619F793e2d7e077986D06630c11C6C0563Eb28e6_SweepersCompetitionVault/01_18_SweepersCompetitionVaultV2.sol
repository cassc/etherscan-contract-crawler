// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';
import './external/gelato/OpsReady.sol';
import './interfaces/IDust.sol';
import './interfaces/IRandomizer.sol';


contract SweepersCompetitionVault is ReentrancyGuard, Ownable, IERC721Receiver, IERC1155Receiver, OpsReady {

    IDust public DUST;
    IRandomizer public randomizer;
    address payable public sweepersTreasury;
    address payable public sweepersBuyer;
    address payable public legacyTreasury;

    address payable public Dev;
    address payable public VRF;
    uint256 public DevFee = 0.0025 ether;
    uint256 public VRFCost = .005 ether;
    uint256 public SettlementCost = .02 ether;
    uint256 public gasLimit = 60 gwei;

    uint16 public sweepersCut = 8500;
    uint16 public legacyCut = 500;
    uint16 public devCut = 1000;        

    // The competition info
    struct Comp {
        // The Token ID for the listed NFT
        uint256 tokenId;
        // The Contract Address for the listed NFT
        address contractAddress;
        // The NFT Contract Type
        bool is1155;
        // The entry limit per wallet 
        uint32 entryLimit;
        // The number of entries received
        uint32 numberEntries;
        // The raffle entry method restrictions
        bool onlyDust;
        bool onlyEth;
        // The statuses of the competition
        bool blind;
        bool revealed;
        bool settled;
        bool failed;
        string hiddenImage;
        string openseaSlug;
    }
    Comp[] public comps;

    struct CompETHPrices {
        uint8 id;
        uint32 numEntries;
        uint256 price;
    }
    struct CompDustPrices {
        uint8 id;
        uint32 numEntries;
        uint256 price;
    }
    mapping(uint256 => CompETHPrices[5]) public ethPrices;
    mapping(uint256 => CompDustPrices[5]) public dustPrices;

    struct CompTargetParams {
        uint256 minimumETH;
        uint256 maximumETH;
        uint32 startTime;
        uint32 endTime;
        uint32 entryCap;
        bool useETHParams;
        bool useTimeParams;
        bool useEntryParams; 
    }
    mapping(uint256 => CompTargetParams) public targetParams;

    struct CompDistributions {
        uint256 treasury;
        uint256 legacy;
        uint256 dev;
    }
    mapping(uint256 => CompDistributions) public distributions;

    mapping(uint256 => uint256) public cancelDate;
    uint256 public refundPeriod = 30 days;

    mapping(uint256 => uint256) public ethCollected;
    mapping(uint256 => uint256) public dustCollected;
    mapping(uint256 => uint256) public ethDistributed;

    struct Entries {
        address entrant;
        uint32 entryLength;
    }
    mapping(uint256 => Entries[]) public entries;

    struct UserEntries {
        uint32 numberEntries;
        uint256 ethSpent;
        uint256 dustSpent;
        bool claimed;
    }
    mapping(bytes32 => UserEntries) public userData;
    mapping(uint256 => bool) public winnerRequested;
    mapping(uint256 => address) public compWinner;
    mapping(uint256 => bytes32) public pickWinnerTaskId;

    struct Referrer {
        bool isValidReferrer;
        uint256 referralCount;
        uint256 referralCredits;
        address referrerAddress;
    }
    mapping(bytes32 => Referrer) public referrer;
    mapping(address => bytes32) public referrerId;
    mapping(bytes32 => mapping(address => uint256)) public referralExpiration;
    mapping(address => bool) public hasBonused;
    uint256 public earningRate = 10;
    uint32 public referreeBonus = 1;
    uint256 public referralPeriod = 30 days;

    modifier onlySweepersTreasury() {
        require(msg.sender == sweepersTreasury || msg.sender == owner() || msg.sender == sweepersBuyer, "Sender not allowed");
        _;
    }

    modifier onlyRandomizer() {
        require(msg.sender == address(randomizer), "Sender not allowed");
        _;
    }

    event CompCreated(uint256 indexed CompId, uint32 startTime, uint32 endTime, address indexed NFTContract, uint256 indexed TokenId, uint32 entryLimit, uint32 entryCap, bool BlindComp);
    event CompSettled(uint256 indexed CompId, address indexed NFTProjectAddress, uint256 tokenID, address winner, uint256 winningEntryID);
    event CompFailed(uint256 indexed CompId, address indexed NFTProjectAddress, uint256 tokenID);
    event CompCanceled(uint256 indexed CompId, address indexed NFTProjectAddress, uint256 tokenID);
    event EntryReceived(uint256 indexed CompId, address sender, uint256 entriesBought, uint256 currentEntryLength, uint256 compPriceId, bool withETH, uint256 timeStamp);
    event RefundClaimed(uint256 indexed CompId, uint256 ethRefunded, uint256 dustRefunded, address Entrant);
    event Received(address indexed From, uint256 Amount);

    constructor(
        address _dust,
        address payable _ops,
        IRandomizer _randomizer,
        address payable _vrf,
        address payable _legacy,
        address payable _treasury,
        address payable _buyer
    ) OpsReady(_ops) {
        DUST = IDust(_dust);
        Dev = payable(msg.sender);
        randomizer = _randomizer;
        VRF = _vrf;
        legacyTreasury = _legacy;
        sweepersTreasury = _treasury;
        sweepersBuyer = _buyer;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return interfaceID == this.supportsInterface.selector;
    }

    function setDust(address _dust) external onlyOwner {
        DUST = IDust(_dust);
    }

    function setDev(address _dev, uint256 _devFee) external onlyOwner {
        Dev = payable(_dev);
        DevFee = _devFee;
    }

    function setDistribution(uint16 _sweepersCut, uint16 _legacyCut, uint16 _devCut) external onlyOwner {
        require(_sweepersCut + _legacyCut + _devCut == 10000);
        sweepersCut = _sweepersCut;
        legacyCut = _legacyCut;
        devCut = _devCut;  
    }

    function setRefundPeriod(uint256 _period) external onlyOwner {
        refundPeriod = _period;
    }

    function setReferralParams(uint256 _rate, uint16 _bonus, uint256 _period) external onlyOwner {
        earningRate = _rate;
        referreeBonus = _bonus;
        referralPeriod = _period;
    }

    function updateSweepersTreasury(address payable _treasury) external onlyOwner {
        sweepersTreasury = _treasury;
    }

    function updateSweepersBuyer(address payable _buyer) external onlyOwner {
        sweepersBuyer = _buyer;
    }

    function updateLegacyTreasury(address payable _treasury) external onlyOwner {
        legacyTreasury = _treasury;
    }

    function updateSettlementParams(
        IRandomizer _randomizer, 
        address payable _vrf, 
        uint256 _vrfCost, 
        uint256 _settlementCost, 
        uint256 _gasLimit 
    ) external onlyOwner {
        randomizer = _randomizer;
        VRF = _vrf;
        VRFCost = _vrfCost;
        SettlementCost = _settlementCost;
        gasLimit = _gasLimit;
    }

    function createComp(
        address _nftContract, 
        uint256 _tokenId, 
        bool _is1155, 
        bool _blind,
        uint32 _startTime, 
        uint32 _endTime, 
        uint16 _entryCap,
        uint16 _entryLimit,
        uint256 _minETH,
        uint256 _maxETH,
        CompDustPrices[] calldata _dustPrices,
        CompETHPrices[] calldata _ethPrices,
        bool _onlyDust,
        bool _onlyEth,
        bool _ethParams,
        bool _timeParams,
        bool _entryParams,
        string calldata _hiddenImage, 
        string calldata _slug
    ) external payable onlySweepersTreasury returns (uint256) {
        require(msg.value == VRFCost + SettlementCost);
        require(_ethParams || _timeParams || _entryParams);
        require(_blind ? _tokenId == 0 : _tokenId != 0);

        Comp memory _comp = Comp({
            tokenId : _tokenId,
            contractAddress : _nftContract,
            is1155 : _is1155,
            entryLimit : _entryLimit,
            numberEntries : 0,
            onlyDust : _onlyDust,
            onlyEth : _onlyEth,
            blind : _blind,
            revealed : _blind ? false : true,
            settled : false,
            failed : false,
            hiddenImage : _blind ? _hiddenImage : 'null',
            openseaSlug : _slug
        });

        comps.push(_comp);

        if(!_onlyDust) {
            require(_ethPrices.length > 0, "No prices");

            for (uint256 i = 0; i < _ethPrices.length; i++) {
                require(_ethPrices[i].numEntries > 0, "numEntries is 0");

                CompETHPrices memory p = CompETHPrices({
                    id: uint8(i),
                    numEntries: _ethPrices[i].numEntries,
                    price: _ethPrices[i].price
                });

                ethPrices[comps.length - 1][i] = p;
            }
        }

        if(!_onlyEth) {
            require(_dustPrices.length > 0, "No prices");

            for (uint256 i = 0; i < _dustPrices.length; i++) {
                require(_dustPrices[i].numEntries > 0, "numEntries is 0");

                CompDustPrices memory d = CompDustPrices({
                    id: uint8(i),
                    numEntries: _dustPrices[i].numEntries,
                    price: _dustPrices[i].price
                });

                dustPrices[comps.length - 1][i] = d;
            }
        }

        targetParams[comps.length - 1] = CompTargetParams({
            minimumETH : _minETH,
            maximumETH : _maxETH,
            startTime : _startTime,
            endTime : _endTime,
            entryCap : _entryCap,
            useETHParams : _ethParams,
            useTimeParams : _timeParams,
            useEntryParams : _entryParams 
        });

        if(!_blind) {
            if(_is1155) {
                IERC1155(_nftContract).safeTransferFrom(msg.sender, address(this), _tokenId, 1, "");
            } else {
                IERC721(_nftContract).safeTransferFrom(msg.sender, address(this), _tokenId);
            }
        }

        startPickWinnerTask(comps.length - 1);

        emit CompCreated(comps.length - 1, _startTime, _endTime, _nftContract, _tokenId, _entryLimit, _entryCap, _blind);

        return comps.length - 1;
    }

    function updateBlindComp(uint32 _id, uint256 _tokenId) external onlySweepersTreasury {
        require(comps[_id].tokenId == 0, "Comp already updated");
        require(_tokenId != 0);
        comps[_id].tokenId = _tokenId;
        if(comps[_id].is1155) {
            IERC1155(comps[_id].contractAddress).safeTransferFrom(msg.sender, address(this), _tokenId, 1, "");
        } else {
            IERC721(comps[_id].contractAddress).safeTransferFrom(msg.sender, address(this), _tokenId);
        }
    }

    function updateBlindComp1155(uint256 _id, bool _is1155) external onlySweepersTreasury {
        comps[_id].is1155 = _is1155;
    }

    function updateBlindImage(uint256 _id, string calldata _hiddenImage) external onlySweepersTreasury {
        comps[_id].hiddenImage = _hiddenImage;
    }

    function updateOpenseaSlug(uint256 _id, string calldata _slug) external onlySweepersTreasury {
        comps[_id].openseaSlug = _slug;
    }

    function updateCompEndTime(uint256 _id, uint32 _endTime) external onlySweepersTreasury {
        targetParams[_id].endTime = _endTime;
    }

    function emergencyCancelComp(uint32 _id) external payable onlySweepersTreasury {
        require(compStatus(_id) == 1 || compStatus(_id) == 0, 'Can only cancel active comps');
        require(msg.value == ethDistributed[_id], 'Must send back enough ETH to cover refunds');
        _cancelComp(_id);
    }

    function _cancelComp(uint32 _id) private {
        comps[_id].failed = true;
        cancelDate[_id] = block.timestamp;

        stopTask(pickWinnerTaskId[_id]);

        if (comps[_id].tokenId != 0) {
            if(comps[_id].is1155) {
                IERC1155(comps[_id].contractAddress).safeTransferFrom(address(this), Dev, comps[_id].tokenId, 1, "");
            } else {
                IERC721(comps[_id].contractAddress).safeTransferFrom(address(this), Dev, comps[_id].tokenId);
            }
        }
        delete distributions[_id];
        delete ethDistributed[_id];
        emit CompCanceled(_id, address(comps[_id].contractAddress), comps[_id].tokenId);
    }

    function claimRefund(uint256 _id) external nonReentrant {
        require(compStatus(_id) == 4, "not failed");
        require(
            block.timestamp <= cancelDate[_id] + refundPeriod,
            "claim time expired"
        );

        UserEntries storage claimData = userData[
            keccak256(abi.encode(msg.sender, _id))
        ];

        require(claimData.claimed == false, "already refunded");

        ethCollected[_id] -= claimData.ethSpent;
        dustCollected[_id] -= claimData.dustSpent;

        claimData.claimed = true;
        if(claimData.ethSpent > 0) {
            (bool sentETH, ) = msg.sender.call{value: claimData.ethSpent}("");
            require(sentETH, "Fail send refund");
        }

        if(claimData.dustSpent > 0) { DUST.mint(msg.sender, claimData.dustSpent); }

        emit RefundClaimed(_id, claimData.ethSpent, claimData.dustSpent, msg.sender);
    }

    function emergencyRescueNFT(address _nft, uint256 _tokenId, bool _is1155) external onlySweepersTreasury {
        if(_is1155) {
            IERC1155(_nft).safeTransferFrom(address(this), Dev, _tokenId, 1, "");
        } else {
            IERC721(_nft).safeTransferFrom(address(this), Dev, _tokenId);
        }
    }

    function emergencyRescueETH(uint256 amount) external onlySweepersTreasury {
        (bool sent,) = Dev.call{value: amount}("");
        require(sent);
    }

    /**
     * @notice Buy a competition entry using DUST.
     */
    function buyEntryDust(uint256 _id, uint256 _priceId, bytes32 _referrer, uint16 _redeemEntries) external payable nonReentrant {
        require(compStatus(_id) == 1, 'Comp is not Active');
        require(!comps[_id].onlyEth, 'Comp is restricted to only ETH');

        CompDustPrices memory priceStruct = getDustPriceStructForId(_id, _priceId);
        require(msg.value == DevFee, 'Fee not covered');
        
        bytes32 hash = keccak256(abi.encode(msg.sender, _id));
        require(userData[hash].numberEntries + priceStruct.numEntries + _redeemEntries <= comps[_id].entryLimit, "Bought too many entries"); 
        if(targetParams[_id].useEntryParams) require(comps[_id].numberEntries + priceStruct.numEntries + _redeemEntries <= targetParams[_id].entryCap, "Not enough entries remaining"); 

        uint32 _numEntries = priceStruct.numEntries;
        if(_redeemEntries > 0) {
            bytes32 _ref = referrerId[msg.sender];
            require(referrer[_ref].referralCredits >= _redeemEntries * 1000, 'Not enough credits available');
            referrer[_ref].referralCredits -= (_redeemEntries * 1000);
            _numEntries += _redeemEntries;
        }

        if(referrer[_referrer].isValidReferrer) {
            if(referralExpiration[_referrer][msg.sender] == 0) {
                referralExpiration[_referrer][msg.sender] = block.timestamp + referralPeriod;
            }
            if(block.timestamp < referralExpiration[_referrer][msg.sender]) {
                referrer[_referrer].referralCount += priceStruct.numEntries;
                referrer[_referrer].referralCredits += (priceStruct.numEntries) * 1000 / earningRate;
                if(!hasBonused[msg.sender]) {
                    _numEntries += referreeBonus;
                    hasBonused[msg.sender] = true;
                }
            }
        }

        Entries memory entryBought = Entries({
            entrant: msg.sender,
            entryLength: comps[_id].numberEntries + _numEntries
        });
        entries[_id].push(entryBought);
  
        dustCollected[_id] += priceStruct.price;
        comps[_id].numberEntries += _numEntries;

        userData[hash].numberEntries += _numEntries;
        userData[hash].dustSpent += priceStruct.price;

        DUST.burnFrom(msg.sender, priceStruct.price);
        
        (bool sent,) = Dev.call{value: DevFee}("");
        require(sent);

        emit EntryReceived(
            _id,
            msg.sender,
            priceStruct.numEntries,
            _numEntries,
            _priceId,
            false,
            block.timestamp
        );
    }

    /**
     * @notice Buy a competition entry using ETH.
     */
    function buyEntryETH(uint32 _id, uint256 _priceId, bytes32 _referrer, uint16 _redeemEntries) external payable nonReentrant {
        require(compStatus(_id) == 1, 'Comp is not Active');
        require(!comps[_id].onlyDust, 'Comp is restricted to only DUST');

        CompETHPrices memory priceStruct = getEthPriceStructForId(_id, _priceId);
        require(msg.value == priceStruct.price, 'msg.value must be equal to the price');
        
        bytes32 hash = keccak256(abi.encode(msg.sender, _id));
        require(userData[hash].numberEntries + priceStruct.numEntries + _redeemEntries <= comps[_id].entryLimit, "Bought too many entries");
        if(targetParams[_id].useEntryParams) require(comps[_id].numberEntries + priceStruct.numEntries + _redeemEntries <= targetParams[_id].entryCap, "Not enough entries remaining"); 

        uint32 _numEntries = priceStruct.numEntries;
        if(_redeemEntries > 0) {
            bytes32 _ref = referrerId[msg.sender];
            require(referrer[_ref].referralCredits >= _redeemEntries * 1000, 'Not enough credits available');
            referrer[_ref].referralCredits -= (_redeemEntries * 1000);
            _numEntries += _redeemEntries;
        }

        if(referrer[_referrer].isValidReferrer) {
            if(referralExpiration[_referrer][msg.sender] == 0) {
                referralExpiration[_referrer][msg.sender] = block.timestamp + referralPeriod;
            }
            if(block.timestamp < referralExpiration[_referrer][msg.sender]) {
                referrer[_referrer].referralCount += priceStruct.numEntries;
                referrer[_referrer].referralCredits += (priceStruct.numEntries) * 1000 / earningRate;
                if(!hasBonused[msg.sender]) {
                    _numEntries += referreeBonus;
                    hasBonused[msg.sender] = true;
                }
            }
        }

        // add the entry to the entries array
        Entries memory entryBought = Entries({
            entrant: msg.sender,
            entryLength: comps[_id].numberEntries + _numEntries
        });
        entries[_id].push(entryBought);
  
        comps[_id].numberEntries += _numEntries;

        userData[hash].numberEntries += _numEntries;
        userData[hash].ethSpent += priceStruct.price;

        if(targetParams[_id].useETHParams) {
            if(ethCollected[_id] < targetParams[_id].minimumETH) {
                (bool sent,) = sweepersBuyer.call{value: msg.value}("");
                require(sent);
                ethDistributed[_id] += msg.value * (10000 - sweepersCut) / 10000;
            } else if(ethDistributed[_id] > 0) {
                uint256 adjuster = msg.value * (sweepersCut) / 10000;
                if(ethDistributed[_id] > adjuster) {
                    ethDistributed[_id] -= adjuster;
                } else {
                    distributions[_id].treasury += adjuster - ethDistributed[_id];
                    ethDistributed[_id] = 0;
                }
            } else {
                distributions[_id].treasury += msg.value * sweepersCut / 10000;
            }
        } else {
            distributions[_id].treasury += msg.value * sweepersCut / 10000;
        }
        distributions[_id].legacy += msg.value * legacyCut / 10000;
        distributions[_id].dev += msg.value * devCut / 10000;

        ethCollected[_id] += priceStruct.price;

        emit EntryReceived(
            _id,
            msg.sender,
            _numEntries,
            comps[_id].numberEntries,
            _priceId,
            true,
            block.timestamp
        );
    }

    function enrollReferrer(string calldata referralCode) external nonReentrant {
        require(referrerId[msg.sender] == 0, 'User already enrolled');
        bytes32 bytesCode = bytes32(bytes(referralCode)); 
        require(referrer[bytesCode].referralCount == 0 && !referrer[bytesCode].isValidReferrer && bytesCode != 0, 'referralCode already exists');
        referrerId[msg.sender] = bytesCode;
        referrer[bytesCode].isValidReferrer = true;
        referrer[bytesCode].referrerAddress = msg.sender;
    }

    function removeReferrer(bytes32 _referrerId, address _referrer) external onlySweepersTreasury {
        delete referrer[_referrerId];
        delete referrerId[_referrer];
    }

    function suspendReferrer(bytes32 _referrer) external onlySweepersTreasury {
        referrer[_referrer].isValidReferrer = false;
    }

    function getEthPriceStructForId(uint256 _idRaffle, uint256 _id)
        internal
        view
        returns (CompETHPrices memory)
    {
        if (ethPrices[_idRaffle][_id].id == _id) {
            return ethPrices[_idRaffle][_id];
        }
        return CompETHPrices({id: 0, numEntries: 0, price: 0});
    }

    function getDustPriceStructForId(uint256 _idRaffle, uint256 _id)
        internal
        view
        returns (CompDustPrices memory)
    {
        if (dustPrices[_idRaffle][_id].id == _id) {
            return dustPrices[_idRaffle][_id];
        }
        return CompDustPrices({id: 0, numEntries: 0, price: 0});
    }

    function startPickWinnerTask(uint256 _id) internal {
        pickWinnerTaskId[_id] = IOps(ops).createTaskNoPrepayment(
            address(this), 
            this._pickCompWinner.selector,
            address(this),
            abi.encodeWithSelector(this.canPickChecker.selector, _id),
            ETH
        );
    }

    function canPickChecker(uint256 _id) 
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        canExec = (compStatus(_id) == 2 && !winnerRequested[_id] && comps[_id].tokenId != 0);
        
        execPayload = abi.encodeWithSelector(
            this._pickCompWinner.selector,
            _id
        );
    }

    function pickCompWinner(uint256 _id) public {
        require(compStatus(_id) == 2, 'cant be settled now');
        require(comps[_id].tokenId != 0, 'update comp tokenID');
        
        if(comps[_id].numberEntries > 0) {
            randomizer.requestRandomWords(_id);
            winnerRequested[_id] = true;
            (bool sent,) = VRF.call{value: VRFCost}("");
            require(sent);
        } else {
            winnerRequested[_id] = true;
            _closeComp(_id);
        }
    }

    function _pickCompWinner(uint256 _id) external onlyOps {
        require(tx.gasprice < gasLimit, 'cant be settled now');
        (uint256 fee, address feeToken) = IOps(ops).getFeeDetails();
        _transfer(fee, feeToken);

        pickCompWinner(_id);

        stopTask(pickWinnerTaskId[_id]);
    }

    function earlyCloseConp(uint256 _id) external onlySweepersTreasury {
        require(targetParams[_id].useETHParams, 'Can only close with ETH params');
        require(ethCollected[_id] >= targetParams[_id].minimumETH && ethDistributed[_id] == 0, 'Can not close with current funding');
        require(comps[_id].tokenId != 0, 'Update comp tokenID');

        randomizer.requestRandomWords(_id);
        winnerRequested[_id] = true;
        (bool sent,) = VRF.call{value: VRFCost}("");
        require(sent);
    }
    
    /**
     * @notice Settle a competition, finalizing the bid and transferring the NFT to the winner.
     * @dev If there are no entries, the competition is failed and can be relisted.
     */
    function settleComp(uint256 _id) external {
        uint256 seed = randomizer.getRandomWord();
        _settleComp(_id, seed);
    }

    function autoSettleComp(uint256 _id, uint256 seed) external onlyRandomizer {
        _settleComp(_id, seed);
    }

    function _settleComp(uint256 _id, uint256 seed) internal {
        require(compStatus(_id) == 6, 'cant be settled now');
        require(comps[_id].numberEntries > 0, 'comp has no entries');

        comps[_id].settled = true;
        uint256 entryIndex = seed % comps[_id].numberEntries + 1;
        uint256 winnerIndex = findWinner(entries[_id], entryIndex);
        address _compWinner = entries[_id][winnerIndex].entrant;
        compWinner[_id] = _compWinner;

        if(comps[_id].is1155) {
            IERC1155(comps[_id].contractAddress).safeTransferFrom(address(this), _compWinner, comps[_id].tokenId, 1, "");
        } else {
            IERC721(comps[_id].contractAddress).safeTransferFrom(address(this), _compWinner, comps[_id].tokenId);
        }

        if(comps[_id].blind) {
            comps[_id].revealed = true;
        }

        if(distributions[_id].treasury > 0) {
            (bool sent1,) = sweepersTreasury.call{value: distributions[_id].treasury}("");
            require(sent1);
        }
        if(distributions[_id].legacy > 0) {
            (bool sent2,) = legacyTreasury.call{value: distributions[_id].legacy}("");
            require(sent2);
        }
        if(distributions[_id].dev > 0) {
            (bool sent3,) = Dev.call{value: distributions[_id].dev}("");
            require(sent3);
        }

        emit CompSettled(_id, address(comps[_id].contractAddress), comps[_id].tokenId, _compWinner, entryIndex);
    }

    function _closeComp(uint256 _id) internal {
        require(compStatus(_id) == 2, 'cant be settled now');
        require(comps[_id].numberEntries == 0, 'comp has entries');

        comps[_id].settled = true;
        uint256 entryIndex;
        address _compWinner;

        comps[_id].failed = true;
        if (comps[_id].tokenId != 0) {
            if(comps[_id].is1155) {
                IERC1155(comps[_id].contractAddress).safeTransferFrom(address(this), Dev, comps[_id].tokenId, 1, "");
            } else {
                IERC721(comps[_id].contractAddress).safeTransferFrom(address(this), Dev, comps[_id].tokenId);
            }
        }
        emit CompFailed(_id, address(comps[_id].contractAddress), comps[_id].tokenId);
        
        emit CompSettled(_id, address(comps[_id].contractAddress), comps[_id].tokenId, _compWinner, entryIndex);
    }

    function findWinner(Entries[] storage _array, uint256 entryIndex) internal pure returns (uint256) {
        Entries[] memory array = _array;
        
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid].entryLength > entryIndex) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1].entryLength == entryIndex) {
            return low - 1;
        } else {
            return low;
        }
    }

    function compStatus(uint256 _id) public view returns (uint8) {
        if (winnerRequested[_id] && !comps[_id].settled) {
            return 6; // AWAITING SETTLEMENT - Winner selected and awaiting settlement    
        }
        if (comps[_id].failed) {
            return 4; // FAILED - not sold by end time
        }
        if (comps[_id].settled) {
            return 3; // SUCCESS - Entrant won 
        }
        if(targetParams[_id].useTimeParams) {    
            if (block.timestamp >= targetParams[_id].endTime && comps[_id].tokenId == 0) {
                return 5; // AWAITING TOKENID - Comp finished
            }
            if (block.timestamp >= targetParams[_id].endTime || comps[_id].numberEntries == targetParams[_id].entryCap) {
                return 2; // AWAITING WINNER SELECTION - Comp finished
            }
            if (block.timestamp <= targetParams[_id].endTime && block.timestamp >= targetParams[_id].startTime) {
                return 1; // ACTIVE - entries enabled
            }
        } else if(targetParams[_id].useETHParams) {
            if (ethCollected[_id] >= targetParams[_id].maximumETH && comps[_id].tokenId == 0) {
                return 5; // AWAITING TOKENID - Comp finished
            }
            if (ethCollected[_id] >= targetParams[_id].maximumETH) {
                return 2; // AWAITING WINNER SELECTION - Comp finished
            }
            if (ethCollected[_id] < targetParams[_id].maximumETH && block.timestamp >= targetParams[_id].startTime) {
                return 1; // ACTIVE - entries enabled
            }
        } else if(targetParams[_id].useEntryParams) {
            if (comps[_id].numberEntries >= targetParams[_id].entryCap && comps[_id].tokenId == 0) {
                return 5; // AWAITING TOKENID - Comp finished
            }
            if (comps[_id].numberEntries >= targetParams[_id].entryCap) {
                return 2; // AWAITING WINNER SELECTION - Comp finished
            }
            if (comps[_id].numberEntries < targetParams[_id].entryCap && block.timestamp >= targetParams[_id].startTime) {
                return 1; // ACTIVE - entries enabled
            }
        }
        return 0; // QUEUED - awaiting start time
    }

    function getEntries(uint256 _id) external view returns (Entries[] memory) {
        return entries[_id];
    }

    function getUserData(uint256 _id, address _entrant) external view returns (UserEntries memory) {
        return userData[keccak256(abi.encode(_entrant, _id))];
    }

    function getCompsLength() external view returns (uint256) {
        return comps.length;
    }

    function getReferrerData(address _referrer) external view returns(bool isReferrer, bytes32 code, uint256 numReferrals, uint256 numCredits) {
        code = referrerId[_referrer];
        if(code == 0) {
            return (false, 0x0, 0, 0);
        } else {
            isReferrer = referrer[code].isValidReferrer;
            numReferrals = referrer[code].referralCount;
            numCredits = referrer[code].referralCredits;
        }
    }

    function stopTask(bytes32 taskId) internal {
        IOps(ops).cancelTask(taskId);
    }

    function manualStopTask(bytes32 taskId) external onlySweepersTreasury {
        stopTask(taskId);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}