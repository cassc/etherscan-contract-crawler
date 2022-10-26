// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol';
import './external/gelato/OpsReady.sol';
import './interfaces/IDust.sol';
import './interfaces/INFT.sol';
import './interfaces/IRandomizer.sol';


contract SweepersCompetitionVault is ReentrancyGuard, Ownable, IERC721Receiver, IERC1155Receiver, OpsReady {

    INFT public SWEEPERS;
    IDust public DUST;
    IRandomizer public randomizer;
    address payable public sweepersTreasury;
    address payable public legacyTreasury;

    address public admin;

    address payable public Dev;
    address payable public VRF;
    uint256 public DevFee = 0.0025 ether;
    uint256 public VRFCost = .005 ether;
    uint256 public SettlementCost = .02 ether;
    uint256 public gasLimit = 60 gwei;
    uint256 public autoSettleTimer = 3 minutes;

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
        // The time that the competition started
        uint32 startTime;
        // The time that the competition is scheduled to end
        uint32 endTime;
        // The entry prices for the competition
        uint256 entryPriceDust;
        uint256 entryPriceETH;
        // The tx cost to buy an entry in eth
        uint256 entryCost;
        // The total entries allowed for a competition
        uint16 entryCap;
        // The entry limit per wallet 
        uint16 entryLimit;
        // The number of entries received
        uint16 numberEntries;
        // The statuses of the competition
        bool blind;
        bool settled;
        bool failed;
        string hiddenImage;
        string openseaSlug;
    }
    mapping(uint32 => Comp) public compId;
    uint32 private currentCompId = 0;
    uint32 private currentEntryId = 0;
    uint32 public activeCompCount;
    mapping(uint32 => uint256) public ethCollected;

    struct Entries {
        address entrant;
        uint32 compId;
        bool useETH;
        bool winner;
    }
    mapping(uint32 => Entries) public entryId;
    mapping(uint32 => uint32[]) public compEntries;
    mapping(uint32 => mapping(address => uint32[])) public userEntries;
    mapping(uint32 => bool) public winnerRequested;
    mapping(uint32 => uint256) public winnerRequestedTime;
    mapping(uint32 => address) public compWinner;
    bool public mustHold;

    modifier holdsSweeper() {
        require(!mustHold || SWEEPERS.balanceOf(msg.sender) > 0, "Must hold a Sweeper");
        _;
    }

    modifier onlySweepersTreasury() {
        require(msg.sender == sweepersTreasury || msg.sender == owner() || msg.sender == admin, "Sender not allowed");
        _;
    }

    modifier onlyRandomizer() {
        require(msg.sender == address(randomizer), "Sender not allowed");
        _;
    }

    event CompCreated(uint32 indexed CompId, uint32 startTime, uint32 endTime, address indexed NFTContract, uint256 indexed TokenId, uint32 entryLimit, uint32 entryCap, uint256 entryPriceDust, uint256 entryPriceETH, bool BlindComp);
    event CompSettled(uint32 indexed CompId, address indexed NFTProjectAddress, uint256 tokenID, address winner, uint32 winningEntryID, bool withETH);
    event CompFailed(uint32 indexed CompId, address indexed NFTProjectAddress, uint256 tokenID);
    event CompCanceled(uint32 indexed CompId, address indexed NFTProjectAddress, uint256 tokenID);
    event EntryReceived(uint32 indexed EntryIds, uint32 indexed CompId, address sender, uint256 entryPrice, bool withETH);
    event Received(address indexed From, uint256 Amount);

    constructor(
        address _sweepers,
        address _dust,
        address payable _ops,
        IRandomizer _randomizer,
        address payable _vrf,
        address payable _legacy
    ) OpsReady(_ops) {
        DUST = IDust(_dust);
        SWEEPERS = INFT(_sweepers);
        Dev = payable(msg.sender);
        randomizer = _randomizer;
        VRF = _vrf;
        legacyTreasury = _legacy;
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

    function setSweepers(address _sweepers) external onlyOwner {
        SWEEPERS = INFT(_sweepers);
    }

    function setDust(address _dust) external onlyOwner {
        DUST = IDust(_dust);
    }

    function setDev(address _dev, uint256 _devFee) external onlyOwner {
        Dev = payable(_dev);
        DevFee = _devFee;
    }

    function setDistribution(uint16 _sweepersCut, uint16 _legacyCut, uint16 _devCut) external onlyOwner {
        require(_sweepersCut + _legacyCut + _devCut == 10000, "Sets must equal 10,000 / 100%");
        sweepersCut = _sweepersCut;
        legacyCut = _legacyCut;
        devCut = _devCut;  
    }

    function setMustHold(bool _flag) external onlyOwner {
        mustHold = _flag;
    }

    function updateSweepersTreasury(address payable _treasury) external onlyOwner {
        sweepersTreasury = _treasury;
    }

    function updateLegacyTreasury(address payable _treasury) external onlyOwner {
        legacyTreasury = _treasury;
    }

    function updateAdmin(address _admin) external onlyOwner {
        admin = _admin;
    }

    function updateSettlementParams(
        IRandomizer _randomizer, 
        address payable _vrf, 
        uint256 _vrfCost, 
        uint256 _settlementCost, 
        uint256 _gasLimit, 
        uint256 _autoSettleTimer
    ) external onlyOwner {
        randomizer = _randomizer;
        VRF = _vrf;
        VRFCost = _vrfCost;
        SettlementCost = _settlementCost;
        gasLimit = _gasLimit;
        autoSettleTimer = _autoSettleTimer;
    }

    function createComp(
        address _nftContract, 
        uint256 _tokenId, 
        bool _is1155, 
        uint32 _startTime, 
        uint32 _endTime, 
        uint256 _entryPriceDust,
        uint256 _entryPriceETH, 
        uint16 _entryCap,
        uint16 _entryLimit,
        string calldata _slug
    ) external onlySweepersTreasury nonReentrant {

        uint32 id = currentCompId++;
        uint256 _entryCost = (VRFCost + SettlementCost) / _entryCap;

        compId[id] = Comp({
            contractAddress : _nftContract,
            tokenId : _tokenId,
            is1155 : _is1155,
            startTime : _startTime,
            endTime : _endTime,
            entryPriceDust : _entryPriceDust,
            entryPriceETH : _entryPriceETH,
            entryCap : _entryCap,
            entryLimit : _entryLimit,
            numberEntries : 0,
            entryCost : _entryCost,
            blind : false,
            settled : false,
            failed : false,
            hiddenImage : 'null',
            openseaSlug : _slug
        });
        activeCompCount++;

        if(_is1155) {
            IERC1155(_nftContract).safeTransferFrom(msg.sender, address(this), _tokenId, 1, "");
        } else {
            IERC721(_nftContract).safeTransferFrom(msg.sender, address(this), _tokenId);
        }

        emit CompCreated(id, _startTime, _endTime, _nftContract, _tokenId, _entryLimit, _entryCap, _entryPriceDust, _entryPriceETH, false);
    }

    function createManyCompSameProject(
        address _nftContract, 
        uint256[] calldata _tokenIds, 
        bool _is1155, 
        uint32 _startTime, 
        uint32 _endTime, 
        uint256 _entryPriceDust,
        uint256 _entryPriceETH,  
        uint16 _entryCap,
        uint16 _entryLimit,
        string calldata _slug
    ) external onlySweepersTreasury nonReentrant {
        
        for(uint i = 0; i < _tokenIds.length; i++) {
            uint32 id = currentCompId++;
            uint256 _entryCost = (VRFCost + SettlementCost) / _entryCap;
            compId[id] = Comp({
                contractAddress : _nftContract,
                tokenId : _tokenIds[i],
                is1155 : _is1155,
                startTime : _startTime,
                endTime : _endTime,
                entryPriceDust : _entryPriceDust,
                entryPriceETH : _entryPriceETH,
                entryCap : _entryCap,
                entryLimit : _entryLimit,
                numberEntries : 0,
                entryCost : _entryCost,
                blind : false,
                settled : false,
                failed : false,
                hiddenImage : 'null',
                openseaSlug : _slug
            });
            activeCompCount++;

            if(_is1155) {
                IERC1155(_nftContract).safeTransferFrom(msg.sender, address(this), _tokenIds[i], 1, "");
            } else {
                IERC721(_nftContract).safeTransferFrom(msg.sender, address(this), _tokenIds[i]);
            }

            emit CompCreated(id, _startTime, _endTime, _nftContract, _tokenIds[i], _entryLimit, _entryCap, _entryPriceDust, _entryPriceETH, false);
        }
    }

    function createBlindComp(
        address _nftContract, 
        bool _is1155, 
        uint32 _startTime, 
        uint32 _endTime, 
        string calldata _hiddenImage, 
        uint256 _entryPriceDust,
        uint256 _entryPriceETH,  
        uint16 _entryCap,
        uint16 _entryLimit, 
        string calldata _slug
    ) external onlySweepersTreasury nonReentrant {

        uint32 id = currentCompId++;
        uint256 _entryCost = (VRFCost + SettlementCost) / _entryCap;

        compId[id] = Comp({
            contractAddress : _nftContract,
            tokenId : 0,
            is1155 : _is1155,
            startTime : _startTime,
            endTime : _endTime,
            entryPriceDust : _entryPriceDust,
            entryPriceETH : _entryPriceETH,
            entryCap : _entryCap,
            entryLimit : _entryLimit,
            numberEntries : 0,
            entryCost : _entryCost,
            blind : true,
            settled : false,
            failed : false,
            hiddenImage : _hiddenImage,
            openseaSlug : _slug
        });
        activeCompCount++;       

        emit CompCreated(id, _startTime, _endTime, _nftContract, 0, _entryLimit, _entryCap, _entryPriceDust, _entryPriceETH, true);
    }

    function createManyBlindCompSameProject(
        address _nftContract, 
        bool _is1155, 
        uint16 _numComps, 
        uint32 _startTime, 
        uint32 _endTime, 
        string calldata _hiddenImage, 
        uint256 _entryPriceDust,
        uint256 _entryPriceETH,  
        uint16 _entryCap,
        uint16 _entryLimit,
        string calldata _slug
    ) external onlySweepersTreasury nonReentrant {
        
        for(uint i = 0; i < _numComps; i++) {
            uint32 id = currentCompId++;
            uint256 _entryCost = (VRFCost + SettlementCost) / _entryCap;
            compId[id] = Comp({
                contractAddress : _nftContract,
                tokenId : 0,
                is1155 : _is1155,
                startTime : _startTime,
                endTime : _endTime,
                entryPriceDust : _entryPriceDust,
                entryPriceETH : _entryPriceETH,
                entryCap : _entryCap,
                entryLimit : _entryLimit,
                numberEntries : 0,
                entryCost : _entryCost,
                blind : true,
                settled : false,
                failed : false,
                hiddenImage : _hiddenImage,
                openseaSlug : _slug
            });
            activeCompCount++;

            emit CompCreated(id, _startTime, _endTime, _nftContract, 0, _entryLimit, _entryCap, _entryPriceDust, _entryPriceETH, true);
        }
    }

    function updateBlindComp(uint32 _id, uint256 _tokenId) external onlySweepersTreasury {
        require(compId[_id].tokenId == 0, "Comp already updated");
        compId[_id].tokenId = _tokenId;
        if(compId[_id].is1155) {
            IERC1155(compId[_id].contractAddress).safeTransferFrom(msg.sender, address(this), _tokenId, 1, "");
        } else {
            IERC721(compId[_id].contractAddress).safeTransferFrom(msg.sender, address(this), _tokenId);
        }
        compId[_id].blind = false;
    }

    function updateBlindComp1155(uint32 _id, bool _is1155) external onlySweepersTreasury {
        compId[_id].is1155 = _is1155;
    }

    function updateBlindImage(uint32 _id, string calldata _hiddenImage) external onlySweepersTreasury {
        compId[_id].hiddenImage = _hiddenImage;
    }

    function updateOpenseaSlug(uint32 _id, string calldata _slug) external onlySweepersTreasury {
        compId[_id].openseaSlug = _slug;
    }

    function updateCompEntryPrice(uint32 _id, uint256 _entryPriceDust, uint256 _entryPriceETH) external onlySweepersTreasury {
        compId[_id].entryPriceDust = _entryPriceDust;
        compId[_id].entryPriceETH = _entryPriceETH;
    }

    function updateCompEndTime(uint32 _id, uint32 _endTime) external onlySweepersTreasury {
        compId[_id].endTime = _endTime;
    }

    function emergencyCancelComp(uint32 _id) external onlySweepersTreasury {
        require(compStatus(_id) == 1 || compStatus(_id) == 0, 'Can only cancel active comps');
        _cancelComp(_id);
    }

    function _cancelComp(uint32 _id) private {
        compId[_id].endTime = uint32(block.timestamp);
        compId[_id].failed = true;

        uint256 entryLength = compEntries[_id].length;
        if(entryLength > 0) {
            address _entrant;
            uint256 _refundAmount;
            for(uint i = 0; i < entryLength; i++) {
                _entrant = entryId[compEntries[_id][i]].entrant;

                if(!entryId[compEntries[_id][i]].useETH) {
                    _refundAmount = compId[_id].entryPriceDust;
                    DUST.mint(_entrant, _refundAmount);
                } else {
                    _refundAmount = compId[_id].entryPriceETH;
                    payable(_entrant).transfer(_refundAmount);
                }
            }
        }

        if (!compId[_id].blind) {
            if(compId[_id].is1155) {
                IERC1155(compId[_id].contractAddress).safeTransferFrom(address(this), Dev, compId[_id].tokenId, 1, "");
            } else {
                IERC721(compId[_id].contractAddress).safeTransferFrom(address(this), Dev, compId[_id].tokenId);
            }
        }
        emit CompCanceled(_id, address(compId[_id].contractAddress), compId[_id].tokenId);
    }

    function emergencyRescueNFT(address _nft, uint256 _tokenId, bool _is1155) external onlySweepersTreasury {
        if(_is1155) {
            IERC1155(_nft).safeTransferFrom(address(this), Dev, _tokenId, 1, "");
        } else {
            IERC721(_nft).safeTransferFrom(address(this), Dev, _tokenId);
        }
    }

    function emergencyRescueETH(uint256 amount) external onlySweepersTreasury {
        Dev.transfer(amount);
    }

    /**
     * @notice Buy a competition entry using DUST.
     */
    function buyEntryDust(uint32 _id, uint16 _numEntries) external payable holdsSweeper nonReentrant {
        require(compStatus(_id) == 1, 'Comp is not Active');
        require(block.timestamp < compId[_id].endTime, 'Comp expired');
        require(_numEntries + compId[_id].numberEntries <= compId[_id].entryCap, 'Entry cap exceeded');
        require(_numEntries + userEntries[_id][msg.sender].length <= compId[_id].entryLimit, 'Entry limit exceeded');
        require(msg.value == DevFee + (compId[_id].entryCost * _numEntries), 'Fee not covered');

        // start the automation tasks if this is the first entry
        if(compId[_id].numberEntries == 0) {
            startPickWinnerTask(_id);
        }

        uint32 _entryId;
        uint256 _entryCost = _numEntries * compId[_id].entryPriceDust;

        for(uint i = 0; i < _numEntries; i++) {
            _entryId = currentEntryId++;

            compEntries[_id].push(_entryId);
            entryId[_entryId].entrant = msg.sender;
            entryId[_entryId].compId = _id;
            entryId[_entryId].useETH = false;
            entryId[_entryId].winner = false;
            userEntries[_id][msg.sender].push(_entryId);
            emit EntryReceived(_entryId, _id, msg.sender, compId[_id].entryPriceDust, false);
        }

        compId[_id].numberEntries = compId[_id].numberEntries + _numEntries;

        DUST.burnFrom(msg.sender, _entryCost);
        
        Dev.transfer(DevFee);
    }

    /**
     * @notice Buy a competition entry using ETH.
     */
    function buyEntryETH(uint32 _id, uint16 _numEntries) external payable holdsSweeper nonReentrant {
        require(compStatus(_id) == 1, 'Comp not Active');
        require(block.timestamp < compId[_id].endTime, 'Comp expired');
        require(_numEntries + compId[_id].numberEntries <= compId[_id].entryCap, 'Cap exceeded');
        require(_numEntries + userEntries[_id][msg.sender].length <= compId[_id].entryLimit, 'Entry limit exceeded');
        require(msg.value == (compId[_id].entryCost * _numEntries) + (compId[_id].entryPriceETH * _numEntries), 'Fee not covered');

        // start the automation tasks if this is the first entry
        if(compId[_id].numberEntries == 0) {
            startPickWinnerTask(_id);
        }

        uint32 _entryId;
        uint256 _entryCost = _numEntries * compId[_id].entryPriceETH;

        for(uint i = 0; i < _numEntries; i++) {
            _entryId = currentEntryId++;

            compEntries[_id].push(_entryId);
            entryId[_entryId].entrant = msg.sender;
            entryId[_entryId].compId = _id;
            entryId[_entryId].useETH = true;
            entryId[_entryId].winner = false;
            userEntries[_id][msg.sender].push(_entryId);
            emit EntryReceived(_entryId, _id, msg.sender, compId[_id].entryPriceDust, true);
        }

        compId[_id].numberEntries = compId[_id].numberEntries + _numEntries;

        ethCollected[_id] = _entryCost;
    }

    function startPickWinnerTask(uint32 _id) internal {
        IOps(ops).createTaskNoPrepayment(
            address(this), 
            this._pickCompWinner.selector,
            address(this),
            abi.encodeWithSelector(this.canPickChecker.selector, _id),
            ETH
        );
    }

    function canPickChecker(uint32 _id) 
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        canExec = (compStatus(_id) == 2 && !winnerRequested[_id] && tx.gasprice < gasLimit);
        
        execPayload = abi.encodeWithSelector(
            this._pickCompWinner.selector,
            _id
        );
    }

    function pickCompWinner(uint32 _id) public {
        require(compStatus(_id) == 2, 'cant be settled now');
        
        if(compEntries[_id].length > 0) {
            randomizer.requestRandomWords();
            winnerRequested[_id] = true;
            winnerRequestedTime[_id] = block.timestamp;
            startSettleTask(_id);
            VRF.transfer(VRFCost);
        } else {
            winnerRequested[_id] = true;
            _settleComp(_id);
        }
    }

    function _pickCompWinner(uint32 _id) external onlyOps {
        (uint256 fee, address feeToken) = IOps(ops).getFeeDetails();
        _transfer(fee, feeToken);

        pickCompWinner(_id);
    }

    function startSettleTask(uint32 _id) internal {
        IOps(ops).createTaskNoPrepayment(
            address(this), 
            this.autoSettleComp.selector,
            address(this),
            abi.encodeWithSelector(this.canSettleChecker.selector, _id),
            ETH
        );
    }

    function canSettleChecker(uint32 _id) 
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        canExec = (compStatus(_id) == 6 && block.timestamp - winnerRequestedTime[_id] >= autoSettleTimer && tx.gasprice < gasLimit);
        
        execPayload = abi.encodeWithSelector(
            this.autoSettleComp.selector,
            _id
        );
    }

    function settleComp(uint32 _id) external {
        _settleComp(_id);
    }

    function autoSettleComp(uint32 _id) external onlyOps {
        (uint256 fee, address feeToken) = IOps(ops).getFeeDetails();
        _transfer(fee, feeToken);

        _settleComp(_id);
    }
    
    /**
     * @notice Settle an competition, finalizing the bid and transferring the NFT to the winner.
     * @dev If there are no entries, the competition is failed and can be relisted.
     */
    function _settleComp(uint32 _id) internal {
        require(compStatus(_id) == 6, 'cant be settled now');
        require(compId[_id].tokenId != 0, 'update comp tokenID');

        compId[_id].settled = true;
        uint32 _winningEntryId;
        address _compWinner;
        if (compId[_id].numberEntries == 0) {
            compId[_id].failed = true;
            if (!compId[_id].blind) {
                if(compId[_id].is1155) {
                    IERC1155(compId[_id].contractAddress).safeTransferFrom(address(this), Dev, compId[_id].tokenId, 1, "");
                } else {
                    IERC721(compId[_id].contractAddress).safeTransferFrom(address(this), Dev, compId[_id].tokenId);
                }
            }
            emit CompFailed(_id, address(compId[_id].contractAddress), compId[_id].tokenId);
        } else {
            uint256 seed = randomizer.getRandomWord();
            uint256 entryIndex = seed % compEntries[_id].length;
            _winningEntryId = compEntries[_id][entryIndex];
            _compWinner = entryId[_winningEntryId].entrant;
            compWinner[_id] = _compWinner;

            if(compId[_id].is1155) {
                IERC1155(compId[_id].contractAddress).safeTransferFrom(address(this), _compWinner, compId[_id].tokenId, 1, "");
            } else {
                IERC721(compId[_id].contractAddress).safeTransferFrom(address(this), _compWinner, compId[_id].tokenId);
            }

            if(ethCollected[_id] > 0) {
                uint256 treasuryAmount = ethCollected[_id] * sweepersCut / 10000;
                uint256 legacyAmount = ethCollected[_id] * legacyCut / 10000;
                uint256 devAmount = ethCollected[_id] * devCut / 10000;
                sweepersTreasury.transfer(treasuryAmount);
                legacyTreasury.transfer(legacyAmount);
                Dev.transfer(devAmount);
            }
        }
        activeCompCount--;
        emit CompSettled(_id, address(compId[_id].contractAddress), compId[_id].tokenId, _compWinner, _winningEntryId, entryId[_winningEntryId].useETH);
    }

    function compStatus(uint32 _id) public view returns (uint8) {
        if (winnerRequested[_id] && !compId[_id].settled) {
        return 6; // AWAITING SETTLEMENT - Winner selected and awaiting settlement    
        }
        if (block.timestamp >= compId[_id].endTime && compId[_id].tokenId == 0) {
        return 5; // AWAITING TOKENID - Comp finished
        }
        if (compId[_id].failed) {
        return 4; // FAILED - not sold by end time
        }
        if (compId[_id].settled) {
        return 3; // SUCCESS - Entrant won 
        }
        if (block.timestamp >= compId[_id].endTime || compId[_id].numberEntries == compId[_id].entryCap) {
        return 2; // AWAITING WINNER SELECTION - Comp finished
        }
        if (block.timestamp <= compId[_id].endTime && block.timestamp >= compId[_id].startTime) {
        return 1; // ACTIVE - entries enabled
        }
        return 0; // QUEUED - awaiting start time
    }

    function getEntriesByCompId(uint32 _id) external view returns (uint32[] memory entryIds) {
        uint256 length = compEntries[_id].length;
        entryIds = new uint32[](length);
        for(uint i = 0; i < length; i++) {
            entryIds[i] = compEntries[_id][i];
        }
    }

    function getEntriesByUser(uint32 _id, address _user) external view returns (uint32[] memory entryIds) {
        uint256 length = userEntries[_id][_user].length;
        entryIds = new uint32[](length);
        for(uint i = 0; i < length; i++) {
            entryIds[i] = userEntries[_id][_user][i];
        }
    }

    function getTotalEntriesLength() external view returns (uint32) {
        return currentEntryId;
    }

    function getEntriesLengthForComp(uint32 _id) external view returns (uint256) {
        return compEntries[_id].length;
    }

    function getEntriesLengthForUser(uint32 _id, address _user) external view returns (uint256) {
        return userEntries[_id][_user].length;
    }

    function getEntryInfoByIndex(uint32 _entryId) external view returns (address _entrant, uint32 _compId, string memory _entryStatus) {
        _entrant = entryId[_entryId].entrant;
        _compId = entryId[_entryId].compId;
        if(compId[entryId[_entryId].compId].settled && entryId[_entryId].winner) {
            _entryStatus = 'won';
        } else if(compId[entryId[_entryId].compId].settled && !entryId[_entryId].winner) {
            _entryStatus = 'lost';
        } else {
            _entryStatus = 'entered';
        }
    }

    function getAllComps() external view returns (uint32[] memory comps, uint8[] memory status) {
        comps = new uint32[](currentCompId);
        status = new uint8[](currentCompId);
        for(uint32 i = 0; i < currentCompId; i++) {
            comps[i] = i;
            status[i] = compStatus(i);
        }
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}