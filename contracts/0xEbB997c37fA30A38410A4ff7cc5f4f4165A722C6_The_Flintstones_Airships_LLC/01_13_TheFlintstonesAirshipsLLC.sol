// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/*
                    .:^~~!!!!!~^:.
                .^7J5GBB#########BGPY7~.
             :75G#####BBGP5555PGBB#####B57:
           ~YB####GY?~^:.      ..:~7YG####B5!.
         ~P####GJ^.                  .^?P####P!
       :Y####P!.                        .~5####5:
      ^G###B7        .::::::::.            !G###G~             .:::::::::::.          .::::::::::::::.      .::::.       :::::.     :::::::::::::::.
     ^G###P:        7PBBBBBBBBG5J!:         :5###B~            ?#BBB#####BBG5!.       5#BBB#########B^      5#B##G~     :G###B^    :B######BB######!
    .P###G:        ~####BBBBB#####GJ:        .P###G:           5####GPPPG#####J      .G####GPPPPPPPP5.     :B######?    ~####G.    ^PPPPG#####PPPPP:
    7###B~         J###B^.:::^!JB###G~        ^B###?          .G####~    J####G.     ~####G.               !#######&5:  J####5          7&###P
    5###5         .G###Y        :5###B^        5###G.         ~####G:  .:Y###&Y      ?####BYYYYYYYY:       J#########G~ P####7          5&##&?
   .G###J         ~####!         :B###7        ?###B:         J#####GGGGB####5:      5#######&&&&&#:      .P####7J#####JB####^         .B####~
   .P###Y         J###G:         ~####7        J###B:         5####BGB####B?^       .B####7               :B###B: !B########G.         ~####B.
    Y#B#G.       .G###Y        .7B###P.        P###5         :B####~ .5####J        ~####B~               !####G.  :P&######Y          ?&###5
    ~##B#?       !####!       ?G###BY.        7####!         !####G.  :P###&Y.      J&############&!      Y&##&Y    .J#####&7          P&&&&?
     J###B!      J###G.       5####J         ~B###Y          !5YY5?    :Y5YY5~      ?5YYYY555555Y5Y:     .J5YY5~      !5555Y:         .Y5555^
     .Y###B7    .G###J        .J####?       7B###5.
      .J####5^  !####~          ?####Y.   ^5####Y.
        ~P###B5~Y###G.           !B###5:~YB###G!
         .7P####B###J             ~B###B####G?.
           .!YB#####~              ^G####B5!.
              .!J557                :?YJ!:

 */

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

