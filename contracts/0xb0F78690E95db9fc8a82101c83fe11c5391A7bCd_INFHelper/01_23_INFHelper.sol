pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./INFFactory.sol";
import "./interfaces/IMisoCrowdsale.sol";
import "./interfaces/IINFFactory.sol";


interface IPaymentToken is IERC20 {
    function symbol() external view returns (string memory);
}

contract INFHelper {
    IINFFactory private immutable infFactory;

    constructor(address factoryAddress) {
        infFactory = IINFFactory(factoryAddress);
    }

    struct Info {
        address auction;
        uint256 commitment;
        uint256 tokensClaimable;
        uint256 remainingToBeClaimed;
        string commitmentTokenSymbol;
    }

    function  auctionInfo(IERC20 token, address user) public view returns (Info[] memory) {
        IMisoCrowdsale misoCrowdsale;
        address[] memory auctions = infFactory.getAuctions(token);
        Info[] memory info = new Info[](auctions.length);
        for (uint256 i = 0; i < auctions.length; i++) {
            address auction = auctions[i];
            misoCrowdsale = IMisoCrowdsale(auction);
            uint256 tokensClaimable = misoCrowdsale.tokensClaimable(user);
            uint256 commitment = misoCrowdsale.commitments(user);

            info[i].auction = auction;
            info[i].commitment = commitment;
            info[i].tokensClaimable = tokensClaimable;
            info[i].remainingToBeClaimed = misoCrowdsale.getTokenAmount(commitment) - tokensClaimable;
            info[i].commitmentTokenSymbol = IPaymentToken(misoCrowdsale.paymentCurrency()).symbol();
        }
        return info;
    }

    function claimAll(address[] calldata auctions, address user) external {
        IMisoCrowdsale misoCrowdsale;
        for (uint256 i = 0; i < auctions.length; i++) {
            address auction = auctions[i];
            misoCrowdsale = IMisoCrowdsale(auction);
            misoCrowdsale.withdrawTokens(user);
        }
    }
}