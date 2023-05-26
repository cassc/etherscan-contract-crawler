pragma solidity =0.8.7;

import "./IBasket.sol";
import "./IAuction.sol";

interface IFactory {
    struct Proposal {
        uint256 licenseFee;
        string tokenName;
        string tokenSymbol;
        address proposer;
        address[] tokens;
        uint256[] weights;
        address basket;
        uint256 maxSupply;
    }

    struct PendingChange{
        uint256 change;
        uint256 timestamp;
    }


    function proposal(uint256) external view returns (Proposal memory);
    function proposals(uint256[] memory _ids) external view returns (Proposal[] memory); 
    function proposalsLength() external view returns (uint256);
    function minLicenseFee() external view returns (uint256);
    function auctionDecrement() external view returns (uint256);
    function auctionMultiplier() external view returns (uint256);
    function bondPercentDiv() external view returns (uint256);
    function ownerSplit() external view returns (uint256);
    function auctionImpl() external view returns (IAuction);
    function basketImpl() external view returns (IBasket);
    function getProposalWeights(uint256 id) external view returns (address[] memory, uint256[] memory);

    function createBasket(uint256) external returns (IBasket);
    function proposeBasketLicense(uint256, string calldata, string calldata, address[] memory tokens, uint256[] memory weights, uint256) external returns (uint256);
    function setMinLicenseFee(uint256) external;
    function setAuctionDecrement(uint256) external;
    function setAuctionMultiplier(uint256) external;
    function setBondPercentDiv(uint256) external;
    function setOwnerSplit(uint256) external;

    event BasketCreated(address indexed basket, uint256 id);
    event BasketLicenseProposed(address indexed proposer, string tokenName, uint256 indexed id);

    event NewMinLicenseFeeSubmitted(uint256);
    event ChangedMinLicenseFee(uint256);
    event NewAuctionDecrementSubmitted(uint256);
    event ChangedAuctionDecrement(uint256);
    event NewAuctionMultiplierSubmitted(uint256);
    event ChangedAuctionMultipler(uint256);
    event NewBondPercentDivSubmitted(uint256);
    event ChangedBondPercentDiv(uint256);
    event NewOwnerSplitSubmitted(uint256);
    event ChangedOwnerSplit(uint256);
}