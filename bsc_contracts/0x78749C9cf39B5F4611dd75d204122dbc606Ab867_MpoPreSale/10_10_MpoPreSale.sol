// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/interface/router2.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

// /Users/lay_chen/Desktop/HardhatProject/hardhat-project/node_modules/@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol
interface IMPOInvite {
    function whoIsYourInviter(address, address) external returns (bool);

    function checkInviter(address) external view returns (address);
}

contract MpoPreSale is OwnableUpgradeable {
    // pre-sale info
    uint private preSaleAmount;
    uint private preSaleShare;
    uint private preSalePrice;

    // after Sale
    uint private preSaleInitShare;
    uint private preSaleTatol;
    uint private preSaleClaimed;
    uint private tatolToClaim;
    // ADDRESS
    address public PANCAKE_ROUTER;
    address public PANCAKE_FACTORY;
    address public USDT;
    address public MPO;
    address public INVITE;
    address public WALLET;
    address[] private _excluded;
    address[] public offlinePreSale;
    address[] public onlinePreSale;

    uint public slip;
    uint public bonusNumber;
    uint public releaseAmount;
    uint public constant MAX_INT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    bool public status;
    bool public autoSellBuy;

    struct UserInfo {
        bool isPreSale;
        uint amount;
        uint toClaim;
        uint lastClaimedTime;
        uint claimed;
    }
    mapping(address => UserInfo) public userInfo;

    mapping(address => uint) public nftminted;
    mapping(address => uint) internal basicNft;
    mapping(address => address[]) public preSaleTeam;
    mapping(uint => address[]) public path;
    mapping(address => bool) public isExcluded;
    mapping(address => bool) public admin;

    event PreSaleProcess(address indexed user, address indexed inviter);
    event Withdraw(address indexed user, uint indexed amount);
    event Minted(address indexed user, uint indexed amount);

    // 2.0
    address public MpoNft;
    modifier onlyAdmin() {
        require(admin[msg.sender], "not admin!");
        _;
    }

    ////////////////////////////////
    ///////////// admin ////////////
    ////////////////////////////////

    function init() public initializer {
        status = true;
        __Context_init_unchained();
        __Ownable_init_unchained();
        setAdmin(msg.sender);

        // main
        PANCAKE_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        PANCAKE_FACTORY = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
        USDT = 0x55d398326f99059fF775485246999027B3197955;
        INVITE = 0x24A980baAc726f09D5c3EABf069bFbEB64236CF3;

        preSaleAmount = 200000000 ether;
        preSaleShare = 320;
        preSaleInitShare = preSaleShare;
        preSalePrice = 100 ether;
        releaseAmount = 50000000 ether;
        slip = 50;
        bonusNumber = 5;
    }

    function setStatus(bool status_) public onlyOwner {
        status = status_;
    }

    function setAdmin(address admin_) public onlyOwner {
        admin[admin_] = true;
    }

    function setINVITE(address INVITE_) public onlyOwner {
        INVITE = INVITE_;
    }

    function setMPO(address mpo_) public onlyOwner {
        MPO = mpo_;
        path[0] = [mpo_, USDT];
        path[1] = [USDT, mpo_];
    }

    function setMpoNft(address addr_) public onlyOwner {
        MpoNft = addr_;
    }

    function setUSDT(address U_) public onlyOwner {
        USDT = U_;
    }

    function setWALLET(address w_) public onlyOwner {
        WALLET = w_;
    }

    function setPancake(address router, address factory) public onlyOwner {
        PANCAKE_ROUTER = router;
        PANCAKE_FACTORY = factory;
    }

    function setAutoSellBuy(bool b_) public onlyAdmin {
        autoSellBuy = b_;
    }

    function setSlip(uint slip_) public onlyAdmin {
        slip = slip_;
    }

    function setBonusNumber(uint nmuber_) public onlyAdmin {
        bonusNumber = nmuber_;
    }

    function setReleaseAmount(uint amount_) public onlyAdmin {
        releaseAmount = amount_;
    }

    function setUserOut(address user_) public onlyAdmin {
        userInfo[user_].isPreSale = false;
        isExcluded[user_] = true;
        _excluded.push(user_);
    }

    function setUserIn(address user_) external onlyAdmin {
        require(isExcluded[user_], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == user_) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _excluded.pop();
                isExcluded[user_] = false;
                userInfo[user_].isPreSale = true;
                break;
            }
        }
    }

    function changeNftMinted(address user_, uint u_) public onlyAdmin {
        nftminted[user_] += u_;
        emit Minted(user_, u_);
    }

    function changePreSaleInfo(
        uint amount_,
        uint share_,
        uint price_
    ) public onlyOwner {
        preSaleAmount = amount_;
        preSaleShare = share_;
        preSalePrice = price_;
    }

    function safePull(
        address token,
        address wallet,
        uint amount
    ) external onlyOwner {
        IERC20(token).transfer(wallet, amount);
    }

    function setOfflinePreSale(address[] memory list_) public onlyAdmin {
        for (uint i = 0; i < list_.length; i++) {
            offlinePreSale.push(list_[i]);
        }
    }

    function _check(address user_) internal view returns (bool) {
        if (onlinePreSale.length > 0) {
            for (uint i = 0; i < onlinePreSale.length; i++) {
                if (onlinePreSale[i] == user_) {
                    return true;
                }
            }
        }

        if (offlinePreSale.length > 0) {
            for (uint i = 0; i < offlinePreSale.length; i++) {
                if (offlinePreSale[i] == user_) {
                    return true;
                }
            }
        }

        return false;
    }

    function releaseAddress(address[] memory addrList_) public onlyAdmin {
        for (uint i = 0; i < addrList_.length; i++) {
            if (_check(addrList_[i])) {
                userInfo[addrList_[i]].toClaim += releaseAmount;
                tatolToClaim += releaseAmount;
            }
        }
    }

    ////////////////////////////////
    /////////// pre-sale ///////////
    ////////////////////////////////
    function chaeckOffline(address user_) internal view returns (bool) {
        for (uint i = 0; i < offlinePreSale.length; i++) {
            if (offlinePreSale[i] == user_) {
                return true;
            }
        }
        return false;
    }

    function preInvite(address user_, address inv_) internal {
        address _inv = IMPOInvite(INVITE).checkInviter(user_);
        if (_inv != address(0)) {
            require(_inv == inv_, "inviter wrong");
        } else {
            IMPOInvite(INVITE).whoIsYourInviter(user_, inv_);
        }
        preSaleTeam[inv_].push(user_);
    }

    function preSaleProcess(address inv_) public returns (bool) {
        require(status, "not start yet");
        require(INVITE != address(0), "contract error");
        preInvite(msg.sender, inv_);

        require(!userInfo[msg.sender].isPreSale, "bid_1");
        require(userInfo[msg.sender].amount == 0, "bid_2");

        require(preSaleShare > 0, "out of sale!");
        preSaleShare -= 1;
        preSaleTatol += preSaleAmount;

        userInfo[msg.sender] = UserInfo({
            isPreSale: true,
            amount: preSaleAmount,
            toClaim: 0,
            lastClaimedTime: 0,
            claimed: 0
        });

        basicNft[msg.sender] = 1;

        if (!chaeckOffline(msg.sender)) {
            IERC20(USDT).transferFrom(msg.sender, WALLET, preSalePrice);
            onlinePreSale.push(msg.sender);
        }

        emit PreSaleProcess(msg.sender, inv_);
        return true;
    }

    function calculate(address user_) public view returns (uint) {
        UserInfo storage user = userInfo[user_];
        return user.toClaim;
    }

    function withdraw() public returns (uint) {
        UserInfo storage user = userInfo[msg.sender];
        require(MPO != address(0), "token not be defined");
        require(!isExcluded[msg.sender], "Account is excluded");
        require(user.isPreSale, "not in presale");
        require(user.toClaim + user.claimed < user.amount, "is over");
        uint _amount = calculate(msg.sender);

        if (_amount > 0) {
            preSaleClaimed += _amount;
            tatolToClaim -= _amount;

            if (autoSellBuy) {
                uint init_T = IERC20(MPO).balanceOf(address(this));
                uint init_U = IERC20(USDT).balanceOf(address(this));
                require(init_T > _amount, "no enough balance");

                // swap in pancake, sell token
                swapExactTokensForTokensInPancake(path[0], _amount);
                uint balance1 = IERC20(USDT).balanceOf(address(this));
                uint diff1 = balance1 - init_U;

                // swap in pancake, buy token
                swapExactTokensForTokensInPancake(path[1], diff1);
                uint balance2 = IERC20(MPO).balanceOf(address(this));
                uint diff2 = balance2 - (init_T - _amount);
                //updata amount
                _amount = diff2;
            }
            // updata data
            user.lastClaimedTime = block.timestamp;
            user.claimed += _amount;
            user.toClaim = 0;

            // transfer Token to user
            IERC20(MPO).transfer(msg.sender, _amount);

            emit Withdraw(msg.sender, _amount);
        }

        return _amount;
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

    ////////////////////////////////
    ///////////// swap /////////////
    ////////////////////////////////

    function approveToSwap(address[] memory token_) public {
        uint len = token_.length;
        for (uint i = 0; i < len; i++) {
            IERC20(address(token_[i])).approve(
                address(PANCAKE_ROUTER),
                MAX_INT
            );
        }
    }

    function getAmountOutbyAddress(address[] memory path_, uint amountInput_)
        public
        view
        returns (uint)
    {
        address _pair = IFactory(PANCAKE_FACTORY).getPair(path_[0], path_[1]);
        (uint re0, uint re1, ) = IPair(_pair).getReserves();
        address _t0 = IPair(_pair).token0();
        address _t1 = IPair(_pair).token1();

        {
            // scope for amountOutput, avoids stack too deep errors
            uint amountOutput;
            if (_t0 == path_[0]) {
                amountOutput = IRouter01(PANCAKE_ROUTER).getAmountOut(
                    amountInput_,
                    re0,
                    re1
                );
            } else if (_t1 == path_[0]) {
                amountOutput = IRouter01(PANCAKE_ROUTER).getAmountOut(
                    amountInput_,
                    re1,
                    re0
                );
            }
            return amountOutput;
        }
    }

    function swapExactTokensForTokensInPancake(
        address[] memory path_,
        uint amountInput_
    ) private {
        uint _amountOutput = getAmountOutbyAddress(path_, amountInput_);
        uint amountOutMin = (_amountOutput * slip) / 100;
        uint deadline = (block.timestamp + 180);

        IRouter02(PANCAKE_ROUTER)
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountInput_,
                amountOutMin,
                path_,
                address(this),
                deadline
            );
    }

    ////////////////////////////////
    ////////////// veiw ////////////
    ////////////////////////////////

    function checkNftBouns(address user_)
        public
        view
        returns (uint limit, uint minted)
    {
        uint aa = basicNft[user_];
        limit = (checkTeamLength(user_) / bonusNumber) + aa;
        minted = nftminted[user_];
    }

    function checkTeam(address addr_) public view returns (address[] memory) {
        return preSaleTeam[addr_];
    }

    function checkTeamLength(address user_) public view returns (uint) {
        return preSaleTeam[user_].length;
    }

    function checkOfflineList(uint u_) public view returns (address[] memory) {
        if (u_ == 8888) {
            return offlinePreSale;
        }
    }

    function checkOnlineList(uint u_) public view returns (address[] memory) {
        if (u_ == 8888) {
            return onlinePreSale;
        }
    }

    function checkPreSaleInfo()
        public
        view
        returns (
            uint,
            uint,
            uint,
            uint
        )
    {
        uint allSale = preSaleAmount * preSaleInitShare;
        return (allSale, preSaleAmount, preSaleInitShare, preSalePrice);
    }

    function checkPreSaleReceived()
        public
        view
        returns (
            uint,
            uint,
            uint,
            uint
        )
    {
        uint soldPreSle = preSaleInitShare - preSaleShare;
        uint tatolRemaining = preSaleTatol - preSaleClaimed;
        return (soldPreSle, preSaleClaimed, tatolRemaining, tatolToClaim);
    }
}