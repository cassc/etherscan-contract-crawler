// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IAssets.sol";
import "./INFT.sol";
import "./INormalLotto.sol";

interface ICarryOverLotto is IAssets {
    event OpenSeri(uint256 indexed seriId, uint256 indexed seriType);
    event CloseSeri(uint256 indexed seriId, uint256 endTime);
    event OpenResult(uint256 indexed seriId, bool won);
    event BuyTicket(uint256 cryptoRate, uint256 totalAmount);
    event SetWinners(uint256 seri, uint256 turn);

    // 4 slot
    struct Config {
        // slot #0
        INFT nft;
        uint96 expiredPeriod;
        // slot #1
        address postAddr;
        uint96 currentSignTime;
        // slot #2
        address verifier;
        uint96 currentCOSeriId;
        // slot #3
        INormalLotto normalLotto;
    }

    struct AssetBalance {
        uint256 remain;
        uint256 winAmt;
    }

    struct Seri {
        // slot #0
        uint8 status;
        bool seriType;
        bool takeAssetExpired;
        uint32 soldTicket;
        uint32 totalWin;
        uint40 nonce;
        uint64 winInitPrice;
        uint64 initPrizeTaken;
        // slot #1
        uint256 endTime;
        // slot #2
        uint256 embededInfo;
        // slot #3
        string result;
    }

    function openSeri(
        uint256 seri_,
        uint256 price_,
        uint256 postPrice_,
        uint256 max2sale_,
        address[] calldata initialAssets_,
        uint256[] calldata initialPrizes_
    ) external payable;

    function buy(
        uint256 seri_,
        string calldata numberInfo_,
        uint256 assetIdx_,
        uint256 totalTicket_
    ) external payable;

    function openResult(
        uint256 seri_,
        bool isWin_,
        uint256 _totalWin,
        uint256 timestamp_,
        string calldata result_,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function closeSeri(uint256 seri_) external;

    function setWinners(
        uint256 seri_,
        uint256 startTime_,
        address[] memory winners_,
        uint256[][] memory buyTickets_,
        uint256 totalTicket_,
        string[] memory assets_,
        uint256 turn_,
        uint256 timestamp_,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function takePrize(uint256 nftId_) external;

    function takePrizeExpired(uint256 seri_) external;

    function configSigner(address _signer) external;

    function configAddress(
        address post_,
        address nft_,
        address normalLotto_
    ) external;

    function configAffiliate(address[] calldata shareAddress_, uint256[] calldata sharePercents_) external;

    // VIEW
    function getAffilicateConfig() external view returns (address[] memory, uint256[] memory);

    function seriAssetRemain(uint256 _seri, uint256 _asset) external view returns (uint256);

    function getUserTickets(uint256 _seri, address _user) external view returns (string[] memory);

    function getSeriWinners(uint256 _seri) external view returns (uint256[] memory);

    function getNftsTaken(uint256 _seri) external view returns (uint256[] memory);

    function getSeriesAssets(uint256 _seri) external view returns (uint256[] memory);

    function getAsset(string memory _symbol) external view returns (Asset memory _asset);

    function currentSignTime() external view returns (uint256);

    function currentCarryOverSeri() external view returns (uint256);

    function signer() external view returns (address);

    function postAddress() external view returns (address payable);

    function normalLotto() external view returns (INormalLotto);

    function nft() external view returns (INFT);

    function seriExpiredPeriod(uint256 seri_) external view returns (uint256);

    function postPrices(uint256 seri_) external view returns (uint256);

    function currentTurn(uint256 seri_) external view returns (uint256);

    function series(uint256 seri_)
        external
        view
        returns (
            uint256 price,
            uint256 soldTicket,
            string memory result,
            uint256 status,
            uint256 endTime,
            bool takeAssetExpired,
            uint256 max2sale,
            uint256 totalWin,
            uint256 seriType,
            uint256 initPrizeTaken,
            uint256 winInitPrize
        );

    function totalPrize(uint256 seri_) external view returns (uint256 _prize);
}