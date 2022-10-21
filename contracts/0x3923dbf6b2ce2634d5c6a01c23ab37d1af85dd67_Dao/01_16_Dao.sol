// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin-contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "chainlink/interfaces/VRFCoordinatorV2Interface.sol";
import "chainlink/VRFConsumerBaseV2.sol";

import "../interface/ILayerZeroReceiver.sol";
import "../interface/ILayerZeroEndpoint.sol";
import "../interface/IERC721.sol";

contract Dao is
    Initializable, 
    OwnableUpgradeable,
    UUPSUpgradeable,
    ILayerZeroReceiver,
    IERC721ReceiverUpgradeable,
    VRFConsumerBaseV2(0x271682DEB8C4E0901D1a1550aD2e64D568E69909)
{
    ILayerZeroEndpoint constant lzEndpoint = ILayerZeroEndpoint(0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675);
    mapping(uint16 => bytes) public trustedRemoteLookup; // record contract on Optimism

    address constant vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
    VRFCoordinatorV2Interface private COORDINATOR;
    uint64 public s_subscriptionId;

    IERC721 public nft;
    address public reward;
    uint public totalSeats;
    bool public rngInProgress;
    uint public randomSeat;
    address public winner;

    event LzReceiveRetry(uint16 _srcChainId, bytes _srcAddress, bytes _payload);
    event LzReceiveClear(uint16 _srcChainId, address _srcAddress);
    event DistributeNFT(address winner, address _nft, uint tokenId);
    event SetNft(address _nft);
    event SetReward(address _reward);
    event SetTotalSeats(uint _totalSeats);
    event SetRandomSeat(uint _randomSeat);
    event SetWinner(address _winner);
    event SetTrustedRemote(uint16 chainId, address record);

    function initialize(address record, uint64 subscriptionId, address _nft) external initializer {
        __Ownable_init();

        trustedRemoteLookup[111] = abi.encodePacked(record);
        nft = IERC721(_nft);

        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
    }

    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64, bytes memory _payload) override external {
        require(msg.sender == address(lzEndpoint), "sender != lzEndpoint");
        require(keccak256(_srcAddress) == keccak256(trustedRemoteLookup[_srcChainId]), "srcAddr != trustedRemote");
        
        (uint _totalSeats, address _winner) = abi.decode(_payload, (uint, address));
        if (_totalSeats != 0 && winner == address(0)) {
            totalSeats = _totalSeats;
            emit SetTotalSeats(_totalSeats);
        } else {
            winner = _winner;
            emit SetWinner(_winner);
        }
    }

    ///@notice retrieve any payload that didn't execute due to error, can view from layerzeroscan.com 
    ///@param _srcChainId 111 for optimism
    ///@param _srcAddress abi.encodePacked(optimismRecordAddr, address(this))
    ///@param _payload abi.encode(totalSeats, address(0)) || abi.encode(0, winnerAddr)
    function lzReceiveRetry(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external {
        lzEndpoint.retryPayload(_srcChainId, _srcAddress, _payload);

        emit LzReceiveRetry(_srcChainId, _srcAddress, _payload);
    }

    ///@notice clear any payload that block the subsequent payload
    ///@param _srcChainId 111 for optimism
    ///@param srcAddress optimismRecordAddr
    function lzReceiveClear(uint16 _srcChainId, address srcAddress) external onlyOwner {
        bytes memory _srcAddress = abi.encodePacked(srcAddress, address(this));
        lzEndpoint.forceResumeReceive(_srcChainId, _srcAddress);

        emit LzReceiveClear(_srcChainId, srcAddress);
    }

    function requestRandomWords() external {
        require(totalSeats != 0, "totalSeats == 0");
        require(randomSeat == 0, "randomSeat != 0");
        require(!rngInProgress, "rng in progress");

        // Will revert if subscription is not set and funded.
        COORDINATOR.requestRandomWords(
            0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef, // keyHash
            s_subscriptionId, // s_subscriptionId
            3, // requestConfirmations
            100000, // callBackGasLimit
            1 // numWords
        );

        rngInProgress = true;
    }

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        uint randomNumber = randomWords[0];
        randomSeat = randomNumber % totalSeats;
        rngInProgress = false;

        emit SetRandomSeat(randomSeat);
    }

    function distributeNFT(uint tokenId) external {
        require(winner != address(0), "winner == address(0)");

        nft.transferFrom(address(this), winner, tokenId);
        emit DistributeNFT(winner, address(nft), tokenId);

        winner = address(0);
        randomSeat = 0;
        totalSeats = 0;
    }

    function setNft(address _nft) external onlyOwner {
        nft = IERC721(_nft);

        emit SetNft(_nft);
    }

    function setReward(address _reward) external onlyOwner {
        reward = _reward;

        emit SetReward(_reward);
    }

    ///@notice only use this function if layerzero failed
    function setTotalSeats(uint _totalSeats) external onlyOwner {
        totalSeats = _totalSeats;

        emit SetTotalSeats(_totalSeats);
    }

    ///@notice only use this function if layerzero failed
    function setWinner(address _winner) external onlyOwner {
        winner = _winner;

        emit SetWinner(_winner);
    }

    function setTrustedRemote(uint16 chainId, address record) external onlyOwner {
        trustedRemoteLookup[chainId] = abi.encodePacked(record, address(this));

        emit SetTrustedRemote(chainId, record);
    }

    function getTokenId() external view returns (uint tokenId) {
        uint totalSupply = nft.totalSupply();
        for (uint i = 1; i < totalSupply; i++) {
            address tokenOwner;
            try nft.ownerOf(i) {
                tokenOwner = nft.ownerOf(i);
            } catch {}
            if (tokenOwner == address(this)) {
                tokenId = i;
                break;
            }
        }
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}