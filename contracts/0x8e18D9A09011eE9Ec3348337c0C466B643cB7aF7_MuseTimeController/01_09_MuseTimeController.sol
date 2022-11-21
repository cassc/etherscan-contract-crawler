// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "lib/solmate/src/utils/LibString.sol";
import "./interfaces/IERC20.sol";
import "./libraries/SignatureVerification.sol";

contract MuseTimeController is OwnableUpgradeable {

    struct TimeTrove {
        bytes32 arOwnerAddress;
        uint256 balance;
    }

    enum TimeTokenStatus {
        PENDING,
        REJECTED,
        CONFIRMED
    }

    struct TimeToken {
        uint256 valueInWei;
        address topicOwner;
        TimeTokenStatus status;
    }

    address public museTimeNFT;
    address public paramsSigner;

    string public baseURI;
    uint256 public mintIndex;

    /**
     * @dev Key(uint256) mapping to a claimed key.
     * Used to prevent address from rebroadcasting mint transactions
     */
    mapping(uint256 => bool) private _claimedMintKeysLegacy;  // deprecated, but keep the storage slot
    mapping(address => TimeTrove) private _timeTrovesLegacy;  // deprecated, but keep the storage slot

    mapping(address => TimeTrove) private _timeTroves;
    mapping(uint256 => TimeToken) private _timeTokens;

    uint256 public feeDivisor;  // divisor 500: (1 / 500) == 0.2% | 2000000000000000 === (2 / 1000) * 1e18

    /* variables end */

    event TimeTroveCreated(address indexed topicOwner);
    event TimeTokenMinted(
        address indexed topicOwner, bytes32 indexed topicId, uint256 indexed tokenId,
        address tokenOwner, bytes32 profileArId, bytes32 topicsArId);

    /* events end */

    function initialize(
        address museTimeNFT_,
        string memory baseURI_,
        address paramsSigner_
    ) initializer public {
        __Ownable_init();
        museTimeNFT = museTimeNFT_;
        baseURI = baseURI_;
        paramsSigner = paramsSigner_;
    }

    /**
     *  @dev TimeTrove
     */

    struct CreateTimeTroveParams {
        bytes32 arOwnerAddress;
        address topicOwner;
        bytes signature;
    }

    function createTimeTroves(CreateTimeTroveParams[] memory params) external {
        for (uint256 i=0; i<params.length; ++i) {
            bytes32 arOwnerAddress = params[i].arOwnerAddress;
            address topicOwner = params[i].topicOwner;
            bytes memory signature = params[i].signature;
            require(_timeTroves[topicOwner].arOwnerAddress == 0, 'TIME_TROVE_EXISTS');
            SignatureVerification.requireValidSignature(
                abi.encodePacked(this, topicOwner, arOwnerAddress),
                signature,
                paramsSigner
            );
            _timeTroves[topicOwner] = TimeTrove(arOwnerAddress, 0);
            emit TimeTroveCreated(topicOwner);
        }
    }

    function timeTroveOf(address topicOwner) external view returns (TimeTrove memory) {
        return _timeTroves[topicOwner];
    }

    /**
     *  @dev TimeToken
     */

    function mintTimeToken(
        uint256 expired,
        uint256 valueInWei,
        bytes32 profileArId,
        bytes32 topicsArId,
        bytes32 topicId,
        address topicOwner,
        bytes memory signature
    ) external payable returns (uint256 tokenId) {
        require(block.number <= expired, "EXPIRED");
        require(valueInWei == msg.value, "INCORRECT_ETHER_VALUE");
        require(_timeTroves[topicOwner].arOwnerAddress != 0, 'TIME_TROVE_NOT_EXIST');
        SignatureVerification.requireValidSignature(
            abi.encodePacked(this, msg.sender, expired, valueInWei, profileArId, topicsArId, topicId, topicOwner),
            signature,
            paramsSigner
        );
        mintIndex += 1;
        tokenId = mintIndex;
        _timeTokens[tokenId] = TimeToken(valueInWei, topicOwner, TimeTokenStatus.PENDING);
        IMuseTime(museTimeNFT).mint(msg.sender, tokenId);
        emit TimeTokenMinted(topicOwner, topicId, tokenId, msg.sender, profileArId, topicsArId);
    }

    function timeTokenOf(uint256 tokenId) external view returns (TimeToken memory) {
        return _timeTokens[tokenId];
    }

    function setConfirmed(uint256[] memory tokenIds, bool withdrawOnSuccess) external {
        uint256 balance = _timeTroves[msg.sender].balance;
        for (uint256 i=0; i<tokenIds.length; ++i) {
            uint256 tokenId = tokenIds[i];
            // IMuseTime(museTimeNFT).ownerOf(tokenId); // get owner first to ensure token exists, but it's not necessary since timeToken.topicOwner exists
            TimeToken memory timeToken = _timeTokens[tokenId];
            require(msg.sender == timeToken.topicOwner, "NOT_TOPIC_OWNER");
            require(timeToken.status == TimeTokenStatus.PENDING, "WRONG_STATUS");
            // update contract state
            _timeTokens[tokenId].status = TimeTokenStatus.CONFIRMED;
            balance += timeToken.valueInWei;
        }
        _timeTroves[msg.sender].balance = balance;
        if (withdrawOnSuccess) {
            withdrawFromTimeTrove();
        }
    }

    function setRejected(uint256[] memory tokenIds) external {
        for (uint256 i=0; i<tokenIds.length; ++i) {
            uint256 tokenId = tokenIds[i];
            address tokenOwner = IMuseTime(museTimeNFT).ownerOf(tokenId);
            TimeToken memory timeToken = _timeTokens[tokenId];
            require(msg.sender == timeToken.topicOwner, "NOT_TOPIC_OWNER");
            require(timeToken.status == TimeTokenStatus.PENDING, "WRONG_STATUS");
            // update contract state
            _timeTokens[tokenId].status = TimeTokenStatus.REJECTED;
            payable(tokenOwner).transfer(timeToken.valueInWei); // do refund
        }
    }

    function withdrawFromTimeTrove() public {
        uint256 balance = _timeTroves[msg.sender].balance;
        require(balance > 0, "NO_BALANCE");
        uint256 fee = 0;
        if (feeDivisor >= 1) {
            fee = balance / feeDivisor;
        }
        _timeTroves[msg.sender].balance = 0;
        payable(msg.sender).transfer(balance - fee);
    }

    /**
     *  @dev Render
     */

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        if (bytes(baseURI).length > 0) {
            return string(abi.encodePacked(baseURI, LibString.toString(tokenId)));
        } else {
            return "";
        }
    }

    /**
     * @dev Controller owner actions
     */

    receive() external payable {}

    function withdrawETH(uint256 amount) external onlyOwner {
        uint256 balance = address(this).balance;
        require(amount <= balance, 'NO_ENOUGH_BALANCE');
        payable(msg.sender).transfer(amount);
    }

    function withdrawERC20(IERC20 token, uint256 amount) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(amount <= balance, 'NO_ENOUGH_BALANCE');
        token.transfer(msg.sender, amount);
    }

    function setFeeDivisor(uint256 feeDivisor_) external onlyOwner {
        require(feeDivisor_ >= 1 || feeDivisor_ == 0);
        feeDivisor = feeDivisor_;
    }

    function setParamsSigner(address paramsSigner_) external onlyOwner {
        paramsSigner = paramsSigner_;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

}

interface IMuseTime {
    function mint(address to, uint256 tokenId) external;
    function ownerOf(uint256 id) external view returns (address owner);
}