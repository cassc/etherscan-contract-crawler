/**
 *Submitted for verification at BscScan.com on 2023-04-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract SmartAngel {
    using SafeMath for uint256;
    using SafeERC20 for USD;
    USD public Obj_USD;

    uint256 public totalAngels;
    uint256 public totalDonation;
    address payable public owner;
    uint256 public min_wth;
    address public ContractAddress;
    uint32 public chainId;
    uint256 public charityPercent;
    uint256[8] public aryRanks;
    address private mgr_address;
    bool private mgr_address_block;
    address[] private aryUsers;
    uint256 private sRank_amount;

    struct Angels {
        uint256 ang_regiTime;
        uint256 ang_tot_dwnline_count;
        uint256 ang_wth_wallet;
        address ang_introducer;
        uint256 ang_total_withdrawal;
        uint256 ang_directs;
        bool ang_is_auto;
        bool ang_is_block;
        bool ang_is_tempblock;
        uint256 ang_id;
        uint8 cuHelpNo;
    }

    struct SysFlags {
        bool sys_wthPause;
        bool sys_sysPause;
        bool sys_ban_fromwalletUp;
    }
    mapping(address => Angels) public tb_Angels;
    mapping(address => SysFlags) public tb_SysFlags;
    mapping(address => uint256[8]) public tb_Ang_selfHelp;
    mapping(address => uint256[8]) public tb_Ang_A_received;
    mapping(address => uint256[8]) public tb_Ang_flushed_biz;
    mapping(address => uint256[8]) public tb_Angels_levels_count;
    mapping(address => uint256[8]) public tb_Ang_A_dnBiz;
    mapping(address => uint256[8]) public tb_Ang_B_dnBiz;
    mapping(address => uint256[8]) public tb_Ang_B_received;

    uint256 public tot_blocked_gethelp;
    uint256 public tot_flushed_help;
    uint256 public GlobalWallet;
    uint256 public DevFund_used;
    uint256 public systotal_withdrawal;
    event onDonate(address indexed donor, uint256 donation);
    event onWithdrawal(address indexed donor, uint256 bonus);
    modifier onlyOwner() {
        require(msg.sender != address(0));
        require(payable(msg.sender) == owner);
        _;
    }

    modifier onlyManager() {
        require(msg.sender != address(0));
        if (mgr_address_block == true) {
            require(owner == msg.sender);
        } else {
            require(mgr_address == msg.sender || owner == msg.sender);
        }
        _;
    }

    constructor(
        address _ContractAddress,
        uint32 _chainId,
        uint256 _sRank_amount,
        uint256 _min_wth
    ) {
        owner = payable(msg.sender);
        tb_Angels[owner].ang_regiTime = block.timestamp;
        tb_Angels[owner].ang_introducer = owner;
        aryUsers.push(owner);

        charityPercent = 20e18;
        min_wth = _min_wth;
        sRank_amount = _sRank_amount;
        fn_set_ranks(_sRank_amount);
        blk_rnk(msg.sender, sRank_amount, 8);
        ContractAddress = _ContractAddress;
        chainId = _chainId;
        Obj_USD = USD(_ContractAddress);
    }

    function fn_set_ranks(uint256 _value) private {
        for (uint8 i = 0; i < 8; i++) {
            aryRanks[i] = _value;
            _value = _value.mul(2);
        }
    }

    //--- Add Help ----
    function fn_addHelp(
        address _Introducer,
        address _conAddress,
        uint32 _chainId,
        uint256 addHelpAmount,
        bool _autoFlag
    ) public returns (bool) {
        fn_intial_add_chek(msg.sender, _Introducer, _conAddress, _chainId);
        require(tb_SysFlags[owner].sys_sysPause == false);
        uint8 rankNo = fn_validate_rank(addHelpAmount);

        Angels storage objAngel = tb_Angels[msg.sender];

        require(Obj_USD.balanceOf(msg.sender) >= addHelpAmount);
        Obj_USD.safeTransferFrom(msg.sender, address(this), addHelpAmount);

        if (objAngel.ang_regiTime == 0) {
            objAngel.ang_regiTime = block.timestamp;
            objAngel.ang_introducer = _Introducer;
            objAngel.ang_is_auto = _autoFlag;
            aryUsers.push(msg.sender);

            totalAngels++;
            objAngel.ang_id = totalAngels;

            tb_Angels[_Introducer].ang_directs = tb_Angels[_Introducer]
                .ang_directs
                .add(1);
        } else {
            _Introducer = objAngel.ang_introducer;
        }
        fn_update_self_addHelp(msg.sender, addHelpAmount, rankNo);

        totalDonation = totalDonation.add(addHelpAmount);

        fn_add_passiveHelp(addHelpAmount, _Introducer, rankNo);

        fn_add_active_help(addHelpAmount, _Introducer, rankNo);
        emit onDonate(msg.sender, addHelpAmount);
        return true;
    }

    function fn_intial_add_chek(
        address _angle_addr,
        address _Introducer,
        address _conAddress,
        uint32 _chainId
    ) private view {
        require(_conAddress == ContractAddress);
        require(_angle_addr != address(0));
        require(_chainId == chainId);

        require(_Introducer != _angle_addr);
        require(tb_Angels[_Introducer].ang_regiTime > 0);
    }

    //---

    function fn_Wallet_addHelp_call(uint256 addHelpAmount) public {
        require(msg.sender != address(0));
        require(tb_SysFlags[owner].sys_sysPause == false);
        require(tb_Angels[msg.sender].ang_regiTime > 0);
        require(tb_Angels[msg.sender].ang_wth_wallet >= addHelpAmount);
        require(tb_SysFlags[owner].sys_ban_fromwalletUp == false);

        fn_Wallet_addHelp_action(msg.sender, addHelpAmount);
    }

    function fn_Wallet_addHelp_action(address _address, uint256 addHelpAmount)
        private
        returns (bool)
    {
        uint8 rankNo = fn_validate_rank(addHelpAmount);

        address _Introducer = tb_Angels[_address].ang_introducer;
        fn_update_self_addHelp(_address, addHelpAmount, rankNo);
        tb_Angels[_address].ang_wth_wallet = tb_Angels[_address]
            .ang_wth_wallet
            .sub(addHelpAmount);
        totalDonation = totalDonation.add(addHelpAmount);
        fn_add_passiveHelp(addHelpAmount, _Introducer, rankNo);
        fn_add_active_help(addHelpAmount, _Introducer, rankNo);
        emit onDonate(_address, addHelpAmount);
        return true;
    }

    //----------------------------------------------------------------------------
    function fn_add_passiveHelp(
        uint256 _addHelpAmount,
        address Introducer,
        uint8 _rankNo
    ) private {
        uint256 payableAmt = _addHelpAmount.mul(1e18).div(100e18);

        for (uint8 level_no = 0; level_no < 8; level_no++) {
            if (Introducer == owner) {
                break;
            }

            if (_rankNo == 0) {
                tb_Angels_levels_count[Introducer][
                    level_no
                ] = tb_Angels_levels_count[Introducer][level_no].add(1);

                tb_Angels[Introducer].ang_tot_dwnline_count = tb_Angels[
                    Introducer
                ].ang_tot_dwnline_count.add(1);
            }

            tb_Ang_B_dnBiz[Introducer][level_no] = tb_Ang_B_dnBiz[Introducer][
                level_no
            ].add(_addHelpAmount);

            tb_Ang_B_received[Introducer][level_no] = tb_Ang_B_received[
                Introducer
            ][level_no].add(payableAmt);

            //swap
            fn_addWallet(Introducer, payableAmt);
            Introducer = tb_Angels[Introducer].ang_introducer;
        }
    }

    //----------------------------------------------------------------------------
    function fn_add_active_help(
        uint256 _addHelpAmount,
        address Introducer,
        uint8 _rankNo
    ) private {
        for (uint8 level_no = 0; level_no < 8; level_no++) {
            if (Introducer == owner) {
                break;
            }
            uint256 afterDeduction = _addHelpAmount.sub(
                _addHelpAmount.mul(8e18).div(100e18)
            );

            //-- Qualifier
            if (level_no == _rankNo) {
                tb_Ang_A_dnBiz[Introducer][level_no] = tb_Ang_A_dnBiz[
                    Introducer
                ][level_no].add(_addHelpAmount);

                if (tb_Ang_selfHelp[Introducer][level_no] > 0) {
                    tb_Ang_A_received[Introducer][level_no] = tb_Ang_A_received[
                        Introducer
                    ][level_no].add(afterDeduction);

                    fn_addWallet(Introducer, afterDeduction);
                } else {
                    tb_Ang_flushed_biz[Introducer][
                        level_no
                    ] = tb_Ang_flushed_biz[Introducer][level_no].add(
                        afterDeduction
                    );
                    tot_flushed_help = tot_flushed_help.add(afterDeduction);
                    GlobalWallet = GlobalWallet.add(afterDeduction);
                }
                //-
                break;
            }
            //swap
            Introducer = tb_Angels[Introducer].ang_introducer;
        }
    }

    //------------------------------
    function fn_update_self_addHelp(
        address angle_addr,
        uint256 _addHelpAmount,
        uint8 _rankNo
    ) private {
        tb_Ang_selfHelp[angle_addr][_rankNo] = _addHelpAmount;
        tb_Angels[msg.sender].cuHelpNo = _rankNo + 1;
        if (_rankNo == 7) {
            tb_Angels[angle_addr].ang_is_auto = false;
        }
    }

    //----------------------------------------------------------------------------
    function fn_validate_rank(uint256 _addHelpAmount)
        private
        view
        returns (uint8 _rankNo)
    {
        uint8 rankNo = 100;

        for (uint8 i = 0; i < 8; i++) {
            if (aryRanks[i] == _addHelpAmount) {
                rankNo = i;
                break;
            }
        }
        require(rankNo < 100);
        //-
        if (rankNo == 0) {
            require(tb_Ang_selfHelp[msg.sender][0] == 0);
        } else {
            require(tb_Ang_selfHelp[msg.sender][rankNo] == 0);
            require(tb_Ang_selfHelp[msg.sender][rankNo - 1] > 0);
        }
        return rankNo;
    }

    //----------------------------------------------------------------------------
    function fn_addWallet(address angle_addr, uint256 _amount) private {
        if (tb_Angels[angle_addr].ang_is_block) {
            tot_blocked_gethelp = tot_blocked_gethelp.add(_amount);
            GlobalWallet = GlobalWallet.add(_amount);
        } else {
            tb_Angels[angle_addr].ang_wth_wallet = tb_Angels[angle_addr]
                .ang_wth_wallet
                .add(_amount);
        }
    }

    //----------------------------------------------------------------------------
    function fn_wth_Help(uint256 _amount) public returns (bool) {
        require(msg.sender != address(0));
        require(tb_SysFlags[owner].sys_sysPause == false);
        require(tb_SysFlags[owner].sys_wthPause == false);
        require(tb_Angels[msg.sender].ang_directs >= 3);
        require(_amount >= min_wth);
        require(tb_Angels[msg.sender].ang_wth_wallet >= _amount);
        require(
            (tb_Angels[msg.sender].ang_is_block == false) &&
                (tb_Angels[msg.sender].ang_is_tempblock == false)
        );
        require(Obj_USD.balanceOf(address(this)) >= _amount);

        tb_Angels[msg.sender].ang_wth_wallet = tb_Angels[msg.sender]
            .ang_wth_wallet
            .sub(_amount);

        tb_Angels[msg.sender].ang_total_withdrawal = tb_Angels[msg.sender]
            .ang_total_withdrawal
            .add(_amount);

        systotal_withdrawal = systotal_withdrawal.add(_amount);

        uint256 charityDeduct = _amount.mul(charityPercent).div(100e18);
        uint256 amttoSender = _amount.sub(charityDeduct);
        GlobalWallet = GlobalWallet.add(charityDeduct);
        Obj_USD.safeTransfer(msg.sender, amttoSender);
        emit onWithdrawal(msg.sender, _amount);
        return true;
    }

    //----------------------------------------------------------------------------
    function user_set_isAuto(bool _flag) public returns (bool) {
        require(tb_Angels[msg.sender].cuHelpNo < 8);
        tb_Angels[msg.sender].ang_is_auto = _flag;
        return true;
    }

    function user_details(address _addr)
        public
        view
        returns (uint256[8][7] memory ary)
    {
        ary[0] = tb_Ang_selfHelp[_addr];
        ary[1] = tb_Ang_A_received[_addr];
        ary[2] = tb_Ang_flushed_biz[_addr];
        ary[3] = tb_Angels_levels_count[_addr];
        ary[4] = tb_Ang_A_dnBiz[_addr];
        ary[5] = tb_Ang_B_dnBiz[_addr];
        ary[6] = tb_Ang_B_received[_addr];
        return ary;
    }

    //----------------------------------[ system ]------------------------------------------
    function set_manager(address _address, bool _flag)
        public
        onlyOwner
        returns (bool)
    {
        mgr_address = _address;
        mgr_address_block = _flag;
        return true;
    }

    function sys_add_sid(
        address _address,
        address _Introducer,
        uint32 _chainId,
        address _conAddress,
        uint8 ranksCnt
    ) external onlyManager returns (bool) {
        fn_intial_add_chek(_address, _Introducer, _conAddress, _chainId);
        require(ranksCnt >= 1 && ranksCnt <= 8);
        Angels storage objAngel = tb_Angels[_address];
        if (objAngel.ang_regiTime == 0) {
            objAngel.ang_regiTime = block.timestamp;
            aryUsers.push(_address);
            objAngel.ang_introducer = _Introducer;
            totalAngels++;
            objAngel.ang_id = totalAngels;
            tb_Angels[_Introducer].ang_directs = tb_Angels[_Introducer]
                .ang_directs
                .add(1);
        }
        for (uint8 i = 0; i < 8; i++) {
            tb_Ang_selfHelp[_address][i] = 0;
        }
        blk_rnk(_address, sRank_amount, ranksCnt);
        return true;
    }

    function blk_rnk(
        address _address,
        uint256 rank_amt,
        uint8 ranksCnt
    ) private {
        for (uint8 i = 0; i < ranksCnt; i++) {
            tb_Ang_selfHelp[_address][i] = rank_amt;
            rank_amt = rank_amt.mul(2);
        }
        tb_Angels[_address].cuHelpNo = ranksCnt;
        if (ranksCnt == 8) {
            tb_Angels[_address].ang_is_auto = false;
        }
    }

    function sys_withdraw(uint256 _amount, bool wthType)
        public
        onlyOwner
        returns (bool)
    {
        require(Obj_USD.balanceOf(address(this)) >= _amount);

        Obj_USD.safeTransfer(owner, _amount);
        if (wthType == true) {
            GlobalWallet = GlobalWallet.sub(_amount);
            DevFund_used = DevFund_used.add(_amount);
        }
        return true;
    }

    function sys_add_cb(uint256 _amount) public onlyOwner returns (bool) {
        require(Obj_USD.balanceOf(msg.sender) >= _amount);
        Obj_USD.safeTransferFrom(msg.sender, address(this), _amount);
        return true;
    }

    function sys_cb() external view onlyOwner returns (uint256) {
        return Obj_USD.balanceOf(address(this));
    }

    function sys_setBlckchain(address _ContractAddress, uint32 _chainId)
        public
        onlyOwner
    {
        ContractAddress = _ContractAddress;
        chainId = _chainId;
        Obj_USD = USD(_ContractAddress);
    }

    function set_blockid(
        address _address,
        bool _flag,
        bool block_type
    ) external onlyManager returns (bool) {
        require(tb_Angels[_address].ang_regiTime > 0);
        if (block_type == false) {
            tb_Angels[_address].ang_is_tempblock = _flag;
        } else {
            tb_Angels[_address].ang_is_block = _flag;
        }
        return true;
    }

    function sys_usr_set_isAuto(address _address, bool _flag)
        external
        onlyManager
        returns (bool)
    {
        tb_Angels[_address].ang_is_auto = _flag;
        return true;
    }

    function set_sys_Actions(uint8 systype, bool _flag)
        external
        onlyManager
        returns (bool)
    {
        if (systype == 1) {
            tb_SysFlags[owner].sys_wthPause = _flag;
        } else if (systype == 2) {
            tb_SysFlags[owner].sys_sysPause = _flag;
        } else if (systype == 3) {
            tb_SysFlags[owner].sys_ban_fromwalletUp = _flag;
        }
        return true;
    }

    function sys_editWallet(
        address angle_addr,
        uint256 _amount,
        bool _flag
    ) external onlyManager returns (bool) {
        if (_flag) {
            tb_Angels[angle_addr].ang_wth_wallet = tb_Angels[angle_addr]
                .ang_wth_wallet
                .add(_amount);
        } else {
            if (tb_Angels[angle_addr].ang_wth_wallet >= _amount) {
                tb_Angels[angle_addr].ang_wth_wallet = tb_Angels[angle_addr]
                    .ang_wth_wallet
                    .sub(_amount);
            }
        }
        return true;
    }

    function set_sys_rates(uint8 systype, uint256 _number)
        external
        onlyManager
        returns (bool)
    {
        if (systype == 1) {
            charityPercent = _number;
        } else if (systype == 2) {
            min_wth = _number;
        }
        return true;
    }

    function getUsers() external view onlyManager returns (address[] memory) {
        return aryUsers;
    }

    function getAry(uint256 sIn, uint256 eIn)
        external
        view
        onlyManager
        returns (address[] memory)
    {
        require(eIn >= sIn && eIn < aryUsers.length);
        address[] memory Ary = new address[](eIn - sIn + 1);
        for (uint256 i = sIn; i <= eIn; i++) {
            Ary[i - sIn] = aryUsers[i];
        }
        return Ary;
    }

    function sys_bulk_auto() external onlyManager returns (bool) {
        address _addr;
        uint8 _cuHelpNo;
        for (uint256 i = (aryUsers.length - 1); i > 0; i--) {
            if (aryUsers[i] == owner) {
                return true;
            }
            _addr = aryUsers[i];
            _cuHelpNo = tb_Angels[_addr].cuHelpNo;
            if (
                tb_Angels[_addr].ang_is_auto == true &&
                tb_Angels[_addr].ang_is_block == false
            ) {
                if (
                    (tb_Angels[_addr].ang_wth_wallet >= aryRanks[_cuHelpNo]) &&
                    (tb_Ang_selfHelp[_addr][_cuHelpNo] == 0)
                ) {
                    fn_Wallet_addHelp_action(_addr, aryRanks[_cuHelpNo]);
                }
            }
        }
        return true;
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }
}

interface USD {
    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(
        USD token,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        USD token,
        address from,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        USD token,
        address spender,
        uint256 value
    ) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0));
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function callOptionalReturn(USD token, bytes memory data) private {
        require(isContract(address(token)));

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success);

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)));
        }
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}