///@title The_Flintstones_Airships_LLC
contract The_Flintstones_Airships_LLC is ERC1155, Ownable {
    ///===================================================
    ///============= Custom errors =======================

    error WrongAmountRENT(
        address user,
        uint256 idTiket,
        uint256 amountTiket,
        uint256 amountRENT
    );
    error ErrorSendingFunds(address user, uint256 amount);
    error FranchiseDoesNotExist(address user, uint256 idFranchise);
    error TikeDoesNotExist(address user, uint256 idFranchise, uint256 idTikets);
    error TikeDoesNotActivate(
        address user,
        uint256 idFranchise,
        uint256 idTikets
    );
    error LimitByTiket(address user, uint256 idTiket, uint256 amount);
    error LimitByFranchise(address user, uint256 idFranchise, uint256 idTiket);
    error TicketAlreadyExists(uint256 idFranchise, uint256 idTiket);

    using Counters for Counters.Counter;

    /// ================================================
    /// ===========  Struc  ============================
    struct Account {
        uint256 idFranchise;
        uint256 amountRENT;
        uint256 amountStake;
        uint256 limitByFranchise;
        uint256 limitByUser;
        bool activate;
    }

    /// =================================================
    /// ============ Immutable storage ==================
    IERC20 private RENT;

    /// =================================================
    ///=========== Mutable Storage ======================


    Counters.Counter public idFranchise;

    mapping(uint256 => Account) public tikets;

    mapping(uint256 => uint256[]) public tiketsByFranchise;

    mapping(address => mapping(uint256 => uint256)) public amountTiketsByUser;

    mapping(uint256 => mapping(uint256 => uint256))
        public currentAmountStakeSaleByFranchise;

    mapping(address => bool) public profileChangesBalances;

    constructor() ERC1155("") {
        RENT = IERC20(0x285EB91bda97F85871AAD7ebe2dCCcbC8208DC81);

        uint8 idFranchiseInit = 1;
        uint8 idTiketInit = 1;
        uint256 balanceToken1Init = 280;
        uint256 maxStakeToken1Init = 280;
        uint256 amountStakeTiket1Init = balanceToken1Init / maxStakeToken1Init;
        uint256 valueTiket1UsdInit = 1000e18;
        idFranchise.increment();
        mint(balanceToken1Init);
        setTiketsValue(
            idFranchiseInit,
            idTiketInit,
            valueTiket1UsdInit,
            amountStakeTiket1Init,
            maxStakeToken1Init,
            maxStakeToken1Init
        );
    }

    /// =========================================================
    /// ==================== Events =============================

    event SetTiketsValue(
        address indexed owner,
        uint256 idFranchise,
        uint256 idTiket,
        uint256 amountRENT,
        uint256 amountStake,
        uint256 limitByFranchise,
        uint256 limitByUser
    );

    event BuyTiket(
        address indexed user,
        uint256 idFranchise,
        uint256 idTiket,
        uint256 tiketAmount
    );

    event ChangeStateTiket(uint256 idFranchise, uint256 idTiket, bool state);

    event AddNewProfileChangesBalances(
        address indexed owner,
        address newAddress
    );

    event TranferTikets(
        address indexed from,
        address indexed to,
        uint256 idTiket,
        uint256 tiketAmount
    );

    /// =========================================================
    /// ============  midifier ==================================

    modifier onlyProfileChangesBalances() {
        require(
            profileChangesBalances[msg.sender] || msg.sender == owner(),
            "Restricted : the caller does not have permissions"
        );
        _;
    }

    /// =========================================================
    /// ============ Functions ==================================

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function uri(uint256 id) public view override returns (string memory) {
        return
            string(
                abi.encodePacked(super.uri(id), Strings.toString(id), ".json")
            );
    }

    function mint(uint256 amount) public onlyOwner {
        _mint(owner(), idFranchise.current(), amount, "");
        idFranchise.increment();
    }

    function setTiketsValue(
        uint256 _idFranchise,
        uint256 _idTiket,
        uint256 _amountRENT,
        uint256 _amountStake,
        uint256 _limitByFranchise,
        uint256 _limitByUser
    ) public onlyOwner {
        if (tikets[_idTiket].idFranchise == _idFranchise) {
            revert TicketAlreadyExists(_idFranchise, _idTiket);
        }

        tikets[_idTiket] = Account(
            _idFranchise,
            _amountRENT,
            _amountStake,
            _limitByFranchise,
            _limitByUser,
            true
        );

        tiketsByFranchise[_idFranchise].push(_idTiket);
        emit SetTiketsValue(
            msg.sender,
            _idFranchise,
            _idTiket,
            _amountRENT,
            _amountStake,
            _limitByFranchise,
            _limitByUser
        );
    }

    function changeStateTiket(
        uint256 _idFranchise,
        uint256 _idTiket,
        bool state
    ) public onlyOwner {
        if (tikets[_idTiket].idFranchise != _idFranchise) {
            revert TikeDoesNotExist(msg.sender, _idFranchise, _idTiket);
        }

        tikets[_idTiket].activate = state;

        emit ChangeStateTiket(_idFranchise, _idTiket, state);
    }

    function buyTiket(
        uint256 _idFranchise,
        uint256 _idTiket,
        uint256 _tiketAmount,
        uint256 _amountRENT
    ) external {
        uint256 amountRENTdByTiket = tikets[_idTiket].amountRENT;

        if (balanceOf(owner(), _idFranchise) == 0) {
            revert FranchiseDoesNotExist(msg.sender, _idFranchise);
        }

        if (tikets[_idTiket].idFranchise != _idFranchise) {
            revert TikeDoesNotExist(msg.sender, _idFranchise, _idTiket);
        }

        if (!tikets[_idTiket].activate) {
            revert TikeDoesNotActivate(msg.sender, _idFranchise, _idTiket);
        }

        //no hay para vender de ese tiket
        uint256 currentSaleByFranchise = currentAmountStakeSaleByFranchise[
            _idFranchise
        ][_idTiket];
        if (
            _tiketAmount >
            tikets[_idTiket].limitByFranchise - currentSaleByFranchise
        ) {
            revert LimitByFranchise(msg.sender, _idFranchise, _idTiket);
        }

        if (
            _tiketAmount >
            (tikets[_idTiket].limitByUser -
                amountTiketsByUser[msg.sender][_idTiket])
        ) {
            revert LimitByTiket(msg.sender, _idTiket, _tiketAmount);
        }

        if (_amountRENT != amountRENTdByTiket * _tiketAmount) {
            revert WrongAmountRENT(
                msg.sender,
                _idTiket,
                _tiketAmount,
                _amountRENT
            );
        }

        emit BuyTiket(msg.sender, _idFranchise, _idTiket, _tiketAmount);

        currentAmountStakeSaleByFranchise[_idFranchise][
            _idTiket
        ] += _tiketAmount;
        amountTiketsByUser[msg.sender][_idTiket] += _tiketAmount;

        if (!RENT.transferFrom(msg.sender, owner(), _amountRENT)) {
            revert ErrorSendingFunds(msg.sender, _amountRENT);
        }
    }

    function addNewProfileChangesBalances(address newProfile) public onlyOwner {
        profileChangesBalances[newProfile] = true;
        emit AddNewProfileChangesBalances(msg.sender, newProfile);
    }

    function tranferTikets(
        address from,
        address to,
        uint256 idTiket,
        uint256 tiketAmount
    ) public onlyProfileChangesBalances {
        require(to != address(0), "ERC1155: transfer to the zero address");
        uint256 fromBalance = amountTiketsByUser[from][idTiket];
        require(
            fromBalance >= tiketAmount,
            "ERC1155: insufficient balance for transfer"
        );

        unchecked {
            amountTiketsByUser[from][idTiket] = fromBalance - tiketAmount;
        }

        amountTiketsByUser[to][idTiket] += tiketAmount;
        emit TranferTikets(from, to, idTiket, tiketAmount);
    }
}