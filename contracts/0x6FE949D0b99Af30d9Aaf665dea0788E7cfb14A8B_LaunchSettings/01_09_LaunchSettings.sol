// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./ILaunchSettings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
contract LaunchSettings is ILaunchSettings, Ownable, IERC165 {

    using ERC165Checker for address;
    bytes4 public constant IID_IERC1155 = type(IERC1155).interfaceId;
    bytes4 public constant IID_IERC721 = type(IERC721).interfaceId;

    uint256 public override maxAuctionLength;
    uint256 public override maxAuctionLengthForNFT;

    uint256 public constant maxMaxAuctionLength = 8 weeks;
    uint256 public constant maxMaxAuctionLengthForNFT = 8 weeks;

    uint256 public override minAuctionLength;
    uint256 public override minAuctionLengthForNFT;

    uint256 public constant minMinAuctionLength = 6 hours;
    uint256 public constant minMinAuctionLengthForNFT = 6 hours;

    uint256 public override governanceFee;
    uint256 public override governanceFeeForNFT;

    uint256 public constant maxGovFee = 2000;
    uint256 public constant maxGovFeeForNFT = 2000;

    uint256 public override maxCuratorFee;
    uint256 public override maxCuratorFeeForNFT;

    uint256 public override minBidIncrease;
    uint256 public override minBidIncreaseForNFT;

    uint256 public constant maxMinBidIncrease = 1000;
    uint256 public constant maxMinBidIncreaseForNFT = 1000;

    uint256 public constant minMinBidIncrease = 100;
    uint256 public constant minMinBidIncreaseForNFT = 100;

    uint256 public override minVotePercentage;
    uint256 public override minVotePercentageForNFT;

    uint256 public override maxReserveFactor;
    uint256 public override maxReserveFactorForNFT;

    uint256 public override minReserveFactor;
    uint256 public override minReserveFactorForNFT;

    address payable public override feeReceiver;
    address payable public override feeReceiverForNFT;

    mapping(address=>uint256) public platformFee;

    event UpdateMaxAuctionLength(uint256 _old, uint256 _new);
    event UpdateMaxAuctionLengthForNFT(uint256 _old, uint256 _new);

    event UpdateMinAuctionLength(uint256 _old, uint256 _new);
    event UpdateMinAuctionLengthForNFT(uint256 _old, uint256 _new);

    event UpdateGovernanceFee(uint256 _old, uint256 _new);
    event UpdateGovernanceFeeForNFT(uint256 _old, uint256 _new);

    event UpdateCuratorFee(uint256 _old, uint256 _new);
    event UpdateCuratorFeeForNFT(uint256 _old, uint256 _new);

    event UpdateMinBidIncrease(uint256 _old, uint256 _new);
    event UpdateMinBidIncreaseForNFT(uint256 _old, uint256 _new);

    event UpdateMinVotePercentage(uint256 _old, uint256 _new);
    event UpdateMinVotePercentageForNFT(uint256 _old, uint256 _new);

    event UpdateMaxReserveFactor(uint256 _old, uint256 _new);
    event UpdateMaxReserveFactorForNFT(uint256 _old, uint256 _new);

    event UpdateMinReserveFactor(uint256 _old, uint256 _new);
    event UpdateMinReserveFactorForNFT(uint256 _old, uint256 _new);

    event UpdateFeeReceiver(address _old, address _new);
    event UpdateFeeReceiverForNFT(address _old, address _new);

    //update values to bips
    constructor() {
        maxAuctionLength = 2 weeks;
        maxAuctionLengthForNFT = 2 weeks;
        minAuctionLength = 1 days;
        minAuctionLengthForNFT = 1 days;
        feeReceiver = payable(msg.sender);
        feeReceiverForNFT = payable(msg.sender);
        minReserveFactor = 2000;  // 20% * 100
        minReserveFactorForNFT = 2000;  // 20%
        maxReserveFactor = 50000; // 500%
        maxReserveFactorForNFT = 50000; // 500%
        minBidIncrease = 500;     // 5%
        minBidIncreaseForNFT = 500;     // 5%
        maxCuratorFee = 1000; //10%
        maxCuratorFeeForNFT = 1000; //10%
        minVotePercentage = 5000; // 50%
        minVotePercentageForNFT = 5000; // 50%
        platformFee[0x0000000000000000000000000000000000000000] = 25; // ETH fee is 0.25% is 25
    }

    function setMaxAuctionLength(uint256 _length) external onlyOwner {
        require(_length <= maxMaxAuctionLength, "max auction length too high");
        require(_length > minAuctionLength, "max auction length too low");

        emit UpdateMaxAuctionLength(maxAuctionLength, _length);

        maxAuctionLength = _length;
    }

    function setMaxAuctionLengthForNFT(uint256 _length) external onlyOwner {
        require(_length <= maxMaxAuctionLengthForNFT, "max auction length too high");
        require(_length > minAuctionLengthForNFT, "max auction length too low");

        emit UpdateMaxAuctionLengthForNFT(maxAuctionLengthForNFT, _length);

        maxAuctionLengthForNFT = _length;
    }

    function setMinAuctionLength(uint256 _length) external onlyOwner {
        require(_length >= minMinAuctionLength, "min auction length too low");
        require(_length < maxAuctionLength, "min auction length too high");

        emit UpdateMinAuctionLength(minAuctionLength, _length);

        minAuctionLength = _length;
    }

    function setMinAuctionLengthForNFT(uint256 _length) external onlyOwner {
        require(_length >= minMinAuctionLengthForNFT, "min auction length too low");
        require(_length < maxAuctionLengthForNFT, "min auction length too high");

        emit UpdateMinAuctionLengthForNFT(minAuctionLengthForNFT, _length);

        minAuctionLengthForNFT = _length;
    }

    function setGovernanceFee(uint256 _fee) external onlyOwner {
        require(_fee <= maxGovFee, "fee too high");

        emit UpdateGovernanceFee(governanceFee, _fee);

        governanceFee = _fee;
    }
    function setGovernanceFeeForNFT(uint256 _fee) external onlyOwner {
        require(_fee <= maxGovFeeForNFT, "fee too high");

        emit UpdateGovernanceFeeForNFT(governanceFeeForNFT, _fee);

        governanceFeeForNFT = _fee;
    }

    function setMaxCuratorFee(uint256 _fee) external onlyOwner {
        emit UpdateCuratorFee(governanceFee, _fee);

        maxCuratorFee = _fee;
    }
    function setMaxCuratorFeeForNFT(uint256 _fee) external onlyOwner {
        emit UpdateCuratorFeeForNFT(governanceFeeForNFT, _fee);

        maxCuratorFeeForNFT = _fee;
    }

    function setMinBidIncrease(uint256 _min) external onlyOwner {
        require(_min <= maxMinBidIncrease, "min bid increase too high");
        require(_min >= minMinBidIncrease, "min bid increase too low");

        emit UpdateMinBidIncrease(minBidIncrease, _min);

        minBidIncrease = _min;
    }
    function setMinBidIncreaseForNFT(uint256 _min) external onlyOwner {
        require(_min <= maxMinBidIncreaseForNFT, "min bid increase too high");
        require(_min >= minMinBidIncreaseForNFT, "min bid increase too low");

        emit UpdateMinBidIncreaseForNFT(minBidIncreaseForNFT, _min);

        minBidIncreaseForNFT = _min;
    }

    function setMinVotePercentage(uint256 _min) external onlyOwner {
        // 10000 is 100%
        require(_min <= 10000, "min vote percentage too high");

        emit UpdateMinVotePercentage(minVotePercentage, _min);

        minVotePercentage = _min;
    }
    function setMinVotePercentageForNFT(uint256 _min) external onlyOwner {
        // 10000 is 100%
        require(_min <= 10000, "min vote percentage too high");

        emit UpdateMinVotePercentageForNFT(minVotePercentageForNFT, _min);

        minVotePercentageForNFT = _min;
    }

    function setMaxReserveFactor(uint256 _factor) external onlyOwner {
        require(_factor > minReserveFactor, "max reserve factor too low");

        emit UpdateMaxReserveFactor(maxReserveFactor, _factor);

        maxReserveFactor = _factor;
    }
    function setMaxReserveFactorForNFT(uint256 _factor) external onlyOwner {
        require(_factor > minReserveFactorForNFT, "max reserve factor too low");

        emit UpdateMaxReserveFactorForNFT(maxReserveFactorForNFT, _factor);

        maxReserveFactorForNFT = _factor;
    }

    function setMinReserveFactor(uint256 _factor) external onlyOwner {
        require(_factor < maxReserveFactor, "min reserve factor too high");

        emit UpdateMinReserveFactor(minReserveFactor, _factor);

        minReserveFactor = _factor;
    }
    function setMinReserveFactorForNFT(uint256 _factor) external onlyOwner {
        require(_factor < maxReserveFactorForNFT, "min reserve factor too high");

        emit UpdateMinReserveFactorForNFT(minReserveFactorForNFT, _factor);

        minReserveFactorForNFT = _factor;
    }

    function setFeeReceiver(address payable _receiver) external onlyOwner {
        require(_receiver != address(0), "fees cannot go to 0 address");

        emit UpdateFeeReceiver(feeReceiver, _receiver);

        feeReceiver = _receiver;
    }
    function setFeeReceiverForNFT(address payable _receiver) external onlyOwner {
        require(_receiver != address(0), "fees cannot go to 0 address");

        emit UpdateFeeReceiverForNFT(feeReceiverForNFT, _receiver);

        feeReceiverForNFT = _receiver;
    }

    function isERC721(address nft) external override view returns(bool){
        return nft.supportsInterface(IID_IERC721);
    }
    function isERC1155(address nft) external override view returns(bool){
        return nft.supportsInterface(IID_IERC1155);
    }

     function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == IID_IERC1155 || interfaceId == IID_IERC721;
    }

    function setPlatformFee(address _index, uint256 _platformFee) public onlyOwner{
        platformFee[_index] = _platformFee;
    }

    function getPlatformFee(address _index) public override view returns(uint256) {
        return platformFee[_index];
    }

}