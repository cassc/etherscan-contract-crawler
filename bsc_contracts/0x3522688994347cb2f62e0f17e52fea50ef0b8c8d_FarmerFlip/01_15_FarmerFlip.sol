// SPDX-License-Identifier: WTFPL
/*
███████╗██╗ ██████╗ ███╗   ██╗    ███████╗ █████╗ ██████╗ ███╗   ███╗███████╗██████╗     ███████╗██╗     ██╗██████╗ 
╚══███╔╝██║██╔═══██╗████╗  ██║    ██╔════╝██╔══██╗██╔══██╗████╗ ████║██╔════╝██╔══██╗    ██╔════╝██║     ██║██╔══██╗
  ███╔╝ ██║██║   ██║██╔██╗ ██║    █████╗  ███████║██████╔╝██╔████╔██║█████╗  ██████╔╝    █████╗  ██║     ██║██████╔╝
 ███╔╝  ██║██║   ██║██║╚██╗██║    ██╔══╝  ██╔══██║██╔══██╗██║╚██╔╝██║██╔══╝  ██╔══██╗    ██╔══╝  ██║     ██║██╔═══╝ 
███████╗██║╚██████╔╝██║ ╚████║    ██║     ██║  ██║██║  ██║██║ ╚═╝ ██║███████╗██║  ██║    ██║     ███████╗██║██║     
╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝    ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝    ╚═╝     ╚══════╝╚═╝╚═╝     
*/
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./Recoverable.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract FarmerFlip is Ownable, VRFConsumerBaseV2, ReentrancyGuard, Pausable, Recoverable {
    VRFCoordinatorV2Interface private immutable coordinator;
    VRFConfig private vrfConfig;
    IERC721Enumerable private immutable zionLion;

    address public feeReceiver;
    address public nftReceiver;

    struct VRFConfig {
        bytes32 keyHash;
        uint16 requestConfirmations;
        uint32 callbackGasLimit;
        uint64 subscriptionId;
    }

    uint256[] private data = new uint256[](100);
    uint8 public winPercent = 50;
    uint256 public fee = 0.001 ether;
    uint256 public totalPlays;
    uint256 public totalAmountWon;
    mapping(address => uint256) private wonCount;
    mapping(address => uint256) private loseCount;

    uint256[] public explorerRewardIds;

    struct Data {
        uint256 idx;
        uint256 value;
    }

    struct Result {
        bool resolved;
        uint8 betChoice;
        uint256 result;
        address playerAddress;
        uint256 tokenId;
    }

    uint256[] public requests = new uint256[](5);

    mapping(address => bool) public inPlay;
    mapping(uint256 => Result) public results;

    event SetRewards(uint256[] tokenIds);
    event NewIdRequest(address indexed player, uint256 requestId);
    event GeneratedRandomNumber(
        uint256 requestId,
        uint256 randomNumber,
        uint256 randomWordsGot
    );
    event BetResult(address indexed player, bool victory, uint256 tokenId);
    event SetWinPercent(uint8 winPercent);
    event SetFee(uint256 fee);

    error InsufficientFunds(uint256 required);
    error InvalidChoice(uint8[2] choices);
    error BetAlreadyOngoing();
    error NotEnoughPrizes();
    error NothingToBet();
    error NotTokenOwner();
    error InvalidTokenId();
    error WithdrawFailed();
    error ZeroAddress();

    constructor(address _vrfCoordinator, uint64 _subscriptionId, uint256[] memory _data) VRFConsumerBaseV2(_vrfCoordinator) {
        coordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        vrfConfig = VRFConfig({
            subscriptionId: _subscriptionId,
            keyHash: 0x114f3da0a805b6a67d6e9cd2ec746f7028f1b7376365af575cfea3550dd1aa04,
            callbackGasLimit: 1e6,
            requestConfirmations: 3
        });
        zionLion = IERC721Enumerable(0x8492D8E17F3e520e171682D792B0eb79dC126B4E);
        feeReceiver = address(this);
        nftReceiver = address(this);
        data = _data;
    }

    modifier checkConditions() {
        if (msg.value < fee) revert InsufficientFunds(fee);
        if (inPlay[_msgSender()]) revert BetAlreadyOngoing();
        if (explorerRewardIds.length == 0) {
            revert NotEnoughPrizes();
        } else {
            uint256 count = 0;
            uint256[] memory _requests = requests;
            for (uint256 i = 0; i < _requests.length;) {
                if (requests[i] > 0 && !results[requests[i]].resolved) {
                    count++;
                }
                unchecked {
                    ++i;
                }
            }
            if (explorerRewardIds.length <= count) revert NotEnoughPrizes();
        }
        _;
    }

    function betHeads(uint256 _tokenId) external payable checkConditions {
        _gambleToken(0, _tokenId);
    }

    function betTails(uint256 _tokenId) external payable checkConditions {
        _gambleToken(1, _tokenId);
    }

    function _gambleToken(uint8 _choice, uint256 _tokenId) internal whenNotPaused nonReentrant {
        address player = _msgSender();

        uint256 _tokenOut = _tokenId;
        inPlay[player] = true;

        if (_tokenOut == 0) {        
            uint256 balance = zionLion.balanceOf(player);
            for (uint256 i = 0; i < balance;) {
                uint256 _id = zionLion.tokenOfOwnerByIndex(player, i);
                if (_test(_id, 0)) {
                    _tokenOut = _id;
                    break;
                }
                unchecked {
                    ++i;
                }
            }
        }

        if (_tokenOut == 0) revert NothingToBet();
        if (zionLion.ownerOf(_tokenOut) != player) revert NotTokenOwner();
        zionLion.transferFrom(player, nftReceiver, _tokenOut);

        uint256 requestId = requestRandomWords();
        results[requestId].playerAddress = player;
        results[requestId].tokenId = _tokenOut;
        results[requestId].betChoice = _choice;
        results[requestId].resolved = false;

        requests[totalPlays++ % requests.length] = requestId;
        emit NewIdRequest(player, requestId);
        
        if (feeReceiver != address(this) && fee > 0) {
            payable(feeReceiver).call{value: fee}("");
        }
    }

    function requestRandomWords() private returns (uint256) {
        VRFConfig memory vrf = vrfConfig;
        return coordinator.requestRandomWords(vrf.keyHash, vrf.subscriptionId, vrf.requestConfirmations, vrf.callbackGasLimit, 1);
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        checkResult(_requestId, _randomWords);
    }

    function checkResult(uint256 _requestId, uint256[] memory _randomWords) internal whenNotPaused {
        uint8 choice = results[_requestId].betChoice;
        uint256 randomResult;
        if (winPercent == 50 || choice == 0) {
            randomResult = _randomWords[0] % 100 < winPercent ? 0 : 1;
        } else {
            randomResult = _randomWords[0] % 100 >= (100 - winPercent) ? 1 : 0;
        }
        results[_requestId].result = randomResult;
        results[_requestId].resolved = true;

        emit GeneratedRandomNumber(_requestId, randomResult, _randomWords[0]);

        address player = results[_requestId].playerAddress;
        uint256 tokenId;
        inPlay[player] = false;
        if (results[_requestId].betChoice == randomResult) {
            tokenId = explorerRewardIds[explorerRewardIds.length - 1];
            explorerRewardIds.pop();
            zionLion.transferFrom(address(this), player, tokenId);

            ++totalAmountWon;
            ++wonCount[player];
            emit BetResult(player, true, tokenId);
            return;
        } 
        
        tokenId = results[_requestId].tokenId;
        ++loseCount[player];

        emit BetResult(player, false, tokenId);
    }

    function getWonCount(address adr) external view returns (uint256) {
        return wonCount[adr];
    }

    function getLoseCount(address adr) external view returns (uint256) {
        return loseCount[adr];
    }

    function withdrawContractBalance(address adr) external onlyOwner {
        if (address(this).balance > 0) {
            _payout(adr);
        }
    }

    function withdrawGambledNFTS(address adr) external onlyOwner {
        uint256 balance = zionLion.balanceOf(address(this));
        uint256[] memory tokenIds = new uint256[](balance);
        uint256 count = 0;
        for (uint256 i = 0; i < balance;) {
            uint256 tokenId = zionLion.tokenOfOwnerByIndex(address(this), i);
            if (_test(tokenId, 0)) {
                tokenIds[count++] = tokenId;
            }
            unchecked {
                ++i;
            }
        }
        for (uint256 i = 0; i < count;) {
            zionLion.transferFrom(address(this), adr, tokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    function configureVRF(uint64 _vrfSubscriptionId, bytes32 _vrfKeyHash, uint16 _vrfRequestConfirmations, uint32 _vrfCallbackGasLimit) external onlyOwner {
        VRFConfig storage vrf = vrfConfig;
        vrf.subscriptionId = _vrfSubscriptionId;
        vrf.keyHash = _vrfKeyHash;
        vrf.requestConfirmations = _vrfRequestConfirmations;
        vrf.callbackGasLimit = _vrfCallbackGasLimit;
    }

    function fulfillRandomWordsFallback(uint256 _requestId) external onlyOwner {
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = uint256(keccak256(abi.encode(_requestId, block.difficulty, block.gaslimit, block.number, msg.sender)));
        checkResult(_requestId, randomWords);
    }

    function setWinPercent(uint8 _winPercent) external onlyOwner {
        winPercent = _winPercent;
        emit SetWinPercent(_winPercent);
    }

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
        emit SetFee(_fee);
    }

    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        if (_feeReceiver == address(0)) revert ZeroAddress();
        feeReceiver = _feeReceiver;
    }

    function setNftReceiver(address _nftReceiver) external onlyOwner {
        if (_nftReceiver == address(0)) revert ZeroAddress();
        nftReceiver = _nftReceiver;
    }

    function depositRewards(uint256[] calldata _tokenIds) external onlyOwner {
        for (uint256 i = 0; i < _tokenIds.length;) {
            uint256 tokenId = _tokenIds[i];
            if (zionLion.ownerOf(tokenId) != _msgSender()) revert NotTokenOwner();
            if (!_test(tokenId, 1)) revert InvalidTokenId();
            zionLion.transferFrom(_msgSender(), address(this), tokenId);
            unchecked {
                ++i;
            }
        }
        _setRewardIds();
    }

    function _setRewardIds() private {
        uint256 balance = zionLion.balanceOf(address(this));
        uint256 count = 0;
        for (uint256 i = 0; i < balance;) {
            uint256 _tokenId = zionLion.tokenOfOwnerByIndex(address(this), i);
            if (_test(_tokenId, 1)) {
                count++;
            }
            unchecked {
                ++i;
            }
        }
        uint256[] memory _tokenIds = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < balance;) {
            uint256 _tokenId = zionLion.tokenOfOwnerByIndex(address(this), i);
            if (_test(_tokenId, 1)) {
                _tokenIds[index] = _tokenId;
                index++;
            }
            unchecked {
                ++i;
            }
        }
        explorerRewardIds = _tokenIds;
        emit SetRewards(_tokenIds);
    }

    function replaceData(Data[] calldata _data) external onlyOwner {
        for (uint256 i = 0; i < _data.length;) {
            uint256 idx = _data[i].idx;
            data[idx] = _data[i].value;
            unchecked {
                ++i;
            }
        }
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function _test(uint256 _id, uint _t) private view returns (bool) {
        return data[_id / 256 + (25 * _t)] & (1 << _id % 256) != 0;
    }

    function _payout(address adr) private returns (uint256) {
        uint256 toTransfer = address(this).balance;
        payable(adr).transfer(toTransfer);
        return toTransfer;
    }

    receive() payable external {}
}