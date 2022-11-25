// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/interface/router2.sol";
import "contracts/interface/mpo.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract MpoBuyTokenBon is OwnableUpgradeable {
    // ADDRESS
    address public MpoInvite;
    address public MpoNft;
    address public USDT;
    address public MPO;
    address public ROUTER;
    address public WALLET;

    // STATUS
    bool public swSwitch;
    bool public wSwitch;
    bool public idoRelease;
    uint public swTime;
    uint public wTime;
    uint public bonusNumber;

    uint public f_thisRoundTotal;
    uint public f_thisRoundClaimed;
    uint public f_lowestHold;

    struct IDOInfo {
        bool status;
        uint share;
        uint amount;
        uint price;
    }
    IDOInfo public ido;
    IDOInfo public idoInit;

    struct UserInfo {
        uint claimed;
        uint lastClaimTime;
    }
    mapping(uint => mapping(address => UserInfo)) public f_userInfo;

    mapping(address => bool) public admin;
    mapping(address => bool) public sw;
    mapping(address => bool) public w;
    mapping(address => address[]) public idoTeam;
    mapping(address => uint) public nftminted;
    mapping(address => bool) public isido;
    mapping(address => bool) public isidoClaimed;

    event BuyIdo(address indexed user, address indexed inv);
    event Minted(address indexed user, uint indexed amount);
    event ClaimBonus(address indexed user, uint indexed amount);
    event ClaimIDO(address indexed user, uint indexed amount);
    event MintNftBonus(address indexed user_, uint indexed amount_);

    modifier onlyAdmin() {
        require(admin[msg.sender], "not admin!");
        _;
    }

    function init() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        setAdmin(msg.sender);
        bonusNumber = 5;

        swSwitch = true;
        wSwitch = true;

        MpoInvite = 0x24A980baAc726f09D5c3EABf069bFbEB64236CF3;
        USDT = 0x55d398326f99059fF775485246999027B3197955;
        ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        WALLET = 0xDdBb87f99B9468CF6Daad0a6e5EA40676E83107E;
    }

    ////////////////////////////////
    ///////////// admin ////////////
    ////////////////////////////////

    function setAdmin(address admin_) public onlyOwner {
        admin[admin_] = true;
    }

    function setSW(address[] calldata swList_, bool b_) public onlyAdmin {
        for (uint i = 0; i < swList_.length; i++) {
            sw[swList_[i]] = b_;
            w[swList_[i]] = b_;
        }
    }

    function setW(address[] calldata wList_, bool b_) public onlyAdmin {
        for (uint i = 0; i < wList_.length; i++) {
            w[wList_[i]] = b_;
        }
    }

    function setThisRoundBonus(uint bonus_) public onlyAdmin {
        f_thisRoundTotal = bonus_;
        f_thisRoundClaimed = 0;
    }

    function setLowestHold(uint lowestHold_) public onlyAdmin {
        f_lowestHold = lowestHold_;
    }

    function setIDO(
        uint share_,
        uint amount_,
        uint price_,
        uint swTime_,
        uint wTime_
    ) public onlyAdmin {
        require(!ido.status, "is start");

        ido = IDOInfo({
            status: true,
            share: share_,
            amount: amount_,
            price: price_
        });
        idoInit = IDOInfo({
            status: true,
            share: share_,
            amount: amount_,
            price: price_
        });

        swTime = swTime_;
        wTime = wTime_;
    }

    function setSWandWtime(uint swT_, uint wT_) public onlyAdmin {
        swTime = swT_;
        wTime = wT_;
    }

    function safePull(
        address token,
        address wallet,
        uint amount
    ) external onlyOwner {
        IERC20(token).transfer(wallet, amount);
    }

    function setMpoInviteAddress(address addr_) public onlyOwner {
        MpoInvite = addr_;
    }

    function setMpoTokenAddress(address addr_) public onlyOwner {
        MPO = addr_;
    }

    function setMpoNftAddress(address addr_) public onlyOwner {
        MpoNft = addr_;
    }

    function setIdoSWswitch(bool b_) external onlyAdmin {
        swSwitch = b_;
    }

    function setIdoWswitch(bool b_) external onlyAdmin {
        wSwitch = b_;
    }

    function setIdoRelease(bool b_) external onlyAdmin {
        idoRelease = b_;
    }

    ////////////////////////////////
    ////////////// IDO /////////////
    ////////////////////////////////

    function addPool(
        uint256 mpoAmount,
        uint256 usdtAmount,
        address to_
    ) external onlyAdmin {
        address router = ROUTER;
        IERC20(USDT).approve(address(router), usdtAmount);
        IERC20(MPO).approve(address(router), mpoAmount);
        // add the liquidity
        IRouter02(router).addLiquidity(
            MPO,
            USDT,
            mpoAmount,
            usdtAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            to_,
            block.timestamp + 360
        );
    }

    function preInvite(address user_, address inv_) internal {
        address _inv = Iinvite(MpoInvite).checkInviter(user_);
        if (_inv != address(0)) {
            require(_inv == inv_, "inviter wrong");
        } else {
            Iinvite(MpoInvite).whoIsYourInviter(user_, inv_);
        }
        idoTeam[inv_].push(user_);
    }

    function preCheck() internal {
        require(ido.status, "not start yet");
        require(MpoInvite != address(0), "contract error");
        require(!isido[msg.sender], "bid");
        require(block.timestamp > swTime, "too early");
        if (block.timestamp > wTime) {
            swSwitch = false;
        }
        if (swSwitch) {
            require(sw[msg.sender], "not sw");
        }
        if (wSwitch) {
            require(w[msg.sender] || sw[msg.sender], "not w");
        }
    }

    function buyIdo(address inv_) public returns (bool) {
        if (ido.share == 0) {
            ido.status = false;
        }

        preCheck();
        preInvite(msg.sender, inv_);

        require(ido.share > 0, "out of sale!");
        ido.share -= 1;

        IERC20(USDT).transferFrom(msg.sender, WALLET, ido.price);

        isido[msg.sender] = true;
        emit BuyIdo(msg.sender, inv_);
        return true;
    }

    function claimIdo() public {
        require(idoRelease, "not release");
        require(isido[msg.sender], "not in ido");
        require(!isidoClaimed[msg.sender], "claimed");

        isidoClaimed[msg.sender] = true;
        IERC20(MPO).transfer(msg.sender, ido.amount);

        emit ClaimIDO(msg.sender, ido.amount);
    }

    function mintBonusNft(uint u_) public {
        require(MpoNft != address(0), "no nft");
        (uint max, uint minted) = checkNftBouns(msg.sender);
        require(max >= minted + u_, "out of amount");

        if (u_ > 1) {
            INft(MpoNft).mintMulti(msg.sender, 10001, u_);
        } else if (u_ == 1) {
            INft(MpoNft).mint(msg.sender, 10001);
        }

        nftminted[msg.sender] += u_;
        emit Minted(msg.sender, u_);
    }

    function changeNftMinted(address user_, uint u_) public onlyAdmin {
        (uint max, uint minted) = checkNftBouns(msg.sender);
        require(max >= minted + u_, "out of amount");
        nftminted[user_] += u_;
        emit MintNftBonus(user_, u_);
    }

    function checkTeam(address addr_) public view returns (address[] memory) {
        return idoTeam[addr_];
    }

    function checkTeamLength(address user_) public view returns (uint) {
        return idoTeam[user_].length;
    }

    function checkNftBouns(address user_)
        public
        view
        returns (uint limit, uint minted)
    {
        limit = (checkTeamLength(user_) / bonusNumber);
        // limit = 5;
        minted = nftminted[user_];
    }

    function mutiCheck(address user_)
        external
        view
        returns (
            uint[4] memory list,
            bool[2] memory b,
            uint[2] memory idoTime
        )
    {
        list[0] = idoInit.share - ido.share;
        list[1] = checkTeamLength(user_);
        (list[2], list[3]) = checkNftBouns(user_);
        if (ido.share == 0) {
            b[0] = false;
        } else {
            b[0] = true;
        }
        b[1] = isido[user_];
        idoTime = [swTime, wTime];
    }

    ////////////////////////////////
    /////////// Finance ////////////
    ////////////////////////////////

    function finance_checktoClaimBonus(address user_)
        public
        view
        returns (uint aa)
    {
        uint p = IMPOT(MPO).checkPhase();
        uint temp = IMPOT(MPO).checkPhaseUserBonus(p, user_);
        if (temp > 0) {
            aa = temp - f_userInfo[p][user_].claimed;
        }
    }

    function finance_claimBonus() public returns (uint rew) {
        require(f_thisRoundClaimed < f_thisRoundTotal, "out of bonus");
        require(IMPOT(MPO).checkPhaseStatus(), "not start");
        require(
            IERC20(MPO).balanceOf(msg.sender) >= f_lowestHold,
            "user ba too low"
        );

        address user = msg.sender;
        uint _phase = IMPOT(MPO).checkPhase();
        uint _thisRoundRemaining = f_thisRoundTotal - f_thisRoundClaimed;

        rew = finance_checktoClaimBonus(user);
        if (rew > 0) {
            if (_thisRoundRemaining < rew) {
                rew = _thisRoundRemaining;
                IMPOT(MPO).setBuyTokensBonusPhaseStatus(false);
            }
            f_userInfo[_phase][user].claimed += rew;
            f_userInfo[_phase][user].lastClaimTime = block.timestamp;
            f_thisRoundClaimed += rew;
            IERC20(MPO).transfer(user, rew);

            emit ClaimBonus(user, rew);
        }
    }
}