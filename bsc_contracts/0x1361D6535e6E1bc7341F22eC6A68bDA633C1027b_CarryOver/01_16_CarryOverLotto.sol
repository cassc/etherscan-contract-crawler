// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./interfaces/ICarryOverLotto.sol";
import "./interfaces/INormalLotto.sol";
import "./libraries/SeriLib.sol";

contract CarryOver is ICarryOverLotto, Ownable, ReentrancyGuard {
    using SeriLib for uint256;
    using SafeCast for uint256;
    using Address for address;
    using SafeERC20 for IERC20;

    Config private _config;

    uint256[] private _sharePercents;
    address[] private _shareAddresses;

    mapping(uint256 => uint256[]) private _winners;
    mapping(uint256 => uint256[]) private _nftsTaken;
    mapping(uint256 => uint256[]) private _takenPrizes;
    mapping(uint256 => uint256[]) private _assetIndices;
    mapping(uint256 => uint256[]) private _initialPrizes;
    mapping(uint256 => address[]) private _initialAssets;

    mapping(uint256 => Seri) private _series;
    // seriId => userAddr => Ticket
    mapping(uint256 => mapping(address => string[])) private _userTickets;
    // seriId => assetIdx => AssetBalance
    mapping(uint256 => mapping(uint256 => AssetBalance)) private _balances;
    // seriId => user => ticketId => tokenId
    mapping(uint256 => mapping(address => mapping(uint256 => uint256))) public userTicketsWon;
    // seriId => user => tokenId => ticketId
    mapping(uint256 => mapping(address => mapping(uint256 => uint256))) public userTicketsWonb;

    constructor() payable {
        Config memory cfg;
        cfg.postAddr = 0x949a4A932dEc9727d20c3Bf9ABcaBF19aE2d860F;
        cfg.verifier = 0xe9d9b26f1Af5722627c976029A22DeF7c51E0CcD;
        cfg.nft = INFT(0x3E5b39625eE9934Db40Bb601f95EEf841687BF21);
        cfg.normalLotto = INormalLotto(0x2152aEE15e021C01A57aC7E543B39230ae2fCaa1);

        _config = cfg;
    }

    function openSeri(
        uint256 seri_,
        uint256 price_,
        uint256 postPrice_,
        uint256 max2sale_,
        address[] calldata initialAssets_,
        uint256[] calldata initialPrizes_
    ) external payable override onlyOwner {
        require(price_ >= postPrice_, "INVALID_PARAMS");

        Seri memory seri = _series[seri_];
        require(seri.embededInfo == 0, "EXISTED");

        Config memory cfg = _config;
        uint256 currentCOSeri = cfg.currentCOSeriId;
        require(currentCOSeri == 0 || _series[currentCOSeri].status != 0, "CO_OPENING");

        _config.currentCOSeriId = seri_.toUint96();
        seri.seriType = true;
        seri.embededInfo = SeriLib.encode(price_, max2sale_, postPrice_, INormalLotto(cfg.normalLotto).expiredPeriod());

        _series[seri_] = seri;
        __transferCarryOverAssetTo(seri_, initialAssets_, initialPrizes_);
        emit OpenSeri(seri_, seri.seriType ? 2 : 1);
    }

    function buy(
        uint256 seri_,
        string calldata numberInfo_,
        uint256 assetIdx_,
        uint256 totalTicket_
    ) external payable override nonReentrant {
        INormalLotto _normalLotto = _config.normalLotto;
        string[] memory priceFeeds = _normalLotto.getPriceFeeds();

        uint256 assetAmt;
        uint256 postAmt;
        {
            Seri memory seri = _series[seri_];
            uint256 embededInfo = seri.embededInfo;
            unchecked {
                require(seri.soldTicket + totalTicket_ <= embededInfo.max2Sale(), "EXCEED_MAX_TO_SALE");
            }
            assetAmt = ticket2Asset(seri_, priceFeeds[assetIdx_]) * totalTicket_;
            postAmt = (assetAmt * embededInfo.postPrice()) / embededInfo.price();
            unchecked {
                _series[seri_].soldTicket += totalTicket_.toUint32();
            }
        }

        uint256 assetRemain = _buyTransfer(
            IAssets(address(_normalLotto)).getAsset(priceFeeds[assetIdx_]).asset,
            assetAmt,
            postAmt
        );
        _userTickets[seri_][_msgSender()].push(numberInfo_);
        if (_balances[seri_][assetIdx_].remain == 0) _assetIndices[seri_].push(assetIdx_);
        _balances[seri_][assetIdx_].remain += assetRemain;
        emit BuyTicket(_normalLotto.asset2USD(priceFeeds[assetIdx_]), assetAmt);
    }

    function _permit(
        uint256 timestamp_,
        string memory result_,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private view returns (bool) {
        return
            ECDSA.recover(
                keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        keccak256(abi.encodePacked(timestamp_, result_))
                    )
                ),
                v,
                r,
                s
            ) == _config.verifier;
    }

    function openResult(
        uint256 seri_,
        bool isWin_,
        uint256 _totalWin,
        uint256 timestamp_,
        string calldata result_,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override onlyOwner {
        Seri memory seri = _series[seri_];
        require(seri.status == 1, "NOT_CLOSE");
        require(timestamp_ > _config.currentSignTime, "INVALID_TIMESTAMP");
        require(_permit(timestamp_, result_, v, r, s), "INVALID_SIG");

        if (isWin_) {
            seri.status = 2;
            seri.totalWin = _totalWin.toUint32();
        } else {
            seri.status = 3;
            __transferRemainAsset(seri_, _assetIndices[seri_]);
            __transferCarryOverRemainAsset(seri_);
        }
        seri.endTime = block.timestamp;
        seri.result = result_;

        _series[seri_] = seri;
        _config.currentSignTime = timestamp_.toUint96();

        emit OpenResult(seri_, isWin_);
    }

    function closeSeri(uint256 seri_) external override onlyOwner {
        Seri memory seri = _series[seri_];
        require(seri.status == 0, "NOT_OPEN");
        require(seri.soldTicket == seri.embededInfo.max2Sale(), "NOT_SOLD_OUT");
        _series[seri_].status = 1;
        emit CloseSeri(seri_, block.timestamp);
    }

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
    ) external override onlyOwner {
        {
            Seri memory seri = _series[seri_];
            require(seri.nonce != turn_, "ALREADY_PAID");
            require(seri.status == 2, "NOT_WINNER");
            unchecked {
                require(seri.totalWin >= _winners[seri_].length + totalTicket_, "INVALID_WINNERS");
            }
        }

        {
            Config memory cfg = _config;
            require(timestamp_ > cfg.currentSignTime, "INVALID_TIMESTAMP");

            require(
                ECDSA.recover(
                    keccak256(
                        abi.encodePacked(
                            "\x19Ethereum Signed Message:\n32",
                            getbytesDataSetWinners(
                                timestamp_,
                                seri_,
                                winners_,
                                buyTickets_,
                                totalTicket_,
                                assets_,
                                turn_
                            )
                        )
                    ),
                    v,
                    r,
                    s
                ) == cfg.verifier,
                "INVALID_SIG"
            );
            _sendNFT(cfg.nft, seri_, startTime_, winners_, assets_, buyTickets_);
        }

        _config.currentSignTime = (timestamp_).toUint96();
        _series[seri_].nonce = (turn_).toUint40();

        emit SetWinners(seri_, turn_);
    }

    function takePrize(uint256 nftId_) external override nonReentrant {
        address sender = _msgSender();
        // require(sender == tx.origin && !sender.isContract(), "ONLY_EOA");
        Seri memory seri;
        uint256 _seri;
        uint256 _winTickets;
        uint256 _buyTickets;
        {
            INFT _nft = _config.nft;
            (_seri, , , , , _winTickets, , _buyTickets, ) = _nft.metadatas(nftId_);

            seri = _series[_seri];
            require(seri.status == 2, "NOT_WINNER");
            unchecked {
                require(seri.endTime + seri.embededInfo.expiredPeriod() > block.timestamp, "EXPIRED");
            }
            _nft.transferFrom(sender, address(this), nftId_);
            _nft.burn(nftId_);
            _nftsTaken[_seri].push(nftId_);
            __takePrize(_seri, _winTickets, _buyTickets);
        }
    }

    function takePrizeExpired(uint256 seri_) external override onlyOwner {
        Seri memory seri = _series[seri_];

        require(!seri.takeAssetExpired, "TAKED");
        unchecked {
            require(block.timestamp > seri.endTime + seri.embededInfo.expiredPeriod(), "NOT_EXPIRED");
        }

        _series[seri_].takeAssetExpired = true;

        Config memory cfg = _config;
        __transferRemainAsset(seri_, _assetIndices[seri_]);
        address[] memory initialAsset = _initialAssets[seri_];
        uint256 length = initialAsset.length;
        uint256[] memory initialPrize = _initialPrizes[seri_];
        uint256[] memory takenPrize = _takenPrizes[seri_];
        address carryOverAddr = cfg.normalLotto.carryOver();
        for (uint256 i; i < length; ) {
            __transfer(initialAsset[i], carryOverAddr, initialPrize[i] - takenPrize[i]);
            unchecked {
                ++i;
            }
        }
    }

    function configSigner(address _signer) external override {
        require(_msgSender() == _config.verifier, "UNAUTHORIZED");
        _config.verifier = _signer;
    }

    function configAddress(
        address post_,
        address nft_,
        address normalLotto_
    ) external override onlyOwner {
        Config memory cfg = _config;
        cfg.postAddr = post_;
        cfg.nft = INFT(nft_);
        cfg.normalLotto = INormalLotto(normalLotto_);

        _config = cfg;
    }

    function configAffiliate(address[] calldata shareAddresses_, uint256[] calldata sharePercents_) external onlyOwner {
        uint256 length = shareAddresses_.length;
        require(length == sharePercents_.length, "LENGTH_MISMATCH");
        uint256 sumPercents;
        for (uint256 i; i < length; ) {
            sumPercents += sharePercents_[i];
            unchecked {
                ++i;
            }
        }
        require(sumPercents < 1e6, "INVALID_PARAMS");
        _shareAddresses = shareAddresses_;
        _sharePercents = sharePercents_;
    }

    function getbytesDataSetWinners(
        uint256 timestamp_,
        uint256 seri_,
        address[] memory winners_,
        uint256[][] memory buyTickets_,
        uint256 totalTicket_,
        string[] memory assets_,
        uint256 turn_
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(timestamp_, abi.encode(seri_, winners_, buyTickets_, totalTicket_, assets_, turn_))
            );
    }

    function getAffilicateConfig() external view returns (address[] memory, uint256[] memory) {
        return (_shareAddresses, _sharePercents);
    }

    function seriAssetRemain(uint256 _seri, uint256 _asset) external view override returns (uint256) {
        return _balances[_seri][_asset].remain;
    }

    function getUserTickets(uint256 _seri, address _user) external view override returns (string[] memory) {
        return _userTickets[_seri][_user];
    }

    function getSeriWinners(uint256 _seri) external view override returns (uint256[] memory) {
        return _winners[_seri];
    }

    function getNftsTaken(uint256 _seri) external view override returns (uint256[] memory) {
        return _nftsTaken[_seri];
    }

    function getSeriesAssets(uint256 _seri) external view override returns (uint256[] memory) {
        return _assetIndices[_seri];
    }

    function getAsset(string memory _symbol) external view override returns (Asset memory _asset) {
        _asset = IAssets(address(_config.normalLotto)).getAsset(_symbol);
    }

    function currentSignTime() external view override returns (uint256) {
        return _config.currentSignTime;
    }

    function currentCarryOverSeri() external view override returns (uint256) {
        return _config.currentCOSeriId;
    }

    function signer() external view override returns (address) {
        return _config.verifier;
    }

    function postAddress() external view override returns (address payable) {
        return payable(_config.postAddr);
    }

    function normalLotto() external view returns (INormalLotto) {
        return _config.normalLotto;
    }

    function nft() external view override returns (INFT) {
        return _config.nft;
    }

    function seriExpiredPeriod(uint256 seri_) external view override returns (uint256) {
        return _series[seri_].embededInfo.expiredPeriod();
    }

    function postPrices(uint256 seri_) external view override returns (uint256) {
        return _series[seri_].embededInfo.postPrice();
    }

    function currentTurn(uint256 seri_) external view override returns (uint256) {
        return _series[seri_].nonce;
    }

    function series(uint256 seri_)
        external
        view
        override
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
        )
    {
        Seri memory seri = _series[seri_];
        price = seri.embededInfo.price();
        soldTicket = seri.soldTicket;
        result = seri.result;
        status = seri.status;
        endTime = seri.endTime;
        takeAssetExpired = seri.takeAssetExpired;
        max2sale = seri.embededInfo.max2Sale();
        totalWin = seri.totalWin;
        seriType = seri.seriType ? 2 : 1;
        initPrizeTaken = seri.initPrizeTaken;
        winInitPrize = seri.winInitPrice;
    }

    function totalPrize(uint256 seri_) external view override returns (uint256 _prize) {
        uint256[] memory assetIndices = _assetIndices[seri_];
        uint256 length = assetIndices.length;
        uint256 assetIdx;
        Config memory cfg = _config;
        string[] memory priceFeeds = cfg.normalLotto.getPriceFeeds();
        AssetBalance memory assetBalance;
        for (uint256 i; i < length; ) {
            assetIdx = assetIndices[i];
            assetBalance = _balances[seri_][assetIdx];
            if (assetBalance.remain != 0) {
                _prize += cfg.normalLotto.asset2USD(priceFeeds[assetIdx], assetBalance.remain);
            }
            unchecked {
                ++i;
            }
        }
    }

    function ticket2Asset(uint256 seri_, string memory symbol_) public view returns (uint256) {
        return (_series[seri_].embededInfo.price() * 1 ether) / _config.normalLotto.asset2USD(symbol_);
    }

    function _buyTransfer(
        address asset_,
        uint256 assetAmt_,
        uint256 postAmt_
    ) private returns (uint256 assetRemain) {
        __transferFrom(asset_, _msgSender(), address(this), assetAmt_, msg.value);
        __transfer(asset_, _config.postAddr, assetAmt_ - postAmt_);

        address[] memory shareAddress = _shareAddresses;
        uint256[] memory sharePercents = _sharePercents;
        assetRemain = postAmt_;
        uint256 shareAmount;
        uint256 length = shareAddress.length;
        for (uint256 i; i < length; ) {
            shareAmount = (postAmt_ * sharePercents[i]) / 1e6;
            __transfer(asset_, shareAddress[i], shareAmount);

            unchecked {
                assetRemain -= shareAmount;
                ++i;
            }
        }
    }

    function _sendNFT(
        INFT nft_,
        uint256 seri_,
        uint256 startTime_,
        address[] memory winners_,
        string[] memory assets_,
        uint256[][] memory buyTickets_
    ) private {
        uint256 winnerLength = winners_.length;
        require(100 >= winnerLength, "MAX_LOOP");

        uint256 tokenID;
        uint256 totalWin;
        string memory result;
        {
            Seri memory seri = _series[seri_];
            totalWin = seri.totalWin;
            result = seri.result;
        }
        address winner;
        for (uint256 i; i < winnerLength; ) {
            winner = winners_[i];
            for (uint256 j; j < buyTickets_[i].length; ) {
                tokenID = __mintNFT(nft_, winner, seri_, startTime_, totalWin, result, assets_[i]);
                _winners[seri_].push(tokenID);

                userTicketsWon[seri_][winner][buyTickets_[i][j]] = tokenID;
                userTicketsWonb[seri_][winner][tokenID] = buyTickets_[i][j];
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    function __mintNFT(
        INFT nft_,
        address to_,
        uint256 seri_,
        uint256 startTime_,
        uint256 winTickets_,
        string memory result_,
        string memory asset_
    ) private returns (uint256) {
        return nft_.mint(to_, seri_, startTime_, block.timestamp, result_, 2, winTickets_, to_, 1, asset_);
    }

    function __takePrize(
        uint256 seri_,
        uint256 winTickets_,
        uint256 buyTickets_
    ) private {
        address sender = _msgSender();
        {
            uint256 takeAmt;
            uint256 remain;
            uint256[] memory assetIndices = _assetIndices[seri_];
            uint256 length = assetIndices.length;
            uint256 assetIdx;
            INormalLotto _normalLotto = _config.normalLotto;
            AssetBalance memory assetBalance;
            string[] memory priceFeeds = _normalLotto.getPriceFeeds();
            for (uint256 i; i < length; ) {
                assetIdx = assetIndices[i];
                assetBalance = _balances[seri_][assetIdx];
                remain = assetBalance.remain;
                if (remain != 0) {
                    takeAmt = assetBalance.winAmt;

                    if (takeAmt == 0) {
                        takeAmt = (remain * buyTickets_) / winTickets_;
                        _balances[seri_][assetIdx].winAmt = takeAmt;
                    }
                    unchecked {
                        _balances[seri_][assetIdx].remain -= takeAmt;
                    }

                    __transfer(IAssets(address(_normalLotto)).getAsset(priceFeeds[assetIdx]).asset, sender, takeAmt);
                }
                unchecked {
                    ++i;
                }
            }
        }

        address[] memory initialAsset = _initialAssets[seri_];
        uint256 coLength = initialAsset.length;
        uint256 takeAssetInitialAmt;
        uint256[] memory initialPrize = _initialPrizes[seri_];
        uint256[] memory takenPrizes = _takenPrizes[seri_];
        for (uint256 j; j < coLength; ) {
            takeAssetInitialAmt = (initialPrize[j] * buyTickets_) / winTickets_;
            takenPrizes[j] += takeAssetInitialAmt;
            __transfer(initialAsset[j], sender, takeAssetInitialAmt);
            unchecked {
                ++j;
            }
        }
        _takenPrizes[seri_] = takenPrizes;
    }

    function __transferCarryOverAssetTo(
        uint256 seri_,
        address[] calldata initialAssets_,
        uint256[] calldata initialPrizes_
    ) private {
        uint256 length = initialAssets_.length;
        require(length == initialPrizes_.length, "LENGTH_MISMATCH");

        _initialAssets[seri_] = initialAssets_;
        _initialPrizes[seri_] = initialPrizes_;
        _takenPrizes[seri_] = new uint256[](length);

        address sender = _msgSender();
        uint256 msgValue = msg.value;
        for (uint256 i; i < length; ) {
            __transferFrom(initialAssets_[i], sender, address(this), initialPrizes_[i], msgValue);
            unchecked {
                ++i;
            }
        }
    }

    function __transferCarryOverRemainAsset(uint256 seri_) private {
        INormalLotto _normalLotto = _config.normalLotto;
        address[] memory initialAsset = _initialAssets[seri_];
        uint256 length = initialAsset.length;
        uint256[] memory initialPrize = _initialPrizes[seri_];
        address carryOverAddr = _normalLotto.carryOver();
        for (uint256 i; i < length; ) {
            __transfer(initialAsset[i], carryOverAddr, initialPrize[i]);
            unchecked {
                ++i;
            }
        }
    }

    function __transferRemainAsset(uint256 seri_, uint256[] memory assetIndices_) private {
        uint256 length = assetIndices_.length;
        uint256 assetIdx;
        uint256 remain;
        INormalLotto _normalLotto = _config.normalLotto;
        string[] memory priceFeeds = _normalLotto.getPriceFeeds();
        address carryOverAddr = _normalLotto.carryOver();
        for (uint256 i; i < length; ) {
            assetIdx = assetIndices_[i];
            remain = _balances[seri_][assetIdx].remain;
            delete _balances[seri_][assetIdx].remain;
            __transfer(IAssets(address(_normalLotto)).getAsset(priceFeeds[assetIdx]).asset, carryOverAddr, remain);

            unchecked {
                ++i;
            }
        }
    }

    function __transferFrom(
        address asset_,
        address from_,
        address to_,
        uint256 amount_,
        uint256 msgValue_
    ) private {
        if (amount_ == 0) return;
        if (asset_ == address(0)) {
            require(msgValue_ >= amount_, "INSUFICIENT_BALANCE");
        } else IERC20(asset_).safeTransferFrom(from_, to_, amount_);
    }

    function __transfer(
        address asset_,
        address to_,
        uint256 amount_
    ) private {
        if (amount_ == 0) return;
        if (asset_ == address(0)) {
            // solhint-disable-next-line
            (bool ok, ) = payable(to_).call{ value: amount_ }("");
            require(ok, "INSUFICIENT_BALANCE");
        } else IERC20(asset_).safeTransfer(to_, amount_);
    }
}