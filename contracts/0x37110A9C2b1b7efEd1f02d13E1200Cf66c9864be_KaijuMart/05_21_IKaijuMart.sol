// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./IKingzInTheShell.sol";
import "./IMutants.sol";
import "./IScientists.sol";
import "./IScales.sol";
import "./IRWaste.sol";
import "./IKaijuMartRedeemable.sol";
import "./IAuctionManager.sol";
import "./IDoorbusterManager.sol";
import "./IRaffleManager.sol";
import "./IKaijuMart.sol";

interface IKaijuMart {
    enum LotType {
        NONE,
        AUCTION,
        RAFFLE,
        DOORBUSTER
    }

    enum PaymentToken {
        RWASTE,
        SCALES,
        EITHER
    }

    struct Lot {
        uint104 rwastePrice;
        uint104 scalesPrice;
        LotType lotType;
        PaymentToken paymentToken;
        IKaijuMartRedeemable redeemer;
    }

    struct CreateLot {
        PaymentToken paymentToken;
        IKaijuMartRedeemable redeemer;
    }

    struct KaijuContracts {
        IKingzInTheShell kaiju;
        IMutants mutants;
        IScientists scientists;
        IRWaste rwaste;
        IScales scales;
    }

    struct ManagerContracts {
        IAuctionManager auction;
        IDoorbusterManager doorbuster;
        IRaffleManager raffle;
    }

    event Create(
        uint256 indexed id,
        LotType indexed lotType,
        address indexed managerContract
    );

    event Bid(
        uint256 indexed id,
        address indexed account,
        uint104 value
    );

    event Redeem(
        uint256 indexed id,
        uint32 indexed amount,
        address indexed to,
        IKaijuMartRedeemable redeemer
    );

    event Refund(
        uint256 indexed id,
        address indexed account,
        uint104 value
    );

    event Purchase(
        uint256 indexed id,
        address indexed account,
        uint64 amount
    );

    event Enter(
        uint256 indexed id,
        address indexed account,
        uint64 amount
    );

    // 🦖👑👶🧬👨‍🔬👩‍🔬🧪

    function isKing(address account) external view returns (bool);

    // 💻💻💻💻💻 ADMIN FUNCTIONS 💻💻💻💻💻

    function setKaijuContracts(KaijuContracts calldata _kaijuContracts) external;

    function setManagerContracts(ManagerContracts calldata _managerContracts) external;

    // 📣📣📣📣📣 AUCTION FUNCTIONS 📣📣📣📣📣

    function getAuction(uint256 auctionId) external view returns (IAuctionManager.Auction memory);

    function getBid(uint256 auctionId, address account) external view returns (uint104);

    function createAuction(
        uint256 lotId,
        CreateLot calldata lot,
        IAuctionManager.CreateAuction calldata auction
    ) external;

    function close(
        uint256 auctionId,
        uint104 lowestWinningBid,
        address[] calldata tiebrokenWinners
    ) external;

    function bid(uint256 auctionId, uint104 value) external;

    function refund(uint256 auctionId) external;

    function redeem(uint256 auctionId) external;

    // 🎟🎟🎟🎟🎟 RAFFLE FUNCTIONS 🎟🎟🎟🎟🎟

    function getRaffle(uint256 raffleId) external view returns (IRaffleManager.Raffle memory);

    function createRaffle(
        uint256 lotId,
        CreateLot calldata lot,
        uint104 rwastePrice,
        uint104 scalesPrice,
        IRaffleManager.CreateRaffle calldata raffle
    ) external;

    function draw(uint256 raffleId, bool vrf) external;

    function enter(uint256 raffleId, uint32 amount, PaymentToken token) external;

    // 🛒🛒🛒🛒🛒 DOORBUSTER FUNCTIONS 🛒🛒🛒🛒🛒

    function getDoorbuster(uint256 doorbusterId) external view returns (IDoorbusterManager.Doorbuster memory);

    function createDoorbuster(
        uint256 lotId,
        CreateLot calldata lot,
        uint104 rwastePrice,
        uint104 scalesPrice,
        uint32 supply
    ) external;

    function purchase(
        uint256 doorbusterId,
        uint32 amount,
        PaymentToken token,
        uint256 nonce,
        bytes calldata signature
    ) external;
}